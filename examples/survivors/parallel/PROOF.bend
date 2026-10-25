import Base
import scheduler.bend as S
import LAWS.bend as L

def same(~Context:Data,~T:Data,~job:Context -> U32 -> T,+context:Context,+plan:S.Plan) -> {S.map_parallel(~Context,~T,~job,context,plan) == S.map_serial(~Context,~T,~job,context,plan) : S.Results<T>}:
  match plan:
    case S.Empty{}: {==}
    case S.Job{index}: {==}
    case S.Split{+left,+right}:
      Equal.trans(S.Results<T>,S.Both{S.map_parallel(~Context,~T,~job,context,left),S.map_parallel(~Context,~T,~job,context,right)},S.Both{S.map_serial(~Context,~T,~job,context,left),S.map_parallel(~Context,~T,~job,context,right)},S.Both{S.map_serial(~Context,~T,~job,context,left),S.map_serial(~Context,~T,~job,context,right)},Equal.cong(S.Results<T>,S.Results<T>,l => S.Both{l,S.map_parallel(~Context,~T,~job,context,right)},S.map_parallel(~Context,~T,~job,context,left),S.map_serial(~Context,~T,~job,context,left),same(~Context,~T,~job,context,left)),Equal.cong(S.Results<T>,S.Results<T>,r => S.Both{S.map_serial(~Context,~T,~job,context,left),r},S.map_parallel(~Context,~T,~job,context,right),S.map_serial(~Context,~T,~job,context,right),same(~Context,~T,~job,context,right)))
def L.parallel_matches_serial(Context,T,job,context,plan): same(~Context,~T,~job,context,plan)

def L.serial_executes_each_planned_job(Context,T,job,context,plan):
  match plan:
    case S.Empty{}: {==}
    case S.Job{index}: {==}
    case S.Split{+left,+right}:
      Equal.trans(List<&2,T>,List.append(&2,T,S.to_list(~T,S.map_serial(~Context,~T,~job,context,left)),S.to_list(~T,S.map_serial(~Context,~T,~job,context,right))),List.append(&2,T,L.ordered_jobs(~Context,~T,~job,context,left),S.to_list(~T,S.map_serial(~Context,~T,~job,context,right))),List.append(&2,T,L.ordered_jobs(~Context,~T,~job,context,left),L.ordered_jobs(~Context,~T,~job,context,right)),Equal.cong(List<&2,T>,List<&2,T>,xs => List.append(&2,T,xs,S.to_list(~T,S.map_serial(~Context,~T,~job,context,right))),S.to_list(~T,S.map_serial(~Context,~T,~job,context,left)),L.ordered_jobs(~Context,~T,~job,context,left),L.serial_executes_each_planned_job(~Context,~T,~job,context,left)),Equal.cong(List<&2,T>,List<&2,T>,ys => List.append(&2,T,L.ordered_jobs(~Context,~T,~job,context,left),ys),S.to_list(~T,S.map_serial(~Context,~T,~job,context,right)),L.ordered_jobs(~Context,~T,~job,context,right),L.serial_executes_each_planned_job(~Context,~T,~job,context,right)))
