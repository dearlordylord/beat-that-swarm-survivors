# Verification failure diagnostics

The first CI attempt for Survivors PR 12 printed `FAIL` for
`native-record/PROOF.bend` without the child status or diagnostic output.
The wrapper continued and reported 55/56 proof files passed. Its explicit
60-second wall-timeout message was absent. The same commit subsequently passed
the complete CI job without changes. The first failure's exit code and signal
were not recorded, so its cause cannot be recovered from that log.

A controlled reproduction established the logging defect. A child killed with
`SIGKILL` returned -9, but the original proof wrapper printed only `FAIL` and an
empty line. This reproduction does not establish what killed the first CI run.

## Failure contract

Verification boundaries retain the command, working directory, exit status,
signal, configured limits, elapsed time and available output or output-file
paths. A wall timeout, spawn failure and ordinary nonzero exit are distinct.
`SIGKILL` identifies the signal; it does not establish a CPU limit, an OOM kill
or an external cancellation as its cause.

Python checks share `scripts/process_diagnostics.py`. Normal termination is not
success: a positive check still requires its expected exit code and verdict.
Negative controls require their intended refusal status and diagnostic, rather
than accepting a timeout, signal or missing executable as equivalent evidence.
Owned child process groups are cleaned up on timeout or cancellation.

Existing resource limits and proof obligations are preserved. Successful
measurement timing excludes failure-diagnostic collection. Successful quiet
commands remain quiet; failed quiet commands retain both output streams.

## Audited boundaries

| Boundary | Failure handling |
| --- | --- |
| Proof and semantic-mutant runners | Shared process result; explicit status, signal, timeout and expected-verdict checks. |
| ABI, cache, birth-wiring and capability checks | Captured compiler output and process outcome retained; infrastructure failures cannot satisfy semantic refusals. |
| Shared shell/Node executor | Child status and signal reported alongside command; actual timeout remains distinct from a child's own exit 124. |
| Source fingerprints and native cache probes | Failed find/hash/key commands propagate as command failures, rather than successful fingerprints or changed-input reports. |
| Native batch, parallel comparison and measurement | Failure receipts identify child outcomes and retained diagnostics. |
| Visible native controller | Underlying spawn/controller errors are preserved in stderr and receipts. |
| Quiet publication commands | Failed command context and both streams are preserved; publication is not exercised by fault tests. |

The audit covered maintained verification/build runners under `scripts`,
`examples` and `tools`. Vendored dependencies and generated outputs were not
edited. Intentional Git-version fallback, existing file-backed replay/Metal
diagnostics and inherited child output remain in place.

## Regression checks

After installing the normal development dependencies and generating the
current TypeScript declarations, run:

```sh
python3 -B scripts/test-process-diagnostics.py
python3 -B scripts/test-python-verification-diagnostics.py
python3 -B tools/survivors-bot/verification-diagnostics.test.py
python3 -B tools/survivors-bot/replay_measure_test.py
node --test scripts/verification-diagnostics.test.mts
bash tools/survivors-bot/native-batch.test.sh
```

CI runs these commands after the normal TypeScript gate. The suite uses controlled
child programs to exercise nonzero exits, signals, partial output on timeout,
spawn failures, missing verdicts, cancellation and descendant cleanup. It also
checks that unrelated infrastructure failures cannot pass negative controls.
It does not run a game, browser session or performance benchmark. Ordinary
proof and functional gates remain separate and enabled.
