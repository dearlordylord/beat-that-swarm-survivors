import { escapeHtml } from "./host-values.mts"
import { ITEM_ICON_SHAPES, PERSONAL_ICON_LABELS } from "./item-icon-shapes.mts"

export type ItemIconKind = keyof typeof ITEM_ICON_SHAPES

export function itemIcon(kind: ItemIconKind, id: number, size = 24): string {
  const shape = ITEM_ICON_SHAPES[kind][id]
  return shape
    ? `<svg class="item-icon" data-icon="${kind}/${id}" viewBox="0 0 32 32" width="${size}" height="${size}" aria-hidden="true" focusable="false">${shape}</svg>`
    : ""
}

export function rewardIcon(kind: number, id: number, fallback: string, size = 32): string {
  if (kind === 0 || kind === 3) return itemIcon("weapon", id, size) || escapeHtml(fallback)
  if (kind === 1) return itemIcon("passive", id, size) || escapeHtml(fallback)
  return escapeHtml(fallback)
}

export function personalIconLabel(id: number): string {
  return PERSONAL_ICON_LABELS[id] || ""
}
