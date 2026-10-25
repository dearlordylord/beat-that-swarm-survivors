import assert from "node:assert/strict"
import { test } from "node:test"
import { execFileSync } from "node:child_process"
import fs from "node:fs"
import path from "node:path"
import ts from "typescript-compiler-api"

const root = path.resolve(import.meta.dirname, "..")
const files = execFileSync("git", ["ls-files", "--cached", "--others", "--exclude-standard"], {
  cwd: root,
  encoding: "utf8"
})
  .trim()
  .split("\n")
  .filter((file) => /\.(?:mts|ts)$/.test(file) && /^(?:examples|tools|scripts)\//.test(file))
const graph = new Map<string, string[]>()
const external = new Map<string, string[]>()
function runtimeSpecifiers(file: string): string[] {
  const source = ts.createSourceFile(file, fs.readFileSync(file, "utf8"), ts.ScriptTarget.Latest, true)
  const result: string[] = []
  function visit(node: ts.Node) {
    if (ts.isImportDeclaration(node)) {
      const clause = node.importClause
      if (clause?.isTypeOnly) return
      if (
        clause &&
        !clause.name &&
        clause.namedBindings &&
        ts.isNamedImports(clause.namedBindings) &&
        clause.namedBindings.elements.every((item) => item.isTypeOnly)
      )
        return
      if (ts.isStringLiteral(node.moduleSpecifier)) result.push(node.moduleSpecifier.text)
    } else if (ts.isExportDeclaration(node)) {
      if (!node.isTypeOnly && node.moduleSpecifier && ts.isStringLiteral(node.moduleSpecifier))
        result.push(node.moduleSpecifier.text)
    } else if (ts.isCallExpression(node) && node.expression.kind === ts.SyntaxKind.ImportKeyword) {
      const arg = node.arguments[0]
      if (arg && ts.isStringLiteral(arg)) result.push(arg.text)
    }
    ts.forEachChild(node, visit)
  }
  visit(source)
  return result
}
function load(file: string): void {
  if (graph.has(file)) return
  graph.set(file, [])
  const edges: string[] = []
  const packages: string[] = []
  for (const specifier of runtimeSpecifiers(file)) {
    if (!specifier.startsWith(".")) {
      packages.push(specifier)
      continue
    }
    const candidate = path.resolve(path.dirname(file), specifier)
    const source = candidate.endsWith(".mjs") ? candidate.slice(0, -4) + ".mts" : candidate
    if (!/\.(?:mts|ts)$/.test(source) || !fs.existsSync(source)) continue
    edges.push(source)
    load(source)
  }
  graph.set(file, edges)
  external.set(file, packages)
}
for (const file of files) load(path.join(root, file))
await test("authored runtime module graph has no circular imports", () => {
  const done = new Set<string>(),
    stack: string[] = []
  function visit(file: string) {
    const index = stack.indexOf(file)
    assert.equal(
      index,
      -1,
      `Runtime import cycle: ${[...stack.slice(index), file].map((p) => path.relative(root, p)).join(" -> ")}`
    )
    if (done.has(file)) return
    stack.push(file)
    for (const next of graph.get(file) ?? []) visit(next)
    stack.pop()
    done.add(file)
  }
  for (const file of graph.keys()) visit(file)
})
await test("browser presentation closures remain free of Node and Effect runtime imports", () => {
  const done = new Set<string>()
  function visit(file: string) {
    if (done.has(file)) return
    done.add(file)
    for (const specifier of external.get(file) ?? [])
      assert.ok(
        !specifier.startsWith("node:") &&
          specifier !== "effect" &&
          !specifier.startsWith("effect/") &&
          !specifier.startsWith("@effect/"),
        `${path.relative(root, file)} imports ${specifier}`
      )
    for (const next of graph.get(file) ?? []) visit(next)
  }
  for (const entry of [
    "examples/survivors/browser.mts",
    "examples/survivors/coop-browser.mts",
    "examples/survivors/coop-worker.mts",
    "examples/survivors/entry-scripts.mts",
    "tools/survivors-bot/journal-client.mts"
  ])
    visit(path.join(root, entry))
})
