#!/usr/bin/env python3
"""Receipt and exposure-ledger controls, not a game-balance qualification."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("balance_report", HERE / "balance-report.py")
R = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(R)


class BalanceReportControls(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.criteria = {"schemaVersion": 1, "axis": "game", "milestoneTicks": [60, 180]}
        self.criteria_path = self.root / "criteria.json"
        self.criteria_path.write_text(json.dumps(self.criteria))
        self.criteria_hash = R.digest_bytes(self.criteria_path.read_bytes())

    def sample(self, seed, tick, population, **extra):
        return {"type": "sample", "seed": seed, "tick": tick, "phase": 0, "population": population,
                "hp0": 70, "hp1": 70, "maxHp0": 70, "maxHp1": 70, "xp": 0, "level": 1, "kills": 0, **extra}

    def summary(self, seed, tick=180, phase=0, outcome="horizon", **extra):
        return {"type": "summary", "seed": seed, "tick": tick, "phase": phase, "outcome": outcome,
                "hp0": 70, "hp1": 70, "xp": 0, "level": 1, "kills": 0, "uncollectedBaseXp": 8, **extra}

    def campaign(self, name, rows=None, **changes):
        directory = self.root / name
        directory.mkdir()
        manifest = {"schemaVersion": 1, "campaignId": name, "status": "completed", "setupId": "fresh-duo",
                    "styleId": "resource-memory-duo", "setup": {"profile": "fresh", "characters": [0, 0], "stage": 0, "arcana": [0, 0]}, "partySize": 2, "requestedTicks": 180,
                    "gameHash": ("a" if name == "baseline" else "b") * 64, "policyHash": "c" * 64,
                    "sourceHash": "d" * 64, "gameContextHash": "e" * 64, "extraPercent": 25,
                    "seeds": [1, 2], "records": ["runs.jsonl"], "criteriaSha256": self.criteria_hash, **changes}
        if rows is None:
            rows = []
            for seed in manifest["seeds"]:
                rows += [self.sample(seed, 0, seed * 10), self.sample(seed, 60, seed * 10 + 10), self.summary(seed)]
        (directory / "manifest.json").write_text(json.dumps(manifest))
        (directory / "runs.jsonl").write_text("".join(json.dumps(row) + "\n" for row in rows))
        return directory

    def compare(self, left, right, **kwargs):
        return R.compare(R.load_campaign(left), R.load_campaign(right), self.criteria, self.criteria_hash, **kwargs)

    def test_pairing_uses_seed_not_receipt_order(self):
        left = self.campaign("baseline")
        rows = []
        for seed in [2, 1]:
            rows += [self.sample(seed, 0, seed * 10 - 3), self.sample(seed, 60, seed * 10 + 7), self.summary(seed)]
        report = self.compare(left, self.campaign("candidate", rows))
        self.assertEqual(report["pairCount"], 2)
        self.assertEqual([p["identity"]["seed"] for p in report["pairs"]], [1, 2])
        self.assertTrue(all(r["pairedMeanDelta"] == -3 for r in report["pairedTimeCurves"] if r["field"] == "population"))
        self.assertEqual(report["outcomes"]["baseline"]["horizon"], 2)
        self.assertEqual(report["outcomes"]["baseline"]["victory"], 0)

    def test_different_seed_setup_or_horizon_refused(self):
        baseline = self.campaign("baseline")
        for name, change in [("seed", {"seeds": [1, 3]}), ("setup", {"setupId": "advanced"}), ("horizon", {"requestedTicks": 181})]:
            with self.subTest(name=name), self.assertRaises(R.Invalid):
                self.compare(baseline, self.campaign(name, **change))

    def test_frozen_axis_guard_and_context_guard(self):
        baseline = self.campaign("baseline")
        with self.assertRaisesRegex(R.Invalid, "policyHash"):
            self.compare(baseline, self.campaign("changed-policy", policyHash="f" * 64))
        with self.assertRaisesRegex(R.Invalid, "context"):
            self.compare(baseline, self.campaign("changed-context", gameContextHash="f" * 64))
        self.criteria["axis"] = "bot"
        with self.assertRaisesRegex(R.Invalid, "gameHash"):
            self.compare(baseline, self.campaign("changed-game"))
        report = self.compare(baseline, self.campaign("bot-candidate", gameHash="a" * 64, policyHash="f" * 64))
        self.assertEqual(report["axis"], "bot")

    def test_complete_setup_and_runner_identity_guard(self):
        baseline = self.campaign("baseline", runnerHash="f" * 64)
        with self.assertRaisesRegex(R.Invalid, "canonical setup"):
            self.compare(baseline, self.campaign("mislabeled", setup={"profile": "advanced"}, runnerHash="f" * 64))
        with self.assertRaisesRegex(R.Invalid, "runnerHash"):
            self.compare(baseline, self.campaign("different-runner", runnerHash="a" * 64))

    def test_common_prefix_has_equal_denominators_and_no_postdeath_fill(self):
        left = [self.sample(1, 0, 10), self.sample(1, 60, 20), self.sample(1, 120, 30)]
        right = [self.sample(1, 30, 5), self.sample(1, 90, 15)]
        result = R.common_population(left, right)
        self.assertEqual((result["startTick"], result["endTick"], result["observedTicks"]), (30, 90, 60))
        self.assertEqual(result["baselinePopulationTickIntegral"], 900)
        self.assertEqual(result["candidatePopulationTickIntegral"], 300)
        self.assertEqual(result["timeWeightedPopulationDelta"], -10)

    def test_future_milestones_distinguish_early_defeat_from_horizon(self):
        self.criteria["milestoneTicks"] = [3600]
        baseline = self.campaign("baseline", [self.summary(1, tick=100, phase=3, outcome="defeat"), self.summary(2)], requestedTicks=180)
        candidate = self.campaign("candidate", [self.sample(1, 0, 5), self.sample(1, 60, 10, level=2), self.summary(1, level=2), self.summary(2)])
        report = self.compare(baseline, candidate)
        b, c = report["milestones"][0]["baseline"], report["milestones"][0]["candidate"]
        self.assertEqual((b["defeatedByMilestone"], b["unknownOrCensoredBefore"]), (1, 1))
        self.assertEqual(c["unknownOrCensoredBefore"], 2)
        self.assertEqual(b["level2ObservedByTick"], {"yes": 0, "no": 1, "unknown": 1})
        self.assertEqual(c["level2ObservedByTick"], {"yes": 1, "no": 0, "unknown": 1})

    def test_declared_win_cannot_hide_horizon_or_defeat(self):
        baseline = self.campaign("baseline")
        for phase in [0, 3]:
            with self.subTest(phase=phase), self.assertRaisesRegex(R.Invalid, "contradicts"):
                self.compare(baseline, self.campaign("bad" + str(phase), [self.summary(1, phase=phase, outcome="victory"), self.summary(2)]))

    def test_phase_four_zero_hp_is_victory_not_defeat(self):
        report = self.compare(self.campaign("baseline"), self.campaign("candidate", [self.summary(1, phase=4, outcome="victory", hp0=0, hp1=0), self.summary(2, tick=90, phase=3, outcome="defeat", hp0=0, hp1=0)]))
        self.assertEqual(report["outcomes"]["candidate"]["victory"], 1)
        self.assertEqual(report["outcomes"]["candidate"]["defeat"], 1)
        self.assertEqual(report["milestones"][1]["candidate"]["aliveOrReachedEndpoint"], 1)
        self.assertEqual(report["milestones"][1]["candidate"]["defeatedByMilestone"], 1)

    def test_missing_summary_or_failed_campaign_is_inconclusive(self):
        baseline = self.campaign("baseline")
        report = self.compare(baseline, self.campaign("candidate", [self.summary(1)]))
        self.assertEqual(report["status"], "inconclusive")
        self.assertEqual(report["outcomes"]["candidate"]["infrastructure"], 1)
        failed = self.compare(baseline, self.campaign("failed", status="timeout"))
        self.assertEqual(failed["status"], "inconclusive")
        self.assertEqual(failed["outcomes"]["candidate"]["horizon"], 2)

    def test_time_integral_uses_actual_intervals_and_no_horizon_extension(self):
        rows = [self.sample(1, 0, 10), self.sample(1, 30, 20), self.sample(1, 120, 99)]
        observed = R.population_observation(rows)
        self.assertEqual(observed["populationTickIntegral"], 2100)
        self.assertEqual(observed["observedTicks"], 120)
        self.assertEqual(observed["timeWeightedPopulation"], 17.5)
        self.assertNotEqual(observed["timeWeightedPopulation"], (10 + 20 + 99) / 3)

    def test_missing_samples_never_become_zero_or_invent_damage(self):
        rows = [self.sample(1, 0, 10), self.sample(1, 60, 20, hp0=75), self.summary(1), self.summary(2)]
        del rows[1]["population"]
        report = self.compare(self.campaign("baseline"), self.campaign("candidate", rows))
        self.assertFalse(report["pairs"][0]["candidatePopulation"]["available"])
        pop_ticks = [r for r in report["pairedTimeCurves"] if r["field"] == "population"]
        self.assertEqual([r["tick"] for r in pop_ticks], [0])
        self.assertTrue(any("not received damage" in text for text in report["limits"]))
        self.assertTrue(any("missingTelemetry" in note for note in report["pairs"][0]["retrospective"]))
        self.assertNotIn("damageTaken", json.dumps(report))

    def test_duplicate_seed_and_nonmonotone_samples_refused(self):
        with self.assertRaisesRegex(R.Invalid, "duplicate seeds"):
            R.load_campaign(self.campaign("bad-seeds", seeds=[1, 1]))
        with self.assertRaisesRegex(R.Invalid, "strictly increase"):
            R.load_campaign(self.campaign("bad-time", [self.sample(1, 60, 20), self.sample(1, 30, 10)]))
        with self.assertRaisesRegex(R.Invalid, "duplicate summary"):
            R.load_campaign(self.campaign("bad-summary", [self.summary(1), self.summary(1)]))

    def test_criteria_binding_required_except_explicit_diagnostic(self):
        left = self.campaign("baseline")
        right = self.campaign("candidate", criteriaSha256="f" * 64)
        with self.assertRaisesRegex(R.Invalid, "criteria hash"):
            self.compare(left, right)
        report = self.compare(left, right, allow_unbound=True)
        self.assertEqual(report["status"], "diagnostic-only")
        self.assertFalse(report["criteriaBoundToCampaigns"])

    def test_global_holdout_guard_across_bot_and_game_and_idempotency(self):
        path = self.root / "ledger.json"
        tune = {"seeds": [1, 2], "axis": "bot", "cohort": "development", "purpose": "tune", "note": "inspected paths"}
        R.register_usage(path, tune)
        final = {"seeds": [2, 3], "axis": "game", "cohort": "final", "purpose": "evaluate", "comparison": "new-game"}
        with self.assertRaisesRegex(R.Invalid, "already exposed"):
            R.register_usage(path, final)
        final["seeds"] = [3, 4]
        self.assertTrue(R.register_usage(path, final)["registered"])
        self.assertTrue(R.register_usage(path, final)["idempotent"])
        final["comparison"] = "another-candidate"
        with self.assertRaisesRegex(R.Invalid, "already exposed"):
            R.register_usage(path, final)

    def test_final_crossed_setups_share_one_frozen_group_not_new_candidate(self):
        path = self.root / "ledger.json"
        first = {"seeds": [3, 4], "axis": "game", "cohort": "final", "purpose": "evaluate", "comparison": "fresh-pair", "evaluationGroup": "frozen-candidate", "scope": "fresh"}
        R.register_usage(path, first)
        second = {**first, "comparison": "advanced-pair", "scope": "advanced"}
        self.assertTrue(R.register_usage(path, second)["registered"])
        self.assertTrue(R.register_usage(path, second)["idempotent"])
        with self.assertRaises(R.Invalid):
            R.register_usage(path, {**first, "comparison": "rerun-fresh"})
        with self.assertRaises(R.Invalid):
            R.register_usage(path, {**second, "comparison": "next-candidate", "evaluationGroup": "retuned-candidate", "scope": "fresh-v2"})

    def test_malformed_ledger_cannot_hide_string_seed_overlap(self):
        path = self.root / "ledger.json"
        path.write_text(json.dumps({"schemaVersion": 1, "uses": [{"seeds": ["1"], "axis": "bot", "cohort": "development", "purpose": "tune"}]}))
        with self.assertRaises(R.Invalid):
            R.register_usage(path, {"seeds": [1], "axis": "game", "cohort": "final", "purpose": "evaluate"})

    def test_cli_writes_evidence_and_refuses_final_without_ledger(self):
        left, right = self.campaign("baseline"), self.campaign("candidate")
        command = ["python3", str(HERE / "balance-report.py"), "compare", "--baseline", str(left), "--candidate", str(right), "--criteria", str(self.criteria_path), "--output", str(self.root / "report")]
        completed = subprocess.run(command, text=True, capture_output=True, timeout=5)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        report = json.loads((self.root / "report/report.json").read_text())
        self.assertTrue(report["criteriaBoundToCampaigns"])
        self.assertEqual(report["baseline"]["manifestSha256"], R.digest_bytes((left / "manifest.json").read_bytes()))
        self.assertEqual(report["analyzerSha256"], R.digest_bytes((HERE / "balance-report.py").read_bytes()))
        final = subprocess.run(command + ["--cohort", "final", "--purpose", "evaluate"], text=True, capture_output=True, timeout=5)
        self.assertEqual(final.returncode, 1)
        self.assertIn("requires a global exposure ledger", final.stderr)

    def test_declared_cohorts_reject_mislabeled_seed_and_allow_cost_pilot(self):
        left, right = self.campaign("baseline"), self.campaign("candidate")
        campaigns = [R.load_campaign(left), R.load_campaign(right)]
        criteria = {"cohorts": [{"id": "dev", "kind": "development", "seeds": [1, 2], "requestedTicks": 180}, {"id": "held", "kind": "final", "seeds": [3, 4], "requestedTicks": 180}], "pilot": {"seed": 1, "requestedTicks": 60, "extraPercents": [25]}}
        self.assertTrue(R.declared_cohort(criteria, campaigns, "development")["entireDeclaredCohortIncluded"])
        with self.assertRaisesRegex(R.Invalid, "declared final"):
            R.declared_cohort(criteria, campaigns, "final")
        pilot = [R.load_campaign(self.campaign("pilot-a", [self.sample(1, 0, 10), self.summary(1, tick=60)], seeds=[1], requestedTicks=60)), R.load_campaign(self.campaign("pilot-b", [self.sample(1, 0, 10), self.summary(1, tick=60)], seeds=[1], requestedTicks=60))]
        self.assertEqual(R.declared_cohort(criteria, pilot, "development")["scope"], "pilot")
        with self.assertRaisesRegex(R.Invalid, "declared final"):
            R.declared_cohort(criteria, pilot, "final")

    def test_reversed_baseline_arm_and_wrong_confirmation_candidate_refused(self):
        left, right = self.campaign("baseline", extraPercent=25), self.campaign("candidate", extraPercent=100)
        self.criteria["baselineExtraPercent"] = 100
        with self.assertRaisesRegex(R.Invalid, "baseline arm"):
            self.compare(left, right)
        criteria = {"preferredExtraPercent": 25, "cohorts": [{"kind": "final", "seeds": [1, 2], "requestedTicks": 180, "extraPercents": [25, 100]}]}
        with self.assertRaisesRegex(R.Invalid, "confirmation candidate"):
            R.declared_cohort(criteria, [R.load_campaign(right), R.load_campaign(right)], "final")

    def test_declared_setup_catalog_binds_stage_style_and_party(self):
        self.criteria["setups"] = [{"setupId": "fresh-duo", "styleId": "resource-memory-duo", "partySize": 2, "profile": "fresh", "characters": [0, 0], "stage": 0, "arcana": [0, 0]}]
        for name, change in [("wrong-stage", {"setup": {"profile": "fresh", "characters": [0, 0], "stage": 99, "arcana": [0, 0]}}), ("wrong-style", {"styleId": "another-policy"}), ("wrong-party", {"partySize": 1})]:
            with self.subTest(name=name), self.assertRaisesRegex(R.Invalid, "predeclared setup"):
                self.compare(self.campaign(name + "-b", **change), self.campaign(name + "-c", **change))

    def test_null_population_is_missing_not_typeerror_or_zero(self):
        rows = [self.sample(1, 0, None), self.sample(1, 60, 20), self.summary(1), self.summary(2)]
        report = self.compare(self.campaign("baseline"), self.campaign("candidate", rows))
        self.assertFalse(report["pairs"][0]["candidatePopulation"]["available"])
        self.assertFalse(report["pairs"][0]["commonPrefixPopulation"]["available"])
        self.assertEqual([x["tick"] for x in report["pairedTimeCurves"] if x["field"] == "population"], [60])

    def test_null_progression_and_xp_remainder_remain_unknown(self):
        rows = [self.sample(1, 0, 10, level=None), self.sample(1, 60, 20, level=None), self.summary(1, level=None, uncollectedBaseXp=None), self.summary(2)]
        report = self.compare(self.campaign("baseline"), self.campaign("candidate", rows))
        self.assertEqual(report["milestones"][0]["candidate"]["level2ObservedByTick"]["unknown"], 1)
        self.assertFalse(any(note.get("observation") == "Uncollected XP remains" for note in report["pairs"][0]["retrospective"] if note.get("arm") == "candidate"))

    def test_json_root_must_be_object(self):
        path = self.root / "malformed.json"
        path.write_text("[]")
        with self.assertRaisesRegex(R.Invalid, "JSON object"):
            R.read_json(path)

    def test_record_path_escape_and_resource_budget_refused(self):
        campaign = self.campaign("baseline")
        manifest = json.loads((campaign / "manifest.json").read_text())
        manifest["records"] = ["../criteria.json"]
        (campaign / "manifest.json").write_text(json.dumps(manifest))
        with self.assertRaisesRegex(R.Invalid, "escapes"):
            R.load_campaign(campaign)
        with self.assertRaisesRegex(R.Invalid, "resource limit"):
            R.load_campaign(self.campaign("bounded"), max_records=1)


if __name__ == "__main__":
    unittest.main()
