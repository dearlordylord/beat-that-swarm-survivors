import { object, text, boolean } from "./host-values.mts"

export interface PartyLobby {
  players: { player: number; character: number; ready: boolean; connected: boolean }[]
  started: boolean
  canStart: boolean
}
const PREFIX = "BPL1:"
function integer(value: unknown, min: number, max: number) {
  if (typeof value !== "number" || !Number.isInteger(value) || value < min || value > max)
    throw Error("Invalid party number.")
  return value
}
export function encodeLobby(lobby: PartyLobby) {
  return PREFIX + JSON.stringify(lobby)
}
export function decodeLobby(bytes: Uint8Array): PartyLobby | null {
  if (bytes.length > 4096 || ![66, 80, 76, 49, 58].every((value, index) => bytes[index] === value)) return null
  const value = new TextDecoder("utf-8", { fatal: true }).decode(bytes)
  if (!value.startsWith(PREFIX)) return null
  const raw: unknown = JSON.parse(value.slice(PREFIX.length))
  const record = object(raw)
  if (!Array.isArray(record.players) || record.players.length > 4) throw Error("Invalid party roster.")
  const players = record.players.map((value: unknown) => {
    const player = object(value)
    return {
      player: integer(player.player, 0, 3),
      character: integer(player.character, 0, 0xffffffff),
      ready: boolean(player.ready),
      connected: boolean(player.connected)
    }
  })
  if (new Set(players.map((player) => player.player)).size !== players.length) throw Error("Duplicate party seat.")
  return { players, started: boolean(record.started), canStart: boolean(record.canStart) }
}
export function encodeInvitation(tickets: string[]) {
  return "party1:" + JSON.stringify(tickets)
}
export function invitationSeats(invitation: string) {
  if (!invitation.startsWith("party1:")) return [{ player: 1, ticket: invitation }]
  const value: unknown = JSON.parse(invitation.slice(7))
  if (!Array.isArray(value) || value.length !== 3) throw Error("Invalid party invitation.")
  return value.map((ticket: unknown, index) => ({ player: index + 1, ticket: text(ticket) }))
}
