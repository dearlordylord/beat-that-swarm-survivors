import { array, boolean, number, object, text } from "./host-values.mts"
export interface Stats {
  kills: number
  totalgold: number
  survive: number
  wins: number
  evolutions: number
  levels: number
  characters: number
  stages: number
  weapons: number
  revivals: number
  bosskills: number
  characterwins: number
  relics: number
}
export interface Profile {
  version: number
  gold: number
  meta: number[]
  characters: number[]
  stages: number[]
  achievements: string[]
  stats: Stats
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
const statKeys: (keyof Stats)[] = [
  "kills",
  "totalgold",
  "survive",
  "wins",
  "evolutions",
  "levels",
  "characters",
  "stages",
  "weapons",
  "revivals",
  "bosskills",
  "characterwins",
  "relics"
]
function isStatKey(value: string): value is keyof Stats {
  return statKeys.some((key) => key === value)
}
export function profileStat(stats: Stats, key: string): number {
  if (!isStatKey(key)) throw new TypeError(`Unknown profile statistic: ${key}`)
  return stats[key]
}
function nonnegative(value: unknown): number {
  const result = number(value)
  if (result < 0) throw new TypeError("Expected a nonnegative profile value")
  return result
}
function natural(value: unknown): number {
  const result = nonnegative(value)
  if (!Number.isInteger(result) || result > 4294967295) throw new TypeError("Expected an integer profile value")
  return result
}
export function parseProfile(value: unknown): Profile {
  const p = object(value),
    settings = object(p.settings),
    collection = object(p.collection),
    stats = object(p.stats)
  if (p.version !== 1 || Object.keys(stats).some((key) => !isStatKey(key))) throw new TypeError("Invalid profile shape")
  return {
    version: 1,
    gold: nonnegative(p.gold),
    meta: array(p.meta, natural),
    characters: array(p.characters, natural),
    stages: array(p.stages, natural),
    achievements: array(p.achievements, text),
    stats: {
      kills: nonnegative(stats.kills),
      totalgold: nonnegative(stats.totalgold),
      survive: nonnegative(stats.survive),
      wins: nonnegative(stats.wins),
      evolutions: nonnegative(stats.evolutions),
      levels: nonnegative(stats.levels),
      characters: nonnegative(stats.characters),
      stages: nonnegative(stats.stages),
      weapons: nonnegative(stats.weapons),
      revivals: nonnegative(stats.revivals),
      bosskills: nonnegative(stats.bosskills),
      characterwins: nonnegative(stats.characterwins),
      relics: nonnegative(stats.relics)
    },
    collection: {
      weapons: array(collection.weapons, natural),
      evolutions: array(collection.evolutions, natural),
      enemies: array(collection.enemies, natural)
    },
    stageRelics: array(p.stageRelics, natural),
    wonCharacters: array(p.wonCharacters, natural),
    recorded: array(p.recorded, text),
    settings: {
      muted: boolean(settings.muted),
      volume: number(settings.volume),
      reducedMotion: boolean(settings.reducedMotion),
      showDamage: boolean(settings.showDamage)
    }
  }
}
