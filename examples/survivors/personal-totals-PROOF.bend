import Base
import personal-totals.bend as P
import personal-totals-LAWS.bend as L

def L.fold_exact(Row,Context,own,count,context,rows,totals):
  match rows:
    case []: {==}
    case row <> rest: L.fold_exact(~Row,~Context,~own,~count,context,rest,P.add(count(own(context,row)),totals))
def L.projectile_exact(h,hit,x,g,he,c,k): {==}
def L.enemy_exact(h,n,hit,x,g,he,c,k): {==}
def L.pickup_exact(x0,g0,he0,c0,hit,x,g,he,c,k): {==}

def L.empty_exact(hit,x,g,he,c,k): {==}
