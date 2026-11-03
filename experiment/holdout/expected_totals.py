"""Independent expected totals: plain csv module, no pandas, no project code."""
import csv, json, sys
seen, totals = set(), {}
for row in csv.DictReader(open(sys.argv[1])):
    if row["event_id"] in seen:
        continue
    seen.add(row["event_id"])
    day = row["occurred_at"][:10]
    totals[day] = totals.get(day, 0) + int(row["amount_cents"])
print(json.dumps(dict(sorted(totals.items()))))
