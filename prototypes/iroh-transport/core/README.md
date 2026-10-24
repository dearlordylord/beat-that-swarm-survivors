# Bend protocol boundary

This protocol is independent of the Survivors game and ECS. Iroh supplies an
authenticated peer connection and transports bytes. Bend owns message admission,
serialization/parsing, sequence consumption and receive-frontier updates.

`ProtocolSession` in `../core-adapter.mjs` wraps the emitted Bend module. It exposes
`send(text)`, `receive(wire)`, `reset()` and `snapshot()`. Send results contain
`accepted`, `wire`, `seq`, `text`, `reason`, `state`; receive results omit `wire`.
The state is `{nextSeq,lastRemoteSeq,sent,received,rejected}`. `sent` counts locally
prepared envelopes, not successful network writes or peer acknowledgments. Accepted
receive count is application admission on this endpoint. There is no delivery-ACK
message in this prototype.

## Wire and session contract

The UTF-8 body is `BIP1|<canonical decimal sequence>|<text>`. The text is nonempty,
at most 256 Unicode scalar values, and may contain additional `|` characters,
line breaks and emoji. Iroh's shared byte transport separately limits messages to 1 MiB. The lab's
256-scalar application limit remains unchanged; the game uses a separate protocol. Invalid JavaScript
UTF-16 strings are normalized by Bend's compiler String ABI to U+FFFD before the
pure protocol sees them; valid scalar Unicode round-trips exactly.

Each newly authenticated connection epoch must create/reset a `ProtocolSession`.
Sequence numbers start at 1. Receive admits only a strictly larger sequence than
its previously accepted frontier, up to 4294967295. Duplicate, zero, older,
noncanonical, malformed, unsupported-version and oversize messages do not deliver.
The final send number is 4294967295; nextSeq then becomes 0 as an exhausted sentinel
and further sends refuse without consuming state. The transport must preserve
message order, for example using one framed stream; this core does not reorder or
buffer older arrivals. Gaps are allowed, so a failed send may leave a sequence gap.

Peer identity is deliberately not a trusted field inside the envelope. The host
binds the ProtocolSession to the authenticated Iroh connection. A standalone call
to this codec does not prove who sent bytes, and resetting a session does not revoke
an old socket: the caller must discard events from old connection epochs.

## Validation and limits

From the repository root:

```sh
BEND=bend bash prototypes/iroh-transport/core/check.sh
```

The runner checks the source, proves four laws with the independent `--verdict`
kernel, emits the JavaScript module, builds a real native Bend/C codec executable,
and runs runtime and mutation gates. Proof compilations are bounded to 10 CPU
seconds and 60 wall seconds. Native codec CLI examples:

```sh
prototypes/iroh-transport/dist/protocol-native encode 'Hello|😀'
prototypes/iroh-transport/dist/protocol-native decode 'BIP1|1|Hello|😀'
```

The four laws prove exactly that the explicit refusal branch of send preserves
all protocol state; the refusal branch of receive preserves accepted frontier and
received count; and the success branch installs exactly the supplied frontier.
They do not prove the full parser, UTF-8 codec, monotonic admission predicate,
transport authentication or network delivery. Runtime checks exercise those public
codec paths on malformed/boundary/duplicate/old packets,256/257-codepoint Unicode
boundaries, sequence exhaustion,200 generated Unicode payloads, and actual C/JS
wire agreement. Three deliberate implementation mutations must fail the preserved
proofs: changing refused-send state, dropping refused-receive state, or installing
the wrong accepted frontier. Neither the protocol tests nor these proofs qualify
internet connectivity, NAT traversal, host migration or multiplayer game mechanics.
