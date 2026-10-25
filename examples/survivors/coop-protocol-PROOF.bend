import Base
import ./coop-protocol.bend as P
import ./coop-session.bend as S
import ./coop-protocol-LAWS.bend as L

def L.oversized_refused(text,oversized):
  %oversized : {P.decode_bounded(_,text) == None{} : Maybe<&2,S.Command>}
  {==}
def L.parsed_number_exact(n,digits): {==}
def L.malformed_number_refused(digits): {==}

def L.tick_encoding_exact(round,x,y): {==}
def L.tick_fields_exact(session,player,seq,tick,round,x,y): {==}
