# Explicit authorities shared by solo ownership, co-op ECS, and phase snapshots.
# Session contains match-wide facts. PlayerState contains only personal facts.
import Base
type PlayerState is Data: PlayerState{px: F32,py: F32,hp: U32,maxHp: U32,character: U32,weapons: List<&2,U32>,passives: List<&2,U32>,invuln: U32,arcana: U32,meta: U32,revivals: U32,rerolls: U32,banishes: U32,skips: U32,bannedWeapons: U32,bannedPassives: U32}

type Session is Data: Session{phase: U32,tick: U32,xp: U32,xpNeed: U32,level: U32,kills: U32,gold: U32,seed: U32,stage: U32,bosses: U32,mode: U32,enemyKinds: List<&2,U32>,relicCollected: U32}
def session_phase(value: Session) -> U32:
  match value:
    case Session{phase,_,_,_,_,_,_,_,_,_,_,_,_}: phase
def session_tick(value: Session) -> U32:
  match value:
    case Session{_,tick,_,_,_,_,_,_,_,_,_,_,_}: tick
def session_xp(value: Session) -> U32:
  match value:
    case Session{_,_,xp,_,_,_,_,_,_,_,_,_,_}: xp
def session_xpNeed(value: Session) -> U32:
  match value:
    case Session{_,_,_,xpNeed,_,_,_,_,_,_,_,_,_}: xpNeed
def session_level(value: Session) -> U32:
  match value:
    case Session{_,_,_,_,level,_,_,_,_,_,_,_,_}: level
def session_seed(value: Session) -> U32:
  match value:
    case Session{_,_,_,_,_,_,_,seed,_,_,_,_,_}: seed
def session_stage(value: Session) -> U32:
  match value:
    case Session{_,_,_,_,_,_,_,_,stage,_,_,_,_}: stage
def session_mode(value: Session) -> U32:
  match value:
    case Session{_,_,_,_,_,_,_,_,_,_,mode,_,_}: mode
def session_enemyKinds(value: Session) -> List<&2,U32>:
  match value:
    case Session{_,_,_,_,_,_,_,_,_,_,_,enemyKinds,_}: enemyKinds
def player_px(value: PlayerState) -> F32:
  match value:
    case PlayerState{px,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: px
def player_py(value: PlayerState) -> F32:
  match value:
    case PlayerState{_,py,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: py
def player_hp(value: PlayerState) -> U32:
  match value:
    case PlayerState{_,_,hp,_,_,_,_,_,_,_,_,_,_,_,_,_}: hp
def player_maxHp(value: PlayerState) -> U32:
  match value:
    case PlayerState{_,_,_,maxHp,_,_,_,_,_,_,_,_,_,_,_,_}: maxHp
def player_character(value: PlayerState) -> U32:
  match value:
    case PlayerState{_,_,_,_,character,_,_,_,_,_,_,_,_,_,_,_}: character
def player_weapons(value: PlayerState) -> List<&2,U32>:
  match value:
    case PlayerState{_,_,_,_,_,weapons,_,_,_,_,_,_,_,_,_,_}: weapons
def player_passives(value: PlayerState) -> List<&2,U32>:
  match value:
    case PlayerState{_,_,_,_,_,_,passives,_,_,_,_,_,_,_,_,_}: passives
def player_invuln(value: PlayerState) -> U32:
  match value:
    case PlayerState{_,_,_,_,_,_,_,invuln,_,_,_,_,_,_,_,_}: invuln
def player_bannedWeapons(value: PlayerState) -> U32:
  match value:
    case PlayerState{_,_,_,_,_,_,_,_,_,_,_,_,_,_,bannedWeapons,_}: bannedWeapons
def player_bannedPassives(value: PlayerState) -> U32:
  match value:
    case PlayerState{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,bannedPassives}: bannedPassives
def session_with_phase(state: Session,value: U32) -> Session:
  match state:
    case Session{_,+tick,+xp,+xpNeed,+level,+kills,+gold,+seed,+stage,+bosses,+mode,+enemyKinds,+relicCollected}: Session{value,tick,xp,xpNeed,level,kills,gold,seed,stage,bosses,mode,enemyKinds,relicCollected}
def session_with_tick(state: Session,value: U32) -> Session:
  match state:
    case Session{+phase,_,+xp,+xpNeed,+level,+kills,+gold,+seed,+stage,+bosses,+mode,+enemyKinds,+relicCollected}: Session{phase,value,xp,xpNeed,level,kills,gold,seed,stage,bosses,mode,enemyKinds,relicCollected}
def session_with_gold(state: Session,value: U32) -> Session:
  match state:
    case Session{+phase,+tick,+xp,+xpNeed,+level,+kills,_,+seed,+stage,+bosses,+mode,+enemyKinds,+relicCollected}: Session{phase,tick,xp,xpNeed,level,kills,value,seed,stage,bosses,mode,enemyKinds,relicCollected}
def session_with_stage(state: Session,value: U32) -> Session:
  match state:
    case Session{+phase,+tick,+xp,+xpNeed,+level,+kills,+gold,+seed,_,+bosses,+mode,+enemyKinds,+relicCollected}: Session{phase,tick,xp,xpNeed,level,kills,gold,seed,value,bosses,mode,enemyKinds,relicCollected}
def session_with_mode(state: Session,value: U32) -> Session:
  match state:
    case Session{+phase,+tick,+xp,+xpNeed,+level,+kills,+gold,+seed,+stage,+bosses,_,+enemyKinds,+relicCollected}: Session{phase,tick,xp,xpNeed,level,kills,gold,seed,stage,bosses,value,enemyKinds,relicCollected}
def player_with_px(state: PlayerState,value: F32) -> PlayerState:
  match state:
    case PlayerState{_,+py,+hp,+maxHp,+character,+weapons,+passives,+invuln,+arcana,+meta,+revivals,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives}: PlayerState{value,py,hp,maxHp,character,weapons,passives,invuln,arcana,meta,revivals,rerolls,banishes,skips,bannedWeapons,bannedPassives}
def player_with_py(state: PlayerState,value: F32) -> PlayerState:
  match state:
    case PlayerState{+px,_,+hp,+maxHp,+character,+weapons,+passives,+invuln,+arcana,+meta,+revivals,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives}: PlayerState{px,value,hp,maxHp,character,weapons,passives,invuln,arcana,meta,revivals,rerolls,banishes,skips,bannedWeapons,bannedPassives}
def player_with_hp(state: PlayerState,value: U32) -> PlayerState:
  match state:
    case PlayerState{+px,+py,_,+maxHp,+character,+weapons,+passives,+invuln,+arcana,+meta,+revivals,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives}: PlayerState{px,py,value,maxHp,character,weapons,passives,invuln,arcana,meta,revivals,rerolls,banishes,skips,bannedWeapons,bannedPassives}
def player_with_invuln(state: PlayerState,value: U32) -> PlayerState:
  match state:
    case PlayerState{+px,+py,+hp,+maxHp,+character,+weapons,+passives,_,+arcana,+meta,+revivals,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives}: PlayerState{px,py,hp,maxHp,character,weapons,passives,value,arcana,meta,revivals,rerolls,banishes,skips,bannedWeapons,bannedPassives}
