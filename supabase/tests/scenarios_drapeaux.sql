-- DRAPEAUX (04/11/2026, migration 20261109400000) : le pays de l'enseignant
-- dans mes_groupes_famille_v et mes_seances_v (ENS-PAYS-1_BR.md:15-26).
--   * la famille d'un eleve de la Classe lit teacher_country ;
--   * une famille hors Classe ne lit aucune ligne, donc aucun pays ;
--   * un agent masque lit null (comme le prenom) ;
--   * anon ne lit rien ;
--   * la jointure ne duplique aucune ligne ;
--   * un profil enseignant retire ne donne pas de pays dans mes_seances_v.
-- Chaque refus a son controle positif. Base NEUVE (fixtures annulees).
\o /dev/null
BEGIN;
\ir _acl_photo.sql

CREATE FUNCTION pg_temp.qui_foyer(p_id uuid, p_role text, p_foyer uuid, p_agent uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object('app_metadata',
    pg_catalog.json_strip_nulls(pg_catalog.json_build_object('role', p_role,
      'household_id', p_foyer, 'agent_token_id', p_agent)))::text;
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

GRANT EXECUTE ON FUNCTION pg_temp.qui_foyer(uuid, text, uuid, uuid), pg_temp.ok(text),
  pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('d2a00000-0000-4000-8000-0000000000b1','dr-t1@test.invalid'),
 ('d2a00000-0000-4000-8000-0000000000b2','dr-t2@test.invalid'),
 ('d2a00000-0000-4000-8000-0000000000d1','dr-g1@test.invalid'),
 ('d2a00000-0000-4000-8000-0000000000d2','dr-g2@test.invalid'),
 ('d2a00000-0000-4000-8000-0000000000e1','dr-e1@test.invalid'),
 ('d2a00000-0000-4000-8000-0000000000e2','dr-e2@test.invalid'),
 ('d2a00000-0000-4000-8000-0000000000e3','dr-e3@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('d2a00000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('d2a00000-0000-4000-8000-0000000000f2','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('d2a00000-0000-4000-8000-0000000000b1','DR-ENS-0001','teacher',NULL,'Maryam','DR','provisional_active','female'),
 ('d2a00000-0000-4000-8000-0000000000b2','DR-ENS-0002','teacher',NULL,'Ibrahim','DR','provisional_active','male'),
 ('d2a00000-0000-4000-8000-0000000000d1','DR-TUT-0001','guardian','d2a00000-0000-4000-8000-0000000000f1','Amina','Foyer1','active','female'),
 ('d2a00000-0000-4000-8000-0000000000d2','DR-TUT-0002','guardian','d2a00000-0000-4000-8000-0000000000f2','Sara','Foyer2','active','female'),
 ('d2a00000-0000-4000-8000-0000000000e1','DR-ELV-0001','student','d2a00000-0000-4000-8000-0000000000f1','Yasmine','Foyer1','active','female'),
 ('d2a00000-0000-4000-8000-0000000000e2','DR-ELV-0002','student','d2a00000-0000-4000-8000-0000000000f1','Bilal','Foyer1','active','male'),
 ('d2a00000-0000-4000-8000-0000000000e3','DR-ELV-0003','student','d2a00000-0000-4000-8000-0000000000f2','Adam','Foyer2','active','male');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('d2a00000-0000-4000-8000-0000000000e1','minor','child'),
 ('d2a00000-0000-4000-8000-0000000000e2','minor','standard'),
 ('d2a00000-0000-4000-8000-0000000000e3','minor','standard');
-- Maryam a un pays ; Ibrahim n'a pas de profil enseignant (pays inconnu).
INSERT INTO public.teacher_profiles(profile_id, country, titre) VALUES
 ('d2a00000-0000-4000-8000-0000000000b1','Côte d''Ivoire','sayyida')
ON CONFLICT (profile_id) DO UPDATE SET country = excluded.country, titre = excluded.titre;
-- C1 (Maryam) : Yasmine et Bilal, deux eleves du foyer 1 (fratrie : la
-- jointure ne doit dupliquer aucune ligne) ; C2 (Ibrahim) : Adam, foyer 2.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('d2a00000-0000-4000-8000-0000000000c1','d2a00000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour DR',1,9,'Africa/Abidjan'),
 ('d2a00000-0000-4000-8000-0000000000c2','d2a00000-0000-4000-8000-0000000000b2','enfant',5,'Al-Fajr DR',2,10,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES
 ('d2a00000-0000-4000-8000-0000000000c1','d2a00000-0000-4000-8000-0000000000e1'),
 ('d2a00000-0000-4000-8000-0000000000c1','d2a00000-0000-4000-8000-0000000000e2'),
 ('d2a00000-0000-4000-8000-0000000000c2','d2a00000-0000-4000-8000-0000000000e3');
-- Les seances generees a la creation des Classes portent deja les eleves ;
-- une seance posee en plus, pour un compte exact.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id) VALUES
 ('d2a00000-0000-4000-8000-000000000501','d2a00000-0000-4000-8000-0000000000b1',
  now() + interval '20 days', now() + interval '20 days 45 minutes', 'planned',
  'd2a00000-0000-4000-8000-0000000000c1');
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
 ('d2a00000-0000-4000-8000-000000000501','d2a00000-0000-4000-8000-0000000000e1','student'),
 ('d2a00000-0000-4000-8000-000000000501','d2a00000-0000-4000-8000-0000000000e2','student');

-- Le nombre de lignes attendu dans mes_seances_v, compte sans la jointure.
CREATE TEMP TABLE dr_attendu AS
SELECT count(*) AS n
  FROM public.sessions s
  JOIN public.session_participants spe
    ON spe.session_id = s.id AND spe.role = 'student' AND spe.deleted_at IS NULL
 WHERE s.deleted_at IS NULL AND s.groupe_id = 'd2a00000-0000-4000-8000-0000000000c1';
GRANT SELECT ON dr_attendu TO authenticated;

-- ------------------------------------------------------------
-- 1. Forme : la colonne en dernier, texte, sans perdre la garde
-- ------------------------------------------------------------
SELECT pg_temp.vrai((SELECT a.attname FROM pg_catalog.pg_attribute a
                      WHERE a.attrelid = 'public.mes_groupes_famille_v'::pg_catalog.regclass
                        AND a.attnum > 0 AND NOT a.attisdropped
                      ORDER BY a.attnum DESC LIMIT 1) = 'teacher_country',
  'mes_groupes_famille_v : teacher_country en derniere colonne');
SELECT pg_temp.vrai((SELECT a.attname FROM pg_catalog.pg_attribute a
                      WHERE a.attrelid = 'public.mes_seances_v'::pg_catalog.regclass
                        AND a.attnum > 0 AND NOT a.attisdropped
                      ORDER BY a.attnum DESC LIMIT 1) = 'teacher_country',
  'mes_seances_v : teacher_country en derniere colonne');

-- ------------------------------------------------------------
-- 2. anon ne lit rien
-- ------------------------------------------------------------
SET LOCAL ROLE anon;
SELECT pg_temp.refus($$SELECT teacher_country FROM public.mes_groupes_famille_v$$,
  '42501', 'anon : mes_groupes_famille_v refusee');
SELECT pg_temp.refus($$SELECT teacher_country FROM public.mes_seances_v$$,
  '42501', 'anon : mes_seances_v refusee');
RESET ROLE;

-- ------------------------------------------------------------
-- 3. La famille de la Classe lit le pays
-- ------------------------------------------------------------
SELECT pg_temp.qui_foyer('d2a00000-0000-4000-8000-0000000000d1','guardian','d2a00000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT teacher_country FROM public.mes_groupes_famille_v
                      WHERE groupe_id = 'd2a00000-0000-4000-8000-0000000000c1') = 'Côte d''Ivoire',
  'tuteur : le pays de l''enseignante de la Classe de ses enfants');
SELECT pg_temp.vrai((SELECT count(*) FROM public.mes_groupes_famille_v
                      WHERE groupe_id = 'd2a00000-0000-4000-8000-0000000000c1') = 1,
  'tuteur : une seule ligne pour la Classe de deux enfants (aucun doublon)');
-- nb_membres n'est pas controle ici : il vaut 4 pour deux enfants d'un meme
-- foyer dans la Classe, avant comme apres cette migration (jointure m x m2,
-- defaut anterieur releve le 04/11/2026, hors du lot DRAPEAUX).
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_groupes_famille_v
                                 WHERE groupe_id = 'd2a00000-0000-4000-8000-0000000000c2'),
  'tuteur : la Classe d''un autre foyer absente, donc son pays aussi');
SELECT pg_temp.vrai((SELECT count(*) FROM public.mes_seances_v
                      WHERE session_id = 'd2a00000-0000-4000-8000-000000000501'
                        AND teacher_country = 'Côte d''Ivoire') = 2,
  'tuteur : la seance de ses deux enfants porte le pays, une ligne par enfant');
SELECT pg_temp.vrai((SELECT count(*) FROM public.mes_seances_v v
                      JOIN public.sessions s ON s.id = v.session_id
                     WHERE s.groupe_id = 'd2a00000-0000-4000-8000-0000000000c1')
                    = (SELECT n FROM dr_attendu),
  'tuteur : mes_seances_v garde le meme nombre de lignes (aucune ligne dupliquee)');
RESET ROLE;

SELECT pg_temp.qui_foyer('d2a00000-0000-4000-8000-0000000000e1','student','d2a00000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT teacher_country FROM public.mes_groupes_famille_v
                      WHERE groupe_id = 'd2a00000-0000-4000-8000-0000000000c1') = 'Côte d''Ivoire',
  'eleve : le pays de son enseignante (Classe)');
SELECT pg_temp.vrai((SELECT teacher_country FROM public.mes_seances_v
                      WHERE session_id = 'd2a00000-0000-4000-8000-000000000501') = 'Côte d''Ivoire',
  'eleve : le pays de son enseignante (seance)');
RESET ROLE;

-- Un enseignant sans profil enseignant : pays nul, la ligne reste.
SELECT pg_temp.qui_foyer('d2a00000-0000-4000-8000-0000000000d2','guardian','d2a00000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.mes_groupes_famille_v
                             WHERE groupe_id = 'd2a00000-0000-4000-8000-0000000000c2'
                               AND teacher_country IS NULL AND teacher_prenom = 'Ibrahim'),
  'tuteur du foyer 2 : sa Classe se lit, pays nul sans profil enseignant');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_groupes_famille_v
                                 WHERE groupe_id = 'd2a00000-0000-4000-8000-0000000000c1'),
  'tuteur du foyer 2 : la Classe du foyer 1 absente, son pays aussi');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_seances_v
                                 WHERE session_id = 'd2a00000-0000-4000-8000-000000000501'),
  'tuteur du foyer 2 : la seance du foyer 1 absente, son pays aussi');
RESET ROLE;

-- ------------------------------------------------------------
-- 4. Un agent masque : le pays suit le prenom (nul)
-- ------------------------------------------------------------
-- Une session d'agent dont le jeton n'existe pas : agent_identite_masquee()
-- vaut vrai (le sens sur), les lignes de la famille restent lisibles.
SELECT pg_temp.qui_foyer('d2a00000-0000-4000-8000-0000000000d1','guardian','d2a00000-0000-4000-8000-0000000000f1',
                         'd2a00000-0000-4000-8000-0000000000aa');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.mes_groupes_famille_v
                             WHERE groupe_id = 'd2a00000-0000-4000-8000-0000000000c1'
                               AND teacher_prenom IS NULL),
  'agent masque : la ligne de la Classe se lit, prenom masque');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_groupes_famille_v
                                 WHERE teacher_country IS NOT NULL),
  'agent masque : aucun pays dans mes_groupes_famille_v');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.mes_seances_v
                             WHERE session_id = 'd2a00000-0000-4000-8000-000000000501'
                               AND teacher_first_name = 'DR-ENS-0001'),
  'agent masque : la seance se lit, prenom remplace par l''identifiant');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_seances_v
                                 WHERE teacher_country IS NOT NULL),
  'agent masque : aucun pays dans mes_seances_v');
RESET ROLE;

-- ------------------------------------------------------------
-- 5. L'enseignante voit son propre pays ; un profil enseignant retire n'en
--    donne plus dans mes_seances_v
-- ------------------------------------------------------------
SELECT pg_temp.qui_foyer('d2a00000-0000-4000-8000-0000000000b1','teacher',NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.mes_seances_v
                      WHERE session_id = 'd2a00000-0000-4000-8000-000000000501'
                        AND teacher_country = 'Côte d''Ivoire') = 2,
  'enseignante : sa seance porte son pays');
RESET ROLE;

UPDATE public.teacher_profiles SET deleted_at = now()
 WHERE profile_id = 'd2a00000-0000-4000-8000-0000000000b1';
SELECT pg_temp.qui_foyer('d2a00000-0000-4000-8000-0000000000d1','guardian','d2a00000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.mes_seances_v
                      WHERE session_id = 'd2a00000-0000-4000-8000-000000000501'
                        AND teacher_country IS NULL) = 2,
  'profil enseignant retire : la seance reste, sans pays');
RESET ROLE;

\ir _acl_retablir.sql

DO $fin$
BEGIN
  IF current_setting('test.r_n')::int <> 20 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 20 attendus', current_setting('test.r_n');
  END IF;
  RAISE NOTICE 'DRAPEAUX : % controles verts', current_setting('test.r_n');
END $fin$;

ROLLBACK;
