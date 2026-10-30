-- D5 (30/10/2026) : l'adulte titulaire entre dans une classe adulte de son
-- genre. Migration 20261031200000_d5_titulaire_adulte_en_classe.sql.
--
--   (a) `eleves_proposables_classe` : eleves comme avant ; l'adulte titulaire
--       seulement pour une classe adulte de son genre (ou mixte) ; jamais le
--       parent sans profil d'eleve ; rien pour qui n'est pas la direction ;
--       anon n'a aucun droit ;
--   (b) `ajouter_eleve_groupe` refuse l'adulte hors de sa classe (enfant,
--       autre genre), refuse le parent, accepte l'adulte dans sa classe ;
--   (c) l'adulte devient participant `student` des seances a venir, et
--       `seance_a_rejoindre` l'admet ;
--   (d) le chemin d'un eleve `student` est inchange.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations).
-- Chaque controle leve 'D5 ROUGE : ...' s'il echoue. Tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object(
             'sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
             'app_metadata', pg_catalog.json_build_object('role', p_role))::text;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'D5 ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- L'ajout, sous l'identite de la direction : 'accepte' ou le message du refus.
CREATE FUNCTION pg_temp.ajout(p_groupe uuid, p_profil uuid) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.ajouter_eleve_groupe(p_groupe, p_profil, 'D5 scenario');
  RETURN 'accepte';
EXCEPTION WHEN OTHERS THEN
  RETURN SQLERRM;
END $$;

-- La liste proposee pour une classe, sous l'identite courante.
CREATE FUNCTION pg_temp.propose(p_groupe uuid, p_profil uuid) RETURNS boolean
LANGUAGE sql AS $$
  SELECT EXISTS (SELECT 1 FROM public.eleves_proposables_classe(p_groupe) e
                  WHERE e.profile_id = p_profil);
$$;

-- Fixtures : 0d5e0000-... (personnes), 0d5e0a00-... (classes).
--   ...01 direction, ...02 enseignant, ...03 adulte homme titulaire,
--   ...04 adulte femme titulaire, ...05 parent sans profil d'eleve,
--   ...06 eleve mineur.
INSERT INTO auth.users (id, email) VALUES
  ('0d5e0000-0000-4000-8000-000000000001', 'd5-direction@example.test'),
  ('0d5e0000-0000-4000-8000-000000000002', 'd5-enseignant@example.test'),
  ('0d5e0000-0000-4000-8000-000000000003', 'd5-adulte-h@example.test'),
  ('0d5e0000-0000-4000-8000-000000000004', 'd5-adulte-f@example.test'),
  ('0d5e0000-0000-4000-8000-000000000005', 'd5-parent@example.test'),
  ('0d5e0000-0000-4000-8000-000000000006', 'd5-eleve@example.test');

INSERT INTO public.households (id, timezone) VALUES
  ('0d5effff-0000-4000-8000-000000000003', 'Europe/Paris'),
  ('0d5effff-0000-4000-8000-000000000004', 'Europe/Paris'),
  ('0d5effff-0000-4000-8000-000000000005', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('0d5e0000-0000-4000-8000-000000000001', 'ADMIN-D5-000001', 'admin', NULL,
   'Fixture', 'Direction', 'active', 'female'),
  ('0d5e0000-0000-4000-8000-000000000002', 'TEACH-D5-000001', 'teacher', NULL,
   'Fixture', 'Enseignant', 'provisional_active', 'male'),
  ('0d5e0000-0000-4000-8000-000000000003', 'GUARD-D5-000001', 'guardian',
   '0d5effff-0000-4000-8000-000000000003', 'Fixture', 'AdulteH', 'active', 'male'),
  ('0d5e0000-0000-4000-8000-000000000004', 'GUARD-D5-000002', 'guardian',
   '0d5effff-0000-4000-8000-000000000004', 'Fixture', 'AdulteF', 'active', 'female'),
  ('0d5e0000-0000-4000-8000-000000000005', 'GUARD-D5-000003', 'guardian',
   '0d5effff-0000-4000-8000-000000000005', 'Fixture', 'Parent', 'active', 'male'),
  ('0d5e0000-0000-4000-8000-000000000006', 'STUD-D5-000001', 'student',
   '0d5effff-0000-4000-8000-000000000005', 'Fixture', 'Eleve', 'active', 'male');

-- Le profil d'eleve des deux adultes est sur eux-memes (inscrire_titulaire).
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode, camera_policy) VALUES
  ('0d5e0000-0000-4000-8000-000000000003', 'autonomous', 'standard', 'forbidden'),
  ('0d5e0000-0000-4000-8000-000000000004', 'autonomous', 'standard', 'forbidden'),
  ('0d5e0000-0000-4000-8000-000000000006', 'minor', 'standard', 'forbidden');

-- Classes actives : H adulte hommes, F adulte femmes, M adulte mixte,
-- E enfant. Mercredi 18 h a Paris.
INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, genre_public, mixte, seuil_max, libelle,
   weekday, hour_local, timezone_iana)
VALUES
  ('0d5e0a00-0000-4000-8000-00000000000a', '0d5e0000-0000-4000-8000-000000000002',
   'active', 'adulte', 'hommes', false, 6, 'D5 H', 3, 18, 'Europe/Paris'),
  ('0d5e0a00-0000-4000-8000-00000000000b', '0d5e0000-0000-4000-8000-000000000002',
   'active', 'adulte', 'femmes', false, 6, 'D5 F', 4, 18, 'Europe/Paris'),
  ('0d5e0a00-0000-4000-8000-00000000000c', '0d5e0000-0000-4000-8000-000000000002',
   'active', 'adulte', 'indetermine', true, 6, 'D5 M', 5, 18, 'Europe/Paris'),
  ('0d5e0a00-0000-4000-8000-00000000000d', '0d5e0000-0000-4000-8000-000000000002',
   'active', 'enfant', 'hommes', false, 5, 'D5 E', 6, 18, 'Europe/Paris');

INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local)
SELECT g.id, g.weekday, g.hour_local FROM public.groupes g
 WHERE g.id::text LIKE '0d5e0a00-%'
ON CONFLICT DO NOTHING;

-- (a) la liste proposee
SELECT pg_temp.qui('0d5e0000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.propose('0d5e0a00-0000-4000-8000-00000000000a', '0d5e0000-0000-4000-8000-000000000006'),
  '(a) classe H : l''eleve est propose, comme avant');
SELECT pg_temp.vrai(pg_temp.propose('0d5e0a00-0000-4000-8000-00000000000a', '0d5e0000-0000-4000-8000-000000000003'),
  '(a) classe adulte hommes : l''adulte titulaire homme est propose');
SELECT pg_temp.vrai(NOT pg_temp.propose('0d5e0a00-0000-4000-8000-00000000000a', '0d5e0000-0000-4000-8000-000000000004'),
  '(a) classe adulte hommes : l''adulte titulaire femme n''est pas proposee');
SELECT pg_temp.vrai(pg_temp.propose('0d5e0a00-0000-4000-8000-00000000000b', '0d5e0000-0000-4000-8000-000000000004')
    AND NOT pg_temp.propose('0d5e0a00-0000-4000-8000-00000000000b', '0d5e0000-0000-4000-8000-000000000003'),
  '(a) classe adulte femmes : la femme oui, l''homme non');
SELECT pg_temp.vrai(pg_temp.propose('0d5e0a00-0000-4000-8000-00000000000c', '0d5e0000-0000-4000-8000-000000000003')
    AND pg_temp.propose('0d5e0a00-0000-4000-8000-00000000000c', '0d5e0000-0000-4000-8000-000000000004'),
  '(a) classe adulte mixte : les deux adultes sont proposes');
SELECT pg_temp.vrai(NOT pg_temp.propose('0d5e0a00-0000-4000-8000-00000000000d', '0d5e0000-0000-4000-8000-000000000003'),
  '(a) classe d''enfants : l''adulte n''est jamais propose');
SELECT pg_temp.vrai(NOT pg_temp.propose('0d5e0a00-0000-4000-8000-00000000000c', '0d5e0000-0000-4000-8000-000000000005'),
  '(a) le parent sans profil d''eleve n''est jamais propose');
SELECT pg_temp.vrai((SELECT e.adulte_titulaire FROM public.eleves_proposables_classe('0d5e0a00-0000-4000-8000-00000000000c') e
                      WHERE e.profile_id = '0d5e0000-0000-4000-8000-000000000003')
    AND NOT (SELECT e.adulte_titulaire FROM public.eleves_proposables_classe('0d5e0a00-0000-4000-8000-00000000000c') e
              WHERE e.profile_id = '0d5e0000-0000-4000-8000-000000000006'),
  '(a) adulte_titulaire distingue l''adulte de l''eleve');
RESET ROLE;

SELECT pg_temp.qui('0d5e0000-0000-4000-8000-000000000002', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.eleves_proposables_classe('0d5e0a00-0000-4000-8000-00000000000c')) = 0,
  '(a) un enseignant ne lit rien');
RESET ROLE;

SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.eleves_proposables_classe(uuid)', 'execute'),
  '(a) anon n''a aucun droit sur la liste');
SELECT pg_temp.vrai((SELECT p.provolatile = 's' AND p.prosecdef
                       FROM pg_proc p WHERE p.oid = 'public.eleves_proposables_classe(uuid)'::regprocedure),
  '(a) la liste est STABLE et SECURITY DEFINER');

-- (b) l'ajout
SELECT pg_temp.qui('0d5e0000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.ajout('0d5e0a00-0000-4000-8000-00000000000d', '0d5e0000-0000-4000-8000-000000000003')
    LIKE 'cet eleve n''existe pas%',
  '(b) l''adulte est refuse dans une classe d''enfants');
SELECT pg_temp.vrai(pg_temp.ajout('0d5e0a00-0000-4000-8000-00000000000a', '0d5e0000-0000-4000-8000-000000000004')
    LIKE 'cet eleve n''existe pas%',
  '(b) la femme est refusee dans une classe d''hommes');
SELECT pg_temp.vrai(pg_temp.ajout('0d5e0a00-0000-4000-8000-00000000000c', '0d5e0000-0000-4000-8000-000000000005')
    LIKE 'cet eleve n''existe pas%',
  '(b) le parent sans profil d''eleve est refuse');
SELECT pg_temp.vrai(pg_temp.ajout('0d5e0a00-0000-4000-8000-00000000000a', '0d5e0000-0000-4000-8000-000000000003') = 'accepte',
  '(b) l''adulte homme entre dans la classe adulte hommes');
SELECT pg_temp.vrai(pg_temp.ajout('0d5e0a00-0000-4000-8000-00000000000c', '0d5e0000-0000-4000-8000-000000000004') = 'accepte',
  '(b) l''adulte femme entre dans la classe mixte');
SELECT pg_temp.vrai(pg_temp.ajout('0d5e0a00-0000-4000-8000-00000000000c', '0d5e0000-0000-4000-8000-000000000003')
    LIKE 'cet eleve appartient deja%',
  '(b) un adulte deja en classe n''entre pas dans une seconde');
-- (d) le chemin de l'eleve
SELECT pg_temp.vrai(pg_temp.ajout('0d5e0a00-0000-4000-8000-00000000000d', '0d5e0000-0000-4000-8000-000000000006') = 'accepte',
  '(d) l''eleve entre dans la classe d''enfants, comme avant');
RESET ROLE;

SELECT pg_temp.qui('0d5e0000-0000-4000-8000-000000000002', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.ajout('0d5e0a00-0000-4000-8000-00000000000b', '0d5e0000-0000-4000-8000-000000000004')
    LIKE 'ajout d''un eleve a un groupe reserve%',
  '(b) un enseignant n''ajoute personne');
RESET ROLE;

-- (c) les seances a venir et la salle
SELECT pg_temp.vrai((SELECT count(*) FROM public.session_participants sp
                       JOIN public.sessions s ON s.id = sp.session_id
                      WHERE s.groupe_id = '0d5e0a00-0000-4000-8000-00000000000a'
                        AND sp.profile_id = '0d5e0000-0000-4000-8000-000000000003'
                        AND sp.role = 'student') > 0,
  '(c) l''adulte est participant student des seances a venir de sa classe');

SELECT pg_temp.qui('0d5e0000-0000-4000-8000-000000000003', 'guardian');
SET LOCAL ROLE authenticated;
DO $$
BEGIN
  PERFORM public.seance_a_rejoindre('0d5e0a00-0000-4000-8000-00000000000a');
  RAISE NOTICE 'OK (c) seance_a_rejoindre admet l''adulte membre de sa classe';
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'D5 ROUGE : (c) seance_a_rejoindre refuse l''adulte (%)', SQLERRM;
END $$;
DO $$
BEGIN
  PERFORM public.seance_a_rejoindre('0d5e0a00-0000-4000-8000-00000000000b');
  RAISE EXCEPTION 'D5 ROUGE : (c) seance_a_rejoindre admet l''adulte dans une classe qui n''est pas la sienne';
EXCEPTION WHEN OTHERS THEN
  IF SQLERRM <> 'SeanceNonAutorisee' THEN
    RAISE;
  END IF;
  RAISE NOTICE 'OK (c) seance_a_rejoindre refuse une classe qui n''est pas la sienne';
END $$;
RESET ROLE;

\o
SELECT 'D5 VERT' AS resultat;
ROLLBACK;
