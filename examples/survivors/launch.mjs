// Portable development launcher: current Bend sources are built at every launch.
import { createServer } from "node:http";
import { createReadStream } from "node:fs";
import { mkdtemp, mkdir, rename, rm, stat } from "node:fs/promises";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";
import { randomUUID } from "node:crypto";
import path from "node:path";
if (Number(process.versions.node.split(".")[0]) < 20)
  throw Error("Node.js 20 or newer is required.");
const run = promisify(execFile);
const app = fileURLToPath(new URL(".", import.meta.url));
const repo = path.resolve(app, "../..");
const args = process.argv.slice(2);
let port = 8713,
  host = "127.0.0.1",
  openBrowser = true;
for (let i = 0; i < args.length; i++) {
  if (args[i] === "--no-open") openBrowser = false;
  else if (args[i] === "--port") port = Number(args[++i]);
  else if (args[i] === "--host") host = args[++i];
  else if (args[i] === "--help") {
    console.log(
      "run.command [--port 8713] [--host 127.0.0.1] [--no-open]\nBuilds current Bend sources, starts the server and opens the browser.",
    );
    process.exit(0);
  } else throw Error(`Unknown argument: ${args[i]}`);
}
if (!Number.isInteger(port) || port < 1 || port > 65535 || !host)
  throw Error("Use a valid --port (1–65535) and --host.");
const address = host === "0.0.0.0" ? "127.0.0.1" : host;
const url = `http://${address.includes(":") ? `[${address}]` : address}:${port}`;
const dist = path.join(app, "dist");
async function build() {
  await mkdir(dist, { recursive: true });
  const staging = await mkdtemp(path.join(dist, ".launch-"));
  try {
    console.log("Building current Bend sources…");
    const child = execFile(
      process.env.BEND || "bend",
      [path.join(app, "game.bend"), "-o", path.join(staging, "game.mjs")],
      { cwd: repo, timeout: 300000, killSignal: "SIGKILL" },
      (error) => {
        if (error?.code === "ENOENT")
          console.error(
            "Bend was not found. Add ~/.bend/bin to PATH or set BEND=/absolute/path/to/bend.",
          );
      },
    );
    child.stdout.pipe(process.stdout);
    child.stderr.pipe(process.stderr);
    await new Promise((resolve, reject) => {
      child.once("error", reject);
      child.once("close", (code, signal) =>
        code === 0
          ? resolve()
          : reject(Error(`Bend build failed (${signal || code}).`)),
      );
    });
    await rename(path.join(staging, "game.mjs"), path.join(dist, "game.mjs"));
    console.log("Build complete.");
  } finally {
    await rm(staging, { recursive: true, force: true });
  }
}
const assets = new Map([
  ["/", ["index.html", "text/html"]],
  ["/index.html", ["index.html", "text/html"]],
  ["/style.css", ["style.css", "text/css"]],
  ...["browser", "renderer", "content", "audio", "progression"].map((name) => [
    `/${name}.mjs`,
    [`${name}.mjs`, "text/javascript"],
  ]),
  ["/dist/game.mjs", ["dist/game.mjs", "text/javascript"]],
]);
async function stopPrevious() {
  let previous;
  try {
    const response = await fetch(url + "/__nightfall", {
      signal: AbortSignal.timeout(800),
    });
    if (response.ok) previous = await response.json();
  } catch {
    return;
  }
  if (previous?.application !== "nightfall-survivors" || previous.root !== app)
    return;
  const response = await fetch(url + "/__nightfall/stop", {
    method: "POST",
    headers: { "x-nightfall-instance": previous.instance },
    signal: AbortSignal.timeout(2000),
  });
  if (!response.ok)
    throw Error("Could not restart the previous Nightfall server.");
}
async function main() {
  await build(); // A failed build leaves the previous compiled file/server intact.
  await stopPrevious();
  const instance = randomUUID();
  const server = createServer(async (req, res) => {
    const pathname = new URL(req.url, url).pathname;
    res.setHeader("Cache-Control", "no-store");
    if (pathname === "/__nightfall" && req.method === "GET") {
      res.setHeader("Content-Type", "application/json");
      res.end(
        JSON.stringify({
          application: "nightfall-survivors",
          root: app,
          instance,
        }),
      );
      return;
    }
    if (
      pathname === "/__nightfall/stop" &&
      req.method === "POST" &&
      req.headers["x-nightfall-instance"] === instance
    ) {
      res.writeHead(202).end();
      setImmediate(() => server.close(() => process.exit(0)));
      return;
    }
    if (!["GET", "HEAD"].includes(req.method)) {
      res.writeHead(405).end();
      return;
    }
    if (pathname === "/favicon.ico") {
      res.writeHead(204).end();
      return;
    }
    const asset = assets.get(pathname);
    if (!asset) {
      res.writeHead(404).end();
      return;
    }
    try {
      const file = path.join(app, asset[0]);
      await stat(file);
      res.setHeader("Content-Type", asset[1] + "; charset=utf-8");
      if (req.method === "HEAD") res.end();
      else
        createReadStream(file)
          .on("error", () => res.destroy())
          .pipe(res);
    } catch {
      res.writeHead(404).end();
    }
  });
  // The previous launcher may still be releasing its listening socket.
  for (let attempt = 0; ; attempt++) {
    try {
      await new Promise((resolve, reject) => {
        server.once("error", reject);
        server.listen(port, host, resolve);
      });
      break;
    } catch (error) {
      if (error.code !== "EADDRINUSE" || attempt >= 20) throw error;
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  console.log(
    `Nightfall Survivors: ${url}\nRefresh the page for changed UI files. Relaunch to rebuild Bend. Ctrl+C stops the server.`,
  );
  if (openBrowser) {
    const command =
      process.platform === "darwin"
        ? "open"
        : process.platform === "win32"
          ? "explorer.exe"
          : "xdg-open";
    try {
      await run(command, [url]);
    } catch {
      console.log(`Open ${url} in your browser.`);
    }
  }
  for (const signal of ["SIGINT", "SIGTERM"])
    process.once(signal, () => server.close(() => process.exit(0)));
}
main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
