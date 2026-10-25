import Base
import ./contact-id-set.bend as IdSet

# Guarantees: an empty receipt set has no character path or terminal key.
# Why it matters: a fresh journal cannot suppress its first cosmetic receipt.
law empty_exact:
  {IdSet.empty() == IdSet.Empty{} : IdSet.IdSet}

# Guarantees: a matching character returns the child at the first edge.
# Why it matters: lookup cannot skip an exact prefix for a later duplicate edge.
law find_edge_choose_hit:
  for rest: Unit -> Maybe<&2, IdSet.IdSet>
  for +child: IdSet.IdSet
  {IdSet.find_edge_choose(True{}, child, rest) == Some{child} : Maybe<&2, IdSet.IdSet>}

# Guarantees: a failed character comparison resumes the deferred edge scan.
# Why it matters: an unrelated edge cannot hide a later matching prefix.
law find_edge_choose_miss:
  for ~rest: Unit -> Maybe<&2, IdSet.IdSet>
  for +child: IdSet.IdSet
  {IdSet.find_edge_choose(False{}, child, rest) == rest(Unit{}) : Maybe<&2, IdSet.IdSet>}

# Guarantees: no stored edge returns no child.
# Why it matters: insertion of a new first character starts below an empty subtree.
law find_edge_empty:
  for +wanted: Char
  {IdSet.find_edge(wanted, []) == None{} : Maybe<&2, IdSet.IdSet>}

# Guarantees: an edge scan tests its head before continuing into the tail.
# Why it matters: duplicate edge representations retain first-match semantics.
law find_edge_cons:
  for +wanted: Char
  for +char: Char
  for +child: IdSet.IdSet
  for +tail: List<&2, IdSet.Edge>
  {IdSet.find_edge(wanted, IdSet.Edge{char, child} <> tail) == IdSet.find_edge_choose(Char.is_eq(wanted, char), child, _ => IdSet.find_edge(wanted, tail)) : Maybe<&2, IdSet.IdSet>}

# Guarantees: a missing child resolves to an empty subtree.
# Why it matters: insertion creates only the requested absent path.
law edge_child_missing:
  {IdSet.edge_child(None{}) == IdSet.Empty{} : IdSet.IdSet}

# Guarantees: a found child is passed through unchanged.
# Why it matters: updates retain the old subtree before adding a suffix.
law edge_child_found:
  for +child: IdSet.IdSet
  {IdSet.edge_child(Some{child}) == child : IdSet.IdSet}

# Guarantees: a missing lookup result is false and does not call its continuation.
# Why it matters: a suffix cannot match when its first character is absent.
law contains_found_missing:
  for continue: IdSet.IdSet -> Bool
  {IdSet.contains_found(None{}, continue) == False{} : Bool}

# Guarantees: a found first edge delegates lookup to its child.
# Why it matters: membership follows only the stored matching prefix.
law contains_found_child:
  for ~continue: IdSet.IdSet -> Bool
  for +child: IdSet.IdSet
  {IdSet.contains_found(Some{child}, continue) == continue(child) : Bool}

# Guarantees: edge lookup finds its first matching child before suffix traversal.
# Why it matters: duplicate edge representations cannot merge unrelated subtrees.
law contains_edges_exact:
  for ~continue: IdSet.IdSet -> Bool
  for +wanted: Char
  for +edges: List<&2, IdSet.Edge>
  {IdSet.contains_edges(wanted, edges, continue) == IdSet.contains_found(IdSet.find_edge(wanted, edges), continue) : Bool}

# Guarantees: an empty string is present only at a terminal root.
# Why it matters: prefixes are distinct from the longer IDs beneath them.
law contains_go_empty:
  {IdSet.contains_go(SNil{}, IdSet.Empty{}) == False{} : Bool}

# Guarantees: an empty string lookup returns the root terminal bit.
# Why it matters: inserting a prefix does not imply inserting its extensions.
law contains_go_terminal:
  for +terminal: Bool
  for +edges: List<&2, IdSet.Edge>
  {IdSet.contains_go(SNil{}, IdSet.Node{terminal, edges}) == terminal : Bool}

# Guarantees: a nonempty string has no path in an empty root.
# Why it matters: only explicit inserted prefixes can match.
law contains_go_nonempty_empty:
  for +char: Char
  for +tail: String
  {IdSet.contains_go(SCon{char, tail}, IdSet.Empty{}) == False{} : Bool}

# Guarantees: a nonempty lookup follows its first character through stored edges.
# Why it matters: a missing first character cannot be mistaken for a suffix hit.
law contains_go_nonempty_node:
  for +char: Char
  for +tail: String
  for terminal: Bool
  for +edges: List<&2, IdSet.Edge>
  {IdSet.contains_go(SCon{char, tail}, IdSet.Node{terminal, edges}) == IdSet.contains_edges(char, edges, child => IdSet.contains_go(tail, child)) : Bool}

# Guarantees: the public lookup passes the ID and set to the trie walk unchanged.
# Why it matters: callers observe the same exact membership operation as its core.
law contains_wiring:
  for +set: IdSet.IdSet
  for +id: String
  {IdSet.contains(set, id) == IdSet.contains_go(id, set) : Bool}

# Guarantees: a matching edge is replaced with its updated child and keeps its tail.
# Why it matters: insertion updates only the first matching duplicate edge.
law replace_edge_choose_hit:
  for +wanted: Char
  for +stored: Char
  for +old_child: IdSet.IdSet
  for +child: IdSet.IdSet
  for +rest: List<&2, IdSet.Edge>
  for miss: Unit -> List<&2, IdSet.Edge>
  {IdSet.replace_edge_choose(True{}, wanted, IdSet.Edge{stored, old_child}, child, rest, miss) == IdSet.Edge{wanted, child} <> rest : List<&2, IdSet.Edge>}

# Guarantees: a nonmatching edge is preserved before the deferred tail edit.
# Why it matters: insertion keeps unrelated sibling paths and their order.
law replace_edge_choose_miss:
  for ~miss: Unit -> List<&2, IdSet.Edge>
  for +wanted: Char
  for +stored: Char
  for +old_child: IdSet.IdSet
  for +child: IdSet.IdSet
  for +rest: List<&2, IdSet.Edge>
  {IdSet.replace_edge_choose(False{}, wanted, IdSet.Edge{stored, old_child}, child, rest, miss) == IdSet.Edge{stored, old_child} <> miss(Unit{}) : List<&2, IdSet.Edge>}

# Guarantees: an empty sibling list receives the new first-character edge.
# Why it matters: inserting an unknown prefix always creates a reachable path.
law replace_edge_empty:
  for +wanted: Char
  for +child: IdSet.IdSet
  {IdSet.replace_edge(wanted, child, []) == [IdSet.Edge{wanted, child}] : List<&2, IdSet.Edge>}

# Guarantees: a nonempty sibling list delegates first-match replacement to its head.
# Why it matters: duplicate character edges cannot redirect the update to a later child.
law replace_edge_cons:
  for +wanted: Char
  for +child: IdSet.IdSet
  for +char: Char
  for +old_child: IdSet.IdSet
  for +tail: List<&2, IdSet.Edge>
  {IdSet.replace_edge(wanted, child, IdSet.Edge{char, old_child} <> tail) == IdSet.replace_edge_choose(Char.is_eq(wanted, char), wanted, IdSet.Edge{char, old_child}, child, tail, _ => IdSet.replace_edge(wanted, child, tail)) : List<&2, IdSet.Edge>}

# Guarantees: the edge editor applies its continuation to the first child or Empty.
# Why it matters: new receipt suffixes extend exactly one persistent trie path.
law edit_edges_exact:
  for ~continue: IdSet.IdSet -> IdSet.IdSet
  for +wanted: Char
  for +edges: List<&2, IdSet.Edge>
  {IdSet.edit_edges(wanted, edges, continue) == IdSet.replace_edge(wanted, continue(IdSet.edge_child(IdSet.find_edge(wanted, edges))), edges) : List<&2, IdSet.Edge>}

# Guarantees: an empty string sets only the root terminal bit.
# Why it matters: adding an empty ID preserves all existing character branches.
law insert_go_empty_root:
  {IdSet.insert_go(SNil{}, IdSet.Empty{}) == IdSet.Node{True{}, []} : IdSet.IdSet}

# Guarantees: inserting an empty string marks an existing root terminal.
# Why it matters: empty IDs remain distinct from IDs with a nonempty suffix.
law insert_go_empty_node:
  for +terminal: Bool
  for +edges: List<&2, IdSet.Edge>
  {IdSet.insert_go(SNil{}, IdSet.Node{terminal, edges}) == IdSet.Node{True{}, edges} : IdSet.IdSet}

# Guarantees: a nonempty ID creates a nonterminal root with its first edge.
# Why it matters: insertion preserves the distinction between prefixes and keys.
law insert_go_nonempty_empty:
  for +char: Char
  for +tail: String
  {IdSet.insert_go(SCon{char, tail}, IdSet.Empty{}) == IdSet.Node{False{}, IdSet.edit_edges(char, [], child => IdSet.insert_go(tail, child))} : IdSet.IdSet}

# Guarantees: a nonempty ID preserves the root terminal bit and edits its first matching edge.
# Why it matters: unrelated root keys and stored duplicate edges retain their order.
law insert_go_nonempty_node:
  for +char: Char
  for +tail: String
  for +terminal: Bool
  for +edges: List<&2, IdSet.Edge>
  {IdSet.insert_go(SCon{char, tail}, IdSet.Node{terminal, edges}) == IdSet.Node{terminal, IdSet.edit_edges(char, edges, child => IdSet.insert_go(tail, child))} : IdSet.IdSet}

# Guarantees: the public insertion passes the requested ID into its persistent trie update.
# Why it matters: receipt callers cannot accidentally update an unrelated key.
law insert_wiring:
  for +set: IdSet.IdSet
  for +id: String
  {IdSet.insert(set, id) == IdSet.insert_go(id, set) : IdSet.IdSet}

# Guarantees: every arbitrary string is absent from the empty trie.
# Why it matters: a fresh cosmetic receipt ledger begins without false duplicates.
law contains_empty:
  for +id: String
  {IdSet.contains(IdSet.empty(), id) == False{} : Bool}

# Guarantees: insertion adds exactly its key and preserves every previous membership.
# Why it matters: duplicate receipts are suppressed without dropping or merging distinct IDs.
law contains_insert:
  for +key: String
  for +query: String
  for +set: IdSet.IdSet
  {IdSet.contains(IdSet.insert(set, key), query) == Bool.or(String.eq(key, query), IdSet.contains(set, query)) : Bool}
