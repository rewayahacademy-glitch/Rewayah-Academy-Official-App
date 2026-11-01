-- CLASSES-PLAFOND (22/10/2026) : le nombre maximal de Classes par enseignant,
-- reglable par la direction (decision du 22/10, DECISION-CANDIDATURES-2026-10-21
-- section 1 ter : « trois Classes au plus par enseignant pour l'instant, la
-- direction peut changer cela dans les reglages »).
-- Migration 20261022000200_classes_plafond_par_enseignant.sql.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Le
-- scenario pose ses fixtures (aucune donnee personnelle), appelle les vraies
-- RPC sous les vrais roles, et annule tout a la fin.
--   (a) le reglage : present a 3, entier de 1 a 80, journal, droits ;
--   (b) au plafond (creer_groupe) : trois Classes passent, la quatrieme est
--       refusee plafond_classes_atteint, sans classe ni seance en reste ;
--   (c) au plafond (affectation d'une classe en attente, c11bis) ;
--   (d) au-dessus du plafond (donnees anterieures) : la Classe suivante est
--       refusee, les existantes ne bougent pas ;
--   (e) apres un changement du reglage par la direction : monte, baisse,
--       rendu ; le journal garde chaque changement ; la proposition
--       d'enseignants suit ;
--   (f) une Classe close ne compte pas ;
--   (g) un remplacement ponctuel ne compte pas, et n'est pas refuse au plafond ;
--   (h) les refus existants gardent leur message et leur priorite ;
--   (i) personne d'autre que la direction active ne change le reglage ;
--   (j) aucun autre chemin ne donne une Classe a un enseignant ;
--   (k) droits et forme des fonctions.
-- Chaque controle leve 'CLASSES-PLAFOND ROUGE : ...' s'il echoue.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Un appel doit etre refuse avec ce SQLSTATE et un message qui commence ainsi.
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE IS DISTINCT FROM p_code OR SQLERRM NOT LIKE p_message || '%' THEN
      RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : % (%, « % » au lieu de %, « % »)',
        p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Comptes lus hors RLS (le proprietaire du scenario) : les Classes qui comptent
-- (actives, non closes), toutes les classes, toutes les seances, les lignes
-- de journal du reglage.
CREATE FUNCTION pg_temp.nb_classes(p_teacher uuid) RETURNS integer
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT count(*)::integer FROM public.groupes g
   WHERE g.teacher_id = p_teacher AND g.ended_at IS NULL AND g.etat = 'active';
$$;
CREATE FUNCTION pg_temp.nb_groupes() RETURNS bigint
LANGUAGE sql SECURITY DEFINER AS $$ SELECT count(*) FROM public.groupes; $$;
CREATE FUNCTION pg_temp.nb_seances() RETURNS bigint
LANGUAGE sql SECURITY DEFINER AS $$ SELECT count(*) FROM public.sessions; $$;
CREATE FUNCTION pg_temp.reglage() RETURNS jsonb
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT value FROM public.app_config WHERE key = 'enseignant.classes_max';
$$;
CREATE FUNCTION pg_temp.nb_journal() RETURNS bigint
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT count(*) FROM public.app_config_history WHERE key = 'enseignant.classes_max';
$$;

-- La classe d'un enseignant un jour donne (a 10 h), lue hors RLS.
CREATE FUNCTION pg_temp.groupe_de(p_teacher uuid, p_jour integer) RETURNS uuid
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT g.id FROM public.groupes g WHERE g.teacher_id = p_teacher AND g.weekday = p_jour AND g.hour_local = 10;
$$;

-- Creer une classe pour un enseignant : le jour de 1 a 7, a 10 h a Paris.
CREATE FUNCTION pg_temp.creer(p_teacher uuid, p_jour integer, p_heure integer DEFAULT 10) RETURNS uuid
LANGUAGE sql AS $$
  SELECT public.creer_groupe(p_teacher, 'adulte', 'Plafond ' || p_jour || ' h ' || p_heure,
                             p_jour::smallint, p_heure::smallint, 6::smallint, 'Europe/Paris'::text, NULL::smallint);
$$;

-- Une creation refusee plafond_classes_atteint, sans classe ni seance en reste,
-- avec le compte et le maximum dans le DETAIL.
CREATE FUNCTION pg_temp.refus_plafond(p_teacher uuid, p_jour integer, p_actives integer, p_max integer,
                                      p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_g bigint := pg_temp.nb_groupes();
  v_s bigint := pg_temp.nb_seances();
  v_detail text;
BEGIN
  BEGIN
    PERFORM pg_temp.creer(p_teacher, p_jour);
    RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_detail = PG_EXCEPTION_DETAIL;
    IF SQLSTATE IS DISTINCT FROM 'P0001' OR SQLERRM IS DISTINCT FROM 'plafond_classes_atteint'
       OR v_detail IS DISTINCT FROM pg_catalog.format('classes actives : %s ; maximum : %s', p_actives, p_max) THEN
      RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : % (%, « % », « % »)', p_label, SQLSTATE, SQLERRM, v_detail;
    END IF;
  END;
  IF pg_temp.nb_groupes() <> v_g OR pg_temp.nb_seances() <> v_s THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : % (une classe ou une seance est restee)', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

-- ------------------------------------------------------------------
-- Fixtures. Aucune donnee personnelle : des noms de fixture.
--   admin ...01 (direction active) ; ...02 (direction desactivee) ;
--   TA..TI : enseignants, tous aptes (compte, piece approuvee, genre connu,
--   francais, plafond horaire de 40 h) sauf TI (plafond horaire d'une heure).
-- ------------------------------------------------------------------
INSERT INTO auth.users (id, email)
SELECT ('c1a50000-0000-4000-8000-0000000000' || x.k)::uuid, 'plafond-' || x.k || '@example.test'
  FROM (VALUES ('01'), ('02'), ('a1'), ('b1'), ('c1'), ('d1'), ('e1'), ('f1'), ('a2'), ('b2'), ('a3')) x(k);

INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES
  ('c1a50000-0000-4000-8000-000000000001', 'PLAFADMIN0000001', 'admin', 'Fixture', 'Direction', 'active', 'female'),
  ('c1a50000-0000-4000-8000-000000000002', 'PLAFADMIN0000002', 'admin', 'Fixture', 'Desactivee', 'disabled', 'female'),
  ('c1a50000-0000-4000-8000-0000000000a1', 'PLAFTEACHER00A1', 'teacher', 'TA', 'Creation', 'provisional_active', 'female'),
  ('c1a50000-0000-4000-8000-0000000000b1', 'PLAFTEACHER00B1', 'teacher', 'TB', 'Affectation', 'provisional_active', 'male'),
  ('c1a50000-0000-4000-8000-0000000000c1', 'PLAFTEACHER00C1', 'teacher', 'TC', 'AuDessus', 'provisional_active', 'female'),
  ('c1a50000-0000-4000-8000-0000000000d1', 'PLAFTEACHER00D1', 'teacher', 'TD', 'SousLePlafond', 'provisional_active', 'male'),
  ('c1a50000-0000-4000-8000-0000000000e1', 'PLAFTEACHER00E1', 'teacher', 'TE', 'Close', 'provisional_active', 'female'),
  ('c1a50000-0000-4000-8000-0000000000f1', 'PLAFTEACHER00F1', 'teacher', 'TF', 'RemplacantAuPlafond', 'provisional_active', 'male'),
  ('c1a50000-0000-4000-8000-0000000000a2', 'PLAFTEACHER00A2', 'teacher', 'TG', 'RemplacantEnDessous', 'provisional_active', 'male'),
  ('c1a50000-0000-4000-8000-0000000000b2', 'PLAFTEACHER00B2', 'teacher', 'TI', 'PlafondHoraire', 'provisional_active', 'female'),
  ('c1a50000-0000-4000-8000-0000000000a3', 'PLAFTEACHER00A3', 'teacher', 'TH', 'Titulaire', 'provisional_active', 'male');

INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
SELECT p.id, 'FR', ARRAY['francais'], CASE WHEN p.last_name = 'PlafondHoraire' THEN 1 ELSE 40 END,
       'approved', 'Europe/Paris'
  FROM public.profiles p WHERE p.role = 'teacher' AND p.id::text LIKE 'c1a50000-%';

-- Classes deja actives (donnees anterieures au plafond), hors des RPC :
-- TB deux (lundi, mardi), TC quatre (lundi a jeudi), TD une, TE trois, TF
-- trois, TG deux, TH une (celle dont on remplace les seances), TI trois.
INSERT INTO public.groupes (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
SELECT gen_random_uuid(), ('c1a50000-0000-4000-8000-0000000000' || t.k)::uuid, 'active', 'adulte', 6,
       'Fixture ' || t.k || ' jour ' || j, j, 10, 'Europe/Paris'
  FROM (VALUES ('b1', 2), ('c1', 4), ('d1', 1), ('e1', 3), ('f1', 3), ('a2', 2), ('b2', 3)) t(k, n),
       generate_series(1, 4) j
 WHERE j <= t.n;
INSERT INTO public.groupes (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES ('c1a5ffff-0000-4000-8000-0000000000a3', 'c1a50000-0000-4000-8000-0000000000a3', 'active', 'adulte', 6,
        'Fixture TH classe remplacee', 5, 20, 'Europe/Paris');

-- Trois classes en attente d'un enseignant : jeudi, vendredi et samedi a 10 h.
INSERT INTO public.groupes (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES
  ('c1a5ffff-0000-4000-8000-000000000001', NULL, 'en_attente_enseignant', 'adulte', 6, 'Attente jeudi', 4, 10, 'Europe/Paris'),
  ('c1a5ffff-0000-4000-8000-000000000002', NULL, 'en_attente_enseignant', 'adulte', 6, 'Attente vendredi', 5, 10, 'Europe/Paris'),
  ('c1a5ffff-0000-4000-8000-000000000003', NULL, 'en_attente_enseignant', 'adulte', 6, 'Attente samedi', 6, 10, 'Europe/Paris');

-- Disponibilites : la couverture est exigee a l'affectation d'une classe en
-- attente. TB couvre jeudi et vendredi ; TA, TB, TC, TD couvrent samedi. Les
-- classes sont des Classes d'adultes, qui durent 90 minutes : chaque jour
-- demande les heures 10 ET 11 (CLASSES-DUREE, 22/10 ; avant, l'heure 10 seule
-- suffisait, la seance etant comptee 60 minutes).
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
VALUES
  ('c1a50000-0000-4000-8000-0000000000b1', 4, 10, 'Europe/Paris'),
  ('c1a50000-0000-4000-8000-0000000000b1', 4, 11, 'Europe/Paris'),
  ('c1a50000-0000-4000-8000-0000000000b1', 5, 10, 'Europe/Paris'),
  ('c1a50000-0000-4000-8000-0000000000b1', 5, 11, 'Europe/Paris'),
  ('c1a50000-0000-4000-8000-0000000000a1', 6, 10, 'Europe/Paris'),
  ('c1a50000-0000-4000-8000-0000000000a1', 6, 11, 'Europe/Paris'),
  ('c1a50000-0000-4000-8000-0000000000b1', 6, 10, 'Europe/Paris'),
  ('c1a50000-0000-4000-8000-0000000000b1', 6, 11, 'Europe/Paris'),
  ('c1a50000-0000-4000-8000-0000000000c1', 6, 10, 'Europe/Paris'),
  ('c1a50000-0000-4000-8000-0000000000c1', 6, 11, 'Europe/Paris'),
  ('c1a50000-0000-4000-8000-0000000000d1', 6, 10, 'Europe/Paris'),
  ('c1a50000-0000-4000-8000-0000000000d1', 6, 11, 'Europe/Paris');

-- Les propositions d'enseignants relevees a chaque etape (lues sous la direction).
CREATE TEMP TABLE pl_prop (etape text, teacher_id uuid) ON COMMIT DROP;
GRANT ALL ON pl_prop TO authenticated;

-- Deux seances futures de la classe de TH, a remplacer ponctuellement.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT ('c1a5eeee-0000-4000-8000-00000000000' || n)::uuid, 'c1a50000-0000-4000-8000-0000000000a3',
       ((date_trunc('day', clock_timestamp() AT TIME ZONE 'Europe/Paris') + (n + 1) * interval '1 day' + interval '3 hours') AT TIME ZONE 'Europe/Paris'),
       ((date_trunc('day', clock_timestamp() AT TIME ZONE 'Europe/Paris') + (n + 1) * interval '1 day' + interval '4 hours') AT TIME ZONE 'Europe/Paris'),
       'planned', 'standard', 'c1a5ffff-0000-4000-8000-0000000000a3'
  FROM generate_series(1, 2) n;

SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.groupes g WHERE g.teacher_id::text LIKE 'c1a50000-%' AND g.etat = 'active') = 2 + 4 + 1 + 3 + 3 + 2 + 3 + 1
  AND (SELECT count(*) FROM public.groupes WHERE etat = 'en_attente_enseignant' AND id::text LIKE 'c1a5ffff-%') = 3
  AND (SELECT count(*) FROM public.sessions WHERE id::text LIKE 'c1a5eeee-%') = 2,
  'fixtures : 19 classes actives chez 8 enseignants, 3 classes en attente, 2 seances a remplacer');

-- ------------------------------------------------------------------
-- (a) Le reglage : present, a 3, entier, journal vide, droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.reglage() = '3'::jsonb AND jsonb_typeof(pg_temp.reglage()) = 'number'
                    AND app_private.classes_max_par_enseignant() = 3 AND pg_temp.nb_journal() = 0,
  '(a) le reglage enseignant.classes_max vaut 3 (un nombre), le maximum lu vaut 3, aucun changement n''est encore journalise');

-- ------------------------------------------------------------------
-- (b) Au plafond, par creer_groupe : TA a zero Classe
-- ------------------------------------------------------------------
SELECT pg_temp.qui('c1a50000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.creer('c1a50000-0000-4000-8000-0000000000a1', 1);
SELECT pg_temp.creer('c1a50000-0000-4000-8000-0000000000a1', 2);
SELECT pg_temp.creer('c1a50000-0000-4000-8000-0000000000a1', 3);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000a1') = 3
                    AND app_private.classes_actives_enseignant('c1a50000-0000-4000-8000-0000000000a1') = 3,
  '(b) trois Classes de suite passent pour TA (de zero a trois), et le decompte du serveur dit trois');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus_plafond('c1a50000-0000-4000-8000-0000000000a1', 4, 3, 3,
  '(b) la quatrieme Classe de TA est refusee plafond_classes_atteint (P0001, 3 actives, maximum 3), sans classe ni seance en reste');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000a1') = 3,
  '(b) TA garde ses trois Classes');

-- ------------------------------------------------------------------
-- (c) Au plafond, par l'affectation d'une classe en attente (c11bis) : TB a deux
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.affecter_enseignant_classe_c11bis('c1a5ffff-0000-4000-8000-000000000001',
                      'c1a50000-0000-4000-8000-0000000000b1') = 'affecte',
  '(c) TB (deux Classes) recoit la classe du jeudi : c''est sa troisieme, affecte');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000b1') = 3
    AND (SELECT teacher_id = 'c1a50000-0000-4000-8000-0000000000b1' AND etat = 'active'
           FROM public.groupes WHERE id = 'c1a5ffff-0000-4000-8000-000000000001'),
  '(c) la classe du jeudi est a TB, active');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.affecter_enseignant_classe_c11bis('c1a5ffff-0000-4000-8000-000000000002',
                        'c1a50000-0000-4000-8000-0000000000b1')$$,
  'P0001', 'plafond_classes_atteint',
  '(c) la classe du vendredi est refusee a TB (trois Classes) : plafond_classes_atteint, P0001');
RESET ROLE;
SELECT pg_temp.vrai((SELECT teacher_id IS NULL AND etat = 'en_attente_enseignant'
                       FROM public.groupes WHERE id = 'c1a5ffff-0000-4000-8000-000000000002')
    AND NOT EXISTS (SELECT 1 FROM public.sessions WHERE groupe_id = 'c1a5ffff-0000-4000-8000-000000000002')
    AND pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000b1') = 3,
  '(c) le refus ne laisse rien : la classe du vendredi attend toujours, sans enseignant ni seance ; TB garde trois Classes');
-- Revalider la Classe qu'il tient deja ne la compte pas deux fois : la classe
-- du jeudi est a TB, le predicat la reverifie (trois Classes dont celle-la).
SELECT pg_temp.vrai((SELECT true FROM (SELECT public.tc_verifier_affectation_enseignant(
                       'c1a5ffff-0000-4000-8000-000000000001', 'c1a50000-0000-4000-8000-0000000000b1')) x),
  '(c) revalider la Classe du jeudi, deja tenue par TB (3 Classes dont elle), passe : elle n''est pas comptee deux fois');
-- Le meme refus par le predicat, sans passer par la RPC.
SELECT pg_temp.refus($$SELECT public.tc_verifier_affectation_enseignant('c1a5ffff-0000-4000-8000-000000000002',
                        'c1a50000-0000-4000-8000-0000000000b1')$$,
  'P0001', 'plafond_classes_atteint',
  '(c) tc_verifier_affectation_enseignant (deux arguments) refuse TB de la meme facon');
SELECT pg_temp.refus($$SELECT app_private.verifier_affectation_enseignant('c1a5ffff-0000-4000-8000-000000000002',
                        'c1a50000-0000-4000-8000-0000000000b1', false)$$,
  'P0001', 'plafond_classes_atteint',
  '(c) le predicat interne, sans les disponibilites, refuse TB de la meme facon');

-- ------------------------------------------------------------------
-- (d) Au-dessus du plafond : TC a quatre Classes (donnees anterieures)
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000c1') = 4,
  '(d) TC a quatre Classes, au-dessus du maximum de trois');
SELECT pg_temp.qui('c1a50000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus_plafond('c1a50000-0000-4000-8000-0000000000c1', 5, 4, 3,
  '(d) une cinquieme Classe est refusee a TC (4 actives, maximum 3)');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000c1') = 4,
  '(d) les quatre Classes de TC ne bougent pas : le plafond refuse la suivante, il ne retire rien');

-- La proposition d'enseignants pour la classe du samedi : TA, TB et TC sont
-- disponibles le samedi mais au plafond ; seul TD (une Classe) est propose.
SET LOCAL ROLE authenticated;
INSERT INTO pl_prop SELECT 'defaut', teacher_id FROM public.enseignants_pour_classe('c1a5ffff-0000-4000-8000-000000000003');
RESET ROLE;
SELECT pg_temp.vrai((SELECT array_agg(teacher_id::text ORDER BY teacher_id::text) FROM pl_prop WHERE etape = 'defaut')
                    = ARRAY['c1a50000-0000-4000-8000-0000000000d1'],
  '(d) enseignants_pour_classe (samedi) ne propose que TD : TA, TB (trois) et TC (quatre) sont au plafond, donc ecartes');

-- ------------------------------------------------------------------
-- (e) Apres un changement du reglage par la direction
-- ------------------------------------------------------------------
-- Comme l'ecran Reglages : un UPDATE direct de la ligne, updated_by = soi.
SELECT pg_temp.qui('c1a50000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(4), updated_by = auth.uid()
 WHERE key = 'enseignant.classes_max';
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.reglage() = '4'::jsonb AND app_private.classes_max_par_enseignant() = 4
    AND pg_temp.nb_journal() = 1
    AND (SELECT old_value = '3'::jsonb AND new_value = '4'::jsonb
                AND changed_by = 'c1a50000-0000-4000-8000-000000000001'
           FROM public.app_config_history WHERE key = 'enseignant.classes_max'),
  '(e) la direction passe le maximum a 4 : la valeur change, et le journal garde 3 vers 4 avec son auteur');
SET LOCAL ROLE authenticated;
SELECT pg_temp.creer('c1a50000-0000-4000-8000-0000000000a1', 4);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000a1') = 4,
  '(e) maximum 4 : TA (trois Classes) recoit sa quatrieme');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus_plafond('c1a50000-0000-4000-8000-0000000000a1', 5, 4, 4,
  '(e) maximum 4 : une cinquieme Classe est refusee a TA (4 actives, maximum 4)');
SELECT pg_temp.refus_plafond('c1a50000-0000-4000-8000-0000000000c1', 5, 4, 4,
  '(e) maximum 4 : TC (quatre Classes) est toujours au plafond');
INSERT INTO pl_prop SELECT 'quatre', teacher_id FROM public.enseignants_pour_classe('c1a5ffff-0000-4000-8000-000000000003');
RESET ROLE;
SELECT pg_temp.vrai((SELECT array_agg(teacher_id::text ORDER BY teacher_id::text) FROM pl_prop WHERE etape = 'quatre')
                    = ARRAY['c1a50000-0000-4000-8000-0000000000b1', 'c1a50000-0000-4000-8000-0000000000d1'],
  '(e) maximum 4 : la proposition du samedi ajoute TB (trois Classes) ; TA (quatre) et TC (quatre) restent ecartes');

-- Baisse a 2 : TD (une Classe) passe a deux puis est refuse ; TB (trois) aussi.
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(2), updated_by = auth.uid()
 WHERE key = 'enseignant.classes_max';
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.reglage() = '2'::jsonb AND pg_temp.nb_journal() = 2
    AND (SELECT old_value = '4'::jsonb AND new_value = '2'::jsonb
           FROM public.app_config_history WHERE key = 'enseignant.classes_max' ORDER BY id DESC LIMIT 1),
  '(e) la direction baisse le maximum a 2 : le journal garde 4 vers 2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.creer('c1a50000-0000-4000-8000-0000000000d1', 2);
SELECT pg_temp.refus_plafond('c1a50000-0000-4000-8000-0000000000d1', 3, 2, 2,
  '(e) maximum 2 : TD (une Classe) en recoit une deuxieme, puis la troisieme est refusee');
SELECT pg_temp.refus($$SELECT public.affecter_enseignant_classe_c11bis('c1a5ffff-0000-4000-8000-000000000002',
                        'c1a50000-0000-4000-8000-0000000000b1')$$,
  'P0001', 'plafond_classes_atteint',
  '(e) maximum 2 : TB (trois Classes) reste refusee pour la classe du vendredi');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000a1') = 4
    AND pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000b1') = 3
    AND pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000c1') = 4,
  '(e) la baisse ne retire aucune Classe : TA 4, TB 3, TC 4');

-- Retour a 3 : TD (deux Classes) recoit sa troisieme, TB (trois) y reste.
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(3), updated_by = auth.uid()
 WHERE key = 'enseignant.classes_max';
SELECT pg_temp.creer('c1a50000-0000-4000-8000-0000000000d1', 3);
SELECT pg_temp.refus_plafond('c1a50000-0000-4000-8000-0000000000d1', 4, 3, 3,
  '(e) maximum rendu a 3 : TD recoit sa troisieme Classe, la quatrieme est refusee');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.reglage() = '3'::jsonb AND pg_temp.nb_journal() = 3
    AND (SELECT array_agg(old_value::text || '>' || new_value::text ORDER BY id)
           FROM public.app_config_history WHERE key = 'enseignant.classes_max') = ARRAY['3>4', '4>2', '2>3'],
  '(e) le journal du reglage garde les trois changements dans l''ordre : 3>4, 4>2, 2>3');

-- La valeur ecrite est validee : un entier de 1 a 80, jamais autre chose.
SELECT pg_temp.qui('c1a50000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$UPDATE public.app_config SET value = '0'::jsonb WHERE key = 'enseignant.classes_max'$$,
  '22023', 'nombre maximal de Classes par enseignant', '(e) zero Classe : refuse');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = '81'::jsonb WHERE key = 'enseignant.classes_max'$$,
  '22023', 'nombre maximal de Classes par enseignant', '(e) 81 Classes : refuse (80 est le plafond horaire maximal)');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = '-3'::jsonb WHERE key = 'enseignant.classes_max'$$,
  '22023', 'nombre maximal de Classes par enseignant', '(e) un nombre negatif : refuse');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = '2.5'::jsonb WHERE key = 'enseignant.classes_max'$$,
  '22023', 'nombre maximal de Classes par enseignant', '(e) un nombre decimal : refuse');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = '"3"'::jsonb WHERE key = 'enseignant.classes_max'$$,
  '22023', 'nombre maximal de Classes par enseignant', '(e) un texte : refuse');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'enseignant.classes_max'$$,
  '22023', 'nombre maximal de Classes par enseignant', '(e) un booleen : refuse');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = 'null'::jsonb WHERE key = 'enseignant.classes_max'$$,
  '22023', 'nombre maximal de Classes par enseignant', '(e) un null JSON : refuse');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = '[3]'::jsonb WHERE key = 'enseignant.classes_max'$$,
  '22023', 'nombre maximal de Classes par enseignant', '(e) une liste : refuse');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = '{"max": 3}'::jsonb WHERE key = 'enseignant.classes_max'$$,
  '22023', 'nombre maximal de Classes par enseignant', '(e) un objet : refuse');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.reglage() = '3'::jsonb AND pg_temp.nb_journal() = 3,
  '(e) apres neuf refus, le reglage vaut toujours 3 et le journal n''a pas bouge');
-- 3.0 s'ecrit 3 ; 4.0 s'ecrit 4, et le journal garde 4 (le declencheur de
-- validation precede le journal) ; les bornes 80 et 1 passent.
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = '3.0'::jsonb, updated_by = auth.uid() WHERE key = 'enseignant.classes_max';
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.reglage()::text = '3' AND pg_temp.nb_journal() = 3,
  '(e) 3.0 est ecrit 3 (entier) ; la valeur ne change pas, donc aucune ligne de journal');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = '4.0'::jsonb, updated_by = auth.uid() WHERE key = 'enseignant.classes_max';
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.reglage()::text = '4' AND pg_temp.nb_journal() = 4
    AND (SELECT new_value::text = '4' AND old_value::text = '3'
           FROM public.app_config_history WHERE key = 'enseignant.classes_max' ORDER BY id DESC LIMIT 1),
  '(e) 4.0 est ecrit 4, et le journal garde « 4 » (le declencheur de validation precede le journal)');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = '80'::jsonb, updated_by = auth.uid() WHERE key = 'enseignant.classes_max';
UPDATE public.app_config SET value = '1'::jsonb, updated_by = auth.uid() WHERE key = 'enseignant.classes_max';
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.reglage() = '1'::jsonb AND app_private.classes_max_par_enseignant() = 1 AND pg_temp.nb_journal() = 6,
  '(e) les bornes 80 puis 1 sont acceptees et journalisees');
-- Maximum 1 : TG (deux Classes) est au-dessus, TH (une) est au plafond.
SELECT pg_temp.qui('c1a50000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus_plafond('c1a50000-0000-4000-8000-0000000000a3', 6, 1, 1,
  '(e) maximum 1 : TH (une Classe) est au plafond');
UPDATE public.app_config SET value = '3'::jsonb, updated_by = auth.uid() WHERE key = 'enseignant.classes_max';
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.reglage() = '3'::jsonb AND pg_temp.nb_journal() = 7,
  '(e) retour au maximum de trois, pour la suite');

-- La cle ne se renomme pas, ne s'efface pas (meme pour le proprietaire).
SELECT pg_temp.refus($$DELETE FROM public.app_config WHERE key = 'enseignant.classes_max'$$,
  '42501', 'le reglage enseignant.classes_max ne s''efface pas', '(e) la cle ne s''efface pas (proprietaire du scenario)');
SELECT pg_temp.refus($$UPDATE public.app_config SET key = 'enseignant.classes_maximum' WHERE key = 'enseignant.classes_max'$$,
  '42501', 'le reglage enseignant.classes_max ne se renomme pas', '(e) la cle ne se renomme pas');
SELECT pg_temp.vrai(pg_temp.reglage() = '3'::jsonb, '(e) le reglage est intact');

-- ------------------------------------------------------------------
-- (f) Une Classe close ne compte pas : TE a trois Classes
-- ------------------------------------------------------------------
SELECT pg_temp.qui('c1a50000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus_plafond('c1a50000-0000-4000-8000-0000000000e1', 4, 3, 3,
  '(f) TE (trois Classes) est au plafond');
SELECT public.cloturer_groupe(pg_temp.groupe_de('c1a50000-0000-4000-8000-0000000000e1', 3),
  'fin de la Classe (scenario)');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000e1') = 2
    AND app_private.classes_actives_enseignant('c1a50000-0000-4000-8000-0000000000e1') = 2
    AND (SELECT count(*) FROM public.groupes WHERE teacher_id = 'c1a50000-0000-4000-8000-0000000000e1') = 3,
  '(f) une Classe close ne compte pas : TE a trois lignes dans groupes mais deux Classes qui comptent');
SET LOCAL ROLE authenticated;
SELECT pg_temp.creer('c1a50000-0000-4000-8000-0000000000e1', 4);
SELECT pg_temp.refus_plafond('c1a50000-0000-4000-8000-0000000000e1', 5, 3, 3,
  '(f) TE recoit une Classe a la place de la Classe close, puis la suivante est refusee');
RESET ROLE;

-- ------------------------------------------------------------------
-- (g) Un remplacement ponctuel ne compte pas : TF (trois Classes, au plafond)
-- et TG (deux) prennent chacune une seance de TH
-- ------------------------------------------------------------------
SELECT pg_temp.qui('c1a50000-0000-4000-8000-0000000000a3', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.declarer_absence_seance('c1a5eeee-0000-4000-8000-000000000001',
                      'c1a5dddd-0000-4000-8000-000000000001') ->> 'etat' = 'absence_declaree'
  AND public.declarer_absence_seance('c1a5eeee-0000-4000-8000-000000000002',
                      'c1a5dddd-0000-4000-8000-000000000002') ->> 'etat' = 'absence_declaree',
  '(g) TH declare son absence a deux seances');
RESET ROLE;
SELECT pg_temp.qui('c1a50000-0000-4000-8000-0000000000f1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.prendre_remplacement('c1a5eeee-0000-4000-8000-000000000001',
                      'c1a5dddd-0000-4000-8000-000000000003') ->> 'etat' = 'acceptee',
  '(g) TF, au plafond de Classes, prend un remplacement ponctuel : accepte, le plafond ne le refuse pas');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000f1') = 3
    AND (SELECT count(*) FROM public.groupes WHERE teacher_id = 'c1a50000-0000-4000-8000-0000000000f1') = 3
    AND (SELECT teacher_id FROM public.sessions WHERE id = 'c1a5eeee-0000-4000-8000-000000000001')
        = 'c1a50000-0000-4000-8000-0000000000a3',
  '(g) le remplacement n''ecrit aucune Classe : TF garde trois Classes, la seance reste a son titulaire');
SELECT pg_temp.qui('c1a50000-0000-4000-8000-0000000000a2', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.prendre_remplacement('c1a5eeee-0000-4000-8000-000000000002',
                      'c1a5dddd-0000-4000-8000-000000000004') ->> 'etat' = 'acceptee',
  '(g) TG (deux Classes) prend un remplacement ponctuel');
RESET ROLE;
SELECT pg_temp.qui('c1a50000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.creer('c1a50000-0000-4000-8000-0000000000a2', 3);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.nb_classes('c1a50000-0000-4000-8000-0000000000a2') = 3,
  '(g) le remplacement ne compte pas : TG, avec une seance remplacee, recoit quand meme sa troisieme Classe');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus_plafond('c1a50000-0000-4000-8000-0000000000a2', 4, 3, 3,
  '(g) TG est ensuite au plafond comme les autres');
SELECT pg_temp.refus_plafond('c1a50000-0000-4000-8000-0000000000f1', 4, 3, 3,
  '(g) et TF, apres son remplacement, reste au plafond : le remplacement n''a rien change');
RESET ROLE;

-- ------------------------------------------------------------------
-- (h) Les refus existants gardent leur message et leur priorite
-- ------------------------------------------------------------------
SELECT pg_temp.qui('c1a50000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
-- TA a quatre Classes pour un maximum de trois ; TI en a trois et son plafond
-- horaire est d'une heure.
SELECT pg_temp.refus($$SELECT pg_temp.creer('c1a50000-0000-4000-8000-0000000000a1', 1)$$,
  'P0001', 'chevauchement avec une classe ou affectation active',
  '(h) TA, au-dessus du plafond, creant sur un horaire pris : le refus de collision garde la priorite');
SELECT pg_temp.refus($$SELECT pg_temp.creer('c1a50000-0000-4000-8000-0000000000b2', 4)$$,
  'P0001', 'plafond horaire enseignant',
  '(h) TI, au plafond de Classes et au plafond horaire (1 h) : le refus horaire garde la priorite');
SELECT pg_temp.refus($$SELECT public.creer_groupe('c1a50000-0000-4000-8000-000000000001', 'adulte', 'Pas un enseignant',
                          4::smallint, 10::smallint, 6::smallint, 'Europe/Paris'::text, NULL::smallint)$$,
  'P0001', 'cet enseignant n''existe pas ou son compte n''est pas valide',
  '(h) un compte qui n''est pas enseignant : le refus de creer_groupe est inchange');
RESET ROLE;

-- ------------------------------------------------------------------
-- (i) Personne d'autre que la direction active ne change le reglage
-- ------------------------------------------------------------------
CREATE FUNCTION pg_temp.tenter(p_id uuid, p_role text, p_sql_role text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_n integer;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_sql_role);
  BEGIN
    UPDATE public.app_config SET value = '50'::jsonb, updated_by = auth.uid() WHERE key = 'enseignant.classes_max';
    GET DIAGNOSTICS v_n = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN
    v_n := 0;
  END;
  RESET ROLE;
  IF v_n <> 0 OR pg_temp.reglage() IS DISTINCT FROM '3'::jsonb THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : % (%  ligne(s), reglage %)', p_label, v_n, pg_temp.reglage();
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;
SELECT pg_temp.tenter('c1a50000-0000-4000-8000-0000000000a1', 'teacher', 'authenticated',
  '(i) un enseignant ne change pas le reglage (0 ligne)');
SELECT pg_temp.tenter('c1a50000-0000-4000-8000-000000000003', 'guardian', 'authenticated',
  '(i) un tuteur ne change pas le reglage (0 ligne)');
SELECT pg_temp.tenter('c1a50000-0000-4000-8000-000000000004', 'accountant', 'authenticated',
  '(i) un comptable ne change pas le reglage (0 ligne)');
SELECT pg_temp.tenter('c1a50000-0000-4000-8000-000000000005', 'student', 'authenticated',
  '(i) un eleve ne change pas le reglage (0 ligne)');
SELECT pg_temp.tenter('c1a50000-0000-4000-8000-000000000002', 'admin', 'authenticated',
  '(i) une direction desactivee (compte disabled) ne change pas le reglage (0 ligne)');
SELECT pg_temp.tenter('c1a50000-0000-4000-8000-000000000001', 'admin', 'agent_ro',
  '(i) l''agent en lecture seule ne change pas le reglage');
SELECT pg_temp.tenter('c1a50000-0000-4000-8000-000000000001', 'admin', 'anon',
  '(i) un visiteur sans compte ne change pas le reglage');
SELECT pg_temp.vrai(pg_temp.nb_journal() = 7, '(i) aucune de ces tentatives n''a laisse de ligne de journal');
-- Et ils ne le lisent pas non plus : seule la direction active lit app_config.
SELECT pg_temp.qui('c1a50000-0000-4000-8000-0000000000a1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.app_config WHERE key = 'enseignant.classes_max') = 0,
  '(i) un enseignant ne lit pas le reglage (RLS)');
RESET ROLE;

-- ------------------------------------------------------------------
-- (j) Aucun autre chemin ne donne une Classe a un enseignant
-- ------------------------------------------------------------------
-- Les fonctions qui ECRIVENT groupes.teacher_id (un UPDATE de groupes dont la
-- liste SET nomme teacher_id, a n'importe quelle place) : trois, toutes derriere
-- le predicat. Une quatrieme fait echouer ce controle, pour etre relue.
SELECT pg_temp.vrai(
  (SELECT array_agg(p.oid::regprocedure::text ORDER BY p.oid::regprocedure::text COLLATE "C")
     FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema') AND p.prokind = 'f'
      AND p.prosrc ~* 'update\s+(only\s+)?(public\.)?groupes\y' AND p.prosrc ~* '(set|,)\s*teacher_id\s*=') =
  -- 29/10/2026 : creer_classe_creneaux_admin (classe a plusieurs creneaux),
  -- relue : meme predicat que creer_groupe, avant l'affectation.
  ARRAY['affecter_enseignant_classe(uuid,uuid)', 'affecter_enseignant_classe_c11bis(uuid,uuid)',
        'creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint)',
        'creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)',
  -- 31/10/2026 (PR 104) : reaffecter_enseignant_classe, relue le 01/11 (L1) :
  -- app_private.verifier_affectation_enseignant (dont le maximum de
  -- Classes) avant l'ecriture, par private.verifier_reaffectation.
        'reaffecter_enseignant_classe(uuid,uuid,text)'],
  '(j) cinq fonctions seulement ecrivent groupes.teacher_id (affecter_enseignant_classe, sa version c11bis, creer_groupe a 8 arguments, creer_classe_creneaux_admin, reaffecter_enseignant_classe)');
SELECT pg_temp.vrai(
  -- reaffecter_enseignant_classe y passe par private.verifier_reaffectation,
  -- qui appelle app_private.verifier_affectation_enseignant (relu le 01/11).
  (SELECT bool_and(p.prosrc ~* '(verifier_affectation_enseignant|verifier_reaffectation)')
     FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema') AND p.prokind = 'f'
      AND p.prosrc ~* 'update\s+(only\s+)?(public\.)?groupes\y' AND p.prosrc ~* '(set|,)\s*teacher_id\s*='),
  '(j) chacune appelle le predicat d''affectation (directement ou par tc_verifier_affectation_enseignant)');
-- Les fonctions qui INSERENT une ligne de groupes : creer_groupe (6 et 8
-- arguments) et creer_classe_depuis_regroupement. La surcharge a 6 arguments
-- pose un enseignant sans predicat : elle n'est executable par personne ; les
-- deux autres inserent une classe SANS enseignant.
SELECT pg_temp.vrai(
  (SELECT array_agg(p.oid::regprocedure::text ORDER BY p.oid::regprocedure::text COLLATE "C")
     FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema') AND p.prokind = 'f'
      AND p.prosrc ~* 'insert\s+into\s+(public\.)?groupes\s*\(') =
  -- 29/10/2026 : creer_classe_creneaux_admin insere aussi une classe SANS
  -- enseignant, puis passe le predicat avant de l'affecter.
  ARRAY['creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint)',
        'creer_classe_depuis_regroupement(uuid,uuid,text)',
        'creer_groupe(uuid,text,text,smallint,smallint,smallint)',
        'creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)'],
  '(j) quatre fonctions seulement inserent dans groupes');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) r
               WHERE has_function_privilege(r, 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)'::regprocedure, 'EXECUTE')),
  '(j) la surcharge a six arguments de creer_groupe n''est executable par aucun role');
SELECT pg_temp.vrai(
  (SELECT prosrc LIKE '%(NULL, ''en_attente_enseignant'',%' FROM pg_proc
    WHERE oid = 'public.creer_classe_depuis_regroupement(uuid,uuid,text)'::regprocedure)
  AND (SELECT prosrc LIKE '%(null, ''en_attente_enseignant'',%' FROM pg_proc
    WHERE oid = 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)'::regprocedure),
  '(j) creer_classe_depuis_regroupement et creer_groupe (8 arguments) inserent une classe sans enseignant');
-- publier_groupe_depuis_offre passe par creer_groupe ; il n'est de toute facon
-- pas executable par un client.
SELECT pg_temp.vrai(
  (SELECT prosrc LIKE '%public.creer_groupe(%' FROM pg_proc
    WHERE oid = 'public.publier_groupe_depuis_offre(uuid,uuid,text,uuid[])'::regprocedure),
  '(j) publier_groupe_depuis_offre donne son enseignant par creer_groupe, donc par le predicat');
-- Les affectations individuelles ne creent aucune Classe et sont fermees aux
-- comptes connectes (L3-02) : un cours particulier est une Classe de capacite un.
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM unnest(ARRAY['anon', 'authenticated']) r,
                    unnest(ARRAY['public.attribuer_eleve(uuid,uuid,integer,integer,text)',
                                 'public.prendre_eleve(uuid,integer,integer)']) f
               WHERE has_function_privilege(r, f::regprocedure, 'EXECUTE'))
  AND NOT has_function_privilege('service_role', 'public.attribuer_eleve(uuid,uuid,integer,integer,text)'::regprocedure, 'EXECUTE'),
  '(j) attribuer_eleve et prendre_eleve restent fermes aux comptes connectes (aucun contournement par l''affectation individuelle)');
-- Les remplacements n'ecrivent jamais groupes.
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM pg_proc p
               WHERE p.oid IN ('public.prendre_remplacement(uuid,uuid)'::regprocedure,
                               'public.designer_remplacant_admin(uuid,uuid,uuid)'::regprocedure,
                               'public.declarer_absence_seance(uuid,uuid)'::regprocedure)
                 AND p.prosrc ~* '(update|insert\s+into)\s+(public\.)?groupes\M'),
  '(j) prendre_remplacement, designer_remplacant_admin et declarer_absence_seance n''ecrivent pas groupes');

-- Aucun client n'ecrit groupes directement : la direction non plus. Le stub de
-- test n'accorde pas INSERT ni UPDATE sur groupes a authenticated, alors que
-- Supabase accorde tout par defaut : pour que ce soit la RLS qu'on eprouve, et
-- pas l'absence de privilege, on accorde les deux ici (annule avec le reste par
-- le ROLLBACK final).
GRANT INSERT, UPDATE ON public.groupes TO authenticated;
SELECT pg_temp.qui('c1a50000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
DO $direct$
DECLARE v_n integer := 0;
BEGIN
  -- Privileges de table accordes (voir plus haut) : seule la RLS refuse. Un
  -- UPDATE ne voit aucune ligne (aucune policy d'ecriture), un INSERT est
  -- refuse (42501) : jamais une ecriture.
  BEGIN
    UPDATE public.groupes SET teacher_id = 'c1a50000-0000-4000-8000-0000000000a1'
     WHERE id = 'c1a5ffff-0000-4000-8000-000000000002';
    GET DIAGNOSTICS v_n = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN
    v_n := 0;
  END;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : (j) la direction a ecrit groupes.teacher_id directement';
  END IF;
  BEGIN
    INSERT INTO public.groupes (teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local)
    VALUES ('c1a50000-0000-4000-8000-0000000000a1', 'active', 'adulte', 6, 'Directe', 7, 10);
    RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : (j) la direction a insere une classe directement';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$direct$;
RESET ROLE;
SELECT pg_temp.ok('(j) meme avec INSERT et UPDATE accordes a authenticated, la direction ne peut ni mettre a jour ni inserer une classe directement dans groupes (RLS, aucune policy d''ecriture)');

-- ------------------------------------------------------------------
-- (k) Droits et forme des fonctions
-- ------------------------------------------------------------------
DO $droits$
DECLARE
  v_f regprocedure;
  v_role text;
  v_p pg_catalog.pg_proc%ROWTYPE;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
      'app_private.classes_max_par_enseignant()'::regprocedure,
      'app_private.classes_actives_enseignant(uuid,uuid)'::regprocedure,
      'app_private.verifier_plafond_classes_enseignant(uuid,uuid)'::regprocedure,
      'app_private.verifier_affectation_enseignant(uuid,uuid,boolean)'::regprocedure,
      'app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)'::regprocedure,
      'private.plafond_classes_valider()'::regprocedure] LOOP
    SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_f::oid;
    IF v_p.prosecdef OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false)
       OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres' THEN
      RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : (k) % : INVOKER, search_path vide et postgres attendus', v_f;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v_f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : (k) % execute %', v_role, v_f;
      END IF;
    END LOOP;
    IF coalesce(pg_catalog.obj_description(v_f::oid, 'pg_proc'), '') NOT LIKE '%INVOKER, aucun EXECUTE client%'
       AND v_f::text <> 'private.plafond_classes_valider()' THEN
      RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : (k) % : commentaire absent', v_f;
    END IF;
  END LOOP;
  -- Le predicat public garde sa signature et ses droits (lot c11bis).
  IF (SELECT p.proacl::text FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.tc_verifier_affectation_enseignant(uuid,uuid)'::regprocedure::oid)
       <> '{postgres=X/postgres,service_role=X/postgres}' THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : (k) droits du predicat public changes';
  END IF;
  -- creer_groupe garde son empreinte F86 (il n'a pas ete reecrit).
  IF coalesce(pg_catalog.obj_description(
       'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)'::regprocedure::oid, 'pg_proc'), '')
     NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)'::regprocedure)) || '%' THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : (k) empreinte F86 de creer_groupe';
  END IF;
  -- Le declencheur de validation precede le journal des reglages.
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t WHERE t.tgrelid = 'public.app_config'::regclass
                  AND t.tgname = 'app_config_classes_max' AND t.tgenabled = 'O')
     OR 'app_config_classes_max' COLLATE "C" >= 'app_config_history' COLLATE "C" THEN
    RAISE EXCEPTION 'CLASSES-PLAFOND ROUGE : (k) declencheur de validation';
  END IF;
END
$droits$;
SELECT pg_temp.ok('(k) six fonctions INVOKER sans EXECUTE client ; predicat public et empreinte de creer_groupe inchanges ; declencheur avant le journal');

SELECT pg_temp.vrai(coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int >= 77,
  'au moins 77 controles ont passe (78 avec celui-ci)');

ROLLBACK;
