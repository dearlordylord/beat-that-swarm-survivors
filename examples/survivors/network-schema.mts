export type WireSpec =
  | "u32"
  | "f32"
  | "f64"
  | "nat"
  | "bool"
  | "string"
  | { list: WireSpec }
  | { maybe: WireSpec }
  | { ref: string }
export type WireFields = readonly (readonly [string, WireSpec])[]
export type WireSchema = Readonly<Record<string, readonly (readonly [string, WireFields])[]>>
