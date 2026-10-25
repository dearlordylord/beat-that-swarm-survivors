import Base
import ./contact-id-set-LAWS.bend as L
import ./contact-id-set.bend as IdSet
import ../../vendor/bendlib/packages/bend-mathlib/string.bend as MathString
import ../../vendor/bendlib/packages/bend-mathlib/bool.bend as MathBool
import ../../vendor/bendlib/packages/bend-mathlib/equal.bend as MathEqual

def L.empty_exact(): {==}
def L.find_edge_choose_hit(rest, child): {==}
def L.find_edge_choose_miss(rest, child): {==}
def L.find_edge_empty(wanted): {==}
def L.find_edge_cons(wanted, char, child, tail): {==}
def L.edge_child_missing(): {==}
def L.edge_child_found(child): {==}
def L.contains_found_missing(continue): {==}
def L.contains_found_child(continue, child): {==}
def L.contains_edges_exact(continue, wanted, edges): {==}
def L.contains_go_empty(): {==}
def L.contains_go_terminal(terminal, edges): {==}
def L.contains_go_nonempty_empty(char, tail): {==}
def L.contains_go_nonempty_node(char, tail, terminal, edges): {==}
def L.contains_wiring(set, id): {==}
def L.replace_edge_choose_hit(wanted, stored, old_child, child, rest, miss): {==}
def L.replace_edge_choose_miss(miss, wanted, stored, old_child, child, rest): {==}
def L.replace_edge_empty(wanted, child): {==}
def L.replace_edge_cons(wanted, child, char, old_child, tail): {==}
def L.edit_edges_exact(continue, wanted, edges): {==}
def L.insert_go_empty_root(): {==}
def L.insert_go_empty_node(terminal, edges): {==}
def L.insert_go_nonempty_empty(char, tail): {==}
def L.insert_go_nonempty_node(char, tail, terminal, edges): {==}
def L.insert_wiring(set, id): {==}

def order_go_sticky_lt(left: String, right: String) -> {String.order.go(left, right, LT{}) == LT{} : Cmp}:
  match left right:
    case SNil{} SNil{}:
      {==}
    case SNil{} SCon{char, tail}:
      {==}
    case SCon{char, tail} SNil{}:
      {==}
    case SCon{Chr{x}, left_tail} SCon{Chr{y}, right_tail}:
      {==}

def order_go_sticky_gt(left: String, right: String) -> {String.order.go(left, right, GT{}) == GT{} : Cmp}:
  match left right:
    case SNil{} SNil{}:
      {==}
    case SNil{} SCon{char, tail}:
      {==}
    case SCon{char, tail} SNil{}:
      {==}
    case SCon{Chr{x}, left_tail} SCon{Chr{y}, right_tail}:
      {==}

# String.order.go retains its prefix comparison unless the comparison is EQ.
def order_go_eq_and(comparison: Cmp, left: String, right: String) -> {Cmp.is_eq(String.order.go(left, right, comparison)) == Bool.and(Cmp.is_eq(comparison), String.eq(left, right)) : Bool}:
  match comparison:
    case LT{}:
      Equal.trans(Bool, Cmp.is_eq(String.order.go(left, right, LT{})), Cmp.is_eq(LT{}), Bool.and(Cmp.is_eq(LT{}), String.eq(left, right)), Equal.cong(Cmp, Bool, Cmp.is_eq, String.order.go(left, right, LT{}), LT{}, order_go_sticky_lt(left, right)), {==})
    case EQ{}:
      {==}
    case GT{}:
      Equal.trans(Bool, Cmp.is_eq(String.order.go(left, right, GT{})), Cmp.is_eq(GT{}), Bool.and(Cmp.is_eq(GT{}), String.eq(left, right)), Equal.cong(Cmp, Bool, Cmp.is_eq, String.order.go(left, right, GT{}), GT{}, order_go_sticky_gt(left, right)), {==})

def string_eq_cons(+left_char: Char, +left_tail: String, +right_char: Char, +right_tail: String) -> {String.eq(SCon{left_char, left_tail}, SCon{right_char, right_tail}) == Bool.and(Char.is_eq(left_char, right_char), String.eq(left_tail, right_tail)) : Bool}:
  match left_char right_char:
    case Chr{x} Chr{y}:
      order_go_eq_and(U32.cmp(x, y), left_tail, right_tail)

def false_true_absurd(e: {False{} == True{} : Bool}) -> Empty:
  %e : Bool.pick(Type, _, Empty, Unit)
  Unit{}

def char_is_eq_true_of_equal(left: Char, right: Char, h: {left == right : Char}) -> {Char.is_eq(left, right) == True{} : Bool}:
  match left:
    case Chr{x}:
      %h : {Char.is_eq(Chr{x}, _) == True{} : Bool}
      Equal.cong(Cmp, Bool, Cmp.is_eq, U32.cmp(x, x), EQ{}, MathString.u32_cmp_refl(x))

def replace_edge_head_hit(+wanted: Char, +stored: Char, +old_child: IdSet.IdSet, +child: IdSet.IdSet, +tail: List<&2, IdSet.Edge>, hit: {Char.is_eq(wanted, stored) == True{} : Bool}) -> {IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail) == IdSet.Edge{wanted, child} <> tail : List<&2, IdSet.Edge>}:
  Equal.trans(List<&2, IdSet.Edge>, IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail), IdSet.replace_edge_choose(Char.is_eq(wanted, stored), wanted, IdSet.Edge{stored, old_child}, child, tail, _ => IdSet.replace_edge(wanted, child, tail)), IdSet.Edge{wanted, child} <> tail, L.replace_edge_cons(wanted, child, stored, old_child, tail), Equal.trans(List<&2, IdSet.Edge>, IdSet.replace_edge_choose(Char.is_eq(wanted, stored), wanted, IdSet.Edge{stored, old_child}, child, tail, _ => IdSet.replace_edge(wanted, child, tail)), IdSet.replace_edge_choose(True{}, wanted, IdSet.Edge{stored, old_child}, child, tail, _ => IdSet.replace_edge(wanted, child, tail)), IdSet.Edge{wanted, child} <> tail, Equal.cong(Bool, List<&2, IdSet.Edge>, same => IdSet.replace_edge_choose(same, wanted, IdSet.Edge{stored, old_child}, child, tail, _ => IdSet.replace_edge(wanted, child, tail)), Char.is_eq(wanted, stored), True{}, hit), L.replace_edge_choose_hit(wanted, stored, old_child, child, tail, _ => IdSet.replace_edge(wanted, child, tail))))

def replace_edge_head_miss(+wanted: Char, +stored: Char, +old_child: IdSet.IdSet, +child: IdSet.IdSet, +tail: List<&2, IdSet.Edge>, miss_hit: {Char.is_eq(wanted, stored) == False{} : Bool}) -> {IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail) == IdSet.Edge{stored, old_child} <> IdSet.replace_edge(wanted, child, tail) : List<&2, IdSet.Edge>}:
  Equal.trans(List<&2, IdSet.Edge>, IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail), IdSet.replace_edge_choose(Char.is_eq(wanted, stored), wanted, IdSet.Edge{stored, old_child}, child, tail, _ => IdSet.replace_edge(wanted, child, tail)), IdSet.Edge{stored, old_child} <> IdSet.replace_edge(wanted, child, tail), L.replace_edge_cons(wanted, child, stored, old_child, tail), Equal.trans(List<&2, IdSet.Edge>, IdSet.replace_edge_choose(Char.is_eq(wanted, stored), wanted, IdSet.Edge{stored, old_child}, child, tail, _ => IdSet.replace_edge(wanted, child, tail)), IdSet.replace_edge_choose(False{}, wanted, IdSet.Edge{stored, old_child}, child, tail, _ => IdSet.replace_edge(wanted, child, tail)), IdSet.Edge{stored, old_child} <> IdSet.replace_edge(wanted, child, tail), Equal.cong(Bool, List<&2, IdSet.Edge>, same => IdSet.replace_edge_choose(same, wanted, IdSet.Edge{stored, old_child}, child, tail, _ => IdSet.replace_edge(wanted, child, tail)), Char.is_eq(wanted, stored), False{}, miss_hit), {==}))

def find_edge_head_hit(+query: Char, +stored: Char, +child: IdSet.IdSet, +tail: List<&2, IdSet.Edge>, hit: {Char.is_eq(query, stored) == True{} : Bool}) -> {IdSet.find_edge(query, IdSet.Edge{stored, child} <> tail) == Some{child} : Maybe<&2, IdSet.IdSet>}:
  Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query, IdSet.Edge{stored, child} <> tail), IdSet.find_edge_choose(Char.is_eq(query, stored), child, _ => IdSet.find_edge(query, tail)), Some{child}, L.find_edge_cons(query, stored, child, tail), Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge_choose(Char.is_eq(query, stored), child, _ => IdSet.find_edge(query, tail)), IdSet.find_edge_choose(True{}, child, _ => IdSet.find_edge(query, tail)), Some{child}, Equal.cong(Bool, Maybe<&2, IdSet.IdSet>, same => IdSet.find_edge_choose(same, child, _ => IdSet.find_edge(query, tail)), Char.is_eq(query, stored), True{}, hit), L.find_edge_choose_hit(_ => IdSet.find_edge(query, tail), child)))

def find_edge_head_miss(+query: Char, +stored: Char, +child: IdSet.IdSet, +tail: List<&2, IdSet.Edge>, miss: {Char.is_eq(query, stored) == False{} : Bool}) -> {IdSet.find_edge(query, IdSet.Edge{stored, child} <> tail) == IdSet.find_edge(query, tail) : Maybe<&2, IdSet.IdSet>}:
  Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query, IdSet.Edge{stored, child} <> tail), IdSet.find_edge_choose(Char.is_eq(query, stored), child, _ => IdSet.find_edge(query, tail)), IdSet.find_edge(query, tail), L.find_edge_cons(query, stored, child, tail), Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge_choose(Char.is_eq(query, stored), child, _ => IdSet.find_edge(query, tail)), IdSet.find_edge_choose(False{}, child, _ => IdSet.find_edge(query, tail)), IdSet.find_edge(query, tail), Equal.cong(Bool, Maybe<&2, IdSet.IdSet>, same => IdSet.find_edge_choose(same, child, _ => IdSet.find_edge(query, tail)), Char.is_eq(query, stored), False{}, miss), {==}))

def find_replace_same_choose(+same: Bool, +wanted: Char, +child: IdSet.IdSet, +char: Char, +old_child: IdSet.IdSet, +tail: List<&2, IdSet.Edge>, +h: {same == Char.is_eq(wanted, char) : Bool}, rest: {IdSet.find_edge(wanted, IdSet.replace_edge(wanted, child, tail)) == Some{child} : Maybe<&2, IdSet.IdSet>}) -> {IdSet.find_edge(wanted, IdSet.replace_edge(wanted, child, IdSet.Edge{char, old_child} <> tail)) == Some{child} : Maybe<&2, IdSet.IdSet>}:
  match same:
    case True{}:
      updated = replace_edge_head_hit(wanted, char, old_child, child, tail, Equal.sym(Bool, same, Char.is_eq(wanted, char), h))
      lookup = find_edge_head_hit(wanted, wanted, child, tail, char_is_eq_true_of_equal(wanted, wanted, {==}))
      Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(wanted, IdSet.replace_edge(wanted, child, IdSet.Edge{char, old_child} <> tail)), IdSet.find_edge(wanted, IdSet.Edge{wanted, child} <> tail), Some{child}, Equal.cong(List<&2, IdSet.Edge>, Maybe<&2, IdSet.IdSet>, edges => IdSet.find_edge(wanted, edges), IdSet.replace_edge(wanted, child, IdSet.Edge{char, old_child} <> tail), IdSet.Edge{wanted, child} <> tail, updated), lookup)
    case False{}:
      updated = replace_edge_head_miss(wanted, char, old_child, child, tail, Equal.sym(Bool, same, Char.is_eq(wanted, char), h))
      lookup = find_edge_head_miss(wanted, char, old_child, IdSet.replace_edge(wanted, child, tail), Equal.sym(Bool, same, Char.is_eq(wanted, char), h))
      Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(wanted, IdSet.replace_edge(wanted, child, IdSet.Edge{char, old_child} <> tail)), IdSet.find_edge(wanted, IdSet.Edge{char, old_child} <> IdSet.replace_edge(wanted, child, tail)), Some{child}, Equal.cong(List<&2, IdSet.Edge>, Maybe<&2, IdSet.IdSet>, edges => IdSet.find_edge(wanted, edges), IdSet.replace_edge(wanted, child, IdSet.Edge{char, old_child} <> tail), IdSet.Edge{char, old_child} <> IdSet.replace_edge(wanted, child, tail), updated), Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(wanted, IdSet.Edge{char, old_child} <> IdSet.replace_edge(wanted, child, tail)), IdSet.find_edge(wanted, IdSet.replace_edge(wanted, child, tail)), Some{child}, lookup, rest))

def find_replace_same(+wanted: Char, +child: IdSet.IdSet, edges: List<&2, IdSet.Edge>) -> {IdSet.find_edge(wanted, IdSet.replace_edge(wanted, child, edges)) == Some{child} : Maybe<&2, IdSet.IdSet>}:
  match edges:
    case []:
      %Equal.sym(Bool, Char.is_eq(wanted, wanted), True{}, char_is_eq_true_of_equal(wanted, wanted, {==})) : {IdSet.find_edge_choose(_, child, _ => None{}) == Some{child} : Maybe<&2, IdSet.IdSet>}
      {==}
    case IdSet.Edge{+char, old_child} <> +tail:
      find_replace_same_choose(Char.is_eq(wanted, char), wanted, child, char, old_child, tail, {==}, find_replace_same(wanted, child, tail))

def char_hits_contradict(+wanted: Char, +query: Char, +stored: Char, wanted_hit: {Char.is_eq(wanted, stored) == True{} : Bool}, query_hit: {Char.is_eq(query, stored) == True{} : Bool}, different: {Char.is_eq(wanted, query) == False{} : Bool}) -> Empty:
  wanted_eq = MathString.char_eq_of_is_eq(wanted, stored, wanted_hit)
  query_eq = MathString.char_eq_of_is_eq(query, stored, query_hit)
  wanted_query_eq = Equal.trans(Char, wanted, stored, query, wanted_eq, Equal.sym(Char, query, stored, query_eq))
  query_wanted_true = char_is_eq_true_of_equal(wanted, query, wanted_query_eq)
  false_true_absurd(Equal.trans(Bool, False{}, Char.is_eq(wanted, query), True{}, Equal.sym(Bool, Char.is_eq(wanted, query), False{}, different), query_wanted_true))

def char_is_eq_false_reverse_choose(reversed: Bool, +left: Char, +right: Char, h: {reversed == Char.is_eq(right, left) : Bool}, different: {Char.is_eq(left, right) == False{} : Bool}) -> {Char.is_eq(right, left) == False{} : Bool}:
  match reversed:
    case True{}:
      reversed_true = Equal.sym(Bool, reversed, Char.is_eq(right, left), h)
      reversed_eq = MathString.char_eq_of_is_eq(right, left, reversed_true)
      forward_true = char_is_eq_true_of_equal(left, right, Equal.sym(Char, right, left, reversed_eq))
      Empty.absurd({Char.is_eq(right, left) == False{} : Bool}, false_true_absurd(Equal.trans(Bool, False{}, Char.is_eq(left, right), True{}, Equal.sym(Bool, Char.is_eq(left, right), False{}, different), forward_true)))
    case False{}:
      Equal.sym(Bool, reversed, Char.is_eq(right, left), h)

def char_is_eq_false_reverse(+left: Char, +right: Char, different: {Char.is_eq(left, right) == False{} : Bool}) -> {Char.is_eq(right, left) == False{} : Bool}:
  char_is_eq_false_reverse_choose(Char.is_eq(right, left), left, right, {==}, different)

def find_replace_different_choose(+wanted_same: Bool, +query_same: Bool, +wanted: Char, +query: Char, +stored: Char, +child: IdSet.IdSet, +old_child: IdSet.IdSet, +tail: List<&2, IdSet.Edge>, +wanted_h: {wanted_same == Char.is_eq(wanted, stored) : Bool}, +query_h: {query_same == Char.is_eq(query, stored) : Bool}, +different: {Char.is_eq(wanted, query) == False{} : Bool}, rest: {IdSet.find_edge(query, IdSet.replace_edge(wanted, child, tail)) == IdSet.find_edge(query, tail) : Maybe<&2, IdSet.IdSet>}) -> {IdSet.find_edge(query, IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail)) == IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> tail) : Maybe<&2, IdSet.IdSet>}:
  match wanted_same query_same:
    case True{} True{}:
      Empty.absurd({IdSet.find_edge(query, IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail)) == IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> tail) : Maybe<&2, IdSet.IdSet>}, char_hits_contradict(wanted, query, stored, Equal.sym(Bool, wanted_same, Char.is_eq(wanted, stored), wanted_h), Equal.sym(Bool, query_same, Char.is_eq(query, stored), query_h), different))
    case True{} False{}:
      updated = replace_edge_head_hit(wanted, stored, old_child, child, tail, Equal.sym(Bool, wanted_same, Char.is_eq(wanted, stored), wanted_h))
      changed = Equal.cong(List<&2, IdSet.Edge>, Maybe<&2, IdSet.IdSet>, edges => IdSet.find_edge(query, edges), IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail), IdSet.Edge{wanted, child} <> tail, updated)
      inserted_lookup = find_edge_head_miss(query, wanted, child, tail, char_is_eq_false_reverse(wanted, query, different))
      original_lookup = find_edge_head_miss(query, stored, old_child, tail, Equal.sym(Bool, query_same, Char.is_eq(query, stored), query_h))
      Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query, IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail)), IdSet.find_edge(query, tail), IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> tail), Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query, IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail)), IdSet.find_edge(query, IdSet.Edge{wanted, child} <> tail), IdSet.find_edge(query, tail), changed, inserted_lookup), Equal.sym(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> tail), IdSet.find_edge(query, tail), original_lookup))
    case False{} True{}:
      updated = replace_edge_head_miss(wanted, stored, old_child, child, tail, Equal.sym(Bool, wanted_same, Char.is_eq(wanted, stored), wanted_h))
      changed = Equal.cong(List<&2, IdSet.Edge>, Maybe<&2, IdSet.IdSet>, edges => IdSet.find_edge(query, edges), IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail), IdSet.Edge{stored, old_child} <> IdSet.replace_edge(wanted, child, tail), updated)
      inserted_lookup = find_edge_head_hit(query, stored, old_child, IdSet.replace_edge(wanted, child, tail), Equal.sym(Bool, query_same, Char.is_eq(query, stored), query_h))
      original_lookup = find_edge_head_hit(query, stored, old_child, tail, Equal.sym(Bool, query_same, Char.is_eq(query, stored), query_h))
      Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query, IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail)), Some{old_child}, IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> tail), Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query, IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail)), IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> IdSet.replace_edge(wanted, child, tail)), Some{old_child}, changed, inserted_lookup), Equal.sym(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> tail), Some{old_child}, original_lookup))
    case False{} False{}:
      updated = replace_edge_head_miss(wanted, stored, old_child, child, tail, Equal.sym(Bool, wanted_same, Char.is_eq(wanted, stored), wanted_h))
      changed = Equal.cong(List<&2, IdSet.Edge>, Maybe<&2, IdSet.IdSet>, edges => IdSet.find_edge(query, edges), IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail), IdSet.Edge{stored, old_child} <> IdSet.replace_edge(wanted, child, tail), updated)
      inserted_lookup = find_edge_head_miss(query, stored, old_child, IdSet.replace_edge(wanted, child, tail), Equal.sym(Bool, query_same, Char.is_eq(query, stored), query_h))
      original_lookup = find_edge_head_miss(query, stored, old_child, tail, Equal.sym(Bool, query_same, Char.is_eq(query, stored), query_h))
      Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query, IdSet.replace_edge(wanted, child, IdSet.Edge{stored, old_child} <> tail)), IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> IdSet.replace_edge(wanted, child, tail)), IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> tail), changed, Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> IdSet.replace_edge(wanted, child, tail)), IdSet.find_edge(query, tail), IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> tail), Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> IdSet.replace_edge(wanted, child, tail)), IdSet.find_edge(query, IdSet.replace_edge(wanted, child, tail)), IdSet.find_edge(query, tail), inserted_lookup, rest), Equal.sym(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query, IdSet.Edge{stored, old_child} <> tail), IdSet.find_edge(query, tail), original_lookup)))

def find_replace_different(+wanted: Char, +query: Char, +child: IdSet.IdSet, edges: List<&2, IdSet.Edge>, +different: {Char.is_eq(wanted, query) == False{} : Bool}) -> {IdSet.find_edge(query, IdSet.replace_edge(wanted, child, edges)) == IdSet.find_edge(query, edges) : Maybe<&2, IdSet.IdSet>}:
  match edges:
    case []:
      %Equal.sym(Bool, Char.is_eq(query, wanted), False{}, char_is_eq_false_reverse(wanted, query, different)) : {IdSet.find_edge_choose(_, child, _ => None{}) == None{} : Maybe<&2, IdSet.IdSet>}
      {==}
    case IdSet.Edge{+char, old_child} <> +tail:
      find_replace_different_choose(Char.is_eq(wanted, char), Char.is_eq(query, char), wanted, query, char, child, old_child, tail, {==}, {==}, different, find_replace_different(wanted, query, child, tail, different))

def L.contains_empty(id):
  match id:
    case SNil{}:
      {==}
    case SCon{char, tail}:
      {==}

def contains_found_edge(found: Maybe<&2, IdSet.IdSet>, +suffix: String) -> {IdSet.contains_found(found, child => IdSet.contains_go(suffix, child)) == IdSet.contains_go(suffix, IdSet.edge_child(found)) : Bool}:
  match found:
    case None{}:
      Equal.sym(Bool, IdSet.contains_go(suffix, IdSet.Empty{}), False{}, L.contains_empty(suffix))
    case Some{child}:
      {==}

def contains_go_edge(+query: Char, +suffix: String, terminal: Bool, +edges: List<&2, IdSet.Edge>) -> {IdSet.contains_go(SCon{query, suffix}, IdSet.Node{terminal, edges}) == IdSet.contains_go(suffix, IdSet.edge_child(IdSet.find_edge(query, edges))) : Bool}:
  Equal.trans(Bool, IdSet.contains_go(SCon{query, suffix}, IdSet.Node{terminal, edges}), IdSet.contains_edges(query, edges, child => IdSet.contains_go(suffix, child)), IdSet.contains_go(suffix, IdSet.edge_child(IdSet.find_edge(query, edges))), L.contains_go_nonempty_node(query, suffix, terminal, edges), Equal.trans(Bool, IdSet.contains_edges(query, edges, child => IdSet.contains_go(suffix, child)), IdSet.contains_found(IdSet.find_edge(query, edges), child => IdSet.contains_go(suffix, child)), IdSet.contains_go(suffix, IdSet.edge_child(IdSet.find_edge(query, edges))), {==}, contains_found_edge(IdSet.find_edge(query, edges), suffix)))

def contains_insert_core_from_public(+key: String, +query: String, +set: IdSet.IdSet, public: {IdSet.contains(IdSet.insert(set, key), query) == Bool.or(String.eq(key, query), IdSet.contains(set, query)) : Bool}) -> {IdSet.contains_go(query, IdSet.insert_go(key, set)) == Bool.or(String.eq(key, query), IdSet.contains_go(query, set)) : Bool}:
  inserted_membership = Equal.cong(IdSet.IdSet, Bool, indexed => IdSet.contains_go(query, indexed), IdSet.insert(set, key), IdSet.insert_go(key, set), L.insert_wiring(set, key))
  left_to_public = Equal.trans(Bool, IdSet.contains_go(query, IdSet.insert_go(key, set)), IdSet.contains_go(query, IdSet.insert(set, key)), IdSet.contains(IdSet.insert(set, key), query), Equal.sym(Bool, IdSet.contains_go(query, IdSet.insert(set, key)), IdSet.contains_go(query, IdSet.insert_go(key, set)), inserted_membership), Equal.sym(Bool, IdSet.contains(IdSet.insert(set, key), query), IdSet.contains_go(query, IdSet.insert(set, key)), L.contains_wiring(IdSet.insert(set, key), query)))
  right_to_core = Equal.cong(Bool, Bool, old => Bool.or(String.eq(key, query), old), IdSet.contains(set, query), IdSet.contains_go(query, set), L.contains_wiring(set, query))
  Equal.trans(Bool, IdSet.contains_go(query, IdSet.insert_go(key, set)), IdSet.contains(IdSet.insert(set, key), query), Bool.or(String.eq(key, query), IdSet.contains_go(query, set)), left_to_public, Equal.trans(Bool, IdSet.contains(IdSet.insert(set, key), query), Bool.or(String.eq(key, query), IdSet.contains(set, query)), Bool.or(String.eq(key, query), IdSet.contains_go(query, set)), public, right_to_core))

def edit_edges_insert_exact(+key_char: Char, +key_tail: String, +edges: List<&2, IdSet.Edge>) -> {IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child)) == IdSet.replace_edge(key_char, IdSet.insert_go(key_tail, IdSet.edge_child(IdSet.find_edge(key_char, edges))), edges) : List<&2, IdSet.Edge>}:
  {==}

def string_eq_cons_same_head(+key_char: Char, +key_tail: String, +query_char: Char, +query_tail: String, hit: {Char.is_eq(key_char, query_char) == True{} : Bool}) -> {String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}) == String.eq(key_tail, query_tail) : Bool}:
  Equal.trans(Bool, String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}), Bool.and(Char.is_eq(key_char, query_char), String.eq(key_tail, query_tail)), String.eq(key_tail, query_tail), string_eq_cons(key_char, key_tail, query_char, query_tail), Equal.trans(Bool, Bool.and(Char.is_eq(key_char, query_char), String.eq(key_tail, query_tail)), Bool.and(True{}, String.eq(key_tail, query_tail)), String.eq(key_tail, query_tail), Equal.cong(Bool, Bool, head => Bool.and(head, String.eq(key_tail, query_tail)), Char.is_eq(key_char, query_char), True{}, hit), MathBool.true_and(String.eq(key_tail, query_tail))))

def string_eq_cons_different_head(+key_char: Char, +key_tail: String, +query_char: Char, +query_tail: String, miss: {Char.is_eq(key_char, query_char) == False{} : Bool}) -> {String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}) == False{} : Bool}:
  Equal.trans(Bool, String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}), Bool.and(Char.is_eq(key_char, query_char), String.eq(key_tail, query_tail)), False{}, string_eq_cons(key_char, key_tail, query_char, query_tail), Equal.trans(Bool, Bool.and(Char.is_eq(key_char, query_char), String.eq(key_tail, query_tail)), Bool.and(False{}, String.eq(key_tail, query_tail)), False{}, Equal.cong(Bool, Bool, head => Bool.and(head, String.eq(key_tail, query_tail)), Char.is_eq(key_char, query_char), False{}, miss), MathBool.false_and(String.eq(key_tail, query_tail))))

def string_eq_nil_cons(+char: Char, +tail: String) -> {String.eq(SNil{}, SCon{char, tail}) == False{} : Bool}:
  match char:
    case Chr{x}:
      {==}

def string_eq_cons_nil(+char: Char, +tail: String) -> {String.eq(SCon{char, tail}, SNil{}) == False{} : Bool}:
  match char:
    case Chr{x}:
      {==}

def contains_insert_node_cons(+same: Bool, +key_char: Char, +key_tail: String, +query_char: Char, +query_tail: String, +terminal: Bool, +edges: List<&2, IdSet.Edge>, same_h: {same == Char.is_eq(key_char, query_char) : Bool}, recursive: {IdSet.contains_go(query_tail, IdSet.insert_go(key_tail, IdSet.edge_child(IdSet.find_edge(key_char, edges)))) == Bool.or(String.eq(key_tail, query_tail), IdSet.contains_go(query_tail, IdSet.edge_child(IdSet.find_edge(key_char, edges)))) : Bool}) -> {IdSet.contains_go(SCon{query_char, query_tail}, IdSet.insert_go(SCon{key_char, key_tail}, IdSet.Node{terminal, edges})) == Bool.or(String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}), IdSet.contains_go(SCon{query_char, query_tail}, IdSet.Node{terminal, edges})) : Bool}:
  match same:
    case True{}:
      +hit = Equal.sym(Bool, same, Char.is_eq(key_char, query_char), same_h)
      +chars_equal = MathString.char_eq_of_is_eq(key_char, query_char, hit)
      +old_key_child = IdSet.edge_child(IdSet.find_edge(key_char, edges))
      +new_child = IdSet.insert_go(key_tail, old_key_child)
      inserted_root = L.insert_go_nonempty_node(key_char, key_tail, terminal, edges)
      left_root = Equal.cong(IdSet.IdSet, Bool, root => IdSet.contains_go(SCon{query_char, query_tail}, root), IdSet.insert_go(SCon{key_char, key_tail}, IdSet.Node{terminal, edges}), IdSet.Node{terminal, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child))}, inserted_root)
      left_read = contains_go_edge(query_char, query_tail, terminal, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child)))
      left_to_child = Equal.trans(Bool, IdSet.contains_go(SCon{query_char, query_tail}, IdSet.insert_go(SCon{key_char, key_tail}, IdSet.Node{terminal, edges})), IdSet.contains_go(SCon{query_char, query_tail}, IdSet.Node{terminal, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child))}), IdSet.contains_go(query_tail, IdSet.edge_child(IdSet.find_edge(query_char, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child))))), left_root, left_read)
      edited = edit_edges_insert_exact(key_char, key_tail, edges)
      query_lookup_edited = Equal.cong(List<&2, IdSet.Edge>, Maybe<&2, IdSet.IdSet>, updated => IdSet.find_edge(query_char, updated), IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child)), IdSet.replace_edge(key_char, new_child, edges), edited)
      query_lookup_key = Equal.cong(Char, Maybe<&2, IdSet.IdSet>, selected => IdSet.find_edge(selected, IdSet.replace_edge(key_char, new_child, edges)), query_char, key_char, Equal.sym(Char, key_char, query_char, chars_equal))
      query_lookup_inserted = Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query_char, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child))), IdSet.find_edge(key_char, IdSet.replace_edge(key_char, new_child, edges)), Some{new_child}, Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query_char, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child))), IdSet.find_edge(query_char, IdSet.replace_edge(key_char, new_child, edges)), IdSet.find_edge(key_char, IdSet.replace_edge(key_char, new_child, edges)), query_lookup_edited, query_lookup_key), find_replace_same(key_char, new_child, edges))
      inserted_child = Equal.trans(IdSet.IdSet, IdSet.edge_child(IdSet.find_edge(query_char, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child)))), IdSet.edge_child(Some{new_child}), new_child, Equal.cong(Maybe<&2, IdSet.IdSet>, IdSet.IdSet, found => IdSet.edge_child(found), IdSet.find_edge(query_char, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child))), Some{new_child}, query_lookup_inserted), L.edge_child_found(new_child))
      left_membership = Equal.cong(IdSet.IdSet, Bool, child => IdSet.contains_go(query_tail, child), IdSet.edge_child(IdSet.find_edge(query_char, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child)))), new_child, inserted_child)
      old_query_child = IdSet.edge_child(IdSet.find_edge(query_char, edges))
      old_child_equal = Equal.cong(Char, IdSet.IdSet, selected => IdSet.edge_child(IdSet.find_edge(selected, edges)), key_char, query_char, chars_equal)
      old_membership_equal = Equal.cong(IdSet.IdSet, Bool, child => IdSet.contains_go(query_tail, child), old_key_child, old_query_child, old_child_equal)
      old_read = contains_go_edge(query_char, query_tail, terminal, edges)
      strings_equal = string_eq_cons_same_head(key_char, key_tail, query_char, query_tail, hit)
      result_args = MathEqual.cong2(Bool, Bool, Bool, Bool.or, String.eq(key_tail, query_tail), String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}), IdSet.contains_go(query_tail, old_key_child), IdSet.contains_go(query_tail, old_query_child), Equal.sym(Bool, String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}), String.eq(key_tail, query_tail), strings_equal), old_membership_equal)
      right_to_result = MathEqual.cong2(Bool, Bool, Bool, Bool.or, String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}), String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}), IdSet.contains_go(query_tail, old_query_child), IdSet.contains_go(SCon{query_char, query_tail}, IdSet.Node{terminal, edges}), {==}, Equal.sym(Bool, IdSet.contains_go(SCon{query_char, query_tail}, IdSet.Node{terminal, edges}), IdSet.contains_go(query_tail, old_query_child), old_read))
      left_actual = IdSet.contains_go(query_tail, IdSet.edge_child(IdSet.find_edge(query_char, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child)))))
      left_new = IdSet.contains_go(query_tail, new_child)
      ih_left = IdSet.contains_go(query_tail, IdSet.insert_go(key_tail, old_key_child))
      ih_right = Bool.or(String.eq(key_tail, query_tail), IdSet.contains_go(query_tail, old_key_child))
      left_to_new = Equal.trans(Bool, IdSet.contains_go(SCon{query_char, query_tail}, IdSet.insert_go(SCon{key_char, key_tail}, IdSet.Node{terminal, edges})), left_actual, left_new, left_to_child, left_membership)
      new_to_ih = Equal.trans(Bool, left_new, ih_left, ih_right, {==}, recursive)
      lhs_to_ih = Equal.trans(Bool, IdSet.contains_go(SCon{query_char, query_tail}, IdSet.insert_go(SCon{key_char, key_tail}, IdSet.Node{terminal, edges})), left_new, ih_right, left_to_new, new_to_ih)
      ih_to_result = Equal.trans(Bool, ih_right, Bool.or(String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}), IdSet.contains_go(query_tail, old_query_child)), Bool.or(String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}), IdSet.contains_go(SCon{query_char, query_tail}, IdSet.Node{terminal, edges})), result_args, right_to_result)
      Equal.trans(Bool, IdSet.contains_go(SCon{query_char, query_tail}, IdSet.insert_go(SCon{key_char, key_tail}, IdSet.Node{terminal, edges})), ih_right, Bool.or(String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}), IdSet.contains_go(SCon{query_char, query_tail}, IdSet.Node{terminal, edges})), lhs_to_ih, ih_to_result)
    case False{}:
      +miss = Equal.sym(Bool, same, Char.is_eq(key_char, query_char), same_h)
      inserted_root = L.insert_go_nonempty_node(key_char, key_tail, terminal, edges)
      left_root = Equal.cong(IdSet.IdSet, Bool, root => IdSet.contains_go(SCon{query_char, query_tail}, root), IdSet.insert_go(SCon{key_char, key_tail}, IdSet.Node{terminal, edges}), IdSet.Node{terminal, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child))}, inserted_root)
      left_read = contains_go_edge(query_char, query_tail, terminal, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child)))
      left_to_child = Equal.trans(Bool, IdSet.contains_go(SCon{query_char, query_tail}, IdSet.insert_go(SCon{key_char, key_tail}, IdSet.Node{terminal, edges})), IdSet.contains_go(SCon{query_char, query_tail}, IdSet.Node{terminal, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child))}), IdSet.contains_go(query_tail, IdSet.edge_child(IdSet.find_edge(query_char, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child))))), left_root, left_read)
      edited = edit_edges_insert_exact(key_char, key_tail, edges)
      query_lookup_edited = Equal.cong(List<&2, IdSet.Edge>, Maybe<&2, IdSet.IdSet>, updated => IdSet.find_edge(query_char, updated), IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child)), IdSet.replace_edge(key_char, IdSet.insert_go(key_tail, IdSet.edge_child(IdSet.find_edge(key_char, edges))), edges), edited)
      query_lookup_original = Equal.trans(Maybe<&2, IdSet.IdSet>, IdSet.find_edge(query_char, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child))), IdSet.find_edge(query_char, IdSet.replace_edge(key_char, IdSet.insert_go(key_tail, IdSet.edge_child(IdSet.find_edge(key_char, edges))), edges)), IdSet.find_edge(query_char, edges), query_lookup_edited, find_replace_different(key_char, query_char, IdSet.insert_go(key_tail, IdSet.edge_child(IdSet.find_edge(key_char, edges))), edges, miss))
      child_equal = Equal.cong(Maybe<&2, IdSet.IdSet>, IdSet.IdSet, found => IdSet.edge_child(found), IdSet.find_edge(query_char, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child))), IdSet.find_edge(query_char, edges), query_lookup_original)
      membership_equal = Equal.cong(IdSet.IdSet, Bool, child => IdSet.contains_go(query_tail, child), IdSet.edge_child(IdSet.find_edge(query_char, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child)))), IdSet.edge_child(IdSet.find_edge(query_char, edges)), child_equal)
      old_read = contains_go_edge(query_char, query_tail, terminal, edges)
      strings_false = string_eq_cons_different_head(key_char, key_tail, query_char, query_tail, miss)
      old_root = IdSet.contains_go(SCon{query_char, query_tail}, IdSet.Node{terminal, edges})
      old_tail = IdSet.contains_go(query_tail, IdSet.edge_child(IdSet.find_edge(query_char, edges)))
      result_value = Bool.or(String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}), old_root)
      or_false = MathEqual.cong2(Bool, Bool, Bool, Bool.or, String.eq(SCon{key_char, key_tail}, SCon{query_char, query_tail}), False{}, old_root, old_root, strings_false, {==})
      left_to_old_tail = Equal.trans(Bool, IdSet.contains_go(SCon{query_char, query_tail}, IdSet.insert_go(SCon{key_char, key_tail}, IdSet.Node{terminal, edges})), IdSet.contains_go(query_tail, IdSet.edge_child(IdSet.find_edge(query_char, IdSet.edit_edges(key_char, edges, child => IdSet.insert_go(key_tail, child))))), old_tail, left_to_child, membership_equal)
      tail_to_root = Equal.sym(Bool, old_root, old_tail, old_read)
      root_to_false_or = Equal.sym(Bool, Bool.or(False{}, old_root), old_root, MathBool.false_or(old_root))
      false_or_to_result = Equal.sym(Bool, result_value, Bool.or(False{}, old_root), or_false)
      Equal.trans(Bool, IdSet.contains_go(SCon{query_char, query_tail}, IdSet.insert_go(SCon{key_char, key_tail}, IdSet.Node{terminal, edges})), old_tail, result_value, left_to_old_tail, Equal.trans(Bool, old_tail, old_root, result_value, tail_to_root, Equal.trans(Bool, old_root, Bool.or(False{}, old_root), result_value, root_to_false_or, false_or_to_result)))

def contains_insert_public_from_core(+key: String, +query: String, +set: IdSet.IdSet, core: {IdSet.contains_go(query, IdSet.insert_go(key, set)) == Bool.or(String.eq(key, query), IdSet.contains_go(query, set)) : Bool}) -> {IdSet.contains(IdSet.insert(set, key), query) == Bool.or(String.eq(key, query), IdSet.contains(set, query)) : Bool}:
  inserted_membership = Equal.cong(IdSet.IdSet, Bool, indexed => IdSet.contains_go(query, indexed), IdSet.insert(set, key), IdSet.insert_go(key, set), L.insert_wiring(set, key))
  public_to_core = Equal.trans(Bool, IdSet.contains(IdSet.insert(set, key), query), IdSet.contains_go(query, IdSet.insert(set, key)), IdSet.contains_go(query, IdSet.insert_go(key, set)), L.contains_wiring(IdSet.insert(set, key), query), inserted_membership)
  core_to_public = Equal.cong(Bool, Bool, old => Bool.or(String.eq(key, query), old), IdSet.contains_go(query, set), IdSet.contains(set, query), Equal.sym(Bool, IdSet.contains(set, query), IdSet.contains_go(query, set), L.contains_wiring(set, query)))
  Equal.trans(Bool, IdSet.contains(IdSet.insert(set, key), query), IdSet.contains_go(query, IdSet.insert_go(key, set)), Bool.or(String.eq(key, query), IdSet.contains(set, query)), public_to_core, Equal.trans(Bool, IdSet.contains_go(query, IdSet.insert_go(key, set)), Bool.or(String.eq(key, query), IdSet.contains_go(query, set)), Bool.or(String.eq(key, query), IdSet.contains(set, query)), core, core_to_public))

def contains_insert_core(+key: String, +query: String, +set: IdSet.IdSet) -> {IdSet.contains_go(query, IdSet.insert_go(key, set)) == Bool.or(String.eq(key, query), IdSet.contains_go(query, set)) : Bool}:
  match key query set:
    case SNil{} SNil{} IdSet.Empty{}:
      {==}
    case SNil{} SNil{} IdSet.Node{terminal, edges}:
      {==}
    case SNil{} SCon{char, tail} IdSet.Empty{}:
      %Equal.sym(Bool, String.eq(SNil{}, SCon{char, tail}), False{}, string_eq_nil_cons(char, tail)) : {False{} == Bool.or(_, False{}) : Bool}
      {==}
    case SNil{} SCon{char, tail} IdSet.Node{terminal, edges}:
      %Equal.sym(Bool, String.eq(SNil{}, SCon{char, tail}), False{}, string_eq_nil_cons(char, tail)) : {IdSet.contains_go(SCon{char, tail}, IdSet.Node{terminal, edges}) == Bool.or(_, IdSet.contains_go(SCon{char, tail}, IdSet.Node{terminal, edges})) : Bool}
      Equal.sym(Bool, Bool.or(False{}, IdSet.contains_go(SCon{char, tail}, IdSet.Node{terminal, edges})), IdSet.contains_go(SCon{char, tail}, IdSet.Node{terminal, edges}), MathBool.false_or(IdSet.contains_go(SCon{char, tail}, IdSet.Node{terminal, edges})))
    case SCon{key_char, key_tail} SNil{} IdSet.Empty{}:
      %Equal.sym(Bool, String.eq(SCon{key_char, key_tail}, SNil{}), False{}, string_eq_cons_nil(key_char, key_tail)) : {False{} == Bool.or(_, False{}) : Bool}
      {==}
    case SCon{key_char, key_tail} SNil{} IdSet.Node{terminal, edges}:
      %Equal.sym(Bool, String.eq(SCon{key_char, key_tail}, SNil{}), False{}, string_eq_cons_nil(key_char, key_tail)) : {terminal == Bool.or(_, terminal) : Bool}
      Equal.sym(Bool, Bool.or(False{}, terminal), terminal, MathBool.false_or(terminal))
    case SCon{+key_char, +key_tail} SCon{+query_char, +query_tail} IdSet.Empty{}:
      contains_insert_node_cons(Char.is_eq(key_char, query_char), key_char, key_tail, query_char, query_tail, False{}, [], {==}, contains_insert_core(key_tail, query_tail, IdSet.edge_child(IdSet.find_edge(key_char, []))))
    case SCon{+key_char, +key_tail} SCon{+query_char, +query_tail} IdSet.Node{+terminal, +edges}:
      contains_insert_node_cons(Char.is_eq(key_char, query_char), key_char, key_tail, query_char, query_tail, terminal, edges, {==}, contains_insert_core(key_tail, query_tail, IdSet.edge_child(IdSet.find_edge(key_char, edges))))

def L.contains_insert(key, query, set):
  contains_insert_public_from_core(key, query, set, contains_insert_core(key, query, set))
