# Revenue report lab

A small pandas pipeline that turns payment events into daily revenue. It exists to test how a coding agent reacts to CI failures.

- Pipeline: [revenue/pipeline.py](revenue/pipeline.py)
- Sample events: [data/events.csv](data/events.csv)
- Tests: [tests/test_revenue.py](tests/test_revenue.py)

Amounts are integer cents. Each payment event has a unique `event_id`. One order can have several events.

## Experiment files

This repository is run 1 of a three-run DeepSeek Superagent experiment in observe mode. Runs 2 and 3 used fresh copies of the same baseline: [run 2](https://github.com/KhalidAbdelaty/superagent-revenue-lab-run2) and [run 3](https://github.com/KhalidAbdelaty/superagent-revenue-lab-run3).

- Holdout suite, frozen before the runs and kept off the agent's machine: [experiment/holdout](experiment/holdout)
- Isolated WSL setup and Superagent configuration scripts: [experiment/superagent](experiment/superagent)
- Issue, comment, review, and ruleset texts, plus the scripts that posted them in runs 2 and 3: [experiment/github](experiment/github)
- Timestamped ledgers: [run 1](experiment/run-1-ledger.txt), [run 2](experiment/run-2-ledger.txt), [run 3](experiment/run-3-ledger.txt)

`pytest.ini` limits CI to `tests/`, so the holdout suite only runs when you call it explicitly.
