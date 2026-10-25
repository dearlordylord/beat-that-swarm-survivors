// Generate constructive parsers from the host ABI, with unsupported shapes rejected.
import fs from "node:fs"
import path from "node:path"
import ts from "typescript-compiler-api"

const root = path.resolve(import.meta.dirname, "..")
const sourcePath = path.join(root, ".typescript/bend.d.ts")
const outputPath = path.join(root, "examples/survivors/bend-codecs.generated.mts")
const source = ts.createSourceFile(sourcePath, fs.readFileSync(sourcePath, "utf8"), ts.ScriptTarget.Latest, true)
const roots = [
  "CoopCombatPrediction.Scene",
  "CoopHitJournal.State",
  "CoopHitJournal.HitEvent",
  "CoopSession.State",
  "CoopSession.Receipt",
  "CoopConnection.State",
  "CoopConnection.Action",
  "CoopLocalProjectiles.RenderShot",
  "CoopLocalProjectiles.ContactFx",
  "CoopLocalProjectiles.TargetFade",
  "CoopContactPlayback.Fx",
  "CoopConnection.Signal"
]
const aliases = new Map<string, ts.TypeAliasDeclaration>()
function collect(node: ts.Node, prefix: string): void {
  if (ts.isModuleDeclaration(node)) {
    const name = node.name.getText(source)
    const next = name === "BendABI" ? "" : prefix ? `${prefix}.${name}` : name
    if (node.body) collect(node.body, next)
    return
  }
  if (ts.isTypeAliasDeclaration(node)) aliases.set(prefix ? `${prefix}.${node.name.text}` : node.name.text, node)
  ts.forEachChild(node, (child) => collect(child, prefix))
}
collect(source, "")
const pending = [...roots]
const emitted = new Set<string>()
const functions: string[] = []
function parserName(name: string): string {
  return `parse${name.replaceAll(".", "")}`
}
function unsupported(node: ts.Node): never {
  throw new Error(`Unsupported serialized ABI node: ${node.getText(source)}`)
}
function expression(node: ts.TypeNode, value: string, owner: string, parameters: ReadonlySet<string>): string {
  switch (node.kind) {
    case ts.SyntaxKind.NumberKeyword:
      return `number(${value})`
    case ts.SyntaxKind.StringKeyword:
      return `text(${value})`
    case ts.SyntaxKind.BooleanKeyword:
      return `boolean(${value})`
    // Opacity is declared by the ABI generator; this makes no validation claim.
    case ts.SyntaxKind.UnknownKeyword:
      return value
  }
  if (ts.isParenthesizedTypeNode(node)) return expression(node.type, value, owner, parameters)
  if (ts.isTypeReferenceNode(node)) {
    const name = node.typeName.getText(source)
    if (parameters.has(name)) return `parse${name}(${value})`
    const args = node.typeArguments ?? []
    const parsers = args.map((arg) => `(item: unknown) => ${expression(arg, "item", owner, parameters)}`)
    if (name === "BendList" || name === "BendMaybe") {
      if (args.length !== 1) return unsupported(node)
      return `${name === "BendList" ? "parseList" : "parseMaybe"}(${value}, ${parsers.join(", ")})`
    }
    const qualified = name.includes(".") ? name : `${owner}.${name}`
    const alias = aliases.get(qualified)
    if (!alias || args.length !== (alias.typeParameters?.length ?? 0)) return unsupported(node)
    pending.push(qualified)
    return `${parserName(qualified)}(${[value, ...parsers].join(", ")})`
  }
  if (ts.isUnionTypeNode(node) || ts.isTypeLiteralNode(node)) {
    const variants = ts.isUnionTypeNode(node) ? node.types : [node]
    const cases = variants.map((variant) => {
      if (!ts.isTypeLiteralNode(variant)) return unsupported(variant)
      const members = variant.members.map((member) => {
        if (!ts.isPropertySignature(member) || !member.type || member.questionToken) return unsupported(member)
        const key =
          ts.isIdentifier(member.name) || ts.isStringLiteral(member.name) ? member.name.text : unsupported(member)
        return { key, type: member.type }
      })
      const tag = members.find((member) => member.key === "$")
      if (!tag || !ts.isLiteralTypeNode(tag.type) || !ts.isStringLiteral(tag.type.literal)) return unsupported(variant)
      const label = JSON.stringify(tag.type.literal.text)
      const fields = members.map(
        (member) =>
          `${JSON.stringify(member.key)}: ${member.key === "$" ? label : expression(member.type, `row[${JSON.stringify(member.key)}]`, owner, parameters)}`
      )
      return `case ${label}: return { ${fields.join(", ")} };`
    })
    return `(() => { const row = object(${value}); switch (row["$"]) { ${cases.join("\n")} default: throw new TypeError("Unexpected Bend constructor") } })()`
  }
  return unsupported(node)
}
while (pending.length) {
  const name = pending.shift()
  if (name === undefined || emitted.has(name)) continue
  emitted.add(name)
  const alias = aliases.get(name)
  if (!alias) throw new Error(`Missing serialized ABI root ${name}`)
  const owner = name.split(".").slice(0, -1).join(".")
  const parameters = alias.typeParameters?.map((parameter) => parameter.name.text) ?? []
  const generic = parameters.length ? `<${parameters.join(", ")}>` : ""
  const inputs = [
    "value: unknown",
    ...parameters.map((parameter) => `parse${parameter}: (value: unknown) => ${parameter}`)
  ]
  const result = expression(alias.type, "value", owner, new Set(parameters))
  functions.push(
    `${roots.includes(name) ? "export " : ""}function ${parserName(name)}${generic}(${inputs.join(", ")}): BendABI.${name}${generic} {\nreturn ${result}\n}`
  )
}
const helpers = `// Generated by scripts/generate-bend-codecs.mts. Do not edit.
import { object, number, text, boolean, parseBendList as parseList } from "./host-values.mts"
function parseMaybe<T>(value: unknown, parse: (value: unknown) => T): BendMaybe<T> {
  const row = object(value)
  switch (row["$"]) {
    case "None": return { $: "None" }
    case "Some": return { $: "Some", value: parse(row["value"]) }
    default: throw new TypeError("Expected a Bend Maybe")
  }
}
`
const usedHelpers = functions.some((body) => body.includes("parseMaybe("))
  ? helpers
  : helpers.slice(0, helpers.indexOf("function parseMaybe"))
fs.writeFileSync(outputPath, `${usedHelpers}\n${functions.join("\n\n")}\n`)
console.log(`Bend host codecs: ${path.relative(root, outputPath)} (${emitted.size} reachable types)`)
