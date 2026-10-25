# Benchmark entrypoints call the actual production observation and transitions.
import Base
import ./coop-core.bend as C

def observe(state:C.CoreState,id:U32) -> C.CorePacket: C.core_observe(state,id)
def start() -> C.CorePacket: C.core_start(0,0,12345)
def join(state:C.CoreState) -> C.CorePacket: C.core_join(state,1,0,0)
def step(state:C.CoreState) -> C.CorePacket: C.core_step(state,1.0,0.0,0.0,1.0)
def disconnect(state:C.CoreState) -> C.CorePacket: C.core_disconnect(state,1)
