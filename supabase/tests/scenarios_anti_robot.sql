-- ANTI-ROBOT (03/11/2026), partie serveur. Migration 20261109000000_anti_robot.sql.
--
-- Ce que le scenario prouve :
--   (a) la cle publique Turnstile : vide a l'installation (null pour l'ecran,
--       donc aucun controle cote client), lue par anon et par un compte ;
--       une cle de la bonne forme est gardee (espaces retires), une autre est
--       refusee ; le reglage n'est pas ecrit par anon ;
--   (b) les deux reglages de plafond : entiers de 1 a 1000, sinon refus ;
--   (c) desinscription : un jeton inconnu n'ecrit toujours rien (aucun seau) ;
--       un jeton reconnu passe jusqu'au plafond de l'heure, puis la reponse dit
--       « plafond » et rien n'est ecrit ; l'heure suivante, le compte repart ;
--       le seau ne porte pas l'adresse en clair ;
--   (d) avis : un lien passe jusqu'au plafond de l'heure, puis « lien
--       indisponible » (meme erreur que tout autre echec), aucun avis de plus,
--       le compteur du lien inchange ;
--   (e) droits : plafond_horaire et la validation executables par aucun
--       compte ; turnstile_cle_site STABLE, DEFINER, search_path vide.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations).
-- Tout est annule a la fin. Mots d'effacement : aucun.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ANTI-ROBOT ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Un appel qui doit etre refuse avec ce code.
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text, p_role text DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  BEGIN
    IF p_role IS NOT NULL THEN
      EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_role);
    END IF;
    EXECUTE p_sql;
    v_passe := true;
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
  END;
  EXECUTE 'RESET ROLE';
  IF v_passe THEN
    RAISE EXCEPTION 'ANTI-ROBOT ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'ANTI-ROBOT ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Un appel sous anon, rendu en jsonb.
CREATE FUNCTION pg_temp.anon(p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', '', true);
  PERFORM pg_catalog.set_config('request.jwt.claims', '{"role":"anon"}', true);
  EXECUTE 'SET LOCAL ROLE anon';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text) TO anon, authenticated;

-- ------------------------------------------------------------
-- (a) La cle publique
-- ------------------------------------------------------------
SELECT pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'securite.turnstile_cle_site') = '""'::jsonb
  AND pg_temp.anon($$SELECT to_jsonb(public.turnstile_cle_site())$$) IS NULL,
  'installation : cle vide, l''ecran lit null (aucun controle cote client)');

UPDATE public.app_config SET value = '"  9xCleInventeeDeFormeValide0000  "' WHERE key = 'securite.turnstile_cle_site';
SELECT pg_temp.vrai(pg_temp.anon($$SELECT to_jsonb(public.turnstile_cle_site())$$) = '"9xCleInventeeDeFormeValide0000"'::jsonb,
  'cle inventee de la bonne forme (aucune vraie cle dans le depot) : gardee sans espaces, lue par anon');
SELECT pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'securite.turnstile_cle_site')
                    = '"9xCleInventeeDeFormeValide0000"'::jsonb,
  'le reglage est enregistre sans espaces');

SELECT pg_temp.refus($$UPDATE public.app_config SET value = '"pas une cle"' WHERE key = 'securite.turnstile_cle_site'$$,
  '22023', 'une cle d''une autre forme est refusee');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = '42' WHERE key = 'securite.turnstile_cle_site'$$,
  '22023', 'un nombre a la place de la cle est refuse');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = to_jsonb('0x' || repeat('A', 120)) WHERE key = 'securite.turnstile_cle_site'$$,
  '22023', 'une cle trop longue est refusee');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = '""' WHERE key = 'securite.turnstile_cle_site'$$,
  '42501', 'anon n''ecrit pas le reglage', 'anon');

SELECT set_config('request.jwt.claims', '{"role":"authenticated","sub":"a0b0c0d0-0000-4000-8000-000000000001"}', true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.turnstile_cle_site() = '9xCleInventeeDeFormeValide0000', 'un compte connecte lit aussi la cle publique');
RESET ROLE;

UPDATE public.app_config SET value = '""' WHERE key = 'securite.turnstile_cle_site';
SELECT pg_temp.vrai(public.turnstile_cle_site() IS NULL, 'revenu a vide : null, le controle disparait cote client');

-- ------------------------------------------------------------
-- (b) Les reglages de plafond
-- ------------------------------------------------------------
SELECT pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'securite.desinscription_par_heure') = '10'::jsonb
  AND (SELECT value FROM public.app_config WHERE key = 'securite.avis_par_heure_par_lien') = '30'::jsonb,
  'installation : 10 desinscriptions par adresse et par heure, 30 avis par lien et par heure');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = '0' WHERE key = 'securite.desinscription_par_heure'$$,
  '22023', 'plafond a 0 refuse');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = '1001' WHERE key = 'securite.avis_par_heure_par_lien'$$,
  '22023', 'plafond au-dela de 1000 refuse');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = '"3"' WHERE key = 'securite.avis_par_heure_par_lien'$$,
  '22023', 'plafond en texte refuse');

-- ------------------------------------------------------------
-- (c) La desinscription
-- ------------------------------------------------------------
UPDATE public.app_config SET value = '2' WHERE key = 'securite.desinscription_par_heure';
INSERT INTO public.courriel_jetons_desinscription (empreinte, adresse, categorie)
SELECT extensions.digest('jeton-anti-robot-0000000000000001', 'sha256'), 'robot.essai@example.test', c.code
  FROM public.courriel_categories c ORDER BY c.code LIMIT 1;
SELECT set_config('test.seaux_avant', (SELECT count(*)::text FROM public.rate_limits), true);

SELECT set_config('test.r_inconnu', pg_temp.anon($$SELECT public.courriel_desinscrire('inconnu-inconnu-inconnu-inconnu')$$)::text, true);
SELECT pg_temp.vrai(NOT (current_setting('test.r_inconnu')::jsonb ->> 'ok')::boolean
  AND (SELECT count(*) FROM public.rate_limits)::text = current_setting('test.seaux_avant'),
  'jeton inconnu : ok faux, aucun seau ecrit');
SELECT set_config('test.r_d1', pg_temp.anon($$SELECT public.courriel_desinscrire('jeton-anti-robot-0000000000000001')$$)::text, true);
SELECT set_config('test.r_d2', pg_temp.anon($$SELECT public.courriel_desinscrire('jeton-anti-robot-0000000000000001')$$)::text, true);
SELECT pg_temp.vrai((current_setting('test.r_d1')::jsonb ->> 'ok')::boolean
  AND (current_setting('test.r_d2')::jsonb ->> 'ok')::boolean,
  'jeton reconnu : deux desinscriptions dans l''heure passent (plafond regle a 2)');
SELECT set_config('test.desinscriptions', (SELECT count(*)::text FROM public.courriel_desinscriptions), true);
SELECT set_config('test.r_d3', pg_temp.anon($$SELECT public.courriel_desinscrire('jeton-anti-robot-0000000000000001')$$)::text, true);
SELECT pg_temp.vrai(current_setting('test.r_d3')::jsonb = '{"ok": false, "plafond": true}'::jsonb
  AND (SELECT count(*) FROM public.courriel_desinscriptions)::text = current_setting('test.desinscriptions'),
  'au-dela du plafond : ok faux et plafond vrai, rien n''est ecrit');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.rate_limits r WHERE r.bucket ILIKE '%example.test%')
  AND EXISTS (SELECT 1 FROM public.rate_limits r
               WHERE r.bucket = 'plafond:desinscription:' || md5('robot.essai@example.test') AND r.tokens = 3),
  'le seau porte l''empreinte de l''adresse, jamais l''adresse en clair');
UPDATE public.rate_limits SET updated_at = date_trunc('hour', now()) - interval '1 hour'
 WHERE bucket = 'plafond:desinscription:' || md5('robot.essai@example.test');
SELECT set_config('test.r_heure', pg_temp.anon($$SELECT public.courriel_desinscrire('jeton-anti-robot-0000000000000001')$$)::text, true);
SELECT pg_temp.vrai((current_setting('test.r_heure')::jsonb ->> 'ok')::boolean
  AND (SELECT tokens FROM public.rate_limits
        WHERE bucket = 'plafond:desinscription:' || md5('robot.essai@example.test')) = 1,
  'l''heure suivante : le compte repart a 1, la desinscription passe');

-- ------------------------------------------------------------
-- (d) L'avis
-- ------------------------------------------------------------
UPDATE public.app_config SET value = '2' WHERE key = 'securite.avis_par_heure_par_lien';
INSERT INTO auth.users (id, email) VALUES ('a0b0c0d0-0000-4000-8000-0000000000a1', 'anti-robot-a1@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES ('a0b0c0d0-0000-4000-8000-0000000000a1', 'AR-ADM-0001', 'admin', 'Direction', 'Essai', 'active', 'male');
INSERT INTO public.avis_liens (libelle, jeton_empreinte, cree_par, cree_le, expire_le, avis_max)
VALUES ('Anti-robot', extensions.digest('jeton-avis-anti-robot-000000000001', 'sha256'),
        'a0b0c0d0-0000-4000-8000-0000000000a1', now(), now() + interval '7 days', 100)
RETURNING id \gset lien_
SELECT set_config('test.lien', :'lien_id', true);

CREATE FUNCTION pg_temp.deposer() RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_temp.anon($q$SELECT to_jsonb(public.avis_deposer('jeton-avis-anti-robot-000000000001', 'Maryam',
           'parent', 'FR', date '2025-01-01', 5, NULL,
           'Une academie serieuse, des cours suivis avec soin.', true))$q$);
$$;
SELECT pg_temp.deposer();
SELECT pg_temp.deposer();
SELECT pg_temp.vrai((SELECT count(*) FROM public.avis WHERE lien_id = current_setting('test.lien')::uuid) = 2
  AND (SELECT avis_recus FROM public.avis_liens WHERE id = current_setting('test.lien')::uuid) = 2,
  'deux avis dans l''heure passent (plafond regle a 2)');
SELECT pg_temp.refus($$SELECT pg_temp.deposer()$$, 'P0002',
  'au-dela du plafond de l''heure : « lien indisponible », la meme erreur que tout autre echec');
SELECT pg_temp.vrai((SELECT count(*) FROM public.avis WHERE lien_id = current_setting('test.lien')::uuid) = 2
  AND (SELECT avis_recus FROM public.avis_liens WHERE id = current_setting('test.lien')::uuid) = 2,
  'apres le refus : aucun avis de plus, compteur du lien inchange');

-- ------------------------------------------------------------
-- (e) Droits
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  has_function_privilege('anon', 'public.turnstile_cle_site()', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.turnstile_cle_site()', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.turnstile_cle_site()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.plafond_horaire(text,integer)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.plafond_horaire(text,integer)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.securite_reglages_valider()', 'EXECUTE')
  AND (SELECT provolatile = 's' AND prosecdef AND proconfig @> ARRAY['search_path=""']
         FROM pg_proc WHERE oid = 'public.turnstile_cle_site()'::regprocedure),
  'droits : la cle publique ouverte a anon et aux comptes (STABLE, DEFINER, search_path vide) ; aides internes fermees');

\o
SELECT 'ANTI-ROBOT : tous les controles sont verts' AS verdict;
ROLLBACK;
