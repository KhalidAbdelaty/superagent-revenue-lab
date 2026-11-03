"""Daily revenue report built from payment events."""
import pandas as pd


def load_events(path):
    """Read payment events; amounts are integer cents."""
    return pd.read_csv(path, parse_dates=["occurred_at", "received_at"])


def daily_revenue(events):
    """Return one row per UTC day with total revenue in cents."""
    # The payment webhook may deliver the same event more than once, with a
    # different received_at but the same event_id. One event_id is one payment
    # event, so keep only its first delivery before aggregating.
    events = events.drop_duplicates(subset="event_id", keep="first")
    days = events["occurred_at"].dt.strftime("%Y-%m-%d")
    report = (
        events.assign(day=days)
        .groupby("day", as_index=False)["amount_cents"]
        .sum()
        .rename(columns={"amount_cents": "revenue_cents"})
    )
    return report
