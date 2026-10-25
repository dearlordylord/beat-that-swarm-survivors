import { execFileSync } from "node:child_process"
import { writeFile } from "node:fs/promises"
import { join } from "node:path"
const [repo, output] = process.argv.slice(2)
if (!repo || !output) throw new Error("Usage: write-survivors-version.mts REPOSITORY OUTPUT")
const repository = repo
function git(args: string[]): string | null {
  try {
    return execFileSync("git", ["-C", repository, ...args], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"]
    }).trim()
  } catch {
    return null
  }
}
const revision = git(["rev-parse", "--verify", "HEAD"])
const status = revision === null ? null : git(["status", "--porcelain=v1", "--untracked-files=all"])
await writeFile(
  join(output, "version.json"),
  JSON.stringify(
    {
      schemaVersion: 1,
      revision: revision ?? "unversioned-local-build",
      dirty: revision === null || status === null || status.length > 0,
      buildContext: "local-development",
      builtAt: new Date().toISOString()
    },
    null,
    2
  ) + "\n"
)
