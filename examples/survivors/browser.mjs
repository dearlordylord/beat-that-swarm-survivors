import { gameFrame } from './observations.mjs';
import { MENU_TABS, renderMenuContent } from './menu-content.mjs';
import {
  WEAPONS,
  PASSIVES,
  CHARACTERS,
  STAGES,
  ARCANA,
  ACHIEVEMENTS,
  UNIONS,
  RUN_MODES,
} from "./content.mjs";
import { renderExpeditionAction } from "./expedition-menu.mjs";
import {
  loadProfile,
  saveProfile,
  buyUpgrade,
  metaCode,
  recordRun,
  isUnlocked,
  unlock,
  requirementsMet,
  allowedWeapons,
  validateSetup,
  observeRun,
} from "./progression.mjs";
const $ = (s) => document.querySelector(s),
  canvas = $("#game"),
  audio = {
    engine: null,
    context: null,
    master: null,
    unlock() {
      if (this.engine) return this.engine.unlock();
      // Keep the browser gesture even when the simulation is still downloading.
      try {
        const Context = globalThis.AudioContext || globalThis.webkitAudioContext;
        if (!this.context && Context) {
          this.context = new Context();
          this.master = this.context.createGain();
          this.master.gain.value = 0;
          this.master.connect(this.context.destination);
        }
        if (this.context?.state === 'suspended') this.context.resume().catch(() => {});
      } catch {}
    },
    stop(...args) { this.engine?.stop(...args); },
    event(...args) { this.engine?.event(...args); },
    update(...args) { this.engine?.update(...args); },
    observe(...args) { this.engine?.observe(...args); },
    setMuted(...args) { this.engine?.setMuted(...args); },
    setVolume(...args) { this.engine?.setVolume(...args); },
  };
let Game, renderer, runtimeTask, starting = false;
function prepareRuntime() {
  if (!runtimeTask) runtimeTask = Promise.all([
    import('./dist/game.mjs'), import('./renderer.mjs'), import('./audio.mjs'),
  ]).then(([game, graphics, sound]) => {
    Game = game.default;
    renderer = new graphics.Renderer(canvas);
    audio.engine = new sound.AudioEngine();
    if (audio.context) {
      audio.engine.context = audio.context;
      audio.engine.master = audio.master;
      audio.engine.nextNote = audio.context.currentTime + 0.1;
    }
    settings();
  }).catch(error => { runtimeTask = null; throw error; });
  return runtimeTask;
}
let profile = loadProfile(),
  state,
  frame,
  running = false,
  paused = false,
  upgradeOpen = false,
  accumulator = 0,
  previous = 0,
  tab = MENU_TABS.includes(new URL(location.href).searchParams.get("tab")) ? new URL(location.href).searchParams.get("tab") : "expedition",
  collectionTab = "weapons",
  character = 0,
  stage = 0,
  arcana = 0,
  mode = 0,
  shownPhase = -1,
  toastTimer,
  runId = "";
let openPanel = null, pendingUnlock = null;
let loadoutSignature = "";
let runHistory = observeRun({}, {});
const runResult = () => ({
  ...frame,
  runId,
  ...runHistory,
});
const keys = new Set(),
  touch = { x: 0, y: 0 },
  STEP = 1000 / 60;
const esc = (s) =>
  String(s ?? "").replace(
    /[&<>"']/g,
    (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        c
      ],
  );
const time = (t) =>
  `${Math.floor(t / 60)
    .toString()
    .padStart(2, "0")}:${Math.floor(t % 60)
    .toString()
    .padStart(2, "0")}`;
function toast(message) {
  $("#toast").textContent = message;
  $("#toast").classList.add("visible");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => $("#toast").classList.remove("visible"), 3000);
}
function settings() {
  audio.setMuted(profile.settings.muted);
  audio.setVolume(profile.settings.volume);
}
function card(item, attributes = "", extra = "", selected = false) {
  const pressed = /data-(stage|arcana|mode)=/.test(attributes)
    ? `aria-pressed="${selected}"`
    : "";
  return `<button class="card banner-panel ${selected ? "selected" : ""}" ${attributes} ${pressed}><div class="banner-heading"><span class="icon" style="color:${item.color || "var(--gold)"}">${item.icon || "✦"}</span><h3>${esc(item.name)}</h3></div><p>${esc(item.description)}</p>${extra}</button>`;
}
function menu() {
  const returningToMenu = $("#menu").hidden;
  const previousFocus = $("#menu").contains(document.activeElement)
    ? {
        id: document.activeElement.id,
        data: { ...document.activeElement.dataset },
      }
    : null;
  running = false;
  paused = false;
  keys.clear();
  touch.x = touch.y = 0;
  audio.stop(true);
  $("#menu").hidden = false;
  $("#overlay").hidden = true;
  $("#hud").hidden = true;
  $("#joystick").hidden = true;
  $("#wallet").textContent =
    `◈ ${profile.gold.toLocaleString("en-US")} · legacy gold`;
  document
    .querySelectorAll("#tabs button")
    .forEach((b) => b.classList.toggle("active", b.dataset.tab === tab));
  document.documentElement.dataset.menuTab = tab;
  const html = renderMenuContent(tab, { profile, character, stage, arcana, mode, openPanel, pendingUnlock }, collectionTab);
  $("#menuContent").innerHTML = html;
  // The dock is a sibling of the scroller, so it cannot cover picker content.
  $("#menuDock").innerHTML = tab === "expedition"
    ? renderExpeditionAction({ character, stage }) : "";
  $("#menuDock").hidden = tab !== "expedition";
  if (previousFocus) {
    const match = [...$("#menu").querySelectorAll("button,input")].find(
      (element) =>
        previousFocus.id
          ? element.id === previousFocus.id
          : Object.keys(previousFocus.data).length &&
            Object.entries(previousFocus.data).every(
              ([key, value]) => element.dataset[key] === value,
            ),
    );
    match?.focus({ preventScroll: true });
  } else if (returningToMenu) {
    $("#tabs .active")?.focus({ preventScroll: true });
  }
}
function consume(method, ...args) {
  const owner = state;
  state = undefined;
  accept(Game[method](owner, ...args));
  if (["choose", "skip", "banish"].includes(method) && [1, 2].includes(frame.phase)) {
    upgradeOpen = true;
  }
}
function accept(packet) {
  if (packet.$ === "Failed") throw Error(packet.error);
  if (packet.$ !== "Packet") throw Error("Invalid simulation response");
  state = packet.state;
  let old = frame;
  frame = gameFrame(packet.frame);
  if (!frame) { frame = old; return; }
  if (old?.phase === 0 && [1, 2].includes(frame.phase)) upgradeOpen = true;
  runHistory = observeRun(runHistory, { weapons: frame.weapons });
  frame.stage ??= stage;
  if (running) audio.observe({...frame,runId});
  if (frame.phase !== shownPhase) {
    shownPhase = frame.phase;
    phase();
  }
}
async function start() {
  if (starting) return;
  starting = true;
  const buttons = [...document.querySelectorAll('#start,#start-top,#restart')];
  buttons.forEach(button => { button.disabled = true; button.setAttribute('aria-busy', 'true'); });
  const status = $('#engineStatus');
  status.textContent = 'Preparing game…';
  try {
    await prepareRuntime();
  } catch (error) {
    status.textContent = 'Could not load the game. Check your connection and reload.';
    console.error(error);
    return;
  } finally {
    starting = false;
    buttons.forEach(button => { button.disabled = false; button.removeAttribute('aria-busy'); });
  }
  status.textContent = '';
  ({ character, stage, arcana, mode } = validateSetup(profile, { character, stage, arcana, mode }));
  upgradeOpen = false;
  banishing = false;
  runId = crypto.randomUUID?.() || `${Date.now()}-${Math.random()}`;
  audio.unlock();
  audio.stop(true);
  settings();
  renderer.reset();
  runHistory = observeRun({}, {});
  frame = undefined;
  shownPhase = -1;
  running = true;
  paused = false;
  accumulator = 0;
  previous = 0;
  $("#menu").hidden = true;
  $("#hud").hidden = false;
  $("#joystick").hidden = !matchMedia("(pointer:coarse)").matches;
  accept(Game.start(character, metaCode(profile)));
  consume("configure", stage, arcana);
  consume("set_mode", mode);
  consume("configure_unlocks", allowedWeapons(profile));
  canvas.focus();
}
function focusDialog() {
  const dialog = $("#dialog");
  (
    dialog.querySelector(
      "button:not(:disabled),input:not(:disabled),[tabindex='0']",
    ) || dialog
  ).focus({ preventScroll: true });
}
function phase() {
  if (!running) return;
  banishing = false;
  paused = false;
  if (![1, 2].includes(frame.phase)) upgradeOpen = false;
  if (frame.phase === 0 || ([1, 2].includes(frame.phase) && !upgradeOpen)) {
    const wasOpen = !$("#overlay").hidden;
    $("#overlay").hidden = true;
    if (wasOpen) canvas.focus({ preventScroll: true });
    return;
  }
  keys.clear();
  touch.x = touch.y = 0;
  $("#overlay").hidden = false;
  const d = $("#dialog");
  if (frame.phase === 1 || frame.phase === 2) {
    audio.stop();
    let offers = frame.offers || [];
    d.innerHTML = `<div class="banner-heading"><div class="eyebrow">${frame.phase === 1 ? `LEVEL ${frame.level}` : "TREASURE OF THE NIGHT"}</div><h2 id="dialog-title">${frame.phase === 1 ? "Power awakens" : "A fallen lord’s gift"}</h2></div><p>${frame.phase === 1 ? "Choose an ability for the next wave." : "Choose your reward. A matching weapon may evolve."}</p><div class="grid choices">${offers
      .map((o, index) => {
        const isW = o.kind === 0 || o.kind === 3,
          item =
            o.kind === 5
              ? UNIONS[o.id]
              : isW
                ? WEAPONS[o.id]
                : o.kind === 1
                  ? PASSIVES[o.id]
                  : o.kind === 4
                    ? {
                        name: "Golden gift",
                        icon: "◈",
                        description: "Gain gold for this run.",
                      }
                    : {
                        name: "Restorative elixir",
                        icon: "♥",
                        description: "Restore health.",
                      };
        return card(
          {
            ...item,
            name: o.kind === 3 ? item.evolvedName : item.name,
            description:
              o.kind === 3 ? item.evolvedDescription : item.description,
          },
          `data-choice="${index}"`,
          `<small>${o.kind === 5 ? "UNION" : o.kind === 3 ? "EVOLUTION" : o.kind === 2 ? "Healing" : o.kind === 4 ? "Gold" : `Level ${o.level}`} · key ${index + 1}</small>`,
        );
      })
      .join(
        "",
      )}</div>${frame.phase === 1 ? `<div class="dialog-actions"><button data-run="reroll" ${frame.rerolls === 0 ? "disabled" : ""}>↻ Reroll${frame.rerolls !== undefined ? ` (${frame.rerolls})` : ""}</button><button id="banish">Banish an offer…</button><button data-run="skip">Skip</button></div>` : ""}`;
  } else if (frame.phase === 3 || frame.phase === 4) {
    const awards = recordRun(profile, runResult());
    saveProfile(profile);
    d.innerHTML = `<div class="banner-heading"><div class="eyebrow">${STAGES[stage].name.toUpperCase()}</div><h2 id="dialog-title">${frame.phase === 4 ? "The dawn is yours" : "The night will remember"}</h2></div><p>${frame.phase === 4 ? "The horde has fallen. Your legacy grows stronger." : "Every shard of power brings the next dawn closer."}</p><div class="summary"><div><strong>${time(frame.tick / 60)}</strong><span>TIME</span></div><div><strong>${frame.kills}</strong><span>DEFEATED</span></div><div><strong>${frame.level}</strong><span>LEVEL</span></div><div><strong>+${frame.gold} ◈</strong><span>LEGACY</span></div></div>${awards.length ? `<p>New achievements: ${awards.map((id) => ACHIEVEMENTS.find((a) => a.id === id)?.name || id).join(", ")}</p>` : ""}<div class="dialog-actions"><button class="primary" id="restart">Another night</button><button id="return">Return to menu</button></div>`;
  }
  focusDialog();
}
function openUpgrade() {
  if (!running || ![1, 2].includes(frame?.phase)) return;
  upgradeOpen = true;
  accumulator = 0;
  phase();
}
function pause(value) {
  if (upgradeOpen) {
    if (value === true) return;
    upgradeOpen = false;
    phase();
    return;
  }
  if (!running || ![0, 1, 2].includes(frame?.phase)) return;
  paused = value ?? !paused;
  keys.clear();
  touch.x = touch.y = 0;
  accumulator = 0;
  if (paused) {
    audio.stop();
    $("#overlay").hidden = false;
    $("#dialog").innerHTML =
      '<div class="banner-heading"><div class="eyebrow">THE WORLD STANDS STILL</div><h2 id="dialog-title">Arena map</h2></div><p>The world is paused · M / Esc to return</p><canvas id="worldmap" class="world-map" width="360" height="360" role="img"></canvas><p class="map-legend"><span>● You</span><span>□ View</span><span class="map-chest">■ Chest</span><span class="map-relic">◆ Stage relic</span></p><p class="map-note">The whole arena · Enemies and XP are not shown</p><div class="dialog-actions"><button class="primary" id="resume">Resume</button><button id="abandon">End run</button></div><p>Keep moving with WASD / arrow keys. Walk over experience shards to collect XP; shards stay on the ground.<br>Collect chests manually; press E to choose a ready reward.<br>Carry up to 6 weapons and 6 relics.</p>';
    renderer.drawMap($("#worldmap"), frame);
    focusDialog();
  } else {
    $("#overlay").hidden = true;
    canvas.focus();
  }
}
function hud() {
  if (!frame) return;
  canvas.dataset.playerX = frame.px;
  canvas.dataset.playerY = frame.py;
  canvas.dataset.tick = frame.tick;
  $("#clock").textContent = time(frame.tick / 60);
  $("#gold").textContent = `◈ ${frame.gold}`;
  $("#level").textContent = [1, 2].includes(frame.phase) ? `LEVEL ${frame.level} · ${frame.phase === 2 ? "TREASURE" : "UPGRADE"} READY [E]` : `LEVEL ${frame.level}`;
  $("#level").style.cursor = [1, 2].includes(frame.phase) ? "pointer" : "";
  $("#level").onclick = openUpgrade;
  $("#level").setAttribute("role", [1, 2].includes(frame.phase) ? "button" : "status");
  $("#level").tabIndex = [1, 2].includes(frame.phase) ? 0 : -1;
  $("#level").onkeydown = (event) => {
    if (event.code === "Enter" || event.code === "Space") {
      event.preventDefault();
      event.stopPropagation();
      openUpgrade();
    }
  };
  $("#xpFill").style.width =
    `${Math.min(100, (frame.xp / Math.max(1, frame.xpNeed)) * 100)}%`;
  $("#hpFill").style.width =
    `${Math.max(0, (frame.hp / Math.max(1, frame.maxHp)) * 100)}%`;
  $("#healthText").textContent = `♥ ${frame.hp} / ${frame.maxHp}`;
  $("#runStats").textContent = `☠ ${frame.kills}`;
  const signature = JSON.stringify([frame.weapons, frame.passives]);
  if (signature === loadoutSignature) return;
  loadoutSignature = signature;
  const slots = [
    ...(frame.weapons || []).flatMap((n, i) =>
      n ? [{ ...WEAPONS[i], ...(n >= 10 ? UNIONS[n - 10] : {}), n }] : [],
    ),
    ...(frame.passives || []).flatMap((n, i) =>
      n ? [{ ...PASSIVES[i], n }] : [],
    ),
  ];
  $("#loadout").innerHTML = slots
    .map(
      (w) =>
        `<span class="slot" title="${esc(w.n >= 10 ? w.name : w.n > 8 ? w.evolvedName : w.name)}" style="color:${w.color || "#d9d0b7"}">${w.icon}<small>${w.n > 8 ? "✦" : w.n}</small></span>`,
    )
    .join("");
}
function fail(error) {
  paused = true;
  audio.stop();
  $("#error").hidden = false;
  $("#error").textContent =
    `Unable to continue the game: ${error.message}\nReload the page to return to the menu.`;
  console.error(error);
}
function animation(now) {
  let dt = Math.min(100, now - (previous || now));
  previous = now;
  try {
    if (running && frame) {
      if (!paused && !upgradeOpen && [0, 1, 2].includes(frame.phase)) {
        accumulator += dt;
        while (accumulator >= STEP) {
          let dx =
              Number(keys.has("KeyD") || keys.has("ArrowRight")) -
              Number(keys.has("KeyA") || keys.has("ArrowLeft")) +
              touch.x,
            dy =
              Number(keys.has("KeyS") || keys.has("ArrowDown")) -
              Number(keys.has("KeyW") || keys.has("ArrowUp")) +
              touch.y,
            l = Math.max(1, Math.hypot(dx, dy));
          consume("advance_live", dx / l, dy / l);
          accumulator -= STEP;
          if (![0, 1, 2].includes(frame.phase) || upgradeOpen) {
            accumulator = 0;
            break;
          }
        }
      } else accumulator = 0;
      audio.update(frame, !paused && !upgradeOpen && [0, 1, 2].includes(frame.phase));
      renderer.draw(frame, dt / 1000, profile.settings);
      hud();
    }
  } catch (e) {
    fail(e);
  }
  requestAnimationFrame(animation);
}
let banishing = false;
document.addEventListener("click", (event) => {
  const b = event.target.closest("button");
  if (!b || b.disabled) return;
  audio.unlock();
  try {
    if (b.dataset.tab) {
      tab = b.dataset.tab;
      menu();
      $("#menuScroll").scrollTop = 0;
    } else if (b.dataset.menuPanel !== undefined) {
      openPanel = openPanel === b.dataset.menuPanel ? null : b.dataset.menuPanel;
      pendingUnlock = null;
      menu();
    } else if (b.dataset.buyKind !== undefined) {
      const kind = b.dataset.buyKind, id = Number(b.dataset.buyId);
      const item = (kind === "character" ? CHARACTERS : kind === "stage" ? STAGES : []).find(x => x.id === id);
      if (!item) return;
      if (unlock(profile, kind, id)) {
        if (kind === "character") character = id;
        else stage = id;
        pendingUnlock = null;
        openPanel = null;
        audio.event("choose");
        menu();
      } else toast(requirementsMet(profile, item) ? "Not enough legacy gold" : item.hint);
    } else if (b.dataset.character !== undefined || b.dataset.stage !== undefined || b.dataset.mode !== undefined) {
      const kind = b.dataset.character !== undefined ? "character" : b.dataset.stage !== undefined ? "stage" : "mode";
      const id = Number(b.dataset[kind]);
      if (isUnlocked(profile, kind, id)) {
        if (kind === "character") character = id;
        else if (kind === "stage") stage = id;
        else mode = id;
        pendingUnlock = null;
        openPanel = null;
        menu();
      } else {
        pendingUnlock = { kind, id };
        openPanel = kind;
        menu();
        const details = $("[data-unlock-details]");
        details?.focus({ preventScroll: true });
        details?.scrollIntoView({ block: "nearest" });
      }
    } else if (b.dataset.arcana !== undefined) {
      arcana = Number(b.dataset.arcana);
      pendingUnlock = null;
      openPanel = null;
      menu();
    } else if (b.dataset.upgrade !== undefined) {
      if (buyUpgrade(profile, +b.dataset.upgrade)) {
        saveProfile(profile);
        audio.event("choose");
        menu();
      }
    } else if (b.dataset.collection) {
      collectionTab = b.dataset.collection;
      menu();
    } else if (b.dataset.choice !== undefined) {
      audio.event("choose");
      upgradeOpen = false;
      consume(banishing ? "banish" : "choose", +b.dataset.choice);
      banishing = false;
      shownPhase = -1;
      phase();
      shownPhase = frame.phase;
    } else if (b.dataset.run) {
      if (b.dataset.run === "skip") upgradeOpen = false;
      consume(b.dataset.run);
      shownPhase = -1;
      phase();
      shownPhase = frame.phase;
    } else if (b.id === "banish") {
      banishing = !banishing;
      b.textContent = banishing
        ? "Choose an ability to banish"
        : "Banish an offer…";
    } else if (b.id === "start" || b.id === "start-top" || b.id === "restart") start().catch(fail);
    else if (b.id === "map") pause(true);
    else if (b.id === "pause" || b.id === "resume") pause();
    else if (b.id === "return") menu();
    else if (b.id === "abandon") {
      recordRun(profile, { ...runResult(), phase: 3 });
      saveProfile(profile);
      menu();
    }
  } catch (e) {
    fail(e);
  }
});
document.addEventListener("change", (e) => {
  const id = e.target.id;
  if (id === "sound") profile.settings.muted = !e.target.checked;
  else if (id === "motion") profile.settings.reducedMotion = e.target.checked;
  else if (id === "damage") profile.settings.showDamage = e.target.checked;
  else if (id === "volume") profile.settings.volume = +e.target.value;
  else return;
  settings();
  saveProfile(profile);
});
window.addEventListener("keydown", (e) => {
  if (e.code === "KeyM" && running && !document.activeElement?.matches("input,select,textarea")) {
    e.preventDefault();
    if (!e.repeat && !upgradeOpen) pause();
    return;
  }
  if (!$("#overlay").hidden && e.code === "Tab") {
    const controls = [
      ...$("#dialog").querySelectorAll(
        "button:not(:disabled),input:not(:disabled),[tabindex='0']",
      ),
    ];
    const first = controls[0],
      last = controls.at(-1);
    if (!first) {
      e.preventDefault();
      $("#dialog").focus();
      return;
    }
    if (!$("#dialog").contains(document.activeElement)) {
      e.preventDefault();
      (e.shiftKey ? last : first).focus();
    } else if (
      (e.shiftKey && document.activeElement === first) ||
      (!e.shiftKey && document.activeElement === last)
    ) {
      e.preventDefault();
      (e.shiftKey ? last : first).focus();
    }
    return;
  }
  // Preserve native keyboard activation and text/range controls.
  if (
    e.code !== "Escape" &&
    (document.activeElement?.matches("input,select,textarea") ||
      (document.activeElement?.matches("button") &&
        !/^Digit[123]$/.test(e.code)))
  )
    return;
  if (
    [
      "ArrowUp",
      "ArrowDown",
      "ArrowLeft",
      "ArrowRight",
      "Space",
      "Escape",
      "KeyW",
      "KeyA",
      "KeyS",
      "KeyD",
      "KeyE",
      "Digit1",
      "Digit2",
      "Digit3",
    ].includes(e.code)
  ) {
    if (running) e.preventDefault();
    if (e.repeat) return;
    if (e.code === "KeyE") openUpgrade();
    else if (e.code === "Escape" || e.code === "Space") pause();
    else if (
      /^Digit[123]$/.test(e.code) &&
      running &&
      !paused &&
      ([1, 2].includes(frame.phase) && upgradeOpen)
    )
      document
        .querySelector(`[data-choice="${+e.code.slice(-1) - 1}"]`)
        ?.click();
    else keys.add(e.code);
  }
});
window.addEventListener("keyup", (e) => keys.delete(e.code));
window.addEventListener("blur", () => {
  keys.clear();
  pause(true);
});
document.addEventListener("visibilitychange", () => {
  if (document.hidden) pause(true);
});
const joy = $("#joystick");
let pointer = null;
function joystick(e) {
  const r = joy.getBoundingClientRect(),
    x = e.clientX - r.left - r.width / 2,
    y = e.clientY - r.top - r.height / 2,
    l = Math.max(35, Math.hypot(x, y));
  touch.x = x / l;
  touch.y = y / l;
  $("#stick").style.transform =
    `translate(${touch.x * 33}px,${touch.y * 33}px)`;
  e.preventDefault();
}
joy.addEventListener("pointerdown", (e) => {
  audio.unlock();
  pointer = e.pointerId;
  joy.setPointerCapture(pointer);
  joystick(e);
});
joy.addEventListener("pointermove", (e) => {
  if (e.pointerId === pointer) joystick(e);
});
for (const type of ["pointerup", "pointercancel"])
  joy.addEventListener(type, () => {
    pointer = null;
    touch.x = touch.y = 0;
    $("#stick").style.transform = "";
  });
({ character, stage, arcana, mode } = validateSetup(profile, {}));
settings();
menu();
requestAnimationFrame(animation);
// Fetch the simulation after the independent menu has mounted.
prepareRuntime().catch(() => { /* Keep the menu usable if the game download fails. */ });
