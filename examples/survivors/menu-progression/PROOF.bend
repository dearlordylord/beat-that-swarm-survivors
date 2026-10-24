import Base
import ../menu-progression.bend as P
import LAWS.bend as Laws

def Laws.upgrade_rejected(profile,id,catalog,denied):
  %denied : {P.pick(_,P.buy_upgrade_ok(profile,id,catalog),P.JNull{}) == P.JNull{} : P.Value}
  {==}
def Laws.purchase_rejected(profile,kind,id,catalog,denied):
  %denied : {P.pick(_,P.purchase_ok(profile,kind,id,catalog),P.JNull{}) == P.JNull{} : P.Value}
  {==}
def Laws.recorded_run_unchanged(profile,frame,catalog,recorded):
  %recorded : {P.pick(_,P.JObject{["profile","added"],[profile,P.JSequence{[]}]},P.recording(profile,frame,catalog)) == P.JObject{["profile","added"],[profile,P.JSequence{[]}]} : P.Value}
  {==}
def Laws.arcana_catalog_membership(profile,id,catalog): {==}
