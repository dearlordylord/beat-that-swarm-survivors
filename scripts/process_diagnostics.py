"""Capture subprocess outcomes without treating process failures as check evidence."""
from dataclasses import dataclass
from pathlib import Path
import os
import resource
import shlex
import signal
import subprocess
import time
from typing import Mapping, Sequence


@dataclass(frozen=True)
class RunResult:
    command: tuple[str, ...]
    cwd: str
    wall_timeout_seconds: float | None
    cpu_limit_seconds: int | None
    elapsed_wall_seconds: float
    returncode: int | None
    wall_timed_out: bool
    spawn_error: str | None
    stdout: str
    stderr: str

    @property
    def normal_exit(self):
        return (not self.wall_timed_out and self.spawn_error is None
                and self.returncode is not None and self.returncode >= 0)

    @property
    def signal_name(self):
        if self.returncode is None or self.returncode >= 0:
            return None
        try:
            return signal.Signals(-self.returncode).name
        except ValueError:
            return f'SIGNAL_{-self.returncode}'

    @property
    def output(self):
        return self.stdout + self.stderr

    @property
    def classification(self):
        if self.spawn_error is not None:
            return 'spawn-failure'
        if self.wall_timed_out:
            return 'wall-timeout'
        if self.returncode is not None and self.returncode < 0:
            return 'signal'
        return 'zero-exit' if self.returncode == 0 else 'nonzero-exit'


def run_process(command: Sequence[str | Path], *, cwd: Path | None = None,
                env: Mapping[str, str] | None = None,
                wall_timeout_seconds: float | None = None,
                cpu_limit_seconds: int | None = None):
    argv = tuple(map(str, command))
    location = str((cwd or Path.cwd()).resolve())
    started = time.monotonic()

    def bounded():
        resource.setrlimit(resource.RLIMIT_CPU, (cpu_limit_seconds, cpu_limit_seconds))

    try:
        child = subprocess.Popen(argv, cwd=location, env=env,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                 text=True, encoding='utf-8', errors='replace',
                                 start_new_session=True,
                                 preexec_fn=bounded if cpu_limit_seconds is not None else None)
    except (OSError, subprocess.SubprocessError) as failure:
        return RunResult(argv, location, wall_timeout_seconds, cpu_limit_seconds,
                         time.monotonic() - started, None, False,
                         f'{type(failure).__name__}: {failure}', '', '')

    def stop_owned_group():
        # This session belongs to this invocation, including its compiler/kernel children.
        try:
            os.killpg(child.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        return child.communicate()

    timed_out = False
    try:
        try:
            stdout, stderr = child.communicate(timeout=wall_timeout_seconds)
        except subprocess.TimeoutExpired:
            timed_out = True
            stdout, stderr = stop_owned_group()
    except BaseException as cancellation:
        try:
            stop_owned_group()
        except BaseException as cleanup_error:
            cancellation.add_note(f'Owned process cleanup failed: {cleanup_error}')
        raise
    return RunResult(argv, location, wall_timeout_seconds, cpu_limit_seconds,
                     time.monotonic() - started, child.returncode, timed_out, None, stdout, stderr)


def format_failure(result: RunResult, reason: str):
    signum = -result.returncode if result.returncode is not None and result.returncode < 0 else None
    cpu = f'{result.cpu_limit_seconds}s' if result.cpu_limit_seconds is not None else 'not configured'
    wall = f'{result.wall_timeout_seconds:g}s' if result.wall_timeout_seconds is not None else 'not configured'
    return '\n'.join([
        f'check failure: {reason}',
        f'classification: {result.classification}',
        f'command: {shlex.join(result.command)}',
        f'cwd: {result.cwd}',
        f'exit code: {result.returncode if result.returncode is not None else "unavailable"}',
        f'signal: {result.signal_name or "none"}' + (f' ({signum})' if signum is not None else ''),
        f'wall timeout: {str(result.wall_timed_out).lower()}',
        f'budgets: CPU {cpu}; wall {wall}',
        f'elapsed wall: {result.elapsed_wall_seconds:.3f}s',
        *([f'spawn error: {result.spawn_error}'] if result.spawn_error else []),
        'child stdout:', result.stdout or '(empty)',
        'child stderr:', result.stderr or '(empty)',
    ])
