import { execFile } from "node:child_process"
import { promisify } from "node:util"
import { defined, errorCode, object } from "../../examples/survivors/host-values.mts"
interface JournalOptions {
  directory?: string
  receipt?: string | undefined
}
import { createServer } from "node:http"
import { readFile, readdir, stat } from "node:fs/promises"
import { resolve, basename } from "node:path"
import { fileURLToPath } from "node:url"
import { parseArgs } from "node:util"
const defaultDirectory = fileURLToPath(new URL("../../examples/survivors/dist/bot-runs/", import.meta.url))
const maxBytes = 64 * 1024 * 1024
// Writers append newline-terminated records. A partial final write is not corruption.
export function parseJournal(input: string) {
  const lines = input.split("\n")
  const incompleteTail = defined(lines.pop()).length > 0
  const records: Record<string, unknown>[] = [],
    errors: { line: number; message: string }[] = []
  lines.forEach((line, index) => {
    if (!line.trim()) return
    try {
      const record = object(JSON.parse(line))
      if (!record || typeof record !== "object" || Array.isArray(record) || typeof record.type !== "string")
        throw new Error("record")
      records.push(record)
    } catch {
      errors.push({ line: index + 1, message: "Invalid completed journal record" })
    }
  })
  return { records, errors, incompleteTail }
}
export async function readJournal({ directory = defaultDirectory, receipt }: JournalOptions = {}) {
  let path = receipt && resolve(receipt)
  if (!path) {
    let files
    try {
      files = (await readdir(directory)).filter((name) => /^[a-zA-Z0-9_-]+\.jsonl$/.test(name))
    } catch (error) {
      if (errorCode(error) === "ENOENT") return { records: [], errors: [], waiting: true }
      throw error
    }
    const ranked = await Promise.all(
      files.map(async (name) => ({
        path: resolve(directory, name),
        modified: (await stat(resolve(directory, name))).mtimeMs
      }))
    )
    ranked.sort((a, b) => b.modified - a.modified || a.path.localeCompare(b.path))
    path = ranked[0]?.path
  }
  if (!path) return { records: [], errors: [], waiting: true }
  const info = await stat(path)
  if (!info.isFile() || info.size > maxBytes)
    throw new Error("Journal exceeds the 64 MiB viewer limit or is not a regular file")
  return { file: basename(path), ...parseJournal(await readFile(path, "utf8")) }
}
export function createJournalServer(options: JournalOptions = {}) {
  return createServer(async (request, response) => {
    response.setHeader("Cache-Control", "no-store")
    response.setHeader("X-Content-Type-Options", "nosniff")
    response.setHeader("Referrer-Policy", "no-referrer")
    response.setHeader(
      "Content-Security-Policy",
      "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; connect-src 'self'; frame-ancestors 'none'"
    )
    if (request.method !== "GET") {
      response.writeHead(405)
      response.end()
      return
    }
    // No URL-supplied paths, shell commands, credentials, or writes.
    if (request.url === "/api/journal") {
      response.setHeader("Content-Type", "application/json; charset=utf-8")
      try {
        response.end(JSON.stringify(await readJournal(options)))
      } catch {
        response.writeHead(503)
        response.end(JSON.stringify({ error: "Journal unavailable or exceeds viewer limit" }))
      }
    } else if (request.url === "/journal-client.mjs") {
      response.setHeader("Content-Type", "text/javascript; charset=utf-8")
      response.end(await readFile(new URL("../../.typescript/journal/journal-client.mjs", import.meta.url)))
    } else if (request.url === "/" || request.url === "/index.html") {
      response.setHeader("Content-Type", "text/html; charset=utf-8")
      response.end(await readFile(new URL("./journal.html", import.meta.url)))
    } else {
      response.writeHead(404)
      response.end()
    }
  })
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const { values } = parseArgs({
    options: {
      host: { type: "string", default: "127.0.0.1" },
      port: { type: "string", default: "8714" },
      receipt: { type: "string" },
      help: { type: "boolean" }
    }
  })
  if (values.help) {
    console.log("node tools/survivors-bot/journal.mts [--host 0.0.0.0] [--port 8714] [--receipt /path/run.jsonl]")
  } else {
    const port = Number(values.port)
    if (!Number.isSafeInteger(port) || port < 1 || port > 65535) throw new Error("Invalid port")
    await promisify(execFile)(process.execPath, [
      fileURLToPath(new URL("../../node_modules/typescript/bin/tsc", import.meta.url)),
      "-p",
      fileURLToPath(new URL("./tsconfig.journal.json", import.meta.url))
    ])
    const server = createJournalServer({ receipt: values.receipt })
    server.on("error", () => {
      console.error("Journal server could not listen. Check host and port.")
      process.exitCode = 1
    })
    server.listen(port, values.host, () =>
      console.log(
        `Decision journal: http://${values.host}:${port}/ (${values.receipt ? "selected receipt" : "latest receipt"})`
      )
    )
  }
}
