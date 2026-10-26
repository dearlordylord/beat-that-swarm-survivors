# Profile progression

[Browser progression](../menu-progression.bend) owns profile normalization,
prices, admission, purchases, rewards and achievements. [The browser adapter](../progression.mts)
passes concrete progression records and persists the browser profile through localStorage.
Presentation settings stay in the host; gameplay prices and eligibility stay in Bend.

[Native economy](../native-economy.bend) owns native purchases and profile slots;
[native recording](../native-record.bend) applies terminal receipts.
[The native adapter](../native-profile.bend) maps game observations and performs
file IO through the [profile codec](../native-profile-codec.bend).

Run the proofs directly from the repository root:

```sh
bend examples/survivors/menu-progression/PROOF.bend --verdict
bend examples/survivors/native-economy/PROOF.bend --verdict
bend examples/survivors/native-record/PROOF.bend --verdict
```

The [browser laws](LAWS.bend) and [native economy laws](../native-economy/LAWS.bend)
state the exact guarantees and premises. Browser amounts use exact nonnegative
rational arithmetic from [menu-amount.bend](../menu-amount.bend); native economy
uses its existing integer representation. Success laws describe the actual
production transformations, rather than asserting cross-platform numeric
equivalence. The host validates stored JSON before constructing progression
records; malformed saved profiles start fresh. Receipt history is bounded by the
implementation; it does not provide permanent historical deduplication.

JavaScript scenario tests of Bend decisions are not maintained. Native file
persistence is exercised by [the IO check](../native-profile-io-check.bend).
