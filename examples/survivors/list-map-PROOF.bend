import Base
import ./list-map.bend as M
import ./list-map-LAWS.bend as L
import ../../vendor/bendlib/packages/bend-mathlib/list.bend as F

def L.accumulator_exact(A,B,Context,f,rows,context,acc):
  match rows:
    case []: {==}
    case head <> tail: L.accumulator_exact(~A,~B,~Context,~f,tail,context,f(context,head) <> acc)

def L.map_exact(A,B,Context,f,rows,context):
  %Equal.sym(List<&2,B>,M.go(~A,~B,~Context,~f,rows,context,[]),List.reverse.go(&2,B,L.reference(~A,~B,~Context,~f,rows,context),[]),L.accumulator_exact(~A,~B,~Context,~f,rows,context,[])) : {List.reverse(&2,B,_) == L.reference(~A,~B,~Context,~f,rows,context) : List<&2,B>}
  F.reverse_reverse(&2,B,L.reference(~A,~B,~Context,~f,rows,context))
