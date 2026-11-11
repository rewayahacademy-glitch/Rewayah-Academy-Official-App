-- PARTAGE-GENERIQUE (11/11/2026) : la page de reprise d'un support qui n'est
-- pas le Coran, par Classe et par support.
-- Migration 20261123000000 (BROUILLON NON APPLIQUE a distance le 11/11/2026).
-- Memes fixtures que scenarios_cahier_c1_position_reprise.sql : une Classe c1,
-- titulaire b1 ; b2 la remplace sur s74 et s72 ; b3 enseignant etranger ; a1
-- la direction ; e1 un eleve. s71 est en cours (fenetre d'ecriture ouverte).
--   1. rien de presente : zero ligne, sans erreur ;
--   2. b1 presente « lettres » page 3 puis « voyelles » page 7 : deux lignes,
--      une par support ; la page du Coran de la Classe n'est pas touchee, et
--      presenter le Coran ne touche pas les supports ;
--   3. b3 (etranger), e1 (eleve) : ecriture et lecture refusees ;
--   4. b2 (remplacant) lit avant sa seance ; n'ecrit pas hors de la seance ;
--      ecrit pendant s74 ; b1, ecarte de s74, n'y ecrit pas ;
--   5. la direction lit, n'ecrit pas ;
--   6. valeurs refusees : page hors du support, support vide, identifiant du
--      Coran, nombre de pages absurde ; seance passee ;
--   7. aucun acces direct a la table ; droits des fonctions.
-- Echoue sans la migration (premier ROUGE : la fonction n'existe pas).
-- Tout est annule a la fin.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('c1c10000-0000-4000-8000-0000000000' || p)::uuid $$;

-- Ecrire la page d'un support ; rend 'ok', 'refus' (42501) ou 'invalide' (22023).
CREATE FUNCTION pg_temp.ecrire(p_seance uuid, p_support text, p_page integer,
                               p_pages integer DEFAULT 40) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.enregistrer_position_support(p_seance, p_support, 'v1', p_page, p_pages);
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN invalid_parameter_value THEN RETURN 'invalide';
END $$;

-- Lire les pages de la Classe d'une seance : « lettres=3,voyelles=7 »,
-- 'vide' ou 'refus'.
CREATE FUNCTION pg_temp.lire(p_seance uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  SELECT pg_catalog.string_agg(r.support || '=' || r.page::text, ',' ORDER BY r.support)
    INTO v FROM public.positions_reprise_supports_seance(p_seance) r;
  RETURN coalesce(v, 'vide');
EXCEPTION WHEN insufficient_privilege THEN RETURN 'refus';
END $$;

-- La page du Coran de la Classe (CAHIER-C1) ; 'vide' si aucune.
CREATE FUNCTION pg_temp.coran(p_groupe uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  SELECT r.page INTO v FROM public.position_reprise_classe(p_groupe) r;
  RETURN coalesce(v::text, 'vide');
EXCEPTION WHEN insufficient_privilege THEN RETURN 'refus';
END $$;

-- Presenter une page du Coran (CAHIER-C1) ; rend 'ok' ou 'refus'.
CREATE FUNCTION pg_temp.ecrire_coran(p_seance uuid, p_page integer) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.enregistrer_page_presentee(p_seance, p_page);
  RETURN 'ok';
EXCEPTION WHEN insufficient_privilege THEN RETURN 'refus';
END $$;

-- Lecture directe de la table ; vrai si refusee.
CREATE FUNCTION pg_temp.table_fermee() RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM 1 FROM public.classe_position_support;
  RETURN false;
EXCEPTION WHEN insufficient_privilege THEN RETURN true;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.ecrire(uuid, text, integer, integer), pg_temp.lire(uuid), pg_temp.coran(uuid),
  pg_temp.ecrire_coran(uuid, integer), pg_temp.table_fermee() TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'c1-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b2','b3','e1']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.role = 'student' THEN pg_temp.u('f1') END,
       x.prenom, 'C1', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','C1-ADM-01','admin','Direction'),
   ('b1','C1-ENS-01','teacher','Titulaire'),
   ('b2','C1-ENS-02','teacher','Remplacante'),
   ('b3','C1-ENS-03','teacher','Etrangere'),
   ('e1','C1-ELV-01','student','Eleve un')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
VALUES (pg_temp.u('e1'), 'minor'::public.student_type, 'standard'::public.interface_mode);
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour C1', 1, 18, 'America/Toronto');
-- Horloge : une classe active avec son enseignant recoit, a sa creation, ses
-- prochaines seances hebdomadaires (tc_materialiser_apres_creation_groupe). Selon
-- l'heure a laquelle la CI tourne, l'une d'elles chevauche une seance que ce scenario
-- fixe a now() + ... (sessions_no_teacher_overlap, 23P01) : il echouait a certains
-- creneaux de la semaine. Il pose ses propres seances ; celles de l'horaire recurrent
-- n'ont rien a faire ici et se retirent, ce qui le rend independant de l'heure sans
-- changer un seul de ses controles (meme correction que scenarios_fn025_motif_refus_salle).
DELETE FROM public.sessions
 WHERE groupe_id IN (pg_temp.u('c1'));

INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT pg_temp.u(x.s), pg_temp.u('b1'),
       pg_catalog.now() + x.debut * interval '1 minute',
       pg_catalog.now() + (x.debut + 60) * interval '1 minute',
       'planned', pg_temp.u('c1')
  FROM (VALUES ('71', -70), ('74', 20), ('72', 1440), ('73', -14400)) AS x(s, debut);
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u(x), pg_temp.u('e1'), 'student'::public.participant_role
  FROM unnest(ARRAY['71','74','72','73']) AS x;

-- s74 et s72 : absence declaree par la titulaire, puis remplacement pris par b2.
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence, cree_le)
SELECT pg_temp.u(x.s), x.ev, pg_temp.u('b1'),
       CASE WHEN x.ev = 'remplacement_pris' THEN pg_temp.u('b2') END,
       CASE WHEN x.ev = 'remplacement_pris' THEN pg_temp.u('b2') ELSE pg_temp.u('b1') END,
       pg_temp.u(x.cle), pg_catalog.clock_timestamp() + x.ms * interval '1 millisecond'
  FROM (VALUES ('74', 'absence_declaree', '91', 0), ('74', 'remplacement_pris', '92', 1),
               ('72', 'absence_declaree', '93', 2), ('72', 'remplacement_pris', '94', 3))
       AS x(s, ev, cle, ms);

-- ------------------------------------------------------------------
-- 1. Rien de presente
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.u('71')) = 'vide',
  'titulaire : aucun support presente, la lecture rend vide sans erreur');

-- ------------------------------------------------------------------
-- 2. Une page par Classe et par support ; le Coran a part
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.ecrire_coran(pg_temp.u('71'), 14) = 'ok'
  AND pg_temp.coran(pg_temp.u('c1')) = '14',
  'titulaire : le Coran est page 14 (CAHIER-C1, inchange)');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('71'), 'lettres', 3) = 'ok'
  AND pg_temp.ecrire(pg_temp.u('71'), 'voyelles', 7) = 'ok',
  'titulaire : enregistre « lettres » page 3 et « voyelles » page 7');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('71'), 'lettres', 3) = 'ok',
  'titulaire : la meme page enregistree deux fois ne casse rien');
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.u('71')) = 'lettres=3,voyelles=7',
  'titulaire : une page par support');
SELECT pg_temp.vrai(pg_temp.coran(pg_temp.u('c1')) = '14',
  'ouvrir un autre support n''a pas touche la page du Coran de la Classe');
SELECT pg_temp.vrai(pg_temp.ecrire_coran(pg_temp.u('71'), 15) = 'ok'
  AND pg_temp.lire(pg_temp.u('71')) = 'lettres=3,voyelles=7',
  'tourner la page du Coran ne touche pas les pages des supports');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('71'), 'lettres', 4) = 'ok'
  AND pg_temp.lire(pg_temp.u('71')) = 'lettres=4,voyelles=7',
  'titulaire : la page de « lettres » avance, « voyelles » reste');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Etranger et eleve
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('71'), 'lettres', 9) = 'refus'
  AND pg_temp.lire(pg_temp.u('71')) = 'refus',
  'enseignant etranger : n''ecrit pas, ne lit pas');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('71'), 'lettres', 9) = 'refus'
  AND pg_temp.lire(pg_temp.u('71')) = 'refus',
  'eleve : n''ecrit pas, ne lit pas');
RESET ROLE;

-- ------------------------------------------------------------------
-- 4. Le remplacant
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.u('72')) = 'lettres=4,voyelles=7',
  'remplacant : lit les pages avant la seance qui lui est confiee');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('72'), 'lettres', 9) = 'refus',
  'remplacant : n''ecrit pas hors de la seance (demain)');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('74'), 'lettres', 5) = 'ok',
  'remplacant : enregistre pendant la seance remplacee');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('74'), 'lettres', 6) = 'refus',
  'titulaire ecarte : n''ecrit pas sur la seance remplacee');
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.u('71')) = 'lettres=5,voyelles=7',
  'titulaire : « lettres » reprend page 5, celle du remplacant');
RESET ROLE;

-- ------------------------------------------------------------------
-- 5. La direction
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.u('71')) = 'lettres=5,voyelles=7'
  AND pg_temp.ecrire(pg_temp.u('71'), 'lettres', 9) = 'refus',
  'direction : lit les pages, n''ecrit pas');
RESET ROLE;

-- ------------------------------------------------------------------
-- 6. Valeurs et fenetre
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('71'), 'lettres', 0) = 'invalide'
  AND pg_temp.ecrire(pg_temp.u('71'), 'lettres', 41) = 'invalide'
  AND pg_temp.ecrire(pg_temp.u('71'), 'lettres', NULL) = 'invalide'
  AND pg_temp.ecrire(pg_temp.u('71'), 'lettres', 3, 0) = 'invalide'
  AND pg_temp.ecrire(pg_temp.u('71'), 'lettres', 3, 5001) = 'invalide',
  'page hors du support et nombre de pages absurde refuses');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('71'), '', 3) = 'invalide'
  AND pg_temp.ecrire(pg_temp.u('71'), NULL, 3) = 'invalide'
  AND pg_temp.ecrire(pg_temp.u('71'), 'mushaf', 3) = 'invalide'
  AND pg_temp.ecrire(pg_temp.u('71'), 'mushaf-madina-15', 3) = 'invalide'
  AND pg_temp.ecrire(pg_temp.u('71'), pg_catalog.repeat('x', 121), 3) = 'invalide',
  'support vide, trop long, ou identifiant du Coran refuses');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('73'), 'lettres', 9) = 'refus',
  'seance passee depuis dix jours : ecriture refusee');
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.u('71')) = 'lettres=5,voyelles=7'
  AND pg_temp.coran(pg_temp.u('c1')) = '15',
  'aucune ecriture refusee n''a change une position');

-- ------------------------------------------------------------------
-- 7. Acces direct et droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.table_fermee(),
  'table : aucune lecture directe pour un enseignant');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon',
        'public.enregistrer_position_support(uuid, text, text, integer, integer)', 'EXECUTE')
  AND NOT has_function_privilege('anon',
        'public.positions_reprise_supports_seance(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro',
        'public.enregistrer_position_support(uuid, text, text, integer, integer)', 'EXECUTE')
  AND has_function_privilege('authenticated',
        'public.enregistrer_position_support(uuid, text, text, integer, integer)', 'EXECUTE')
  AND NOT has_table_privilege('authenticated', 'public.classe_position_support', 'INSERT')
  AND NOT has_table_privilege('anon', 'public.classe_position_support', 'SELECT'),
  'droits : fonctions fermees a anon et agent_ro, table fermee');

\o
ROLLBACK;
