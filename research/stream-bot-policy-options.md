# Optional hot-reload strategy for a native stream bot

Research date: 2026-10-26. This is a design recommendation, not an implemented integration or a performance result.

## Recommendation

Use an **optional Node.js JavaScript/TypeScript sidecar** for the visible, continuously running stream bot. Keep the existing Bend policy as the fallback and retain the fully native headless and visible launch paths. The stream mode can add readable decision explanations, deliberate upgrade-selection pauses and automatic restart between runs without making those presentation choices part of the fast simulation path.

This is an architectural recommendation: the current [bot documentation](../tools/survivors-bot/README.md) says movement, XP planning, memory and upgrade selection remain in the native process, with no external controller. The proposed optional stream mode would introduce a new, deliberately narrow boundary. It does not reverse that arrangement for ordinary bots or headless batches.

## Viable options

| Option | Why use it | Cost and reload model | Fit here |
| --- | --- | --- | --- |
| Node.js JS/TS sidecar | Convenient editable scripts, familiar development tools, separate failure domain from native game | Optional extra runtime; bounded IPC; replace the strategy worker or entire sidecar process | Recommended first experiment |
| QuickJS embedded through native C bindings | JavaScript in the native executable without Node | Own bindings, allocation, exceptions and runtime lifecycle; replace the isolated runtime/context and explicitly migrate state | Best alternative when a single executable matters more than Node tooling |
| Embedded Lua | Small C embedding API designed for host-controlled scripting | Different policy language; own bindings, allocator, instruction budget and state lifecycle | Viable if Lua is preferred; no requirement here makes it preferable to JS |

Node provides asynchronous child-process creation and pipes; its built-in Node-to-Node IPC is not automatically a protocol for a Bend executable. A native host would need an explicit pipe or local-socket protocol. A whole sidecar process offers a stronger separation from the native game than an embedded interpreter. See [Node child processes](https://nodejs.org/api/child_process.html).

QuickJS is an embeddable JavaScript engine with a C API, rather than the Node runtime. Its documented runtime memory limit, stack limit and interrupt callback support bounded strategy execution. A runtime owns its object heap; contexts provide separate globals within a runtime. Recommendation: use a separate strategy runtime and recycle it on reload, releasing all retained values. Replacing source or context does not automatically migrate the previous strategy's closures or memory. Do not assume Node modules or TypeScript execution are available; feed supported JavaScript, compiling TypeScript separately if desired. See [QuickJS embedding and limits](https://bellard.org/quickjs/quickjs.html#QuickJS-C-API).

Lua exposes host-callable functions, independent states, a custom allocator and instruction-count hooks. Its `require` caches modules in `package.loaded`; loading a changed file is not automatic state migration. Recommendation: replace a strategy state and import an explicit memory record, rather than trying to update arbitrary closures in place. The host must implement allocation accounting and execution budgets; hooks do not preempt arbitrary blocking native bindings. See [Lua 5.4 manual](https://www.lua.org/manual/5.4/manual.html), especially `lua_newstate`, `lua_sethook` and `require`.

Lisp and Elixir are not shortlisted: neither is required by the requested editable strategy interface, and adopting another language/runtime adds work without a demonstrated advantage for this bounded decision service. This is a scope judgment, not a language-performance comparison.

## Boundary that preserves native performance and authority

The following are proposed constraints, not existing features:

1. **Bend owns the world.** Physics, combat, RNG, legal upgrades, progression, game time and persistence remain native. Scripts return requested input/upgrade choices and a short explanation; Bend validates and applies them.
2. **Observe at decision cadence.** Start with a configurable modest cadence, then measure it. Export a bounded typed record: run/decision ID, player status, nearby threat/XP summaries, legal offered upgrades and bounded policy memory. Never serialize the whole ECS world every simulation tick. Bound collection sizes and total message bytes.
3. **Keep rendering independent.** Poll nonblocking IPC at native frame/decision boundaries. Permit at most one pending decision and coalesce superseded observations. Give responses a generation, run and decision ID, plus expiry; discard stale results.
4. **Make pauses visible and bounded.** During an existing upgrade pause, a native presentation state can show offers, highlight a recommendation and delay confirmation. Rendering and event polling continue. Use wall-clock deadlines, not simulation ticks, since the upgrade pause stops game time. Do not stop active combat to wait for strategic advice. A deadline selects a legal fallback if the script stalls.
5. **Handle strategy failure locally.** On timeout, malformed output, disconnection or invalid choice, use the native policy for that decision and keep the window responsive. Restart with backoff; expose the active strategy version and fallback/reload status in the overlay.

## Reload and 24/7 lifecycle

Node ES modules are cached by URL. Different query strings load separate instances, while `require.cache` does not control the ESM cache. Therefore repeatedly importing `strategy.mjs?generation=N` into a permanent supervisor is not the proposed long-running reload mechanism: it creates distinct module identities without providing a lifecycle for old generations. See [Node ESM URL caching](https://nodejs.org/api/esm.html#urls) and [its separate cache](https://nodejs.org/api/esm.html#no-requirecache).

Instead, keep a small supervisor and create a fresh worker for each candidate strategy generation. Load and validate it, run a bounded smoke decision, then atomically select the new generation at a decision boundary. Keep the old generation on validation failure. Pass only versioned plain-data policy memory, bounded by the protocol; incompatible memory resets explicitly. Terminate the old worker after the switch. Periodically recycle healthy workers as well, cap logs and queues, and monitor sidecar resident memory. Escalate to a full sidecar restart when needed.

Node worker termination is asynchronous; it completes when the exit event arrives. Worker resource limits constrain the JS engine, exclude external allocations such as ArrayBuffers, and do not prevent global process out-of-memory aborts. Consequently they supplement bounded messages and process supervision rather than guaranteeing a total RSS cap. See [Node worker limits and termination](https://nodejs.org/api/worker_threads.html).

Use a pinned supported Node version. Built-in TypeScript support strips erasable types without type checking and ignores `tsconfig.json`; full TypeScript features need a separate toolchain. Prefer plain JS initially, or restricted TS with an independent type-check step. See [Node TypeScript support](https://nodejs.org/api/typescript.html#type-stripping).

Watch the strategy directory, debounce editor writes and compare a content hash before preparing a candidate; also provide explicit reload and a periodic hash check. File watching has platform/filesystem caveats, including inode behavior after replacement, so it should be a notification aid rather than the source of truth. See [Node file-watching caveats](https://nodejs.org/api/fs.html#caveats).

## Current integration gaps

`bot-driver.bend` directly calls the native policy and immediately applies the result. There is no runtime policy interface yet. `bot-window-single.bend` recreates initial UI state on each draw, and native offer rows have no recommendation index. A stream session needs persistent presentation state and explicit offer highlighting. Existing bot windows stop at the end of a run and do not use the human native client's persistent audio Session. Automatic restart, run transitions and normal game audio must therefore be integrated explicitly.

The recommended structure separates game authority, native steering, replaceable strategy and a stream presentation state machine. For human-readable play, expose visible threats and remembered discoveries rather than hidden whole-world knowledge. Strategy cadence and upgrade dwell should be configurable. Quick evasive reactions can interrupt a longer-lived travel goal; adding a blind delay to every action would make the bot frustrating to watch. These are proposed design choices, not measured properties.

## What an implementation would need to establish

First prove the experience with one visible native game: edit a strategy while it runs, see the new version activate, watch a readable upgrade pause and recover from a deliberate loop or exception without freezing the window. Then soak-test repeated reloads, disconnections, stale replies and automatic new runs while tracking memory and log growth. Separately verify that the existing native headless entrypoints still launch without Node and retain their existing execution path. No latency, throughput or 24/7 reliability claim is established by this research.
