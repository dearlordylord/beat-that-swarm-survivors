// Executed diagnostics require successful setup before inspecting a world.
export function corePacket(
  packet: BendABI.CoopCore.CorePacket
): Extract<BendABI.CoopCore.CorePacket, { $: "CorePacket" }> {
  if (packet.$ !== "CorePacket") throw new Error(`Core fixture failed: ${packet.message}`)
  return packet
}
