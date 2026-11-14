-- PLAN-DE-CLASSE A (lot 5, 13/11/2026). Migration 20261125700000.
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
INSERT INTO pc_r VALUES ('d1', public.dater_entree_etape(pg_temp.u('e1'), (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 20, 'Il a commence le mois dernier'));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.entree_etape_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 20
          AND f.entree_niveau_le = f.entree_etape_le
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e1')),
  'la date d''entree devient la date passee (etape et niveau)');;
RESET ROLE;

SELECT pg_temp.vrai(
  (SELECT d.date_limite = ((pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 20) + 70 AND d.date_limite_semaines = 10
     FROM private.dates_etape(pg_temp.u('e1')) d)
  AND (SELECT j ->> 'date_limite' = (((pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 20) + 70)::text FROM pc_r WHERE cle = 'd1'),
  'la date limite (10 semaines, 6-9 ans) se calcule depuis cette date, et le geste la rend');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
-- Une date reposee REMPLACE la precedente : l'entree dans le niveau suit quand
-- elle coincide avec l'entree dans l'etape (elle n'est pas collante).
SELECT public.dater_entree_etape(pg_temp.u('e1'), (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 5, 'Date corrigee');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.entree_etape_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 5
          AND f.entree_niveau_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 5
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e1')),
  'une date reposee remplace la premiere : etape et niveau suivent (jamais une date fausse collee)');
SET LOCAL ROLE authenticated;
-- Bornes
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date + 1), ''x'')') = 'date_future',
  'jamais dans le futur');
RESET ROLE;
SELECT pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'programme.date_debut_plancher_annees') = pg_catalog.to_jsonb(10),
  'le plancher est un reglage, dix ans par defaut');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - 61), ''x'')') = 'ok',
  'un jour AVANT la creation du compte (inscrit il y a 60 jours) est accepte : l''academie enseignait avant l''application');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''10 years'' - interval ''1 day'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  'sous le plancher (dix ans) : refuse, le message donne le plus ancien jour accepte');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''10 years'')::date, ''x'')') = 'ok',
  'pile au plancher : accepte');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', NULL, ''x'')') = 'date_obligatoire', 'date obligatoire');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - 3), '' '')') = 'motif_obligatoire', 'motif obligatoire');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e3') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - 3), ''x'')') = 'eleve_sans_etape',
  'un eleve sans etape (il attend l''entretien) ne se date pas : on le place d''abord');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.entree_etape_le = ((pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - interval '10 years')::date FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e1')),
  'seul le dernier geste accepte a ecrit (les refus n''ont rien change)');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.audit_logs WHERE action = 'entree_etape_datee') = 4
  AND (SELECT payload ->> 'ancienne_entree' FROM public.audit_logs WHERE action = 'entree_etape_datee'
        ORDER BY created_at, id LIMIT 1) = (pg_catalog.now()::date)::text,
  'chaque datation est tracee : ancienne date, nouvelle date, motif');;
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('x1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - 3), ''x'')') = 'refus',
  'un enseignant ne date pas l''entree d''un eleve');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - 3), ''x'')') = 'refus',
  'l''eleve ne date pas sa propre entree');
SELECT pg_temp.vrai(
  (public.etape_eleve_lecture(pg_temp.u('e1')) #>> '{etape,date_limite}') IS NULL
  AND (public.etape_eleve_lecture(pg_temp.u('e1')) #>> '{niveau,horizon}') IS NULL,
  'l''enfant de 6 a 9 ans ne voit toujours ni date limite ni horizon, meme date dans le passe');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.etape_eleve_lecture(pg_temp.u('e1')) #>> '{etape,date_limite}')::date = (((pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - interval '10 years')::date) + 70,
  'son tuteur recoit la date limite');
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 3 bis. Le plancher est un reglage
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
SELECT public.donner_niveau_classe(pg_temp.u('c1'), (SELECT id FROM pc_ids WHERE cle='n1'), 'Premiere etape');;
RESET ROLE;

UPDATE public.app_config SET value = pg_catalog.to_jsonb(1) WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - 400), ''x'')') LIKE 'date_sous_plancher: %',
  'plancher regle a un an : un jour de il y a 400 jours est refuse');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - 300), ''x'')') = 'ok',
  'plancher regle a un an : un jour de il y a 300 jours est accepte');;
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 3 ter. Une date reposee remplace la precedente, dans les deux sens
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
SELECT public.dater_entree_etape(pg_temp.u('e1'), (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 100, 'Faute de frappe');
SELECT public.dater_entree_etape(pg_temp.u('e1'), (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 10, 'Corrigee');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.entree_etape_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 10
          AND f.entree_niveau_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 10
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e1')),
  'pose a -100 puis corrigee a -10 : l''entree dans le niveau n''est plus a -100');
SET LOCAL ROLE authenticated;
SELECT public.dater_entree_etape(pg_temp.u('e1'), (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 200, 'Dans l''autre sens');
SELECT public.dater_entree_etape(pg_temp.u('e1'), (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 5, 'Et revenue');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.entree_etape_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 5
          AND f.entree_niveau_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 5
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e1')),
  'dans l''autre sens aussi : -200 puis -5, l''entree dans le niveau suit');;
RESET ROLE;

-- Un eleve monte d'une etape precedente du niveau (entree dans le niveau plus
-- ancienne que l'entree dans l'etape) et un recul du lot 2.
UPDATE public.eleve_etape_en_cours
   SET entree_niveau_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 300,
       entree_etape_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 20,
       recul_jours = 7
 WHERE student_id = pg_temp.u('e1');
CREATE TEMP TABLE pc_recul AS SELECT recul_jours AS r FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e1');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.dater_entree_etape(pg_temp.u('e1'), (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 5, 'Date de la montee');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.entree_etape_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 5
          AND f.entree_niveau_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 300
          AND f.recul_jours = (SELECT r FROM pc_recul)
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e1')),
  'monte d''une etape precedente : l''entree dans le niveau reste ; recul_jours n''est jamais touche par ces gestes (7 avec le lot 1 seul, derive par le lot 2 sinon)');
SET LOCAL ROLE authenticated;
SELECT public.dater_entree_etape(pg_temp.u('e1'), (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 400, 'Avant la montee');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.entree_niveau_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 400 FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e1')),
  'une date qui precede l''entree dans le niveau l''abaisse (jamais d''etape avant son niveau)');;
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 4 bis. Adulte titulaire a placer, apercu de la date limite, jour de l'academie
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
  (SELECT x ->> 'raison' FROM jsonb_array_elements(public.eleves_sans_etape() -> 'eleves') x
    WHERE x ->> 'student_id' = pg_temp.u('e3')::text) = 'attente_entretien',
  'l''adulte titulaire en attente d''entretien est dans la liste');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement_depuis(''' || pg_temp.u('t1') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n2') || ''', ''Essai'', NULL)') = 'cet eleve n''existe pas ou son compte n''est pas valide',
  'un tuteur qui n''est pas eleve ne se place jamais');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement(''' || pg_temp.u('e3') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n2') || ''', ''Essai'')') = 'cet eleve n''existe pas ou son compte n''est pas valide',
  'la fonction de main reste inchangee : elle ne place que le role eleve');
INSERT INTO pc_ids VALUES ('p3', public.decider_placement_depuis(pg_temp.u('e3'), (SELECT id FROM pc_ids WHERE cle='n2'), 'Entretien de lecture', (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 30));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.niveau_id = (SELECT id FROM pc_ids WHERE cle='n2') AND f.origine = 'decision'
          AND f.entree_etape_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 30
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e3'))
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(public.eleves_sans_etape() -> 'eleves') x
                   WHERE x ->> 'student_id' = pg_temp.u('e3')::text),
  'l''adulte titulaire est place a l''etape 2, date de son vrai debut, et sort de la liste');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement_depuis(''' || pg_temp.u('e3') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n1') || ''', ''Encore'', NULL)') LIKE '%deja un niveau decide%',
  'une seconde decision passe par Progression');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement_depuis(''' || pg_temp.u('e5') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n1') || ''', '' '', NULL)') = 'un motif est requis pour decider un placement',
  'motif obligatoire, meme phrase que la fonction de main');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.audit_logs WHERE action = 'placement_decide') = 1,
  'le placement de l''adulte est trace comme celui d''un eleve');
SET LOCAL ROLE authenticated;
-- Apercu de la date limite : le serveur calcule, le client non.
SELECT public.donner_niveau_classe(pg_temp.u('c1'), (SELECT id FROM pc_ids WHERE cle='n1'), 'Premiere etape');
CREATE TEMP TABLE pc_r(cle text PRIMARY KEY, j jsonb);
GRANT ALL ON pc_r TO authenticated;
INSERT INTO pc_r VALUES ('passee', public.apercu_date_limite(pg_temp.u('e1'), ((now() AT TIME ZONE 'Asia/Riyadh')::date - interval '3 years')::date));
INSERT INTO pc_r VALUES ('future', public.apercu_date_limite(pg_temp.u('e1'), (now() AT TIME ZONE 'Asia/Riyadh')::date));
INSERT INTO pc_r VALUES ('placement', public.apercu_date_limite(pg_temp.u('e5'), (now() AT TIME ZONE 'Asia/Riyadh')::date, (SELECT id FROM pc_ids WHERE cle='n3')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j ->> 'deja_passee')::boolean AND (j ->> 'semaines')::int = 10
          AND (j ->> 'date_limite')::date = (((now() AT TIME ZONE 'Asia/Riyadh')::date - interval '3 years')::date) + 70
     FROM pc_r WHERE cle = 'passee'),
  'trois ans en arriere sur un 6-9 ans : la date limite resultante est dite deja passee (calculee par le serveur)');
SELECT pg_temp.vrai(
  (SELECT NOT (j ->> 'deja_passee')::boolean AND (j ->> 'date_limite')::date = (now() AT TIME ZONE 'Asia/Riyadh')::date + 70 FROM pc_r WHERE cle = 'future'),
  'un debut aujourd''hui : date limite dans dix semaines, pas passee');
SELECT pg_temp.vrai(
  (SELECT (j ->> 'semaines')::int = (SELECT (n.durees -> 'enfant_6_9' ->> 'limite')::int FROM public.programme_niveaux n WHERE n.id = (SELECT id FROM pc_ids WHERE cle='n3'))
     FROM pc_r WHERE cle = 'placement'),
  'l''apercu d''un placement lit la duree de l''etape choisie, pour la tranche de l''eleve');
SELECT pg_temp.vrai(
  public.apercu_date_limite(pg_temp.u('e5'), NULL) ->> 'date_limite' IS NULL,
  'sans etape ni date : pas de date limite, pas d''erreur');
SELECT pg_temp.vrai(public.jour_academie_direction() = (now() AT TIME ZONE 'Asia/Riyadh')::date,
  'le jour de reference est celui de La Mecque, rendu par le serveur');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.audit_logs WHERE action = 'entree_etape_datee') = 1,
  'un apercu n''ecrit rien (ni date, ni journal : seul le placement date a ecrit)');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.progression_historique WHERE student_id = pg_temp.u('e5'))
  AND NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e5')),
  'l''apercu d''un placement ne laisse ni decision ni etape');
SET LOCAL ROLE authenticated;
INSERT INTO pc_r VALUES ('hors', public.apercu_date_limite(pg_temp.u('e1'), ((now() AT TIME ZONE 'Asia/Riyadh')::date + 1)));
INSERT INTO pc_r VALUES ('ancien', public.apercu_date_limite(pg_temp.u('e1'), ((now() AT TIME ZONE 'Asia/Riyadh')::date - interval '11 years')::date));
INSERT INTO pc_r VALUES ('sansetape', public.apercu_date_limite(pg_temp.u('e5'), (now() AT TIME ZONE 'Asia/Riyadh')::date));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT j ->> 'refus' = 'date_future' AND j ->> 'date_limite' IS NULL FROM pc_r WHERE cle = 'hors')
  AND (SELECT j ->> 'refus' = 'date_sous_plancher' AND j ->> 'date_limite' IS NULL FROM pc_r WHERE cle = 'ancien')
  AND (SELECT j ->> 'refus' = 'eleve_sans_etape' FROM pc_r WHERE cle = 'sansetape'),
  'un jour refuse par l''ecriture est refuse par l''apercu (le meme chemin), sans date');
SET LOCAL ROLE authenticated;
-- L'apercu est LE MEME calcul que l'ecriture : la date posee ensuite est celle annoncee.
SELECT public.dater_entree_etape(pg_temp.u('e1'), ((now() AT TIME ZONE 'Asia/Riyadh')::date - interval '3 years')::date, 'Jour annonce');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT d.date_limite FROM private.dates_etape(pg_temp.u('e1')) d)
    = (SELECT (j ->> 'date_limite')::date FROM pc_r WHERE cle = 'passee'),
  'la date limite apres l''ecriture est exactement celle de l''apercu');;
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('x1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.apercu_date_limite(''' || pg_temp.u('e1') || ''', current_date)') = 'refus'
  AND pg_temp.essai('SELECT public.jour_academie_direction()') = 'refus',
  'un enseignant ne lit ni l''apercu ni le jour de la direction');
RESET ROLE;
UPDATE public.profiles SET deleted_at = pg_catalog.now() WHERE id = pg_temp.u('e5');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement_depuis(''' || pg_temp.u('e5') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n1') || ''', ''x'', NULL)') = 'cet eleve n''existe pas ou son compte n''est pas valide',
  'un compte supprime ne se place pas');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', (now() AT TIME ZONE ''Asia/Riyadh'')::date, ''x'')') = 'ok',
  'avant la suppression de e1, la datation marche');;
RESET ROLE;

UPDATE public.profiles SET deleted_at = pg_catalog.now() WHERE id = pg_temp.u('e1');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', (now() AT TIME ZONE ''Asia/Riyadh'')::date, ''x'')') = 'eleve_introuvable',
  'un compte supprime ne se date pas');;
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 3 quater. Le reglage du plancher se lit sans jamais echouer
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
SELECT public.donner_niveau_classe(pg_temp.u('c1'), (SELECT id FROM pc_ids WHERE cle='n1'), 'Premiere etape');;
RESET ROLE;
UPDATE public.app_config SET value = '0'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''9 years'')::date, ''x'')') = 'ok'
  AND pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''11 years'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  'reglage zero : dix ans par defaut, jamais d''erreur brute');;
RESET ROLE;
UPDATE public.app_config SET value = '-5'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''9 years'')::date, ''x'')') = 'ok'
  AND pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''11 years'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  'reglage negatif : dix ans par defaut, jamais d''erreur brute');;
RESET ROLE;
UPDATE public.app_config SET value = '"abc"'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''9 years'')::date, ''x'')') = 'ok'
  AND pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''11 years'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  'reglage texte : dix ans par defaut, jamais d''erreur brute');;
RESET ROLE;
UPDATE public.app_config SET value = '2.5'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''9 years'')::date, ''x'')') = 'ok'
  AND pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''11 years'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  'reglage decimal : dix ans par defaut, jamais d''erreur brute');;
RESET ROLE;
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''9 years'')::date, ''x'')') = 'ok'
  AND pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''11 years'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  'reglage booleen : dix ans par defaut, jamais d''erreur brute');;
RESET ROLE;
UPDATE public.app_config SET value = '100000'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''9 years'')::date, ''x'')') = 'ok'
  AND pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''11 years'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  'reglage enorme : dix ans par defaut, jamais d''erreur brute');;
RESET ROLE;
UPDATE public.app_config SET value = 'null'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''9 years'')::date, ''x'')') = 'ok'
  AND pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''11 years'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  'reglage json null : dix ans par defaut, jamais d''erreur brute');;
RESET ROLE;
UPDATE public.app_config SET value = '51'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''9 years'')::date, ''x'')') = 'ok'
  AND pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''11 years'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  'reglage au-dessus de 50 : dix ans par defaut, jamais d''erreur brute');;
RESET ROLE;
UPDATE public.app_config SET value = '1e400'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''9 years'')::date, ''x'')') = 'ok'
  AND pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''11 years'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  'reglage exposant enorme : dix ans par defaut, jamais d''erreur brute');;
RESET ROLE;
UPDATE public.app_config SET value = '10.0'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''9 years'')::date, ''x'')') = 'ok'
  AND pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''11 years'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  'reglage dix point zero : dix ans par defaut, jamais d''erreur brute');;
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 3 quinquies. Bornes valides du reglage : 1 et 50
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
SELECT public.donner_niveau_classe(pg_temp.u('c1'), (SELECT id FROM pc_ids WHERE cle='n1'), 'Premiere etape');;
RESET ROLE;
UPDATE public.app_config SET value = '50'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''49 years'')::date, ''x'')') = 'ok',
  '50 ans : accepte');;
RESET ROLE;
UPDATE public.app_config SET value = '20.0'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''19 years'')::date, ''x'')') = 'ok'
  AND pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''21 years'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  '20.0 : un entier ecrit avec une virgule vaut 20 ans, sans erreur brute');;
RESET ROLE;
UPDATE public.app_config SET value = '1'::jsonb WHERE key = 'programme.date_debut_plancher_annees';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.dater_entree_etape(''' || pg_temp.u('e1') || ''', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''2 years'')::date, ''x'')') LIKE 'date_sous_plancher: %',
  '1 an : refuse au-dela');;
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 6 ter. Repartir des bases deux fois ne cree qu'un brouillon
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
INSERT INTO pc_ids VALUES ('b1', public.repartir_des_bases_programme());
INSERT INTO pc_ids VALUES ('b2', public.repartir_des_bases_programme());
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT id FROM pc_ids WHERE cle = 'b1') = (SELECT id FROM pc_ids WHERE cle = 'b2')
  AND (SELECT pg_catalog.count(*) FROM public.programme_versions WHERE statut = 'brouillon') = 1,
  'deux appels : le meme brouillon, aucun doublon');;
RESET ROLE;

UPDATE public.programme_niveaux SET objectifs = objectifs || ARRAY['un objectif de plus']
 WHERE version_id = (SELECT id FROM pc_ids WHERE cle = 'b1') AND code_technique = 'BASES-1';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('b3', public.repartir_des_bases_programme());
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT id FROM pc_ids WHERE cle = 'b3') <> (SELECT id FROM pc_ids WHERE cle = 'b1')
  AND (SELECT pg_catalog.count(*) FROM public.programme_versions WHERE statut = 'brouillon') = 2,
  'un brouillon des bases MODIFIE n''est pas rendu : on en cree un neuf');;
RESET ROLE;

UPDATE public.programme_cycles SET durees = jsonb_set(durees, '{adulte_18_plus,limite}', '21'::jsonb)
 WHERE version_id = (SELECT id FROM pc_ids WHERE cle = 'b3');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('b4', public.repartir_des_bases_programme());
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT id FROM pc_ids WHERE cle = 'b4') NOT IN (SELECT id FROM pc_ids WHERE cle IN ('b1','b3')),
  'un niveau modifie compte aussi : le brouillon n''est pas « intact »');;
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 4 ter. Un titulaire dont la fiche d'eleve est supprimee ne se place pas
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

INSERT INTO auth.users(id, email) VALUES (pg_temp.u('g2'), 'pc-g2@test.invalid');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.u('g2'), 'PC-TIT-04', 'guardian', pg_temp.u('f3'), 'Titulaire supprime', 'PC', 'active', 'female');
INSERT INTO public.student_profiles(profile_id, titulaire_profile_id, student_type, interface_mode, cohorte, niveau_declare)
VALUES (pg_temp.u('g2'), pg_temp.u('g2'), 'autonomous', 'standard', 'adulte_18_plus', 'lecture_courante');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement_depuis(''' || pg_temp.u('g2') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n2') || ''', ''x'', NULL)') = 'ok',
  'temoin : un titulaire adulte eleve autonome, fiche non supprimee, se place');;
RESET ROLE;

DELETE FROM public.progression_historique WHERE student_id = pg_temp.u('g2');
DELETE FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('g2');
UPDATE public.student_profiles SET deleted_at = pg_catalog.now() WHERE profile_id = pg_temp.u('g2');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement_depuis(''' || pg_temp.u('g2') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n2') || ''', ''x'', NULL)') = 'cet eleve n''existe pas ou son compte n''est pas valide',
  'la fiche d''eleve autonome supprimee : le titulaire ne se place plus');;
RESET ROLE;

ROLLBACK;

-- ======================================================================
-- 7. Avec le lot 2 (si installe) : l'apercu est le meme calcul que l'ecriture, recul compris
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
SELECT public.dater_entree_etape(pg_temp.u('e1'), (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date, 'Debut aujourd''hui');;
RESET ROLE;

DO $lot2$
DECLARE
  v_jour date := (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date;
  v_apercu jsonb;
  v_recul_avant integer;
  v_pose date;
BEGIN
  IF pg_catalog.to_regclass('public.calendrier_ecole') IS NULL THEN
    RAISE NOTICE 'OK lot 2 absent : ce controle est sans objet (recul_jours reste celui du lot 1)';
    RETURN;
  END IF;
  -- Une fermeture publiee de 7 jours, a venir : dans la fenetre de l'etape qui commence aujourd'hui.
  INSERT INTO public.calendrier_ecole(type, categorie, titre, du, au, portee, publie, publie_le)
  VALUES ('fermeture', 'autre', 'Fermeture d''essai', v_jour + 5, v_jour + 11, 'ecole', true, pg_catalog.now());
  UPDATE public.eleve_etape_en_cours SET maj_le = maj_le WHERE student_id = pg_temp.u('e1');
  SELECT recul_jours INTO v_recul_avant FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e1');
  IF v_recul_avant <> 7 THEN
    RAISE EXCEPTION 'ROUGE : fixture du lot 2 : le recul de la fermeture devrait etre 7, il vaut %', v_recul_avant;
  END IF;
  -- Un debut il y a 100 jours : la fermeture n'est plus dans la fenetre de l'etape, le
  -- recul d'ecriture tombe a 0. Un apercu qui reprendrait l'ANCIEN recul (7) mentirait.
  PERFORM pg_temp.qui(pg_temp.u('a1'), 'admin');
  v_apercu := public.apercu_date_limite(pg_temp.u('e1'), v_jour - 100);
  PERFORM public.dater_entree_etape(pg_temp.u('e1'), v_jour - 100, 'Debut annonce');
  SELECT d.date_limite INTO v_pose FROM private.dates_etape(pg_temp.u('e1')) d;
  IF (v_apercu ->> 'date_limite')::date IS DISTINCT FROM v_pose THEN
    RAISE EXCEPTION 'ROUGE : l''apercu (%) differe de la date reellement posee (%)', v_apercu ->> 'date_limite', v_pose;
  END IF;
  IF v_pose <> v_jour - 100 + 70 THEN
    RAISE EXCEPTION 'ROUGE : date posee inattendue % (attendu %)', v_pose, v_jour - 100 + 70;
  END IF;
  RAISE NOTICE 'OK avec le lot 2 : l''apercu annonce la date reellement posee (recul recalcule par le declencheur)';
END
$lot2$;

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
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement_depuis(''' || pg_temp.u('e5') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n3') || ''', ''Entretien'', ((now() AT TIME ZONE ''Asia/Riyadh'')::date + 2))') = 'date_future',
  'date future : refusee');
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.decider_placement_depuis(''' || pg_temp.u('e5') || ''', ''' || (SELECT id FROM pc_ids WHERE cle='n3') || ''', ''Entretien'', ((now() AT TIME ZONE ''Asia/Riyadh'')::date - interval ''11 years'')::date)') LIKE 'date_sous_plancher: %',
  'sous le plancher : refusee');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.progression_historique WHERE student_id = pg_temp.u('e5'))
  AND NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e5')),
  'une date refusee n''ecrit aucun placement (rien a moitie)');
SET LOCAL ROLE authenticated;
INSERT INTO pc_ids VALUES ('p1', public.decider_placement_depuis(pg_temp.u('e5'), (SELECT id FROM pc_ids WHERE cle='n3'), 'Entretien de lecture', (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 14));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT f.niveau_id = (SELECT id FROM pc_ids WHERE cle='n3')
          AND f.entree_etape_le = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date - 14
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
  (SELECT f.entree_etape_le = pg_catalog.now()::date FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e2')),
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
     'public.repartir_des_bases_programme()'::regprocedure,
     'public.apercu_date_limite(uuid, date, uuid)'::regprocedure,
     'public.jour_academie_direction()'::regprocedure])),
  'dix fonctions : DEFINER, search_path vide, rien pour anon ni PUBLIC, EXECUTE a authenticated');
SELECT pg_temp.vrai((
  SELECT NOT pg_catalog.has_function_privilege('authenticated', 'private.fixer_entree_etape(uuid, date)', 'EXECUTE')
     AND NOT pg_catalog.has_function_privilege('anon', 'private.fixer_entree_etape(uuid, date)', 'EXECUTE')),
  'l''aide privee n''est ouverte a personne');
SELECT pg_temp.vrai((
  SELECT NOT pg_catalog.has_function_privilege('authenticated', 'private.jour_academie()', 'EXECUTE')
     AND NOT pg_catalog.has_function_privilege('authenticated', 'private.plancher_date_debut()', 'EXECUTE')
     AND NOT pg_catalog.has_function_privilege('anon', 'private.jour_academie()', 'EXECUTE')
     AND NOT pg_catalog.has_function_privilege('authenticated', 'private.eleve_placable(uuid)', 'EXECUTE')
     AND NOT pg_catalog.has_function_privilege('authenticated', 'private.version_bases_intacte(uuid)', 'EXECUTE')),
  'le jour de l''academie et le plancher ne sont ouverts a personne');

ROLLBACK;
\o
SELECT 'scenarios_plan_de_classe_a : tous les controles sont verts' AS resultat;
