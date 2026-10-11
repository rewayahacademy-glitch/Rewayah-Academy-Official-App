import json, sys, collections
sys.path.insert(0, sys.argv[1])
import verify_allowlist as v
cat = json.load(open(sys.argv[2]))
out = []
for f in cat['functions']:
    sig = f['signature']
    if sig in v._PINNED_EXCEPTION_SIGNATURES:
        cls = 'PINNED_FUNCTIONDEF_EXCEPTION'
    elif v._has_positive_nullsafe_guard(f['prosrc']):
        cls = 'ROLE_POSITIVE_TEMPLATE'
    else:
        cls = 'NO_GUARD_HELPER'
    row = {k: f[k] for k in ('signature','schema','owner','language','search_path','execute','execute_acl','effective_execute_roles','md5_functiondef')}
    row['classification'] = cls
    row['reviewer'] = 'claude-session-lot-BR1 (non auteur) - CLASSIFICATION AUTOMATIQUE, NON REVUE FONCTION PAR FONCTION'
    row['reviewed_at'] = '2026-10-11'
    if cls != 'ROLE_POSITIVE_TEMPLATE':
        row['justification'] = 'A JUSTIFIER PAR CODEX : aucune garde positive null-safe reconnue en premiere instruction (' + cls + ')'
    out.append(row)
man = {'metadata': {'database': cat['metadata']['database'], 'project_ref': cat['metadata']['project_ref'],
        'approval_state': 'CANDIDATE_NOT_APPROVED', 'function_count': len(out), 'event_trigger_count': 0,
        'source': 'rejeu PG16 local de codex/backend-canon-fixes @7e44fece (0084: bloc m2_scan retire en copie), privileges par defaut Supabase emules',
        'generated': '2026-10-11'},
       'functions': out, 'event_triggers': []}
json.dump(man, open(sys.argv[3], 'w'), ensure_ascii=False, indent=1)
print(collections.Counter(r['classification'] for r in out))
# verification
man2 = dict(man); man2['metadata'] = dict(man['metadata'], approval_state='APPROVED_ALLOWLIST')
try:
    v.verify(man2, cat, cat['metadata']['project_ref'])
    print('VERIFY OK')
except v.GateFailure as e:
    lines = str(e).split('\n')
    print('VERIFY: %d problemes' % len(lines))
    c = collections.Counter(l.split(': ',1)[1][:70] if ': ' in l else l[:70] for l in lines)
    for k, n in c.most_common(12): print(n, k)
    open(sys.argv[3] + '.problemes.txt', 'w').write('\n'.join(lines))
