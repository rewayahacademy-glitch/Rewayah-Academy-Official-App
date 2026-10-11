import json, sys, re, collections
sys.path.insert(0, sys.argv[1])
import verify_allowlist as v
cat = json.load(open(sys.argv[2]))
vol = dict(l.rstrip('\n').split('\t') for l in open(sys.argv[3]))
HELP_ANON = {'public.app_role()','public.app_user_id()','public.app_household_id()','public.app_account_valid()','public.app_config_int(p_key text, p_defaut integer)'}
JUST_ANON = {'public.agent_identite_masquee()','public.agent_pre_request()'}
DML = re.compile(r'\b(insert\s+into|update\s+[a-z_."]+\s+set|delete\s+from|truncate|set_config\s*\(|nextval|log_sensitive_access)', re.I)
def dml(src): return bool(DML.search(re.sub(r'--[^\n]*','',src or '')))
rows=[]; actions=collections.defaultdict(list)
for f in cat['functions']:
    sig=f['signature']; src=f['prosrc']; stable = vol.get(sig) in ('s','i'); writes = dml(src) or not stable
    ex=dict(f['execute']); 
    if ex.get('service_role'): actions['revoke_service_role'].append(sig)
    ex['service_role']=False
    access=None
    if ex.get('anon'):
        if sig in HELP_ANON: access='HELPER_CLAIMS'
        else:
            actions['anon_a_justifier_ou_revoquer'].append(sig); 
            if sig not in JUST_ANON: pass
            ex['anon']=False if sig not in JUST_ANON else True
            if sig in JUST_ANON: access='ANON_A_JUSTIFIER'
    if ex.get('agent_ro'):
        if not writes: access = access or 'AGENT_RO_LECTURE'
        else:
            actions['revoke_agent_ro_ecriture'].append(sig); ex['agent_ro']=False
    if v._has_positive_nullsafe_guard(src): cls='ROLE_POSITIVE_TEMPLATE'
    elif sig in v._PINNED_EXCEPTION_SIGNATURES: cls='PINNED_FUNCTIONDEF_EXCEPTION'
    elif stable and not dml(src): cls='NO_GUARD_HELPER'
    else:
        cls='NO_GUARD_HELPER'; actions['no_guard_non_admis_(volatile_ou_dml)'].append(sig)
    if sig in v._PINNED_EXCEPTION_SIGNATURES: cls='PINNED_FUNCTIONDEF_EXCEPTION'
    acl=[a for a in f['execute_acl'] if a['grantee'] in ('postgres','authenticated') or (a['grantee']=='anon' and ex['anon']) or (a['grantee']=='agent_ro' and ex['agent_ro'])]
    eff=sorted(r for r in f['effective_execute_roles'] if (r not in ('service_role',)) and (r!='anon' or ex['anon']) and (r!='agent_ro' or ex['agent_ro']))
    row={k:f[k] for k in ('signature','schema','owner','language','search_path')}
    row.update(execute=ex, execute_acl=acl, effective_execute_roles=eff, md5_functiondef=f['md5_functiondef'],
               classification=cls, access_class=access, volatilite=vol.get(sig), ecrit_des_donnees=dml(src),
               reviewer='claude-session-lot-BR1 (non auteur) - CLASSIFICATION AUTOMATIQUE', reviewed_at='2026-10-11')
    if cls!='ROLE_POSITIVE_TEMPLATE': row['justification']='helper STABLE sans DML (regle F86-GRANTS ligne 396)' if cls=='NO_GUARD_HELPER' and stable and not dml(src) else 'A JUSTIFIER PAR CODEX'
    rows.append(row)
man={'metadata':{'database':cat['metadata']['database'],'project_ref':cat['metadata']['project_ref'],'approval_state':'CANDIDATE_NOT_APPROVED','function_count':len(rows),'event_trigger_count':0,
 'etat':'ETAT CIBLE apres la migration F86-ACL (service_role revoque partout ; agent_ro lecture seule ; anon = 5 helpers de claims). md5 = ceux du rejeu ACTUEL ; a recalculer apres la migration.',
 'source':'rejeu PG16 de codex/backend-canon-fixes @7e44fece'},'functions':rows,'event_triggers':[]}
json.dump(man,open(sys.argv[4],'w'),ensure_ascii=False,indent=1)
print('classes',collections.Counter(r['classification'] for r in rows)); print('access',collections.Counter(r['access_class'] for r in rows))
for k,l in actions.items(): print(k,len(l))
json.dump({k:l for k,l in actions.items()},open(sys.argv[4]+'.actions.json','w'),ensure_ascii=False,indent=1)
