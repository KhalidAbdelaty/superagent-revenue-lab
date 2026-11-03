"""Compact evidence view: CI baseline KV, Triggers, Decisions, Tickets (times UTC)."""
import glob, json, sqlite3, sys
db = sqlite3.connect(glob.glob('/home/superagent/.dsh/state/superagent/*.sqlite')[0])
for k, v in db.execute("select key, value from kv where key like 'github-branch-ci%' or key like 'github-cursor%'"):
    print('KV', k, v[:160])
def rows(t):
    try: return [(i, json.loads(v)) for i, v in db.execute(f'select id, value from {t} order by rowid')]
    except Exception as e: return []
for i, d in rows('trigger'):
    print('TRIG', i[:8], d.get('at') or d.get('createdAt'), json.dumps(d.get('text') or d.get('summary') or '')[:110], d.get('threadKey') or d.get('thread'))
for i, d in rows('decision'):
    print('DEC ', i[:8], d.get('at') or d.get('createdAt'), d.get('kind'), json.dumps(d.get('reason'))[:260])
for i, t in rows('ticket'):
    print('TICK', i[:8], t.get('createdAt'), (t.get('title') or '')[:60], 'ended=', json.dumps(t.get('ended')))
    for a in t.get('assignments', []): print('   A', a.get('id', '')[:8], a.get('state'), a.get('startedAt'), a.get('endedAt'))
