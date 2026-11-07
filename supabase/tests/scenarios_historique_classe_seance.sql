-- HISTORIQUE-CLASSE (07/11/2026, migration 20261110900000, point 4 du pilote) :
-- mes_seances_v rend la Classe de la seance (groupe_id, groupe_libelle), lue
-- avec la seance sous la meme garde.
--   * la famille lit le nom de la Classe d'une seance passee d'une Classe
--     CLOSE depuis, et d'une Classe QUITTEE depuis (le cas « Classe non
--     disponible » de l'Historique) ;
--   * une famille hors foyer ne lit aucune ligne, donc aucun nom ;
--   * anon ne lit rien ;
--   * la garde FN-106 tient : une seance posee apres le depart reste cachee ;
--   * une seance sans Classe garde sa ligne, Classe nulle ;
--   * la jointure ne duplique ni ne perd aucune ligne.
-- Chaque refus a son controle positif. Base NEUVE (fixtures annulees).
\o /dev/null
BEGIN;
\ir _acl_photo.sql

CREATE FUNCTION pg_temp.qui_foyer(p_id uuid, p_role text, p_foyer uuid) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object('app_metadata',
    pg_catalog.json_strip_nulls(pg_catalog.json_build_object('role', p_role,
      'household_id', p_foyer)))::text;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.r_n',
    (coalesce(nullif(pg_catalog.current_setting('test.r_n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'ROUGE : % (code % au lieu de % : %)', p_label, SQLSTATE, p_code, SQLERRM;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui_foyer(uuid, text, uuid), pg_temp.ok(text),
  pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('4c100000-0000-4000-8000-0000000000b1','hc-t1@test.invalid'),
 ('4c100000-0000-4000-8000-0000000000d1','hc-g1@test.invalid'),
 ('4c100000-0000-4000-8000-0000000000d2','hc-g2@test.invalid'),
 ('4c100000-0000-4000-8000-0000000000e1','hc-e1@test.invalid'),
 ('4c100000-0000-4000-8000-0000000000e2','hc-e2@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('4c100000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('4c100000-0000-4000-8000-0000000000f2','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('4c100000-0000-4000-8000-0000000000b1','HC-ENS-0001','teacher',NULL,'Maryam','HC','provisional_active','female'),
 ('4c100000-0000-4000-8000-0000000000d1','HC-TUT-0001','guardian','4c100000-0000-4000-8000-0000000000f1','Amina','Foyer1','active','female'),
 ('4c100000-0000-4000-8000-0000000000d2','HC-TUT-0002','guardian','4c100000-0000-4000-8000-0000000000f2','Sara','Foyer2','active','female'),
 ('4c100000-0000-4000-8000-0000000000e1','HC-ELV-0001','student','4c100000-0000-4000-8000-0000000000f1','Yasmine','Foyer1','active','female'),
 ('4c100000-0000-4000-8000-0000000000e2','HC-ELV-0002','student','4c100000-0000-4000-8000-0000000000f2','Adam','Foyer2','active','male');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('4c100000-0000-4000-8000-0000000000e1','minor','standard'),
 ('4c100000-0000-4000-8000-0000000000e2','minor','standard');
-- C1 : Classe que Yasmine a QUITTEE ; C2 : Classe CLOSE depuis ; C3 : Classe
-- courante d'Adam (foyer 2).
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('4c100000-0000-4000-8000-0000000000c1','4c100000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour HC',1,9,'Europe/Paris'),
 ('4c100000-0000-4000-8000-0000000000c2','4c100000-0000-4000-8000-0000000000b1','enfant',5,'Al-Fajr HC',2,10,'Europe/Paris'),
 ('4c100000-0000-4000-8000-0000000000c3','4c100000-0000-4000-8000-0000000000b1','enfant',5,'Al-Huda HC',3,11,'Europe/Paris');
-- Une seule Classe active par eleve (groupe_membres_actif_uidx) : Yasmine
-- est entree dans C1, l'a quittee il y a 7 jours, puis est entree dans C2.
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at, left_at, left_by, left_reason) VALUES
 ('4c100000-0000-4000-8000-0000000000c1','4c100000-0000-4000-8000-0000000000e1',
  now() - interval '30 days', now() - interval '7 days',
  '4c100000-0000-4000-8000-0000000000d1', 'Scenario : changement de Classe');
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES
 ('4c100000-0000-4000-8000-0000000000c2','4c100000-0000-4000-8000-0000000000e1'),
 ('4c100000-0000-4000-8000-0000000000c3','4c100000-0000-4000-8000-0000000000e2');

-- Seances passees, posees a la main (identifiants connus) :
--   501 : C1, il y a 20 jours (avant le depart de Yasmine) ;
--   502 : C2, il y a 15 jours (avant la cloture de C2) ;
--   503 : C1, il y a 2 jours (APRES le depart : FN-106 la cache) ;
--   504 : sans Classe, il y a 10 jours ;
--   505 : C3, il y a 5 jours (foyer 2).
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id) VALUES
 ('4c100000-0000-4000-8000-000000000501','4c100000-0000-4000-8000-0000000000b1',
  now() - interval '20 days', now() - interval '20 days' + interval '45 minutes', 'ended',
  '4c100000-0000-4000-8000-0000000000c1'),
 ('4c100000-0000-4000-8000-000000000502','4c100000-0000-4000-8000-0000000000b1',
  now() - interval '15 days', now() - interval '15 days' + interval '45 minutes', 'ended',
  '4c100000-0000-4000-8000-0000000000c2'),
 ('4c100000-0000-4000-8000-000000000503','4c100000-0000-4000-8000-0000000000b1',
  now() - interval '2 days', now() - interval '2 days' + interval '45 minutes', 'ended',
  '4c100000-0000-4000-8000-0000000000c1'),
 ('4c100000-0000-4000-8000-000000000504','4c100000-0000-4000-8000-0000000000b1',
  now() - interval '10 days', now() - interval '10 days' + interval '45 minutes', 'ended',
  NULL),
 ('4c100000-0000-4000-8000-000000000505','4c100000-0000-4000-8000-0000000000b1',
  now() - interval '5 days', now() - interval '5 days' + interval '45 minutes', 'ended',
  '4c100000-0000-4000-8000-0000000000c3');
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
 ('4c100000-0000-4000-8000-000000000501','4c100000-0000-4000-8000-0000000000e1','student'),
 ('4c100000-0000-4000-8000-000000000502','4c100000-0000-4000-8000-0000000000e1','student'),
 ('4c100000-0000-4000-8000-000000000503','4c100000-0000-4000-8000-0000000000e1','student'),
 ('4c100000-0000-4000-8000-000000000504','4c100000-0000-4000-8000-0000000000e1','student'),
 ('4c100000-0000-4000-8000-000000000505','4c100000-0000-4000-8000-0000000000e2','student')
ON CONFLICT DO NOTHING;

-- C2 est close il y a 7 jours.
UPDATE public.groupes SET ended_at = now() - interval '7 days',
       ended_by = '4c100000-0000-4000-8000-0000000000d1', end_reason = 'Scenario : Classe close'
 WHERE id = '4c100000-0000-4000-8000-0000000000c2';

-- Le nombre de lignes attendu pour le foyer 1, compte sans aucune jointure
-- de Classe (meme garde FN-106 que la vue, ecrite a la main).
CREATE TEMP TABLE hc_attendu AS
SELECT count(*) AS n
  FROM public.sessions s
  JOIN public.session_participants spe
    ON spe.session_id = s.id AND spe.role = 'student' AND spe.deleted_at IS NULL
 WHERE s.deleted_at IS NULL
   AND spe.profile_id = '4c100000-0000-4000-8000-0000000000e1'
   AND s.id IN ('4c100000-0000-4000-8000-000000000501','4c100000-0000-4000-8000-000000000502',
                '4c100000-0000-4000-8000-000000000504');
GRANT SELECT ON hc_attendu TO authenticated;

-- ------------------------------------------------------------
-- 1. Forme : les deux colonnes en dernier, sans perdre la garde
-- ------------------------------------------------------------
SELECT pg_temp.vrai((SELECT pg_catalog.string_agg(a.attname, ',' ORDER BY a.attnum)
                       FROM (SELECT a.attname, a.attnum FROM pg_catalog.pg_attribute a
                              WHERE a.attrelid = 'public.mes_seances_v'::pg_catalog.regclass
                                AND a.attnum > 0 AND NOT a.attisdropped
                              ORDER BY a.attnum DESC LIMIT 2) a) = 'groupe_id,groupe_libelle',
  'mes_seances_v : groupe_id puis groupe_libelle en dernieres colonnes');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                             WHERE c.oid = 'public.mes_seances_v'::pg_catalog.regclass
                               AND coalesce(c.reloptions, '{}') @> ARRAY['security_barrier=true']),
  'mes_seances_v : security_barrier garde');

-- ------------------------------------------------------------
-- 2. anon ne lit rien
-- ------------------------------------------------------------
SET LOCAL ROLE anon;
SELECT pg_temp.refus($$SELECT groupe_libelle FROM public.mes_seances_v$$,
  '42501', 'anon : mes_seances_v refusee');
RESET ROLE;

-- ------------------------------------------------------------
-- 3. La famille lit le nom de la Classe quittee et de la Classe close
-- ------------------------------------------------------------
SELECT pg_temp.qui_foyer('4c100000-0000-4000-8000-0000000000d1','guardian','4c100000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT groupe_libelle FROM public.mes_seances_v
                      WHERE session_id = '4c100000-0000-4000-8000-000000000501') = 'An-Nour HC',
  'tuteur : seance d''une Classe QUITTEE depuis, son nom se lit');
SELECT pg_temp.vrai((SELECT groupe_id FROM public.mes_seances_v
                      WHERE session_id = '4c100000-0000-4000-8000-000000000501')
                    = '4c100000-0000-4000-8000-0000000000c1',
  'tuteur : seance d''une Classe quittee, son groupe_id se lit');
SELECT pg_temp.vrai((SELECT groupe_libelle FROM public.mes_seances_v
                      WHERE session_id = '4c100000-0000-4000-8000-000000000502') = 'Al-Fajr HC',
  'tuteur : seance d''une Classe CLOSE depuis, son nom se lit');
-- Controle de la cause : ces deux Classes ne sont plus « courantes ».
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_groupes_famille_v
                                 WHERE groupe_id IN ('4c100000-0000-4000-8000-0000000000c1',
                                                     '4c100000-0000-4000-8000-0000000000c2')),
  'tuteur : ni la Classe quittee ni la Classe close dans les classes courantes');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.mes_seances_v
                             WHERE session_id = '4c100000-0000-4000-8000-000000000504'
                               AND groupe_id IS NULL AND groupe_libelle IS NULL),
  'tuteur : seance sans Classe, la ligne reste, Classe nulle');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_seances_v
                                 WHERE session_id = '4c100000-0000-4000-8000-000000000503'),
  'tuteur : FN-106 tient, la seance posee apres le depart reste cachee');
SELECT pg_temp.vrai((SELECT count(*) FROM public.mes_seances_v
                      WHERE student_id = '4c100000-0000-4000-8000-0000000000e1')
                    = (SELECT n FROM hc_attendu),
  'tuteur : meme nombre de lignes (aucune ligne dupliquee ni perdue)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_seances_v
                                 WHERE session_id = '4c100000-0000-4000-8000-000000000505'),
  'tuteur du foyer 1 : la seance du foyer 2 absente, son nom de Classe aussi');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_seances_v
                                 WHERE groupe_libelle = 'Al-Huda HC'),
  'tuteur du foyer 1 : aucun nom de Classe d''un autre foyer');
RESET ROLE;

-- ------------------------------------------------------------
-- 4. L'autre foyer et l'eleve
-- ------------------------------------------------------------
SELECT pg_temp.qui_foyer('4c100000-0000-4000-8000-0000000000d2','guardian','4c100000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT groupe_libelle FROM public.mes_seances_v
                      WHERE session_id = '4c100000-0000-4000-8000-000000000505') = 'Al-Huda HC',
  'tuteur du foyer 2 : le nom de la Classe de son enfant');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_seances_v
                                 WHERE groupe_libelle IN ('An-Nour HC', 'Al-Fajr HC')),
  'tuteur du foyer 2 : aucun nom de Classe du foyer 1');
RESET ROLE;

SELECT pg_temp.qui_foyer('4c100000-0000-4000-8000-0000000000e1','student','4c100000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT groupe_libelle FROM public.mes_seances_v
                      WHERE session_id = '4c100000-0000-4000-8000-000000000502') = 'Al-Fajr HC',
  'eleve : le nom de sa Classe close, sur sa seance passee');
RESET ROLE;

\ir _acl_retablir.sql

DO $fin$
BEGIN
  IF current_setting('test.r_n')::int <> 15 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 15 attendus', current_setting('test.r_n');
  END IF;
  RAISE NOTICE 'HISTORIQUE-CLASSE : % controles verts', current_setting('test.r_n');
END $fin$;

ROLLBACK;
