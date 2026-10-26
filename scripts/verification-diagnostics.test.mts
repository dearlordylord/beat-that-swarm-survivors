import assert from "node:assert/strict"
import { test } from "node:test"
import { spawnSync } from "node:child_process"
import { mkdtemp, mkdir, writeFile, chmod, readFile, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import path from "node:path"
import { prepareSite } from "./survivors-publication.mts"
const repo = path.resolve(import.meta.dirname, "..")
const shellQuote = (value: string) => "'" + value.replaceAll("'", "'\"'\"'") + "'"
function run(program: string, args: string[], env = process.env) {
  return spawnSync(program, args, { cwd: repo, env, encoding: "utf8", timeout: 5000 })
}
await test("bounded commands preserve streams, exit, signal and real timeout classification", () => {
  const bounded = (seconds: string, script: string) =>
    run(process.execPath, ["examples/run-bounded.mts", seconds, process.execPath, "-e", script])
  const failed = bounded("2", "process.stdout.write('child-out');process.stderr.write('child-err');process.exit(42)")
  assert.equal(failed.status, 42)
  assert.equal(failed.stdout, "child-out")
  assert.match(failed.stderr, /child-err/)
  assert.match(failed.stderr, /exit=42 signal=none timeout=false/)
  const signaled = bounded("2", "process.kill(process.pid,'SIGTERM')")
  assert.equal(signaled.status, 143)
  assert.match(signaled.stderr, /signal=SIGTERM timeout=false/)
  const child124 = bounded("2", "process.exit(124)")
  assert.equal(child124.status, 124)
  assert.match(child124.stderr, /exit=124 signal=none timeout=false/)
  const timeout = bounded("0.1", "setInterval(()=>{},1000)")
  assert.equal(timeout.status, 124)
  assert.match(timeout.stderr, /timeout=true wallLimitSeconds=0.1/)
  const missing = run(process.execPath, ["examples/run-bounded.mts", "2", "/nonexistent-verification-command"])
  assert.equal(missing.status, 1)
  assert.match(
    missing.stderr,
    /could not start: command=.*nonexistent-verification-command.*cwd=.*timeout=false.*ENOENT/
  )
  const success = bounded("2", "process.stdout.write('ok')")
  assert.equal(success.status, 0)
  assert.equal(success.stdout, "ok")
  assert.equal(success.stderr, "")
})
await test("shell fingerprints propagate failed listing and file hashing", async () => {
  const scratch = await mkdtemp(path.join(tmpdir(), "verification-fingerprint-"))
  try {
    const source = await readFile(path.join(repo, "examples/survivors/check-coop-reliability.sh"), "utf8")
    const fn = source.slice(
      source.indexOf("source_fingerprint() {"),
      source.indexOf("\npython3 ", source.indexOf("source_fingerprint() {"))
    )
    const prefix = `set -euo pipefail\nscratch=${shellQuote(scratch)}\napp=${shellQuote(path.join(repo, "examples/survivors"))}\nexample_repo=${shellQuote(repo)}\n${fn}\n`
    const listing = run("bash", [
      "-c",
      prefix + 'find(){ echo injected-find-failure >&2;return 42; }; fingerprint="$(source_fingerprint)"'
    ])
    assert.equal(listing.status, 42)
    assert.match(listing.stderr, /injected-find-failure/)
    assert.match(listing.stderr, /Source fingerprint find failed: .*exit 42/)
    const hashing = run("bash", [
      "-c",
      prefix + 'find(){ printf "%s\\n" /nonexistent-fingerprint-file; }; fingerprint="$(source_fingerprint)"'
    ])
    assert.equal(hashing.status, 1)
    assert.match(hashing.stderr, /Source fingerprint shasum failed: \/nonexistent-fingerprint-file/)
  } finally {
    await rm(scratch, { recursive: true, force: true })
  }
})
await test("native cache probe failure retains its cause instead of reporting source drift", async () => {
  const source = await readFile(path.join(repo, "examples/survivors/check-launcher-profile-ui.sh"), "utf8")
  const fn = source.slice(
    source.indexOf("unchanged_sources() {"),
    source.indexOf("\nfor source in", source.indexOf("unchanged_sources() {"))
  )
  const result = run("bash", [
    "-c",
    `set -euo pipefail\ncache_key=valid;example_repo=repo;BEND=bend;CLANG=clang\npython3(){ echo injected-probe-error >&2;return 42; }\n${fn}\nunchanged_sources`
  ])
  assert.equal(result.status, 42)
  assert.match(result.stderr, /injected-probe-error/)
  assert.match(result.stderr, /cache fingerprint command failed \(exit 42\)/)
  assert.doesNotMatch(result.stderr, /inputs changed/)
})
await test("window smoke preconditions identify the missing executable without launching a window", () => {
  const smokes: [string, string][] = [
    ["examples/survivors/native-window-smoke.sh", "NIGHTFALL_BINARY"],
    ["tools/survivors-bot/visible-window-smoke.sh", "NIGHTFALL_BOT_BINARY"]
  ]
  for (const [script, variable] of smokes) {
    const result = run("bash", [script, "--worker"], { ...process.env, [variable]: "/nonexistent-window-fixture" })
    assert.equal(result.status, 1)
    assert.match(result.stderr, /Window smoke requires executable: \/nonexistent-window-fixture/)
  }
})
await test("quiet publication failure preserves both streams and leaves Site files untouched", async () => {
  const fixture = await mkdtemp(path.join(tmpdir(), "publication-command-diagnostics-"))
  const source = path.join(fixture, "source"),
    site = path.join(fixture, "site"),
    bin = path.join(fixture, "bin"),
    origin = path.join(fixture, "origin.git")
  const oldPath = process.env.PATH
  function git(args: string[], cwd = source) {
    const result = spawnSync("git", args, { cwd, encoding: "utf8" })
    assert.equal(result.status, 0, result.stderr)
  }
  try {
    for (const directory of [
      source,
      site,
      bin,
      path.join(source, "examples/survivors/web"),
      path.join(site, ".openai")
    ])
      await mkdir(directory, { recursive: true })
    git(["init", "--bare", origin], fixture)
    git(["init", "-b", "master"])
    git(["config", "user.email", "fixture@example.invalid"])
    git(["config", "user.name", "Fixture"])
    await writeFile(path.join(source, "examples/survivors/build-web.sh"), "exit 0\n")
    await writeFile(path.join(source, "examples/survivors/web/package-lock.json"), "{}")
    await writeFile(path.join(source, "bendhub-dependencies.json"), "{}")
    git(["add", "."])
    git(["commit", "-m", "fixture"])
    git(["remote", "add", "origin", origin])
    git(["push", "origin", "master"])
    await writeFile(
      path.join(site, ".openai/hosting.json"),
      JSON.stringify({ project_id: "fixture", static: { directory: "dist" } })
    )
    await writeFile(path.join(site, "preserved.txt"), "original")
    await writeFile(
      path.join(bin, "npm"),
      "#!/bin/sh\nprintf 'quiet-stdout-marker'\nprintf 'quiet-stderr-marker' >&2\nexit 42\n"
    )
    await chmod(path.join(bin, "npm"), 0o755)
    process.env.PATH = bin + path.delimiter + (oldPath ?? "")
    await assert.rejects(prepareSite({ repo: source, siteCheckout: site, quiet: true }), (error) => {
      assert.ok(error instanceof Error)
      assert.match(
        error.message,
        /command=\["npm","ci","--no-audit","--no-fund"\].*cwd=.*exit=42 signal=null timeout=false/
      )
      assert.match(error.message, /stdout:\nquiet-stdout-marker/)
      assert.match(error.message, /stderr:\nquiet-stderr-marker/)
      return true
    })
    await writeFile(
      path.join(bin, "git"),
      "#!/bin/sh\nprintf 'git-stdout-marker'\nprintf 'git-stderr-marker' >&2\nexit 43\n"
    )
    await chmod(path.join(bin, "git"), 0o755)
    await assert.rejects(prepareSite({ repo: source, siteCheckout: site, quiet: true }), (error) => {
      assert.ok(error instanceof Error)
      assert.match(error.message, /command=\["git".*exit=43/)
      assert.match(error.message, /stdout:\ngit-stdout-marker/)
      assert.match(error.message, /stderr:\ngit-stderr-marker/)
      assert.ok(error.cause instanceof Error)
      return true
    })
    assert.equal(await readFile(path.join(site, "preserved.txt"), "utf8"), "original")
  } finally {
    if (oldPath === undefined) delete process.env.PATH
    else process.env.PATH = oldPath
    await rm(fixture, { recursive: true, force: true })
  }
})
