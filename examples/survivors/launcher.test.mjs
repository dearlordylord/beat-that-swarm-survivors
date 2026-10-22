import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { createServer } from "node:net";
import { readFile, stat } from "node:fs/promises";
import { fileURLToPath } from "node:url";
const app = new URL("./", import.meta.url);
const probe = createServer();
await new Promise((resolve) => probe.listen(0, "127.0.0.1", resolve));
const port = probe.address().port;
await new Promise((resolve) => probe.close(resolve));
const url = `http://127.0.0.1:${port}`;
const children = [];
function launch(env = {}) {
  const child = spawn(
    process.execPath,
    [
      fileURLToPath(new URL("launch.mjs", app)),
      "--no-open",
      "--port",
      String(port),
    ],
    {
      cwd: "/tmp",
      env: { ...process.env, ...env },
      stdio: ["ignore", "pipe", "pipe"],
    },
  );
  child.output = "";
  for (const stream of [child.stdout, child.stderr])
    stream.on("data", (data) => (child.output += data));
  child.done = new Promise((resolve) =>
    child.once("close", (code) => resolve(code)),
  );
  children.push(child);
  return child;
}
async function ready(child, previous) {
  const deadline = Date.now() + 12000;
  while (Date.now() < deadline) {
    if (child.exitCode !== null) throw Error(child.output);
    try {
      const value = await (
        await fetch(url + "/__nightfall", { signal: AbortSignal.timeout(300) })
      ).json();
      if (value.instance !== previous) return value;
    } catch {}
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw Error("Launcher readiness timeout: " + child.output);
}
try {
  const first = launch();
  const initial = await ready(first);
  for (const name of [
    "index.html",
    "style.css",
    "browser.mjs",
    "renderer.mjs",
    "content.mjs",
    "audio.mjs",
    "progression.mjs",
    "dist/game.mjs",
  ]) {
    const response = await fetch(url + "/" + name);
    assert.equal(response.status, 200, name);
    assert.equal(response.headers.get("cache-control"), "no-store");
    assert.match(
      response.headers.get("content-type"),
      name.endsWith(".mjs")
        ? /text\/javascript/
        : name.endsWith(".css")
          ? /text\/css/
          : /text\/html/,
    );
    assert.equal(
      await response.text(),
      await readFile(new URL(name, app), "utf8"),
      name,
    );
  }
  const before = (await stat(new URL("dist/game.mjs", app))).mtimeMs;
  const second = launch();
  const replacement = await ready(second, initial.instance);
  assert.equal(await first.done, 0);
  assert.ok((await stat(new URL("dist/game.mjs", app))).mtimeMs > before);
  const compiled = await readFile(new URL("dist/game.mjs", app), "utf8");
  const failed = launch({ BEND: "/nonexistent/nightfall-bend" });
  assert.notEqual(await failed.done, 0);
  assert.equal(await readFile(new URL("dist/game.mjs", app), "utf8"), compiled);
  assert.equal(
    (await (await fetch(url + "/__nightfall")).json()).instance,
    replacement.instance,
  );
  assert.equal((await fetch(url + "/../package.json")).status, 404);
  console.log(
    "Launcher passed: rebuild, assets, restart, failed-build preservation, cwd independence.",
  );
} finally {
  for (const child of children)
    if (child.exitCode === null) child.kill("SIGTERM");
  await Promise.all(children.map((child) => child.done));
}
