# Stream the game and strategy controls on a Mac

Use the browser stream mode for the themed game, normal audio and a reloadable
JavaScript strategy. The game runs in one browser window; its operator controls
can move into a second window. This is a private mod preview, not publication to
the public Survivors site.

## Start the browser stream

1. Build the current browser sources with `npm run build --prefix examples/survivors/web`.
2. On the Mac hosting this checkout, run `bash tools/survivors-performance/serve-private-macos.sh`.
3. Open the printed private HTTPS hostname with `?stream=1`. For the current host,
   use `https://pepkas-macbook-pro.tailc8c871.ts.net:9443/?stream=1`.
4. Select the character and other game options, then click **Start stream**.
   This gesture also enables browser audio.
5. Click **Separate controls** to move the operator panel into its own browser
   window. Allow the popup for this private origin if the browser blocks it.

Each completed run, including death and victory, starts the next survivor in
catalog order. Gilt Hare wraps to Grove Scribe. The first run uses your menu
selection. **Next character** immediately starts a new run with the next survivor,
including while paused. It is disabled before startup and after Stop. Stream
mode unlocks all seven inside its isolated profile. Ordinary
player saves are unchanged. The announcement rebuilds its lead and supporting
roster from the actual newly started character.

The original window keeps the game, HUD and character announcement. The second
window provides pause/resume, stop, **Next character**, strategy reload, audio resume and diagnostics;
it does not start another simulation. **Return controls to game**, or closing
the control window, restores the panel to the game window. This browser strategy
feature was brought across from the separate `bendvy-stream-bot` checkout; the
detachable operator window is part of this mod's integration.

Use HTTPS for iPhone Safari comparisons; see the
[private preview rules](../../examples/survivors/README.md#private-https-preview-on-iphone).
Keep the Mac powered and awake. Stream mode keeps playing when its game document
becomes hidden. A background timer updates the simulation and Canvas while
requestAnimationFrame is suspended. Visible mode uses the normal animation clock;
visibility changes do not resume a manually paused stream. Ordinary player mode
still pauses when hidden.

Browsers can throttle timers or freeze background pages, especially when audio
is muted. This fallback removes the game's own hidden-window pause; it cannot
guarantee minimized-window frame rate or 24/7 operation. See the
[Page Visibility API scheduling limits](https://developer.mozilla.org/en-US/docs/Web/API/Page_Visibility_API).
Check game ticks and the OBS picture in the intended window arrangement before
leaving it unattended. Use **Resume audio** if the browser suspends sound.

## Edit and reload strategy

The default strategy is `examples/survivors/stream-strategy.mts`. Bend owns the
simulation, legal choices and fallback navigation. The strategy runs in a
replaceable Web Worker and supplies bounded intentions and upgrade preferences.

After an ordinary browser build has generated the Bend types, rebuild only the
strategy from the repository root:

```sh
node tools/survivors-bot/build-stream-strategy.mts \
  examples/survivors/stream-strategy.mts \
  examples/survivors/dist/web/stream-strategy.json
```

Then click **Reload strategy** in the operator window. The default manifest is
`./stream-strategy.json`; a different manifest can be selected in the control
panel or with the `strategy` URL option. The builder checks and bundles the
module before replacing its manifest. A failed replacement leaves the working
strategy active; a failed active strategy visibly falls back to Bend. Reloading
a strategy does not restart the world or replay the character announcement.

## Character announcement

Each successfully started run shows **NOW PLAYING**, the actual character's
name and title, its enlarged current sprite, and the run number. The other six
survivors stand behind the current survivor as a borderless group. This is the
roster in cyclic order after the active survivor. After six
seconds the card becomes a compact identity badge. The character comes from
the authoritative game frame after startup, not from a preset label or editable
strategy text. Stopping the stream hides the card. The presentation does not
pause combat or create another simulation.

The announcement is inside the game picture, so it is captured with the game.
Twitch receives the encoded video from software such as OBS; the card needs no
Twitch Extension or chat command. This is an integration inference from the
[Twitch broadcasting pipeline](https://dev.twitch.tv/docs/video-broadcast/).
An independent OBS [Browser Source](https://obsproject.com/kb/browser-source)
could also render graphics, but would require a separate current-run data
channel. The in-game card keeps portrait and name tied to the captured run.

## Capture the game in OBS

1. Add a **macOS Screen Capture** source.
2. Choose **Window Capture** and select the game browser window, not the operator
   window or the whole display.
3. Frame/crop the source to the game content if browser chrome is visible.
4. Hide the cursor if desired and confirm that the operator controls are outside
   the broadcast picture.
5. Check a run transition, the large card becoming compact, sound, and the result
   after switching to the workspace where you intend to work.

The official [macOS Screen Capture guide](https://obsproject.com/kb/macos-screen-capture-source)
documents single-window capture and the option to show fullscreen/hidden windows
in the source list. That option does not establish that the game continues
rendering while hidden. Grant macOS screen-recording permission and restart OBS
if macOS requests it. Configure Twitch in OBS and start broadcasting there when
ready; these launchers never start a broadcast themselves.

## Native fallback

`Start Stream Bot.command` and `stream-macos.sh` launch the older native bot,
not the browser strategy session. It opens `B.T.S: Beat That Swarm - Survivors`, replaces
finished runs inside that same window and prevents idle system/display sleep.
Its `fresh` preset plays Grove Scribe; `advanced` plays Ash Pianist. It uses the
Bend policy directly, has no JavaScript strategy control window and currently
has no normal game audio session. A crash restart creates a new native window.

From the repository root on the Mac:

```sh
bash tools/survivors-bot/stream-macos.sh start
bash tools/survivors-bot/stream-macos.sh status
bash tools/survivors-bot/stream-macos.sh stop
```

Use `install` to start the native mode now and after graphical login; use
`uninstall` to stop it and remove login startup. Remain logged in; closing a
laptop lid may suspend the Mac. The log is
`~/Library/Application Support/Nightfall Stream Bot/last-launch.log`. Each
process launch replaces it; a healthy process's output is not size-capped.

## Verification limits

The built browser artifact passed a local Chromium interaction check covering detached
controls, Start from the game window, advancing ticks, Pause, Resume, strategy
reload without a world restart, and restoring controls after user-close. A second
detach and Stop passed. The check selected Hearth Voyager and verified the actual
character announcement, its compact transition, running audio, unchanged player
profile, ordinary player mode, and no browser exceptions. Controlled death fixtures
exercise a full seven-transition roster cycle, including Gilt Hare wrapping to
Grove Scribe, matching card identities and cyclic supporters after every restart.

`check-background-stream.mts` suppresses animation-frame callbacks while simulating a
hidden document. It verifies continued stream ticks, preserved operator pause,
repeated clock handoffs, and ordinary-player automatic pause. This isolates the
application behavior; it does not qualify target-Mac timer throttling or OBS
capture of a minimized window. Run it against the same private preview:

```sh
node tools/survivors-bot/check-background-stream.mts http://127.0.0.1:8812/
```

The session check passed 34 laws and 28 literal scenarios, with semantic mutants
rejected. The compiled observation and preference behavior checks passed.
`preference-PROOF.bend --verdict` remains unverified because BendTT reports
out-of-scope imported ECS templates. Runtime checks do not establish that proof.

Run the browser interaction check against a running private preview:

```sh
node tools/survivors-bot/check-browser-stream.mts https://your-private-host:9443/
```

The check uses a fresh browser context and unlocks Hearth Voyager only inside
that context. It writes its screenshot to the system temporary directory.
`STREAM_CHECK_CAPTURE` overrides that path. `PLAYWRIGHT_CHROMIUM_EXECUTABLE`
selects an existing Chromium executable instead of Playwright's installed one.

A cold Chromium load through the current Mac HTTPS server returned HTTP 502 for
some ES modules. The same address loaded with HTTP/2 disabled. The launcher now
uses `serve-private.py` with an explicit 128-connection accept queue instead of
Python's default server settings. Its local 110-request concurrency check passed.
Restart the existing Mac launcher to use the new backend. The queue change is a
candidate fix; its behavior behind the target Tailscale proxy remains unverified.

Target-Mac OBS capture, hidden-window behavior and 24-hour continuous operation
remain unverified. Browser throttling and operating-system sleep remain external limits.

The older native lifecycle passed a Linux GUI check that exercised 99 world
replacements in one unchanged window ID, plus a clean close after replacements.
Launcher fixtures covered stream options and Mac service setup. These checks
establish native lifecycle behavior, not full-run survival or browser uptime.
