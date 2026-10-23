import Base
import ../game.bend as G

# Per-plan spatial risk accumulation: same 60px/3600px geometry as the JS
# planner, with single-owner arrays and localized hostile influence rectangles.
# The final 496 padding cells are never addressed by a valid planner cell.
type Grid is Type: Grid{risk: Array<F32>,blocked: Array<U32>}
type Cell is Data: Cell{blocked: Bool,risk: F32}

def empty() -> Grid: Grid{[0.0 : F32*4096n],[0 : U32*4096n]}
def sample_blocked(risk: Array<F32>,value: F32,result: Array<U32> & U32) -> Grid & Cell:
  (blocked,flag)=result
  (Grid{risk,blocked},Cell{Bool.not(U32.is_eq(flag,0)),value})
def sample_risk(index: U32,blocked: Array<U32>,result: Array<F32> & F32) -> Grid & Cell:
  (risk,value)=result
  sample_blocked(risk,value,blocked[index])
def sample(grid: Grid,+index: U32) -> Grid & Cell:
  match grid:
    case Grid{risk,blocked}: sample_risk(index,blocked,Array.get(F32,risk,index))

def paint_blocked(risk: Array<F32>,+index: U32,value: F32,contact: Bool,result: Array<U32> & U32) -> Grid:
  (blocked,old)=result
  Grid{Array.set(F32,risk,index,value),Array.set(U32,blocked,index,U32.or(old,Bool.to_u32(contact)))}
def paint_risk(+index: U32,blocked: Array<U32>,delta: F32,contact: Bool,result: Array<F32> & F32) -> Grid:
  (risk,old)=result
  paint_blocked(risk,index,(old + delta : F32),contact,blocked[index])
def paint(grid: Grid,+index: U32,delta: F32,contact: Bool) -> Grid:
  match grid:
    case Grid{risk,blocked}: paint_risk(index,blocked,delta,contact,Array.get(F32,risk,index))

def lower(value: F32) -> U32: U32.min(59,F32.to_u32((F32.max(0.0,value) / 60.0 : F32)))
def upper(value: F32) -> U32: U32.min(59,F32.to_u32((F32.max(0.0,value) / 60.0 : F32)))
def cell_distance(+x: U32,+y: U32,bx: F32,by: F32) -> F32:
  +dx=(U32.to_f32(x) * 60.0 + 30.0 - bx : F32)
  +dy=(U32.to_f32(y) * 60.0 + 30.0 - by : F32)
  F32.sqrt((dx * dx + dy * dy : F32))
def weight(kind: U32) -> F32:
  match kind:
    case 7: 8.0
    case _: 4.0
def margin(kind: U32) -> F32:
  match kind:
    case 7: 12.0
    case _: 18.0

def select(test: Bool,a: U32,b: U32) -> U32:
  match test:
    case True{}: a
    case False{}: b
def rectangle(fuel: Nat,grid: Grid,+x: U32,+y: U32,+xmin: U32,+xmax: U32,+bx: F32,+by: F32,+radius: F32,+reach: F32,+factor: F32) -> Grid:
  match fuel:
    case 0n: grid
    case 1n+rest:
      +distance=cell_distance(x,y,bx,by)
      +delta=(F32.max(0.0,(1.0 - distance / reach : F32)) * factor : F32)
      next=paint(grid,(y * 60 + x : U32),delta,F32.is_lt(distance,(radius + 21.0 : F32)))
      +endRow=U32.is_eq(x,xmax)
      rectangle(rest,next,select(endRow,xmin,(x + 1 : U32)),select(endRow,(y + 1 : U32),y),xmin,xmax,bx,by,radius,reach,factor)

def add_active(active: Bool,grid: Grid,+x: F32,+y: F32,+kind: U32,radius: F32) -> Grid:
  match active:
    case False{}: grid
    case True{}:
      +radius=(radius + margin(kind) : F32)
      +reach=(radius + 120.0 : F32)
      +xmin=lower((x - reach : F32))
      +xmax=upper((x + reach : F32))
      +ymin=lower((y - reach : F32))
      +ymax=upper((y + reach : F32))
      +cells=((xmax - xmin + 1) * (ymax - ymin + 1) : U32)
      rectangle(U32.to_nat(cells),grid,xmin,ymin,xmin,xmax,x,y,radius,reach,weight(kind))
def add(grid: Grid,body: G.Body) -> Grid:
  match body:
    case G.Body{x,y,+kind,_,hp,_,_,_,radius}: add_active(Bool.or(Bool.and(U32.is_eq(kind,0),U32.is_lt(0,hp)),U32.is_eq(kind,7)),grid,x,y,kind,radius)
def build_rows(rows: List<&2,G.Body>,grid: Grid) -> Grid:
  match rows:
    case []: grid
    case body <> rest: build_rows(rest,add(grid,body))
def build(rows: List<&2,G.Body>) -> Grid: build_rows(rows,empty())

# A read-only planner snapshot owns no affine array. Conversion consumes both
# arrays once and preserves their complete balanced shape for 12-step lookup.
type Frozen is Data:
  Empty{}
  Leaf{cell: Cell}
  Branch{left: Frozen,right: Frozen}
def freeze_arrays(risk: Array<F32>,blocked: Array<U32>) -> Frozen:
  match risk blocked:
    case ALeaf{value} ALeaf{flag}: Leaf{Cell{Bool.not(U32.is_eq(flag,0)),value}}
    case ANode{rl,rr} ANode{bl,br}: Branch{freeze_arrays(rl,bl),freeze_arrays(rr,br)}
    case _ _: Empty{}
def freeze(grid: Grid) -> Frozen:
  match grid:
    case Grid{risk,blocked}: freeze_arrays(risk,blocked)
def choose_tree(test: Bool,left: Frozen,right: Frozen) -> Frozen:
  match test:
    case True{}: left
    case False{}: right
def lookup_go(fuel: Nat,tree: Frozen,+index: U32,+half: U32) -> Cell:
  match fuel tree:
    case _ Empty{}: Cell{False{},0.0}
    case _ Leaf{cell}: cell
    case 0n _: Cell{False{},0.0}
    case 1n+rest Branch{left,right}: lookup_go(rest,choose_tree(U32.is_lt(index,half),left,right),(index % half : U32),(half / 2 : U32))
def lookup(tree: Frozen,index: U32) -> Cell: lookup_go(12n,tree,(index % 4096 : U32),2048)
def snapshot(rows: List<&2,G.Body>) -> Frozen: freeze(build(rows))
def is_blocked(cell: Cell) -> Bool:
  match cell:
    case Cell{blocked,_}: blocked
def risk(cell: Cell) -> F32:
  match cell:
    case Cell{_,risk}: risk
