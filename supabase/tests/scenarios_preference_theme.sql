-- PREFERENCES-PAR-COMPTE (11/11/2026) : le theme porte par le compte
-- (migration 20261123200000). Sa propre ligne : oui ; une autre : non ; anon
-- refuse ; valeur inconnue refusee (22023).
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
    'app_metadata', pg_catalog.json_build_object())::text, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'PREFERENCE-THEME ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('a7e00000-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Lire ou ecrire en tant que [p_id] ; rend le code d'erreur, ou 'ok'.
CREATE FUNCTION pg_temp.regler(p_id uuid, p_theme text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.qui(p_id);
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM public.ma_preference_theme_regler(p_theme);
  EXECUTE 'RESET ROLE';
  RETURN 'ok';
EXCEPTION WHEN OTHERS THEN
  EXECUTE 'RESET ROLE';
  RETURN SQLSTATE;
END $$;

CREATE FUNCTION pg_temp.lire(p_id uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  PERFORM pg_temp.qui(p_id);
  EXECUTE 'SET LOCAL ROLE authenticated';
  v := public.ma_preference_theme();
  EXECUTE 'RESET ROLE';
  RETURN v;
EXCEPTION WHEN OTHERS THEN
  EXECUTE 'RESET ROLE';
  RETURN 'erreur ' || SQLSTATE;
END $$;

SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email, email_confirmed_at) VALUES
  (pg_temp.p('01'), 'theme-01@test.invalid', now()),
  (pg_temp.p('02'), 'theme-02@test.invalid', now());
INSERT INTO public.households (id, timezone, status) VALUES
  (pg_temp.p('90'), 'Europe/Paris', 'active'),
  (pg_temp.p('91'), 'Europe/Paris', 'active');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  (pg_temp.p('01'), 'THM-01', 'guardian', pg_temp.p('90'), 'Compte', 'A', 'active', 'male'),
  (pg_temp.p('02'), 'THM-02', 'guardian', pg_temp.p('91'), 'Compte', 'B', 'active', 'female');
SET LOCAL session_replication_role = origin;

-- 1. Par defaut, « systeme ».
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.p('01')) = 'systeme', 'theme par defaut : systeme');

-- 2. Sa propre ligne : ecrite et relue.
SELECT pg_temp.vrai(pg_temp.regler(pg_temp.p('01'), 'Sombre ') = 'ok', 'A regle son theme');
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.p('01')) = 'sombre', 'A relit sombre');

-- 3. Une autre ligne : jamais touchee. B garde le sien.
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.p('02')) = 'systeme', 'B n est pas touche par A');
SELECT pg_temp.vrai(pg_temp.regler(pg_temp.p('02'), 'clair') = 'ok', 'B regle le sien');
SELECT pg_temp.vrai(
  (SELECT preference_theme FROM public.profiles WHERE id = pg_temp.p('01')) = 'sombre',
  'A garde sombre apres l ecriture de B'
);

-- 4. Valeur inconnue : refusee, rien n'est ecrit.
SELECT pg_temp.vrai(pg_temp.regler(pg_temp.p('01'), 'violet') = '22023', 'valeur inconnue refusee (22023)');
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.p('01')) = 'sombre', 'A garde sombre apres un refus');

-- 5. Sans compte : refuse.
SELECT pg_temp.vrai(pg_temp.regler(NULL, 'clair') = '42501', 'sans compte : ecriture refusee');

-- 5 bis. INCIDENT-CANDIDATS (14/11/2026) : une session sans profil (candidat
-- avant son inscription) lit la valeur par defaut, sans 403 ; sans compte,
-- la lecture reste refusee.
SELECT pg_temp.vrai(pg_temp.lire('00000000-0000-4000-8000-0000000000ff'::uuid) = 'systeme',
  'session sans profil : lecture de la valeur par defaut');
SELECT pg_temp.vrai(pg_temp.lire(NULL) = 'erreur 42501', 'sans compte : lecture refusee');

-- 6. anon : aucun droit d'execution.
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('anon', 'public.ma_preference_theme()'::regprocedure, 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.ma_preference_theme_regler(text)'::regprocedure, 'EXECUTE'),
  'anon refuse en lecture et en ecriture'
);

-- 7. La table n'est pas ecrite directement par la colonne : la contrainte
--    refuse une valeur hors liste.
DO $$
BEGIN
  BEGIN
    UPDATE public.profiles SET preference_theme = 'violet' WHERE id = pg_temp.p('02');
    RAISE EXCEPTION 'PREFERENCE-THEME ROUGE : la contrainte a laisse passer violet';
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'OK contrainte : valeur hors liste refusee';
  END;
END $$;

ROLLBACK;
