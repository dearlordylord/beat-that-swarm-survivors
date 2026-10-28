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
    const activeIndex = CHARACTERS.indexOf(hero)
    const supporting = [...CHARACTERS.slice(activeIndex + 1), ...CHARACTERS.slice(0, activeIndex)]
      .map(
        (member, index) =>
          `<div class="stream-supporter" data-character="${member.id}" style="--member:${index}">${survivorSvg(member.id)}</div>`
      )
      .join("")
    this.card.innerHTML = `<div class="stream-group" aria-hidden="true">${supporting}<div class="stream-lead">${survivorSvg(hero.id)}</div></div><div class="stream-identity"><small>NOW PLAYING · RUN ${run}</small><strong>${escapeHtml(hero.name)}</strong><span>${escapeHtml(hero.title)}</span></div>`
    this.card.hidden = false
    this.timer = setTimeout(() => this.card.classList.add("stream-announcement-compact"), 6000)
  }

  hide() {
    clearTimeout(this.timer)
    this.card.hidden = true
  }
}
