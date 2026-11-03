"""Token usage and cost per DSH session (main session and worker) for the Superagent profile.

Run as the superagent user after the experiment: python3 ~/usage.py
Reads ~/.dsh/sessions/*/*/session.v4.jsonl.zstd (multi-frame zstd, so it shells out to `zstd -dc`)
and sums data.usage on every assistant/message event.
"""
import collections
import glob
import json
import os
import subprocess

# deepseek-flash, USD per 1M tokens: (cache hit, cache miss, output), from api-docs.deepseek.com/quick_start/pricing
RATES = {"off-peak": (0.003, 0.15, 0.60), "peak": (0.006, 0.30, 1.20)}

grand = collections.Counter()
for path in sorted(glob.glob(os.path.expanduser("~/.dsh/sessions/*/*/session.v4.jsonl.zstd"))):
    name = path.split("/")[-2].split("-")[0]
    text = subprocess.run(["zstd", "-dc", path], capture_output=True, text=True, check=True).stdout
    total = collections.Counter()
    for line in text.splitlines():
        event = json.loads(line) if line.strip() else {}
        usage = (event.get("data") or {}).get("usage") if event.get("type") == "assistant/message" else None
        if usage:
            total["steps"] += 1
            total["uncached"] += usage.get("inputTokens", 0)
            total["cached"] += usage.get("cacheReadTokens", 0)
            total["output"] += usage.get("outputTokens", 0)
    if not total:
        continue
    grand.update(total)
    print(name, dict(total))
for label, (hit, miss, out) in RATES.items():
    cost = (grand["cached"] * hit + grand["uncached"] * miss + grand["output"] * out) / 1e6
    print(f"total {label}: ${cost:.4f}")
