# Guest reload and touch reward selection

The host closed its entire Iroh endpoint on guest disconnect. The invitation
therefore pointed at a closed endpoint. Independently, admission retained the
old guest sequence and the game only allocated a guest before tick zero.

The host now retains its endpoint and pauses simulation when the connection
closes. A new connection has a fresh guest command lane, input queue and receipt;
connection epochs fence queued messages, snapshots and late worker notifications.
An existing player is reattached without applying the lobby setup again. The
complete world, health, equipment and pending reward choices remain in memory.
The invitation grants the vacant guest slot; this is not an account-based resume
system. Closing/reloading the host still destroys the party. A connection attempt
has a 45-second outer deadline, in addition to Iroh's operation timeouts.

Bend laws pin live-session lane reset, ended-session preservation, fresh setup
admission, and initial/return dispatch for arbitrary affine state. The dispatcher
law does not prove its caller/adapters: production wiring and complete emitted
CoreState equality were checked separately. The direct monolithic core proof
exceeded the existing kernel CPU budget; that is not counted as a passing proof.

A temporary two-browser diagnostic over real Iroh exercised reload during combat
and a pending reward. The initial post-rejoin guest observation matched the full
paused observation, the invitation stayed identical, and the world did not advance
while disconnected. The reward was opened using a diagnostic fixture through the
production Bend reward path; this was not an organically earned level-up.

Touch diagnostics reproduced a separate CSS fault at 375×667: the later-positioned
movement pad overlapped the third reward card and intercepted its tap. The pad is
now hidden while the reward modal is visible, with manipulation touch handling on
cards. The same touch coordinate sends exactly one choice; a one-tap guest choice
was also acknowledged by the host over Iroh. Chromium touch emulation was checked;
Safari/device behavior remains unqualified. These temporary browser diagnostics
are evidence of exercised paths, not a replacement for Bend laws or release gates.
