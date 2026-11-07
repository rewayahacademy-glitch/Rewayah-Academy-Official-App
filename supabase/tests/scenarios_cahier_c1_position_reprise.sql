-- CAHIER-C1 (06/11/2026) : la position de reprise automatique d'une Classe.
-- Migration 20261110100000.
-- Une Classe c1, titulaire b1 ; b2 la remplace sur deux seances ; b3 est un
-- enseignant etranger ; a1 la direction ; e1 un eleve. Seances (heures
-- relatives a maintenant, pour que la fenetre d'ecriture soit testee) :
--   s71 : de -70 min a -10 min, tenue par b1 (fenetre ouverte jusqu'a +50) ;
--   s74 : de +20 min a +80 min, remplacee par b2 ;
--   s72 : demain, remplacee par b2 ;
--   s73 : il y a dix jours, tenue par b1.
--   1. rien de presente : la lecture rend zero ligne, sans erreur ;
--   2. b1 presente la page 14 pendant s71 ; il la relit par la Classe ;
--   3. b3 (etranger), e1 (eleve) : ecriture et lecture refusees ;
--   4. b2, remplacant de demain : lit « page 14 » par la seance s72 et par
--      la Classe ; n'ecrit pas sur s72 (hors de la seance) ;
--   5. b2 presente la page 15 sur s74 ; b1, titulaire ecarte de s74,
--      n'ecrit pas sur s74 ; la Classe reprend page 15 ;
--   6. la direction lit, n'ecrit pas ;
--   7. page hors du Coran refusee ; seance passee refusee ;
--   8. aucun acces direct a la table ; droits des fonctions.
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

-- Ecrire une page ; rend 'ok', 'refus' (42501) ou 'invalide' (22023).
CREATE FUNCTION pg_temp.ecrire(p_seance uuid, p_page integer) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.enregistrer_page_presentee(p_seance, p_page);
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN invalid_parameter_value THEN RETURN 'invalide';
END $$;

-- Lire la page de la Classe ; rend la page, 'vide' ou 'refus'.
CREATE FUNCTION pg_temp.lire_classe(p_groupe uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  SELECT r.page INTO v FROM public.position_reprise_classe(p_groupe) r;
  RETURN coalesce(v::text, 'vide');
EXCEPTION WHEN insufficient_privilege THEN RETURN 'refus';
END $$;

CREATE FUNCTION pg_temp.lire_seance(p_seance uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  SELECT r.page INTO v FROM public.position_reprise_seance(p_seance) r;
  RETURN coalesce(v::text, 'vide');
EXCEPTION WHEN insufficient_privilege THEN RETURN 'refus';
END $$;

-- Lecture directe de la table ; vrai si refusee.
CREATE FUNCTION pg_temp.table_fermee() RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM 1 FROM public.classe_position_reprise;
  RETURN false;
EXCEPTION WHEN insufficient_privilege THEN RETURN true;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.ecrire(uuid, integer), pg_temp.lire_classe(uuid), pg_temp.lire_seance(uuid),
  pg_temp.table_fermee() TO authenticated, anon;

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
SELECT pg_temp.vrai(pg_temp.lire_classe(pg_temp.u('c1')) = 'vide',
  'titulaire : aucune page presentee, la lecture rend vide sans erreur');

-- ------------------------------------------------------------------
-- 2. Le titulaire presente la page 14 pendant s71
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('71'), 14) = 'ok',
  'titulaire : enregistre la page 14 pendant sa seance');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('71'), 14) = 'ok',
  'titulaire : la meme page enregistree deux fois ne casse rien');
SELECT pg_temp.vrai(pg_temp.lire_classe(pg_temp.u('c1')) = '14'
  AND pg_temp.lire_seance(pg_temp.u('71')) = '14',
  'titulaire : la Classe reprend page 14');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Etranger et eleve
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('71'), 30) = 'refus'
  AND pg_temp.lire_classe(pg_temp.u('c1')) = 'refus'
  AND pg_temp.lire_seance(pg_temp.u('71')) = 'refus',
  'enseignant etranger : n''ecrit pas, ne lit pas');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('71'), 30) = 'refus'
  AND pg_temp.lire_classe(pg_temp.u('c1')) = 'refus',
  'eleve : n''ecrit pas, ne lit pas');
RESET ROLE;

-- ------------------------------------------------------------------
-- 4. Le remplacant de demain
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.lire_seance(pg_temp.u('72')) = '14'
  AND pg_temp.lire_classe(pg_temp.u('c1')) = '14',
  'remplacant : voit « On reprend page 14 » avant la seance qui lui est confiee');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('72'), 20) = 'refus',
  'remplacant : n''ecrit pas hors de la seance (demain)');
SELECT pg_temp.vrai(pg_temp.lire_seance(pg_temp.u('71')) = '14',
  'remplacant : lit par une seance de la Classe qu''il ne tient pas (meme Classe)');

-- ------------------------------------------------------------------
-- 5. Le remplacant presente la page 15 sur s74
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('74'), 15) = 'ok',
  'remplacant : enregistre la page 15 pendant la seance remplacee');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('74'), 16) = 'refus',
  'titulaire ecarte : n''ecrit pas sur la seance remplacee');
SELECT pg_temp.vrai(pg_temp.lire_classe(pg_temp.u('c1')) = '15',
  'titulaire : la Classe reprend page 15, celle du remplacant');
RESET ROLE;

-- ------------------------------------------------------------------
-- 6. La direction
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.lire_classe(pg_temp.u('c1')) = '15'
  AND pg_temp.ecrire(pg_temp.u('71'), 40) = 'refus',
  'direction : lit la position, n''ecrit pas');
RESET ROLE;

-- ------------------------------------------------------------------
-- 7. Valeurs et fenetre
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('71'), 0) = 'invalide'
  AND pg_temp.ecrire(pg_temp.u('71'), 605) = 'invalide'
  AND pg_temp.ecrire(pg_temp.u('71'), NULL) = 'invalide',
  'page hors du Coran refusee (0, 605, nulle)');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('73'), 50) = 'refus',
  'seance passee depuis dix jours : ecriture refusee');
SELECT pg_temp.vrai(pg_temp.lire_classe(pg_temp.u('c1')) = '15',
  'aucune ecriture refusee n''a change la position');

-- ------------------------------------------------------------------
-- 8. Acces direct et droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.table_fermee(),
  'table : aucune lecture directe pour un enseignant');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.enregistrer_page_presentee(uuid, integer)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.position_reprise_classe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.position_reprise_seance(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.enregistrer_page_presentee(uuid, integer)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.cahier_c1_peut_lire_classe(uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.enregistrer_page_presentee(uuid, integer)', 'EXECUTE')
  AND NOT has_table_privilege('authenticated', 'public.classe_position_reprise', 'INSERT'),
  'droits : fonctions fermees a anon et agent_ro, table fermee, aide privee');

\o
ROLLBACK;
