import Base
import bot-grid-layout.bend as L

law ten_columns: {L.columns(10) == 4 : U32}
law ten_rows: {L.rows(10) == 3 : U32}
law ten_height: {L.height(10) == 768 : U32}
law max_height: {L.height(64) == 1024 : U32}
# Guarantees: the four input images retain their row-major positions.
# Why it matters: compositing must never swap independent worlds.
law four_row_major:
  for a: Image
  for b: Image
  for c: Image
  for d: Image
  {L.image(4,[a,b,c,d]) == Qua{a,b,c,d} : Image}
# Guarantees: ten images fill three rows with background in every unused slot.
# Why it matters: the rectangular window must preserve IDs across quadrant boundaries.
law ten_row_major:
  for a: Image
  for b: Image
  for c: Image
  for d: Image
  for e: Image
  for f: Image
  for g: Image
  for h: Image
  for i: Image
  for j: Image
  {L.image(10,[a,b,c,d,e,f,g,h,i,j]) == Qua{Qua{a,b,e,f},Qua{c,d,g,h},Qua{i,j,Pix{725017},Pix{725017}},Qua{Pix{725017},Pix{725017},Pix{725017},Pix{725017}}} : Image}
law first_seed: {L.seed(12345,0) == 12345 : U32}
law tenth_seed: {L.seed(12345,9) == 12354 : U32}
law seed_wrap: {L.seed(4294967295,1) == 0 : U32}
