#!/bin/bash
# Amorce, dans la base LOCALE seulement, les deux comptes que l'interface ne
# sait pas creer : la direction et un enseignant deja valide. Tous les autres
# comptes passent par l'interface, comme un vrai utilisateur.
# Adresses fictives (example.com), prefixe E2E sur les noms. Pur SQL local :
# aucune cle de service. Idempotent : on peut le relancer.
set -euo pipefail
TRAVAIL="${E2E_TRAVAIL:-/tmp/e2e-pile}"
DB_URL=$(grep '^DB_URL=' "$TRAVAIL/statut.env" | cut -d'"' -f2)
case "$DB_URL" in postgresql://*@127.0.0.1:*) ;; *) echo "refus : base non locale"; exit 1 ;; esac
MDP="${E2E_MOT_DE_PASSE:-E2E-motdepasse-2026}"

creer_utilisateur() { # courriel -> id (auth.users + identite e-mail, confirmee)
  psql "$DB_URL" -v ON_ERROR_STOP=1 -Atq -v courriel="$1" -v mdp="$MDP" <<'SQL'
with existant as (select id from auth.users where email = :'courriel'),
nouveau as (
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change)
  select '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated',
    'authenticated', :'courriel', extensions.crypt(:'mdp', extensions.gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''
  where not exists (select 1 from existant)
  returning id
),
ident as (
  insert into auth.identities (id, user_id, provider_id, identity_data, provider, created_at, updated_at, last_sign_in_at)
  select gen_random_uuid(), n.id, n.id::text,
    jsonb_build_object('sub', n.id::text, 'email', :'courriel', 'email_verified', true),
    'email', now(), now(), now()
  from nouveau n
  returning user_id
)
select id from nouveau union all select id from existant;
SQL
}

ADMIN=$(creer_utilisateur e2e-direction@example.com)
PROF=$(creer_utilisateur e2e-enseignant@example.com)

psql "$DB_URL" -v ON_ERROR_STOP=1 -q <<SQL
insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
values ('$ADMIN', 'E2E-ADMIN-1', 'admin', 'E2E Direction', 'Locale', 'active', 'female')
on conflict (id) do nothing;
insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
values ('$PROF', 'E2E-PROF-1', 'teacher', 'E2E Enseignant', 'Valide', 'provisional_active', 'male')
on conflict (id) do nothing;
insert into public.teacher_profiles (profile_id, country, languages, kyc_status)
values ('$PROF', 'FR', '{fr}', 'approved')
on conflict (profile_id) do update set kyc_status = 'approved';
DO \$\$
DECLARE v_nda text; v_notice text;
BEGIN
  IF (SELECT account_status FROM public.profiles WHERE id = '$PROF') = 'active' THEN RETURN; END IF;
  SELECT version INTO v_nda FROM public.contract_texts WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
  SELECT version INTO v_notice FROM public.contract_required_versions WHERE contract_kind='recording_and_control_notice';
  PERFORM set_config('request.jwt.claim.sub', '$PROF', true);
  PERFORM set_config('request.jwt.claims', '{"sub":"$PROF","role":"authenticated","app_metadata":{"role":"teacher"}}', true);
  PERFORM public.signer_contrat(v_nda, 'E2E Enseignant Valide');
  INSERT INTO public.contract_acceptances(profile_id, contract_kind, version)
  VALUES ('$PROF', 'recording_and_control_notice', v_notice) ON CONFLICT DO NOTHING;
  INSERT INTO public.contract_acceptances(profile_id, contract_kind, version)
  VALUES ('$PROF', 'teacher_conduct_code', public.code_conduite_version_requise()) ON CONFLICT DO NOTHING;
  UPDATE public.profiles SET account_status = 'active' WHERE id = '$PROF';
END
\$\$;
SQL
psql "$DB_URL" -Atc "select role, account_status, first_name from public.profiles where id in ('$ADMIN','$PROF')"
echo "Comptes amorces : e2e-direction@example.com, e2e-enseignant@example.com"
