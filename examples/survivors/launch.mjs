// Portable development launcher: the canonical Bend + Astro build runs at every launch.
import { createServer } from "node:http";
import { createReadStream } from "node:fs";
import { realpath, stat } from "node:fs/promises";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";
import { randomUUID } from "node:crypto";
import path from "node:path";
const [major, minor, patch] = process.versions.node.split(".").map(Number);
if (major < 22 || (major === 22 && (minor < 23 || (minor === 23 && patch < 4))))
  throw Error("Node.js 22.23.4 or newer is required for Astro.");
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
      "node examples/survivors/launch.mjs [--port 8713] [--host 127.0.0.1] [--no-open]\nBuilds current Bend sources and the Astro menu, starts the server and opens the browser.",
    );
    process.exit(0);
  } else throw Error(`Unknown argument: ${args[i]}`);
}
if (!Number.isInteger(port) || port < 1 || port > 65535 || !host)
  throw Error("Use a valid --port (1–65535) and --host.");
const address = host === "0.0.0.0" ? "127.0.0.1" : host;
const url = `http://${address.includes(":") ? `[${address}]` : address}:${port}`;
const web = path.join(app, "dist", "web");
async function build() {
  console.log("Building current Bend sources and Astro menu…");
  const child = execFile(
    "bash",
    [path.join(app, "build-web.sh")],
    { cwd: repo, timeout: 300000, killSignal: "SIGKILL", maxBuffer: 8 * 1024 * 1024 },
  );
  child.stdout.pipe(process.stdout);
  child.stderr.pipe(process.stderr);
  await new Promise((resolve, reject) => {
    child.once("error", reject);
    child.once("close", (code, signal) =>
      code === 0
        ? resolve()
        : reject(Error(`Web build failed (${signal || code}).`)),
    );
  });
  await stat(path.join(web, "index.html"));
  console.log("Build complete.");
}
const mime = new Map([
  [".html", "text/html; charset=utf-8"],
  [".css", "text/css; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".mjs", "text/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".map", "application/json; charset=utf-8"],
  [".svg", "image/svg+xml"],
  [".png", "image/png"],
  [".webp", "image/webp"],
  [".ico", "image/x-icon"],
  [".woff2", "font/woff2"],
  [".wasm", "application/wasm"],
  [".txt", "text/plain; charset=utf-8"],
]);
function within(root, candidate) {
  return candidate === root || candidate.startsWith(root + path.sep);
}
async function assetFile(pathname) {
  const decoded = decodeURIComponent(pathname);
  if (decoded.includes("\0")) return null;
  let file = path.resolve(web, "." + decoded);
  if (!within(web, file)) return null;
  let info = await stat(file);
  if (info.isDirectory()) {
    file = path.join(file, "index.html");
    info = await stat(file);
  }
  if (!info.isFile()) return null;
  const [realRoot, realFile] = await Promise.all([realpath(web), realpath(file)]);
  return within(realRoot, realFile) ? { file, info } : null;
}
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
    let pathname;
    try {
      pathname = new URL(req.url, url).pathname;
    } catch {
      res.writeHead(400).end();
      return;
    }
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
    try {
      const asset = await assetFile(pathname);
      if (!asset) {
        res.writeHead(404).end();
        return;
      }
      res.setHeader("Content-Type", mime.get(path.extname(asset.file)) || "application/octet-stream");
      res.setHeader("Content-Length", asset.info.size);
      res.setHeader("X-Content-Type-Options", "nosniff");
      if (req.method === "HEAD") res.end();
      else
        createReadStream(asset.file)
          .on("error", () => res.destroy())
          .pipe(res);
    } catch (error) {
      res.writeHead(error instanceof URIError ? 400 : 404).end();
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
    `Nightfall Survivors: ${url}\nRelaunch to rebuild Bend and the static menu. Ctrl+C stops the server.`,
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
