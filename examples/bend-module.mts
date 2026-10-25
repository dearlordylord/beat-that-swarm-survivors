import { object } from "./survivors/host-values.mts"

// The generated ABI owns signatures; this import boundary checks the requested
// runtime exports and exposes only those checked members to the consumer.
export function bendModule<API extends object>() {
  return async <
    const Keys extends readonly (keyof API & string)[],
    const Optional extends readonly (keyof API & string)[] = readonly []
  >(
    location: string | URL,
    required: Keys,
    optional?: Optional
  ): Promise<{ default: Pick<API, Keys[number]> & Partial<Pick<API, Optional[number]>> }> => {
    const loaded: unknown = await import(String(location))
    const api = object(object(loaded).default)
    const checked: Record<string, unknown> = {}
    for (const key of required) {
      const value = api[key]
      if (typeof value !== "function") throw new TypeError(`Missing Bend function export: ${key}`)
      checked[key] = value
    }
    for (const key of optional ?? []) {
      const value = api[key]
      if (value === undefined) continue
      if (typeof value !== "function") throw new TypeError(`Invalid optional Bend function export: ${key}`)
      checked[key] = value
    }
    return { default: checked as Pick<API, Keys[number]> & Partial<Pick<API, Optional[number]>> }
  }
}
