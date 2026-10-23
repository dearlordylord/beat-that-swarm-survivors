#!/usr/bin/env python3
"""Check actual native summaries and optional deterministic replay (development only)."""
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("first", type=Path)
parser.add_argument("--replay", type=Path)
parser.add_argument("--count", type=int, default=2)
parser.add_argument("--ticks", type=int, default=1200)
parser.add_argument("--seed", type=int, default=100)
parser.add_argument("--require-choices", action="store_true")
args = parser.parse_args()


def summaries(path):
    rows = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
    rows.sort(key=lambda row: row["index"])
    assert len(rows) == args.count, ("summary count", len(rows), args.count)
    for index, row in enumerate(rows):
        assert row["backend"] == "native" and row["status"] == "completed", row
        assert row["index"] == index and row["seed"] == (args.seed + index) % 2**32, row
        assert row["profile"] == ("fresh" if index % 2 == 0 else "advanced"), row
        assert row["requestedTicks"] == args.ticks, row
        if row["outcome"] == "bounded-observation":
            assert row["tick"] == args.ticks and row["phase"] in (0, 1, 2), row
        else:
            assert row["outcome"] == "terminal" and row["phase"] in (3, 4), row
            assert row["tick"] <= args.ticks, row
        assert isinstance(row["wallMs"], int) and row["wallMs"] >= 0, row
        if args.require_choices:
            assert row["choices"] > 0, ("exercise menu transitions before horizon", row)
    return rows


first = summaries(args.first)
if args.replay:
    replay = summaries(args.replay)
    assert [{k: v for k, v in row.items() if k != "wallMs"} for row in first] == [
        {k: v for k, v in row.items() if k != "wallMs"} for row in replay
    ], "native seeded replay diverged"
print("NATIVE BATCH RESULT PASS" + (" (deterministic replay)" if args.replay else ""))
