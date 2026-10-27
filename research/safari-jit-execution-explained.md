# Why disabling JIT made the iPhone preview unplayable

## What this incident establishes

The player reported about one displayed frame per second on iPhone Safari over
the private HTTP address. The diagnostic attributed almost all callback time to
simulation advance; freezing simulation restored FPS. The original game also
ran slowly at that HTTP origin. The same mod build ran smoothly after moving
the preview to private Tailscale HTTPS. These are observations reported by the
player, not an instrumented measurement of the phone's compiler tiers.

The explanation is strongly supported by WebKit's documented behavior: its
developers confirmed that iOS 27 Enhanced Security applies hardening policies
to plaintext HTTP navigations, including the JIT restriction described in the
report. The report also documents a same-device HTTP/HTTPS performance gap
without warming up to the faster tier over HTTP. This is a browser policy,
not a claim that HTTP inherently executes arithmetic more slowly.
[WebKit issue 324968, comments 1 and 3](https://bugs.webkit.org/show_bug.cgi?id=324968#c3).

Our conclusion should remain precise: HTTPS resolved this incident; JIT
suppression is the supported mechanism, but JIT status was not directly observed
on the affected phone. We did not establish that every Safari version or every
HTTP page follows the same policy.

## Compilation is more than one operation

This project's browser path is:

```text
Bend source
  -> generated JavaScript (.mjs)
  -> JavaScriptCore bytecode
  -> interpreter execution OR JIT-generated CPU instructions
```

Compiling Bend to JavaScript does not produce the final CPU instructions.
Bundling or minifying that JavaScript does not do so either. The browser still
has to execute the resulting JavaScript program.

JavaScriptCore parses JavaScript and produces bytecode. It can interpret this
bytecode or compile it into machine code. Bytecode remains the common input to
the engine's execution tiers. Therefore, “the script was compiled already” may
mean bytecode exists, without implying that machine code for the application
exists. [WebKit: A New Bytecode Format for JavaScriptCore](https://webkit.org/blog/9329/a-new-bytecode-format-for-javascriptcore/).

The interpreter itself is compiled machine code supplied with the browser. It
repeatedly reads application bytecode and performs the requested operations.
It is the application that is being interpreted; the CPU is still executing
native instructions inside the interpreter.

Ahead-of-time (AOT) native compilation generates application machine code before
the application runs. JIT generates application machine code during execution.
Neither definition promises a fixed speed ratio. Both differ from executing
application bytecode through an interpreter. Apple describes JIT as translating
intermediate script code or bytecode into executable machine instructions.
[Apple: Porting just-in-time compilers to Apple silicon](https://developer.apple.com/documentation/Apple-Silicon/porting-just-in-time-compilers-to-apple-silicon).

## Why waiting does not fix a disabled JIT

With normal tiering, JavaScriptCore can move a hot function from LLInt, its
interpreter, through Baseline JIT to the optimizing DFG and FTL JITs. This trades
initial compilation work for higher throughput. Functions can occupy different
tiers simultaneously. [WebKit: JavaScriptCore](https://docs.webkit.org/Deep%20Dive/JSC/JavaScriptCore.html).

With JIT disabled, that transition is unavailable. “Not compiled yet” and
“not permitted to compile” are different states. Running a function another
million times cannot override the restriction. WebKit's debugging documentation
explicitly identifies `JSC_useJIT=false` as disabling all three JIT tiers and
leaving LLInt enabled. This is also the flag used in our local reproduction.
[WebKit: JavaScriptCore CSI](https://webkit.org/blog/6411/javascriptcore-csi-a-crash-site-investigation-story/).

Interpreter caches can still improve execution. That is not equivalent to
eventually enabling a prohibited compiler. Nor does stable cost per operation
imply stable frame time when the number of enemies or simulation steps grows.

## Why the difference can be large

Even Baseline JIT removes repeated interpreter opcode dispatch and uses stronger
inline caching. Optimizing JITs additionally specialize operations using observed
types and object shapes, eliminate redundant checks, and optimize across
operations. Incorrect assumptions cause a safe exit to less optimized execution.
These changes can affect every iteration of a hot loop, rather than merely
saving the one-time cost of parsing the script.
[WebKit: Speculation in JavaScriptCore](https://webkit.org/blog/10308/speculation-in-javascriptcore/).

For example, reading `enemy.spatial.x` and adding a velocity can require several
dynamic operations. With suitable proven or guarded assumptions, a compiler can
turn the common case into direct field loads and numeric instructions. This is
an explanation of an available optimization, not a disassembly of our game's
actual optimized code. Allocation elimination is also conditional; we have not
shown which game objects, if any, were eliminated by JIT.

The generated game uses tagged JavaScript objects, linked list nodes, many
function calls, field reads and newly constructed state records. Concrete
examples in the current local generated artifact are `run_loop` / `run_lib`
around lines 151–160 and `$prepared_projectile` around line 12545. These artifacts
are ignored build output and line numbers change on rebuild. Their source
counterparts include [`prepared_projectile`](../examples/survivors/game.bend)
and the `State`, snapshot and projectile data types in that file. JIT has many
opportunities in such code; that is a plausible explanation for sensitivity,
not a quantified allocation/type-check breakdown from a profile.

Existing local simulation runs support the magnitude. For the mod, five
repetitions of the same 60-tick scenario had median advance time
514 ms with normal JIT settings versus 6,066 ms with `JSC_useJIT=false`, about
11.8 times slower. Ranges were 484–539 ms and 5,950–6,276 ms respectively.
The original also showed a large gap. These were Linux WebKit runs, not iPhone
benchmarks: character 0, seed 12345, 30 warmup ticks, then ticks 30–90 with
rightward input. End tick 90 was verified; the harness did not verify an exact
observation digest. Raw scripts and logs are outside tracked source in the
shared `survivors-performance-report` directory. This is supporting evidence,
not proof that the phone experienced exactly an 11.8-fold slowdown.

A third diagnostic batch disabled DFG and FTL while retaining Baseline JIT:
`JSC_useDFGJIT=false JSC_useFTLJIT=false`. The mod's median was 2,586 ms,
range 2,575–2,705 ms over five repetitions. This separates a roughly 2.3-fold
interpreter-to-Baseline gain from a further roughly 5-fold gain with normal
optimizing tiers in this workload. It does not identify which individual
optimizations account for that second gain. The original's medians were
6,001 ms, 2,541 ms and 488 ms for interpreter, Baseline-only and normal settings.
The options and environment-variable mechanism are documented in
[JavaScriptCore OptionsList.h](https://github.com/WebKit/WebKit/blob/main/Source/JavaScriptCore/runtime/OptionsList.h).

Original/mod order alternated within each mode's batch; the three execution
modes ran in separate batches, not interleaved. These results are diagnostic
evidence for a large tier effect, not a tightly controlled production speedup
claim. A precise tier comparison should interleave fresh processes across modes
and verify matching final observation digests as well as end ticks.

## Why a slowdown becomes visible freezing

The browser loop targets 60 simulation ticks per second: a 16.7 ms budget per
tick before rendering. It accumulates elapsed time and advances multiple times
before drawing when behind. See `STEP` and `animation` in
[`browser.mts`](../examples/survivors/browser.mts).

An illustrative 8 ms tick fits that budget. A 100 ms tick does not. Once behind,
the loop can execute about six such ticks before drawing because its elapsed
time contribution is clamped to 100 ms. Six 100 ms steps consume roughly 600 ms
before the next picture, even if drawing is cheap. This arithmetic illustrates
the feedback mechanism; it is not a measured iPhone tick duration. The clamp
bounds catch-up work but does not make it fit a frame budget.

The diagnostic's `ADV` and `SIM` values originally accumulated all steps within
one animation callback. Therefore, an `ADV` of 300 ms must not be reported as
300 ms per tick. The updated panel also exposes steps per frame and ADV per step.

## Why a browser would impose this restriction

JIT compilation creates executable code at runtime and has additional security
requirements. Apple documents the need to write generated code and then execute
it, with memory protections separating writable and executable states. That
complexity creates security concerns that do not arise in the same form when
only the pre-existing interpreter executes application bytecode.
[Apple: Protecting code compiled just in time](https://developer.apple.com/documentation/browserenginekit/protecting-code-compiled-just-in-time).

The WebKit issue confirms the HTTP hardening decision; it should not be read as
proof that HTTPS content is intrinsically safe. For this project, private HTTPS
is the appropriate preview and performance-testing environment. No protection
settings needed to be disabled on the player's phone.
