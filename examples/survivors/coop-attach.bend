import Base

# The attached state is affine: a returning player passes the original state
# directly to resume. Initial setup is evaluated only for a new attachment.
def dispatch(~State:Type,~Packet:Type,~resume:State -> Packet,~initial:State -> U32 -> U32 -> U32 -> U32 -> Packet,count:Nat,state:State,character:U32,meta:U32,arcana:U32,mask:U32) -> Packet:
  match count:
    case 2n: resume(state)
    case _: initial(state,character,meta,arcana,mask)
