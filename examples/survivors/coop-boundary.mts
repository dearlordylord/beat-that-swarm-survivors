import { array, boolean, number, object, text, parseBendList } from "./host-values.mts"
import { parseCoopFrame } from "./frame.mts"
import type { CoopFrame } from "./frame.mts"
import { parseSetup } from "./profile.mts"
import type { CoopSetup } from "./coop-ui.mts"
import {
  parseCoopConnectionAction,
  parseCoopConnectionState,
  parseCoopConnectionSignal,
  parseCoopHitJournalState,
  parseCoopHitJournalHitEvent,
  parseCoopSessionReceipt,
  parseCoopSessionState
} from "./bend-codecs.generated.mts"

export interface CoreView {
  tick: number
  phase?: number
  roundId?: number
  predictionAllowed?: boolean
  advanced?: boolean
  contacts?: BendList<BendABI.CoopHitJournal.HitEvent>
  contactsOmitted?: number
}
export function parseCoreView(value: unknown): CoreView {
  const row = object(value)
  return {
    ...row,
    tick: number(row.tick),
    ...(row.phase === undefined ? {} : { phase: number(row.phase) }),
    ...(row.roundId === undefined ? {} : { roundId: number(row.roundId) }),
    ...(row.predictionAllowed === undefined ? {} : { predictionAllowed: boolean(row.predictionAllowed) }),
    ...(row.advanced === undefined ? {} : { advanced: boolean(row.advanced) }),
    ...(row.contacts === undefined ? {} : { contacts: parseBendList(row.contacts, parseCoopHitJournalHitEvent) }),
    ...(row.contactsOmitted === undefined ? {} : { contactsOmitted: number(row.contactsOmitted) })
  }
}
export interface SnapshotEnvelope {
  type: "frame"
  connectionVersion: number
  token: number
  initial: boolean
  frame: CoopFrame
  admission: BendABI.CoopSession.State
  receipt: BendABI.CoopSession.Receipt
  observationSeq: number
  contactJournal: BendABI.CoopHitJournal.State
  inputTiming: unknown
}
export function parseSnapshotEnvelope(value: unknown): SnapshotEnvelope {
  const row = object(value)
  if (row.type !== "frame") throw new TypeError("Expected a frame envelope")
  return {
    type: "frame",
    connectionVersion: number(row.connectionVersion),
    token: number(row.token),
    initial: boolean(row.initial),
    frame: parseCoopFrame(row.frame),
    admission: parseCoopSessionState(row.admission),
    receipt: parseCoopSessionReceipt(row.receipt),
    observationSeq: number(row.observationSeq),
    contactJournal: parseCoopHitJournalState(row.contactJournal),
    inputTiming: row.inputTiming
  }
}
export type WorkerRequest =
  | { type: "init"; setup: CoopSetup; session: number; seed: number }
  | { type: "connected"; connectionEpoch: number }
  | { type: "handshake"; signal: BendABI.CoopConnection.Signal; connectionEpoch: number }
  | { type: "command"; player: number; text: string; deliveryId: number; connectionEpoch: number }
  | { type: "disconnect"; connectionEpoch?: number }
  | { type: "stop" }
export function parseWorkerRequest(value: unknown): WorkerRequest {
  const row = object(value)
  switch (row.type) {
    case "init": {
      const setup = object(row.setup)
      return {
        type: "init",
        setup: { ...parseSetup(setup), meta: number(setup.meta), allowedWeapons: number(setup.allowedWeapons) },
        session: number(row.session),
        seed: number(row.seed)
      }
    }
    case "connected":
      return { type: "connected", connectionEpoch: number(row.connectionEpoch) }
    case "handshake":
      return {
        type: "handshake",
        signal: parseCoopConnectionSignal(row.signal),
        connectionEpoch: number(row.connectionEpoch)
      }
    case "command":
      return {
        type: "command",
        player: number(row.player),
        text: text(row.text),
        deliveryId: number(row.deliveryId),
        connectionEpoch: number(row.connectionEpoch)
      }
    case "disconnect":
      return {
        type: "disconnect",
        ...(row.connectionEpoch === undefined ? {} : { connectionEpoch: number(row.connectionEpoch) })
      }
    case "stop":
      return { type: "stop" }
    default:
      throw new TypeError("Unknown worker request")
  }
}
export type WorkerReply =
  | { type: "command-consumed"; deliveryId: number }
  | {
      type: "frame"
      frame: CoopFrame
      observationSeq: number
      contactJournal: BendABI.CoopHitJournal.State
      connectionReady: boolean
    }
  | {
      type: "remote-frame"
      frame: CoopFrame
      admission: BendABI.CoopSession.State
      receipt: BendABI.CoopSession.Receipt
      observationSeq: number
      connectionEpoch: number
      token: number
      initial: boolean
      contactJournal: BendABI.CoopHitJournal.State
      inputTiming: unknown
    }
  | {
      type: "handshake-action"
      state: BendABI.CoopConnection.State
      action: BendABI.CoopConnection.Action
      connectionEpoch: number
    }
  | { type: "choice-unavailable"; player: number; connectionEpoch: number }
  | { type: "ready" }
  | { type: "error"; message: string; stack?: string; connectionEpoch: number; context: Record<string, unknown> }
  | { type: "rejected"; message: string; connectionEpoch: number }
  | {
      type: "input-rejected"
      reason: number
      seq: number
      targetWorldTick: number
      worldTick: number
      connectionEpoch: number
    }
export function parseWorkerReply(value: unknown): WorkerReply {
  const row = object(value)
  switch (row.type) {
    case "command-consumed":
      return { type: "command-consumed", deliveryId: number(row.deliveryId) }
    case "frame":
      return {
        type: "frame",
        frame: parseCoopFrame(row.frame),
        observationSeq: number(row.observationSeq),
        contactJournal: parseCoopHitJournalState(row.contactJournal),
        connectionReady: boolean(row.connectionReady)
      }
    case "remote-frame":
      return {
        type: "remote-frame",
        frame: parseCoopFrame(row.frame),
        admission: parseCoopSessionState(row.admission),
        receipt: parseCoopSessionReceipt(row.receipt),
        observationSeq: number(row.observationSeq),
        connectionEpoch: number(row.connectionEpoch),
        token: number(row.token),
        initial: boolean(row.initial),
        contactJournal: parseCoopHitJournalState(row.contactJournal),
        inputTiming: row.inputTiming
      }
    case "handshake-action":
      return {
        type: "handshake-action",
        state: parseCoopConnectionState(row.state),
        action: parseCoopConnectionAction(row.action),
        connectionEpoch: number(row.connectionEpoch)
      }
    case "choice-unavailable":
      return { type: "choice-unavailable", player: number(row.player), connectionEpoch: number(row.connectionEpoch) }
    case "ready":
      return { type: "ready" }
    case "error":
      return {
        type: "error",
        message: text(row.message),
        ...(row.stack === undefined ? {} : { stack: text(row.stack) }),
        connectionEpoch: number(row.connectionEpoch),
        context: object(row.context)
      }
    case "rejected":
      return { type: "rejected", message: text(row.message), connectionEpoch: number(row.connectionEpoch) }
    case "input-rejected":
      return {
        type: "input-rejected",
        reason: number(row.reason),
        seq: number(row.seq),
        targetWorldTick: number(row.targetWorldTick),
        worldTick: number(row.worldTick),
        connectionEpoch: number(row.connectionEpoch)
      }
    default:
      throw new TypeError("Unknown worker reply")
  }
}
export function parseVisualFrame(value: unknown) {
  const row = object(value)
  return {
    shots: array(row.shots, (value) => {
      const shot = object(value)
      return {
        id: text(shot.id),
        player: number(shot.player),
        kind: number(shot.kind),
        weapon: number(shot.weapon),
        seed: number(shot.seed),
        age: number(shot.age),
        x: number(shot.x),
        y: number(shot.y),
        radius: number(shot.radius),
        life: number(shot.life),
        fade: number(shot.fade),
        opacity: number(shot.opacity)
      }
    }),
    corpses: array(row.corpses, (value) => {
      const fade = object(value)
      return {
        id: text(fade.id),
        seed: number(fade.seed),
        generation: number(fade.generation),
        x: number(fade.x),
        y: number(fade.y),
        radius: number(fade.radius),
        lastSeen: number(fade.lastSeen)
      }
    })
  }
}
export function parseBuildVersion(value: unknown) {
  const row = object(value)
  return {
    ...(row.revision === undefined ? {} : { revision: text(row.revision) }),
    ...(row.dirty === undefined ? {} : { dirty: boolean(row.dirty) }),
    ...(row.sourceFingerprint === undefined ? {} : { sourceFingerprint: text(row.sourceFingerprint) }),
    ...(row.buildContext === undefined ? {} : { buildContext: text(row.buildContext) })
  }
}
