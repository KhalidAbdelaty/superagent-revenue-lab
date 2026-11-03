"""Per-session turns, durations, tool calls (incl. any Search/Fetch) from DSH session logs."""
import collections, datetime as dt, glob, json, os, subprocess
f = lambda ms: dt.datetime.fromtimestamp(ms / 1000, dt.timezone.utc).strftime('%H:%M:%S')
for path in sorted(glob.glob(os.path.expanduser("~/.dsh/sessions/*/*/session.v4.jsonl.zstd"))):
    name = path.split("/")[-2].split("-")[0]
    ev = [json.loads(l) for l in subprocess.run(["zstd", "-dc", path], capture_output=True, text=True).stdout.splitlines() if l.strip()]
    tools = collections.Counter(); turn = None; out = []
    for e in ev:
        t, d = e.get("type"), e.get("data") or {}
        if t == "tool/call": tools[d.get("name")] += 1
        if t == "turn/start": turn = [e["time"], 0]
        if t == "assistant/message" and d.get("usage") and turn: turn[1] += 1
        if t == "turn/end" and turn: out.append(f"{f(turn[0])}+{(e['time']-turn[0])/1000:.1f}s/{turn[1]}st"); turn = None
    print("==", name, "tool calls", sum(tools.values()), dict(tools))
    print("   turns", " ".join(out))
