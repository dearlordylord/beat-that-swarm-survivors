import Base
import native_draw.bend as D

# Opaque, sparse pixel art. Shapes are presentation only; gameplay owns positions,
# radii, life, actor phases and collision. Display-list heads paint in front.
def ink() -> U32: 593433
def tint(on: Bool,yes: U32,no: U32) -> U32:
  match on:
    case True{}: yes
    case False{}: no

def box(+x: F32,+y: F32,+scale: F32,dx: F32,dy: F32,w: F32,h: F32,color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  D.rect((x + dx * scale : F32),(y + dy * scale : F32),(w * scale : F32),(h * scale : F32),color,tail)

def ring(+x: F32,+y: F32,+r: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  a = D.rect((x - r * 0.5 : F32),(y - r : F32),r,1.0,color,tail)
  b = D.rect((x - r * 0.5 : F32),(y + r - 1.0 : F32),r,1.0,color,a)
  c = D.rect((x - r : F32),(y - r * 0.5 : F32),1.0,r,color,b)
  d = D.rect((x + r - 1.0 : F32),(y - r * 0.5 : F32),1.0,r,color,c)
  e = D.rect((x - r * 0.8 : F32),(y - r * 0.8 : F32),(r * 0.3 : F32),1.0,color,d)
  f = D.rect((x + r * 0.5 : F32),(y - r * 0.8 : F32),(r * 0.3 : F32),1.0,color,e)
  g = D.rect((x - r * 0.8 : F32),(y + r * 0.8 : F32),(r * 0.3 : F32),1.0,color,f)
  D.rect((x + r * 0.5 : F32),(y + r * 0.8 : F32),(r * 0.3 : F32),1.0,color,g)

def shadow(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  box(x,y,scale,(0.0 - 10.0 : F32),8.0,20.0,3.0,1054498,tail)

def skeleton(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 6.0 : F32),(0.0 - 12.0 : F32),12.0,10.0,593433,tail)
  r1 = box(x,y,scale,(0.0 - 5.0 : F32),(0.0 - 11.0 : F32),10.0,8.0,15391673,r0)
  r2 = box(x,y,scale,(0.0 - 3.0 : F32),(0.0 - 8.0 : F32),2.0,3.0,593433,r1)
  r3 = box(x,y,scale,1.0,(0.0 - 8.0 : F32),2.0,3.0,593433,r2)
  r4 = box(x,y,scale,(0.0 - 2.0 : F32),(0.0 - 3.0 : F32),4.0,2.0,15391673,r3)
  r5 = box(x,y,scale,(0.0 - 1.0 : F32),(0.0 - 1.0 : F32),2.0,10.0,15391673,r4)
  r6 = box(x,y,scale,(0.0 - 5.0 : F32),0.0,10.0,2.0,15391673,r5)
  r7 = box(x,y,scale,(0.0 - 4.0 : F32),4.0,8.0,2.0,15391673,r6)
  r8 = box(x,y,scale,(0.0 - 8.0 : F32),0.0,2.0,8.0,15391673,r7)
  r9 = box(x,y,scale,6.0,0.0,2.0,8.0,15391673,r8)
  r10 = box(x,y,scale,(0.0 - 5.0 : F32),8.0,3.0,4.0,15391673,r9)
  box(x,y,scale,2.0,8.0,3.0,4.0,15391673,r10)

def bat(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 13.0 : F32),(0.0 - 5.0 : F32),10.0,5.0,593433,tail)
  r1 = box(x,y,scale,3.0,(0.0 - 5.0 : F32),10.0,5.0,593433,r0)
  r2 = box(x,y,scale,(0.0 - 11.0 : F32),(0.0 - 3.0 : F32),8.0,5.0,color,r1)
  r3 = box(x,y,scale,3.0,(0.0 - 3.0 : F32),8.0,5.0,color,r2)
  r4 = box(x,y,scale,(0.0 - 15.0 : F32),(0.0 - 8.0 : F32),5.0,4.0,color,r3)
  r5 = box(x,y,scale,10.0,(0.0 - 8.0 : F32),5.0,4.0,color,r4)
  r6 = box(x,y,scale,(0.0 - 5.0 : F32),(0.0 - 7.0 : F32),10.0,15.0,593433,r5)
  r7 = box(x,y,scale,(0.0 - 3.0 : F32),(0.0 - 6.0 : F32),6.0,12.0,color,r6)
  r8 = box(x,y,scale,(0.0 - 5.0 : F32),(0.0 - 10.0 : F32),3.0,4.0,color,r7)
  r9 = box(x,y,scale,2.0,(0.0 - 10.0 : F32),3.0,4.0,color,r8)
  r10 = box(x,y,scale,(0.0 - 3.0 : F32),(0.0 - 3.0 : F32),2.0,2.0,16741501,r9)
  box(x,y,scale,1.0,(0.0 - 3.0 : F32),2.0,2.0,16741501,r10)

def walker(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 8.0 : F32),(0.0 - 3.0 : F32),16.0,13.0,593433,tail)
  r1 = box(x,y,scale,(0.0 - 6.0 : F32),(0.0 - 2.0 : F32),12.0,10.0,color,r0)
  r2 = box(x,y,scale,(0.0 - 6.0 : F32),(0.0 - 13.0 : F32),12.0,12.0,593433,r1)
  r3 = box(x,y,scale,(0.0 - 4.0 : F32),(0.0 - 11.0 : F32),8.0,8.0,11252894,r2)
  r4 = box(x,y,scale,(0.0 - 3.0 : F32),(0.0 - 8.0 : F32),2.0,2.0,16741501,r3)
  r5 = box(x,y,scale,1.0,(0.0 - 8.0 : F32),2.0,2.0,16741501,r4)
  r6 = box(x,y,scale,(0.0 - 11.0 : F32),(0.0 - 1.0 : F32),3.0,10.0,11252894,r5)
  r7 = box(x,y,scale,8.0,(0.0 - 1.0 : F32),3.0,10.0,11252894,r6)
  r8 = box(x,y,scale,(0.0 - 6.0 : F32),8.0,4.0,5.0,593433,r7)
  r9 = box(x,y,scale,2.0,8.0,4.0,5.0,593433,r8)
  box(x,y,scale,(0.0 - 4.0 : F32),1.0,8.0,2.0,6318953,r9)

def slime(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 12.0 : F32),0.0,24.0,10.0,593433,tail)
  r1 = box(x,y,scale,(0.0 - 9.0 : F32),(0.0 - 5.0 : F32),18.0,14.0,593433,r0)
  r2 = box(x,y,scale,(0.0 - 8.0 : F32),(0.0 - 3.0 : F32),16.0,11.0,color,r1)
  r3 = box(x,y,scale,(0.0 - 10.0 : F32),2.0,20.0,6.0,color,r2)
  r4 = box(x,y,scale,(0.0 - 5.0 : F32),(0.0 - 2.0 : F32),5.0,2.0,14150064,r3)
  r5 = box(x,y,scale,(0.0 - 5.0 : F32),3.0,2.0,3.0,593433,r4)
  r6 = box(x,y,scale,3.0,3.0,2.0,3.0,593433,r5)
  box(x,y,scale,(0.0 - 2.0 : F32),7.0,4.0,1.0,593433,r6)

def beast(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 13.0 : F32),(0.0 - 4.0 : F32),25.0,11.0,593433,tail)
  r1 = box(x,y,scale,(0.0 - 11.0 : F32),(0.0 - 3.0 : F32),20.0,8.0,color,r0)
  r2 = box(x,y,scale,6.0,(0.0 - 8.0 : F32),9.0,10.0,593433,r1)
  r3 = box(x,y,scale,7.0,(0.0 - 6.0 : F32),7.0,7.0,color,r2)
  r4 = box(x,y,scale,7.0,(0.0 - 11.0 : F32),3.0,5.0,color,r3)
  r5 = box(x,y,scale,12.0,(0.0 - 10.0 : F32),3.0,4.0,color,r4)
  r6 = box(x,y,scale,11.0,(0.0 - 5.0 : F32),2.0,2.0,16741501,r5)
  r7 = box(x,y,scale,(0.0 - 9.0 : F32),6.0,3.0,5.0,593433,r6)
  r8 = box(x,y,scale,6.0,6.0,3.0,5.0,593433,r7)
  r9 = box(x,y,scale,(0.0 - 16.0 : F32),(0.0 - 6.0 : F32),5.0,3.0,color,r8)
  box(x,y,scale,12.0,1.0,5.0,3.0,12826525,r9)

def ghost(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 6.0 : F32),(0.0 - 12.0 : F32),12.0,5.0,593433,tail)
  r1 = box(x,y,scale,(0.0 - 9.0 : F32),(0.0 - 7.0 : F32),18.0,18.0,593433,r0)
  r2 = box(x,y,scale,(0.0 - 4.0 : F32),(0.0 - 10.0 : F32),8.0,5.0,color,r1)
  r3 = box(x,y,scale,(0.0 - 7.0 : F32),(0.0 - 5.0 : F32),14.0,15.0,color,r2)
  r4 = box(x,y,scale,(0.0 - 7.0 : F32),10.0,4.0,4.0,color,r3)
  r5 = box(x,y,scale,3.0,10.0,4.0,4.0,color,r4)
  r6 = box(x,y,scale,(0.0 - 3.0 : F32),(0.0 - 5.0 : F32),2.0,3.0,16052433,r5)
  r7 = box(x,y,scale,2.0,(0.0 - 5.0 : F32),2.0,3.0,16052433,r6)
  r8 = box(x,y,scale,(0.0 - 1.0 : F32),1.0,2.0,3.0,593433,r7)
  box(x,y,scale,(0.0 - 4.0 : F32),8.0,8.0,2.0,6715276,r8)

def spider(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 13.0 : F32),(0.0 - 8.0 : F32),5.0,3.0,color,tail)
  r1 = box(x,y,scale,8.0,(0.0 - 8.0 : F32),5.0,3.0,color,r0)
  r2 = box(x,y,scale,(0.0 - 16.0 : F32),(0.0 - 5.0 : F32),6.0,3.0,color,r1)
  r3 = box(x,y,scale,10.0,(0.0 - 5.0 : F32),6.0,3.0,color,r2)
  r4 = box(x,y,scale,(0.0 - 15.0 : F32),3.0,6.0,3.0,color,r3)
  r5 = box(x,y,scale,9.0,3.0,6.0,3.0,color,r4)
  r6 = box(x,y,scale,(0.0 - 12.0 : F32),6.0,4.0,4.0,color,r5)
  r7 = box(x,y,scale,8.0,6.0,4.0,4.0,color,r6)
  r8 = box(x,y,scale,(0.0 - 8.0 : F32),(0.0 - 7.0 : F32),16.0,16.0,593433,r7)
  r9 = box(x,y,scale,(0.0 - 6.0 : F32),(0.0 - 5.0 : F32),12.0,12.0,color,r8)
  r10 = box(x,y,scale,(0.0 - 5.0 : F32),(0.0 - 2.0 : F32),3.0,3.0,16741501,r9)
  r11 = box(x,y,scale,2.0,(0.0 - 2.0 : F32),3.0,3.0,16741501,r10)
  box(x,y,scale,(0.0 - 3.0 : F32),5.0,6.0,2.0,593433,r11)

def armored(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 10.0 : F32),(0.0 - 2.0 : F32),20.0,12.0,593433,tail)
  r1 = box(x,y,scale,(0.0 - 8.0 : F32),0.0,16.0,8.0,color,r0)
  r2 = box(x,y,scale,(0.0 - 8.0 : F32),(0.0 - 14.0 : F32),16.0,13.0,593433,r1)
  r3 = box(x,y,scale,(0.0 - 6.0 : F32),(0.0 - 12.0 : F32),12.0,9.0,9016996,r2)
  r4 = box(x,y,scale,(0.0 - 5.0 : F32),(0.0 - 8.0 : F32),10.0,3.0,593433,r3)
  r5 = box(x,y,scale,(0.0 - 2.0 : F32),(0.0 - 8.0 : F32),4.0,2.0,16741501,r4)
  r6 = box(x,y,scale,(0.0 - 13.0 : F32),(0.0 - 3.0 : F32),6.0,6.0,9016996,r5)
  r7 = box(x,y,scale,7.0,(0.0 - 3.0 : F32),6.0,6.0,9016996,r6)
  r8 = box(x,y,scale,(0.0 - 6.0 : F32),8.0,4.0,5.0,593433,r7)
  r9 = box(x,y,scale,2.0,8.0,4.0,5.0,593433,r8)
  r10 = box(x,y,scale,(0.0 - 1.0 : F32),0.0,2.0,7.0,9016996,r9)
  r11 = box(x,y,scale,(0.0 - 12.0 : F32),3.0,3.0,9.0,9016996,r10)
  box(x,y,scale,10.0,2.0,2.0,12.0,15391673,r11)

def ranged(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 7.0 : F32),(0.0 - 4.0 : F32),14.0,15.0,593433,tail)
  r1 = box(x,y,scale,(0.0 - 5.0 : F32),(0.0 - 3.0 : F32),10.0,12.0,color,r0)
  r2 = box(x,y,scale,(0.0 - 5.0 : F32),(0.0 - 13.0 : F32),10.0,11.0,593433,r1)
  r3 = box(x,y,scale,(0.0 - 3.0 : F32),(0.0 - 11.0 : F32),6.0,7.0,15391673,r2)
  r4 = box(x,y,scale,(0.0 - 2.0 : F32),(0.0 - 8.0 : F32),4.0,2.0,593433,r3)
  r5 = box(x,y,scale,(0.0 - 6.0 : F32),9.0,4.0,4.0,593433,r4)
  r6 = box(x,y,scale,2.0,9.0,4.0,4.0,593433,r5)
  r7 = box(x,y,scale,9.0,(0.0 - 13.0 : F32),2.0,25.0,10254413,r6)
  r8 = box(x,y,scale,7.0,(0.0 - 14.0 : F32),6.0,5.0,16741501,r7)
  r9 = box(x,y,scale,8.0,(0.0 - 13.0 : F32),4.0,2.0,16052433,r8)
  box(x,y,scale,(0.0 - 9.0 : F32),(0.0 - 1.0 : F32),3.0,8.0,color,r9)

def reaper(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 10.0 : F32),(0.0 - 13.0 : F32),20.0,27.0,593433,tail)
  r1 = box(x,y,scale,(0.0 - 7.0 : F32),(0.0 - 20.0 : F32),14.0,14.0,593433,r0)
  r2 = box(x,y,scale,(0.0 - 13.0 : F32),2.0,26.0,12.0,593433,r1)
  r3 = box(x,y,scale,(0.0 - 8.0 : F32),0.0,3.0,13.0,6827336,r2)
  r4 = box(x,y,scale,5.0,0.0,3.0,13.0,6827336,r3)
  r5 = box(x,y,scale,(0.0 - 6.0 : F32),(0.0 - 15.0 : F32),12.0,11.0,6367037,r4)
  r6 = box(x,y,scale,(0.0 - 4.0 : F32),(0.0 - 14.0 : F32),8.0,8.0,16052433,r5)
  r7 = box(x,y,scale,(0.0 - 3.0 : F32),(0.0 - 11.0 : F32),2.0,3.0,593433,r6)
  r8 = box(x,y,scale,1.0,(0.0 - 11.0 : F32),2.0,3.0,593433,r7)
  r9 = box(x,y,scale,(0.0 - 1.0 : F32),(0.0 - 7.0 : F32),2.0,3.0,15391673,r8)
  r10 = box(x,y,scale,12.0,(0.0 - 23.0 : F32),2.0,39.0,12893098,r9)
  r11 = box(x,y,scale,0.0,(0.0 - 24.0 : F32),16.0,3.0,16741501,r10)
  r12 = box(x,y,scale,(0.0 - 7.0 : F32),(0.0 - 21.0 : F32),8.0,3.0,16741501,r11)
  r13 = box(x,y,scale,(0.0 - 10.0 : F32),(0.0 - 18.0 : F32),5.0,3.0,16741501,r12)
  r14 = box(x,y,scale,(0.0 - 11.0 : F32),(0.0 - 15.0 : F32),3.0,4.0,16741501,r13)
  box(x,y,scale,(0.0 - 4.0 : F32),13.0,8.0,3.0,6827336,r14)

def wisp(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 2.0 : F32),(0.0 - 10.0 : F32),4.0,3.0,color,tail)
  r1 = box(x,y,scale,(0.0 - 5.0 : F32),(0.0 - 7.0 : F32),3.0,3.0,color,r0)
  r2 = box(x,y,scale,2.0,(0.0 - 7.0 : F32),3.0,3.0,color,r1)
  r3 = box(x,y,scale,(0.0 - 8.0 : F32),(0.0 - 4.0 : F32),3.0,7.0,color,r2)
  r4 = box(x,y,scale,5.0,(0.0 - 4.0 : F32),3.0,7.0,color,r3)
  r5 = box(x,y,scale,(0.0 - 5.0 : F32),3.0,3.0,3.0,color,r4)
  r6 = box(x,y,scale,2.0,3.0,3.0,3.0,color,r5)
  r7 = box(x,y,scale,(0.0 - 2.0 : F32),6.0,4.0,3.0,color,r6)
  r8 = box(x,y,scale,(0.0 - 2.0 : F32),(0.0 - 3.0 : F32),4.0,5.0,16052433,r7)
  box(x,y,scale,(0.0 - 1.0 : F32),10.0,2.0,3.0,color,r8)

def ward(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 11.0 : F32),8.0,22.0,5.0,593433,tail)
  r1 = box(x,y,scale,(0.0 - 9.0 : F32),9.0,18.0,3.0,6650747,r0)
  r2 = box(x,y,scale,(0.0 - 6.0 : F32),1.0,12.0,8.0,593433,r1)
  r3 = box(x,y,scale,(0.0 - 4.0 : F32),2.0,8.0,7.0,color,r2)
  r4 = box(x,y,scale,(0.0 - 8.0 : F32),(0.0 - 11.0 : F32),16.0,11.0,593433,r3)
  r5 = box(x,y,scale,(0.0 - 6.0 : F32),(0.0 - 9.0 : F32),12.0,7.0,color,r4)
  r6 = box(x,y,scale,(0.0 - 1.0 : F32),(0.0 - 10.0 : F32),2.0,9.0,16052433,r5)
  r7 = box(x,y,scale,(0.0 - 4.0 : F32),(0.0 - 7.0 : F32),8.0,2.0,16052433,r6)
  r8 = box(x,y,scale,(0.0 - 10.0 : F32),(0.0 - 3.0 : F32),4.0,3.0,6650747,r7)
  box(x,y,scale,6.0,(0.0 - 3.0 : F32),4.0,3.0,6650747,r8)

def hero(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 8.0 : F32),(0.0 - 6.0 : F32),16.0,19.0,593433,tail)
  r1 = box(x,y,scale,(0.0 - 11.0 : F32),6.0,22.0,7.0,593433,r0)
  r2 = box(x,y,scale,(0.0 - 6.0 : F32),(0.0 - 4.0 : F32),12.0,14.0,color,r1)
  r3 = box(x,y,scale,(0.0 - 9.0 : F32),8.0,18.0,3.0,color,r2)
  r4 = box(x,y,scale,(0.0 - 6.0 : F32),(0.0 - 16.0 : F32),12.0,12.0,593433,r3)
  r5 = box(x,y,scale,(0.0 - 4.0 : F32),(0.0 - 14.0 : F32),8.0,8.0,14993058,r4)
  r6 = box(x,y,scale,(0.0 - 5.0 : F32),(0.0 - 16.0 : F32),10.0,4.0,3550273,r5)
  r7 = box(x,y,scale,(0.0 - 5.0 : F32),(0.0 - 12.0 : F32),2.0,7.0,3550273,r6)
  r8 = box(x,y,scale,3.0,(0.0 - 12.0 : F32),2.0,7.0,3550273,r7)
  r9 = box(x,y,scale,(0.0 - 2.0 : F32),(0.0 - 10.0 : F32),1.0,2.0,593433,r8)
  r10 = box(x,y,scale,2.0,(0.0 - 10.0 : F32),1.0,2.0,593433,r9)
  r11 = box(x,y,scale,(0.0 - 6.0 : F32),4.0,12.0,2.0,15584891,r10)
  r12 = box(x,y,scale,9.0,(0.0 - 13.0 : F32),2.0,28.0,9796433,r11)
  r13 = box(x,y,scale,7.0,(0.0 - 16.0 : F32),6.0,6.0,7985384,r12)
  r14 = box(x,y,scale,8.0,(0.0 - 15.0 : F32),4.0,2.0,16052433,r13)
  r15 = box(x,y,scale,(0.0 - 7.0 : F32),11.0,4.0,4.0,593433,r14)
  r16 = box(x,y,scale,3.0,11.0,4.0,4.0,593433,r15)
  box(x,y,scale,(0.0 - 12.0 : F32),16.0,24.0,2.0,16052433,r16)

def chest(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 10.0 : F32),(0.0 - 7.0 : F32),20.0,15.0,593433,tail)
  r1 = box(x,y,scale,(0.0 - 8.0 : F32),(0.0 - 5.0 : F32),16.0,11.0,8935486,r0)
  r2 = box(x,y,scale,(0.0 - 8.0 : F32),(0.0 - 5.0 : F32),16.0,3.0,13936731,r1)
  r3 = box(x,y,scale,(0.0 - 9.0 : F32),0.0,18.0,2.0,15584891,r2)
  r4 = box(x,y,scale,(0.0 - 6.0 : F32),(0.0 - 5.0 : F32),2.0,11.0,15584891,r3)
  r5 = box(x,y,scale,4.0,(0.0 - 5.0 : F32),2.0,11.0,15584891,r4)
  box(x,y,scale,(0.0 - 2.0 : F32),(0.0 - 1.0 : F32),4.0,5.0,16052433,r5)

def relic(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  r0 = box(x,y,scale,(0.0 - 9.0 : F32),7.0,18.0,4.0,6914433,tail)
  r1 = box(x,y,scale,(0.0 - 6.0 : F32),3.0,12.0,4.0,10135194,r0)
  r2 = box(x,y,scale,(0.0 - 2.0 : F32),(0.0 - 15.0 : F32),4.0,4.0,16052433,r1)
  r3 = box(x,y,scale,(0.0 - 5.0 : F32),(0.0 - 11.0 : F32),10.0,5.0,color,r2)
  r4 = box(x,y,scale,(0.0 - 7.0 : F32),(0.0 - 6.0 : F32),14.0,6.0,color,r3)
  r5 = box(x,y,scale,(0.0 - 4.0 : F32),0.0,8.0,4.0,color,r4)
  r6 = box(x,y,scale,(0.0 - 1.0 : F32),(0.0 - 12.0 : F32),2.0,13.0,16052433,r5)
  r7 = box(x,y,scale,(0.0 - 11.0 : F32),(0.0 - 7.0 : F32),2.0,4.0,color,r6)
  box(x,y,scale,9.0,(0.0 - 7.0 : F32),2.0,4.0,color,r7)

def crowned(boss: Bool,+x: F32,+y: F32,+s: F32,color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match boss:
    case False{}: walker(x,y,s,color,tail)
    case True{}:
      a = armored(x,y,s,color,tail)
      b = box(x,y,s,(0.0 - 10.0 : F32),(0.0 - 19.0 : F32),3.0,8.0,15391673,a)
      c = box(x,y,s,7.0,(0.0 - 19.0 : F32),3.0,8.0,15391673,b)
      box(x,y,s,(0.0 - 5.0 : F32),(0.0 - 16.0 : F32),10.0,3.0,16741501,c)

def enemy(variant: U32,+x: F32,+y: F32,+s: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match variant:
    case 0: skeleton(x,y,s,color,tail)
    case 1: bat(x,y,s,color,tail)
    case 3: slime(x,y,s,color,tail)
    case 4: beast(x,y,s,color,tail)
    case 5: armored(x,y,s,color,tail)
    case 6: beast(x,y,s,color,tail)
    case 7: ghost(x,y,s,color,tail)
    case 8: spider(x,y,s,color,tail)
    case 9: ranged(x,y,s,color,tail)
    case 10: ranged(x,y,s,color,tail)
    case 11: chest(x,y,s,color,tail)
    case 12: armored(x,y,s,color,tail)
    case 13: bat(x,y,s,color,tail)
    case 14: slime(x,y,s,color,tail)
    case 15: bat(x,y,s,color,tail)
    case 16: armored(x,y,s,color,tail)
    case 17: spider(x,y,s,color,tail)
    case 18: armored(x,y,s,color,tail)
    case 19: ghost(x,y,s,color,tail)
    case 30: reaper(x,y,s,color,tail)
    case +v: crowned(U32.is_le(20,v),x,y,s,color,tail)

def ray(+x: F32,+y: F32,+r: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  a = D.rect((x - r : F32),(y - 2.0 : F32),(r * 2.0 : F32),4.0,593433,tail)
  b = D.rect((x - r : F32),(y - 1.0 : F32),(r * 2.0 : F32),2.0,color,a)
  D.rect((x + r - 2.0 : F32),(y - 2.0 : F32),2.0,4.0,16052433,b)

def spark(+x: F32,+y: F32,+r: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  a = D.rect((x - r * 0.4 : F32),(y - r : F32),(r * 0.8 : F32),(r * 2.0 : F32),color,tail)
  b = D.rect((x - r : F32),(y - r * 0.4 : F32),(r * 2.0 : F32),(r * 0.8 : F32),color,a)
  D.rect((x - 1.0 : F32),(y - 1.0 : F32),2.0,2.0,16052433,b)

def cross(+x: F32,+y: F32,+r: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  a = D.rect((x - 2.0 : F32),(y - r : F32),4.0,(r * 2.0 : F32),593433,tail)
  b = D.rect((x - r : F32),(y - 2.0 : F32),(r * 2.0 : F32),4.0,593433,a)
  c = D.rect((x - 1.0 : F32),(y - r : F32),2.0,(r * 2.0 : F32),color,b)
  D.rect((x - r : F32),(y - 1.0 : F32),(r * 2.0 : F32),2.0,color,c)

def area(+x: F32,+y: F32,+r: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  cross(x,y,F32.min(4.0,(r * 0.2 : F32)),color,ring(x,y,r,color,tail))

def projectile(variant: U32,+x: F32,+y: F32,+r: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match variant:
    case 1: ray(x,y,r,color,tail)
    case 3: ring(x,y,r,color,tail)
    case 4: area(x,y,r,color,tail)
    case 5: area(x,y,r,color,tail)
    case 7: area(x,y,r,color,tail)
    case 8: cross(x,y,r,color,tail)
    case 9: area(x,y,r,color,tail)
    case 10: ray(x,y,r,color,tail)
    case 11: area(x,y,r,color,tail)
    case 13: ray(x,y,r,color,tail)
    case 18: ray(x,y,r,color,tail)
    case 19: ring(x,y,r,color,tail)
    case 20: area(x,y,r,color,tail)
    case 21: spark(x,y,r,color,tail)
    case 22: area(x,y,r,color,tail)
    case _: spark(x,y,F32.min(r,9.0),color,tail)

def actor_shape(kind: U32,x: F32,y: F32,color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match kind:
    case 10: wisp(x,y,0.7,color,tail)
    case _: ward(x,y,0.9,color,tail)

def actor(phase: U32,+kind: U32,+x: F32,+y: F32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match phase:
    case 2: tail
    case +phase: actor_shape(kind,x,y,tint(U32.is_eq(phase,1),7985384,5930121),tail)

def hero_color(character: U32) -> U32:
  match character:
    case 0: 12343408
    case 1: 7445442
    case 2: 13280605
    case 3: 9157265
    case 4: 11305413
    case 5: 14653549
    case 6: 8565936
    case _: 11840636

def player(+x: F32,+y: F32,character: U32,invuln: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  hero(x,y,0.85,tint(U32.is_lt(0,invuln),16052433,hero_color(character)),tail)

def gem_scaled(+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  a = box(x,y,scale,(0.0 - 1.0 : F32),(0.0 - 4.0 : F32),2.0,8.0,color,tail)
  b = box(x,y,scale,(0.0 - 2.0 : F32),(0.0 - 2.0 : F32),4.0,4.0,color,a)
  c = box(x,y,scale,(0.0 - 3.0 : F32),(0.0 - 1.0 : F32),6.0,2.0,color,b)
  box(x,y,scale,(0.0 - 1.0 : F32),(0.0 - 2.0 : F32),1.0,2.0,16052433,c)
def gem(x: F32,y: F32,color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>: gem_scaled(x,y,1.0,color,tail)

def sprite(kind: U32,+variant: U32,+x: F32,+y: F32,+radius: F32,+color: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match kind:
    case 0: enemy(variant,x,y,F32.max(0.5,(radius / 10.0 : F32)),color,shadow(x,y,F32.max(0.5,(radius / 10.0 : F32)),color,tail))
    case 1: projectile(variant,x,y,radius,color,tail)
    case 2: gem(x,y,color,tail)
    case 3: box(x,y,1.0,(0.0 - 3.0 : F32),(0.0 - 3.0 : F32),6.0,6.0,14394951,box(x,y,1.0,(0.0 - 4.0 : F32),(0.0 - 4.0 : F32),8.0,8.0,593433,tail))
    case 4: cross(x,y,5.0,10871200,tail)
    case 5: chest(x,y,0.8,color,tail)
    case 6: ring(x,y,radius,color,tail)
    case 7: spark(x,y,F32.max(3.0,radius),16741501,ring(x,y,(radius + 2.0 : F32),593433,tail))
    case 8: tail
    case 9: relic(x,y,0.9,15584891,tail)
    case 10: actor(variant,kind,x,y,tail)
    case 11: actor(variant,kind,x,y,tail)
    case _: tail

# Always visible for living enemies, including full health. The dark track and
# pale border keep damage readable against every arena and enemy palette.
def health_bar_visible(visible: Bool,+x: F32,+y: F32,+radius: F32,hp: U32,+maxHp: U32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  match visible:
    case False{}: tail
    case True{}:
      +width = F32.max(16.0,(radius * 2.0 : F32))
      +left = (x - width / 2.0 : F32)
      +top = (y - 24.0 * F32.max(0.5,(radius / 10.0 : F32)) - 8.0 : F32)
      fill = (width * U32.to_f32(U32.min(hp,maxHp)) / U32.to_f32(U32.max(1,maxHp)) : F32)
      D.rect(left,top,fill,2.0,10871200,
        D.rect(left,top,width,2.0,5841972,
          D.rect((left - 1.0 : F32),(top - 1.0 : F32),(width + 2.0 : F32),4.0,15391673,tail)))
def health_bar(+kind: U32,+hp: U32,maxHp: U32,x: F32,y: F32,radius: F32,tail: List<&2,D.Rect>) -> List<&2,D.Rect>:
  health_bar_visible(Bool.and(U32.is_eq(kind,0),U32.is_lt(0,hp)),x,y,radius,hp,maxHp,tail)
