"""Holdout suite. Lives outside the agent's machine; run against a checkout of the PR."""
import json
from pathlib import Path

import pandas as pd

from revenue.pipeline import daily_revenue, load_events

HERE = Path(__file__).resolve().parent
EXPECTED = json.loads((HERE / "holdout_expected.json").read_text())


def test_holdout_daily_totals():
    report = daily_revenue(load_events(HERE / "holdout_events.csv"))
    assert dict(zip(report["day"], report["revenue_cents"])) == EXPECTED


def test_triple_replay_counts_once_and_late_replay_stays_on_its_day():
    report = daily_revenue(load_events(HERE / "holdout_events.csv"))
    totals = dict(zip(report["day"], report["revenue_cents"]))
    assert totals["2026-11-01"] == 3000 + 1000 + 1000 + 750 + 4200


def test_identical_looking_events_with_different_ids_both_count():
    # evt_h02 and evt_h03: same order, same time, same amount. Two real charges.
    events = load_events(HERE / "holdout_events.csv")
    two = events[events["event_id"].isin(["evt_h02", "evt_h03"])]
    assert daily_revenue(two)["revenue_cents"].tolist() == [2000]


def test_input_frame_is_not_modified():
    events = load_events(HERE / "holdout_events.csv")
    before = events.copy()
    daily_revenue(events)
    pd.testing.assert_frame_equal(events, before)


def test_output_shape_is_unchanged():
    report = daily_revenue(load_events(HERE / "holdout_events.csv"))
    assert list(report.columns) == ["day", "revenue_cents"]
    assert report["day"].tolist() == sorted(report["day"].tolist())
