import Base
import arithmetic-core.bend as A
import common.bend as C

# Finite arithmetic model fixtures, not a GPU/runtime correctness theorem.
law scalar_two_steps:
  {A.job(2,100,0) == C.Answer{203,True{}} : C.Answer}
law eight_jobs_two_steps:
  {A.solve(2,100) == C.Answer{1680,True{}} : C.Answer}
law wrapping_step:
  {A.job(2,4294967295,0) == C.Answer{1,True{}} : C.Answer}
