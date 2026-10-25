interface ElementsBySelector {
  "#worldmap": HTMLCanvasElement
  "#app": HTMLElement
  "#clock": HTMLElement
  "#coop-arcana": HTMLSelectElement
  "#coop-character": HTMLSelectElement
  "#coop-clock": HTMLElement
  "#coop-close-room": HTMLButtonElement
  "#coop-copy": HTMLButtonElement
  "#coop-fps": HTMLElement
  "#coop-game": HTMLCanvasElement
  "#coop-gold": HTMLElement
  "#coop-host": HTMLButtonElement
  "#coop-host-actions": HTMLElement
  "#coop-host-help": HTMLElement
  "#coop-host-own": HTMLAnchorElement
  "#coop-invitation": HTMLDialogElement
  "#coop-invite-again": HTMLButtonElement
  "#coop-invite-close": HTMLButtonElement
  "#coop-invite-link": HTMLInputElement
  "#coop-invite-title": HTMLElement
  "#coop-join": HTMLButtonElement
  "#coop-join-detail": HTMLElement
  "#coop-join-form": HTMLFormElement
  "#coop-join-title": HTMLElement
  "#coop-leave": HTMLButtonElement
  "#coop-level": HTMLElement
  "#coop-lobby": HTMLElement
  "#coop-map": HTMLCanvasElement
  "#coop-map-close": HTMLButtonElement
  "#coop-map-panel": HTMLElement
  "#coop-map-toggle": HTMLButtonElement
  "#coop-mode": HTMLSelectElement
  "#coop-offers": HTMLElement
  "#coop-play": HTMLElement
  "#coop-play-status": HTMLElement
  "#coop-players": HTMLElement
  "#coop-reward": HTMLElement
  "#coop-reward-detail": HTMLElement
  "#coop-reward-kind": HTMLElement
  "#coop-reward-title": HTMLElement
  "#coop-room-ready": HTMLElement
  "#coop-room-title": HTMLElement
  "#coop-setup-detail": HTMLElement
  "#coop-setup-fields": HTMLFieldSetElement
  "#coop-setup-preview": HTMLElement
  "#coop-share": HTMLButtonElement
  "#coop-share-status": HTMLElement
  "#coop-stage": HTMLSelectElement
  "#coop-status": HTMLElement
  "#coop-ticket": HTMLInputElement
  "#coop-touch": HTMLElement
  "#coop-wallet": HTMLElement
  "#coop-xp": HTMLElement
  "#dialog": HTMLElement
  "#engineStatus": HTMLElement
  "#error": HTMLElement
  "#game": HTMLCanvasElement
  "#gold": HTMLElement
  "#healthText": HTMLElement
  "#hpFill": HTMLElement
  "#hud": HTMLElement
  "#joystick": HTMLElement
  "#level": HTMLElement
  "#loadout": HTMLElement
  "#lobby-title": HTMLElement
  "#map": HTMLButtonElement
  "#menu": HTMLElement
  "#menuContent": HTMLElement
  "#menuDock": HTMLElement
  "#menuScroll": HTMLElement
  "#overlay": HTMLElement
  "#pause": HTMLButtonElement
  "#runStats": HTMLElement
  "#stick": HTMLElement
  "#tabs": HTMLElement
  "#toast": HTMLElement
  "#wallet": HTMLElement
  "#xpFill": HTMLElement
}
type Selected<S extends string> = S extends keyof ElementsBySelector ? ElementsBySelector[S] : HTMLElement
export function element<S extends string>(selector: S, document?: Document): Selected<S>
export function element(selector: string, document = globalThis.document): HTMLElement {
  const node = document.querySelector<HTMLElement>(selector)
  if (!node) throw new Error(`Missing element: ${selector}`)
  return node
}

export function enableSecondaryRewardTouch(root: HTMLElement, signal?: AbortSignal) {
  const contacts = new Map<number, { button: HTMLButtonElement; x: number; y: number }>()
  const options = signal ? { signal } : {}
  root.addEventListener(
    "pointerdown",
    (event) => {
      if (event.pointerType !== "touch" || event.isPrimary) return
      const button =
        event.target instanceof Element ? event.target.closest<HTMLButtonElement>("button[data-choice]") : null
      if (button && !button.disabled) contacts.set(event.pointerId, { button, x: event.clientX, y: event.clientY })
    },
    options
  )
  root.addEventListener(
    "pointermove",
    (event) => {
      const contact = contacts.get(event.pointerId)
      if (contact && Math.hypot(event.clientX - contact.x, event.clientY - contact.y) > 10)
        contacts.delete(event.pointerId)
    },
    options
  )
  root.addEventListener(
    "pointercancel",
    (event) => {
      contacts.delete(event.pointerId)
    },
    options
  )
  root.addEventListener(
    "pointerup",
    (event) => {
      const contact = contacts.get(event.pointerId)
      contacts.delete(event.pointerId)
      if (!contact || contact.button.disabled || !contact.button.isConnected) return
      const releasedOver = root.ownerDocument.elementFromPoint(event.clientX, event.clientY)?.closest("button")
      if (releasedOver === contact.button && Math.hypot(event.clientX - contact.x, event.clientY - contact.y) <= 10)
        contact.button.click()
    },
    options
  )
}
