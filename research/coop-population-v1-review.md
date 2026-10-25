# Co-op population v1 — independent review

## Analysis and report layer

Reviewer scope: `tools/survivors-bot/balance-report.py` and its test suite, reviewed on 2026-10-25 against the preregistered `research/coop-population-v1-contract.json`. This reviewer authored the population policy, so the policy implementation/proofs are **excluded** from this independent review claim. No analyzer or campaign code was edited by the reviewer. No actual campaign results or final-cohort game trajectories were inspected.

### Verified behavior

- The 20 existing analyzer controls passed before this review's new counterexamples. They are finite receipt/ledger tests, not gameplay-balance evidence.
- Phase 3 defeat, phase 4 victory (including HP zero at the game's endpoint), bounded horizon and infrastructure/incomplete runs stay distinct. A missing summary or non-completed campaign prevents final qualification. Death exactly on a milestone is counted as defeated by it; the separate strictly-before counter retains its intended inequality.
- Pairing uses explicit seed/setup/style/party tuples, equal horizons and complete canonical setup values, not receipt order. Game-axis comparisons freeze `policyHash`; bot-axis comparisons freeze `gameHash`; optional runner/setup/context guards are applied when present. The real native supervisor supplies these additional identities.
- Population integration uses left-held samples on their measured intervals. The pair metric uses exactly overlapping observed coverage and a common denominator, without filling the remainder after death. A hand calculation with baseline `(0,10),(60,20),(120,30)` and candidate `(30,5),(90,15)` produces the common interval30..90, integrals900/300 and mean delta−10. That agrees with the implementation and retained test.
- The exposure ledger is global across game/bot axes, blocks final seeds already used for tuning/evaluation, and permits a crossed setup only within the same frozen evaluation group with a distinct scope. This is declared-exposure bookkeeping; it does not detect undeclared manual inspection. No stronger secrecy or statistical independence guarantee is claimed.

### Concrete findings before the first real qualification

1. **Declared baseline/candidate roles were not enforced.** A synthetic, otherwise paired comparison with baseline extra25 and candidate extra100 returned `observations-complete` despite criteria declaring baseline100/preferred25. The individual values were allowed by the final cohort. This could invert the intended delta during a mistaken CLI invocation. Require baseline role validation and the preferred candidate in validation/final; keep development controls explicit.
2. **Declared setup verification was broader than its checks.** `declared_cohort` returned `verified: true` for final receipts whose two canonical setups both had stage99 while the contract's setup catalogue specified stage0. It checked seeds/horizon/profile/coefficient but not the full declared setup/style/party panel. The current native supervisor hardcodes stage0, so this is not an observed producer failure; it is a false provenance/admission claim that needs narrowing or a binding guard. Final-profile overrides must remain explicit rather than silently rejecting the declared advanced panel.
3. **Nullable population caused an uncaught exception.** The loader allowed `population: null`; the integration helper treated key presence as availability and raised `TypeError`. Missing/null metrics should be unavailable evidence (or a typed `Invalid` refusal), never zero and never an uncaught arithmetic crash.

All three findings were sent to the analyzer owner and root. The owner accepted them and is adding guards plus retained counterexample tests. Review disposition is pending that correction; the common-prefix arithmetic and outcome classification need no change for these findings.

### Initial reviewed source pins

- Analyzer SHA-256: `3ffc292222952ec2f8f0e76c0d743daa469f61e5619e42d5f48be7ffdc4f7023`.
- Test SHA-256: `97f5b63b72b835c9e1a287f003b1430a2ebbdc67f32c89644b98691b2c80fbb8`.

### Resolution on the frozen pre-formal analyzer

The analyzer owner fixed all three findings and retained their counterexamples. Independent rerun: **23/23 controls passed**. Separate reviewer reproductions now confirm:

- reversed extra25→extra100 arms are refused against baseline100 criteria;
- an undeclared stage99 is refused before the report can verify its declared cohort;
- `population: null` yields unavailable population evidence, without being filled as zero or raising `TypeError`;
- both current, explicitly catalogued fresh and advanced final setups are admitted in synthetic metadata checks.

The current criteria SHA-256 is `5661dd428f784a2ecad0aaa5b087e49448520eadfd4f5f553e86e14faed56ff0`. Git history retains the original contract and the pre-formal amendments `a5a646c` / `18f9e09`, which specify the existing advanced final setup and fresh-only early scopes. The numeric seeds, horizons, coefficient choices and selection rules remain unchanged. The initial integration warning about missing advanced metadata referred to the older file; it is resolved by those explicit amendments. The native supervisor now aligns semantic setup/style labels and `metaPreset` with the catalogue. No final-cohort game trajectories were read to make this correction.

**Disposition:** no remaining blocking analyzer finding in the reviewed scope. This approves receipt interpretation/guarding for the first real campaign, not the resulting coefficient or a claim of human enjoyment. Root must still use the same exposure ledger for subsequent bot/game analyses; a fresh path cannot establish that earlier undeclared inspections did not occur. Actual campaign source/binary identity and native receipt generation remain the supervisor/runner review scope, not a proof supplied by the analyzer.

### Final reviewed source pins

- Analyzer SHA-256: `7a870b5f15a1625655b979ab3c460d2c3981d09934aaa5e3c5d840f62a10ac63`.
- Tests SHA-256: `33f86b2827a60a8a516bbdcde0b942a44d35b8146c0ae94053057025c9f2acc1`.
