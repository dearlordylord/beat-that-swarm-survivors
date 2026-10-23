#!/usr/bin/env python3
"""Run frozen native replay artifacts serially and compare complete observations.

This is a development correctness gate, never a performance measurement. Binaries
must already be built. Logs and unconditional terminal receipts live outside the
source checkout in a fresh --output-dir. No compiler/provider/network is invoked.
"""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import time

from replay_compare import compare, file_sha, ReplayError, trace_contract

def terminate(child):
    """Bound cleanup of the one owned native process group."""
    if child.poll() is not None:
        return
    try:
        os.killpg(child.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        child.wait(timeout=2)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(child.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        child.wait(timeout=2)

def run(binary, trace, fixture, prefix, seconds, threads):
    command = [str(binary), "+RTS", "--threads", str(threads), "-RTS"]
    env = {**os.environ, "NIGHTFALL_REPLAY_TRACE": str(trace), "NIGHTFALL_REPLAY_FIXTURE": fixture}
    env.pop("BENDRTS", None)
    started = time.monotonic()
    with prefix.with_suffix(".jsonl").open("wb") as stdout, prefix.with_suffix(".stderr").open("wb") as stderr:
        child = subprocess.Popen(command, env=env, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr, start_new_session=True)
        result = {"command": command, "trace": str(trace), "fixture": fixture, "status": "running"}
        try:
            code = child.wait(timeout=seconds)
            result.update(status="complete" if code == 0 else "failed", exitCode=code)
            if code != 0:
                raise ReplayError(f"Native replay exited {code}: {prefix}")
            return result
        except subprocess.TimeoutExpired as error:
            result["status"] = "timeout"
            raise ReplayError(f"Native replay exceeded {seconds:g}s: {prefix}") from error
        except BaseException:
            if result["status"] == "running":
                result["status"] = "interrupted"
            raise
        finally:
            terminate(child)
            result["terminalExitCode"] = child.returncode
            result["externalWallSeconds"] = time.monotonic() - started
            prefix.with_suffix(".process.json").write_text(json.dumps(result, indent=2) + "\n")

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", required=True, type=Path); parser.add_argument("--candidate", required=True, type=Path)
    parser.add_argument("--trace", required=True, action="append", type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--protect", action="append", default=[], type=Path)
    parser.add_argument("--timeout-seconds", type=float, default=90)
    parser.add_argument("--wall-seconds", type=float, default=600)
    parser.add_argument("--threads", type=int, default=1)
    args = parser.parse_args()
    if not 0 < args.timeout_seconds <= 900 or not 0 < args.wall_seconds <= 3600 or not 1 <= args.threads <= 128:
        parser.error("Invalid wall/thread bounds")
    args.baseline = args.baseline.resolve(strict=True); args.candidate = args.candidate.resolve(strict=True)
    if args.baseline == args.candidate:
        parser.error("Baseline and candidate must be distinct frozen artifacts")
    traces = [path.resolve(strict=True) for path in args.trace]
    paths = list(dict.fromkeys([args.baseline, args.candidate, *traces, Path(__file__).resolve(), Path(__file__).with_name("replay_compare.py").resolve(), *[p.resolve(strict=True) for p in args.protect]]))
    before = {str(path): file_sha(path) for path in paths}
    out = args.output_dir.resolve(); out.mkdir(parents=True, exist_ok=False)
    receipt = {"status": "running", "beforeSha256": before, "threads": args.threads,
               "scope": "Native gameplay and authoritative payload/metadata equivalence, not timing qualification.", "fixtures": []}
    (out / "source-before.json").write_text(json.dumps(before, indent=2) + "\n")
    deadline = time.monotonic() + args.wall_seconds
    def interrupted(_signum, _frame):
        raise KeyboardInterrupt("Replay check interrupted")
    prior = {sig: signal.signal(sig, interrupted) for sig in (signal.SIGINT, signal.SIGTERM)}
    try:
        for index, trace in enumerate(traces):
            contract = trace_contract(trace)
            fixture = contract["fixture"]
            item = {"fixture": fixture, "traceSha256": file_sha(trace)}; receipt["fixtures"].append(item)
            for label, binary in (("baseline", args.baseline), ("candidate", args.candidate)):
                seconds = min(args.timeout_seconds, deadline - time.monotonic())
                if seconds <= 0:
                    raise ReplayError("Overall replay check deadline reached")
                item[label] = run(binary, trace, fixture, out / f"{index}-{label}", seconds, args.threads)
            item["comparison"] = compare(out / f"{index}-baseline.jsonl", out / f"{index}-candidate.jsonl", trace=trace)
        receipt["status"] = "passed"
    except (Exception, KeyboardInterrupt) as error:
        receipt.update(status="failed", error=f"{type(error).__name__}: {error}")
    finally:
        for sig, handler in prior.items():
            signal.signal(sig, handler)
        try:
            after = {str(path): file_sha(path) for path in paths}
            receipt["afterSha256"] = after
            receipt["inputsStable"] = before == after
            if before != after:
                receipt.update(status="failed", error="Protected replay input changed")
        except OSError as error:
            receipt.update(status="failed", error=f"Input postguard failed: {error}")
        (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"status": receipt["status"], "receipt": str(out / "receipt.json")}))
    return 0 if receipt["status"] == "passed" else 1

if __name__ == "__main__":
    raise SystemExit(main())
