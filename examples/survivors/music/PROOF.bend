import Base
import LAWS.bend as Laws

def Laws.latest_at_boundary(active,latest): {==}
def Laws.held_between_boundaries(active,latest): {==}
def Laws.replaced_before_next_bar(active,earlier,latest): {==}

def Laws.emergency_rise(previous,raw): {==}
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
