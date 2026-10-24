import Base

# Age and kind are intentionally irrelevant to physical collection.
def close(+x: F32,+y: F32,+px: F32,+py: F32,+radius: F32) -> Bool:
  F32.is_le(((x - px) * (x - px) + (y - py) * (y - py) : F32),(radius * radius : F32))
def admission(x: F32,y: F32,px: F32,py: F32,radius: F32,age: U32,kind: U32) -> Bool:
  close(x,y,px,py,radius)
