import Base
import scheduler.bend as S

# Scheduling may change evaluation order, never the result shape/values.
# This is pure scheduler equivalence, not universal game equivalence.
law parallel_matches_serial:
  for ~Context:Data
  for ~T:Data
  for ~job:Context -> U32 -> T
  for +context:Context
  for +plan:S.Plan
  {S.map_parallel(~Context,~T,~job,context,plan) == S.map_serial(~Context,~T,~job,context,plan) : S.Results<T>}

def ordered_jobs(~Context:Data,~T:Data,~job:Context -> U32 -> T,+context:Context,plan:S.Plan) -> List<&2,T>:
  match plan:
    case S.Empty{}: []
    case S.Job{index}: [job(context,index)]
    case S.Split{left,right}: List.append(&2,T,ordered_jobs(~Context,~T,~job,context,left),ordered_jobs(~Context,~T,~job,context,right))

# Guarantees: serial execution produces each planned job's result in left-to-right
# leaf order, including repeated identifiers and machine-wraparound values.
# Why it matters: agreement between parallel and serial execution alone would
# allow both implementations to drop the same jobs or replace all their results.
law serial_executes_each_planned_job:
  for ~Context:Data
  for ~T:Data
  for ~job:Context -> U32 -> T
  for +context:Context
  for +plan:S.Plan
  {S.to_list(~T,S.map_serial(~Context,~T,~job,context,plan)) == ordered_jobs(~Context,~T,~job,context,plan) : List<&2,T>}
