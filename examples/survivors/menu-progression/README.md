# Profile progression

[Browser progression](../menu-progression.bend) owns profile normalization,
prices, admission, purchases, rewards and achievements. [The browser adapter](../progression.mts)
converts values and persists them through localStorage.

[Native economy](../native-economy.bend) owns native purchases and profile slots;
[native recording](../native-record.bend) applies terminal receipts.
[The native adapter](../native-profile.bend) maps game observations and performs
file IO through the [profile codec](../native-profile-codec.bend).

Run the complete [proof gate](../../../scripts/check-bend-laws.py) and
[semantic mutation gate](../../../scripts/check-bend-mutants.py) from the repository root:

```sh
python3 scripts/check-bend-laws.py
python3 scripts/check-bend-mutants.py
```

The [browser laws](LAWS.bend) and [native economy laws](../native-economy/LAWS.bend)
state the exact guarantees and premises. Generic JSON arithmetic, malformed
profiles and native integer arithmetic have different representations; success
laws describe the actual production transformations, rather than asserting
cross-platform numeric equivalence. Receipt history is bounded by the
implementation; it does not provide permanent historical deduplication.

JavaScript scenario tests of Bend decisions are not maintained. Native file
persistence is exercised by [the IO check](../native-profile-io-check.bend).
