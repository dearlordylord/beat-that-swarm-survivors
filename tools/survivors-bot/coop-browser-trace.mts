import type { Frame, Player } from "../../examples/survivors/frame.mts"
export type Role = "host" | "guest"
export interface BrowserError {
  role: Role
  message: string
  console?: boolean
  location?: { url: string; lineNumber: number; columnNumber: number }
}
export interface LastFrame {
  wall: number
  tick: number
  phase: number
  round: number
  runId: string
  choicePending?: boolean
}
export interface RenderRow extends Omit<LastFrame, "choicePending"> {
  at: number
  round: number
  timing?: Frame["predictionTiming"]
  remotePresentation: Frame["remotePresentation"]
  presentationMeasurement: { sampledAt: number; callbackEntry: number; onDisplayEnd: number } | undefined
  players: Player[] | undefined
  enemies: { x: number; y: number; identity: number; lifetime: string }[]
}
export interface InputResolution {
  wall: number
  worldTick: number
  phase: number
  round: number
  eligible: boolean
  applied: boolean
  x: number
  y: number
  seq: number
}
export interface SnapshotAck {
  at: number
  wall: number
  token: number
  observation: number
}
export interface SnapshotSend extends SnapshotAck {
  tick: number
  phase: number
  round: number
  depth: number
}
export interface Trace {
  workerInitializations: {
    wall: number
    at: number
    requestedSeed: number
    seed: number
    overridden: boolean
    session: number
  }[]
  workerErrors: unknown[]
  workerFailures: unknown[]
  inputResolutions: InputResolution[]
  inputRejections: { reason: number }[]
  snapshotSends: SnapshotSend[]
  snapshotAcks: SnapshotAck[]
  predictionBlocks: { total: number; horizon: number; disconnected: number }
  presentationSamples: number
  failNextDraw: boolean
  injectedDrawFailures: number
  renders: RenderRow[]
  statuses: unknown[]
  inputs: { at: number; wall?: number; type?: string; code?: string; x?: number; y?: number }[]
  pointerEvents: { at: number; type: string; pointerId: number; target: string }[]
  arrivals: {
    at: number
    wall: number
    tick: number
    observation: number
    admissionGuestLastSeq: number
    receipt: BendABI.CoopSession.Receipt
    inputTiming: { worldTick: number }
  }[]
  nativeSends: unknown[]
  lastFrame: LastFrame | null
}
declare global {
  var __qaDefined: <T>(value: T | undefined | null) => T
  var __reliable: Trace
  var __reliableDraw: (frame: Frame & { presentationMeasurement?: RenderRow["presentationMeasurement"] }) => void
}
