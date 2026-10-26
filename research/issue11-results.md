# Native bot 100x investigation

100x remains unmet. No performance change from this cycle is approved for master. This report preserves the experiment.

The current reference and candidate use master `c39d149`, published BendHub `bendvy-ecs-core@0.1.0.1`, native C, one world, two deterministic Bend policies, one runtime thread and GPU off. Node supervises development checks; it does not control the bots or exchange world JSON each tick.

| Evidence | Result |
| --- | --- |
| Both seeds, 36,000-tick physical/action/memory comparisons | Pass; 36,046/36,053 actions and 153/167 checkpoints |
| Fresh ordered journals | Pass at 1,200 ticks; full 36,000-tick runs unconfirmed |
| Current C profile | 6,000 ticks, 4,104 self samples; clean/instrumented telemetry matches all 101 records |
| Historical timing panel | Incomplete; one pair 379.433/340.575 seconds, next reference interrupted and retained |
| 100x qualification | Not achieved; requires each complete 600-game-second run within 6 external seconds |

The historical pair includes the Game query-binding change now present in master, the experimental personal fold and the boxed driver. It does not isolate our driver/fold contribution or qualify the current base. No failed attempt was dropped.

Shared runtime RC/closure helpers account for 47.8% of profile self samples. Named ECS helpers account for 10.0%, with another 7.7% in mapped World/Store helpers that mix transport and checks. Named personal helpers account for 2.2% and named telemetry helpers for 0.6%. These classifications do not measure complete subsystem costs; shared runtime is not exclusively ECS. Parent-chain rejection affects attribution. This is a diagnostic, not a speedup result.

Independent source/evidence reviews and Astra found no credible >=10% forecast for the remaining small usage-only changes. The next large investigation belongs in World/Store ownership transport while preserving access checks, capabilities, ordered events and rollback.

Current candidate ordinary/audit/journal C output is byte-identical to the earlier selected candidate; fresh binaries differ. Old captures remain historical, not new repeats. Generic personal-total laws and mutants were checked previously with unchanged source; the actual Game bridge has no claimed kernel verdict.

Local evidence is preserved under `.autoresearch/artifacts/resume039`, including `master-c39/build-and-validation/completion.json` (SHA256 `750f6be4bb9207d8bbb649fa32681ce12aadba98193dda63184a2faf02522e9e`), `final-query-profile/REPORT.md`, `final-c39-evidence-review.md`, and `astra-current-native-review.md`. The timing erratum is explicit: native work ended around 11:38 UTC, the last light parser at 11:40:38, and the light aggregate at 11:43:10.899, 10.899 seconds beyond the queue boundary. The later release notice and all original records are retained.

The retained local patch applies cleanly to c39d149 and contains only the selected Core/driver, numeric-total laws and verification entries. It has not been adopted. Unused specification helpers and rejected prototypes are excluded. The complete source worktrees and raw evidence remain intact.

Patch SHA256: `4bcd73bbc04708a5bbf751948c18ca311d01f2fc0c9c69366b49bcbdf6fbd6b9`.

The complete local report, source patch and source-hash manifest are preserved in `.autoresearch/artifacts/resume039/handoff-c39/` of the research checkout.
