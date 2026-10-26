import { object } from "./survivors/host-values.mts"

// The generated ABI owns signatures; this import boundary checks the requested
// runtime exports and exposes only those checked members to the consumer.
export function bendModule<API extends object>() {
  return async <const Keys extends readonly (keyof API & string)[]>(
    location: string | URL,
    required: Keys
  ): Promise<{ default: Pick<API, Keys[number]> }> => {
    const loaded: unknown = await import(String(location))
    const api = object(object(loaded).default)
    const checked: Record<string, unknown> = {}
    for (const key of required) {
      const value = api[key]
      if (typeof value !== "function") throw new TypeError(`Missing Bend function export: ${key}`)
      checked[key] = value
    }
    return { default: checked as Pick<API, Keys[number]> }
  }
}
