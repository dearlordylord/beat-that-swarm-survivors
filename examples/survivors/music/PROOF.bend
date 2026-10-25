import Base
import LAWS.bend as Laws
import ../music.bend as M

def Laws.theme_in_range(pair,bit):
  match pair bit:
    case False{} False{}: {==}
    case False{} True{}: {==}
    case True{} False{}: {==}
    case True{} True{}: {==}
def Laws.opposite_pairs_differ(pair,earlier,later):
  match pair earlier later:
    case False{} False{} False{}: {==}
    case False{} False{} True{}: {==}
    case False{} True{} False{}: {==}
    case False{} True{} True{}: {==}
    case True{} False{} False{}: {==}
    case True{} False{} True{}: {==}
    case True{} True{} False{}: {==}
    case True{} True{} True{}: {==}
def Laws.commit_at_any_boundary(step,active,latest,boundary):
  %boundary : {M.boundary(_,active,latest) == U32.min(3,latest) : U32}
  {==}
def Laws.commit_between_any_boundaries(step,active,latest,between):
  %between : {M.boundary(_,active,latest) == active : U32}
  {==}
def Laws.latest_supersedes_any_previous_commit(earlierStep,step,active,earlier,latest,boundary):
  %boundary : {M.boundary(_,M.commit(earlierStep,active,earlier),latest) == U32.min(3,latest) : U32}
  {==}
def Laws.public_emergency_bypasses_ramp(previous,raw,rising,emergency):
  %rising : {M.smooth_direction(_,U32.min(previous,1000),U32.min(raw,1000)) == U32.min(raw,1000) : U32}
  %emergency : {M.rise_policy(_,U32.min(previous,1000),U32.min(raw,1000)) == U32.min(raw,1000) : U32}
  {==}
