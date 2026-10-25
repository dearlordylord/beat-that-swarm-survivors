import { projectileFrame } from "./observations.mts"
import { admitSnapshot } from "./snapshot-envelope.mts"
import { displayText, defined, list as nativeList, errorMessage, at, parseJson, object } from "./host-values.mts"
import type { Frame, Body, CoopFrame } from "./frame.mts"
import type { CoopSetup } from "./coop-ui.mts"
import Protocol from "./dist/coop-protocol.mjs"
import Connection from "./dist/coop-connection.mjs"
import ClientDelivery from "./dist/coop-client-delivery.mjs"
import SnapshotFlow from "./dist/coop-snapshot-flow.mjs"
import Prediction from "./dist/coop-prediction.mjs"
import PlaybackWire from "./dist/coop-playback-wire.mjs"
import ClientClock from "./dist/coop-client-clock.mjs"
import LocalProjectiles from "./dist/coop-local-projectiles.mjs"
import HitJournal from "./dist/coop-hit-journal.mjs"
import { CoopTransport } from "./coop-transport.mts"
import type { TransportEvent } from "./coop-transport.mts"
import { encodeSnapshot, SnapshotDecoder } from "./coop-snapshot-codec.mts"
import { CoopUI } from "./coop-ui.mts"
import type { SnapshotEnvelope, WorkerReply, WorkerRequest } from "./coop-boundary.mts"
import { parseBuildVersion } from "./coop-boundary.mts"
type Role = "host" | "guest"
// Browser IO: Iroh, input, worker scheduling and presentation. No simulation here.

let transport: CoopTransport | null = null,
  worker: Worker | null = null,
  role: Role | undefined,
  sessionId: number,
  sequence = 0,
  tick = 0,
  epoch = 0
function postWorker(message: WorkerRequest) {
  worker?.postMessage(message)
}
let activeSnapshotDecoder: SnapshotDecoder | null = null
let runId = "",
  stalled = false
let input = { x: 0, y: 0 },
  inputTimer: ReturnType<typeof setInterval> | undefined,
  lastFrameAt = 0,
  connected = false
let latestSnapshot: Extract<WorkerReply, { type: "remote-frame" }> | null
let snapshotFlow = SnapshotFlow.fresh(0)
const pendingCommands = new Set(),
  MAX_COMMANDS = 64
const MAX_COMMAND_BYTES = ClientDelivery.max_frame_bytes()
let deliverySequence = 0,
  connectionEpoch = 0,
  connectDeadline: ReturnType<typeof setTimeout> | undefined
let connectionState = Connection.fresh({ $: "Guest" }),
  selectedSetup: CoopSetup,
  hostFrame: Frame | null
let clientDelivery = ClientDelivery.fresh(0)
let failureDiagnostic: Record<string, unknown> | null
const buildVersion = fetch("./version.json")
  .then(async (response) => {
    const value: unknown = await response.json()
    return parseBuildVersion(value)
  })
  .catch(() => null)
function reportFailure(error: unknown, source: string, context: Record<string, unknown> = {}) {
  if (failureDiagnostic) return
  const scrub = (text: unknown) => displayText(text).replace(/([?&#](?:join|session)=)[^\s&#)]+/g, "$1[redacted]")
  const details = typeof error === "object" && error !== null ? error : {}
  const report: Record<string, unknown> = {
    source,
    role,
    tick,
    connectionEpoch,
    message: scrub("message" in details && typeof details.message === "string" ? details.message : errorMessage(error)),
    stack: scrub("stack" in details && typeof details.stack === "string" ? details.stack : undefined),
    ...context
  }
  failureDiagnostic = report
  ui.diagnostic(report)
  void buildVersion.then((version) => {
    if (failureDiagnostic !== report) return
    if (version?.revision) report.revision = version.revision
    if (typeof version?.dirty === "boolean") report.dirty = version.dirty
    if (version?.sourceFingerprint) report.sourceFingerprint = version.sourceFingerprint
    if (version?.buildContext) report.buildContext = version.buildContext
    ui.diagnostic(report)
  })
}
let prediction: BendABI.CoopPrediction.State | null,
  predictionRun: string | null | undefined,
  predictionStage: number | undefined,
  predictionRound: number | null | undefined,
  authorityFrame: CoopFrame | null
let predictionClock = ClientClock.fresh(0)
let visualClock = ClientClock.fresh(0)
let predictionLead = 4,
  inputAckDelayMs = 0,
  lastPredictionResync: Record<string, unknown> | null,
  authorityInputTiming: unknown
const sentCommandTimes = new Map<number, number>()
let localShots = LocalProjectiles.empty(),
  localRun: BendABI.Game.Run | null,
  localTargets: BendList<BendABI.CoopLocalProjectiles.Target> = { $: "Nil" },
  remoteFrame: Frame | null
let contactJournal = HitJournal.fresh(0),
  receivedContacts = HitJournal.playback(0)
let playedContacts = HitJournal.playback(0),
  pendingJournal: BendABI.CoopHitJournal.State | null
const micros = (now: number) => {
  const value = Math.floor(now * 1000)
  if (!Number.isSafeInteger(value) || value < 0) throw Error("Invalid local input clock.")
  return value
}
const each = <T,>(rows: BendList<T>, callback: (row: T) => void) => {
  for (; rows.$ === "Con"; rows = rows.tail) callback(rows.head)
}
const bendBool = (value: unknown) => Boolean(value)
function advanceLocalVisuals(now: number) {
  if (!localRun || !remoteFrame || !prediction?.enabled || !Connection.running(connectionState)) return
  const budget = ClientClock.consume(visualClock, micros(now))
  visualClock = budget.state
  const point = Prediction.view(prediction)
  for (let step = 0; step < budget.steps; step++)
    localShots = LocalProjectiles.advance_tick(
      localShots,
      localRun,
      point.x,
      point.y,
      defined(remoteFrame.remotePresentation).tick,
      localTargets
    )
}
function advancePrediction(now = performance.now()) {
  if (role !== "guest" || !prediction || !authorityFrame || !Connection.running(connectionState)) return
  advanceLocalVisuals(now)
  const budget = ClientClock.consume(predictionClock, micros(now))
  predictionClock = budget.state
  for (let step = 0; step < budget.steps; step++) {
    if (!Prediction.can_tick(prediction) || !connected) break
    if (
      !sendAction({
        $: "MovementTick",
        round: predictionRound ?? 0,
        x: Math.sign(input.x) + 1,
        y: Math.sign(input.y) + 1
      })
    ) {
      predictionClock = ClientClock.discard(predictionClock)
      break
    }
    prediction = Prediction.tick(prediction)
    if (localRun && remoteFrame) {
      const point = Prediction.view(prediction)
      localShots = LocalProjectiles.accept_tick(
        localShots,
        true,
        1,
        localRun,
        input.x,
        input.y,
        point.x,
        point.y,
        prediction.displayWorldTick,
        defined(remoteFrame.remotePresentation).tick,
        authorityFrame.tick,
        localTargets,
        authorityFrame.combatForecast.snapshots
      )
    }
  }
}
function observeInputAcknowledgement(envelope: SnapshotEnvelope, now: number) {
  const acknowledged = envelope.admission?.guest?.lastSeq
  if (!Number.isInteger(acknowledged)) return
  const sentAt = sentCommandTimes.get(acknowledged)
  if (sentAt !== undefined) inputAckDelayMs = Math.max(0, now - sentAt)
  // Sample first: the first eligible frame must include its Setup round trip.
  for (const seq of sentCommandTimes.keys()) if (seq <= acknowledged) sentCommandTimes.delete(seq)
}
function reconcilePrediction(envelope: SnapshotEnvelope) {
  const frame = envelope.frame,
    now = performance.now()
  if (prediction && !Prediction.observation_newer(prediction, envelope.observationSeq)) return false
  observeInputAcknowledgement(envelope, now)
  const newRun = !prediction || predictionRun !== frame.runId || predictionStage !== frame.stage
  const reset = newRun || predictionRound !== (frame.roundId ?? 0)
  const wasEnabled = !reset && prediction?.enabled === true
  if (reset || !wasEnabled) predictionLead = Prediction.lead(Math.ceil(inputAckDelayMs))
  if (reset) {
    prediction = Prediction.fresh(
      frame.px,
      frame.py,
      frame.stepDistance,
      bendBool(frame.predictionAllowed),
      frame.tick,
      predictionLead
    )
    predictionRun = frame.runId
    predictionStage = frame.stage
    predictionRound = frame.roundId ?? 0
    predictionClock = ClientClock.fresh(micros(now))
  } else advancePrediction(now)
  const resync =
    !reset && wasEnabled && frame.predictionAllowed && Prediction.resync_needed(defined(prediction), frame.tick)
  const previousLead = predictionLead
  predictionLead = Prediction.choose_lead(defined(prediction), frame.tick, Math.ceil(inputAckDelayMs), predictionLead)
  const previousDisplayWorldTick = defined(prediction).displayWorldTick
  prediction = Prediction.reconcile(
    defined(prediction),
    envelope.observationSeq,
    frame.tick,
    frame.px,
    frame.py,
    frame.stepDistance,
    bendBool(frame.predictionAllowed),
    predictionLead
  )
  if (resync)
    lastPredictionResync = Object.freeze({
      reason: "authority-caught-display-cursor",
      previousDisplayWorldTick,
      anchorWorldTick: frame.tick,
      displayWorldTick: prediction.displayWorldTick,
      lead: predictionLead
    })
  else if (!reset && predictionLead > previousLead && prediction.displayWorldTick > previousDisplayWorldTick)
    lastPredictionResync = Object.freeze({
      reason: "input-lead-increased",
      previousDisplayWorldTick,
      anchorWorldTick: frame.tick,
      displayWorldTick: prediction.displayWorldTick,
      previousLead,
      lead: predictionLead
    })
  else if (reset) lastPredictionResync = null
  if (prediction.observation !== envelope.observationSeq) return false
  authorityFrame = frame
  authorityInputTiming = envelope.inputTiming
  const ownRun = PlaybackWire.own_run(frame.combatForecast)
  localRun = ownRun.$ === "Some" ? ownRun.value : null
  pendingJournal = envelope.contactJournal
  if (newRun) {
    localShots = LocalProjectiles.empty()
    contactJournal = envelope.contactJournal || HitJournal.fresh(connectionEpoch)
    receivedContacts = HitJournal.attach(contactJournal)
    playedContacts = HitJournal.attach(contactJournal)
  }
  if (!frame.predictionAllowed) localShots = LocalProjectiles.empty()
  if (!frame.predictionAllowed || !wasEnabled) {
    predictionClock = ClientClock.fresh(micros(now))
    visualClock = ClientClock.fresh(micros(now))
  }
  return true
}
function prepareDisplayFrame(now: number) {
  if (role !== "guest" || !authorityFrame) return
  const frame = remoteFrame || {
    ...authorityFrame,
    remotePresentation: { sourceTick: authorityFrame.tick, tick: authorityFrame.tick }
  }
  const targets = []
  for (const body of frame.bodies || []) {
    const target = LocalProjectiles.observed_target(
      body[7],
      body[2],
      body[6],
      defined(frame.remotePresentation).sourceTick,
      body[0],
      body[1],
      body[8],
      body[4]
    )
    if (target.$ === "Some") targets.push(target.value)
  }
  localTargets = nativeList(targets)
  if (localRun && prediction && Connection.running(connectionState)) {
    const boot = LocalProjectiles.ensure_bootstrap(
      localShots,
      1,
      localRun,
      authorityFrame.tick,
      localTargets,
      authorityFrame.combatForecast.snapshots,
      prediction
    )
    localShots = boot.state
    if (boot.started) visualClock = ClientClock.fresh(micros(now))
  }
  if (pendingJournal) {
    contactJournal = pendingJournal
    pendingJournal = null
    const newContacts = HitJournal.collect(receivedContacts, contactJournal)
    receivedContacts = newContacts.state
    each(newContacts.events, (event) => {
      localShots = LocalProjectiles.confirm(localShots, event, defined(frame.remotePresentation).tick, localTargets)
    })
  }
  // Finish costly bootstrap/contact work before selecting the painted remote time.
  advancePrediction(performance.now())
}
function displayFrame(frame: Frame | null): Frame | null {
  if (role !== "guest" || !authorityFrame || !frame) return frame
  remoteFrame = frame
  const targets = []
  for (const body of frame.bodies || []) {
    const target = LocalProjectiles.observed_target(
      body[7],
      body[2],
      body[6],
      defined(frame.remotePresentation).sourceTick,
      body[0],
      body[1],
      body[8],
      body[4]
    )
    if (target.$ === "Some") targets.push(target.value)
  }
  localTargets = nativeList(targets)
  const point =
    prediction && authorityFrame.predictionAllowed
      ? Prediction.view(prediction)
      : { x: authorityFrame.px, y: authorityFrame.py }
  const sample = ui.presentation.currentSample
  if (sample) {
    const confirmed = HitJournal.play_sample(playedContacts, contactJournal, sample)
    playedContacts = confirmed.state
    localShots = LocalProjectiles.play_effects(localShots, confirmed.events, defined(frame.remotePresentation).tick)
  }
  const visual = projectileFrame(
    LocalProjectiles.render_frame(localShots, 1, defined(frame.remotePresentation).tick, localTargets)
  )
  const visibility = LocalProjectiles.prepare_visibility(localShots)
  const bodies = (frame.bodies || [])
    .filter((body) =>
      LocalProjectiles.should_show_prepared(
        visibility,
        1,
        body[2],
        body[10] ?? 0,
        typeof body[9] === "string" ? body[9] : ""
      )
    )
    .concat(
      visual.shots.map(
        (shot): Body => [
          shot.x,
          shot.y,
          shot.kind,
          shot.weapon,
          0,
          0,
          shot.age,
          shot.seed,
          shot.radius,
          shot.id,
          shot.player,
          0,
          shot.opacity
        ]
      )
    )
  for (const corpse of visual.corpses) {
    const metadata = ui.presentation.bodyMetadata(corpse.seed, corpse.id)
    if (metadata) {
      const body: Body = [...metadata]
      body[0] = corpse.x
      body[1] = corpse.y
      body[4] = 0
      body[12] = 0.45
      bodies.push(body)
    }
  }
  return {
    ...frame,
    bodies,
    px: point.x,
    py: point.y,
    ...(frame.players
      ? {
          players: frame.players.map((player) =>
            player.id === defined(authorityFrame).ownPlayerId
              ? {
                  ...player,
                  ...defined(authorityFrame).players?.find((own) => own.id === player.id),
                  px: point.x,
                  py: point.y
                }
              : player
          )
        }
      : {}),
    ...(prediction
      ? {
          predictionTiming: {
            anchorWorldTick: prediction.anchorWorldTick,
            displayWorldTick: prediction.displayWorldTick,
            lead: predictionLead,
            inputAckDelayMs,
            resync: lastPredictionResync,
            server: authorityInputTiming
          }
        }
      : {})
  }
}
function postCommand(text: string, player: number) {
  if (!worker || pendingCommands.size >= MAX_COMMANDS) return false
  const deliveryId = ++deliverySequence
  pendingCommands.add(deliveryId)
  postWorker({ type: "command", player, text, deliveryId, connectionEpoch })
  return true
}
const decoder = new TextDecoder("utf-8", { fatal: true })
const random = () => at(crypto.getRandomValues(new Uint32Array(1)), 0)
function command(action: BendABI.CoopSession.Action) {
  const seq = ++sequence
  const intendedTick =
    role === "guest" && prediction && action.$ === "MovementTick" ? Prediction.next_world_tick(prediction) : tick
  if (role === "guest") {
    sentCommandTimes.set(seq, performance.now())
    if (sentCommandTimes.size > 256) sentCommandTimes.delete(defined(sentCommandTimes.keys().next().value))
  }
  if (role === "guest" && prediction && action.$ === "MovementTick")
    prediction = Prediction.command(prediction, seq, action.x, action.y)
  return Protocol.encode({
    $: "Command",
    session: sessionId,
    player: role === "host" ? 0 : 1,
    seq,
    intendedTick,
    action
  })
}
function signalConnection(signal: BendABI.CoopConnection.Signal, envelope?: SnapshotEnvelope) {
  if (role === "host" && worker) {
    postWorker({ type: "handshake", connectionEpoch, signal })
    return
  }
  const result = Connection.step(connectionState, Connection.epoch(connectionState), signal)
  connectionState = result.state
  connectionAction(result.action, envelope)
}
function transportFailure(error: unknown) {
  console.error(error)
  reportFailure(error, "transport")
  signalConnection({ $: "Reject", reason: { $: "TransportFailed" } })
}
function sendControl(action: BendABI.CoopConnection.Action) {
  const generation = epoch,
    connection = connectionEpoch,
    channel = transport
  return defined(channel)
    .send(Connection.encode_action(action))
    .catch((error) => {
      if (generation === epoch && connection === connectionEpoch) transportFailure(error)
      throw error
    })
}
function connectionAction(action: BendABI.CoopConnection.Action, envelope?: SnapshotEnvelope) {
  switch (action.$) {
    case "SendHello":
      sendControl(action).catch(() => {})
      break
    case "HelloAckAndSetup": {
      const generation = epoch,
        connection = connectionEpoch
      sendControl(action)
        .then(() => {
          if (generation !== epoch || connection !== connectionEpoch || !connected) return
          return defined(transport).send(
            command({
              $: "Setup",
              character: selectedSetup.character,
              arcana: selectedSetup.arcana,
              meta: selectedSetup.meta,
              allowedWeapons: selectedSetup.allowedWeapons
            })
          )
        })
        .catch((error) => {
          if (generation === epoch && connection === connectionEpoch) transportFailure(error)
        })
      break
    }
    case "PresentSnapshot": {
      try {
        if (!envelope?.frame || typeof envelope.frame.predictionAllowed !== "boolean" || !envelope.receipt)
          throw Error("Invalid authoritative snapshot")
        if (!reconcilePrediction(envelope)) return
        lastFrameAt = performance.now()
        tick = envelope.frame.tick
        if (stalled && Connection.running(connectionState)) ui.status("")
        stalled = false
        ui.present({
          ...envelope.frame,
          observationSeq: envelope.observationSeq,
          contactJournal: envelope.contactJournal
        })
        if (!Connection.running(connectionState)) ui.setChoicePending(true)
        signalConnection({ $: "SnapshotSeen", token: action.token, observation: action.observation })
        clientDelivery = ClientDelivery.offer_receipt(clientDelivery, action.token, action.observation)
      } catch (error) {
        console.error(error)
        reportFailure(error, "snapshot")
        signalConnection({ $: "Reject", reason: { $: "SnapshotFailed" } })
      }
      break
    }
    case "SendReadyAck":
      sendControl(action).catch(() => {})
      break
    case "StartAndConfirm":
      clearTimeout(connectDeadline)
      if (hostFrame) ui.present({ ...defined(hostFrame), runId })
      ui.setChoicePending(false)
      ui.status("")
      sendControl(action).catch(() => {})
      break
    case "GuestReady":
      clearTimeout(connectDeadline)
      predictionClock = ClientClock.fresh(micros(performance.now()))
      ui.setChoicePending(false)
      ui.status("")
      break
    case "Suspend":
      ui.setChoicePending(true)
      ui.status(
        role === "host"
          ? "Waiting for your teammate to rejoin. The run is paused."
          : "Host disconnected. Rejoin using the invitation if the party is still open.",
        { error: role !== "host" }
      )
      break
    case "CloseConnection": {
      clearTimeout(connectDeadline)
      clearInterval(inputTimer)
      prediction = null
      authorityFrame = null
      localShots = LocalProjectiles.empty()
      localRun = null
      ui.setChoicePending(false)
      ui.status(Connection.reason_text(action.reason), { error: true })
      const generation = epoch,
        connection = connectionEpoch,
        channel = transport
      const closePeer = () => {
        if (generation !== epoch || connection !== connectionEpoch) return
        if (role === "host") channel?.disconnectPeer()
        else channel?.close()
        connected = false
      }
      if (connected && channel) {
        defined(channel)
          .send(Connection.encode_action(action), { confirmDelivery: true })
          .catch(() => {})
          .finally(closePeer)
      } else {
        closePeer()
        // Endpoint creation may still complete after its IO deadline.
        if (!channel) epoch++
      }
      break
    }
  }
}
function armConnectionDeadline() {
  clearTimeout(connectDeadline)
  const generation = epoch,
    connection = connectionEpoch
  connectDeadline = setTimeout(() => {
    if (generation !== epoch || connection !== connectionEpoch) return
    // The browser owns the IO deadline; it cannot rely on an unresponsive worker.
    const result = Connection.step(connectionState, Connection.epoch(connectionState), { $: "Timeout" })
    connectionState = result.state
    if (role === "host" && worker) postWorker({ type: "handshake", connectionEpoch, signal: { $: "Timeout" } })
    connectionAction(result.action)
  }, 45000)
}
function sendAction(action: BendABI.CoopSession.Action) {
  if (role === "host" ? !worker : !connected || !Connection.running(connectionState)) {
    if (action.$ === "Choice") ui.setChoicePending(false)
    return false
  }
  if (role === "host") {
    const text = command(action)
    if (!postCommand(text, 0) && action.$ === "Choice") {
      ui.setChoicePending(false)
      ui.status("Host is busy. Please choose again.")
      return false
    }
    return true
  } else {
    // Reserve a bounded journal slot before assigning a sequence or predicting
    // its tick. A busy transport cannot create an unsent speculative input.
    const candidate: BendABI.CoopSession.Command = {
      $: "Command",
      session: sessionId,
      player: 1,
      seq: sequence + 1,
      intendedTick: prediction && action.$ === "MovementTick" ? Prediction.next_world_tick(prediction) : tick,
      action
    }
    const admission = ClientDelivery.enqueue(clientDelivery, candidate)
    clientDelivery = admission.state
    if (!admission.accepted) {
      if (action.$ === "Choice") {
        ui.setChoicePending(false)
        ui.status("Sending previous commands. Please choose again.")
      }
      return false
    }
    sequence = candidate.seq
    sentCommandTimes.set(sequence, performance.now())
    if (sentCommandTimes.size > 256) sentCommandTimes.delete(defined(sentCommandTimes.keys().next().value))
    if (prediction && action.$ === "MovementTick")
      prediction = Prediction.command(prediction, sequence, action.x, action.y)
    if (action.$ === "Choice") flushClientDelivery()
    return true
  }
}
function flushClientDelivery() {
  if (role !== "guest" || !connected) return
  const prepared = ClientDelivery.prepare(clientDelivery)
  clientDelivery = prepared.state
  if (prepared.packet.$ !== "Some") return
  const packet = prepared.packet.value,
    generation = epoch,
    connection = connectionEpoch
  defined(transport)
    .send(ClientDelivery.encode(packet))
    .then(() => {
      if (generation === epoch && connection === connectionEpoch)
        clientDelivery = ClientDelivery.complete(clientDelivery, packet.epoch, packet.id)
    })
    .catch((error) => {
      if (generation !== epoch || connection !== connectionEpoch) return
      clientDelivery = ClientDelivery.fail(clientDelivery, packet.epoch, packet.id)
      transportFailure(error)
    })
}
function flushSnapshot() {
  if (!connected || role !== "host") return
  const prepared = SnapshotFlow.prepare(snapshotFlow)
  snapshotFlow = prepared.state
  if (prepared.observation.$ !== "Some") return
  const message = latestSnapshot
  latestSnapshot = null
  if (!message || message.observationSeq !== prepared.observation.value)
    throw Error("The pending snapshot payload disagrees with its Bend delivery journal.")
  const generation = epoch,
    connection = connectionEpoch,
    channel = transport
  // Native completion clears only the writer; application receipts clear the
  // bounded observation window. QUIC delivery is weaker
  // than successful parsing, admission and presentation by the guest.
  encodeSnapshot(message.bytes)
    .then((bytes) => {
      if (generation !== epoch || connection !== connectionEpoch || !connected) return
      return defined(channel).send(bytes)
    })
    .then(() => {
      if (generation !== epoch || connection !== connectionEpoch) return
      snapshotFlow = SnapshotFlow.complete(snapshotFlow, message.token, message.observationSeq)
      flushSnapshot()
    })
    .catch((error) => {
      if (generation === epoch && connection === connectionEpoch && connected) transportFailure(error)
    })
}
async function connect(
  kind: Role,
  ticket: string | null,
  setup: CoopSetup,
  invitation: { session?: string | null } = {}
) {
  cleanup()
  ui.reset()
  const generation = epoch
  let snapshotDecoder = new SnapshotDecoder()
  activeSnapshotDecoder = snapshotDecoder
  role = kind
  ui.role(kind)
  sequence = 0
  selectedSetup = setup
  connectionState = Connection.fresh({ $: kind === "host" ? "Host" : "Guest" })
  if (kind === "host")
    runId =
      crypto.randomUUID?.() ||
      Array.from(crypto.getRandomValues(new Uint32Array(4)), (n) => n.toString(16).padStart(8, "0")).join("")
  const requestedSession = invitation.session ?? new URL(location.href).searchParams.get("session")
  if (kind === "guest" && requestedSession === null) throw Error("Open the complete invitation link.")
  sessionId = kind === "host" ? random() : Number(requestedSession)
  if (!Number.isInteger(sessionId) || sessionId < 0 || sessionId > 0xffffffff)
    throw Error("Open the complete invitation link.")
  ui.status("Connecting to Iroh…", { busy: true })
  armConnectionDeadline()
  try {
    const handleEvent = async (event: TransportEvent) => {
      if (generation !== epoch) return
      if (event.type === "connected") {
        connectionEpoch = event.connectionEpoch
        snapshotDecoder.close()
        snapshotDecoder = new SnapshotDecoder()
        activeSnapshotDecoder = snapshotDecoder
        clientDelivery = ClientDelivery.fresh(connectionEpoch)
        connected = true
        lastFrameAt = performance.now()
        clearInterval(inputTimer)
        latestSnapshot = null
        snapshotFlow = SnapshotFlow.fresh(connectionEpoch)
        armConnectionDeadline()
        if (kind === "host") {
          connectionState = Connection.state(Connection.reconnect(connectionState, connectionEpoch))
          snapshotFlow = SnapshotFlow.fresh(Connection.epoch(connectionState))
          postWorker({ type: "connected", connectionEpoch })
        } else {
          const result = Connection.reconnect(connectionState, connectionEpoch)
          connectionState = result.state
          connectionAction(result.action)
        }
        ui.status("Connected. Checking party compatibility…", { busy: true })
        inputTimer = setInterval(() => {
          if (kind === "guest") {
            advancePrediction()
            flushClientDelivery()
          } else sendAction({ $: "Movement", x: Math.sign(input.x) + 1, y: Math.sign(input.y) + 1 })
        }, 50)
      } else if (event.type === "message") {
        if (event.connectionEpoch !== connectionEpoch) return
        const messageDecoder = snapshotDecoder
        try {
          if (kind === "host" && event.bytes.byteLength > MAX_COMMAND_BYTES) {
            signalConnection({ $: "Reject", reason: { $: "ProtocolError" } })
            return
          }
          const bytes = kind === "guest" ? await messageDecoder.decode(event.bytes) : event.bytes
          if (generation !== epoch || event.connectionEpoch !== connectionEpoch) return
          const text = decoder.decode(bytes)
          const control = Connection.decode(text)
          if (control.$ === "Some") {
            signalConnection(control.value)
            return
          }
          if (kind === "host") {
            const decoded = ClientDelivery.decode(text)
            if (decoded.$ !== "Some") {
              signalConnection({ $: "Reject", reason: { $: "ProtocolError" } })
              return
            }
            const payload = decoded.value
            if (payload.receipt.$ === "Some") {
              snapshotFlow = SnapshotFlow.ack(
                snapshotFlow,
                payload.receipt.value.token,
                payload.receipt.value.observation
              )
              flushSnapshot()
            }
            if (payload.commands.$ !== "Nil" && !postCommand(text, 1)) {
              reportFailure(Error("The host command inbox is full."), "worker-inbox")
              signalConnection({ $: "Reject", reason: { $: "ProtocolError" } })
            }
          } else {
            const incoming = object(parseJson(text))
            if (incoming.type !== "frame") return
            const envelope = admitSnapshot(incoming)
            const number = (value: unknown) =>
              typeof value === "number" && Number.isInteger(value) && value >= 0 && value <= 0xffffffff ? value : 0
            signalConnection(
              {
                $: "Frame",
                version: number(envelope.connectionVersion),
                token: number(envelope.token),
                observation: number(envelope.observationSeq)
              },
              envelope
            )
          }
        } catch (error) {
          if (generation !== epoch || event.connectionEpoch !== connectionEpoch) return
          console.error(error)
          reportFailure(error, "incoming-message")
          signalConnection({ $: "Reject", reason: { $: "ProtocolError" } })
        }
      } else if (event.type === "disconnected") {
        snapshotDecoder.close()
        connectionEpoch = event.connectionEpoch
        connected = false
        prediction = null
        authorityFrame = null
        localShots = LocalProjectiles.empty()
        localRun = null
        clearInterval(inputTimer)
        latestSnapshot = null
        snapshotFlow = SnapshotFlow.fresh(connectionEpoch)
        ui.clearInput()
        clearTimeout(connectDeadline)
        if (kind === "host") postWorker({ type: "disconnect", connectionEpoch })
        else signalConnection({ $: "Lost" })
      } else if (event.type === "error") transportFailure(Error(event.message))
    }
    const created = await CoopTransport.create((event) => {
      void handleEvent(event).catch((error: unknown) => {
        if (generation === epoch) transportFailure(error)
      })
    })
    if (generation !== epoch) {
      created.close()
      return
    }
    transport = created
    if (kind === "host") {
      worker = new Worker("./coop-worker.mjs", { type: "module" })
      worker.onmessage = (event: MessageEvent<WorkerReply>) => {
        if (generation !== epoch) return
        try {
          const message = event.data
          if (message.type === "command-consumed") pendingCommands.delete(message.deliveryId)
          else if (message.type === "frame") {
            tick = message.frame.tick
            hostFrame = {
              ...message.frame,
              observationSeq: message.observationSeq,
              contactJournal: message.contactJournal
            }
            if (message.connectionReady || ui.frame) ui.present({ ...defined(hostFrame), runId })
            if (!message.connectionReady) ui.setChoicePending(true)
          } else if (message.type === "remote-frame") {
            if (!connected || message.connectionEpoch !== connectionEpoch) return
            if (!SnapshotFlow.offer_allowed(snapshotFlow, message.observationSeq)) return
            latestSnapshot = message
            snapshotFlow = SnapshotFlow.offer(snapshotFlow, message.observationSeq)
            flushSnapshot()
          } else if (message.type === "handshake-action") {
            if (message.connectionEpoch === connectionEpoch && Connection.reason(connectionState).$ === "None") {
              connectionState = message.state
              connectionAction(message.action)
            }
          } else if (
            message.type === "choice-unavailable" &&
            message.player === 0 &&
            message.connectionEpoch === connectionEpoch
          ) {
            ui.setChoicePending(false)
            ui.status("Waiting for your teammate to be ready.")
          } else if (message.type === "ready") {
            clearTimeout(connectDeadline)
            const link = new URL(location.href)
            link.search = ""
            link.searchParams.set("session", String(sessionId))
            link.searchParams.set("join", defined(transport).invitation())
            ui.invitation(link.href)
            ui.status("Send the invitation. Keep this host tab open.")
          } else if (message.type === "error" && message.connectionEpoch === connectionEpoch) {
            console.error(message.message, message.stack)
            reportFailure(message, "host-worker", message.context)
          }
        } catch (error) {
          reportFailure(error, "worker-message")
          signalConnection({ $: "Reject", reason: { $: "RuntimeFailed" } })
        }
      }
      worker.onerror = (event) => {
        if (generation !== epoch) return
        console.error(event.message || "Host worker failed")
        reportFailure(event.error || Error(event.message || "Host worker failed"), "worker-loader")
        worker?.terminate()
        worker = null
        signalConnection({ $: "Reject", reason: { $: "RuntimeFailed" } })
      }
      postWorker({ type: "init", session: sessionId, seed: random(), setup, runId })
    } else await defined(transport).join(defined(ticket))
  } catch (error) {
    if (generation === epoch) transportFailure(error)
  }
}
function showError(error: unknown) {
  ui.status(errorMessage(error), { error: true })
  console.error(error)
}
function cleanup() {
  failureDiagnostic = null
  ui.diagnostic(null)
  epoch++
  connectionState = Connection.fresh({ $: "Guest" })
  hostFrame = null
  clearTimeout(connectDeadline)
  connectionEpoch = 0
  pendingCommands.clear()
  sentCommandTimes.clear()
  stalled = false
  predictionLead = 4
  inputAckDelayMs = 0
  lastPredictionResync = null
  authorityInputTiming = null
  prediction = null
  authorityFrame = null
  localShots = LocalProjectiles.empty()
  localRun = null
  predictionRun = null
  predictionRound = null
  predictionClock = ClientClock.fresh(0)
  visualClock = ClientClock.fresh(0)
  localTargets = { $: "Nil" }
  remoteFrame = null
  pendingJournal = null
  contactJournal = HitJournal.fresh(0)
  receivedContacts = HitJournal.playback(0)
  playedContacts = HitJournal.playback(0)
  clientDelivery = ClientDelivery.fresh(0)
  connected = false
  clearInterval(inputTimer)
  latestSnapshot = null
  snapshotFlow = SnapshotFlow.fresh(connectionEpoch)
  activeSnapshotDecoder?.close()
  activeSnapshotDecoder = null
  worker?.terminate()
  worker = null
  transport?.close()
  transport = null
  input = { x: 0, y: 0 }
}
const ui = new CoopUI({
  onHost: (setup) => connect("host", null, setup).catch(showError),
  onJoin: (ticket, setup, invitation) => connect("guest", ticket, setup, invitation).catch(showError),
  onInput: (value) => {
    advancePrediction()
    input = value
    if (role === "host") sendAction({ $: "Movement", x: Math.sign(input.x) + 1, y: Math.sign(input.y) + 1 })
  },
  onPrepareDisplay: prepareDisplayFrame,
  onDisplay: displayFrame,
  onChoice: ({ round, index }) => sendAction({ $: "Choice", round, index }),
  onLeave: () => {
    cleanup()
    ui.reset()
  }
})
// A browser may suspend the host. Surface it; do not claim workers prevent it.
setInterval(() => {
  if (
    role === "guest" &&
    connected &&
    Connection.running(connectionState) &&
    !stalled &&
    performance.now() - lastFrameAt > 5000
  ) {
    stalled = true
    ui.status("Waiting for host updates. Check the connection and keep the host browser active.", { error: true })
  }
}, 1000)
addEventListener("pagehide", cleanup)
addEventListener("error", (event) => {
  if (!role || !event.message) return
  reportFailure(event.error || Error(event.message), "browser-view")
  signalConnection({ $: "Reject", reason: { $: "PresentationFailed" } })
})
addEventListener("unhandledrejection", (event) => {
  if (!role) return
  reportFailure(event.reason, "browser-promise")
  signalConnection({ $: "Reject", reason: { $: "PresentationFailed" } })
})
