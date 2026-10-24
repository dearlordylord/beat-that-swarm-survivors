import Base
import ../game.bend as G

# Guarantees: opening an ArgsHeld carrier returns every argument exactly
#   as supplied, for every Args value.
# Why it matters: selected gameplay rows receive the same run, geometry,
#   snapshots and hits after a traversal shares an ArgsHeld carrier.
law args_held_roundtrip:
  for +args: G.Args
  {G.carried_args(G.ArgsHeld{args}) == args : G.Args}
