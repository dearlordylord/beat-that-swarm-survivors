// Portable check timeout, including compiler descendants. No npm dependencies.
import { spawn } from 'node:child_process';
import { constants } from 'node:os';
const [seconds, command, ...args] = process.argv.slice(2);
if (!command || !Number.isFinite(Number(seconds)) || !(Number(seconds) > 0))
  throw Error('Usage: run-bounded.mjs SECONDS COMMAND [ARGS...]');
const child = spawn(command, args, { stdio: 'inherit', detached: process.platform !== 'win32' });
let timedOut = false, requestedSignal, escalation;
function stop(signal) {
  if (!child.pid) return;
  try {
    if (process.platform === 'win32') child.kill(signal);
    else process.kill(-child.pid, signal);
  } catch (error) {
    if (error.code !== 'ESRCH') throw error;
  }
}
const timer = setTimeout(() => {
  timedOut = true;
  console.error(`Check exceeded ${seconds} seconds: ${command}`);
  stop('SIGKILL');
}, Number(seconds) * 1000);
function clearTimers() { clearTimeout(timer); clearTimeout(escalation); }
child.once('error', error => { clearTimers(); console.error(error.message); process.exitCode = 1; });
child.once('exit', (code, signal) => {
  clearTimers();
  if (requestedSignal) stop('SIGKILL'); // Also stop descendants that ignored the forwarded signal.
  process.exitCode = timedOut ? 124 : requestedSignal ? 128 + constants.signals[requestedSignal] : code ?? (signal ? 128 + constants.signals[signal] : 1);
});
for (const signal of ['SIGINT', 'SIGTERM']) process.once(signal, () => {
  requestedSignal = signal;
  stop(signal);
  escalation = setTimeout(() => stop('SIGKILL'), 1000);
});
