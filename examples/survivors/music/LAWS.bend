import Base
import ../music.bend as M

# The latest target replaces all previous observations at a musical boundary.
law latest_at_boundary:
  for active: U32
  for latest: U32
  {M.boundary(True{},active,latest) == U32.min(3,latest) : U32}
# Observing danger between bars must not change the committed arrangement.
law held_between_boundaries:
  for active: U32
  for latest: U32
  {M.boundary(False{},active,latest) == active : U32}
# A superseded high target is not an event to replay at the next bar.
law replaced_before_next_bar:
  for active: U32
  for earlier: U32
  for +latest: U32
  {M.commit(16,M.commit(15,active,earlier),latest) == U32.min(3,latest) : U32}
