-- PLAN-DE-CLASSE A (lot 5, 13/11/2026). Migration 20261124600000.
-- Chaque enchainement de gestes a sa transaction (BEGIN ... ROLLBACK), avec sa
-- propre fixture : trois classes ouvertes sans etape, des membres deja la, un
-- programme publie (les bases, d'un geste). Parties : 1 etape d'une classe
-- vivante ; 2 refus ; 3 date d'entree ; 4 placement date ; 5 qui n'a pas d'etape
-- et le rattachement ; 6 l'impasse du brouillon ; 7 droits.
-- Echoue sans la migration. Tout est annule.
\o /dev/null

-- ======================================================================
-- 1. Donner une etape a une classe deja ouverte
-- ======================================================================
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
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
  $$ SELECT pg_catalog.md5('plan-classe-a-' || p)::uuid $$;
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;
CREATE TEMP TABLE pc_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON pc_ids TO authenticated, anon;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text) TO authenticated, anon;

INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pc-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','t1','e1','e2','e3','e5','e6','x1']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f3'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'PC', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PC-ADM-01','admin',NULL,'Direction'),
   ('b1','PC-ENS-01','teacher',NULL,'Titulaire'),
   ('t1','PC-TUT-01','guardian','f1','Tutrice'),
   ('x1','PC-ENS-02','teacher',NULL,'Autre'),
   ('e1','PC-ELV-01','student','f1','Eleve un'),
   ('e2','PC-ELV-02','student','f1','Eleve deux'),
   ('e3','PC-TIT-03','guardian','f3','Adulte'),
   ('e5','PC-ELV-05','student','f1','Eleve cinq'),
   ('e6','PC-ELV-06','student','f1','Eleve six')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte) VALUES
  (pg_temp.u('e1'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e2'), 'minor', 'standard', 'enfant_10_13'),
  (pg_temp.u('e5'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e6'), 'minor', 'child', 'enfant_6_9');
INSERT INTO public.student_profiles(profile_id, titulaire_profile_id, student_type, interface_mode, cohorte, niveau_declare)
VALUES (pg_temp.u('e3'), pg_temp.u('e3'), 'autonomous', 'standard', 'adulte_18_plus', 'lecture_courante');
-- Inscrits depuis 60 jours (les bornes de la date d'entree en dependent).
UPDATE public.profiles SET created_at = pg_catalog.now() - interval '60 days'
 WHERE id IN (pg_temp.u('e1'), pg_temp.u('e2'), pg_temp.u('e3'), pg_temp.u('e5'), pg_temp.u('e6'));

-- Trois classes ouvertes sans etape (avant toute publication), des membres
-- deja la ; e6 est sorti de sa classe.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 5, 'An-Nour PC', 1, 18, 'America/Toronto'),
 (pg_temp.u('c2'), pg_temp.u('b1'), 'adulte', 6, 'Al-Huda PC', 2, 19, 'America/Toronto'),
 (pg_temp.u('c3'), pg_temp.u('b1'), 'enfant', 5, 'Ar-Rahma PC', 3, 17, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 (pg_temp.u('c1'), pg_temp.u('e1'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e2'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c2'), pg_temp.u('e3'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e6'), pg_catalog.now() - interval '40 days');
UPDATE public.groupe_membres SET left_at = pg_catalog.now() - interval '10 days',
       left_by = pg_temp.u('a1'), left_reason = 'depart'
 WHERE student_id = pg_temp.u('e6');

-- Programme publie par la direction (les bases d'un geste, puis la publication).
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('v1', public.repartir_des_bases_programme());
SELECT public.publier_version_programme((SELECT id FROM pc_ids WHERE cle = 'v1'), 'fixture');
RESET ROLE;
INSERT INTO pc_ids SELECT 'n' || n.ordre, n.id FROM public.programme_niveaux n
 WHERE n.version_id = (SELECT id FROM pc_ids WHERE cle = 'v1');
CREATE TEMP TABLE pc_notif AS SELECT pg_catalog.count(*) AS n FROM public.notifications;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
RESET ROLE;
SELECT pg_temp.vrai(
  (public.niveau_classe_direction(pg_temp.u('c1')) ->> 'niveau_id') IS NULL
  AND (public.niveau_classe_direction(pg_temp.u('c1')) ->> 'membres_sans_etape')::int = 2,
  'avant : la classe n''a pas d''etape, ses deux membres non plus (la fiche le dit)');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE pc_r(cle text PRIMARY KEY, j jsonb);
GRANT ALL ON pc_r TO authenticated;
INSERT INTO pc_r VALUES ('c1', public.donner_niveau_classe(pg_temp.u('c1'),
  (SELECT id FROM pc_ids WHERE cle = 'n2'), 'La classe est a la deuxieme etape'));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT programme_niveau_id FROM public.groupes WHERE id = pg_temp.u('c1')) = (SELECT id FROM pc_ids WHERE cle = 'n2'),
  'la classe vivante porte l''etape 2 choisie');
SELECT pg_temp.vrai(
  (SELECT j FROM pc_r WHERE cle = 'c1') = '{"eleves_places": 2, "eleves_en_attente": 0}'::jsonb,
  'les deux membres debutants sans etape en recoivent une (compte rendu)');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.eleve_etape_en_cours f
    WHERE f.student_id IN (pg_temp.u('e1'), pg_temp.u('e2'))
      AND f.niveau_id = (SELECT id FROM pc_ids WHERE cle = 'n1') AND f.origine = 'classe'
      AND f.entree_etape_le = pg_catalog.now()::date) = 2,
  'un debutant entre a l''etape 1 (jamais celle de la classe), datee du jour du geste, une seule fois chacun');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e6')),
  'un eleve sorti de la classe n''est pas touche');
SET LOCAL ROLE authenticated;
-- Rejouer le geste (autre etape) ne remplace aucune etape d'eleve et n'en duplique aucune.
INSERT INTO pc_r VALUES ('c1bis', public.donner_niveau_classe(pg_temp.u('c1'),
  (SELECT id FROM pc_ids WHERE cle = 'n3'), 'Passage de la classe'));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT j FROM pc_r WHERE cle = 'c1bis') = '{"eleves_places": 0, "eleves_en_attente": 0}'::jsonb
  AND (SELECT programme_niveau_id FROM public.groupes WHERE id = pg_temp.u('c1')) = (SELECT id FROM pc_ids WHERE cle = 'n3')
  AND (SELECT pg_catalog.count(*) FROM public.eleve_etape_en_cours WHERE student_id IN (pg_temp.u('e1'), pg_temp.u('e2'))) = 2
  AND (SELECT pg_catalog.count(*) FROM public.eleve_etape_en_cours WHERE niveau_id = (SELECT id FROM pc_ids WHERE cle = 'n1')
        AND student_id IN (pg_temp.u('e1'), pg_temp.u('e2'))) = 2,
  'le geste rejoue : la classe change d''etape, les eleves gardent la leur, aucun doublon');
SET LOCAL ROLE authenticated;
-- Une classe d'adultes dont le membre declare deja lire : il attend l'entretien.
INSERT INTO pc_r VALUES ('c2', public.donner_niveau_classe(pg_temp.u('c2'),
  (SELECT id FROM pc_ids WHERE cle = 'n1'), 'Premiere etape'));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT j FROM pc_r WHERE cle = 'c2') = '{"eleves_places": 0, "eleves_en_attente": 1}'::jsonb
  AND NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e3')),
  'un membre qui declare deja lire n''a pas d''etape supposee : il attend la decision de la direction');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.audit_logs WHERE action = 'classe_niveau_donne') = 3
  AND (SELECT payload ->> 'motif' FROM public.audit_logs WHERE action = 'classe_niveau_donne'
        ORDER BY created_at DESC, id DESC LIMIT 1) = 'Premiere etape',
  'chaque geste est trace au journal, motif compris');;
RESET ROLE;

SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.notifications) = (SELECT n FROM pc_notif),
  'aucune notification n''est creee par ces gestes (aucun message vers un enfant)');

ROLLBACK;

-- ======================================================================
-- 2. Refus : droits, etape non publiee, classe close, motif
-- ======================================================================
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
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
  $$ SELECT pg_catalog.md5('plan-classe-a-' || p)::uuid $$;
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;
CREATE TEMP TABLE pc_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON pc_ids TO authenticated, anon;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text) TO authenticated, anon;

INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pc-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','t1','e1','e2','e3','e5','e6','x1']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f3'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'PC', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PC-ADM-01','admin',NULL,'Direction'),
   ('b1','PC-ENS-01','teacher',NULL,'Titulaire'),
   ('t1','PC-TUT-01','guardian','f1','Tutrice'),
   ('x1','PC-ENS-02','teacher',NULL,'Autre'),
   ('e1','PC-ELV-01','student','f1','Eleve un'),
   ('e2','PC-ELV-02','student','f1','Eleve deux'),
   ('e3','PC-TIT-03','guardian','f3','Adulte'),
   ('e5','PC-ELV-05','student','f1','Eleve cinq'),
   ('e6','PC-ELV-06','student','f1','Eleve six')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte) VALUES
  (pg_temp.u('e1'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e2'), 'minor', 'standard', 'enfant_10_13'),
  (pg_temp.u('e5'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e6'), 'minor', 'child', 'enfant_6_9');
INSERT INTO public.student_profiles(profile_id, titulaire_profile_id, student_type, interface_mode, cohorte, niveau_declare)
VALUES (pg_temp.u('e3'), pg_temp.u('e3'), 'autonomous', 'standard', 'adulte_18_plus', 'lecture_courante');
-- Inscrits depuis 60 jours (les bornes de la date d'entree en dependent).
UPDATE public.profiles SET created_at = pg_catalog.now() - interval '60 days'
 WHERE id IN (pg_temp.u('e1'), pg_temp.u('e2'), pg_temp.u('e3'), pg_temp.u('e5'), pg_temp.u('e6'));

-- Trois classes ouvertes sans etape (avant toute publication), des membres
-- deja la ; e6 est sorti de sa classe.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 5, 'An-Nour PC', 1, 18, 'America/Toronto'),
 (pg_temp.u('c2'), pg_temp.u('b1'), 'adulte', 6, 'Al-Huda PC', 2, 19, 'America/Toronto'),
 (pg_temp.u('c3'), pg_temp.u('b1'), 'enfant', 5, 'Ar-Rahma PC', 3, 17, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 (pg_temp.u('c1'), pg_temp.u('e1'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e2'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c2'), pg_temp.u('e3'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e6'), pg_catalog.now() - interval '40 days');
UPDATE public.groupe_membres SET left_at = pg_catalog.now() - interval '10 days',
       left_by = pg_temp.u('a1'), left_reason = 'depart'
 WHERE student_id = pg_temp.u('e6');

-- Programme publie par la direction (les bases d'un geste, puis la publication).
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('v1', public.repartir_des_bases_programme());
SELECT public.publier_version_programme((SELECT id FROM pc_ids WHERE cle = 'v1'), 'fixture');
RESET ROLE;
INSERT INTO pc_ids SELECT 'n' || n.ordre, n.id FROM public.programme_niveaux n
 WHERE n.version_id = (SELECT id FROM pc_ids WHERE cle = 'v1');
CREATE TEMP TABLE pc_notif AS SELECT pg_catalog.count(*) AS n FROM public.notifications;

SELECT pg_temp.qui(pg_temp.u('x1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.donner_niveau_classe(''' || pg_temp.u('c1') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n1') || ''', ''x'')') = 'refus',
  'un enseignant ne donne pas d''etape a une classe');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.donner_niveau_classe(''' || pg_temp.u('c1') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n1') || ''', ''x'')') = 'refus',
  'un eleve ne donne pas d''etape a une classe');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.niveau_classe_direction(''' || pg_temp.u('c1') || ''')') = 'refus',
  'un tuteur ne lit pas la fiche de direction d''une classe');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.donner_niveau_classe(''' || pg_temp.u('c1') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n1') || ''', ''x'')') = 'refus',
  'anon refuse');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('v2', public.creer_version_programme(NULL));
INSERT INTO pc_ids VALUES ('nb', public.ajouter_niveau_programme((SELECT id FROM pc_ids WHERE cle='v2'), 'brouillon-x', 'Brouillon', 'Cycle', 1, NULL));
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.donner_niveau_classe(''' || pg_temp.u('c1') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='nb') || ''', ''x'')') = 'niveau_non_publie',
  'une etape de brouillon n''est jamais donnee a une classe');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.donner_niveau_classe(''' || pg_temp.u('c1') || ''', ''' || gen_random_uuid() || ''', ''x'')') = 'niveau_non_publie',
  'une etape inconnue est refusee');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.donner_niveau_classe(''' || pg_temp.u('c1') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n1') || ''', ''   '')') = 'motif_obligatoire',
  'sans motif : refus');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.donner_niveau_classe(''' || gen_random_uuid() || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n1') || ''', ''x'')') = 'classe_introuvable',
  'classe inconnue : refus');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT programme_niveau_id FROM public.groupes WHERE id = pg_temp.u('c1')) IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours), 'aucun refus n''a rien ecrit');;
RESET ROLE;

UPDATE public.groupes SET ended_at = pg_catalog.now(), ended_by = pg_temp.u('a1'), end_reason = 'essai'
 WHERE id = pg_temp.u('c3');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.donner_niveau_classe(''' || pg_temp.u('c3') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n1') || ''', ''x'')') = 'classe_close',
  'une classe close ne recoit pas d''etape');;
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 3. Date d'entree d'un eleve deja en cours
-- ======================================================================
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
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
  $$ SELECT pg_catalog.md5('plan-classe-a-' || p)::uuid $$;
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;
CREATE TEMP TABLE pc_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON pc_ids TO authenticated, anon;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text) TO authenticated, anon;

INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pc-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','t1','e1','e2','e3','e5','e6','x1']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f3'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'PC', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PC-ADM-01','admin',NULL,'Direction'),
   ('b1','PC-ENS-01','teacher',NULL,'Titulaire'),
   ('t1','PC-TUT-01','guardian','f1','Tutrice'),
   ('x1','PC-ENS-02','teacher',NULL,'Autre'),
   ('e1','PC-ELV-01','student','f1','Eleve un'),
   ('e2','PC-ELV-02','student','f1','Eleve deux'),
   ('e3','PC-TIT-03','guardian','f3','Adulte'),
   ('e5','PC-ELV-05','student','f1','Eleve cinq'),
   ('e6','PC-ELV-06','student','f1','Eleve six')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte) VALUES
  (pg_temp.u('e1'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e2'), 'minor', 'standard', 'enfant_10_13'),
  (pg_temp.u('e5'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e6'), 'minor', 'child', 'enfant_6_9');
INSERT INTO public.student_profiles(profile_id, titulaire_profile_id, student_type, interface_mode, cohorte, niveau_declare)
VALUES (pg_temp.u('e3'), pg_temp.u('e3'), 'autonomous', 'standard', 'adulte_18_plus', 'lecture_courante');
-- Inscrits depuis 60 jours (les bornes de la date d'entree en dependent).
UPDATE public.profiles SET created_at = pg_catalog.now() - interval '60 days'
 WHERE id IN (pg_temp.u('e1'), pg_temp.u('e2'), pg_temp.u('e3'), pg_temp.u('e5'), pg_temp.u('e6'));

-- Trois classes ouvertes sans etape (avant toute publication), des membres
-- deja la ; e6 est sorti de sa classe.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 5, 'An-Nour PC', 1, 18, 'America/Toronto'),
 (pg_temp.u('c2'), pg_temp.u('b1'), 'adulte', 6, 'Al-Huda PC', 2, 19, 'America/Toronto'),
 (pg_temp.u('c3'), pg_temp.u('b1'), 'enfant', 5, 'Ar-Rahma PC', 3, 17, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 (pg_temp.u('c1'), pg_temp.u('e1'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e2'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c2'), pg_temp.u('e3'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e6'), pg_catalog.now() - interval '40 days');
UPDATE public.groupe_membres SET left_at = pg_catalog.now() - interval '10 days',
       left_by = pg_temp.u('a1'), left_reason = 'depart'
 WHERE student_id = pg_temp.u('e6');

-- Programme publie par la direction (les bases d'un geste, puis la publication).
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('v1', public.repartir_des_bases_programme());
SELECT public.publier_version_programme((SELECT id FROM pc_ids WHERE cle = 'v1'), 'fixture');
RESET ROLE;
INSERT INTO pc_ids SELECT 'n' || n.ordre, n.id FROM public.programme_niveaux n
 WHERE n.version_id = (SELECT id FROM pc_ids WHERE cle = 'v1');
CREATE TEMP TABLE pc_notif AS SELECT pg_catalog.count(*) AS n FROM public.notifications;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.donner_niveau_classe(pg_temp.u('c1'), (SELECT id FROM pc_ids WHERE cle='n1'), 'Premiere etape');
CREATE TEMP TABLE pc_r(cle text PRIMARY KEY, j jsonb);
GRANT ALL ON pc_r TO authenticated;
INSERT INTO pc_r VALUES ('d1', public.dater_entree_etape(pg_temp.u('e1'), (pg_catalog.now() AT TIME ZONE 'UTC')::date - 20, 'Il a commence le mois dernier'));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.entree_etape_le = (pg_catalog.now() AT TIME ZONE 'UTC')::date - 20
          AND f.entree_niveau_le = f.entree_etape_le
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e1')),
  'la date d''entree devient la date passee (etape et niveau)');;
RESET ROLE;

SELECT pg_temp.vrai(
  (SELECT d.date_limite = ((pg_catalog.now() AT TIME ZONE 'UTC')::date - 20) + 70 AND d.date_limite_semaines = 10
     FROM private.dates_etape(pg_temp.u('e1')) d)
  AND (SELECT j ->> 'date_limite' = (((pg_catalog.now() AT TIME ZONE 'UTC')::date - 20) + 70)::text FROM pc_r WHERE cle = 'd1'),
  'la date limite (10 semaines, 6-9 ans) se calcule depuis cette date, et le geste la rend');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
-- Une seconde date plus recente : l'entree dans l'etape recule, celle du niveau reste.
SELECT public.dater_entree_etape(pg_temp.u('e1'), (pg_catalog.now() AT TIME ZONE 'UTC')::date - 5, 'Date corrigee');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.entree_etape_le = (pg_catalog.now() AT TIME ZONE 'UTC')::date - 5
          AND f.entree_niveau_le = (pg_catalog.now() AT TIME ZONE 'UTC')::date - 20
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e1')),
  'une date plus recente : l''entree dans l''etape change, l''entree dans le niveau reste la plus ancienne');
SET LOCAL ROLE authenticated;
-- Bornes
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''UTC'')::date + 1), ''x'')') = 'date_future',
  'jamais dans le futur');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''UTC'')::date - 61), ''x'')') LIKE 'date_avant_inscription%',
  'jamais avant l''inscription (inscrit il y a 60 jours : le 61e est refuse)');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''UTC'')::date - 60), ''x'')') = 'ok',
  'le jour de l''inscription est permis');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', NULL, ''x'')') = 'date_obligatoire', 'date obligatoire');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''UTC'')::date - 3), '' '')') = 'motif_obligatoire', 'motif obligatoire');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e3') || ''', ((now() AT TIME ZONE ''UTC'')::date - 3), ''x'')') = 'eleve_sans_etape',
  'un eleve sans etape (il attend l''entretien) ne se date pas : on le place d''abord');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.entree_etape_le = (pg_catalog.now() AT TIME ZONE 'UTC')::date - 60 FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e1')),
  'seul le dernier geste accepte a ecrit (les refus n''ont rien change)');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.audit_logs WHERE action = 'entree_etape_datee') = 3
  AND (SELECT payload ->> 'ancienne_entree' FROM public.audit_logs WHERE action = 'entree_etape_datee'
        ORDER BY created_at, id LIMIT 1) = ((pg_catalog.now() AT TIME ZONE 'UTC')::date)::text,
  'chaque datation est tracee : ancienne date, nouvelle date, motif');;
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('x1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''UTC'')::date - 3), ''x'')') = 'refus',
  'un enseignant ne date pas l''entree d''un eleve');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''UTC'')::date - 3), ''x'')') = 'refus',
  'l''eleve ne date pas sa propre entree');
SELECT pg_temp.vrai(
  (public.etape_eleve_lecture(pg_temp.u('e1')) #>> '{etape,date_limite}') IS NULL
  AND (public.etape_eleve_lecture(pg_temp.u('e1')) #>> '{niveau,horizon}') IS NULL,
  'l''enfant de 6 a 9 ans ne voit toujours ni date limite ni horizon, meme date dans le passe');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.etape_eleve_lecture(pg_temp.u('e1')) #>> '{etape,date_limite}')::date = ((pg_catalog.now() AT TIME ZONE 'UTC')::date - 60) + 70,
  'son tuteur recoit la date limite');
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 4. Placement du diagnostic avec la date du vrai debut
-- ======================================================================
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
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
  $$ SELECT pg_catalog.md5('plan-classe-a-' || p)::uuid $$;
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;
CREATE TEMP TABLE pc_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON pc_ids TO authenticated, anon;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text) TO authenticated, anon;

INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pc-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','t1','e1','e2','e3','e5','e6','x1']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f3'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'PC', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PC-ADM-01','admin',NULL,'Direction'),
   ('b1','PC-ENS-01','teacher',NULL,'Titulaire'),
   ('t1','PC-TUT-01','guardian','f1','Tutrice'),
   ('x1','PC-ENS-02','teacher',NULL,'Autre'),
   ('e1','PC-ELV-01','student','f1','Eleve un'),
   ('e2','PC-ELV-02','student','f1','Eleve deux'),
   ('e3','PC-TIT-03','guardian','f3','Adulte'),
   ('e5','PC-ELV-05','student','f1','Eleve cinq'),
   ('e6','PC-ELV-06','student','f1','Eleve six')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte) VALUES
  (pg_temp.u('e1'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e2'), 'minor', 'standard', 'enfant_10_13'),
  (pg_temp.u('e5'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e6'), 'minor', 'child', 'enfant_6_9');
INSERT INTO public.student_profiles(profile_id, titulaire_profile_id, student_type, interface_mode, cohorte, niveau_declare)
VALUES (pg_temp.u('e3'), pg_temp.u('e3'), 'autonomous', 'standard', 'adulte_18_plus', 'lecture_courante');
-- Inscrits depuis 60 jours (les bornes de la date d'entree en dependent).
UPDATE public.profiles SET created_at = pg_catalog.now() - interval '60 days'
 WHERE id IN (pg_temp.u('e1'), pg_temp.u('e2'), pg_temp.u('e3'), pg_temp.u('e5'), pg_temp.u('e6'));

-- Trois classes ouvertes sans etape (avant toute publication), des membres
-- deja la ; e6 est sorti de sa classe.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 5, 'An-Nour PC', 1, 18, 'America/Toronto'),
 (pg_temp.u('c2'), pg_temp.u('b1'), 'adulte', 6, 'Al-Huda PC', 2, 19, 'America/Toronto'),
 (pg_temp.u('c3'), pg_temp.u('b1'), 'enfant', 5, 'Ar-Rahma PC', 3, 17, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 (pg_temp.u('c1'), pg_temp.u('e1'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e2'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c2'), pg_temp.u('e3'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e6'), pg_catalog.now() - interval '40 days');
UPDATE public.groupe_membres SET left_at = pg_catalog.now() - interval '10 days',
       left_by = pg_temp.u('a1'), left_reason = 'depart'
 WHERE student_id = pg_temp.u('e6');

-- Programme publie par la direction (les bases d'un geste, puis la publication).
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('v1', public.repartir_des_bases_programme());
SELECT public.publier_version_programme((SELECT id FROM pc_ids WHERE cle = 'v1'), 'fixture');
RESET ROLE;
INSERT INTO pc_ids SELECT 'n' || n.ordre, n.id FROM public.programme_niveaux n
 WHERE n.version_id = (SELECT id FROM pc_ids WHERE cle = 'v1');
CREATE TEMP TABLE pc_notif AS SELECT pg_catalog.count(*) AS n FROM public.notifications;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement_depuis(''' || pg_temp.u('e5') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n3') || ''', ''Entretien'', ((now() AT TIME ZONE ''UTC'')::date + 2))') = 'date_future',
  'date future : refusee');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement_depuis(''' || pg_temp.u('e5') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n3') || ''', ''Entretien'', ((now() AT TIME ZONE ''UTC'')::date - 90))') LIKE 'date_avant_inscription%',
  'avant l''inscription : refusee');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.progression_historique WHERE student_id = pg_temp.u('e5'))
  AND NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e5')),
  'une date refusee n''ecrit aucun placement (rien a moitie)');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('p1', public.decider_placement_depuis(pg_temp.u('e5'), (SELECT id FROM pc_ids WHERE cle='n3'), 'Entretien de lecture', (pg_catalog.now() AT TIME ZONE 'UTC')::date - 14));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.niveau_id = (SELECT id FROM pc_ids WHERE cle='n3')
          AND f.entree_etape_le = (pg_catalog.now() AT TIME ZONE 'UTC')::date - 14
          AND f.origine = 'decision'
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e5'))
  AND EXISTS (SELECT 1 FROM public.progression_historique h WHERE h.id = (SELECT id FROM pc_ids WHERE cle='p1')),
  'placement a l''etape 3, commence il y a 14 jours, decision au journal de progression');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement_depuis(''' || pg_temp.u('e5') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n2') || ''', ''Encore'', NULL)') LIKE '%deja un niveau decide%',
  'un eleve deja decide passe toujours par Progression (meme refus)');
-- Sans date : le geste d'avant (le jour meme).
INSERT INTO pc_ids VALUES ('p2', public.decider_placement_depuis(pg_temp.u('e2'), (SELECT id FROM pc_ids WHERE cle='n2'), 'Entretien', NULL));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.entree_etape_le = (pg_catalog.now() AT TIME ZONE 'UTC')::date FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e2')),
  'sans date : l''entree est le jour du geste, comme avant');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.audit_logs WHERE action = 'entree_etape_datee') = 1,
  'la datation du placement est tracee (et seulement quand une date est donnee)');;
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('x1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement_depuis(''' || pg_temp.u('e6') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n1') || ''', ''x'', NULL)') = 'refus',
  'un enseignant ne decide pas un placement');
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 5. Qui n'a pas d'etape, pourquoi, et le rattachement
-- ======================================================================
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
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
  $$ SELECT pg_catalog.md5('plan-classe-a-' || p)::uuid $$;
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;
CREATE TEMP TABLE pc_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON pc_ids TO authenticated, anon;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text) TO authenticated, anon;

INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pc-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','t1','e1','e2','e3','e5','e6','x1']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f3'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'PC', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PC-ADM-01','admin',NULL,'Direction'),
   ('b1','PC-ENS-01','teacher',NULL,'Titulaire'),
   ('t1','PC-TUT-01','guardian','f1','Tutrice'),
   ('x1','PC-ENS-02','teacher',NULL,'Autre'),
   ('e1','PC-ELV-01','student','f1','Eleve un'),
   ('e2','PC-ELV-02','student','f1','Eleve deux'),
   ('e3','PC-TIT-03','guardian','f3','Adulte'),
   ('e5','PC-ELV-05','student','f1','Eleve cinq'),
   ('e6','PC-ELV-06','student','f1','Eleve six')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte) VALUES
  (pg_temp.u('e1'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e2'), 'minor', 'standard', 'enfant_10_13'),
  (pg_temp.u('e5'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e6'), 'minor', 'child', 'enfant_6_9');
INSERT INTO public.student_profiles(profile_id, titulaire_profile_id, student_type, interface_mode, cohorte, niveau_declare)
VALUES (pg_temp.u('e3'), pg_temp.u('e3'), 'autonomous', 'standard', 'adulte_18_plus', 'lecture_courante');
-- Inscrits depuis 60 jours (les bornes de la date d'entree en dependent).
UPDATE public.profiles SET created_at = pg_catalog.now() - interval '60 days'
 WHERE id IN (pg_temp.u('e1'), pg_temp.u('e2'), pg_temp.u('e3'), pg_temp.u('e5'), pg_temp.u('e6'));

-- Trois classes ouvertes sans etape (avant toute publication), des membres
-- deja la ; e6 est sorti de sa classe.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 5, 'An-Nour PC', 1, 18, 'America/Toronto'),
 (pg_temp.u('c2'), pg_temp.u('b1'), 'adulte', 6, 'Al-Huda PC', 2, 19, 'America/Toronto'),
 (pg_temp.u('c3'), pg_temp.u('b1'), 'enfant', 5, 'Ar-Rahma PC', 3, 17, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 (pg_temp.u('c1'), pg_temp.u('e1'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e2'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c2'), pg_temp.u('e3'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e6'), pg_catalog.now() - interval '40 days');
UPDATE public.groupe_membres SET left_at = pg_catalog.now() - interval '10 days',
       left_by = pg_temp.u('a1'), left_reason = 'depart'
 WHERE student_id = pg_temp.u('e6');

-- Programme publie par la direction (les bases d'un geste, puis la publication).
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('v1', public.repartir_des_bases_programme());
SELECT public.publier_version_programme((SELECT id FROM pc_ids WHERE cle = 'v1'), 'fixture');
RESET ROLE;
INSERT INTO pc_ids SELECT 'n' || n.ordre, n.id FROM public.programme_niveaux n
 WHERE n.version_id = (SELECT id FROM pc_ids WHERE cle = 'v1');
CREATE TEMP TABLE pc_notif AS SELECT pg_catalog.count(*) AS n FROM public.notifications;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE pc_r(cle text PRIMARY KEY, j jsonb);
GRANT ALL ON pc_r TO authenticated;
INSERT INTO pc_r VALUES ('avant', public.eleves_sans_etape());
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT j ->> 'programme_publie' FROM pc_r WHERE cle='avant') = 'true'
  AND (SELECT pg_catalog.jsonb_array_length(j -> 'classes_sans_niveau') FROM pc_r WHERE cle='avant') = 3
  AND (SELECT pg_catalog.jsonb_array_length(j -> 'eleves') FROM pc_r WHERE cle='avant') = 3,
  'avant : 3 classes sans etape ; 3 eleves membres sans etape (le sorti n''est pas compte)');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM pc_r, jsonb_array_elements(j -> 'eleves') x
    WHERE cle='avant' AND x ->> 'raison' = 'debutant_a_rattacher') = 2
  AND (SELECT x ->> 'raison' FROM pc_r, jsonb_array_elements(j -> 'eleves') x
        WHERE cle='avant' AND x ->> 'student_id' = pg_temp.u('e3')::text) = 'attente_entretien',
  'deux debutants a rattacher, un adulte qui declare lire : attente de l''entretien');
SET LOCAL ROLE authenticated;
INSERT INTO pc_r VALUES ('geste', public.rattacher_eleves_et_classes());;
RESET ROLE;

SELECT pg_temp.vrai(
  (SELECT j FROM pc_r WHERE cle='geste') = '{"classes": 3, "eleves": 2}'::jsonb
  AND NOT EXISTS (SELECT 1 FROM public.groupes WHERE ended_at IS NULL AND programme_niveau_id IS NULL),
  'le rattachement rend les comptes et donne l''etape 1 a toutes les classes ouvertes');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_r VALUES ('apres', public.eleves_sans_etape());
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.jsonb_array_length(j -> 'eleves') FROM pc_r WHERE cle='apres') = 1
  AND (SELECT j -> 'eleves' -> 0 ->> 'student_id' FROM pc_r WHERE cle='apres') = pg_temp.u('e3')::text
  AND (SELECT j -> 'eleves' -> 0 ->> 'raison' FROM pc_r WHERE cle='apres') = 'attente_entretien'
  AND (SELECT pg_catalog.jsonb_array_length(j -> 'classes_sans_niveau') FROM pc_r WHERE cle='apres') = 0,
  'apres : il ne reste que l''adulte qui attend l''entretien, aucune classe sans etape');
SET LOCAL ROLE authenticated;
INSERT INTO pc_r VALUES ('rejoue', public.rattacher_eleves_et_classes());
RESET ROLE;
SELECT pg_temp.vrai((SELECT j FROM pc_r WHERE cle='rejoue') = '{"classes": 0, "eleves": 0}'::jsonb
  AND (SELECT pg_catalog.count(*) FROM public.eleve_etape_en_cours) = 2,
  'rejoue : rien n''est ajoute ni remplace');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.audit_logs WHERE action = 'programme_rattachement') = 2,
  'chaque rattachement est trace');;
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('x1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.rattacher_eleves_et_classes()') = 'refus'
  AND pg_temp.essai('SELECT public.eleves_sans_etape()') = 'refus', 'un enseignant ne voit ni ne rattache');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.eleves_sans_etape()') = 'refus', 'anon refuse');
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 5 bis. Sans programme publie : la raison le dit, le rattachement refuse
-- ======================================================================
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
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
  $$ SELECT pg_catalog.md5('plan-classe-a-' || p)::uuid $$;
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;
CREATE TEMP TABLE pc_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON pc_ids TO authenticated, anon;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text) TO authenticated, anon;

INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pc-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','t1','e1','e2','e3','e5','e6','x1']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f3'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'PC', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PC-ADM-01','admin',NULL,'Direction'),
   ('b1','PC-ENS-01','teacher',NULL,'Titulaire'),
   ('t1','PC-TUT-01','guardian','f1','Tutrice'),
   ('x1','PC-ENS-02','teacher',NULL,'Autre'),
   ('e1','PC-ELV-01','student','f1','Eleve un'),
   ('e2','PC-ELV-02','student','f1','Eleve deux'),
   ('e3','PC-TIT-03','guardian','f3','Adulte'),
   ('e5','PC-ELV-05','student','f1','Eleve cinq'),
   ('e6','PC-ELV-06','student','f1','Eleve six')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte) VALUES
  (pg_temp.u('e1'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e2'), 'minor', 'standard', 'enfant_10_13'),
  (pg_temp.u('e5'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e6'), 'minor', 'child', 'enfant_6_9');
INSERT INTO public.student_profiles(profile_id, titulaire_profile_id, student_type, interface_mode, cohorte, niveau_declare)
VALUES (pg_temp.u('e3'), pg_temp.u('e3'), 'autonomous', 'standard', 'adulte_18_plus', 'lecture_courante');
-- Inscrits depuis 60 jours (les bornes de la date d'entree en dependent).
UPDATE public.profiles SET created_at = pg_catalog.now() - interval '60 days'
 WHERE id IN (pg_temp.u('e1'), pg_temp.u('e2'), pg_temp.u('e3'), pg_temp.u('e5'), pg_temp.u('e6'));

-- Trois classes ouvertes sans etape (avant toute publication), des membres
-- deja la ; e6 est sorti de sa classe.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 5, 'An-Nour PC', 1, 18, 'America/Toronto'),
 (pg_temp.u('c2'), pg_temp.u('b1'), 'adulte', 6, 'Al-Huda PC', 2, 19, 'America/Toronto'),
 (pg_temp.u('c3'), pg_temp.u('b1'), 'enfant', 5, 'Ar-Rahma PC', 3, 17, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 (pg_temp.u('c1'), pg_temp.u('e1'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e2'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c2'), pg_temp.u('e3'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e6'), pg_catalog.now() - interval '40 days');
UPDATE public.groupe_membres SET left_at = pg_catalog.now() - interval '10 days',
       left_by = pg_temp.u('a1'), left_reason = 'depart'
 WHERE student_id = pg_temp.u('e6');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM jsonb_array_elements(public.eleves_sans_etape() -> 'eleves') x WHERE x ->> 'raison' = 'aucun_programme') = 3
  AND (public.eleves_sans_etape() ->> 'programme_publie') = 'false',
  'sans version publiee : tous les eleves sont « aucun programme publie »');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.rattacher_eleves_et_classes()') = 'aucun_programme_publie',
  'rattacher sans programme publie : refus');;
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 6. L'impasse du brouillon rempli a la main
-- ======================================================================
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
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
  $$ SELECT pg_catalog.md5('plan-classe-a-' || p)::uuid $$;
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;
CREATE TEMP TABLE pc_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON pc_ids TO authenticated, anon;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text) TO authenticated, anon;

INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pc-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','t1','e1','e2','e3','e5','e6','x1']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f3'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'PC', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PC-ADM-01','admin',NULL,'Direction'),
   ('b1','PC-ENS-01','teacher',NULL,'Titulaire'),
   ('t1','PC-TUT-01','guardian','f1','Tutrice'),
   ('x1','PC-ENS-02','teacher',NULL,'Autre'),
   ('e1','PC-ELV-01','student','f1','Eleve un'),
   ('e2','PC-ELV-02','student','f1','Eleve deux'),
   ('e3','PC-TIT-03','guardian','f3','Adulte'),
   ('e5','PC-ELV-05','student','f1','Eleve cinq'),
   ('e6','PC-ELV-06','student','f1','Eleve six')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte) VALUES
  (pg_temp.u('e1'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e2'), 'minor', 'standard', 'enfant_10_13'),
  (pg_temp.u('e5'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e6'), 'minor', 'child', 'enfant_6_9');
INSERT INTO public.student_profiles(profile_id, titulaire_profile_id, student_type, interface_mode, cohorte, niveau_declare)
VALUES (pg_temp.u('e3'), pg_temp.u('e3'), 'autonomous', 'standard', 'adulte_18_plus', 'lecture_courante');
-- Inscrits depuis 60 jours (les bornes de la date d'entree en dependent).
UPDATE public.profiles SET created_at = pg_catalog.now() - interval '60 days'
 WHERE id IN (pg_temp.u('e1'), pg_temp.u('e2'), pg_temp.u('e3'), pg_temp.u('e5'), pg_temp.u('e6'));

-- Trois classes ouvertes sans etape (avant toute publication), des membres
-- deja la ; e6 est sorti de sa classe.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 5, 'An-Nour PC', 1, 18, 'America/Toronto'),
 (pg_temp.u('c2'), pg_temp.u('b1'), 'adulte', 6, 'Al-Huda PC', 2, 19, 'America/Toronto'),
 (pg_temp.u('c3'), pg_temp.u('b1'), 'enfant', 5, 'Ar-Rahma PC', 3, 17, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 (pg_temp.u('c1'), pg_temp.u('e1'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e2'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c2'), pg_temp.u('e3'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e6'), pg_catalog.now() - interval '40 days');
UPDATE public.groupe_membres SET left_at = pg_catalog.now() - interval '10 days',
       left_by = pg_temp.u('a1'), left_reason = 'depart'
 WHERE student_id = pg_temp.u('e6');

-- Programme publie par la direction (les bases d'un geste, puis la publication).
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('v1', public.repartir_des_bases_programme());
SELECT public.publier_version_programme((SELECT id FROM pc_ids WHERE cle = 'v1'), 'fixture');
RESET ROLE;
INSERT INTO pc_ids SELECT 'n' || n.ordre, n.id FROM public.programme_niveaux n
 WHERE n.version_id = (SELECT id FROM pc_ids WHERE cle = 'v1');
CREATE TEMP TABLE pc_notif AS SELECT pg_catalog.count(*) AS n FROM public.notifications;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
-- Un brouillon rempli a la main, incomplet : la raison vient du serveur.
INSERT INTO pc_ids VALUES ('vh', public.creer_version_programme(NULL));
INSERT INTO pc_ids VALUES ('nh', public.ajouter_niveau_programme((SELECT id FROM pc_ids WHERE cle='vh'), 'lecture-x', 'Lecture', 'Cycle', 1, NULL));
CREATE TEMP TABLE pc_r(cle text PRIMARY KEY, j jsonb);
GRANT ALL ON pc_r TO authenticated;
INSERT INTO pc_r VALUES ('h1', public.etat_publication_brouillon((SELECT id FROM pc_ids WHERE cle='vh')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT j ->> 'peut_publier' FROM pc_r WHERE cle='h1') = 'false'
  AND (SELECT j ->> 'raison' FROM pc_r WHERE cle='h1') = 'incomplet'
  AND (SELECT j ->> 'detail' FROM pc_r WHERE cle='h1') = 'Lecture',
  'brouillon incomplet : le serveur dit « incomplet » et nomme l''etape');
SELECT pg_temp.vrai(
  (SELECT statut FROM public.programme_versions WHERE id = (SELECT id FROM pc_ids WHERE cle='vh')) = 'brouillon'
  AND (SELECT statut FROM public.programme_versions WHERE id = (SELECT id FROM pc_ids WHERE cle='v1')) = 'publiee'
  AND (SELECT pg_catalog.count(*) FROM public.programme_versions WHERE statut = 'publiee') = 1,
  'l''essai n''a rien publie ni archive (la version publiee reste en place)');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.preremplir_bases_programme(''' || (SELECT id FROM pc_ids WHERE cle='vh') || ''')') LIKE 'version_non_vide%',
  'l''impasse existe bien : le brouillon rempli ne se preremplit pas');
-- La sortie : repartir des bases, sans toucher le brouillon.
INSERT INTO pc_ids VALUES ('vn', public.repartir_des_bases_programme());
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT id FROM pc_ids WHERE cle='vn') <> (SELECT id FROM pc_ids WHERE cle='vh')
  AND (SELECT pg_catalog.count(*) FROM public.programme_niveaux WHERE version_id = (SELECT id FROM pc_ids WHERE cle='vn')) = 4
  AND (SELECT pg_catalog.count(*) FROM public.programme_niveaux WHERE version_id = (SELECT id FROM pc_ids WHERE cle='vh')) = 1
  AND (SELECT statut FROM public.programme_versions WHERE id = (SELECT id FROM pc_ids WHERE cle='vn')) = 'brouillon',
  'repartir des bases : une version neuve de 4 etapes ; le brouillon a la main reste tel quel, jamais touche');
SELECT pg_temp.vrai((public.etat_publication_brouillon((SELECT id FROM pc_ids WHERE cle='vn')) ->> 'peut_publier') = 'true',
  'la version neuve se publie (le serveur le dit)');
SET LOCAL ROLE authenticated;
SELECT public.publier_version_programme((SELECT id FROM pc_ids WHERE cle='vn'), 'Repartir des bases');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT statut FROM public.programme_versions WHERE id = (SELECT id FROM pc_ids WHERE cle='vn')) = 'publiee'
  AND (SELECT statut FROM public.programme_versions WHERE id = (SELECT id FROM pc_ids WHERE cle='v1')) = 'archivee'
  AND (SELECT statut FROM public.programme_versions WHERE id = (SELECT id FROM pc_ids WHERE cle='vh')) = 'brouillon',
  'publiee : la precedente est archivee, le brouillon ancien reste un brouillon');
SELECT pg_temp.vrai((public.etat_publication_brouillon((SELECT id FROM pc_ids WHERE cle='vn')) ->> 'raison') = 'non_brouillon'
  AND (public.etat_publication_brouillon(gen_random_uuid()) ->> 'raison') = 'introuvable',
  'une version publiee et une version inconnue ont leur raison');;
RESET ROLE;

RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 6 bis. Brouillon incoherent (sommes des etapes) et sans bases
-- ======================================================================
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
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
  $$ SELECT pg_catalog.md5('plan-classe-a-' || p)::uuid $$;
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;
CREATE TEMP TABLE pc_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON pc_ids TO authenticated, anon;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text) TO authenticated, anon;

INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pc-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','t1','e1','e2','e3','e5','e6','x1']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f3'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'PC', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PC-ADM-01','admin',NULL,'Direction'),
   ('b1','PC-ENS-01','teacher',NULL,'Titulaire'),
   ('t1','PC-TUT-01','guardian','f1','Tutrice'),
   ('x1','PC-ENS-02','teacher',NULL,'Autre'),
   ('e1','PC-ELV-01','student','f1','Eleve un'),
   ('e2','PC-ELV-02','student','f1','Eleve deux'),
   ('e3','PC-TIT-03','guardian','f3','Adulte'),
   ('e5','PC-ELV-05','student','f1','Eleve cinq'),
   ('e6','PC-ELV-06','student','f1','Eleve six')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte) VALUES
  (pg_temp.u('e1'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e2'), 'minor', 'standard', 'enfant_10_13'),
  (pg_temp.u('e5'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e6'), 'minor', 'child', 'enfant_6_9');
INSERT INTO public.student_profiles(profile_id, titulaire_profile_id, student_type, interface_mode, cohorte, niveau_declare)
VALUES (pg_temp.u('e3'), pg_temp.u('e3'), 'autonomous', 'standard', 'adulte_18_plus', 'lecture_courante');
-- Inscrits depuis 60 jours (les bornes de la date d'entree en dependent).
UPDATE public.profiles SET created_at = pg_catalog.now() - interval '60 days'
 WHERE id IN (pg_temp.u('e1'), pg_temp.u('e2'), pg_temp.u('e3'), pg_temp.u('e5'), pg_temp.u('e6'));

-- Trois classes ouvertes sans etape (avant toute publication), des membres
-- deja la ; e6 est sorti de sa classe.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 5, 'An-Nour PC', 1, 18, 'America/Toronto'),
 (pg_temp.u('c2'), pg_temp.u('b1'), 'adulte', 6, 'Al-Huda PC', 2, 19, 'America/Toronto'),
 (pg_temp.u('c3'), pg_temp.u('b1'), 'enfant', 5, 'Ar-Rahma PC', 3, 17, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 (pg_temp.u('c1'), pg_temp.u('e1'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e2'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c2'), pg_temp.u('e3'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e6'), pg_catalog.now() - interval '40 days');
UPDATE public.groupe_membres SET left_at = pg_catalog.now() - interval '10 days',
       left_by = pg_temp.u('a1'), left_reason = 'depart'
 WHERE student_id = pg_temp.u('e6');

-- Programme publie par la direction (les bases d'un geste, puis la publication).
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('v1', public.repartir_des_bases_programme());
SELECT public.publier_version_programme((SELECT id FROM pc_ids WHERE cle = 'v1'), 'fixture');
RESET ROLE;
INSERT INTO pc_ids SELECT 'n' || n.ordre, n.id FROM public.programme_niveaux n
 WHERE n.version_id = (SELECT id FROM pc_ids WHERE cle = 'v1');
CREATE TEMP TABLE pc_notif AS SELECT pg_catalog.count(*) AS n FROM public.notifications;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('vc', public.creer_version_programme(NULL));
SELECT public.preremplir_bases_programme((SELECT id FROM pc_ids WHERE cle='vc'));
RESET ROLE;
SELECT pg_temp.vrai((public.etat_publication_brouillon((SELECT id FROM pc_ids WHERE cle='vc')) ->> 'peut_publier') = 'true', 'bases pre-remplies : publiable');;
RESET ROLE;

UPDATE public.programme_niveaux SET durees = jsonb_set(durees, '{adulte_18_plus,limite}', '99'::jsonb)
 WHERE version_id = (SELECT id FROM pc_ids WHERE cle='vc') AND code_technique = 'BASES-1';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
RESET ROLE;
SELECT pg_temp.vrai(
  (public.etat_publication_brouillon((SELECT id FROM pc_ids WHERE cle='vc')) ->> 'raison') = 'incoherent'
  AND (public.etat_publication_brouillon((SELECT id FROM pc_ids WHERE cle='vc')) ->> 'peut_publier') = 'false',
  'sommes qui ne font plus le niveau : « incoherent »');
SELECT pg_temp.vrai(
  (SELECT statut FROM public.programme_versions WHERE id = (SELECT id FROM pc_ids WHERE cle='vc')) = 'brouillon'
  AND (SELECT statut FROM public.programme_versions WHERE id = (SELECT id FROM pc_ids WHERE cle='v1')) = 'publiee',
  'aucun effet de l''essai');;
RESET ROLE;

-- Etapes sans niveau (cycle_code nul) : « sans bases »
UPDATE public.programme_niveaux SET cycle_code = NULL
 WHERE version_id = (SELECT id FROM pc_ids WHERE cle='vc') AND code_technique = 'BASES-2';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
RESET ROLE;
SELECT pg_temp.vrai((public.etat_publication_brouillon((SELECT id FROM pc_ids WHERE cle='vc')) ->> 'raison') = 'sans_bases',
  'une etape hors du niveau des bases : « sans bases »');;
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('x1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.repartir_des_bases_programme()') = 'refus'
  AND pg_temp.essai('SELECT public.etat_publication_brouillon(''' || gen_random_uuid() || ''')') = 'refus',
  'un enseignant ne repart pas des bases et ne lit pas l''etat d''un brouillon');
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 7. Droits : deux chemins, DEFINER, search_path vide
-- ======================================================================
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
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
  $$ SELECT pg_catalog.md5('plan-classe-a-' || p)::uuid $$;
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;
CREATE TEMP TABLE pc_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON pc_ids TO authenticated, anon;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text) TO authenticated, anon;

INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pc-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','t1','e1','e2','e3','e5','e6','x1']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f3'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'PC', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PC-ADM-01','admin',NULL,'Direction'),
   ('b1','PC-ENS-01','teacher',NULL,'Titulaire'),
   ('t1','PC-TUT-01','guardian','f1','Tutrice'),
   ('x1','PC-ENS-02','teacher',NULL,'Autre'),
   ('e1','PC-ELV-01','student','f1','Eleve un'),
   ('e2','PC-ELV-02','student','f1','Eleve deux'),
   ('e3','PC-TIT-03','guardian','f3','Adulte'),
   ('e5','PC-ELV-05','student','f1','Eleve cinq'),
   ('e6','PC-ELV-06','student','f1','Eleve six')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte) VALUES
  (pg_temp.u('e1'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e2'), 'minor', 'standard', 'enfant_10_13'),
  (pg_temp.u('e5'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e6'), 'minor', 'child', 'enfant_6_9');
INSERT INTO public.student_profiles(profile_id, titulaire_profile_id, student_type, interface_mode, cohorte, niveau_declare)
VALUES (pg_temp.u('e3'), pg_temp.u('e3'), 'autonomous', 'standard', 'adulte_18_plus', 'lecture_courante');
-- Inscrits depuis 60 jours (les bornes de la date d'entree en dependent).
UPDATE public.profiles SET created_at = pg_catalog.now() - interval '60 days'
 WHERE id IN (pg_temp.u('e1'), pg_temp.u('e2'), pg_temp.u('e3'), pg_temp.u('e5'), pg_temp.u('e6'));

-- Trois classes ouvertes sans etape (avant toute publication), des membres
-- deja la ; e6 est sorti de sa classe.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 5, 'An-Nour PC', 1, 18, 'America/Toronto'),
 (pg_temp.u('c2'), pg_temp.u('b1'), 'adulte', 6, 'Al-Huda PC', 2, 19, 'America/Toronto'),
 (pg_temp.u('c3'), pg_temp.u('b1'), 'enfant', 5, 'Ar-Rahma PC', 3, 17, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 (pg_temp.u('c1'), pg_temp.u('e1'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e2'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c2'), pg_temp.u('e3'), pg_catalog.now() - interval '30 days'),
 (pg_temp.u('c1'), pg_temp.u('e6'), pg_catalog.now() - interval '40 days');
UPDATE public.groupe_membres SET left_at = pg_catalog.now() - interval '10 days',
       left_by = pg_temp.u('a1'), left_reason = 'depart'
 WHERE student_id = pg_temp.u('e6');

-- Programme publie par la direction (les bases d'un geste, puis la publication).
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('v1', public.repartir_des_bases_programme());
SELECT public.publier_version_programme((SELECT id FROM pc_ids WHERE cle = 'v1'), 'fixture');
RESET ROLE;
INSERT INTO pc_ids SELECT 'n' || n.ordre, n.id FROM public.programme_niveaux n
 WHERE n.version_id = (SELECT id FROM pc_ids WHERE cle = 'v1');
CREATE TEMP TABLE pc_notif AS SELECT pg_catalog.count(*) AS n FROM public.notifications;

SELECT pg_temp.vrai((
  SELECT bool_and(
           NOT pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       AND NOT pg_catalog.has_function_privilege('public', p.oid, 'EXECUTE')
       AND pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       AND p.prosecdef AND coalesce(p.proconfig @> ARRAY['search_path=""'], false))
    FROM pg_catalog.pg_proc p
   WHERE p.oid = ANY (ARRAY[
     'public.donner_niveau_classe(uuid, uuid, text)'::regprocedure,
     'public.niveau_classe_direction(uuid)'::regprocedure,
     'public.dater_entree_etape(uuid, date, text)'::regprocedure,
     'public.decider_placement_depuis(uuid, uuid, text, date)'::regprocedure,
     'public.eleves_sans_etape()'::regprocedure,
     'public.rattacher_eleves_et_classes()'::regprocedure,
     'public.etat_publication_brouillon(uuid)'::regprocedure,
     'public.repartir_des_bases_programme()'::regprocedure])),
  'huit fonctions : DEFINER, search_path vide, rien pour anon ni PUBLIC, EXECUTE a authenticated');
SELECT pg_temp.vrai((
  SELECT NOT pg_catalog.has_function_privilege('authenticated', 'private.fixer_entree_etape(uuid, date)', 'EXECUTE')
     AND NOT pg_catalog.has_function_privilege('anon', 'private.fixer_entree_etape(uuid, date)', 'EXECUTE')),
  'l''aide privee n''est ouverte a personne');

ROLLBACK;
\o
SELECT 'scenarios_plan_de_classe_a : tous les controles sont verts' AS resultat;
