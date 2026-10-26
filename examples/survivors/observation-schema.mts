export type Primitive = "u32" | "f32" | "nat" | "bool" | "string"
export type Fields = readonly (readonly [string, Spec])[]
export type Spec =
  | Primitive
  | {
      ref?: string
      list?: Spec
      array?: Spec
      tuple?: readonly Spec[]
      record?: Fields
      literal?: string | boolean | number
      nullable?: Spec
      unchecked?: boolean
    }
export type Schema = Record<string, Record<string, Fields>>
