import { object, text, boolean } from "./host-values.mts"
import type { CoopFrame } from "./frame.mts"
import type { CoopSetup } from "./coop-ui.mts"

export type SnapshotEnvelope = BendABI.CoopNetwork.Snapshot
export type WorkerRequest =
  | { type: "init"; setup: CoopSetup; session: number; seed: number; runId: string }
  | { type: "connected"; player: number; connectionEpoch: number }
  | { type: "handshake"; player: number; signal: BendABI.CoopConnection.Signal; connectionEpoch: number }
  | { type: "command"; player: number; text: string; deliveryId: number; connectionEpoch: number }
  | { type: "disconnect"; player: number; connectionEpoch: number }
  | { type: "configure"; setup: CoopSetup }
  | { type: "start" }
  | { type: "stop" }
export type LobbyUpdate = {
  type: "lobby"
  room: Pick<CoopSetup, "stage" | "mode">
  players: Array<{ player: number; character: number; ready: boolean; connected: boolean }>
  started: boolean
  canStart: boolean
  running: boolean
  inputEpoch: number
}
export type WorkerReply =
  | { type: "finished"; observationSeq: number }
  | LobbyUpdate
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
      player: number
      bytes: Uint8Array
      observationSeq: number
      connectionEpoch: number
      token: number
    }
  | {
      type: "handshake-action"
      player: number
      state: BendABI.CoopConnection.State
      action: BendABI.CoopConnection.Action
      connectionEpoch: number
    }
  | { type: "choice-unavailable"; player: number; connectionEpoch: number }
  | { type: "ready" }
  | {
      type: "error"
      player: number
      message: string
      stack?: string
      connectionEpoch: number
      context: Record<string, unknown>
    }
  | { type: "rejected"; player: number; message: string; connectionEpoch: number }
  | {
      type: "input-rejected"
      player: number
      reason: number
      seq: number
      targetWorldTick: number
      worldTick: number
      connectionEpoch: number
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
