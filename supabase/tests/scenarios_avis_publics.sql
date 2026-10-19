-- AVIS-PUBLICS (19/10/2026) : liens de collecte et avis publies. Migration 20261019120000.
--   1. droits : anon n'a que les trois portes publiques ; aucune lecture directe des tables ;
--   2. non-direction : ne cree, ne liste, ne ferme, ne modere rien (42501) ;
--   3. la direction cree un lien et recoit un jeton (base64url, 32 caracteres), la base n'en garde
--      que l'empreinte sha256 ;
--   4. anon : etat du lien (seulement {ouvert}) et depot valide ;
--   5. chaque champ invalide leve 22023 avec le nom du champ ; accord refuse ;
--   6. lien ferme, expire, plein ou inconnu : P0002, et rien n'est ecrit ;
--   7. moderation : transitions permises, motif obligatoire pour refuse et retire ;
--   8. avis_publics : publies seulement, liste blanche de cles, moyenne en dixiemes, plus recents d'abord.
-- Tout est annule a la fin.
\o /dev/null
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('a1500000-0000-0000-0000-000000000001', 'avis-admin@example.test'),
  ('a1500000-0000-0000-0000-000000000002', 'avis-teacher@example.test');
INSERT INTO public.households (id, timezone) VALUES
  ('a15fffff-ffff-ffff-ffff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('a1500000-0000-0000-0000-000000000001', 'ADM-AVIS-000001', 'admin',
   'a15fffff-ffff-ffff-ffff-000000000001', 'Admin', 'Fixture', 'active', 'female'),
  ('a1500000-0000-0000-0000-000000000002', 'TCH-AVIS-000001', 'teacher',
   'a15fffff-ffff-ffff-ffff-000000000001', 'Teacher', 'Fixture', 'provisional_active', 'male');

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
END $$;

-- Execute une instruction et exige l'erreur (sqlstate, et message si fourni).
CREATE FUNCTION pg_temp.refuse(p_sql text, p_etat text, p_msg text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_etat text; v_message text;
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_etat = RETURNED_SQLSTATE, v_message = MESSAGE_TEXT;
    IF v_etat IS DISTINCT FROM p_etat OR (p_msg IS NOT NULL AND v_message IS DISTINCT FROM p_msg) THEN
      RAISE EXCEPTION 'ROUGE : % (attendu % / %, recu % / %)', p_label, p_etat, p_msg, v_etat, v_message;
    END IF;
    RETURN;
  END;
  RAISE EXCEPTION 'ROUGE : % (aucune erreur)', p_label;
END $$;

-- Depot valide de reference ; chaque cas invalide en change un seul argument.
CREATE FUNCTION pg_temp.depot(p_jeton text,
  p_nom text DEFAULT 'Amina B.', p_qualite text DEFAULT 'parent', p_pays text DEFAULT 'fr',
  p_depuis date DEFAULT DATE '2024-09-15', p_note integer DEFAULT 5, p_titre text DEFAULT 'Tres bien',
  p_texte text DEFAULT 'Des cours clairs et une enseignante patiente avec les enfants.',
  p_accord boolean DEFAULT true) RETURNS text
LANGUAGE sql AS $$
  SELECT pg_catalog.format('SELECT public.avis_deposer(%L, %L, %L, %L, %L::date, %s, %L, %L, %L)',
    p_jeton, p_nom, p_qualite, p_pays, p_depuis, coalesce(p_note::text, 'NULL'), p_titre, p_texte, p_accord);
$$;

-- ------------------------------------------------------------------
-- 1. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  has_function_privilege('anon', 'public.avis_lien_etat(text)', 'EXECUTE')
  AND has_function_privilege('anon', 'public.avis_deposer(text,text,text,text,date,integer,text,text,boolean)', 'EXECUTE')
  AND has_function_privilege('anon', 'public.avis_publics()', 'EXECUTE'),
  'droits : anon a les trois portes publiques');
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.avis_lien_creer(text,integer,integer)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.avis_liens_lister()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.avis_lien_fermer(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.avis_lister_admin(text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.avis_moderer(uuid,text,text)', 'EXECUTE'),
  'droits : anon n''a aucune porte de la direction');
SELECT pg_temp.vrai(
  NOT has_function_privilege('service_role', 'public.avis_publics()', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.avis_publics()', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.avis_deposer(text,text,text,text,date,integer,text,text,boolean)', 'EXECUTE'),
  'droits : ni service_role ni agent_ro');
SELECT pg_temp.vrai(
  (SELECT bool_and(prosecdef AND proconfig = ARRAY['search_path=""'])
     FROM pg_proc WHERE pronamespace = 'public'::regnamespace AND proname LIKE 'avis\_%'),
  'fonctions : toutes DEFINER avec search_path vide');
SELECT pg_temp.vrai(
  (SELECT bool_and(relrowsecurity) FROM pg_class WHERE oid IN ('public.avis'::regclass, 'public.avis_liens'::regclass))
  AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename IN ('avis', 'avis_liens')),
  'tables : RLS active, aucune politique');

-- ------------------------------------------------------------------
-- 2. Non-direction : anon, enseignant, sans jeton
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'a1500000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims',
  '{"sub":"a1500000-0000-0000-0000-000000000002","role":"authenticated","app_metadata":{"role":"teacher"}}', true);
SELECT pg_temp.refuse($q$SELECT public.avis_lien_creer('Intrus')$q$, '42501', NULL, 'enseignant : creer un lien');
SELECT pg_temp.refuse($q$SELECT public.avis_liens_lister()$q$, '42501', NULL, 'enseignant : lister les liens');
SELECT pg_temp.refuse($q$SELECT public.avis_lien_fermer(gen_random_uuid())$q$, '42501', NULL, 'enseignant : fermer un lien');
SELECT pg_temp.refuse($q$SELECT public.avis_lister_admin()$q$, '42501', NULL, 'enseignant : lister les avis');
SELECT pg_temp.refuse($q$SELECT public.avis_moderer(gen_random_uuid(), 'publie')$q$, '42501', NULL, 'enseignant : moderer');

-- Connecte sans role applicatif (NULL ne doit pas passer la porte).
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT set_config('request.jwt.claims', '{"role":"authenticated"}', true);
SELECT pg_temp.refuse($q$SELECT public.avis_lien_creer('Intrus')$q$, '42501', NULL, 'sans role : creer un lien');
RESET ROLE;

-- anon
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT set_config('request.jwt.claims', '{"role":"anon"}', true);
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.refuse($q$SELECT public.avis_lien_creer('Intrus')$q$, '42501', NULL, 'anon : creer un lien (execute refuse ou porte)');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. La direction cree un lien
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'a1500000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims',
  '{"sub":"a1500000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal2","app_metadata":{"role":"admin"}}', true);

SELECT pg_temp.refuse($q$SELECT public.avis_lien_creer('   ')$q$, '22023', 'libelle', 'libelle vide');
SELECT pg_temp.refuse($q$SELECT public.avis_lien_creer(repeat('x', 81))$q$, '22023', 'libelle', 'libelle trop long');
SELECT pg_temp.refuse($q$SELECT public.avis_lien_creer('Ok', 0)$q$, '22023', 'jours', 'jours 0');
SELECT pg_temp.refuse($q$SELECT public.avis_lien_creer('Ok', 366)$q$, '22023', 'jours', 'jours 366');
SELECT pg_temp.refuse($q$SELECT public.avis_lien_creer('Ok', 90, 0)$q$, '22023', 'avis_max', 'avis_max 0');
SELECT pg_temp.refuse($q$SELECT public.avis_lien_creer('Ok', 90, 2001)$q$, '22023', 'avis_max', 'avis_max 2001');

CREATE TEMP TABLE avis_t (cle text PRIMARY KEY, j jsonb);
GRANT ALL ON avis_t TO anon, authenticated;
INSERT INTO avis_t SELECT 'lien1', public.avis_lien_creer('Familles octobre 2026');
INSERT INTO avis_t SELECT 'lien_plein', public.avis_lien_creer('Plein', 30, 1);
INSERT INTO avis_t SELECT 'lien_ferme', public.avis_lien_creer('A fermer', 30, 10);
RESET ROLE;

SELECT pg_temp.vrai((SELECT j ?& ARRAY['id', 'jeton', 'expire_le'] AND (SELECT count(*) FROM jsonb_object_keys(j)) = 3
                        FROM avis_t WHERE cle = 'lien1'), 'creation : id, jeton, expire_le');
SELECT pg_temp.vrai((SELECT j ->> 'jeton' ~ '^[A-Za-z0-9_-]{32}$' FROM avis_t WHERE cle = 'lien1'),
  'jeton : 24 octets en base64url sans remplissage (32 caracteres)');
SELECT pg_temp.vrai((SELECT (j ->> 'expire_le')::timestamptz BETWEEN now() + interval '89 days 23 hours' AND now() + interval '90 days 1 hour'
                        FROM avis_t WHERE cle = 'lien1'), 'creation : 90 jours par defaut');
SELECT pg_temp.vrai((SELECT l.jeton_empreinte = extensions.digest(t.j ->> 'jeton', 'sha256') AND l.avis_max = 200 AND l.avis_recus = 0
                        AND l.cree_par = 'a1500000-0000-0000-0000-000000000001'
                        FROM avis_t t JOIN public.avis_liens l ON l.id = (t.j ->> 'id')::uuid WHERE t.cle = 'lien1'),
  'base : empreinte sha256, 200 par defaut, compteur a 0, auteur');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.avis_liens l, avis_t t
                                 WHERE position(t.j ->> 'jeton' IN l.libelle) > 0
                                    OR encode(l.jeton_empreinte, 'escape') = t.j ->> 'jeton'),
  'base : le jeton en clair n''est stocke nulle part');

SELECT set_config('test.jeton1', (SELECT j ->> 'jeton' FROM avis_t WHERE cle = 'lien1'), true);
SELECT set_config('test.jeton_plein', (SELECT j ->> 'jeton' FROM avis_t WHERE cle = 'lien_plein'), true);
SELECT set_config('test.jeton_ferme', (SELECT j ->> 'jeton' FROM avis_t WHERE cle = 'lien_ferme'), true);

-- Un lien expire et un lien deja plein, montes en base.
INSERT INTO public.avis_liens (libelle, jeton_empreinte, cree_par, cree_le, expire_le, avis_max)
VALUES ('Expire', extensions.digest('jeton-expire-0000000000000000000', 'sha256'),
        'a1500000-0000-0000-0000-000000000001', now() - interval '2 days', now() - interval '1 day', 10);

-- ------------------------------------------------------------------
-- 4. anon : etat du lien et depot valide
-- ------------------------------------------------------------------
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT set_config('request.jwt.claims', '{"role":"anon"}', true);
SELECT pg_temp.vrai(public.avis_lien_etat(current_setting('test.jeton1')) = '{"ouvert": true}'::jsonb,
  'anon : lien ouvert, seule cle {ouvert}');
SELECT pg_temp.vrai(public.avis_lien_etat('inconnu') = '{"ouvert": false}'::jsonb, 'anon : jeton inconnu, ouvert=false');
SELECT pg_temp.vrai(public.avis_lien_etat(NULL) = '{"ouvert": false}'::jsonb, 'anon : jeton NULL, ouvert=false');
SELECT pg_temp.vrai(public.avis_lien_etat('jeton-expire-0000000000000000000') = '{"ouvert": false}'::jsonb, 'anon : lien expire, ouvert=false');
SELECT pg_temp.vrai(public.avis_lien_etat(current_setting('test.jeton_ferme')) = '{"ouvert": true}'::jsonb, 'anon : lien a fermer encore ouvert');

SELECT public.avis_deposer(current_setting('test.jeton1'), '  Amina B.  ', 'parent', 'fr', DATE '2024-09-15', 5,
  '   ', E'Des cours clairs\net une enseignante patiente avec les enfants.', true);
SELECT public.avis_deposer(current_setting('test.jeton1'), 'Omar K.', 'eleve_adulte', 'CA', DATE '2023-01-31', 3,
  'Correct', 'Le contenu est bon, mais les horaires sont parfois difficiles a tenir.', true);
SELECT public.avis_deposer(current_setting('test.jeton1'), 'Yasmine', 'parent', 'BE', DATE '2015-01-01', 4,
  NULL, 'Ma fille progresse chaque semaine, merci a toute l''equipe pour la patience.', true);
RESET ROLE;

SELECT pg_temp.vrai((SELECT count(*) FROM public.avis) = 3, 'depot : trois avis ecrits');
SELECT pg_temp.vrai((SELECT avis_recus FROM public.avis_liens WHERE id = (SELECT (j ->> 'id')::uuid FROM avis_t WHERE cle = 'lien1')) = 3,
  'depot : compteur du lien incremente');
SELECT pg_temp.vrai((SELECT nom_affiche = 'Amina B.' AND pays = 'FR' AND depuis = DATE '2024-09-01' AND titre IS NULL
                        AND statut = 'en_attente' AND publie_le IS NULL AND modere_le IS NULL AND motif IS NULL
                        AND accord_public_le IS NOT NULL AND texte LIKE E'%\n%'
                        FROM public.avis WHERE nom_affiche = 'Amina B.'),
  'depot : nom rogne, pays en majuscules, depuis au 1er du mois, titre vide = NULL, en attente, saut de ligne garde');
SELECT pg_temp.vrai((SELECT depuis = DATE '2023-01-01' FROM public.avis WHERE nom_affiche = 'Omar K.'), 'depot : depuis tronque au mois');

-- ------------------------------------------------------------------
-- 5. Chaque champ invalide : 22023, message = nom du champ
-- ------------------------------------------------------------------
SET LOCAL ROLE anon;
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_nom => 'A'), '22023', 'nom', 'nom : 1 caractere');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_nom => '   '), '22023', 'nom', 'nom : blanc');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_nom => repeat('x', 61)), '22023', 'nom', 'nom : 61 caracteres');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_nom => NULL), '22023', 'nom', 'nom : NULL');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_qualite => 'enseignant'), '22023', 'qualite', 'qualite : valeur inconnue');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_qualite => NULL), '22023', 'qualite', 'qualite : NULL');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_pays => 'FRA'), '22023', 'pays', 'pays : 3 lettres');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_pays => 'F1'), '22023', 'pays', 'pays : chiffre');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_pays => NULL), '22023', 'pays', 'pays : NULL');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_depuis => DATE '2014-12-31'), '22023', 'depuis', 'depuis : avant 2015');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_depuis => (date_trunc('month', now()) + interval '1 month')::date),
  '22023', 'depuis', 'depuis : mois prochain');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_depuis => NULL), '22023', 'depuis', 'depuis : NULL');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_note => 0), '22023', 'note', 'note : 0');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_note => 6), '22023', 'note', 'note : 6');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_note => NULL), '22023', 'note', 'note : NULL');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_titre => repeat('t', 81)), '22023', 'titre', 'titre : 81 caracteres');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_texte => 'trop court'), '22023', 'texte', 'texte : trop court');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_texte => repeat('a', 1501)), '22023', 'texte', 'texte : 1501 caracteres');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_texte => NULL), '22023', 'texte', 'texte : NULL');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_texte => 'Un texte assez long' || chr(7) || ' avec un caractere de controle.'),
  '22023', 'texte', 'texte : caractere de controle');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_texte => 'Un texte assez long' || chr(9) || ' avec une tabulation.'),
  '22023', 'texte', 'texte : tabulation refusee');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_accord => false), '22023', 'accord', 'accord : false');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton1'), p_accord => NULL), '22023', 'accord', 'accord : NULL');
-- Bornes acceptees.
SELECT public.avis_deposer(current_setting('test.jeton1'), 'Ab', 'parent', 'us', DATE '2026-10-31', 1, repeat('t', 80), repeat('a', 20), true);
SELECT public.avis_deposer(current_setting('test.jeton1'), repeat('n', 60), 'parent', 'US', date_trunc('month', now())::date, 2, NULL, repeat('a', 1500), true);
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.avis) = 5, 'champs : aucun depot invalide n''a ete ecrit, deux bornes acceptees');
SELECT pg_temp.vrai((SELECT avis_recus FROM public.avis_liens WHERE id = (SELECT (j ->> 'id')::uuid FROM avis_t WHERE cle = 'lien1')) = 5,
  'champs : le compteur ne bouge pas sur un refus');

-- ------------------------------------------------------------------
-- 6. Lien ferme, expire, plein ou inconnu : P0002
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'a1500000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims',
  '{"sub":"a1500000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal2","app_metadata":{"role":"admin"}}', true);
SELECT public.avis_lien_fermer((SELECT (j ->> 'id')::uuid FROM avis_t WHERE cle = 'lien_ferme'));
SELECT public.avis_lien_fermer((SELECT (j ->> 'id')::uuid FROM avis_t WHERE cle = 'lien_ferme'));  -- idempotent
SELECT pg_temp.refuse($q$SELECT public.avis_lien_fermer(gen_random_uuid())$q$, 'P0002', NULL, 'fermer : lien inconnu');
RESET ROLE;

SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims', '{"role":"anon"}', true);
SELECT pg_temp.vrai(public.avis_lien_etat(current_setting('test.jeton_ferme')) = '{"ouvert": false}'::jsonb, 'anon : lien ferme, ouvert=false');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton_ferme')), 'P0002', NULL, 'depot : lien ferme');
SELECT pg_temp.refuse(pg_temp.depot('jeton-expire-0000000000000000000'), 'P0002', NULL, 'depot : lien expire');
SELECT pg_temp.refuse(pg_temp.depot('jeton-qui-n-existe-pas'), 'P0002', NULL, 'depot : jeton inconnu');
SELECT pg_temp.refuse(pg_temp.depot(NULL), 'P0002', NULL, 'depot : jeton NULL');
SELECT pg_temp.refuse(pg_temp.depot(repeat('z', 500)), 'P0002', NULL, 'depot : jeton demesure');
-- Lien plein (avis_max = 1) : le premier passe, le second est refuse.
SELECT pg_temp.vrai(public.avis_lien_etat(current_setting('test.jeton_plein')) = '{"ouvert": true}'::jsonb, 'anon : lien a 1 place ouvert');
SELECT public.avis_deposer(current_setting('test.jeton_plein'), 'Seule place', 'parent', 'FR', DATE '2025-01-10', 5, NULL,
  'Le premier avis occupe la seule place de ce lien.', true);
SELECT pg_temp.vrai(public.avis_lien_etat(current_setting('test.jeton_plein')) = '{"ouvert": false}'::jsonb, 'anon : lien plein, ouvert=false');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton_plein')), 'P0002', NULL, 'depot : lien plein');
-- Les messages ne distinguent pas les cas (aucun oracle).
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton_plein')), 'P0002', 'lien indisponible', 'meme message : plein');
SELECT pg_temp.refuse(pg_temp.depot('inconnu'), 'P0002', 'lien indisponible', 'meme message : inconnu');
SELECT pg_temp.refuse(pg_temp.depot(current_setting('test.jeton_ferme')), 'P0002', 'lien indisponible', 'meme message : ferme');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.avis) = 6, 'liens indisponibles : un seul depot de plus (la place libre)');

-- ------------------------------------------------------------------
-- anon ne lit rien directement
-- ------------------------------------------------------------------
SET LOCAL ROLE anon;
SELECT pg_temp.refuse('SELECT * FROM public.avis', '42501', NULL, 'anon : lecture directe de avis');
SELECT pg_temp.refuse('SELECT * FROM public.avis_liens', '42501', NULL, 'anon : lecture directe de avis_liens');
SELECT pg_temp.refuse('INSERT INTO public.avis (lien_id, nom_affiche, qualite, pays, depuis, note, texte, accord_public_le) SELECT gen_random_uuid(), ''xx'', ''parent'', ''FR'', DATE ''2024-01-01'', 5, repeat(''a'', 30), now()',
  '42501', NULL, 'anon : ecriture directe');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"a1500000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal2","app_metadata":{"role":"admin"}}', true);
SELECT pg_temp.refuse('SELECT * FROM public.avis', '42501', NULL, 'authenticated, meme direction : lecture directe de avis');
SELECT pg_temp.refuse('UPDATE public.avis SET statut = ''publie''', '42501', NULL, 'authenticated : ecriture directe');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2 bis / 7. Direction : liste, moderation
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'a1500000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims',
  '{"sub":"a1500000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal2","app_metadata":{"role":"admin"}}', true);

SELECT pg_temp.vrai(jsonb_array_length(public.avis_liens_lister()) = 4, 'liste des liens : 4 (3 crees, 1 expire)');
SELECT pg_temp.vrai((SELECT bool_and(e ?& ARRAY['id', 'libelle', 'cree_le', 'expire_le', 'avis_max', 'avis_recus', 'ferme', 'actif'])
                       FROM jsonb_array_elements(public.avis_liens_lister()) e), 'liste des liens : cles du contrat');
SELECT pg_temp.vrai((SELECT (e ->> 'actif')::boolean FROM jsonb_array_elements(public.avis_liens_lister()) e WHERE e ->> 'libelle' = 'Familles octobre 2026'),
  'lien courant actif');
SELECT pg_temp.vrai((SELECT NOT (e ->> 'actif')::boolean AND (e ->> 'ferme')::boolean
                       FROM jsonb_array_elements(public.avis_liens_lister()) e WHERE e ->> 'libelle' = 'A fermer'), 'lien ferme : ferme et inactif');
SELECT pg_temp.vrai((SELECT NOT (e ->> 'actif')::boolean AND NOT (e ->> 'ferme')::boolean
                       FROM jsonb_array_elements(public.avis_liens_lister()) e WHERE e ->> 'libelle' = 'Plein'), 'lien plein : inactif sans etre ferme');
SELECT pg_temp.vrai((SELECT NOT (e ->> 'actif')::boolean FROM jsonb_array_elements(public.avis_liens_lister()) e WHERE e ->> 'libelle' = 'Expire'),
  'lien expire : inactif');
SELECT pg_temp.vrai(NOT (public.avis_liens_lister()::text ~ 'jeton'), 'liste des liens : aucun jeton ni empreinte');

SELECT pg_temp.vrai(jsonb_array_length(public.avis_lister_admin()) = 6, 'liste admin : 6 avis');
SELECT pg_temp.vrai(jsonb_array_length(public.avis_lister_admin('en_attente')) = 6, 'liste admin : 6 en attente');
SELECT pg_temp.vrai(jsonb_array_length(public.avis_lister_admin('publie')) = 0, 'liste admin : 0 publie');
SELECT pg_temp.refuse($q$SELECT public.avis_lister_admin('n_importe_quoi')$q$, '22023', 'statut', 'liste admin : statut inconnu');
SELECT pg_temp.vrai((SELECT e ->> 'lien_libelle' = 'Plein' FROM jsonb_array_elements(public.avis_lister_admin()) e WHERE e ->> 'nom_affiche' = 'Seule place'),
  'liste admin : libelle du lien');

CREATE TEMP TABLE avis_ids AS
  SELECT (e ->> 'id')::uuid AS id, e ->> 'nom_affiche' AS nom FROM jsonb_array_elements(public.avis_lister_admin()) e;
GRANT ALL ON avis_ids TO authenticated;

-- Validation des arguments.
SELECT pg_temp.refuse($q$SELECT public.avis_moderer(gen_random_uuid(), 'en_attente')$q$, '22023', 'statut', 'moderer : statut en_attente interdit');
SELECT pg_temp.refuse($q$SELECT public.avis_moderer(gen_random_uuid(), NULL)$q$, '22023', 'statut', 'moderer : statut NULL');
SELECT pg_temp.refuse($q$SELECT public.avis_moderer(gen_random_uuid(), 'publie')$q$, 'P0002', NULL, 'moderer : avis inconnu');
-- Motif obligatoire pour refuse et retire, 3 a 300.
SELECT pg_temp.refuse(format($q$SELECT public.avis_moderer(%L, 'refuse')$q$, (SELECT id FROM avis_ids WHERE nom = 'Omar K.')),
  '22023', 'motif', 'refuser sans motif');
SELECT pg_temp.refuse(format($q$SELECT public.avis_moderer(%L, 'refuse', 'ab')$q$, (SELECT id FROM avis_ids WHERE nom = 'Omar K.')),
  '22023', 'motif', 'refuser : motif de 2 caracteres');
SELECT pg_temp.refuse(format($q$SELECT public.avis_moderer(%L, 'refuse', repeat('m', 301))$q$, (SELECT id FROM avis_ids WHERE nom = 'Omar K.')),
  '22023', 'motif', 'refuser : motif de 301 caracteres');
-- Retire depuis en_attente : interdit.
SELECT pg_temp.refuse(format($q$SELECT public.avis_moderer(%L, 'retire', 'demande de la famille')$q$, (SELECT id FROM avis_ids WHERE nom = 'Omar K.')),
  '22023', 'statut', 'retirer un avis en attente');

-- Publier (motif ignore), refuser.
SELECT public.avis_moderer((SELECT id FROM avis_ids WHERE nom = 'Amina B.'), 'publie');
SELECT public.avis_moderer((SELECT id FROM avis_ids WHERE nom = 'Yasmine'), 'publie', 'motif ignore a la publication');
SELECT public.avis_moderer((SELECT id FROM avis_ids WHERE nom = 'Omar K.'), 'publie');
SELECT public.avis_moderer((SELECT id FROM avis_ids WHERE nom = 'Seule place'), 'refuse', '  doublon  ');
-- Depuis un etat final ou non permis.
SELECT pg_temp.refuse(format($q$SELECT public.avis_moderer(%L, 'publie')$q$, (SELECT id FROM avis_ids WHERE nom = 'Seule place')),
  '22023', 'statut', 'publier un avis refuse');
SELECT pg_temp.refuse(format($q$SELECT public.avis_moderer(%L, 'refuse', 'doublon')$q$, (SELECT id FROM avis_ids WHERE nom = 'Amina B.')),
  '22023', 'statut', 'refuser un avis publie');
SELECT pg_temp.refuse(format($q$SELECT public.avis_moderer(%L, 'publie')$q$, (SELECT id FROM avis_ids WHERE nom = 'Amina B.')),
  '22023', 'statut', 'publier deux fois');
SELECT pg_temp.refuse(format($q$SELECT public.avis_moderer(%L, 'retire')$q$, (SELECT id FROM avis_ids WHERE nom = 'Amina B.')),
  '22023', 'motif', 'retirer sans motif');
RESET ROLE;

SELECT pg_temp.vrai((SELECT a.statut = 'publie' AND a.publie_le IS NOT NULL AND a.modere_le IS NOT NULL AND a.motif IS NULL
                        AND a.modere_par = 'a1500000-0000-0000-0000-000000000001'
                        FROM public.avis a WHERE a.nom_affiche = 'Yasmine'), 'publie : dates, auteur, pas de motif');
SELECT pg_temp.vrai((SELECT a.statut = 'refuse' AND a.publie_le IS NULL AND a.modere_le IS NOT NULL AND a.motif = 'doublon'
                        FROM public.avis a WHERE a.nom_affiche = 'Seule place'), 'refuse : motif rogne, jamais publie');

-- Ordre de publication connu : Amina la plus ancienne, puis Yasmine, puis Omar.
UPDATE public.avis SET publie_le = now() - interval '3 days' WHERE nom_affiche = 'Amina B.';
UPDATE public.avis SET publie_le = now() - interval '2 days' WHERE nom_affiche = 'Yasmine';
UPDATE public.avis SET publie_le = now() - interval '1 day'  WHERE nom_affiche = 'Omar K.';

-- ------------------------------------------------------------------
-- 8. avis_publics : publies seulement
-- ------------------------------------------------------------------
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims', '{"role":"anon"}', true);
CREATE TEMP TABLE avis_pub AS SELECT public.avis_publics() AS j;
GRANT ALL ON avis_pub TO anon;
RESET ROLE;

SELECT pg_temp.vrai((SELECT (j ->> 'nombre')::int = 3 FROM avis_pub), 'publics : 3 avis publies (le refuse et les attentes exclus)');
-- notes publiees : 5, 3, 4 => moyenne 4.0 => 40 dixiemes
SELECT pg_temp.vrai((SELECT (j ->> 'moyenne_dixiemes')::int = 40 FROM avis_pub), 'publics : moyenne 4,0 = 40 dixiemes');
SELECT pg_temp.vrai((SELECT array_agg(e ->> 'nom' ORDER BY ord) = ARRAY['Omar K.', 'Yasmine', 'Amina B.']
                        FROM avis_pub, jsonb_array_elements(j -> 'avis') WITH ORDINALITY AS t(e, ord)),
  'publics : les plus recents d''abord');
SELECT pg_temp.vrai((SELECT bool_and((SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(e) k)
                                      = ARRAY['depuis', 'nom', 'note', 'pays', 'publie_le', 'qualite', 'texte', 'titre'])
                        FROM avis_pub, jsonb_array_elements(j -> 'avis') e),
  'publics : liste blanche de cles par avis');
SELECT pg_temp.vrai((SELECT (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(j) k) = ARRAY['avis', 'moyenne_dixiemes', 'nombre'] FROM avis_pub),
  'publics : cles de premier niveau');
SELECT pg_temp.vrai((SELECT j::text !~ '(lien|motif|modere|statut|accord|jeton|empreinte|"id")' FROM avis_pub),
  'publics : ni identifiant, ni lien, ni motif, ni moderateur');
SELECT pg_temp.vrai((SELECT e ->> 'depuis' = '2015-01-01' AND e ->> 'pays' = 'BE' AND e ->> 'titre' IS NULL
                        FROM avis_pub, jsonb_array_elements(j -> 'avis') e WHERE e ->> 'nom' = 'Yasmine'),
  'publics : valeurs rendues (depuis au premier du mois, pays, titre NULL)');

-- Retirer : l'avis disparait du public.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'a1500000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims',
  '{"sub":"a1500000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal2","app_metadata":{"role":"admin"}}', true);
SELECT public.avis_moderer((SELECT id FROM avis_ids WHERE nom = 'Omar K.'), 'retire', 'A la demande de la personne');
SELECT pg_temp.refuse(format($q$SELECT public.avis_moderer(%L, 'publie')$q$, (SELECT id FROM avis_ids WHERE nom = 'Omar K.')),
  '22023', 'statut', 'republier un avis retire');
SELECT pg_temp.vrai(jsonb_array_length(public.avis_lister_admin('retire')) = 1, 'liste admin : 1 retire');
RESET ROLE;
SELECT pg_temp.vrai((SELECT a.statut = 'retire' AND a.motif = 'A la demande de la personne' AND a.publie_le IS NOT NULL
                        FROM public.avis a WHERE a.nom_affiche = 'Omar K.'), 'retire : motif garde, date de publication conservee');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"role":"authenticated"}', true);
SELECT pg_temp.vrai((public.avis_publics() ->> 'nombre')::int = 2 AND (public.avis_publics() ->> 'moyenne_dixiemes')::int = 45,
  'publics : apres retrait, 2 avis et moyenne 4,5 = 45 dixiemes (authenticated aussi)');
RESET ROLE;

-- Plafond de 200 : 205 avis publies, 200 rendus, le compte reste complet.
INSERT INTO public.avis (lien_id, nom_affiche, qualite, pays, depuis, note, texte, accord_public_le, statut, publie_le)
SELECT (SELECT id FROM public.avis_liens LIMIT 1), 'Bulk ' || g, 'parent', 'FR', DATE '2025-01-01', 5,
       'Un avis de volume pour le plafond de deux cents.', now(), 'publie', now() + g * interval '1 minute'
  FROM generate_series(1, 205) g;
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims', '{"role":"anon"}', true);
SELECT pg_temp.vrai(jsonb_array_length(public.avis_publics() -> 'avis') = 200
                    AND (public.avis_publics() ->> 'nombre')::int = 207
                    AND public.avis_publics() #>> '{avis,0,nom}' = 'Bulk 205',
  'publics : 200 au plus, nombre sur l''ensemble, le plus recent en tete');
RESET ROLE;

ROLLBACK;
\o
\echo 'AVIS-PUBLICS : scenarios VERTS'
