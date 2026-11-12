-- PARCOURS-INSCRITS (12/11/2026) : public.v_parcours_onboarding dit « affectee » pour un apprenant
-- membre actif d'une classe non terminee, meme sans intention d'horaire. Migration
-- 20261123810000_parcours_inscrits_affectee.sql. ROUGE sans elle ; VERT avec. Annule a la fin.
\o /dev/null
\o /dev/null
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
  $$ SELECT pg_catalog.md5('suivi-eleve-' || p)::uuid $$;

CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text) TO authenticated, anon;


INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pi-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','t1','t2','tb','e1','e2','e3','e4','e5','e6','e7']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f2'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'PI', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PI-ADM-01','admin',NULL,'Direction'),
   ('tb','PI-ENS-01','teacher',NULL,'Enseignante'),
   ('t1','PI-TUT-01','guardian','f1','Tutrice'),
   ('t2','PI-TUT-02','guardian','f2','Autre'),
   ('e1','PI-ELV-01','student','f1','Membre'),
   ('e2','PI-ELV-02','student','f1','Sans classe'),
   ('e3','PI-ELV-03','student','f1','Intention vivante'),
   ('e4','PI-ELV-04','student','f1','Intention et membre'),
   ('e5','PI-ELV-05','student','f1','Sorti'),
   ('e6','PI-ELV-06','student','f1','Classe terminee'),
   ('e7','PI-ELV-07','student','f2','Autre foyer')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode, 'enfant_6_9'
  FROM unnest(ARRAY['e1','e2','e3','e4','e5','e6','e7']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('tb'), 'enfant', 6, 'Classe vivante PI', 1, 18, 'America/Toronto'),
 (pg_temp.u('c2'), pg_temp.u('tb'), 'enfant', 6, 'Classe finie PI', 2, 18, 'America/Toronto'),
 (pg_temp.u('c3'), pg_temp.u('tb'), 'enfant', 6, 'Classe nouvelle PI', 3, 18, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id)
SELECT pg_temp.u('c1'), pg_temp.u(x) FROM unnest(ARRAY['e1','e4','e5','e7']) AS x;
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES (pg_temp.u('c2'), pg_temp.u('e6'));
UPDATE public.groupes SET ended_at = pg_catalog.now(), ended_by = pg_temp.u('a1'), end_reason = 'test' WHERE id = pg_temp.u('c2');
UPDATE public.groupe_membres SET left_at = pg_catalog.now(), left_by = pg_temp.u('a1'), left_reason = 'test'
 WHERE student_id = pg_temp.u('e5');
-- Une offre publiee, et deux intentions vivantes : e3 (sans classe) et e4 (deja membre).
INSERT INTO public.offres_horaires(id, type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes,
                                   etat, publiee_at, publiee_par)
SELECT pg_temp.u('o1'), 'enfant', l.code, 'America/Toronto', ARRAY[1,3]::smallint[], 18, 60, 'publiee',
       pg_catalog.now(), pg_temp.u('a1')
  FROM (SELECT code FROM public.langues_cours ORDER BY code LIMIT 1) l;
INSERT INTO public.intentions_horaire(eleve_id, offre_id, fuseau_affiche, heure_affichee, jours_affiches, etat, created_by)
SELECT pg_temp.u(x), pg_temp.u('o1'), 'America/Toronto', 18, ARRAY[1,3]::smallint[], 'enregistree', pg_temp.u('t1')
  FROM unnest(ARRAY['e3','e4']) AS x;
CREATE TEMP TABLE pi_sortie(eleve text PRIMARY KEY, etat text, groupe uuid, indispo boolean, fuseau boolean);
GRANT ALL ON pi_sortie TO authenticated;

-- 1. Le tuteur du foyer lit.
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO pi_sortie
SELECT x.k, v.intention_etat, v.groupe_id, v.offre_indisponible, v.fuseau_change
  FROM (VALUES ('e1'),('e2'),('e3'),('e4'),('e5'),('e6'),('e7')) AS x(k)
  LEFT JOIN public.v_parcours_onboarding v ON v.eleve_id = pg_temp.u(x.k);
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT etat = 'affectee' AND groupe = pg_temp.u('c1') FROM pi_sortie WHERE eleve = 'e1'),
  'membre actif sans intention : affectee, avec sa classe (le defaut corrige)');
SELECT pg_temp.vrai(
  (SELECT etat IS NULL AND groupe IS NULL FROM pi_sortie WHERE eleve = 'e2'),
  'sans classe ni intention : aucun etat (horaire a choisir cote ecran), inchange');
SELECT pg_temp.vrai(
  (SELECT etat = 'enregistree' AND groupe IS NULL FROM pi_sortie WHERE eleve = 'e3'),
  'intention vivante sans classe : l''etat de l''intention, inchange');
SELECT pg_temp.vrai(
  (SELECT etat = 'affectee' AND groupe = pg_temp.u('c1') AND indispo IS NOT TRUE AND fuseau IS NOT TRUE
     FROM pi_sortie WHERE eleve = 'e4'),
  'intention vivante ET membre actif : affectee, ni offre indisponible ni fuseau change');
SELECT pg_temp.vrai(
  (SELECT etat IS NULL AND groupe IS NULL FROM pi_sortie WHERE eleve = 'e5'),
  'membre sorti (left_at) : pas affectee');
SELECT pg_temp.vrai(
  (SELECT etat IS NULL AND groupe IS NULL FROM pi_sortie WHERE eleve = 'e6'),
  'classe terminee (ended_at) : pas affectee');
-- 2. La RLS joue toujours : l'autre foyer ne voit pas le foyer 1, ni l'inverse.
SELECT pg_temp.qui(pg_temp.u('t2'), 'guardian', pg_temp.u('f2'));
SET LOCAL ROLE authenticated;
SELECT pg_catalog.count(*) FILTER (WHERE v.eleve_id = pg_temp.u('e1')) AS voit_e1,
       pg_catalog.count(*) FILTER (WHERE v.eleve_id = pg_temp.u('e7')) AS voit_e7
  FROM public.v_parcours_onboarding v \gset autre_
RESET ROLE;
SELECT pg_temp.vrai(:autre_voit_e1 = 0, 'autre foyer : ne voit pas le membre du foyer 1');
SELECT pg_temp.vrai(:autre_voit_e7 = 1, 'autre foyer : voit son propre membre (affectee)');
-- 2 bis. Deux adhesions actives : impossible (index unique groupe_membres_actif_uidx), donc la
-- classe affichee ne peut pas varier d'une lecture a l'autre ; un transfert passe par la sortie
-- de l'ancienne classe (left_at), apres quoi la nouvelle est celle qui est rendue.
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format(
    'INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES (%L, %L)',
    pg_temp.u('c3'), pg_temp.u('e1'))) LIKE '%groupe_membres_actif_uidx%',
  'deux adhesions actives pour un meme eleve : refusees par l''index unique');
UPDATE public.groupe_membres SET left_at = pg_catalog.now(), left_by = pg_temp.u('a1'), left_reason = 'transfert'
 WHERE student_id = pg_temp.u('e1') AND left_at IS NULL;
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES (pg_temp.u('c3'), pg_temp.u('e1'));
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT v.groupe_id = pg_temp.u('c3') AND v.intention_etat = 'affectee'
     FROM public.v_parcours_onboarding v WHERE v.eleve_id = pg_temp.u('e1'))
  AND (SELECT pg_catalog.count(*) FROM public.v_parcours_onboarding v WHERE v.eleve_id = pg_temp.u('e1')) = 1,
  'apres transfert : une seule ligne, la nouvelle classe, stable');
RESET ROLE;
-- 3. Les colonnes et les droits.
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'v_parcours_onboarding') = 22,
  'la vue garde ses 22 colonnes');
SELECT pg_temp.vrai(
  NOT pg_catalog.has_table_privilege('anon', 'public.v_parcours_onboarding', 'SELECT')
  AND pg_catalog.has_table_privilege('authenticated', 'public.v_parcours_onboarding', 'SELECT')
  AND (SELECT 'security_invoker=true' = ANY (c.reloptions) FROM pg_catalog.pg_class c
        WHERE c.oid = 'public.v_parcours_onboarding'::pg_catalog.regclass),
  'droits d''avant (pas anon) et security_invoker conserve');
ROLLBACK;
