-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), comptes de connexion sans mot de passe.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

do $garde$ begin
  if exists (select 1 from auth.users where email like '%@sim.rewayah.invalid') then
    raise exception 'population de test deja presente : appliquer d''abord le nettoyage';
  end if;
end $garde$;

insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token,
  email_change_token_new, email_change, email_change_token_current, phone_change, phone_change_token,
  reauthentication_token, is_sso_user, is_anonymous)
select '00000000-0000-0000-0000-000000000000', (c.prefixe || '00000-0000-4000-8000-' || lpad(c.n::text, 12, '0'))::uuid,
  'authenticated', 'authenticated', c.email, null, now(),
  '{"provider":"email","providers":["email"],"population_test":true}'::jsonb, '{}'::jsonb, now(), now(),
  '', '', '', '', '', '', '', '', false, false
from (
  select 'e51' prefixe, n, 'eleve-' || lpad(n::text, 3, '0') || '@sim.rewayah.invalid' email from generate_series(1, 100) n
  union all
  select 'e52', n, 'enseignant-' || lpad(n::text, 2, '0') || '@sim.rewayah.invalid' from generate_series(1, 10) n
  union all
  select 'e53', n, (array['admin', 'admin', 'accountant', 'controller'])[n] || '-' || lpad(n::text, 2, '0') || '@sim.rewayah.invalid' from generate_series(1, 4) n
) c;
