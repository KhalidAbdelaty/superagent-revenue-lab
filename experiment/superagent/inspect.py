"""Print the Superagent evidence chain from orchestrator.sqlite: CI baseline, Triggers, dispositions, Decisions, Tickets."""
import glob, json, sqlite3, sys
db = sqlite3.connect(glob.glob('/home/superagent/.dsh/state/superagent/*.sqlite')[0])
db.row_factory = sqlite3.Row
def cols(t): return [c[1] for c in db.execute(f'pragma table_info({t})')]
if len(sys.argv) > 1 and sys.argv[1] == 'schema':
    for t in ['trigger', 'disposition', 'thread', 'ticket', 'decision', 'trigger_thread', 'effect', 'outbox']:
        print(t, cols(t))
    sys.exit()
for row in db.execute("select key, value from kv where key like '%branch%' or key like '%ci%'"):
    if 'settings-version' not in row['key']: print('KV', row['key'], row['value'][:300])
lim = int(sys.argv[2]) if len(sys.argv) > 2 else 400
for t in ['trigger', 'disposition', 'decision', 'ticket']:
    order = 'rowid'
    for row in db.execute(f'select * from {t} order by {order}'):
        d = dict(row)
        print(t.upper(), json.dumps(d, default=str)[:lim])
