import Base

# Persistent exact-string membership for cosmetic contact receipt IDs. The
# trie stores one edge per traversed character path; it uses no hash key.
type IdSet is Data:
  Empty{}
  Node{terminal: Bool, edges: List<&2, Edge>}

type Edge is Data:
  Edge{char: Char, child: IdSet}

def empty() -> IdSet:
  Empty{}

# The continuation delays scanning the remaining edges until the first
# character comparison has failed.
def find_edge_choose(same: Bool, child: IdSet, rest: Unit -> Maybe<&2, IdSet>) -> Maybe<&2, IdSet>:
  match same:
    case True{}:
      Some{child}
    case False{}:
      rest(Unit{})

def find_edge(+wanted: Char, edges: List<&2, Edge>) -> Maybe<&2, IdSet>:
  match edges:
    case []:
      None{}
    case Edge{char, child} <> tail:
      find_edge_choose(Char.is_eq(wanted, char), child, _ => find_edge(wanted, tail))

def edge_child(found: Maybe<&2, IdSet>) -> IdSet:
  match found:
    case None{}:
      Empty{}
    case Some{child}:
      child

def contains_found(found: Maybe<&2, IdSet>, continue: IdSet -> Bool) -> Bool:
  match found:
    case None{}:
      False{}
    case Some{child}:
      continue(child)

def contains_edges(wanted: Char, edges: List<&2, Edge>, continue: IdSet -> Bool) -> Bool:
  contains_found(find_edge(wanted, edges), continue)

# A missing edge invokes its deferred suffix update; a hit preserves the rest.
def replace_edge_choose(same: Bool, wanted: Char, edge: Edge, child: IdSet, rest: List<&2, Edge>, miss: Unit -> List<&2, Edge>) -> List<&2, Edge>:
  match same:
    case True{}:
      Edge{wanted, child} <> rest
    case False{}:
      edge <> miss(Unit{})

def replace_edge(+wanted: Char, +child: IdSet, edges: List<&2, Edge>) -> List<&2, Edge>:
  match edges:
    case []:
      [Edge{wanted, child}]
    case Edge{+char, old_child} <> +tail:
      replace_edge_choose(Char.is_eq(wanted, char), wanted, Edge{char, old_child}, child, tail, _ => replace_edge(wanted, child, tail))

# `continue` performs the recursive insertion into the old first child, or the
# empty child when no edge matched. It is supplied by insert_go below.
def edit_edges(+wanted: Char, +edges: List<&2, Edge>, continue: IdSet -> IdSet) -> List<&2, Edge>:
  replace_edge(wanted, continue(edge_child(find_edge(wanted, edges))), edges)

def contains_go(id: String, set: IdSet) -> Bool:
  match id set:
    case SNil{} Empty{}:
      False{}
    case SNil{} Node{terminal, _}:
      terminal
    case SCon{_, _} Empty{}:
      False{}
    case SCon{char, tail} Node{_, edges}:
      contains_edges(char, edges, child => contains_go(tail, child))

def contains(set: IdSet, id: String) -> Bool:
  contains_go(id, set)

def insert_go(id: String, set: IdSet) -> IdSet:
  match id set:
    case SNil{} Empty{}:
      Node{True{}, []}
    case SNil{} Node{_, edges}:
      Node{True{}, edges}
    case SCon{char, tail} Empty{}:
      Node{False{}, edit_edges(char, [], child => insert_go(tail, child))}
    case SCon{char, tail} Node{terminal, edges}:
      Node{terminal, edit_edges(char, edges, child => insert_go(tail, child))}

def insert(set: IdSet, id: String) -> IdSet:
  insert_go(id, set)
