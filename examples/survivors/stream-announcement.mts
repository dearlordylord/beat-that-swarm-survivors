import { CHARACTERS } from "./content.mts"
import { at, escapeHtml } from "./host-values.mts"
import { survivorSvg } from "./survivor-art.mts"

export class StreamAnnouncement {
  private readonly card = document.createElement("aside")
  private timer: ReturnType<typeof setTimeout> | undefined

  constructor() {
    this.card.id = "stream-announcement"
    this.card.hidden = true
    this.card.setAttribute("aria-live", "polite")
    document.body.append(this.card)
  }

  show(character: number, run: number) {
    clearTimeout(this.timer)
    const hero = CHARACTERS[character] ?? at(CHARACTERS, 0)
    this.card.dataset.character = String(hero.id)
    this.card.dataset.run = String(run)
    this.card.classList.remove("stream-announcement-compact")
    this.card.innerHTML = `<div class="stream-portrait">${survivorSvg(hero.id)}</div><div><small>NOW PLAYING · RUN ${run}</small><strong>${escapeHtml(hero.name)}</strong><span>${escapeHtml(hero.title)}</span></div>`
    this.card.hidden = false
    this.timer = setTimeout(() => this.card.classList.add("stream-announcement-compact"), 6000)
  }

  hide() {
    clearTimeout(this.timer)
    this.card.hidden = true
  }
}
