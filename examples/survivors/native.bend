import Base
import game.bend as G
import encounters.bend as E
import native_draw.bend as D
import native_art.bend as Art
import loot-visual.bend as LV
import native_audio.bend as Sound
import native-content.bend as C
import native-profile.bend as P
import viewport.bend as V

type Ui is Data: Ui{screen: U32,tab: U32,page: U32,selected: U32,character: U32,stage: U32,arcana: U32,mode: U32,paused: U32,keys: U32,quit: U32,dirty: U32,recorded: U32,frames: U32,clock: Nat,lag: U32}
type Native is Type: Native{game: G.Packet,ui: Ui,profile: P.Profile}
def ui_screen(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: screen
def ui_tab(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: tab
def ui_page(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: page
def ui_selected(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: selected
def ui_character(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: character
def ui_stage(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: stage
def ui_arcana(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: arcana
def ui_mode(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: mode
def ui_paused(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: paused
def ui_keys(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: keys
def ui_quit(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: quit
def ui_dirty(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: dirty
def ui_recorded(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: recorded
def ui_frames(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: frames
def set_screen(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{value,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}
def set_tab(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,value,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}
def set_page(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,value,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}
def set_selected(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,value,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}
def set_character(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,selected,value,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}
def set_stage(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,selected,character,value,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}
def set_arcana(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,selected,character,stage,value,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}
def set_mode(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,selected,character,stage,arcana,value,paused,keys,quit,dirty,recorded,frames,clock,lag}
def set_paused(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,selected,character,stage,arcana,mode,value,keys,quit,dirty,recorded,frames,clock,lag}
def set_keys(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,value,quit,dirty,recorded,frames,clock,lag}
def set_quit(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,value,dirty,recorded,frames,clock,lag}
def set_dirty(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,value,recorded,frames,clock,lag}
def set_recorded(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,value,frames,clock,lag}
def set_frames(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,value,clock,lag}
def run_phase(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: phase
def run_tick(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: tick
def run_px(run: G.Run) -> F32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: px
def run_py(run: G.Run) -> F32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: py
def run_hp(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: hp
def run_maxHp(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: maxHp
def run_xp(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: xp
def run_xpNeed(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: xpNeed
def run_level(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: level
def run_kills(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: kills
def run_gold(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: gold
def run_weapons(run: G.Run) -> List<&2,U32>:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: weapons
def run_passives(run: G.Run) -> List<&2,U32>:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: passives
def run_invuln(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: invuln
def run_rerolls(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: rerolls
def run_banishes(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: banishes
def run_skips(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: skips
def run_stage(run: G.Run) -> U32:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: stage

def ui_clock(ui: Ui) -> Nat:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: clock
def ui_lag(ui: Ui) -> U32:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: lag
def set_clock(ui: Ui,value: Nat) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,value,lag}
def set_lag(ui: Ui,value: U32) -> Ui:
  match ui:
    case Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,lag}: Ui{screen,tab,page,selected,character,stage,arcana,mode,paused,keys,quit,dirty,recorded,frames,clock,value}

def initial_ui() -> Ui: Ui{0,2,0,0,0,0,0,0,0,0,0,0,0,0,0n,0}
def initial_game(profile: P.Profile) -> G.Packet: G.start_quiet(0,P.meta(profile))
def select_color(selected: Bool,yes: U32,no: U32) -> U32:
  match selected:
    case True{}: yes
    case False{}: no

def border(+x: F32,+y: F32,+w: F32,+h: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  D.rect(x,y,w,2.0,color,D.rect(x,(y + h - 2.0 : F32),w,2.0,color,D.rect(x,y,2.0,h,color,D.rect((x + w - 2.0 : F32),y,2.0,h,color,tail))))

def title(category: U32) -> String:
  match category:
    case 2: "CHARACTER"
    case 3: "ARENA"
    case 4: "ARCANA"
    case 5: "POWER UPS"
    case 9: "RUN MODE"
    case 0: "WEAPONS"
    case 1: "PASSIVES"
    case 6: "BESTIARY"
    case 7: "ACHIEVEMENTS"
    case 8: "UNIONS"
    case _: "COLLECTION"

def current_tab(tab: U32,+ui: Ui) -> U32:
  match tab:
    case 2: ui_character(ui)
    case 3: ui_stage(ui)
    case 4: ui_arcana(ui)
    case 9: ui_mode(ui)
    case _: ui_selected(ui)

def current(+ui: Ui) -> U32: current_tab(ui_tab(ui),ui)

def select_label(yes: Bool,a: String,b: String) -> String:
  match yes:
    case True{}: a
    case False{}: b
def status(+profile: P.Profile,+category: U32,+id: U32) -> String:
  match category:
    case 5: "RANK " ++ U32.show(P.rank(profile,id)) ++ "/" ++ U32.show(C.meta_max(id)) ++ "  COST " ++ U32.show(P.cost(profile,category,id))
    case 7: select_label(P.achievement(profile,id),"COMPLETE","NOT YET EARNED")
    case _: select_label(P.allowed(profile,category,id),"AVAILABLE","LOCKED  COST " ++ U32.show(P.cost(profile,category,id)))


def cards(fuel: Nat,+index: U32,+ui: Ui,+profile: P.Profile,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match fuel:
    case 0n: tail
    case 1n+k:
      +id = (ui_page(ui) * 4 + index : U32)
      +y = (96.0 + U32.to_f32(index) * 44.0 : F32)
      +category = ui_tab(ui)
      +color = select_color(U32.is_eq(id,ui_selected(ui)),15584891,4020038)
      D.text(C.name(category,id),22.0,(y + 8.0 : F32),1.0,15196103,D.text(status(profile,category,id),22.0,(y + 23.0 : F32),1.0,9874884,border(14.0,y,484.0,40.0,color,D.rect(14.0,y,484.0,40.0,1186082,cards(k,(index + 1 : U32),ui,profile,tail)))))

def menu_rows(+ui: Ui,+profile: P.Profile) -> List<&2,D.Rect>:
  +category = ui_tab(ui)
  +selected = U32.min(ui_selected(ui),(C.count(category) - 1 : U32))
  D.text("NIGHTFALL",18.0,16.0,3.0,15584891,
  D.text(C.name(2,ui_character(ui)) ++ " / " ++ C.name(3,ui_stage(ui)),20.0,44.0,1.0,15196103,
  D.text(C.name(4,ui_arcana(ui)) ++ " / " ++ C.name(9,ui_mode(ui)),20.0,56.0,1.0,9874884,
  D.text("SPACE START  M POWER UPS  C COLLECTION",20.0,68.0,1.0,7985384,
  D.text("GOLD " ++ U32.show(P.gold(profile)),350.0,20.0,1.0,15584891,
  D.text(title(category) ++ "  " ++ U32.show((ui_page(ui) + 1 : U32)) ++ "/" ++ U32.show(((C.count(category) + 3) / 4 : U32)),20.0,82.0,1.0,15584891,
  cards(U32.to_nat(U32.min(4,(C.count(category) - ui_page(ui) * 4 : U32))),0,ui,profile,
  D.wrapped(C.description(category,selected) ++ " / " ++ C.hint(category,selected) ++ " / " ++ C.recipe(category,selected),20.0,278.0,20.0,486.0,324.0,15196103,
  D.text("ARROWS SELECT  ENTER EQUIP / BUY",20.0,336.0,1.0,15196103,
  D.text("LEFT/RIGHT CATEGORY  [ ] PAGE  ESC BACK",20.0,352.0,1.0,9874884,
  D.text("WASD MOVE  AUTO ATTACK  E REWARD",20.0,370.0,1.0,9874884,[])))))))))))

# The native renderer observes ECS bodies. Shape and color both distinguish
# enemies, pickups, friendly attacks, hostile attacks and the player.
def body_color(kind: U32,variant: U32) -> U32:
  match kind:
    case 0: G.at([12752028,11699166,11900012,10192793,14520952,11063764],(variant % 6 : U32))
    case 1: G.at([7985384,16760705,11900012,13948927,16768903,11137023],(variant % 6 : U32))
    case 2: 7985384
    case 3: 15584891
    case 4: 10474381
    case 5: 15584891
    case 6: 13948927
    case 7: 16348792
    case _: 1186082

def actor_visible(+kind: U32,hp: U32) -> Bool:
  Bool.and(Bool.not(U32.is_eq(kind,8)),Bool.or(U32.is_lt(kind,10),U32.is_lt(0,hp)))
def body_visible(visible: Bool,kind: U32,variant: U32,x: F32,y: F32,radius: F32,color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match visible:
    case True{}: Art.sprite(kind,variant,x,y,radius,color,tail)
    case False{}: tail

# Cull before expanding sprites into display-list rectangles. This conservative
# envelope includes oversized effects, shadows and HP bars at the raster edge.
def body_on_screen(+x: F32,+y: F32,+radius: F32) -> Bool:
  +margin = (radius * 3.0 + 24.0 : F32)
  Bool.and(Bool.and(F32.is_le((0.0 - margin : F32),x),F32.is_le(x,(V.native_image_extent() + margin : F32))),Bool.and(F32.is_le((0.0 - margin : F32),y),F32.is_le(y,(V.native_image_extent() + margin : F32))))
def healthbar_visible(visible: Bool,kind: U32,hp: U32,maxHp: U32,x: F32,y: F32,radius: F32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match visible:
    case True{}: Art.health_bar(kind,hp,maxHp,x,y,radius,tail)
    case False{}: tail

def body_xp_visible(visible: Bool,+kind: U32,+variant: U32,+x: F32,+y: F32,+radius: F32,+amount: U32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match visible kind:
    case False{} _: tail
    case True{} 2: Art.gem_scaled(x,y,LV.scale(amount),LV.pile_color(amount,U32.is_eq(variant,1)),tail)
    case True{} _: Art.sprite(kind,variant,x,y,radius,color,tail)

def body_sprites(rows: List<&2,G.Body>,+px: F32,+py: F32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match rows:
    case []: tail
    case G.Body{x,y,+kind,+variant,+hp,maxHp,age,seed,radius} <> rest:
      +sx = V.native_x(x,px)
      +sy = V.native_y(y,py)
      +scaled = F32.max(2.0,(radius * V.native_scale() : F32))
      body_xp_visible(Bool.and(actor_visible(kind,hp),body_on_screen(sx,sy,scaled)),kind,variant,sx,sy,scaled,hp,body_color(kind,variant),body_sprites(rest,px,py,tail))

# A separate overlay keeps a nearby sprite from hiding another enemy's HP.
def body_healthbars(rows: List<&2,G.Body>,+px: F32,+py: F32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match rows:
    case []: tail
    case G.Body{x,y,kind,variant,hp,maxHp,age,seed,radius} <> rest:
      +sx = V.native_x(x,px)
      +sy = V.native_y(y,py)
      +scaled = F32.max(2.0,(radius * V.native_scale() : F32))
      healthbar_visible(body_on_screen(sx,sy,scaled),kind,hp,maxHp,sx,sy,scaled,body_healthbars(rest,px,py,tail))
def bodies(+rows: List<&2,G.Body>,+px: F32,+py: F32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  body_healthbars(rows,px,py,body_sprites(rows,px,py,tail))

def loadout(rows: List<&2,U32>,+index: U32,+x: F32,+y: F32,+category: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match rows:
    case []: tail
    case +level <> rest:
      D.text(select_label(U32.is_lt(0,level),C.name(category,index) ++ " " ++ U32.show(level),""),x,y,1.0,15196103,loadout(rest,(index + 1 : U32),x,(y + 10.0 * U32.to_f32(Bool.to_u32(U32.is_lt(0,level))) : F32),category,tail))

def seconds_label(short: Bool,value: U32) -> String:
  match short:
    case True{}: "0" ++ U32.show(value)
    case False{}: U32.show(value)
def seconds(+value: U32) -> String: seconds_label(U32.is_lt(value,10),value)
def end_title(phase: U32) -> String:
  match phase:
    case 4: "DAWN SURVIVED"
    case _: "YOU HAVE FALLEN"

# Outermost text remains visible above the opaque HUD background.
def ready_notice(phase: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match phase:
    case 1: D.text("E UPGRADE READY",192.0,36.0,1.0,15584891,tail)
    case 2: D.text("E TREASURE READY",192.0,36.0,1.0,15584891,tail)
    case _: tail
def hud(+run: G.Run,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  ready_notice(run_phase(run),D.text("HP " ++ U32.show(run_hp(run)) ++ "/" ++ U32.show(run_maxHp(run)),12.0,12.0,1.0,15196103,
  D.text("LV " ++ U32.show(run_level(run)) ++ "   " ++ U32.show((run_tick(run) / 3600 : U32)) ++ ":" ++ seconds((run_tick(run) / 60 % 60 : U32)),192.0,12.0,1.0,15584891,
  D.text("KILLS " ++ U32.show(run_kills(run)),370.0,12.0,1.0,15196103,
  D.rect(10.0,26.0,(492.0 * U32.to_f32(U32.min(run_xp(run),run_xpNeed(run))) / U32.to_f32(U32.max(1,run_xpNeed(run))) : F32),4.0,7985384,
  D.rect(10.0,37.0,(140.0 * U32.to_f32(run_hp(run)) / U32.to_f32(U32.max(1,run_maxHp(run))) : F32),4.0,16348792,
  D.rect(0.0,0.0,512.0,48.0,724763,
  D.text("WASD MOVE  ESC PAUSE  V SOUND  GOLD " ++ U32.show(run_gold(run)),12.0,370.0,1.0,15196103,
  D.rect(0.0,360.0,512.0,24.0,724763,tail)))))))))

def offer_label(kind: U32,+id: U32,level: U32) -> String:
  match kind:
    case 0: C.name(0,id) ++ " +" ++ U32.show(level)
    case 1: C.name(1,id) ++ " +" ++ U32.show(level)
    case 2: "RESTORE HEALTH"
    case 3: C.evolved_name(id)
    case 5: C.name(8,id)
    case _: "RESTORE / GOLD"
def offer_name(offer: G.Offer) -> String:
  match offer:
    case G.Offer{kind,id,level}: offer_label(kind,id,level)

def offer_detail_kind(kind: U32,id: U32) -> String:
  match kind:
    case 0: C.description(0,id)
    case 1: C.description(1,id)
    case 2: "Restore health and continue the expedition."
    case 3: C.evolved_description(id)
    case 5: C.description(8,id)
    case _: "Collect bonus gold for permanent upgrades."
def offer_detail(offer: G.Offer) -> String:
  match offer:
    case G.Offer{kind,id,level}: offer_detail_kind(kind,id)

def offer_rows(rows: List<&2,G.Offer>,+index: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match rows:
    case []: tail
    case +offer <> rest:
      +y = (116.0 + U32.to_f32(index) * 58.0 : F32)
      D.text(U32.show((index + 1 : U32)) ++ "  " ++ offer_name(offer),52.0,(y + 9.0 : F32),1.0,15584891,D.wrapped(offer_detail(offer),52.0,(y + 24.0 : F32),52.0,458.0,(y + 43.0 : F32),15196103,border(42.0,y,428.0,54.0,4020038,D.rect(42.0,y,428.0,54.0,1186082,offer_rows(rest,(index + 1 : U32),tail)))))

def modal(phase: U32,+run: G.Run,offers: List<&2,G.Offer>,paused: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match phase paused:
    case 0 0: tail
    case 0 p:
      D.text("PAUSED",72.0,76.0,3.0,15584891,D.text("ESC RESUME  Q END EXPEDITION",56.0,116.0,1.0,15196103,D.text("COLLECT XP GEMS / TAKE CHESTS",56.0,134.0,1.0,7985384,D.text("ATTACKS ARE AUTOMATIC",56.0,146.0,1.0,7985384,loadout(run_weapons(run),0,56.0,162.0,0,loadout(run_passives(run),0,280.0,162.0,1,D.rect(28.0,52.0,456.0,296.0,724763,tail)))))))
    case 1 0: tail
    case 1 1: D.text("PAUSED - ESC RESUME / E UPGRADE",74.0,180.0,1.0,15584891,D.rect(28.0,156.0,456.0,56.0,724763,tail))
    case 1 p:
      D.text("CHOOSE YOUR POWER",56.0,76.0,2.0,15584891,offer_rows(offers,0,D.text("R REROLL " ++ U32.show(run_rerolls(run)) ++ "  K SKIP " ++ U32.show(run_skips(run)),56.0,310.0,1.0,15196103,D.text("B BANISH " ++ U32.show(run_banishes(run)) ++ "  ESC BACK TO BATTLE",56.0,330.0,1.0,9874884,D.rect(28.0,52.0,456.0,296.0,724763,tail)))))
    case 2 0: tail
    case 2 1: D.text("PAUSED - ESC RESUME / E TREASURE",74.0,180.0,1.0,15584891,D.rect(28.0,156.0,456.0,56.0,724763,tail))
    case 2 p:
      D.text("TREASURE",56.0,76.0,3.0,15584891,offer_rows(offers,0,D.text("1 / 2 / 3 CLAIM YOUR REWARD",56.0,316.0,1.0,15196103,D.rect(28.0,52.0,456.0,296.0,724763,tail))))
    case end p:
      D.text(end_title(end),56.0,76.0,2.0,15584891,D.text("LEVEL " ++ U32.show(run_level(run)) ++ "   KILLS " ++ U32.show(run_kills(run)),56.0,132.0,1.0,15196103,D.text("GOLD EARNED " ++ U32.show(run_gold(run)),56.0,164.0,2.0,15584891,D.text("ENTER RETURN TO CAMP",56.0,310.0,1.0,15196103,D.rect(28.0,52.0,456.0,296.0,724763,tail)))))

# Pause map uses world coordinates; only persistent objectives get markers.
def map_coord(value: F32,origin: F32) -> F32:
  (origin + F32.clamp(value,0.0,G.world_size()) * 224.0 / G.world_size() : F32)
def map_marker(kind: U32,x: F32,y: F32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match kind:
    case 5: D.rect((map_coord(x,48.0) - 2.0 : F32),(map_coord(y,96.0) - 2.0 : F32),5.0,5.0,16768903,tail)
    case 9: D.rect((map_coord(x,48.0) - 2.0 : F32),(map_coord(y,96.0) - 2.0 : F32),5.0,5.0,13948927,tail)
    case _: tail
def map_markers(rows: List<&2,G.Body>,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match rows:
    case []: tail
    case G.Body{x,y,kind,_,_,_,_,_,_} <> rest: map_marker(kind,x,y,map_markers(rest,tail))
def map_view(+run: G.Run,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  +left = F32.max(0.0,(run_px(run) - V.native_center_x() / V.native_scale() : F32))
  +top = F32.max(0.0,(run_py(run) - V.native_center_y() / V.native_scale() : F32))
  +right = F32.min(G.world_size(),(run_px(run) + (512.0 - V.native_center_x()) / V.native_scale() : F32))
  +bottom = F32.min(G.world_size(),(run_py(run) + (384.0 - V.native_center_y()) / V.native_scale() : F32))
  border(map_coord(left,48.0),map_coord(top,96.0),((right - left) * 224.0 / G.world_size() : F32),((bottom - top) * 224.0 / G.world_size() : F32),7985384,tail)
def pause_map(+run: G.Run,rows: List<&2,G.Body>,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  D.text("PAUSED / MAP",48.0,68.0,2.0,15584891,
  D.text("YOU",298.0,112.0,1.0,15584891,
  D.text("CHEST",298.0,140.0,1.0,16768903,
  D.text("RELIC",298.0,168.0,1.0,13948927,
  D.text("CAMERA",298.0,196.0,1.0,7985384,
  D.text("ESC / M RESUME",298.0,236.0,1.0,15196103,
  D.text("E READY REWARD",298.0,258.0,1.0,15196103,
  D.text("Q END RUN",298.0,280.0,1.0,15196103,
  D.rect((map_coord(run_px(run),48.0) - 2.0 : F32),(map_coord(run_py(run),96.0) - 2.0 : F32),5.0,5.0,15584891,
  map_markers(rows,map_view(run,border(48.0,96.0,224.0,224.0,4020038,
  D.rect(48.0,96.0,224.0,224.0,1186082,D.rect(28.0,52.0,456.0,296.0,724763,tail))))))))))))))
def map_phase(phase: U32,+run: G.Run,rows: List<&2,G.Body>,offers: List<&2,G.Offer>,paused: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match phase:
    case 0: pause_map(run,rows,tail)
    case 1: pause_map(run,rows,tail)
    case 2: pause_map(run,rows,tail)
    case phase: modal(phase,run,offers,paused,tail)
def world_modal(+run: G.Run,rows: List<&2,G.Body>,offers: List<&2,G.Offer>,paused: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match paused:
    case 1: map_phase(run_phase(run),run,rows,offers,1,tail)
    case p: modal(run_phase(run),run,offers,p,tail)

# Hazard floor is sampled into small world-aligned cells. The very same
# encounter predicate supplies the marked zones, including its refuge exclusion.
def ground_hazard(+stage: U32,+x: F32,+y: F32) -> Bool:
  Bool.and(Bool.and(F32.is_lt(90.0,F32.abs((x - G.world_center() : F32))),F32.is_lt(90.0,F32.abs((y - G.world_center() : F32)))),E.hazard_zone(stage,G.at([300,360,180,240,120],stage),x,y))
def ground_color(outside: Bool,hazard: Bool,warning: Bool,checker: U32) -> U32:
  match outside hazard warning:
    case True{} _ _: 1713957
    case _ True{} True{}: 9010480
    case _ True{} False{}: 3419167
    case _ _ _: select_color(U32.is_eq(checker,0),1186848,1384487)
def ground(fuel: Nat,+index: U32,+run: G.Run,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match fuel:
    case 0n: tail
    case 1n+k:
      +x = (U32.to_f32((index % 32 : U32)) * 16.0 : F32)
      +y = (U32.to_f32((index / 32 : U32)) * 16.0 : F32)
      +wx = ((x - 248.0) / 0.65 + run_px(run) : F32)
      +wy = ((y - 202.0) / 0.65 + run_py(run) : F32)
      +period = G.at([360,420,240,300,180],run_stage(run))
      color = ground_color(Bool.or(Bool.or(F32.is_lt(wx,0.0),F32.is_lt(wy,0.0)),Bool.or(F32.is_lt(G.world_size(),wx),F32.is_lt(G.world_size(),wy))),ground_hazard(run_stage(run),wx,wy),U32.is_le((period - 120 : U32),(run_tick(run) % period : U32)),((F32.to_u32(F32.abs(wx)) / 64 + F32.to_u32(F32.abs(wy)) / 64) % 2 : U32))
      D.rect(x,y,16.0,16.0,color,ground(k,(index + 1 : U32),run,tail))
def gameplay_rows(+run: G.Run,+rows: List<&2,G.Body>,offers: List<&2,G.Offer>,+ui: Ui,snapshots: List<&2,G.Snapshot>) -> List<&2,D.Rect>:
  hud(run,world_modal(run,rows,offers,ui_paused(ui),
  Art.player(256.0,210.0,ui_character(ui),run_invuln(run),
  bodies(rows,run_px(run),run_py(run),ground(768n,0,run,[])))))

def scene_screen(screen: U32,+ui: Ui,+profile: P.Profile,run: G.Run,rows: List<&2,G.Body>,offers: List<&2,G.Offer>,snapshots: List<&2,G.Snapshot>) -> Image:
  match screen:
    case 1: D.image(gameplay_rows(run,rows,offers,ui,snapshots))
    case _: D.image(menu_rows(ui,profile))

def scene(+ui: Ui,profile: P.Profile,run: G.Run,rows: List<&2,G.Body>,offers: List<&2,G.Offer>,snapshots: List<&2,G.Snapshot>) -> Image: scene_screen(ui_screen(ui),ui,profile,run,rows,offers,snapshots)

def view(state: Native) -> Native & Image:
  match state:
    case Native{G.Packet{G.State{world,+run,+rows,+offers,+snapshots,pending},frame},+ui,+profile}:
      (Native{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},ui,profile},scene(ui,profile,run,rows,offers,snapshots))
    case Native{G.Failed{+error},ui,profile}:
      (Native{G.Failed{error},ui,profile},D.image(D.text("ENGINE ERROR",32.0,32.0,2.0,16348792,D.wrapped(error,32.0,80.0,32.0,480.0,450.0,15196103,[]))))

def fps_overlay(ready: Bool,value: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match ready:
    case False{}: D.text("FPS --",438.0,36.0,1.0,15196103,tail)
    case True{}: D.text("FPS " ++ U32.show(value),438.0,36.0,1.0,15196103,tail)
def scene_fps(screen: U32,+ui: Ui,+profile: P.Profile,run: G.Run,rows: List<&2,G.Body>,offers: List<&2,G.Offer>,snapshots: List<&2,G.Snapshot>,ready: Bool,value: U32) -> Image:
  match screen:
    case 1: D.image(fps_overlay(ready,value,gameplay_rows(run,rows,offers,ui,snapshots)))
    case _: D.image(fps_overlay(ready,value,menu_rows(ui,profile)))
def view_fps(state: Native,ready: Bool,value: U32) -> Native & Image:
  match state:
    case Native{G.Packet{G.State{world,+run,+rows,+offers,+snapshots,pending},frame},+ui,+profile}:
      (Native{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},ui,profile},scene_fps(ui_screen(ui),ui,profile,run,rows,offers,snapshots,ready,value))
    case state: view(state)

# Packet transformations retain explicit engine failures for the error screen.
def apply_game(packet: G.Packet,change: G.State -> G.Packet) -> G.Packet:
  match packet:
    case G.Packet{state,frame}: change(state)
    case G.Failed{error}: G.Failed{error}
def configured(packet: G.Packet,+ui: Ui,+profile: P.Profile) -> G.Packet:
  apply_game(apply_game(apply_game(packet,state => G.configure_quiet(state,ui_stage(ui),ui_arcana(ui))),state => G.set_mode_quiet(state,ui_mode(ui))),state => G.configure_unlocks_quiet(state,P.weapon_mask(profile)))
def begin(state: Native) -> Native:
  match state:
    case Native{game,+ui,+profile}:
      Native{configured(G.start_quiet(ui_character(ui),P.meta(profile)),ui,profile),set_frames(set_recorded(set_dirty(set_keys(set_paused(set_screen(ui,1),0),0),1),0),0),P.begin(profile)}

def active_category(screen: U32,tab: U32,+direction: U32) -> U32:
  match screen:
    case 2: 5
    case 3: G.at([0,1,6,7,8],((tab + 5 + direction) % 5 : U32))
    case _: G.at([2,3,4,9],((tab + 4 + direction) % 4 : U32))
def category_index(category: U32) -> U32:
  match category:
    case 3: 1
    case 4: 2
    case 9: 3
    case 1: 1
    case 6: 2
    case 7: 3
    case 8: 4
    case _: 0
def change_category(+ui: Ui,direction: U32) -> Ui:
  set_selected(set_page(set_tab(ui,active_category(ui_screen(ui),category_index(ui_tab(ui)),direction)),0),0)
def move_selection(+ui: Ui,direction: U32) -> Ui:
  +id = ((ui_selected(ui) + C.count(ui_tab(ui)) + direction) % C.count(ui_tab(ui)) : U32)
  set_page(set_selected(ui,id),(id / 4 : U32))
def equip(allowed: Bool,category: U32,+id: U32,ui: Ui) -> Ui:
  match allowed category:
    case False{} c: ui
    case True{} 2: set_character(ui,id)
    case True{} 3: set_stage(ui,id)
    case True{} 4: set_arcana(ui,id)
    case True{} 9: set_mode(ui,id)
    case True{} c: ui

def buy_or_equip(state: Native) -> Native:
  match state:
    case Native{game,+ui,+profile}:
      +bought = P.purchase(profile,ui_tab(ui),ui_selected(ui))
      Native{game,set_dirty(equip(P.allowed(bought,ui_tab(ui),ui_selected(ui)),ui_tab(ui),ui_selected(ui),ui),1),bought}

def menu_key(code: U32,state: Native) -> Native:
  match code state:
    case 32 state: begin(state)
    case 13 state: buy_or_equip(state)
    case 109 Native{game,ui,profile}: Native{game,set_selected(set_page(set_tab(set_screen(ui,2),5),0),0),profile}
    case 99 Native{game,ui,profile}: Native{game,set_selected(set_page(set_tab(set_screen(ui,3),0),0),0),profile}
    case 27 Native{game,ui,profile}: Native{game,set_selected(set_page(set_tab(set_screen(ui,0),2),0),0),profile}
    case 119 Native{game,ui,profile}: Native{game,move_selection(ui,4294967295),profile}
    case 115 Native{game,ui,profile}: Native{game,move_selection(ui,1),profile}
    case 63232 Native{game,ui,profile}: Native{game,move_selection(ui,4294967295),profile}
    case 63233 Native{game,ui,profile}: Native{game,move_selection(ui,1),profile}
    case 65362 Native{game,ui,profile}: Native{game,move_selection(ui,4294967295),profile}
    case 65364 Native{game,ui,profile}: Native{game,move_selection(ui,1),profile}
    case 97 Native{game,ui,profile}: Native{game,change_category(ui,4294967295),profile}
    case 100 Native{game,ui,profile}: Native{game,change_category(ui,1),profile}
    case 63234 Native{game,ui,profile}: Native{game,change_category(ui,4294967295),profile}
    case 63235 Native{game,ui,profile}: Native{game,change_category(ui,1),profile}
    case 65361 Native{game,ui,profile}: Native{game,change_category(ui,4294967295),profile}
    case 65363 Native{game,ui,profile}: Native{game,change_category(ui,1),profile}
    case 91 Native{game,+ui,profile}: Native{game,set_selected(set_page(ui,((ui_page(ui) + (C.count(ui_tab(ui)) + 3) / 4 - 1) % ((C.count(ui_tab(ui)) + 3) / 4) : U32)),(((ui_page(ui) + (C.count(ui_tab(ui)) + 3) / 4 - 1) % ((C.count(ui_tab(ui)) + 3) / 4)) * 4 : U32)),profile}
    case 93 Native{game,+ui,profile}: Native{game,set_selected(set_page(ui,((ui_page(ui) + 1) % ((C.count(ui_tab(ui)) + 3) / 4) : U32)),(((ui_page(ui) + 1) % ((C.count(ui_tab(ui)) + 3) / 4)) * 4 : U32)),profile}
    case code state: state

def key_bit(code: U32) -> U32:
  match code:
    case 119: 1
    case 97: 2
    case 115: 4
    case 100: 8
    case 63232: 1
    case 63234: 2
    case 63233: 4
    case 63235: 8
    case 65362: 1
    case 65361: 2
    case 65364: 4
    case 65363: 8
    case _: 0
def held(down: Bool,+old: U32,+bit: U32) -> U32:
  match down:
    case True{}: U32.or(old,bit)
    case False{}: U32.and(old,U32.xor(4294967295,bit))

# New rewards open automatically. Esc explicitly defers; E reopens a deferred
# choice panel (paused=2); ordinary pause remains paused=1.
def upgrade_key(phase: U32,state: Native) -> Native:
  match phase state:
    case 1 Native{game,+ui,profile}: Native{game,set_keys(set_paused(ui,2),0),profile}
    case 2 Native{game,+ui,profile}: Native{game,set_keys(set_paused(ui,2),0),profile}
    case p state: state
def automatic_upgrade(state: Native) -> Native:
  match state:
    case Native{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},ui,profile}: upgrade_key(run_phase(run),Native{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},ui,profile})
    case state: state
def choose_key(allowed: Bool,index: U32,state: Native) -> Native:
  match allowed state:
    case True{} Native{game,ui,profile}: automatic_upgrade(Native{apply_game(game,s => G.choose_quiet(s,index)),set_paused(ui,0),profile})
    case False{} state: state

def offer_action(paused: U32,action: U32,state: Native) -> Native:
  match paused action state:
    case 2 0 Native{game,ui,profile}: Native{apply_game(game,G.reroll),ui,profile}
    case 2 1 Native{game,ui,profile}: automatic_upgrade(Native{apply_game(game,G.skip),set_paused(ui,0),profile})
    case 2 2 Native{game,ui,profile}: automatic_upgrade(Native{apply_game(game,s => G.banish(s,0)),set_paused(ui,0),profile})
    case p a state: state

def map_toggle(paused: U32,game: G.Packet,+ui: Ui,profile: P.Profile) -> Native:
  match paused:
    case 2: Native{game,ui,profile}
    case p: Native{game,set_keys(set_paused(ui,Bool.to_u32(U32.is_eq(p,0))),0),profile}
def map_key(state: Native) -> Native:
  match state:
    case Native{game,+ui,profile}: map_toggle(ui_paused(ui),game,ui,profile)

def game_key(code: U32,state: Native) -> Native:
  match code state:
    case 109 state: map_key(state)
    case 27 Native{game,+ui,profile}: Native{game,set_keys(set_paused(ui,Bool.to_u32(U32.is_eq(ui_paused(ui),0))),0),profile}
    case 32 Native{game,+ui,profile}: Native{game,set_keys(set_paused(ui,Bool.to_u32(U32.is_eq(ui_paused(ui),0))),0),profile}
    case 49 Native{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},+ui,profile}: choose_key(U32.is_eq(ui_paused(ui),2),0,Native{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},ui,profile})
    case 50 Native{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},+ui,profile}: choose_key(U32.is_eq(ui_paused(ui),2),1,Native{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},ui,profile})
    case 51 Native{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},+ui,profile}: choose_key(U32.is_eq(ui_paused(ui),2),2,Native{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},ui,profile})
    case 101 Native{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},ui,profile}: upgrade_key(run_phase(run),Native{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},ui,profile})
    case 118 Native{game,+ui,profile}: Native{game,set_frames(ui,((ui_frames(ui) + 1) % 2 : U32)),profile}
    case 114 Native{game,+ui,profile}: offer_action(ui_paused(ui),0,Native{game,ui,profile})
    case 107 Native{game,+ui,profile}: offer_action(ui_paused(ui),1,Native{game,ui,profile})
    case 98 Native{game,+ui,profile}: offer_action(ui_paused(ui),2,Native{game,ui,profile})
    case code state: state

def return_to_menu(allowed: Bool,state: Native) -> Native:
  match allowed state:
    case True{} Native{game,ui,profile}: Native{game,set_keys(set_screen(set_tab(set_selected(set_page(ui,0),0),2),0),0),profile}
    case False{} state: state

def abandoned_run(run: G.Run) -> G.Run:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: G.Run{3,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def abandon(paused: U32,state: Native) -> Native:
  match paused state:
    case 1 Native{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},ui,profile}:
      +terminal = abandoned_run(run)
      Native{G.Packet{G.State{world,terminal,rows,offers,snapshots,pending},frame},set_dirty(set_recorded(set_keys(set_paused(set_screen(set_tab(set_selected(set_page(ui,0),0),2),0),0),0),1),1),P.record(profile,terminal)}
    case p state: state

def command_play(code: U32,+ui: Ui,run: G.Run,state: Native) -> Native:
  match code:
    case 13: return_to_menu(U32.is_le(3,run_phase(run)),state)
    case 113: abandon(ui_paused(ui),state)
    case _: game_key(code,state)
def command(screen: U32,code: U32,state: Native) -> Native:
  match screen state:
    case 1 Native{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},+ui,+profile}:
      command_play(code,ui,run,Native{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},ui,profile})
    case 1 state: state
    case _ state: menu_key(code,state)
def key_pressed(down: Bool,code: U32,state: Native) -> Native:
  match down state:
    case False{} state: state
    case True{} Native{game,+ui,profile}: command(ui_screen(ui),code,Native{game,ui,profile})
def key_event(+code: U32,+down: Bool,state: Native) -> Native:
  match state:
    case Native{game,+ui,profile}: key_pressed(down,code,Native{game,set_keys(ui,held(down,ui_keys(ui),key_bit(code))),profile})

# Mouse coordinates are window pixels; the quadtree uses half-resolution pixels.
def clicked_offer(valid: Bool,+y: U32,state: Native) -> Native:
  match valid state:
    case False{} state: state
    case True{} state: choose_key(True{},U32.min(2,(U32.sub(y,U32.min(y,116)) / 58 : U32)),state)
def clicked_play(+x: U32,+y: U32,state: Native) -> Native:
  match state:
    case Native{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},+ui,profile}:
      clicked_offer(Bool.and(U32.is_eq(ui_paused(ui),2),Bool.and(Bool.and(U32.is_le(42,x),U32.is_lt(x,470)),Bool.and(U32.is_le(116,y),U32.is_lt(y,286)))),y,Native{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},ui,profile})
    case state: state
def clicked_menu(in_cards: Bool,+y: U32,state: Native) -> Native:
  match in_cards state:
    case False{} state: state
    case True{} Native{game,+ui,profile}: buy_or_equip(Native{game,set_selected(ui,U32.min((C.count(ui_tab(ui)) - 1 : U32),(ui_page(ui) * 4 + (y - 96) / 44 : U32))),profile})
def clicked(screen: U32,+x: U32,+y: U32,state: Native) -> Native:
  match screen:
    case 1: clicked_play(x,y,state)
    case _: clicked_menu(Bool.and(U32.is_le(96,y),U32.is_lt(y,272)),y,state)
def mouse_event(down: Bool,+x: U32,+y: U32,state: Native) -> Native:
  match down state:
    case False{} state: state
    case True{} Native{game,+ui,profile}: clicked(ui_screen(ui),(x / 2 : U32),(y / 2 : U32),Native{game,ui,profile})
def event(event: Event,state: Native) -> Native:
  match event state:
    case Close{} Native{game,ui,profile}: Native{game,set_quit(ui,1),profile}
    case Key{code,down} state: key_event(code,down,state)
    case Mouse{x,y,button,down} state: mouse_event(down,x,y,state)
    case _ state: state

def reduce(events: List<Event>,state: Native) -> Native:
  match events:
    case []: state
    case e <> rest: reduce(rest,event(e,state))

def direction(+keys: U32,positive: U32,negative: U32) -> F32:
  (U32.to_f32(Bool.to_u32(U32.is_lt(0,U32.and(keys,positive)))) - U32.to_f32(Bool.to_u32(U32.is_lt(0,U32.and(keys,negative)))) : F32)
def new_reward(previousPhase: U32,state: Native) -> Native:
  match previousPhase:
    case 0: automatic_upgrade(state)
    case _: state
def simulate(active: Bool,state: Native) -> Native:
  match active state:
    case True{} Native{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},+ui,profile}: new_reward(run_phase(run),Native{apply_game(G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},s => G.advance_live_quiet(s,direction(ui_keys(ui),8,2),direction(ui_keys(ui),4,1))),ui,profile})
    case _ state: state

def frame(state: Native) -> Native:
  match state:
    case Native{game,+ui,profile}: simulate(Bool.and(U32.is_eq(ui_screen(ui),1),U32.is_eq(ui_paused(ui),0)),Native{game,ui,profile})
def settled(terminal: Bool,state: Native) -> Native:
  match terminal state:
    case False{} state: state
    case True{} Native{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},ui,profile}: Native{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},set_dirty(set_recorded(ui,1),1),P.record(profile,run)}
    case True{} state: state

def settle(state: Native) -> Native:
  match state:
    case Native{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},+ui,profile}: settled(Bool.and(U32.is_eq(ui_recorded(ui),0),U32.is_le(3,run_phase(run))),Native{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},ui,profile})
    case state: state

def save_dirty(dirty: U32,state: Native) -> IO(Native):
  match dirty state:
    case 0 state: IO.pure(Native,state)
    case d Native{game,ui,+profile}:
      do IO<Native>:
        Unit <- P.save(profile)
        IO.pure(Native,Native{game,set_dirty(ui,0),profile})
def persist(state: Native) -> IO(Native):
  match state:
    case Native{game,+ui,profile}: save_dirty(ui_dirty(ui),Native{game,ui,profile})
def finish(quit: U32,state: Native) -> IO(Maybe<Native>):
  match quit:
    case 0: IO.pure(Maybe<Native>,Some{state})
    case _: IO.pure(Maybe<Native>,None{})
def finish_state(state: Native) -> IO(Maybe<Native>):
  match state:
    case Native{game,+ui,profile}: finish(ui_quit(ui),Native{game,ui,profile})
def frames(fuel: Nat,state: Native) -> Native:
  match fuel:
    case 0n: state
    case 1n+k: frames(k,settle(frame(state)))
def elapsed(first: Nat,+now: Nat,last: Nat) -> U32:
  match first:
    case 0n: 0
    case _: U32.from_nat(Nat.min(250n,Nat.sub(now,last)))
def timed(+now: Nat,state: Native) -> Native:
  match state:
    case Native{game,+ui,profile}:
      +total = (ui_lag(ui) + elapsed(ui_clock(ui),now,ui_clock(ui)) * 60 : U32)
      frames(U32.to_nat(U32.min(8,(total / 1000 : U32))),Native{game,set_lag(set_clock(ui,now),(total % 1000 : U32)),profile})
def tick_at(now: Nat,events: List<Event>,state: Native) -> IO(Maybe<Native>):
  do IO<Maybe<Native>>:
    state : Native <- persist(settle(timed(now,reduce(events,state))))
    finish_state(state)
def tick(events: List<Event>,state: Native) -> IO(Maybe<Native>):
  do IO<Maybe<Native>>:
    now : Nat <- IO.now()
    tick_at(now,events,state)

def initial(+profile: P.Profile) -> Native: Native{initial_game(profile),initial_ui(),profile}

# Count actual image callbacks, independently of simulation catch-up ticks.
# Half-second wall-clock windows are smoothed with a 3:1 exponential average.
type Fps is Data: Fps{clock: Nat,frames: U32,value: U32,ready: Bool}
def fps_initial() -> Fps: Fps{0n,0,0,False{}}
def fps_ready(fps: Fps) -> Bool:
  match fps:
    case Fps{_,_,_,ready}: ready
def fps_value(fps: Fps) -> U32:
  match fps:
    case Fps{_,_,value,_}: value
def fps_count(fps: Fps) -> Fps:
  match fps:
    case Fps{clock,frames,value,ready}: Fps{clock,U32.min(1000000,(frames + 1 : U32)),value,ready}
def fps_smooth(ready: Bool,previous: U32,sample: U32) -> U32:
  match ready:
    case False{}: sample
    case True{}: ((previous * 3 + sample + 2) / 4 : U32)
def fps_measured(enough: Bool,+now: Nat,+span: U32,fps: Fps) -> Fps:
  match enough fps:
    case False{} fps: fps
    case True{} Fps{_,frames,value,ready}: Fps{now,0,fps_smooth(ready,value,((frames * 1000 + span / 2) / U32.max(1,span) : U32)),True{}}
def fps_sample(+now: Nat,fps: Fps) -> Fps:
  match fps:
    case Fps{0n,_,value,ready}: Fps{now,0,value,ready}
    case Fps{+clock,frames,value,ready}: fps_measured(Nat.is_le(500n,Nat.sub(now,clock)),now,U32.from_nat(Nat.min(4294967295n,Nat.sub(now,clock))),Fps{clock,frames,value,ready})

type Session is Type: Session{native: Native,audio: Maybe<Audio>,kills: U32,level: U32,health: U32,fps: Fps}
def session_shown(audio: Maybe<Audio>,kills: U32,level: U32,health: U32,fps: Fps,drawn: Native & Image) -> Session & Image:
  (native,image) = drawn
  (Session{native,audio,kills,level,health,fps_count(fps)},image)
def session_view(state: Session) -> Session & Image:
  match state:
    case Session{native,audio,kills,level,health,+fps}: session_shown(audio,kills,level,health,fps,view_fps(native,fps_ready(fps),fps_value(fps)))

def metrics(state: Native) -> Native & (U32 & U32 & U32 & U32):
  match state:
    case Native{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},+ui,profile}:
      (Native{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},ui,profile},(run_kills(run),run_level(run),run_hp(run),ui_frames(ui)))
    case Native{G.Failed{error},ui,profile}: (Native{G.Failed{error},ui,profile},(0,0,0,0))
def sound_cue(muted: U32,damaged: Bool,levelled: Bool,killed: Bool) -> U32:
  match muted damaged levelled killed:
    case 1 _ _ _: 0
    case _ True{} _ _: 1
    case _ _ True{} _: 3
    case _ _ _ True{}: 2
    case _ _ _ _: 0

def session_with_audio(native: Native,kills: U32,level: U32,health: U32,fps: Fps,audio: Maybe<Audio>) -> IO(Maybe<Session>):
  IO.pure(Maybe<Session>,Some{Session{native,audio,kills,level,health,fps}})
def session_metrics(audio: Maybe<Audio>,oldKills: U32,oldLevel: U32,oldHealth: U32,fps: Fps,result: Native & (U32 & U32 & U32 & U32)) -> IO(Maybe<Session>):
  (native,(+kills,+level,+health,muted)) = result
  IO.bind(Maybe<Audio>,Maybe<Session>,Sound.play(audio,sound_cue(muted,U32.is_lt(health,oldHealth),U32.is_lt(oldLevel,level),U32.is_lt(oldKills,kills))),session_with_audio(native,kills,level,health,fps))
def session_next(audio: Maybe<Audio>,kills: U32,level: U32,health: U32,fps: Fps,result: Maybe<Native>) -> IO(Maybe<Session>):
  match result:
    case None{}:
      do IO<Maybe<Session>>:
        Unit <- Sound.close(audio)
        IO.pure(Maybe<Session>,None{})
    case Some{native}: session_metrics(audio,kills,level,health,fps,metrics(native))
def session_tick(events: List<Event>,state: Session) -> IO(Maybe<Session>):
  match state:
    case Session{native,audio,kills,level,health,+fps}:
      do IO<Maybe<Session>>:
        +now : Nat <- IO.now()
        result : Maybe<Native> <- tick_at(now,events,native)
        session_next(audio,kills,level,health,fps_sample(now,fps),result)
def main() -> IO(Unit):
  do IO<Unit>:
    profile : P.Profile <- P.load()
    audio : Maybe<Audio> <- Sound.open()
    App.run(~Session,~App{session_view,session_tick},"Nightfall Survivors - Bend",1024,768,Session{initial(profile),audio,0,1,100,fps_initial()})
