// Host shape checks only. Eligibility, normalization and gameplay belong to Bend.
function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}
export function object(value: unknown): Record<string, unknown> {
  if (!isObject(value)) throw new TypeError("Expected an object")
  return value
}
export function number(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) throw new TypeError("Expected a finite number")
  return value
}
export function text(value: unknown): string {
  if (typeof value !== "string") throw new TypeError("Expected text")
  return value
}
export function boolean(value: unknown): boolean {
  if (typeof value !== "boolean") throw new TypeError("Expected a boolean")
  return value
}
export function array<T>(value: unknown, parse: (value: unknown) => T): T[] {
  if (!Array.isArray(value)) throw new TypeError("Expected an array")
  return value.map(parse)
}
export function at<T>(values: { readonly [index: number]: T }, index: number): T {
  const value = values[index]
  if (value === undefined) throw new RangeError(`Missing item at ${index}`)
  return value
}
export function list<T>(values: readonly T[]): BendList<T> {
  let tail: BendList<T> = { $: "Nil" }
  for (const head of values.toReversed()) tail = { $: "Con", head, tail }
  return tail
}
export function rows<T>(value: BendList<T>): T[] {
  const result: T[] = []
  for (let row = value; row.$ === "Con"; row = row.tail) result.push(row.head)
  return result
}
export function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error)
}
export function errorCode(error: unknown): unknown {
  return typeof error === "object" && error !== null && "code" in error ? error.code : undefined
}
export function defined<T>(value: T | null | undefined): T {
  if (value === undefined || value === null) throw new TypeError("Missing required value")
  return value
}
export function some<T>(value: BendMaybe<T>): T {
  if (value.$ !== "Some") throw new TypeError("Expected a Bend Some value")
  return value.value
}

export function displayText(value: unknown): string {
  const rendered = String(value)
  return value === null || value === undefined ? "" : rendered
}
