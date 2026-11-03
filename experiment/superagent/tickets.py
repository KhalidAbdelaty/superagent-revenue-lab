"""Summarize Tickets, their assignments, inputs, and reports, plus new Triggers/Decisions since a given id list."""
import glob, json, sqlite3, sys
db = sqlite3.connect(glob.glob('/home/superagent/.dsh/state/superagent/*.sqlite')[0])
seen = set(sys.argv[1:])
for (v,) in db.execute('select value from ticket'):
    t = json.loads(v)
    print('TICKET', t['id'][:8], t.get('title', '')[:70], 'stage=', t.get('stage'), 'state=', t.get('state'), 'pr=', t.get('pr') or t.get('prs'))
    for a in t.get('assignments', []): print('  ASSIGN', a.get('id', '')[:8], a.get('state'), a.get('createdAt'), a.get('startedAt'), a.get('endedAt'))
    for i in t.get('inputs', []): print('  INPUT', json.dumps(i)[:220])
    for k in ('reports', 'report', 'lastReport'):
        if k in t: print('  REPORT', json.dumps(t[k])[:400])
    print('  KEYS', sorted(t.keys()))
for tbl in ('trigger', 'decision'):
    for (i, v) in db.execute(f'select id, value from {tbl}'):
        if i[:8] in seen: continue
        d = json.loads(v)
        print(tbl.upper(), i[:8], d.get('at'), d.get('kind', ''), json.dumps(d.get('reason', d.get('text', '')))[:260], 'thread', d.get('threads', d.get('threadKey')))
