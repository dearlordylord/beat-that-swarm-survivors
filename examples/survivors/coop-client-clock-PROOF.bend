import Base
import ./coop-client-clock.bend as C
import ./coop-client-clock-LAWS.bend as L
import ../../vendor/bendlib/packages/bend-mathlib/nat.bend as N

def L.fresh_exact(now):
  {==}

def L.latest_exact(now,lastAt):
  {==}

def L.elapsed_exact(now,lastAt):
  {==}

def L.earned_exact(now,lastAt):
  {==}

def L.total_exact(credit,now,lastAt):
  {==}

def L.count_exact(credit):
  {==}

def L.budget_exact(now,credit):
  {==}

def L.consume_exact(lastAt,credit,now):
  {==}

def L.discard_exact(lastAt,credit):
  {==}

def L.count_bounded(credit):
  N.min_le_left(4n,Nat.div(credit,1000000n))
