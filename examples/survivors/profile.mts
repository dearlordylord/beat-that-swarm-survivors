import { array, boolean, number, object, text } from "./host-values.mts"
// Shapes of serialized results from menu-progression.bend. No game rules here.
export interface Profile {
  version: number
  gold: number
  meta: number[]
  characters: number[]
  stages: number[]
  achievements: string[]
  stats: Record<string, number>
  collection: { weapons: number[]; evolutions: number[]; enemies: number[] }
  stageRelics: number[]
  wonCharacters: number[]
  recorded: string[]
  settings: { muted: boolean; volume: number; reducedMotion: boolean; showDamage: boolean }
}
export interface Setup {
  character: number
  stage: number
  arcana: number
  mode: number
}
export type SetupKind = keyof Setup
export interface MenuState extends Setup {
  profile: Profile
  openPanel?: string | null
  pendingUnlock?: { kind: string; id: number } | null
  staticPickers?: boolean
}
export function parseProfile(value: unknown): Profile {
  const p = object(value),
    settings = object(p.settings),
    collection = object(p.collection)
  return {
    version: number(p.version),
    gold: number(p.gold),
    meta: array(p.meta, number),
    characters: array(p.characters, number),
    stages: array(p.stages, number),
    achievements: array(p.achievements, text),
    stats: Object.fromEntries(Object.entries(object(p.stats)).map(([k, v]) => [k, number(v)])),
    collection: {
      weapons: array(collection.weapons, number),
      evolutions: array(collection.evolutions, number),
      enemies: array(collection.enemies, number)
    },
    stageRelics: array(p.stageRelics, number),
    wonCharacters: array(p.wonCharacters, number),
    recorded: array(p.recorded, text),
    settings: {
      muted: boolean(settings.muted),
      volume: number(settings.volume),
      reducedMotion: boolean(settings.reducedMotion),
      showDamage: boolean(settings.showDamage)
    }
  }
}
export function parseSetup(value: unknown): Setup {
  const s = object(value)
  return { character: number(s.character), stage: number(s.stage), arcana: number(s.arcana), mode: number(s.mode) }
}
