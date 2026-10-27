# Run the native bot on a Mac for OBS

The stream bot opens its own native game window named `Beat That Swarm: Survivors`.
Each completed run starts a new world inside that same window, with a new seed.
OBS keeps the same window across normal run transitions. A process crash creates
another window when macOS restarts the bot.

## Start the window

1. Open this checkout on your Mac. Install Bend and the [native compiler toolchain](../../toolchains/README.md).
2. Open `tools/survivors-bot/Start Stream Bot.command` in Finder.
3. Wait for the native Mac build. The first build can take several minutes.
4. Keep your Mac connected to power and remain logged in.

The launcher verifies the native build on the Mac. It does not use a Docker Linux
executable. Once the window opens, you can close the launcher's Terminal window.
The bot stays active in your desktop session and prevents idle display and
system sleep while it runs. Closing a laptop lid can still suspend the Mac.

The current preset is `fresh`, which plays Grove Scribe. The existing `advanced`
preset plays Ash Pianist with its qualification upgrades. These presets do not
rotate through all seven characters or advance your human player profile.
The stream window does not currently provide the normal native game's audio
session. Do not expect game audio from this bot mode.

## Capture only the game in OBS

1. Add a **macOS Screen Capture** source in OBS.
2. Select **Window Capture** as its capture method.
3. Select the window named `Beat That Swarm: Survivors`.
4. Hide the cursor in the source settings if you do not want it in the broadcast.
5. Confirm that the OBS preview contains the game window.

Use a window source so other applications are outside the captured picture.
On recent macOS versions, OBS uses **macOS Screen Capture** rather than the older
Window Capture source. See the [OBS source guide](https://obsproject.com/kb/macos-screen-capture-source).
If macOS requests screen-recording permission for OBS, grant it in System Settings
and restart OBS as instructed by macOS. Configure your Twitch account in OBS and
start broadcasting there when you are ready. These launchers do not start a broadcast.

## Stop or inspect the bot

Open `tools/survivors-bot/Stop Stream Bot.command` to stop the service. Closing
the game window or pressing Escape also stops normal play. macOS restarts the
process after a failure. Launch frequency is throttled to one launch per 60 seconds.

From the repository root, inspect the service with:

```sh
bash tools/survivors-bot/stream-macos.sh status
```

The latest process launch writes to
`~/Library/Application Support/Nightfall Stream Bot/last-launch.log`.
Each process launch replaces that log. It contains native build and bot output;
there is no accumulated archive of past process launches. Output from one healthy
continuous process is not size-capped.

## Start after login

Run this command on the Mac to install a user login agent and start it now:

```sh
bash tools/survivors-bot/stream-macos.sh install
```

The agent runs only in your logged-in graphical session. It does not run a visible
window before login. Move the checkout only after uninstalling the agent, then
install it again from its new location.

`stop` stops the current service but leaves login startup installed. To stop it
and remove login startup, run:

```sh
bash tools/survivors-bot/stream-macos.sh uninstall
```

## Run a bounded check

To check several run transitions without leaving a service running:

```sh
bash tools/survivors-bot/visible.sh --stream --ticks 30 --seconds 10
```

In stream mode, `--ticks` bounds each individual run. `--seconds` bounds the whole
session. Zero means no bound. The stream mode uses one window at realtime pace.
Closing the window ends the session instead of starting another world.

The native lifecycle is checked in the development environment. The launchd
commands and OBS capture require verification on the target Mac. This setup has
not established a 24-hour soak-test result.

## Development verification

The native Linux build passed. An eight-second GUI check used a three-tick
per-run bound to exercise 99 world replacements in one unchanged window ID,
with the exact title `Beat That Swarm: Survivors`. A separate GUI check closed
the stream window after multiple replacements and confirmed exit status zero.
An ordinary single-bot window retained its existing bounded exit behavior.
These accelerated transitions test lifecycle behavior, not complete-run survival.

The visible-launcher fixture passed, including stream environment forwarding
and rejection of grid/unlimited combinations. Mac setup fixtures covered
start, stop, login installation/removal, build failures and XML-escaped paths.
Independent review found no remaining actionable lifecycle defects. One redundant
comment was removed; the documentation records the log-size and target-Mac
verification limits above.
