import Base
import personal-totals.bend as P

# The unfused reference retains the mapped list before counting it.
def mapped(~Row:Data,~Context:Data,~own:Context -> Row -> Row,+context:Context,rows:List<&2,Row>) -> List<&2,Row>:
  match rows:
    case []: []
    case row <> rest: own(context,row) <> mapped(~Row,~Context,~own,context,rest)
def accumulated(~Row:Data,~count:Row -> P.Delta,rows:List<&2,Row>,totals:P.Totals) -> P.Totals:
  match rows:
    case []: totals
    case row <> rest: accumulated(~Row,~count,rest,P.add(count(row),totals))
# Guarantees: one fused pass equals mapping ownership and then counting in order.
# Why it matters: removing intermediate lists cannot change any personal total.
law fold_exact:
  for ~Row:Data
  for ~Context:Data
  for ~own:Context -> Row -> Row
  for ~count:Row -> P.Delta
  for +context:Context
  for +rows:List<&2,Row>
  for +totals:P.Totals
  {P.fold(~Row,~Context,~own,~count,context,rows,totals) == accumulated(~Row,~count,mapped(~Row,~Context,~own,context,rows),totals) : P.Totals}
# Guarantees: projectile contact adds damage and preserves the other counters.
# Why it matters: contact damage cannot disappear or reset an earlier hit total.
law projectile_exact:
  for h:U32 for hit:U32 for x:U32 for g:U32 for he:U32 for c:U32 for k:U32
  {P.add(P.Projectile{h},P.Totals{hit,x,g,he,c,k}) == P.Totals{(hit + h : U32),x,g,he,c,k} : P.Totals}
# Guarantees: enemy credit adds only damage and attributed kills.
# Why it matters: the fold must preserve both damage and kill ownership.
law enemy_exact:
  for h:U32 for n:U32 for hit:U32 for x:U32 for g:U32 for he:U32 for c:U32 for k:U32
  {P.add(P.Enemy{h,n},P.Totals{hit,x,g,he,c,k}) == P.Totals{(hit + h : U32),x,g,he,c,(k + n : U32)} : P.Totals}
# Guarantees: pickup credit adds XP, gold, healing and chests, preserving damage and kills.
# Why it matters: combining reward counting cannot lose or redirect a collected reward.
law pickup_exact:
  for x0:U32 for g0:U32 for he0:U32 for c0:U32
  for hit:U32 for x:U32 for g:U32 for he:U32 for c:U32 for k:U32
  {P.add(P.Pickup{x0,g0,he0,c0},P.Totals{hit,x,g,he,c,k}) == P.Totals{hit,(x + x0 : U32),(g + g0 : U32),(he + he0 : U32),(c + c0 : U32),k} : P.Totals}

# Guarantees: a row with no personal contribution preserves all six counters.
# Why it matters: empty entity rows cannot erase earlier damage or collected rewards.
law empty_exact:
  for hit:U32 for x:U32 for g:U32 for he:U32 for c:U32 for k:U32
  {P.add(P.Empty{},P.Totals{hit,x,g,he,c,k}) == P.Totals{hit,x,g,he,c,k} : P.Totals}
