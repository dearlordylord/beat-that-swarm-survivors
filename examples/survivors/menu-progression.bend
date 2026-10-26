import Base
import menu-amount.bend as A

type Stat is Data:
  Kills{}
  TotalGold{}
  Survive{}
  Wins{}
  Evolutions{}
  Levels{}
  Characters{}
  Stages{}
  Weapons{}
  Revivals{}
  BossKills{}
  CharacterWins{}
  Relics{}

type SelectionKind is Data: Character{} Stage{} Arcana{} Mode{} Weapon{}

type Stats is Data: Stats{kills: A.Amount,totalgold: A.Amount,survive: A.Amount,wins: A.Amount,evolutions: A.Amount,levels: A.Amount,characters: A.Amount,stages: A.Amount,weapons: A.Amount,revivals: A.Amount,bosskills: A.Amount,characterwins: A.Amount,relics: A.Amount}

type Collection is Data: Collection{weapons: List<&2,U32>,evolutions: List<&2,U32>,enemies: List<&2,U32>}

type Progress is Data: Progress{gold: A.Amount,meta: List<&2,Nat>,characters: List<&2,U32>,stages: List<&2,U32>,achievements: List<&2,String>,stats: Stats,collection: Collection,stageRelics: List<&2,U32>,wonCharacters: List<&2,U32>,recorded: List<&2,String>}

type Setup is Data: Setup{character: U32,stage: U32,arcana: U32,mode: U32}

type Condition is Data: Condition{stat: Stat,threshold: A.Amount}

type UnlockEntry is Data: UnlockEntry{id: U32,cost: A.Amount,condition: Maybe<&2,Condition>}

type ModeEntry is Data: ModeEntry{id: U32,condition: Maybe<&2,Condition>}

type Upgrade is Data: Upgrade{id: U32,costBase: Nat,maxLevel: Nat}

type WeaponUnlock is Data: WeaponUnlock{id: U32,condition: Maybe<&2,Condition>,stageRelic: Maybe<&2,U32>}

type Achievement is Data: Achievement{id: String,conditions: List<&2,Condition>}

type Catalog is Data: Catalog{characters: List<&2,UnlockEntry>,stages: List<&2,UnlockEntry>,arcana: List<&2,U32>,modes: List<&2,ModeEntry>,upgrades: List<&2,Upgrade>,weapons: List<&2,U32>,weaponUnlocks: List<&2,WeaponUnlock>,achievements: List<&2,Achievement>}

type History is Data: History{usedWeapons: List<&2,U32>,evolvedWeapons: List<&2,U32>}

type RunReceipt is Data: RunReceipt{runId: String,character: U32,stage: U32,tick: Nat,gold: A.Amount,kills: A.Amount,level: A.Amount,phase: U32,revivalsUsed: A.Amount,bossesKilled: A.Amount,relicCollected: Bool,weapons: List<&2,Nat>,enemiesKilled: List<&2,U32>,history: History}

type UpgradeStatus is Data: UpgradeStatus{rank: Nat,cost: Maybe<&2,A.Amount>,maxed: Bool,canBuy: Bool}

type PurchaseStatus is Data: PurchaseStatus{owned: Bool,eligible: Bool,affordable: Bool,canBuy: Bool,missingGold: A.Amount,cost: Maybe<&2,A.Amount>}

type RecordResult is Data: RecordResult{profile: Progress,added: List<&2,String>}

def progress_gold(+value: Progress) -> A.Amount:
  match value:
    case Progress{gold,_,_,_,_,_,_,_,_,_}: gold

def progress_meta(+value: Progress) -> List<&2,Nat>:
  match value:
    case Progress{_,meta,_,_,_,_,_,_,_,_}: meta

def progress_characters(+value: Progress) -> List<&2,U32>:
  match value:
    case Progress{_,_,characters,_,_,_,_,_,_,_}: characters

def progress_stages(+value: Progress) -> List<&2,U32>:
  match value:
    case Progress{_,_,_,stages,_,_,_,_,_,_}: stages

def progress_achievements(+value: Progress) -> List<&2,String>:
  match value:
    case Progress{_,_,_,_,achievements,_,_,_,_,_}: achievements

def progress_stats(+value: Progress) -> Stats:
  match value:
    case Progress{_,_,_,_,_,stats,_,_,_,_}: stats

def progress_collection(+value: Progress) -> Collection:
  match value:
    case Progress{_,_,_,_,_,_,collection,_,_,_}: collection

def progress_stageRelics(+value: Progress) -> List<&2,U32>:
  match value:
    case Progress{_,_,_,_,_,_,_,stageRelics,_,_}: stageRelics

def progress_wonCharacters(+value: Progress) -> List<&2,U32>:
  match value:
    case Progress{_,_,_,_,_,_,_,_,wonCharacters,_}: wonCharacters

def progress_recorded(+value: Progress) -> List<&2,String>:
  match value:
    case Progress{_,_,_,_,_,_,_,_,_,recorded}: recorded

def catalog_characters(+value: Catalog) -> List<&2,UnlockEntry>:
  match value:
    case Catalog{characters,_,_,_,_,_,_,_}: characters

def catalog_stages(+value: Catalog) -> List<&2,UnlockEntry>:
  match value:
    case Catalog{_,stages,_,_,_,_,_,_}: stages

def catalog_arcana(+value: Catalog) -> List<&2,U32>:
  match value:
    case Catalog{_,_,arcana,_,_,_,_,_}: arcana

def catalog_modes(+value: Catalog) -> List<&2,ModeEntry>:
  match value:
    case Catalog{_,_,_,modes,_,_,_,_}: modes

def catalog_upgrades(+value: Catalog) -> List<&2,Upgrade>:
  match value:
    case Catalog{_,_,_,_,upgrades,_,_,_}: upgrades

def catalog_weapons(+value: Catalog) -> List<&2,U32>:
  match value:
    case Catalog{_,_,_,_,_,weapons,_,_}: weapons

def catalog_weaponUnlocks(+value: Catalog) -> List<&2,WeaponUnlock>:
  match value:
    case Catalog{_,_,_,_,_,_,weaponUnlocks,_}: weaponUnlocks

def catalog_achievements(+value: Catalog) -> List<&2,Achievement>:
  match value:
    case Catalog{_,_,_,_,_,_,_,achievements}: achievements

def run_runId(+value: RunReceipt) -> String:
  match value:
    case RunReceipt{runId,_,_,_,_,_,_,_,_,_,_,_,_,_}: runId

def run_character(+value: RunReceipt) -> U32:
  match value:
    case RunReceipt{_,character,_,_,_,_,_,_,_,_,_,_,_,_}: character

def run_stage(+value: RunReceipt) -> U32:
  match value:
    case RunReceipt{_,_,stage,_,_,_,_,_,_,_,_,_,_,_}: stage

def run_tick(+value: RunReceipt) -> Nat:
  match value:
    case RunReceipt{_,_,_,tick,_,_,_,_,_,_,_,_,_,_}: tick

def run_gold(+value: RunReceipt) -> A.Amount:
  match value:
    case RunReceipt{_,_,_,_,gold,_,_,_,_,_,_,_,_,_}: gold

def run_kills(+value: RunReceipt) -> A.Amount:
  match value:
    case RunReceipt{_,_,_,_,_,kills,_,_,_,_,_,_,_,_}: kills

def run_level(+value: RunReceipt) -> A.Amount:
  match value:
    case RunReceipt{_,_,_,_,_,_,level,_,_,_,_,_,_,_}: level

def run_phase(+value: RunReceipt) -> U32:
  match value:
    case RunReceipt{_,_,_,_,_,_,_,phase,_,_,_,_,_,_}: phase

def run_revivalsUsed(+value: RunReceipt) -> A.Amount:
  match value:
    case RunReceipt{_,_,_,_,_,_,_,_,revivalsUsed,_,_,_,_,_}: revivalsUsed

def run_bossesKilled(+value: RunReceipt) -> A.Amount:
  match value:
    case RunReceipt{_,_,_,_,_,_,_,_,_,bossesKilled,_,_,_,_}: bossesKilled

def run_relicCollected(+value: RunReceipt) -> Bool:
  match value:
    case RunReceipt{_,_,_,_,_,_,_,_,_,_,relicCollected,_,_,_}: relicCollected

def run_weapons(+value: RunReceipt) -> List<&2,Nat>:
  match value:
    case RunReceipt{_,_,_,_,_,_,_,_,_,_,_,weapons,_,_}: weapons

def run_enemiesKilled(+value: RunReceipt) -> List<&2,U32>:
  match value:
    case RunReceipt{_,_,_,_,_,_,_,_,_,_,_,_,enemiesKilled,_}: enemiesKilled

def run_history(+value: RunReceipt) -> History:
  match value:
    case RunReceipt{_,_,_,_,_,_,_,_,_,_,_,_,_,history}: history

def history_usedWeapons(+value: History) -> List<&2,U32>:
  match value:
    case History{usedWeapons,_}: usedWeapons

def history_evolvedWeapons(+value: History) -> List<&2,U32>:
  match value:
    case History{_,evolvedWeapons}: evolvedWeapons

def collection_weapons(+value: Collection) -> List<&2,U32>:
  match value:
    case Collection{weapons,_,_}: weapons

def upgrade_id(+value: Upgrade) -> U32:
  match value:
    case Upgrade{id,_,_}: id

def upgrade_maxLevel(+value: Upgrade) -> Nat:
  match value:
    case Upgrade{_,_,maxLevel}: maxLevel

def unlockentry_id(+value: UnlockEntry) -> U32:
  match value:
    case UnlockEntry{id,_,_}: id

def modeentry_id(+value: ModeEntry) -> U32:
  match value:
    case ModeEntry{id,_}: id

def weaponunlock_id(+value: WeaponUnlock) -> U32:
  match value:
    case WeaponUnlock{id,_,_}: id

def upgrade_status_canBuy(+value: UpgradeStatus) -> Bool:
  match value:
    case UpgradeStatus{_,_,_,canBuy}: canBuy

def purchase_status_canBuy(+value: PurchaseStatus) -> Bool:
  match value:
    case PurchaseStatus{_,_,_,canBuy,_,_}: canBuy

def record_profile(+value: RecordResult) -> Progress:
  match value:
    case RecordResult{profile,_}: profile

def record_added(+value: RecordResult) -> List<&2,String>:
  match value:
    case RecordResult{_,added}: added

def setup_character(+value: Setup) -> U32:
  match value:
    case Setup{character,_,_,_}: character

def setup_stage(+value: Setup) -> U32:
  match value:
    case Setup{_,stage,_,_}: stage

def setup_arcana(+value: Setup) -> U32:
  match value:
    case Setup{_,_,arcana,_}: arcana

def setup_mode(+value: Setup) -> U32:
  match value:
    case Setup{_,_,_,mode}: mode

def set_gold(+profile: Progress,+value: A.Amount) -> Progress:
  match profile:
    case Progress{_,meta,characters,stages,achievements,stats,collection,stageRelics,wonCharacters,recorded}: Progress{value,meta,characters,stages,achievements,stats,collection,stageRelics,wonCharacters,recorded}

def set_meta(+profile: Progress,+value: List<&2,Nat>) -> Progress:
  match profile:
    case Progress{gold,_,characters,stages,achievements,stats,collection,stageRelics,wonCharacters,recorded}: Progress{gold,value,characters,stages,achievements,stats,collection,stageRelics,wonCharacters,recorded}

def set_characters(+profile: Progress,+value: List<&2,U32>) -> Progress:
  match profile:
    case Progress{gold,meta,_,stages,achievements,stats,collection,stageRelics,wonCharacters,recorded}: Progress{gold,meta,value,stages,achievements,stats,collection,stageRelics,wonCharacters,recorded}

def set_stages(+profile: Progress,+value: List<&2,U32>) -> Progress:
  match profile:
    case Progress{gold,meta,characters,_,achievements,stats,collection,stageRelics,wonCharacters,recorded}: Progress{gold,meta,characters,value,achievements,stats,collection,stageRelics,wonCharacters,recorded}

def set_achievements(+profile: Progress,+value: List<&2,String>) -> Progress:
  match profile:
    case Progress{gold,meta,characters,stages,_,stats,collection,stageRelics,wonCharacters,recorded}: Progress{gold,meta,characters,stages,value,stats,collection,stageRelics,wonCharacters,recorded}

def set_stats(+profile: Progress,+value: Stats) -> Progress:
  match profile:
    case Progress{gold,meta,characters,stages,achievements,_,collection,stageRelics,wonCharacters,recorded}: Progress{gold,meta,characters,stages,achievements,value,collection,stageRelics,wonCharacters,recorded}

def set_collection(+profile: Progress,+value: Collection) -> Progress:
  match profile:
    case Progress{gold,meta,characters,stages,achievements,stats,_,stageRelics,wonCharacters,recorded}: Progress{gold,meta,characters,stages,achievements,stats,value,stageRelics,wonCharacters,recorded}

def set_stageRelics(+profile: Progress,+value: List<&2,U32>) -> Progress:
  match profile:
    case Progress{gold,meta,characters,stages,achievements,stats,collection,_,wonCharacters,recorded}: Progress{gold,meta,characters,stages,achievements,stats,collection,value,wonCharacters,recorded}

def set_wonCharacters(+profile: Progress,+value: List<&2,U32>) -> Progress:
  match profile:
    case Progress{gold,meta,characters,stages,achievements,stats,collection,stageRelics,_,recorded}: Progress{gold,meta,characters,stages,achievements,stats,collection,stageRelics,value,recorded}

def set_recorded(+profile: Progress,+value: List<&2,String>) -> Progress:
  match profile:
    case Progress{gold,meta,characters,stages,achievements,stats,collection,stageRelics,wonCharacters,_}: Progress{gold,meta,characters,stages,achievements,stats,collection,stageRelics,wonCharacters,value}

def stat(+key: Stat,+stats: Stats) -> A.Amount:
  match key stats:

    case Kills{} Stats{kills,_,_,_,_,_,_,_,_,_,_,_,_}: kills

    case TotalGold{} Stats{_,totalgold,_,_,_,_,_,_,_,_,_,_,_}: totalgold

    case Survive{} Stats{_,_,survive,_,_,_,_,_,_,_,_,_,_}: survive

    case Wins{} Stats{_,_,_,wins,_,_,_,_,_,_,_,_,_}: wins

    case Evolutions{} Stats{_,_,_,_,evolutions,_,_,_,_,_,_,_,_}: evolutions

    case Levels{} Stats{_,_,_,_,_,levels,_,_,_,_,_,_,_}: levels

    case Characters{} Stats{_,_,_,_,_,_,characters,_,_,_,_,_,_}: characters

    case Stages{} Stats{_,_,_,_,_,_,_,stages,_,_,_,_,_}: stages

    case Weapons{} Stats{_,_,_,_,_,_,_,_,weapons,_,_,_,_}: weapons

    case Revivals{} Stats{_,_,_,_,_,_,_,_,_,revivals,_,_,_}: revivals

    case BossKills{} Stats{_,_,_,_,_,_,_,_,_,_,bosskills,_,_}: bosskills

    case CharacterWins{} Stats{_,_,_,_,_,_,_,_,_,_,_,characterwins,_}: characterwins

    case Relics{} Stats{_,_,_,_,_,_,_,_,_,_,_,_,relics}: relics

def set_stat(+key: Stat,+stats: Stats,+value: A.Amount) -> Stats:
  match key stats:

    case Kills{} Stats{_,totalgold,survive,wins,evolutions,levels,characters,stages,weapons,revivals,bosskills,characterwins,relics}: Stats{value,totalgold,survive,wins,evolutions,levels,characters,stages,weapons,revivals,bosskills,characterwins,relics}

    case TotalGold{} Stats{kills,_,survive,wins,evolutions,levels,characters,stages,weapons,revivals,bosskills,characterwins,relics}: Stats{kills,value,survive,wins,evolutions,levels,characters,stages,weapons,revivals,bosskills,characterwins,relics}

    case Survive{} Stats{kills,totalgold,_,wins,evolutions,levels,characters,stages,weapons,revivals,bosskills,characterwins,relics}: Stats{kills,totalgold,value,wins,evolutions,levels,characters,stages,weapons,revivals,bosskills,characterwins,relics}

    case Wins{} Stats{kills,totalgold,survive,_,evolutions,levels,characters,stages,weapons,revivals,bosskills,characterwins,relics}: Stats{kills,totalgold,survive,value,evolutions,levels,characters,stages,weapons,revivals,bosskills,characterwins,relics}

    case Evolutions{} Stats{kills,totalgold,survive,wins,_,levels,characters,stages,weapons,revivals,bosskills,characterwins,relics}: Stats{kills,totalgold,survive,wins,value,levels,characters,stages,weapons,revivals,bosskills,characterwins,relics}

    case Levels{} Stats{kills,totalgold,survive,wins,evolutions,_,characters,stages,weapons,revivals,bosskills,characterwins,relics}: Stats{kills,totalgold,survive,wins,evolutions,value,characters,stages,weapons,revivals,bosskills,characterwins,relics}

    case Characters{} Stats{kills,totalgold,survive,wins,evolutions,levels,_,stages,weapons,revivals,bosskills,characterwins,relics}: Stats{kills,totalgold,survive,wins,evolutions,levels,value,stages,weapons,revivals,bosskills,characterwins,relics}

    case Stages{} Stats{kills,totalgold,survive,wins,evolutions,levels,characters,_,weapons,revivals,bosskills,characterwins,relics}: Stats{kills,totalgold,survive,wins,evolutions,levels,characters,value,weapons,revivals,bosskills,characterwins,relics}

    case Weapons{} Stats{kills,totalgold,survive,wins,evolutions,levels,characters,stages,_,revivals,bosskills,characterwins,relics}: Stats{kills,totalgold,survive,wins,evolutions,levels,characters,stages,value,revivals,bosskills,characterwins,relics}

    case Revivals{} Stats{kills,totalgold,survive,wins,evolutions,levels,characters,stages,weapons,_,bosskills,characterwins,relics}: Stats{kills,totalgold,survive,wins,evolutions,levels,characters,stages,weapons,value,bosskills,characterwins,relics}

    case BossKills{} Stats{kills,totalgold,survive,wins,evolutions,levels,characters,stages,weapons,revivals,_,characterwins,relics}: Stats{kills,totalgold,survive,wins,evolutions,levels,characters,stages,weapons,revivals,value,characterwins,relics}

    case CharacterWins{} Stats{kills,totalgold,survive,wins,evolutions,levels,characters,stages,weapons,revivals,bosskills,_,relics}: Stats{kills,totalgold,survive,wins,evolutions,levels,characters,stages,weapons,revivals,bosskills,value,relics}

    case Relics{} Stats{kills,totalgold,survive,wins,evolutions,levels,characters,stages,weapons,revivals,bosskills,characterwins,_}: Stats{kills,totalgold,survive,wins,evolutions,levels,characters,stages,weapons,revivals,bosskills,characterwins,value}

def contains_id(+rows: List<&2,U32>,+id: U32) -> Bool: List.contains(~U32,~U32.is_eq,rows,id)
def contains_text(+rows: List<&2,String>,+id: String) -> Bool: List.contains(~String,~String.eq,rows,id)
def append_id_decided(+seen: Bool,+rows: List<&2,U32>,+id: U32) -> List<&2,U32>:
  match seen:
    case True{}: rows
    case False{}: List.append(&2,U32,rows,[id])
def append_id(+rows: List<&2,U32>,+id: U32) -> List<&2,U32>: append_id_decided(contains_id(rows,id),rows,id)
def maybe_id(+test: Bool,+rows: List<&2,U32>,+id: U32) -> List<&2,U32>:
  match test:
    case True{}: append_id(rows,id)
    case False{}: rows
def rank_at(+rows: List<&2,Nat>,+index: Nat) -> Nat:
  match rows index:
    case Con{head,_} 0n: head
    case Con{_,tail} 1n+p: rank_at(tail,p)
    case _ _: 0n
def replace_at(+rows: List<&2,Nat>,+index: Nat,+value: Nat) -> List<&2,Nat>:
  match rows index:
    case Con{_,tail} 0n: value <> tail
    case Con{head,tail} 1n+p: head <> replace_at(tail,p,value)
    case _ _: []
def fresh() -> Progress:
  Progress{A.zero(),[0n,0n,0n,0n,0n,0n,0n,0n,0n,0n],[0],[0],[],Stats{A.zero(),A.zero(),A.zero(),A.zero(),A.zero(),A.one(),A.one(),A.one(),A.zero(),A.zero(),A.zero(),A.zero(),A.zero()},Collection{[],[],[]},[],[],[]}
def upgrade_find(+rows: List<&2,Upgrade>,+id: U32) -> Maybe<&2,Upgrade>:
  match rows:
    case Nil{}: None{}
    case Con{+head,tail}: Bool.pick(Maybe<&2,Upgrade>,U32.is_eq(upgrade_id(head),id),Some{head},upgrade_find(tail,id))
def upgrade_item(+catalog: Catalog,+id: U32) -> Maybe<&2,Upgrade>: upgrade_find(catalog_upgrades(catalog),id)
def unlock_find(+rows: List<&2,UnlockEntry>,+id: U32) -> Maybe<&2,UnlockEntry>:
  match rows:
    case Nil{}: None{}
    case Con{+head,tail}: Bool.pick(Maybe<&2,UnlockEntry>,U32.is_eq(unlockentry_id(head),id),Some{head},unlock_find(tail,id))
def unlock_item(+kind: SelectionKind,+catalog: Catalog,+id: U32) -> Maybe<&2,UnlockEntry>:
  match kind:
    case Character{}: unlock_find(catalog_characters(catalog),id)
    case Stage{}: unlock_find(catalog_stages(catalog),id)
    case _: None{}
def mode_find(+rows: List<&2,ModeEntry>,+id: U32) -> Maybe<&2,ModeEntry>:
  match rows:
    case Nil{}: None{}
    case Con{+head,tail}: Bool.pick(Maybe<&2,ModeEntry>,U32.is_eq(modeentry_id(head),id),Some{head},mode_find(tail,id))
def has_unlock(+entry: Maybe<&2,UnlockEntry>) -> Bool:
  match entry:
    case Some{_}: True{}
    case None{}: False{}
def has_upgrade(+entry: Maybe<&2,Upgrade>) -> Bool:
  match entry:
    case Some{_}: True{}
    case None{}: False{}
def mode_present(+entry: Maybe<&2,ModeEntry>) -> Bool:
  match entry:
    case Some{_}: True{}
    case None{}: False{}
def catalog_member(+kind: SelectionKind,+id: U32,+catalog: Catalog) -> Bool:
  match kind:
    case Character{}: has_unlock(unlock_find(catalog_characters(catalog),id))
    case Stage{}: has_unlock(unlock_find(catalog_stages(catalog),id))
    case Arcana{}: contains_id(catalog_arcana(catalog),id)
    case Mode{}: mode_present(mode_find(catalog_modes(catalog),id))
    case Weapon{}: contains_id(catalog_weapons(catalog),id)
def requirements_met(+profile: Progress,+condition: Maybe<&2,Condition>) -> Bool:
  match condition:
    case None{}: True{}
    case Some{Condition{key,threshold}}: A.ge(stat(key,progress_stats(profile)),threshold)
def mode_allowed(+entry: Maybe<&2,ModeEntry>,+profile: Progress) -> Bool:
  match entry:
    case None{}: False{}
    case Some{ModeEntry{_,condition}}: requirements_met(profile,condition)
def weapon_allowed(+entry: WeaponUnlock,+profile: Progress) -> Bool:
  match entry:
    case WeaponUnlock{_,condition,None{}}: requirements_met(profile,condition)
    case WeaponUnlock{_,_,Some{relic}}: contains_id(progress_stageRelics(profile),relic)
def allowed_go(+rows: List<&2,WeaponUnlock>,+profile: Progress,+mask: U32) -> U32:
  match rows:
    case Nil{}: mask
    case Con{+head,tail}: allowed_go(tail,profile,U32.and(mask,U32.not((Bool.to_u32(Bool.not(weapon_allowed(head,profile))) * U32.shln(1,U32.to_nat(weaponunlock_id(head))) : U32))))
def allowed_weapons(+profile: Progress,+catalog: Catalog) -> U32: allowed_go(catalog_weaponUnlocks(catalog),profile,16777215)
def owned(+profile: Progress,+kind: SelectionKind) -> List<&2,U32>:
  match kind:
    case Character{}: progress_characters(profile)
    case _: progress_stages(profile)
def set_owned(+profile: Progress,+kind: SelectionKind,+rows: List<&2,U32>) -> Progress:
  match kind:
    case Character{}: set_characters(profile,rows)
    case _: set_stages(profile,rows)
def add_owned(+profile: Progress,+kind: SelectionKind,+id: U32) -> Progress: set_owned(profile,kind,append_id(owned(profile,kind),id))
def unlocked(+profile: Progress,+kind: SelectionKind,+id: U32,+catalog: Catalog) -> Bool:
  match kind:
    case Arcana{}: contains_id(catalog_arcana(catalog),id)
    case Mode{}: mode_allowed(mode_find(catalog_modes(catalog),id),profile)
    case Weapon{}: U32.is_ne(U32.and(allowed_weapons(profile,catalog),U32.shln(1,U32.to_nat(id))),0)
    case kind: contains_id(owned(profile,kind),id)
def upgrade_quoted(+entry: Maybe<&2,Upgrade>,+profile: Progress,+id: U32) -> Maybe<&2,A.Amount>:
  match entry:
    case None{}: None{}
    case Some{Upgrade{_,base,_}}: Some{A.natural(Nat.div(Nat.mul(base,Nat.add(4n,Nat.mul(rank_at(progress_meta(profile),U32.to_nat(id)),3n))),4n))}
def upgrade_cost(+profile: Progress,+id: U32,+catalog: Catalog) -> Maybe<&2,A.Amount>: upgrade_quoted(upgrade_item(catalog,id),profile,id)
def cost_value(+cost: Maybe<&2,A.Amount>) -> A.Amount:
  match cost:
    case None{}: A.zero()
    case Some{cost}: cost
def upgrade_cap(+entry: Maybe<&2,Upgrade>) -> Nat:
  match entry:
    case None{}: 0n
    case Some{Upgrade{_,_,cap}}: cap
def upgrade_admitted(+profile: Progress,+id: U32,+catalog: Catalog) -> Bool:
  Bool.and(has_upgrade(upgrade_item(catalog,id)),Bool.and(Bool.not(Nat.is_ge(rank_at(progress_meta(profile),U32.to_nat(id)),upgrade_cap(upgrade_item(catalog,id)))),A.ge(progress_gold(profile),cost_value(upgrade_cost(profile,id,catalog)))))
def upgrade_status(+profile: Progress,+id: U32,+catalog: Catalog) -> UpgradeStatus:
  UpgradeStatus{rank_at(progress_meta(profile),U32.to_nat(id)),upgrade_cost(profile,id,catalog),Nat.is_ge(rank_at(progress_meta(profile),U32.to_nat(id)),upgrade_cap(upgrade_item(catalog,id))),upgrade_admitted(profile,id,catalog)}
def buy_upgrade_ok(+profile: Progress,+id: U32,+catalog: Catalog) -> Progress:
  set_meta(set_gold(profile,A.subtract(progress_gold(profile),cost_value(upgrade_cost(profile,id,catalog)))),replace_at(progress_meta(profile),U32.to_nat(id),Nat.add(rank_at(progress_meta(profile),U32.to_nat(id)),1n)))
def purchase_decided(+admitted: Bool,+paid: Progress) -> Maybe<&2,Progress>:
  match admitted:
    case True{}: Some{paid}
    case False{}: None{}
def buy_upgrade(+profile: Progress,+id: U32,+catalog: Catalog) -> Maybe<&2,Progress>: purchase_decided(upgrade_admitted(profile,id,catalog),buy_upgrade_ok(profile,id,catalog))
def unlock_cost(+entry: Maybe<&2,UnlockEntry>) -> A.Amount:
  match entry:
    case None{}: A.zero()
    case Some{UnlockEntry{_,cost,_}}: cost
def unlock_price(+entry: Maybe<&2,UnlockEntry>) -> Maybe<&2,A.Amount>:
  match entry:
    case None{}: None{}
    case Some{UnlockEntry{_,cost,_}}: Some{cost}
def unlock_condition(+entry: Maybe<&2,UnlockEntry>) -> Maybe<&2,Condition>:
  match entry:
    case None{}: None{}
    case Some{UnlockEntry{_,_,condition}}: condition
def mode_condition(+entry: Maybe<&2,ModeEntry>) -> Maybe<&2,Condition>:
  match entry:
    case None{}: None{}
    case Some{ModeEntry{_,condition}}: condition
def purchase_condition(+kind: SelectionKind,+catalog: Catalog,+id: U32) -> Maybe<&2,Condition>:
  match kind:
    case Mode{}: mode_condition(mode_find(catalog_modes(catalog),id))
    case kind: unlock_condition(unlock_item(kind,catalog,id))
def purchasable(+kind: SelectionKind) -> Bool:
  match kind:
    case Character{}: True{}
    case Stage{}: True{}
    case _: False{}
def purchase_admitted(+profile: Progress,+kind: SelectionKind,+id: U32,+catalog: Catalog) -> Bool:
  Bool.and(purchasable(kind),Bool.and(has_unlock(unlock_item(kind,catalog,id)),Bool.and(Bool.not(unlocked(profile,kind,id,catalog)),Bool.and(requirements_met(profile,unlock_condition(unlock_item(kind,catalog,id))),A.ge(progress_gold(profile),unlock_cost(unlock_item(kind,catalog,id)))))))
def purchase_status(+profile: Progress,+kind: SelectionKind,+id: U32,+catalog: Catalog) -> PurchaseStatus:
  PurchaseStatus{unlocked(profile,kind,id,catalog),requirements_met(profile,purchase_condition(kind,catalog,id)),A.ge(progress_gold(profile),unlock_cost(unlock_item(kind,catalog,id))),purchase_admitted(profile,kind,id,catalog),A.subtract(unlock_cost(unlock_item(kind,catalog,id)),progress_gold(profile)),unlock_price(unlock_item(kind,catalog,id))}
def conditions_met(+rows: List<&2,Condition>,+profile: Progress) -> Bool:
  match rows:
    case Nil{}: True{}
    case Con{condition,tail}: Bool.and(requirements_met(profile,Some{condition}),conditions_met(tail,profile))
def add_achievement_unseen(+seen: Bool,+profile: Progress,+id: String) -> Progress:
  match seen:
    case True{}: profile
    case False{}: set_achievements(profile,List.append(&2,String,progress_achievements(profile),[id]))
def add_achievement(+test: Bool,+profile: Progress,+id: String) -> Progress:
  match test:
    case False{}: profile
    case True{}: add_achievement_unseen(contains_text(progress_achievements(profile),id),profile,id)
def award_go(+rows: List<&2,Achievement>,+profile: Progress) -> Progress:
  match rows:
    case Nil{}: profile
    case Con{Achievement{id,conditions},tail}: award_go(tail,add_achievement(conditions_met(conditions,profile),profile,id))
def award(+profile: Progress,+catalog: Catalog) -> Progress: award_go(catalog_achievements(catalog),profile)
def set_profile_stat(+profile: Progress,+key: Stat,+value: A.Amount) -> Progress: set_stats(profile,set_stat(key,progress_stats(profile),value))
def add_stat(+profile: Progress,+key: Stat,+value: A.Amount) -> Progress: set_profile_stat(profile,key,A.add(stat(key,progress_stats(profile)),value))
def max_stat(+profile: Progress,+key: Stat,+value: A.Amount) -> Progress: set_profile_stat(profile,key,A.maximum(stat(key,progress_stats(profile)),value))
def refresh_counts(+profile: Progress) -> Progress:
  set_profile_stat(set_profile_stat(profile,Characters{},A.natural(List.length(&2,U32,progress_characters(profile)))),Stages{},A.natural(List.length(&2,U32,progress_stages(profile))))
def purchase_ok(+profile: Progress,+kind: SelectionKind,+id: U32,+catalog: Catalog) -> Progress:
  award(refresh_counts(add_owned(set_gold(profile,A.subtract(progress_gold(profile),unlock_cost(unlock_item(kind,catalog,id)))),kind,id)),catalog)
def purchase(+profile: Progress,+kind: SelectionKind,+id: U32,+catalog: Catalog) -> Maybe<&2,Progress>: purchase_decided(purchase_admitted(profile,kind,id,catalog),purchase_ok(profile,kind,id,catalog))
def meta_go(+rows: List<&2,Nat>,+index: Nat) -> U32:
  match rows:
    case Nil{}: 0
    case Con{head,tail}: U32.or(U32.shln(U32.from_nat(Nat.min(head,7n)),Nat.mul(index,3n)),meta_go(tail,1n+index))
def meta_code(+profile: Progress) -> U32: meta_go(progress_meta(profile),0n)
def normalize_meta(+rows: List<&2,Upgrade>,+ranks: List<&2,Nat>,+index: Nat) -> List<&2,Nat>:
  match rows:
    case Nil{}: []
    case Con{head,tail}: Nat.min(rank_at(ranks,index),upgrade_maxLevel(head)) <> normalize_meta(tail,ranks,1n+index)
def valid_catalog_ids(+rows: List<&2,U32>,+catalog: List<&2,UnlockEntry>,+acc: List<&2,U32>) -> List<&2,U32>:
  match rows:
    case Nil{}: acc
    case Con{+head,tail}: valid_catalog_ids(tail,catalog,maybe_id(has_unlock(unlock_find(catalog,head)),acc,head))
def valid_relics(+rows: List<&2,U32>,+acc: List<&2,U32>) -> List<&2,U32>:
  match rows:
    case Nil{}: acc
    case Con{+head,tail}: valid_relics(tail,maybe_id(U32.is_lt(head,5),acc,head))
def unique_ids(+rows: List<&2,U32>,+acc: List<&2,U32>) -> List<&2,U32>:
  match rows:
    case Nil{}: acc
    case Con{head,tail}: unique_ids(tail,append_id(acc,head))
def normalize_collection(+collection: Collection) -> Collection:
  match collection:
    case Collection{weapons,evolutions,enemies}: Collection{unique_ids(weapons,[]),unique_ids(evolutions,[]),unique_ids(enemies,[])}
def normalize(+profile: Progress,+catalog: Catalog) -> Progress:
  Progress{A.whole(progress_gold(profile)),normalize_meta(catalog_upgrades(catalog),progress_meta(profile),0n),valid_catalog_ids(progress_characters(profile),catalog_characters(catalog),[0]),valid_catalog_ids(progress_stages(profile),catalog_stages(catalog),[0]),progress_achievements(profile),progress_stats(profile),normalize_collection(progress_collection(profile)),valid_relics(progress_stageRelics(profile),[]),progress_wonCharacters(profile),progress_recorded(profile)}
def setup_id(+profile: Progress,+kind: SelectionKind,+id: U32,+catalog: Catalog) -> U32: Bool.pick(U32,Bool.and(catalog_member(kind,id,catalog),unlocked(profile,kind,id,catalog)),id,0)
def validate_setup(+profile: Progress,+setup: Setup,+catalog: Catalog) -> Setup:
  Setup{setup_id(profile,Character{},setup_character(setup),catalog),setup_id(profile,Stage{},setup_stage(setup),catalog),Bool.pick(U32,contains_id(catalog_arcana(catalog),setup_arcana(setup)),setup_arcana(setup),0),setup_id(profile,Mode{},setup_mode(setup),catalog)}
def used_levels(+rows: List<&2,Nat>,+index: U32,+threshold: Nat,+acc: List<&2,U32>) -> List<&2,U32>:
  match rows:
    case Nil{}: acc
    case Con{head,tail}: used_levels(tail,(index + 1 : U32),threshold,maybe_id(Nat.is_ge(head,threshold),acc,index))
def observe_run(+history: History,+weapons: List<&2,Nat>) -> History:
  History{used_levels(weapons,0,1n,history_usedWeapons(history)),used_levels(weapons,0,9n,history_evolvedWeapons(history))}
def union_ids(+rows: List<&2,U32>,+acc: List<&2,U32>) -> List<&2,U32>:
  match rows:
    case Nil{}: acc
    case Con{head,tail}: union_ids(tail,append_id(acc,head))
def add_won(+test: Bool,+profile: Progress,+id: U32) -> Progress:
  match test:
    case True{}: set_wonCharacters(profile,append_id(progress_wonCharacters(profile),id))
    case False{}: profile
def add_relic(+test: Bool,+profile: Progress,+id: U32) -> Progress:
  match test:
    case True{}: set_stageRelics(profile,append_id(progress_stageRelics(profile),id))
    case False{}: profile
def record_collection(+collection: Collection,+history: History,+enemies: List<&2,U32>) -> Collection:
  match collection history:
    case Collection{weapons,evolutions,oldEnemies} History{used,evolved}: Collection{union_ids(used,weapons),union_ids(evolved,evolutions),union_ids(enemies,oldEnemies)}
def run_win(+won: Bool,+profile: Progress,+id: U32) -> Progress:
  match won:
    case True{}: add_won(True{},add_stat(profile,Wins{},A.one()),id)
    case False{}: profile
def run_awards(+profile: Progress,+frame: RunReceipt,+catalog: Catalog) -> Progress:
  +gained = A.whole(run_gold(frame))
  +p2 = add_stat(add_stat(profile,TotalGold{},gained),Kills{},run_kills(frame))
  +p3 = max_stat(p2,Survive{},A.ratio(run_tick(frame),60n))
  +p4 = max_stat(p3,Levels{},run_level(frame))
  +p5 = add_stat(add_stat(p4,Revivals{},run_revivalsUsed(frame)),BossKills{},run_bossesKilled(frame))
  +p6 = run_win(U32.is_eq(run_phase(frame),4),p5,run_character(frame))
  +p7 = add_relic(run_relicCollected(frame),p6,run_stage(frame))
  +p8 = set_profile_stat(p7,Relics{},A.natural(List.length(&2,U32,progress_stageRelics(p7))))
  +history = observe_run(run_history(frame),run_weapons(frame))
  +p9 = set_collection(p8,record_collection(progress_collection(p8),history,run_enemiesKilled(frame)))
  +p10 = add_stat(p9,Evolutions{},A.natural(List.length(&2,U32,history_evolvedWeapons(history))))
  +p11 = set_profile_stat(set_profile_stat(refresh_counts(p10),Weapons{},A.natural(List.length(&2,U32,collection_weapons(progress_collection(p10))))),CharacterWins{},A.natural(List.length(&2,U32,progress_wonCharacters(p10))))
  award(p11,catalog)
def pay_wallet(+awards: Progress,+old: A.Amount,+gained: A.Amount) -> Progress: set_gold(awards,A.add(old,gained))
def run_payment(+profile: Progress,+frame: RunReceipt,+catalog: Catalog) -> Progress: pay_wallet(run_awards(profile,frame,catalog),progress_gold(profile),A.whole(run_gold(frame)))
def recent(+rows: List<&2,String>) -> List<&2,String>: List.drop(&2,String,rows,Nat.sub(List.length(&2,String,rows),100n))
def stamp_receipt(+awards: Progress,+history: List<&2,String>,+signature: String) -> Progress: set_recorded(awards,recent(List.append(&2,String,history,[signature])))
def newly_awarded(+rows: List<&2,String>,+old: List<&2,String>) -> List<&2,String>:
  match rows:
    case Nil{}: []
    case Con{+head,tail}: List.append(&2,String,Bool.pick(List<&2,String>,contains_text(old,head),[],[head]),newly_awarded(tail,old))
def recording(+profile: Progress,+frame: RunReceipt,+catalog: Catalog) -> RecordResult:
  +result = stamp_receipt(run_payment(profile,frame,catalog),progress_recorded(profile),run_runId(frame))
  RecordResult{result,newly_awarded(progress_achievements(result),progress_achievements(profile))}
def record_decided(+seen: Bool,+profile: Progress,+paid: RecordResult) -> RecordResult:
  match seen:
    case True{}: RecordResult{profile,[]}
    case False{}: paid
def record_run(+profile: Progress,+frame: RunReceipt,+catalog: Catalog) -> RecordResult: record_decided(contains_text(progress_recorded(profile),run_runId(frame)),profile,recording(profile,frame,catalog))
