import Base
import ../game.bend as G

# Guarantees: opening the carrier created at each query entry returns every
#   argument exactly as supplied, for every Args value.
# Why it matters: selected gameplay rows receive the same run, geometry,
#   snapshots and hits after the traversal shares the carrier.
law args_held_roundtrip:
  for +args: G.Args
  {G.carried_args(G.ArgsHeld{args}) == args : G.Args}
