import { object, text, boolean } from "./host-values.mts"
import type { CoopFrame } from "./frame.mts"
import type { CoopSetup } from "./coop-ui.mts"

export interface SnapshotEnvelope {
  type: "frame"
  connectionVersion: number
  token: number
  initial: boolean
  runId: string
  frame: Extract<BendABI.CoopCore.Observation, { $: "ViewObservation" }>
  admission: BendABI.CoopSession.State
  receipt: BendABI.CoopSession.Receipt
  observationSeq: number
  contactJournal: BendABI.CoopHitJournal.State
  inputTiming: unknown
}
export type WorkerRequest =
  | { type: "init"; setup: CoopSetup; session: number; seed: number; runId: string }
  | { type: "connected"; connectionEpoch: number }
  | { type: "handshake"; signal: BendABI.CoopConnection.Signal; connectionEpoch: number }
  | { type: "command"; player: number; text: string; deliveryId: number; connectionEpoch: number }
  | { type: "disconnect"; connectionEpoch?: number }
  | { type: "stop" }
export type WorkerReply =
  | { type: "command-consumed"; deliveryId: number }
  | {
      type: "frame"
      frame: CoopFrame
      observationSeq: number
      contactJournal: BendABI.CoopHitJournal.State
      connectionReady: boolean
    }
  | { type: "remote-frame"; bytes: Uint8Array; observationSeq: number; connectionEpoch: number; token: number }
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
export function parseBuildVersion(value: unknown) {
  const row = object(value)
  return {
    ...(row.revision === undefined ? {} : { revision: text(row.revision) }),
    ...(row.dirty === undefined ? {} : { dirty: boolean(row.dirty) }),
    ...(row.sourceFingerprint === undefined ? {} : { sourceFingerprint: text(row.sourceFingerprint) }),
    ...(row.buildContext === undefined ? {} : { buildContext: text(row.buildContext) })
  }
}
