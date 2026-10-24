import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { createServer } from "node:net";
import { request } from "node:http";
import { copyFile, mkdtemp, mkdir, readFile, rm, writeFile, symlink } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

// Isolate launcher behavior from the Bend compiler and Astro's own build tests.
// The stub obeys the canonical build contract: atomically replace dist/web only
// after success, and keep both the previous output and server on build failure.
const fixture = await mkdtemp(path.join(tmpdir(), "survivors-launcher-"));
const app = path.join(fixture, "examples", "survivors");
await mkdir(app, { recursive: true });
await copyFile(new URL("./launch.mjs", import.meta.url), path.join(app, "launch.mjs"));
await writeFile(path.join(fixture, "private.txt"), "must not be served");
await writeFile(path.join(app, "build-web.sh"), `#!/usr/bin/env bash
set -euo pipefail
[[ "$PWD" == ${JSON.stringify(fixture)} ]]
if [[ \${NIGHTFALL_TEST_FAIL:-0} == 1 ]]; then exit 17; fi
app=${JSON.stringify(app)}
mkdir -p "$app/dist"
stage="$(mktemp -d "$app/dist/.web-XXXXXX")"
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/_astro" "$stage/dist" "$stage/guide"
printf '<!doctype html><title>Astro static menu</title><main>Mira</main>' > "$stage/index.html"
printf 'body{color:ivory}' > "$stage/_astro/menu.a1b2.css"
printf 'export const ready=true;' > "$stage/_astro/menu.c3d4.js"
printf 'export default {};' > "$stage/dist/game.mjs"
printf '<svg xmlns="http://www.w3.org/2000/svg"/>' > "$stage/favicon.svg"
printf '<h1>Guide</h1>' > "$stage/guide/index.html"
printf '%s' "\${NIGHTFALL_TEST_REVISION:-first}" > "$stage/revision.txt"
ln -s ${JSON.stringify(path.join(fixture, "private.txt"))} "$stage/leak.txt"
rm -rf "$app/dist/web"
mv "$stage" "$app/dist/web"
`);
const probe = createServer();
await new Promise((resolve) => probe.listen(0, "127.0.0.1", resolve));
const port = probe.address().port;
await new Promise((resolve) => probe.close(resolve));
const url = `http://127.0.0.1:${port}`;
const children = [];
function launch(env = {}, args = []) {
  const child = spawn(
    process.execPath,
    [path.join(app, "launch.mjs"), "--no-open", "--port", String(port), ...args],
    { cwd: tmpdir(), env: { ...process.env, ...env }, stdio: ["ignore", "pipe", "pipe"] },
  );
  child.output = "";
  for (const stream of [child.stdout, child.stderr])
    stream.on("data", (data) => (child.output += data));
  child.done = new Promise((resolve) => child.once("close", resolve));
  children.push(child);
  return child;
}
async function ready(child, previous) {
  const deadline = Date.now() + 12000;
  while (Date.now() < deadline) {
    if (child.exitCode !== null) throw Error(child.output);
    try {
      const value = await (await fetch(url + "/__nightfall", { signal: AbortSignal.timeout(300) })).json();
      if (value.instance !== previous) return value;
    } catch {}
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw Error("Launcher readiness timeout: " + child.output);
}
function rawStatus(pathname) {
  return new Promise((resolve, reject) => {
    const req = request({ hostname: "127.0.0.1", port, path: pathname }, (res) => {
      res.resume();
      res.on("end", () => resolve(res.statusCode));
    });
    req.on("error", reject);
    req.end();
  });
}
try {
  const help = launch({}, ["--help"]);
  assert.equal(await help.done, 0);
  assert.match(help.output, /Astro menu/);
  const invalid = launch({}, ["--port", "invalid"]);
  assert.notEqual(await invalid.done, 0);
  const first = launch();
  const initial = await ready(first);
  assert.equal(initial.root, app + path.sep);
  for (const [name, type] of [
    ["index.html", "text/html"],
    ["_astro/menu.a1b2.css", "text/css"],
    ["_astro/menu.c3d4.js", "text/javascript"],
    ["dist/game.mjs", "text/javascript"],
    ["favicon.svg", "image/svg+xml"],
    ["revision.txt", "text/plain"],
  ]) {
    const response = await fetch(url + "/" + name);
    assert.equal(response.status, 200, name);
    assert.equal(response.headers.get("cache-control"), "no-store");
    assert.ok(response.headers.get("content-type").startsWith(type), name);
    assert.equal(response.headers.get("x-content-type-options"), "nosniff");
    assert.equal(await response.text(), await readFile(path.join(app, "dist", "web", name), "utf8"), name);
  }
  assert.equal(await (await fetch(url + "/guide/")).text(), "<h1>Guide</h1>");
  assert.equal((await fetch(url + "/", { method: "HEAD" })).status, 200);
  assert.equal(await (await fetch(url + "/", { method: "HEAD" })).text(), "");
  assert.equal((await fetch(url + "/", { method: "POST" })).status, 405);
  assert.equal((await fetch(url + "/favicon.ico")).status, 204);
  assert.equal((await fetch(url + "/leak.txt")).status, 404, "Outside symlink is not served");
  assert.equal(await rawStatus("/%2e%2e%2fprivate.txt"), 404, "Encoded traversal is rejected");
  assert.equal(await rawStatus("/%ZZ"), 400, "Malformed escape is rejected");
  assert.equal(await rawStatus("/missing.js"), 404);
  const unauthorizedStop = await fetch(url + "/__nightfall/stop", { method: "POST" });
  assert.equal(unauthorizedStop.status, 405);
  const second = launch({ NIGHTFALL_TEST_REVISION: "second" });
  const replacement = await ready(second, initial.instance);
  assert.equal(await first.done, 0);
  assert.equal(await (await fetch(url + "/revision.txt")).text(), "second");
  const failed = launch({ NIGHTFALL_TEST_FAIL: "1" });
  assert.notEqual(await failed.done, 0);
  assert.match(failed.output, /Web build failed \(17\)/);
  assert.equal(await (await fetch(url + "/revision.txt")).text(), "second");
  assert.equal((await (await fetch(url + "/__nightfall")).json()).instance, replacement.instance);
  console.log("Launcher passed: canonical build, static/hashed assets, MIME, traversal/symlink guards, restart, failed-build preservation, cwd independence.");
} finally {
  for (const child of children) if (child.exitCode === null) child.kill("SIGTERM");
  await Promise.all(children.map((child) => child.done));
  await rm(fixture, { recursive: true, force: true });
}
