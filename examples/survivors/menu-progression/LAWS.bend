import Base
import ../menu-progression.bend as P

# A rejected upgrade must not yield any replacement profile to persist.
law upgrade_rejected:
  for +profile: P.Value
  for +id: P.Value
  for +catalog: P.Value
  for denied: {False{} == P.boolean(P.get(P.upgrade_status(profile,id,catalog),"canBuy")) : Bool}
  {P.buy_upgrade(profile,id,catalog) == P.JNull{} : P.Value}

# A rejected unlock yields no replacement profile for the storage adapter to apply.
law purchase_rejected:
  for +profile: P.Value
  for +kind: String
  for +id: P.Value
  for +catalog: P.Value
  for denied: {False{} == P.boolean(P.get(P.purchase_status(profile,kind,id,catalog),"canBuy")) : Bool}
  {P.purchase(profile,kind,id,catalog) == P.JNull{} : P.Value}

# Re-observing any recorded run preserves the whole profile and adds no achievements.
law recorded_run_unchanged:
  for +profile: P.Value
  for +frame: P.Value
  for +catalog: P.Value
  for recorded: {True{} == P.contains(P.sequence(P.get(profile,"recorded")),P.record_signature(frame)) : Bool}
  {P.record_run(profile,frame,catalog) == P.JObject{["profile","added"],[profile,P.JSequence{[]}]} : P.Value}

# Arcana availability is precisely membership in the supplied catalog.
law arcana_catalog_membership:
  for profile: P.Value
  for +id: P.Value
  for +catalog: P.Value
  {P.unlocked(profile,"arcana",id,catalog) == Bool.not(P.is_null(P.item(catalog,"arcana",id))) : Bool}
