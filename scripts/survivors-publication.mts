import {
  parseAstroVersion,
  parseDependency,
  parseHosting,
  parseJson,
  parseReceipt,
  parseVersion
} from "./survivors-publication-values.mts"
import { defined, errorCode, object } from "../examples/survivors/host-values.mts"
import { createHash } from "node:crypto"
import { execFile, spawn } from "node:child_process"
import { promisify } from "node:util"
import { chmod, lstat, mkdir, mkdtemp, readFile, readdir, realpath, rename, rm, writeFile } from "node:fs/promises"
import os from "node:os"
import path from "node:path"
import { fileURLToPath } from "node:url"
interface SourceFile {
  bytes: Buffer
  mode: number
}
interface FileIdentity {
  sha256: string
  mode: number
}
type SourceFiles = Record<string, FileIdentity>
interface SourceState {
  files: SourceFiles
  content: Map<string, SourceFile>
  fingerprint: string
  dirty: boolean
  dirtyFiles: string[]
}
interface PublicationOptions {
  repo?: string
  siteCheckout?: string
  quiet?: boolean
}
const exec = promisify(execFile)
const defaultRepo = fileURLToPath(new URL("..", import.meta.url))
const scopes = [
  "package.json",
  "package-lock.json",
  "tsconfig.json",
  "types",
  "scripts/generate-bend-types.py",
  "scripts/generate-bend-codecs.mts",
  "scripts/write-survivors-version.mts",
  "tools/iroh-transport",
  "examples/survivors",
  "examples/common.sh",
  "examples/run-bounded.mts",
  "bendhub-dependencies.json",
  "LICENSE-MIT",
  "LICENSE-APACHE"
]
const sourceSnapshot = "source/survivors"
const digest = (bytes: string | Uint8Array) => createHash("sha256").update(bytes).digest("hex")
const within = (root: string, candidate: string) => candidate === root || candidate.startsWith(root + path.sep)
const validRelative = (name: string) =>
  name && !path.isAbsolute(name) && !name.split("/").some((p) => p === ".." || p === "" || p === ".")
const include = (name: string) =>
  name !== "examples/survivors/content.mts" &&
  name !== "examples/survivors/bend-codecs.generated.mts" &&
  !name.split("/").some((p) => ["dist", "node_modules", ".astro"].includes(p))
async function git(repo: string, args: string[]) {
  try {
    return (await exec("git", ["-C", repo, ...args], { maxBuffer: 16 * 1024 * 1024 })).stdout
  } catch {
    throw new Error(`Git operation failed: ${args[0]}. Check repository access and origin/master.`)
  }
}
async function repositoryState(repo: string, fetch = true) {
  const branch = (await git(repo, ["branch", "--show-current"])).trim()
  if (branch !== "master")
    throw new Error("Publication requires the master branch. Switch to master before preparing the site.")
  if (fetch) await git(repo, ["fetch", "--no-tags", "origin", "+refs/heads/master:refs/remotes/origin/master"])
  const revision = (await git(repo, ["rev-parse", "HEAD"])).trim()
  const remote = (await git(repo, ["rev-parse", "refs/remotes/origin/master"])).trim()
  if (revision !== remote)
    throw new Error(
      "Local master differs from origin/master. Pull or push master before publishing; no old or unpublished revision was prepared."
    )
  return { branch, revision }
}
async function regularFile(root: string, name: string): Promise<SourceFile> {
  if (!validRelative(name)) throw new Error(`Unsafe source path: ${name}`)
  const parts = name.split("/")
  let current = root
  for (let i = 0; i < parts.length; i++) {
    current = path.join(current, defined(parts[i]))
    const info = await lstat(current)
    if (info.isSymbolicLink()) throw new Error(`Symbolic links are not publication inputs: ${name}`)
    if (i < parts.length - 1 ? !info.isDirectory() : !info.isFile())
      throw new Error(`Not a regular publication file: ${name}`)
    if (i === parts.length - 1) return { bytes: await readFile(current), mode: info.mode & 0o111 ? 0o755 : 0o644 }
  }
  throw new Error(`No source file at ${name}`)
}
function fingerprint(files: SourceFiles) {
  return digest(JSON.stringify(canonical(files)))
}
async function sourceState(repo: string): Promise<SourceState> {
  const names = [
    ...new Set(
      (await git(repo, ["ls-files", "-z", "--cached", "--others", "--exclude-standard", "--", ...scopes]))
        .split("\0")
        .filter(Boolean)
    )
  ]
    .filter(include)
    .sort()
  const files: SourceFiles = {},
    content = new Map<string, SourceFile>()
  for (const name of names) {
    let file
    try {
      file = await regularFile(repo, name)
    } catch (error) {
      if (errorCode(error) === "ENOENT") continue
      throw error
    }
    files[name] = { sha256: digest(file.bytes), mode: file.mode }
    content.set(name, file)
  }
  const changed = (await git(repo, ["diff", "HEAD", "--name-only", "-z", "--", ...scopes]))
    .split("\0")
    .filter(Boolean)
    .filter(include)
  const untracked = (await git(repo, ["ls-files", "-z", "--others", "--exclude-standard", "--", ...scopes]))
    .split("\0")
    .filter(Boolean)
    .filter(include)
  const dirtyFiles = [...new Set([...changed, ...untracked])].sort()
  return { files, content, fingerprint: fingerprint(files), dirty: dirtyFiles.length > 0, dirtyFiles }
}
async function copySource(destination: string, source: SourceState) {
  for (const [name, file] of source.content) {
    const target = path.join(destination, name)
    await mkdir(path.dirname(target), { recursive: true })
    await writeFile(target, file.bytes)
    await chmod(target, file.mode)
  }
}
async function treeFiles(root: string, withMode?: false): Promise<Record<string, string>>
async function treeFiles(root: string, withMode: true): Promise<SourceFiles>
async function treeFiles(root: string, withMode = false) {
  const rootInfo = await lstat(root)
  if (rootInfo.isSymbolicLink() || !rootInfo.isDirectory())
    throw new Error("Publication tree must be a real directory.")
  const files: Record<string, string | FileIdentity> = {}
  async function walk(directory: string, prefix = "") {
    for (const entry of (await readdir(directory, { withFileTypes: true })).sort((a, b) =>
      a.name.localeCompare(b.name)
    )) {
      const name = prefix + entry.name
      if (entry.isSymbolicLink()) throw new Error(`Symbolic link in publication tree: ${name}`)
      if (entry.isDirectory()) await walk(path.join(directory, entry.name), name + "/")
      else if (entry.isFile()) {
        const file = await regularFile(root, name)
        files[name] = withMode ? { sha256: digest(file.bytes), mode: file.mode } : digest(file.bytes)
      } else throw new Error(`Unsupported publication file: ${name}`)
    }
  }
  await walk(root)
  return files
}
async function directories(repo: string, siteCheckout: string) {
  const source = await realpath(repo || defaultRepo)
  if ((await realpath((await git(source, ["rev-parse", "--show-toplevel"])).trim())) !== source)
    throw new Error("--repo must identify the repository root.")
  const site = await realpath(siteCheckout)
  if (within(source, site) || within(site, source))
    throw new Error(
      "The Site checkout and source repository must be separate directories, neither containing the other."
    )
  for (const name of [".openai", ".openai/hosting.json", "source", "source/survivors", "dist", "SOURCE.json"]) {
    let current = site
    for (const part of name.split("/")) {
      current = path.join(current, part)
      try {
        if ((await lstat(current)).isSymbolicLink()) throw new Error(`Symbolic link in Site destination: ${name}`)
      } catch (error) {
        if (errorCode(error) === "ENOENT") break
        throw error
      }
    }
  }
  const hosting = parseHosting(parseJson((await regularFile(site, ".openai/hosting.json")).bytes.toString("utf8")))
  if (hosting.static?.directory !== "dist" || typeof hosting.project_id !== "string" || !hosting.project_id)
    throw new Error("This publication guard requires a registered static Site with static.directory set to dist.")
  return { repo: source, site, hosting }
}
async function withLock<T>(site: string, action: () => Promise<T>): Promise<T> {
  const directory = path.join(site, ".survivors-publication.lock")
  try {
    await mkdir(directory, { mode: 0o700 })
  } catch (error) {
    if (errorCode(error) === "EEXIST")
      throw new Error(
        "Another publication preparation or verification holds .survivors-publication.lock. Remove a stale lock only after confirming no preparation is running."
      )
    throw error
  }
  try {
    await writeFile(
      path.join(directory, "owner.json"),
      JSON.stringify({ pid: process.pid, startedAt: new Date().toISOString() }) + "\n"
    )
    return await action()
  } finally {
    await rm(directory, { recursive: true, force: true })
  }
}
async function command(program: string, args: string[], cwd: string, quiet: boolean) {
  await new Promise<void>((resolve, reject) => {
    const child = spawn(program, args, { cwd, env: process.env, stdio: quiet ? "pipe" : "inherit" })
    if (quiet) {
      child.stdout?.resume()
      child.stderr?.resume()
    }
    child.once("error", reject)
    child.once("close", (code, signal) =>
      code === 0
        ? resolve()
        : reject(
            new Error(`${path.basename(program)} failed (${signal || code}); the previous Site files were preserved.`)
          )
    )
  })
}
function canonical(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonical)
  if (value && typeof value === "object")
    return Object.fromEntries(
      Object.keys(value)
        .sort()
        .map((key) => [key, canonical(object(value)[key])])
    )
  return value
}
function same(a: unknown, b: unknown) {
  return JSON.stringify(canonical(a)) === JSON.stringify(canonical(b))
}
async function assertFresh(repo: string, expected: { revision: string; sourceFingerprint: string }) {
  const state = await repositoryState(repo)
  const source = await sourceState(repo)
  if (state.revision !== expected.revision || source.fingerprint !== expected.sourceFingerprint)
    throw new Error(
      "Sources changed since this build was captured. Prepare the Site again; publishing these old assets is refused."
    )
  return source
}
async function replacePrepared(site: string, staging: string) {
  const changes: [string, string][] = [
    ["dist", "dist"],
    [sourceSnapshot, sourceSnapshot],
    ["SOURCE.json", "SOURCE.json"]
  ]
  const done = []
  try {
    for (const [name, replacement] of changes) {
      const target = path.join(site, name),
        backup = path.join(staging, "previous", name)
      await mkdir(path.dirname(target), { recursive: true })
      await mkdir(path.dirname(backup), { recursive: true })
      let existed = true
      try {
        await rename(target, backup)
      } catch (error) {
        if (errorCode(error) === "ENOENT") existed = false
        else throw error
      }
      const entry = { target, backup, existed, installed: false }
      done.push(entry)
      await rename(path.join(staging, "next", replacement), target)
      entry.installed = true
    }
  } catch (error) {
    for (const entry of done.reverse()) {
      if (entry.installed) await rm(entry.target, { recursive: true, force: true })
      if (entry.existed) await rename(entry.backup, entry.target)
    }
    throw error
  }
}
export async function prepareSite({ repo = defaultRepo, siteCheckout, quiet = false }: PublicationOptions) {
  if (!siteCheckout) throw new Error("--site-checkout is required.")
  const dirs = await directories(repo, siteCheckout)
  repo = dirs.repo
  const site = dirs.site
  return withLock(site, async () => {
    const state = await repositoryState(repo)
    const source = await sourceState(repo)
    for (const name of [
      "examples/survivors/build-web.sh",
      "examples/survivors/web/package-lock.json",
      "bendhub-dependencies.json"
    ])
      if (!source.files[name]) throw new Error(`Required build input is missing: ${name}`)
    let temporary, staging
    try {
      temporary = await mkdtemp(path.join(os.tmpdir(), "survivors-source-"))
      staging = await mkdtemp(path.join(site, ".survivors-prepare-"))
      await copySource(temporary, source)
      await command("npm", ["ci", "--no-audit", "--no-fund"], temporary, quiet)
      await command(
        process.env.npm_execpath ? process.execPath : "npm",
        process.env.npm_execpath
          ? [
              process.env.npm_execpath,
              "ci",
              "--prefix",
              path.join(temporary, "examples/survivors/web"),
              "--no-audit",
              "--no-fund"
            ]
          : ["ci", "--prefix", path.join(temporary, "examples/survivors/web"), "--no-audit", "--no-fund"],
        temporary,
        quiet
      )
      await command("bash", [path.join(temporary, "examples/survivors/build-web.sh")], temporary, quiet)
      const output = path.join(temporary, "examples/survivors/dist/web")
      await treeFiles(output) // Reject output links before any Site mutation.
      const dependency = parseDependency(
        parseJson(defined(source.content.get("bendhub-dependencies.json")).bytes.toString("utf8"))
      )
      const versionOutput = await exec(process.env.BEND || "bend", ["version"])
      const bendVersion = versionOutput.stdout.match(/\b\d+\.\d+\.\d+\b/)?.[0]
      if (bendVersion !== dependency.bendVersion)
        throw new Error(
          `Bend version ${bendVersion || "unknown"} does not match the source pin ${dependency.bendVersion}.`
        )
      const version = {
        schemaVersion: 1,
        revision: state.revision,
        branch: state.branch,
        sourceFingerprint: source.fingerprint,
        dirty: source.dirty,
        builtAt: new Date().toISOString()
      }
      await writeFile(path.join(output, "version.json"), JSON.stringify(version, null, 2) + "\n")
      const assets = await treeFiles(output)
      const next = path.join(staging, "next")
      await mkdir(path.join(next, "dist"), { recursive: true })
      // Copy output bytes without following links (treeFiles has already confined them).
      for (const name of Object.keys(assets)) {
        const file = await regularFile(output, name),
          target = path.join(next, "dist", name)
        await mkdir(path.dirname(target), { recursive: true })
        await writeFile(target, file.bytes)
        await chmod(target, file.mode)
      }
      if (!same(await treeFiles(path.join(next, "dist")), assets))
        throw new Error("Build output changed while being staged; the previous Site was preserved.")
      await copySource(path.join(next, sourceSnapshot), source)
      let repository = (await git(repo, ["remote", "get-url", "origin"])).trim()
      try {
        const url = new URL(repository)
        url.username = ""
        url.password = ""
        repository = url.href
      } catch {}
      const astro = parseAstroVersion(
        parseJson(defined(source.content.get("examples/survivors/web/package.json")).bytes.toString("utf8"))
      )
      const receipt = {
        schemaVersion: 2,
        siteProjectId: dirs.hosting.project_id,
        repository,
        commit: state.revision,
        branch: state.branch,
        dirty: source.dirty,
        dirtyFiles: source.dirtyFiles,
        sourceFingerprint: source.fingerprint,
        sourceSnapshot,
        sourceFiles: source.files,
        files: assets,
        build: {
          command: "bash examples/survivors/build-web.sh",
          bendVersion,
          astroVersion: astro,
          builtAt: version.builtAt
        },
        dependency
      }
      await writeFile(path.join(next, "SOURCE.json"), JSON.stringify(receipt, null, 2) + "\n")
      await assertFresh(repo, { revision: state.revision, sourceFingerprint: source.fingerprint })
      await replacePrepared(site, staging)
      return {
        siteCheckout: site,
        siteProjectId: dirs.hosting.project_id,
        ...version,
        sourceFiles: Object.keys(source.files).length,
        assets: Object.keys(assets).length
      }
    } finally {
      if (temporary) await rm(temporary, { recursive: true, force: true })
      if (staging) await rm(staging, { recursive: true, force: true })
    }
  })
}
export async function verifySite({ repo = defaultRepo, siteCheckout }: PublicationOptions) {
  if (!siteCheckout) throw new Error("--site-checkout is required.")
  const dirs = await directories(repo, siteCheckout)
  repo = dirs.repo
  const site = dirs.site
  return withLock(site, async () => {
    const receipt = parseReceipt(parseJson(await readFile(path.join(site, "SOURCE.json"), "utf8")))
    if (receipt.siteProjectId !== dirs.hosting.project_id)
      throw new Error("The build receipt belongs to a different Site project.")
    if (receipt.schemaVersion !== 2 || receipt.branch !== "master" || receipt.sourceSnapshot !== sourceSnapshot)
      throw new Error("Site has no current guarded build receipt. Prepare it first.")
    const source = await assertFresh(repo, { revision: receipt.commit, sourceFingerprint: receipt.sourceFingerprint })
    if (!same(source.files, receipt.sourceFiles) || fingerprint(receipt.sourceFiles) !== receipt.sourceFingerprint)
      throw new Error("Source receipt does not match current source files.")
    const snapshot = await treeFiles(path.join(site, sourceSnapshot), true)
    if (!same(snapshot, receipt.sourceFiles)) throw new Error("Saved source snapshot differs from its build receipt.")
    const assets = await treeFiles(path.join(site, "dist"))
    if (!same(assets, receipt.files))
      throw new Error("Site assets differ from their fresh build receipt. Prepare the Site again.")
    const version = parseVersion(parseJson(await readFile(path.join(site, "dist/version.json"), "utf8")))
    for (const [key, value] of Object.entries({
      revision: receipt.commit,
      branch: receipt.branch,
      sourceFingerprint: receipt.sourceFingerprint,
      dirty: receipt.dirty,
      builtAt: receipt.build.builtAt
    }))
      if (Object.entries(version).find(([name]) => name === key)?.[1] !== value)
        throw new Error(`Published version receipt disagrees on ${key}.`)
    if (source.dirty !== receipt.dirty || !same(source.dirtyFiles, receipt.dirtyFiles))
      throw new Error("Source dirty-state receipt changed; prepare the Site again.")
    return {
      verified: true,
      siteProjectId: receipt.siteProjectId,
      revision: receipt.commit,
      branch: receipt.branch,
      dirty: receipt.dirty,
      sourceFingerprint: receipt.sourceFingerprint,
      assets: Object.keys(assets).length
    }
  })
}
export function argumentsFor(argv: string[]) {
  const options: PublicationOptions = {}
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--repo") options.repo = defined(argv[++i])
    else if (argv[i] === "--site-checkout") options.siteCheckout = defined(argv[++i])
    else throw new Error("Usage: --site-checkout PATH [--repo PATH]")
  }
  return options
}
