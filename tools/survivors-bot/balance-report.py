#!/usr/bin/env python3
"""Candidate for deletion: optional research tooling, not required to build or run the game.

Compare frozen native balance receipts; no game execution or policy mutation.

Reports observations, not causation or an automatic judgement of enjoyment.
"""
import argparse
from contextlib import contextmanager
import hashlib
import json
from pathlib import Path
import statistics
import sys
import tempfile
import os

SCHEMA = 1
PAIR_FIELDS = ("seed", "setupId", "styleId", "partySize")
IDENTITIES = ("gameHash", "policyHash", "sourceHash")
SAMPLE_FIELDS = ("population", "ordinaryPopulation", "bossPopulation", "nearEnemies0", "nearEnemies1", "hp0", "hp1", "maxHp0", "maxHp1", "xp", "xpNeed", "level", "kills", "xpPiles", "uncollectedBaseXp")


class Invalid(ValueError):
    pass


def digest_bytes(value):
    return hashlib.sha256(value).hexdigest()


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), allow_nan=False)


def read_json(path):
    try:
        value = json.loads(path.read_text(), parse_constant=lambda value: (_ for _ in ()).throw(Invalid("non-finite JSON: " + value)))
        if not isinstance(value, dict):
            raise Invalid("expected a JSON object")
        return value
    except (OSError, ValueError) as error:
        raise Invalid(f"{path}: {error}") from error


def integer(value, name, minimum=0):
    if isinstance(value, bool) or not isinstance(value, int) or value < minimum:
        raise Invalid(f"{name} must be an integer >= {minimum}")
    return value


def sha(value, name):
    if not isinstance(value, str) or len(value) != 64 or any(c not in "0123456789abcdef" for c in value):
        raise Invalid(name + " must be a lowercase SHA-256")
    return value


def load_campaign(directory, max_records=100000):
    root = Path(directory).resolve()
    manifest_path = root / "manifest.json"
    manifest = read_json(manifest_path)
    if manifest.get("schemaVersion") != SCHEMA:
        raise Invalid("unsupported campaign manifest schemaVersion")
    for field in ("setupId", "styleId"):
        if not isinstance(manifest.get(field), str) or not manifest[field]:
            raise Invalid("manifest requires " + field)
    for field in IDENTITIES:
        sha(manifest.get(field), field)
    if not isinstance(manifest.get("setup"), dict) or not manifest["setup"]:
        raise Invalid("manifest requires the complete canonical setup object, not only setupId")
    for field in ("setupHash", "runnerHash", "gameContextHash"):
        if manifest.get(field) is not None:
            sha(manifest[field], field)
    integer(manifest.get("partySize"), "partySize", 1)
    integer(manifest.get("requestedTicks"), "requestedTicks", 1)
    seeds = manifest.get("seeds")
    if not isinstance(seeds, list) or not seeds:
        raise Invalid("manifest requires explicit nonempty seeds[]")
    for seed in seeds:
        integer(seed, "seed")
        if seed > 4294967295:
            raise Invalid("seed exceeds U32")
    if len(set(seeds)) != len(seeds):
        raise Invalid("duplicate seeds in manifest")
    paths = manifest.get("records")
    if not isinstance(paths, list) or not paths or not all(isinstance(p, str) for p in paths):
        raise Invalid("manifest requires records[] of relative JSONL paths")
    runs = {seed: {"seed": seed, "samples": [], "summary": None, "decisions": [], "issues": []} for seed in seeds}
    count = 0
    receipt_hashes = {}
    for relative in paths:
        path = (root / relative).resolve()
        if not path.is_relative_to(root):
            raise Invalid("record path escapes campaign directory")
        if relative in receipt_hashes:
            raise Invalid("duplicate record path")
        try:
            handle = path.open("rb")
        except OSError as error:
            raise Invalid(f"cannot read receipt {path}: {error}") from error
        receipt_digest = hashlib.sha256()
        for line_number, line in enumerate(bounded_lines(handle, receipt_digest), 1):
            if not line.strip():
                continue
            count += 1
            if count > max_records or len(line) > 1024 * 1024:
                raise Invalid("receipt resource limit exceeded")
            try:
                row = json.loads(line, parse_constant=lambda value: (_ for _ in ()).throw(Invalid("non-finite JSON")))
            except (ValueError, UnicodeError) as error:
                raise Invalid(f"{path}:{line_number}: invalid JSON") from error
            if not isinstance(row, dict) or row.get("type") not in ("sample", "summary", "decision"):
                raise Invalid(f"{path}:{line_number}: unsupported record type")
            seed = integer(row.get("seed"), "record seed")
            if seed not in runs:
                raise Invalid("receipt seed not declared in manifest")
            for field in ("setupId", "styleId", "partySize"):
                if field in row and row[field] != manifest[field]:
                    raise Invalid("record/manifest identity differs: " + field)
            run = runs[seed]
            row = dict(row, evidence={"file": relative, "line": line_number})
            integer(row.get("tick"), "record tick")
            if row["tick"] > manifest["requestedTicks"]:
                raise Invalid("record exceeds declared horizon")
            if row["type"] == "decision":
                run["decisions"].append(row)
                continue
            integer(row.get("phase"), "phase")
            for field in SAMPLE_FIELDS:
                if field in row and row[field] is not None:
                    integer(row[field], field)
            if row["type"] == "sample":
                if run["summary"] is not None:
                    raise Invalid("sample after summary")
                if run["samples"] and row["tick"] <= run["samples"][-1]["tick"]:
                    raise Invalid("sample ticks must strictly increase")
                run["samples"].append(row)
            else:
                if run["summary"] is not None:
                    raise Invalid("duplicate summary for seed")
                if run["samples"] and row["tick"] < run["samples"][-1]["tick"]:
                    raise Invalid("summary precedes last sample")
                run["summary"] = row
        receipt_hashes[relative] = receipt_digest.hexdigest()
    for run in runs.values():
        run["outcome"] = classify(run["summary"], manifest["requestedTicks"])
        if run["summary"] is None:
            run["issues"].append("No terminal summary: infrastructure/incomplete execution, not a gameplay death.")
        run["population"] = population_observation(run["samples"])
    return {"directory": str(root), "manifest": manifest, "manifestSha256": digest_bytes(manifest_path.read_bytes()), "receiptSha256": receipt_hashes, "runs": runs}


def bounded_lines(handle, digest):
    with handle:
        while True:
            line = handle.readline(1024 * 1024 + 1)
            if not line:
                return
            if len(line) > 1024 * 1024:
                raise Invalid("receipt line resource limit exceeded")
            digest.update(line)
            yield line


def classify(summary, horizon):
    if summary is None:
        return "infrastructure"
    declared = summary.get("outcome")
    phase, tick = summary["phase"], summary["tick"]
    if declared in ("aborted", "infrastructure", "error", "timeout", "interrupted"):
        return "infrastructure"
    expected = "defeat" if phase == 3 else "victory" if phase == 4 else "horizon" if phase < 3 and tick == horizon else None
    if expected is None or declared != expected:
        raise Invalid(f"outcome {declared!r} contradicts phase={phase}, tick={tick}, horizon={horizon}")
    return expected


def population_observation(samples):
    valid = [row for row in samples if isinstance(row.get("population"), int) and not isinstance(row["population"], bool) and row["population"] >= 0]
    if len(valid) != len(samples) or len(valid) < 2:
        return {"available": False, "sampleCount": len(valid), "reason": "Need at least two consecutive population samples; missing fields are not zero."}
    duration = valid[-1]["tick"] - valid[0]["tick"]
    integral = sum(a["population"] * (b["tick"] - a["tick"]) for a, b in zip(valid, valid[1:]))
    return {"available": True, "sampleCount": len(valid), "startTick": valid[0]["tick"], "endTick": valid[-1]["tick"], "observedTicks": duration, "populationTickIntegral": integral, "timeWeightedPopulation": integral / duration, "maxSampledPopulation": max(row["population"] for row in valid), "integration": "left sample held until next sample; no extension before/after observed interval"}


def common_population(left, right):
    if not population_observation(left)["available"] or not population_observation(right)["available"]:
        return {"available": False, "reason": "Both arms need complete population samples covering an interval."}
    start, end = max(left[0]["tick"], right[0]["tick"]), min(left[-1]["tick"], right[-1]["tick"])
    if end <= start:
        return {"available": False, "reason": "No common observed population interval."}
    boundaries = sorted({start, end, *[r["tick"] for r in left if start < r["tick"] < end], *[r["tick"] for r in right if start < r["tick"] < end]})
    def integral(rows):
        index, total = 0, 0
        for a, b in zip(boundaries, boundaries[1:]):
            while index + 1 < len(rows) and rows[index + 1]["tick"] <= a:
                index += 1
            total += rows[index]["population"] * (b - a)
        return total
    baseline, candidate = integral(left), integral(right)
    return {"available": True, "startTick": start, "endTick": end, "observedTicks": end - start, "baselinePopulationTickIntegral": baseline, "candidatePopulationTickIntegral": candidate, "baselineTimeWeightedPopulation": baseline / (end - start), "candidateTimeWeightedPopulation": candidate / (end - start), "timeWeightedPopulationDelta": (candidate - baseline) / (end - start), "integration": "piecewise constant observed samples on exactly the common coverage; no fill after the last observed sample"}


def key(campaign, seed):
    m = campaign["manifest"]
    return (seed, m["setupId"], m["styleId"], m["partySize"])


def compare(baseline, candidate, criteria, criteria_hash, allow_unbound=False):
    if criteria.get("schemaVersion") != SCHEMA or criteria.get("axis") not in ("game", "bot"):
        raise Invalid("criteria require schemaVersion=1 and axis=game|bot")
    axis = criteria["axis"]
    b, c = baseline["manifest"], candidate["manifest"]
    if "baselineExtraPercent" in criteria and b.get("extraPercent") != criteria["baselineExtraPercent"]:
        raise Invalid("baseline extraPercent contradicts declared baseline arm")
    for manifest in (b, c):
        verify_setup_catalog(criteria, manifest)
    if canonical(b["setup"]) != canonical(c["setup"]):
        raise Invalid("full canonical setup differs despite pair labels")
    for field in ("setupHash", "runnerHash"):
        if (b.get(field) or c.get(field)) and b.get(field) != c.get(field):
            raise Invalid("comparison changed frozen " + field)
    if b["requestedTicks"] != c["requestedTicks"]:
        raise Invalid("different requested horizons cannot be paired")
    if {key(baseline, seed) for seed in baseline["runs"]} != {key(candidate, seed) for seed in candidate["runs"]}:
        raise Invalid("campaigns do not contain the same explicit seed/setup/style/party pairs")
    frozen_axis = "policyHash" if axis == "game" else "gameHash"
    if b[frozen_axis] != c[frozen_axis]:
        raise Invalid(f"{axis} comparison changed frozen {frozen_axis}")
    if axis == "game" and (b.get("gameContextHash") or c.get("gameContextHash")):
        if b.get("gameContextHash") != c.get("gameContextHash"):
            raise Invalid("game context outside declared tuning inputs changed")
    bound = all(m.get("criteriaSha256") == criteria_hash for m in (b, c))
    if not bound and not allow_unbound:
        raise Invalid("criteria hash is not bound by both campaign manifests; use --allow-unbound-criteria only for diagnostic pilots")
    milestones = criteria.get("milestoneTicks", [])
    if not isinstance(milestones, list) or any(isinstance(t, bool) or not isinstance(t, int) or not 0 <= t <= 4294967295 for t in milestones):
        raise Invalid("invalid milestoneTicks")
    pairs, curves = [], {}
    for seed in sorted(baseline["runs"]):
        br, cr = baseline["runs"][seed], candidate["runs"][seed]
        bs, cs = br["summary"], cr["summary"]
        by_tick = {r["tick"]: r for r in br["samples"]}
        candidate_ticks = {r["tick"]: r for r in cr["samples"]}
        common = sorted(by_tick.keys() & candidate_ticks.keys())
        observations = []
        for tick in common:
            left, right = by_tick[tick], candidate_ticks[tick]
            fields = {name: {"baseline": left[name], "candidate": right[name], "delta": right[name] - left[name]} for name in SAMPLE_FIELDS if isinstance(left.get(name), int) and isinstance(right.get(name), int)}
            observations.append({"tick": tick, "values": fields})
            for field, values in fields.items():
                bucket = curves.setdefault((tick, field), [])
                bucket.append(values)
        pairs.append({"identity": dict(zip(PAIR_FIELDS, key(baseline, seed))), "baselineOutcome": br["outcome"], "candidateOutcome": cr["outcome"], "baselineTerminalTick": bs["tick"] if bs else None, "candidateTerminalTick": cs["tick"] if cs else None, "baselineSummaryEvidence": bs["evidence"] if bs else None, "candidateSummaryEvidence": cs["evidence"] if cs else None, "baselinePopulation": br["population"], "candidatePopulation": cr["population"], "commonPrefixPopulation": common_population(br["samples"], cr["samples"]), "commonSampleTicks": common, "observations": observations, "retrospective": retrospective(br, cr)})
    outcome_counts = lambda campaign: {name: sum(r["outcome"] == name for r in campaign["runs"].values()) for name in ("defeat", "victory", "horizon", "infrastructure")}
    time_curves = [{"tick": tick, "field": field, "pairedObservedRuns": len(values), "baselineMean": statistics.mean(v["baseline"] for v in values), "candidateMean": statistics.mean(v["candidate"] for v in values), "pairedMeanDelta": statistics.mean(v["delta"] for v in values)} for (tick, field), values in sorted(curves.items())]
    infrastructure = sum(r["outcome"] == "infrastructure" for campaign in (baseline, candidate) for r in campaign["runs"].values())
    campaign_complete = all(m.get("status") == "completed" for m in (b, c))
    return {"schemaVersion": SCHEMA, "status": "inconclusive" if infrastructure or not campaign_complete else "diagnostic-only" if not bound else "observations-complete", "axis": axis, "criteriaSha256": criteria_hash, "criteriaBoundToCampaigns": bound, "criteria": criteria, "analyzerSha256": digest_bytes(Path(__file__).read_bytes()), "pairCount": len(pairs), "baseline": provenance(baseline), "candidate": provenance(candidate), "outcomes": {"baseline": outcome_counts(baseline), "candidate": outcome_counts(candidate)}, "milestones": [{"tick": tick, "baseline": milestone(baseline, tick), "candidate": milestone(candidate, tick)} for tick in milestones], "pairedTimeCurves": time_curves, "pairs": pairs, "limits": ["No automatic balance winner or enjoyment score is inferred.", "Criteria hash binding checks the received manifests; the runner must freeze and record it before execution.", "No inferential confidence interval is computed; retain seed-level pairs and do not claim statistical significance from means.", "HP is net health, not received damage; kills are not DPS; XP is current level progress, not cumulative collected XP.", "Time curves include only paired observed samples, with the denominator shown; they do not replace survival counts.", "Population integrals from unequal run durations are not directly comparable as full-horizon pressure; use the explicitly paired common-prefix value.", "First observed level 2 is an observation bound, not an exact upgrade timestamp; event telemetry is needed for exact timing.", "Cohort ledger records declared exposure; it cannot detect manual inspection or undeclared runs."] + ([] if b.get("gameContextHash") and c.get("gameContextHash") else ["No gameContextHash: the report does not establish that the declared tuning input was the only game change."])}


def provenance(campaign):
    return {"directory": campaign["directory"], "manifestSha256": campaign["manifestSha256"], "receiptSha256": campaign["receiptSha256"], "identities": {k: campaign["manifest"].get(k) for k in (*IDENTITIES, "gameContextHash", "campaignId", "setupId", "styleId", "partySize", "requestedTicks", "extraPercent", "status", "exitCode", "setup", "setupHash", "runnerHash")}}


def milestone(campaign, tick):
    reached = lost = unknown = 0
    for run in campaign["runs"].values():
        summary = run["summary"]
        if run["outcome"] == "infrastructure":
            unknown += 1
        elif summary["tick"] >= tick:
            # A defeat at the milestone is not alive at that milestone.
            if run["outcome"] == "defeat" and summary["tick"] == tick:
                lost += 1
            else:
                reached += 1
        elif run["outcome"] == "defeat":
            lost += 1
        else:
            unknown += 1
    progress = {"yes": 0, "no": 0, "unknown": 0}
    for run in campaign["runs"].values():
        rows = [*run["samples"], *([run["summary"]] if run["summary"] else [])]
        if run["outcome"] == "infrastructure":
            progress["unknown"] += 1
        elif any(r["tick"] <= tick and isinstance(r.get("level"), int) and r["level"] >= 2 for r in rows):
            progress["yes"] += 1
        elif any(r["tick"] >= tick and isinstance(r.get("level"), int) and r["level"] < 2 for r in rows) or (run["outcome"] in ("defeat", "victory") and run["summary"]["tick"] < tick and isinstance(run["summary"].get("level"), int) and run["summary"]["level"] < 2):
            progress["no"] += 1
        else:
            progress["unknown"] += 1
    strict_defeats = sum(run["outcome"] == "defeat" and run["summary"]["tick"] < tick for run in campaign["runs"].values())
    return {"aliveOrReachedEndpoint": reached, "defeatedByMilestone": lost, "defeatedStrictlyBeforeTick": strict_defeats, "unknownOrCensoredBefore": unknown, "level2ObservedByTick": progress, "totalRuns": len(campaign["runs"])}


def verify_setup_catalog(criteria, manifest):
    catalog = criteria.get("setups")
    if catalog is None:
        return False
    if not isinstance(catalog, list) or not catalog:
        raise Invalid("criteria setups must be a nonempty array")
    for expected in catalog:
        if not isinstance(expected, dict):
            raise Invalid("invalid criteria setup entry")
        actual = {**manifest["setup"], **{name: manifest[name] for name in ("setupId", "styleId", "partySize")}}
        if all(name in actual and actual[name] == value for name, value in expected.items()):
            return True
    raise Invalid("campaign does not match a full predeclared setup/style/party catalog entry")


def declared_cohort(criteria, campaigns, cohort):
    """Bind methodological labels to the predeclared finite seed/config panel."""
    declared = criteria.get("cohorts")
    if declared is None:
        if cohort == "final":
            raise Invalid("independent final evaluation requires a declared final cohort in criteria")
        return {"verified": False, "scope": "undeclared", "reason": "Criteria do not declare cohorts; only paired observations are checked."}
    if not isinstance(declared, list):
        raise Invalid("criteria cohorts must be an array")
    manifests = [campaign["manifest"] for campaign in campaigns]
    catalog_verified = all(verify_setup_catalog(criteria, m) for m in manifests)
    if cohort in ("validation", "final") and "preferredExtraPercent" in criteria and manifests[1].get("extraPercent") != criteria["preferredExtraPercent"]:
        raise Invalid("candidate extraPercent contradicts the predeclared confirmation candidate")
    pilot = criteria.get("pilot")
    if cohort == "development" and isinstance(pilot, dict) and all(set(m["seeds"]) == {pilot.get("seed")} and m["requestedTicks"] == pilot.get("requestedTicks") and m.get("extraPercent") in pilot.get("extraPercents", []) and ("profile" not in pilot or m["setup"].get("profile") == pilot["profile"]) for m in manifests):
        return {"verified": True, "setupCatalogVerified": catalog_verified, "scope": "pilot", "reason": "Predeclared cost/integration pilot, not balance qualification."}
    for entry in declared:
        if not isinstance(entry, dict) or entry.get("kind") != cohort:
            continue
        allowed_seeds = entry.get("seeds")
        if not isinstance(allowed_seeds, list) or not allowed_seeds:
            raise Invalid("declared cohort requires explicit seeds")
        for seed in allowed_seeds:
            integer(seed, "declared cohort seed")
            if seed > 4294967295:
                raise Invalid("declared cohort seed exceeds U32")
        extras = entry.get("extraPercents", criteria.get("developmentExtraPercents") if cohort == "development" else None)
        if all(set(m["seeds"]).issubset(allowed_seeds) and m["requestedTicks"] == entry.get("requestedTicks") and (extras is None or m.get("extraPercent") in extras) and ("profiles" not in entry or m["setup"].get("profile") in entry["profiles"]) for m in manifests):
            return {"verified": True, "setupCatalogVerified": catalog_verified, "scope": cohort, "cohortId": entry.get("id"), "seedCountInThisComparison": len(manifests[0]["seeds"]), "declaredSeedCount": len(allowed_seeds), "entireDeclaredCohortIncluded": set(manifests[0]["seeds"]) == set(allowed_seeds)}
    raise Invalid("campaign seeds, horizon, extraPercent or profile do not match declared " + cohort + " cohort")


def retrospective(baseline_run, candidate_run):
    notes = []
    for arm, run in (("baseline", baseline_run), ("candidate", candidate_run)):
        summary = run["summary"]
        if run["outcome"] == "defeat":
            notes.append({"arm": arm, "observation": "Defeat recorded", "tick": summary["tick"], "evidence": summary["evidence"], "nextQuestion": "Inspect preceding targets, routes and actual legal alternatives before attributing cause."})
        if summary and isinstance(summary.get("uncollectedBaseXp"), int) and summary["uncollectedBaseXp"] > 0:
            notes.append({"arm": arm, "observation": "Uncollected XP remains", "value": summary["uncollectedBaseXp"], "evidence": summary["evidence"], "nextQuestion": "This does not establish neglect: inspect reachability and route risk."})
        if not run["decisions"]:
            notes.append({"arm": arm, "missingTelemetry": "No decision/goal/alternative records; cannot explain which policy choice caused this outcome."})
        if not run["population"]["available"]:
            notes.append({"arm": arm, "missingTelemetry": run["population"]["reason"]})
    return notes


@contextmanager
def ledger_lock(path):
    import fcntl  # Supported analysis hosts: Linux and macOS.
    path.parent.mkdir(parents=True, exist_ok=True)
    with (path.parent / (path.name + ".lock")).open("a") as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        yield


def register_usage(path, usage):
    """One global seed ledger across bot/game axes; repeated report is idempotent."""
    with ledger_lock(path):
        ledger = read_json(path) if path.exists() else {"schemaVersion": SCHEMA, "uses": []}
        if ledger.get("schemaVersion") != SCHEMA or not isinstance(ledger.get("uses"), list):
            raise Invalid("unsupported exposure ledger")
        for entry in [*ledger["uses"], usage]:
            if not isinstance(entry, dict) or entry.get("axis") not in ("game", "bot") or entry.get("cohort") not in ("development", "validation", "final") or entry.get("purpose") not in ("tune", "evaluate"):
                raise Invalid("invalid ledger usage metadata")
            if not isinstance(entry.get("seeds"), list) or not entry["seeds"]:
                raise Invalid("ledger usage requires nonempty seeds")
            for seed in entry["seeds"]:
                integer(seed, "ledger seed")
                if seed > 4294967295:
                    raise Invalid("ledger seed exceeds U32")
        usage = dict(usage)
        usage["seeds"] = sorted(set(usage["seeds"]))
        usage["id"] = digest_bytes(canonical(usage).encode())
        if any(previous.get("id") == usage["id"] for previous in ledger["uses"]):
            return {"registered": False, "idempotent": True, "usageId": usage["id"]}
        if usage["cohort"] == "final" and usage["purpose"] == "evaluate":
            incompatible = []
            for previous in ledger["uses"]:
                if not (set(usage["seeds"]) & set(previous["seeds"])):
                    continue
                same_frozen_group = (usage.get("evaluationGroup") is not None and previous.get("evaluationGroup") == usage["evaluationGroup"] and previous["cohort"] == "final" and previous["purpose"] == "evaluate")
                different_declared_scope = (usage.get("scope") is not None and previous.get("scope") is not None and usage["scope"] != previous["scope"])
                if not (same_frozen_group and different_declared_scope):
                    incompatible.extend(set(usage["seeds"]) & set(previous["seeds"]))
            if incompatible:
                raise Invalid("final cohort already exposed across game/bot axes: " + ",".join(map(str, sorted(set(incompatible)))))
        ledger["uses"].append(usage)
        descriptor, temporary = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
        try:
            with os.fdopen(descriptor, "w") as handle:
                handle.write(json.dumps(ledger, indent=2) + "\n")
            os.replace(temporary, path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
        return {"registered": True, "idempotent": False, "usageId": usage["id"]}


def markdown(report):
    lines = ["# Balance comparison observations", "", f"Status: **{report['status']}**; axis: `{report['axis']}`; paired runs: {report['pairCount']}.", "", "No automatic winner is selected. Full evidence and time curves are in `report.json`.", "", "| Outcome | Baseline | Candidate |", "| --- | ---: | ---: |"]
    for outcome in ("defeat", "victory", "horizon", "infrastructure"):
        lines.append(f"| {outcome} | {report['outcomes']['baseline'][outcome]} | {report['outcomes']['candidate'][outcome]} |")
    lines += ["", "## Retrospective", ""]
    for pair in report["pairs"]:
        lines.append(f"### Seed {pair['identity']['seed']}")
        lines.append("")
        for note in pair["retrospective"]:
            lines.append("- " + canonical(note))
        lines.append("")
    lines += ["## Limits", ""] + ["- " + limitation for limitation in report["limits"]]
    return "\n".join(lines) + "\n"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    comp = commands.add_parser("compare")
    for name in ("baseline", "candidate", "criteria", "output"):
        comp.add_argument("--" + name, type=Path, required=True)
    comp.add_argument("--allow-unbound-criteria", action="store_true", help="Diagnostic pilot only; never claims criteria were fixed before execution")
    comp.add_argument("--max-records", type=int, default=100000)
    mark = commands.add_parser("mark", help="Register manual inspection or other seed exposure")
    mark.add_argument("--seeds", required=True, help="Comma-separated U32 seeds")
    mark.add_argument("--axis", choices=("game", "bot"), required=True)
    mark.add_argument("--note", required=True)
    for target in (comp, mark):
        target.add_argument("--ledger", type=Path, required=target is mark)
        target.add_argument("--cohort", choices=("development", "validation", "final"), default="development")
        target.add_argument("--purpose", choices=("tune", "evaluate"), default="tune")
    args = parser.parse_args(argv)
    try:
        if args.command == "mark":
            seeds = [int(x) for x in args.seeds.split(",")]
            if not seeds or any(not 0 <= seed <= 4294967295 for seed in seeds):
                raise Invalid("invalid U32 seed list")
            print(json.dumps(register_usage(args.ledger, {"seeds": seeds, "axis": args.axis, "cohort": args.cohort, "purpose": args.purpose, "note": args.note})))
            return 0
        if args.max_records < 1:
            raise Invalid("max-records must be positive")
        if args.cohort == "final" and not args.ledger:
            raise Invalid("final evaluation requires a global exposure ledger")
        criteria_bytes = args.criteria.read_bytes()
        criteria_hash = digest_bytes(criteria_bytes)
        baseline, candidate, criteria = load_campaign(args.baseline, args.max_records), load_campaign(args.candidate, args.max_records), read_json(args.criteria)
        report = compare(baseline, candidate, criteria, criteria_hash, args.allow_unbound_criteria)
        report["declaredCohort"] = declared_cohort(criteria, [baseline, candidate], args.cohort)
        if report["declaredCohort"]["scope"] == "pilot" and report["status"] == "observations-complete":
            report["status"] = "diagnostic-only"
        if args.cohort == "final" and (args.purpose != "evaluate" or report["status"] != "observations-complete"):
            raise Invalid("independent final evaluation requires complete, criteria-bound observations and purpose=evaluate")
        if args.ledger:
            group = {"axis": report["axis"], "criteria": criteria_hash, **{arm: {name: report[arm]["identities"][name] for name in IDENTITIES} for arm in ("baseline", "candidate")}}
            scope = {name: report["baseline"]["identities"][name] for name in ("setupId", "styleId", "partySize", "requestedTicks")}
            report["exposureLedger"] = register_usage(args.ledger, {"seeds": [p["identity"]["seed"] for p in report["pairs"]], "axis": report["axis"], "cohort": args.cohort, "purpose": args.purpose, "comparison": digest_bytes(canonical({k: report[k] for k in ("criteriaSha256", "baseline", "candidate")}).encode()), "evaluationGroup": digest_bytes(canonical(group).encode()), "scope": digest_bytes(canonical(scope).encode())})
        elif args.cohort == "final":
            raise Invalid("final evaluation requires a global exposure ledger")
        args.output.mkdir(parents=True, exist_ok=True)
        (args.output / "report.json").write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")
        (args.output / "report.md").write_text(markdown(report))
        print(json.dumps({"status": report["status"], "pairedRuns": report["pairCount"], "output": str(args.output)}))
        return 0 if report["status"] != "inconclusive" else 2
    except (Invalid, OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
