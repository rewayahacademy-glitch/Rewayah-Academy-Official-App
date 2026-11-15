-- COM-LISTER-FILS-ECONOME (15/11/2026) : la migration 20261127000200 ne change
-- ni le resultat de private.com_paires ni celui de public.com_lister_fils.
-- Methode : un etat « apres » (corps installe par la migration) et un etat
-- « avant » (corps de reference, ecrit ci-dessous tel qu'avant la migration)
-- sont compares sur les memes donnees, dans une transaction annulee.
-- A rejouer sur une base NEUVE apres toutes les migrations.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims',
    pg_catalog.json_build_object('app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

-- Fixtures : une Classe d'un eleve mineur, une Classe d'un adulte, un dossier,
-- un profil de paiement, des fils de chaque type, des messages.
INSERT INTO auth.users(id, email) VALUES
 ('e0000000-0000-4000-8000-0000000000a1','lf-admin@test.invalid'),
 ('e0000000-0000-4000-8000-0000000000a2','lf-compta@test.invalid'),
 ('e0000000-0000-4000-8000-0000000000b1','lf-t1@test.invalid'),
 ('e0000000-0000-4000-8000-0000000000b2','lf-t2@test.invalid'),
 ('e0000000-0000-4000-8000-0000000000d1','lf-g1@test.invalid'),
 ('e0000000-0000-4000-8000-0000000000d2','lf-g2@test.invalid'),
 ('e0000000-0000-4000-8000-0000000000e1','lf-e1@test.invalid'),
 ('e0000000-0000-4000-8000-0000000000e2','lf-e2@test.invalid'),
 ('e0000000-0000-4000-8000-0000000000e3','lf-e3@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('e0000000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('e0000000-0000-4000-8000-0000000000f2','Europe/Paris'),
 ('e0000000-0000-4000-8000-0000000000f3','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('e0000000-0000-4000-8000-0000000000a1','LF-ADM-0001','admin',NULL,'Direction','Lf','active','female'),
 ('e0000000-0000-4000-8000-0000000000a2','LF-CPT-0001','accountant',NULL,'Comptable','Lf','active','male'),
 ('e0000000-0000-4000-8000-0000000000b1','LF-ENS-0001','teacher',NULL,'Maryam','Lf','provisional_active','female'),
 ('e0000000-0000-4000-8000-0000000000b2','LF-ENS-0002','teacher',NULL,'Ibrahim','Lf','provisional_active','male'),
 ('e0000000-0000-4000-8000-0000000000d1','LF-TUT-0001','guardian','e0000000-0000-4000-8000-0000000000f1','Amina','Lf1','active','female'),
 ('e0000000-0000-4000-8000-0000000000d2','LF-TUT-0002','guardian','e0000000-0000-4000-8000-0000000000f2','Sara','Lf2','active','female'),
 ('e0000000-0000-4000-8000-0000000000e1','LF-ELV-0001','student','e0000000-0000-4000-8000-0000000000f1','Yasmine','Lf1','active','female'),
 ('e0000000-0000-4000-8000-0000000000e2','LF-ELV-0002','student','e0000000-0000-4000-8000-0000000000f2','Adam','Lf2','active','male'),
 ('e0000000-0000-4000-8000-0000000000e3','LF-ELV-0003','student','e0000000-0000-4000-8000-0000000000f3','Hamza','Adulte','active','male');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('e0000000-0000-4000-8000-0000000000e1','minor','standard'),
 ('e0000000-0000-4000-8000-0000000000e2','minor','child'),
 ('e0000000-0000-4000-8000-0000000000e3','autonomous','standard');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('e0000000-0000-4000-8000-0000000000c1','e0000000-0000-4000-8000-0000000000b1','enfant',5,'Lf Un',1,9,'Europe/Paris'),
 ('e0000000-0000-4000-8000-0000000000c2','e0000000-0000-4000-8000-0000000000b2','enfant',5,'Lf Deux',2,10,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES
 ('e0000000-0000-4000-8000-0000000000c1','e0000000-0000-4000-8000-0000000000e1'),
 ('e0000000-0000-4000-8000-0000000000c1','e0000000-0000-4000-8000-0000000000e3'),
 ('e0000000-0000-4000-8000-0000000000c2','e0000000-0000-4000-8000-0000000000e2');
INSERT INTO public.com_fils(id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id) VALUES
 ('e0000000-0000-4000-8000-0000000001a1','classe','e0000000-0000-4000-8000-0000000000c1','foyer','e0000000-0000-4000-8000-0000000000f1','profil','e0000000-0000-4000-8000-0000000000b1'),
 ('e0000000-0000-4000-8000-0000000001a2','classe','e0000000-0000-4000-8000-0000000000c1','foyer','e0000000-0000-4000-8000-0000000000f1','equipe',NULL),
 ('e0000000-0000-4000-8000-0000000001a3','classe','e0000000-0000-4000-8000-0000000000c1','profil','e0000000-0000-4000-8000-0000000000e3','profil','e0000000-0000-4000-8000-0000000000b1'),
 ('e0000000-0000-4000-8000-0000000001a4','classe','e0000000-0000-4000-8000-0000000000c2','profil','e0000000-0000-4000-8000-0000000000b2','equipe',NULL),
 ('e0000000-0000-4000-8000-0000000001a5','eleve','e0000000-0000-4000-8000-0000000000e2','foyer','e0000000-0000-4000-8000-0000000000f2','profil','e0000000-0000-4000-8000-0000000000b2'),
 ('e0000000-0000-4000-8000-0000000001a6','eleve','e0000000-0000-4000-8000-0000000000e3','profil','e0000000-0000-4000-8000-0000000000e3','profil','e0000000-0000-4000-8000-0000000000b1'),
 ('e0000000-0000-4000-8000-0000000001a7','dossier','e0000000-0000-4000-8000-0000000000b1','profil','e0000000-0000-4000-8000-0000000000b1','equipe',NULL),
 ('e0000000-0000-4000-8000-0000000001a8','profilPaiement','e0000000-0000-4000-8000-0000000000b2','profil','e0000000-0000-4000-8000-0000000000b2','equipe',NULL),
 ('e0000000-0000-4000-8000-0000000001a9','classe','e0000000-0000-4000-8000-0000000000c2','foyer','e0000000-0000-4000-8000-0000000000f2','equipe',NULL);
INSERT INTO public.com_messages(fil_id, auteur_id, cle_idempotence, texte) VALUES
 ('e0000000-0000-4000-8000-0000000001a1','e0000000-0000-4000-8000-0000000000d1','e0000000-0000-4000-8000-0000000002a1','Bonjour de la famille'),
 ('e0000000-0000-4000-8000-0000000001a1','e0000000-0000-4000-8000-0000000000b1','e0000000-0000-4000-8000-0000000002a2','Reponse de l enseignante'),
 ('e0000000-0000-4000-8000-0000000001a2','e0000000-0000-4000-8000-0000000000d1','e0000000-0000-4000-8000-0000000002a3','Question pour la direction'),
 ('e0000000-0000-4000-8000-0000000001a4','e0000000-0000-4000-8000-0000000000b2','e0000000-0000-4000-8000-0000000002a4','Note de l enseignant'),
 ('e0000000-0000-4000-8000-0000000001a5','e0000000-0000-4000-8000-0000000000b2','e0000000-0000-4000-8000-0000000002a5','Au sujet d Adam'),
 ('e0000000-0000-4000-8000-0000000001a7','e0000000-0000-4000-8000-0000000000b1','e0000000-0000-4000-8000-0000000002a6','Dossier a completer');

-- Etat « apres » (corps installe par la migration), pour chaque appelant.
CREATE TEMP TABLE apres_lister(qui text PRIMARY KEY, res jsonb);
CREATE TEMP TABLE avant_lister(qui text PRIMARY KEY, res jsonb);
CREATE TEMP TABLE apres_paires AS
  SELECT f.type_objet, f.objet_id, q.a_nature, q.a_id, q.b_nature, q.b_id
  FROM (SELECT 'classe' AS type_objet, id AS objet_id FROM public.groupes
        UNION ALL SELECT 'eleve', id FROM public.profiles WHERE role = 'student'
        UNION ALL SELECT 'dossier', id FROM public.profiles
        UNION ALL SELECT 'profilPaiement', id FROM public.profiles
        UNION ALL SELECT 'remplacement', id FROM public.profiles
        UNION ALL SELECT 'inconnu', id FROM public.profiles) f
  CROSS JOIN LATERAL private.com_paires(f.type_objet, f.objet_id) q;
CREATE TEMP TABLE callers(qui text, id uuid, role text);
INSERT INTO callers VALUES
 ('admin','e0000000-0000-4000-8000-0000000000a1','admin'),
 ('compta','e0000000-0000-4000-8000-0000000000a2','accountant'),
 ('ens1','e0000000-0000-4000-8000-0000000000b1','teacher'),
 ('ens2','e0000000-0000-4000-8000-0000000000b2','teacher'),
 ('tut1','e0000000-0000-4000-8000-0000000000d1','guardian'),
 ('tut2','e0000000-0000-4000-8000-0000000000d2','guardian'),
 ('adulte','e0000000-0000-4000-8000-0000000000e3','student');
GRANT ALL ON apres_lister, avant_lister, apres_paires, callers TO PUBLIC;

DO $apres$
DECLARE c record;
BEGIN
  FOR c IN SELECT * FROM callers LOOP
    PERFORM pg_temp.qui(c.id, c.role);
    INSERT INTO apres_lister VALUES (c.qui, public.com_lister_fils());
  END LOOP;
END $apres$;

-- Les droits et l'empreinte F86 de la migration (avant le retour a l'ancien corps).
DO $droits$
DECLARE f regprocedure := 'public.com_lister_fils()'::regprocedure;
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', f, 'EXECUTE') THEN
    RAISE EXCEPTION 'ROUGE : droits EXECUTE de com_lister_fils';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'private.com_paires(text,uuid)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.com_paires(text,uuid)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'ROUGE : droit EXECUTE ouvert sur private.com_paires';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = f AND p.prosecdef
                 AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'ROUGE : com_lister_fils sans DEFINER a search_path vide';
  END IF;
  IF coalesce(pg_catalog.obj_description(f, 'pg_proc'), '') NOT LIKE
     '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)) || '%' THEN
    RAISE EXCEPTION 'ROUGE : empreinte F86 de com_lister_fils perimee';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(f), 'OFFSET 0') = 0 THEN
    RAISE EXCEPTION 'ROUGE : la migration n''est pas installee (OFFSET 0 absent)';
  END IF;
END $droits$;

-- Etat « avant » : le corps de private.com_paires d'avant la migration
-- (membres sans borne), installe le temps du test.
CREATE OR REPLACE FUNCTION private.com_paires(p_type text, p_objet_id uuid)
 RETURNS TABLE(a_nature text, a_id uuid, b_nature text, b_id uuid)
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  WITH membres AS (
    SELECT g.id AS groupe_id, g.teacher_id, s.id AS eleve_id, s.household_id,
           private.com_est_mineur(s.id) AS mineur
    FROM public.groupes g
    JOIN public.groupe_membres m ON m.groupe_id = g.id AND m.left_at IS NULL
    JOIN public.profiles s ON s.id = m.student_id AND s.deleted_at IS NULL
    WHERE g.ended_at IS NULL
  ), cibles AS (
    SELECT 'foyer' AS a_nature, mb.household_id AS a_id, 'profil' AS b_nature, mb.teacher_id AS b_id
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'foyer', mb.household_id, 'equipe', NULL
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'profil', mb.eleve_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND NOT mb.mineur
    UNION
    SELECT 'profil', g.teacher_id, 'equipe', NULL
      FROM public.groupes g WHERE p_type = 'classe' AND g.id = p_objet_id AND g.ended_at IS NULL
    UNION
    SELECT 'foyer', mb.household_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'foyer', mb.household_id, 'equipe', NULL
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'profil', mb.eleve_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND NOT mb.mineur
    UNION
    SELECT CASE p.role WHEN 'teacher' THEN 'profil' ELSE 'foyer' END,
           CASE p.role WHEN 'teacher' THEN p.id ELSE p.household_id END,
           'equipe', NULL
      FROM public.profiles p
      WHERE p_type = 'dossier' AND p.id = p_objet_id AND p.deleted_at IS NULL
        AND p.role IN ('teacher', 'guardian')
    UNION
    SELECT 'profil', x.enseignant_id, 'equipe', NULL
      FROM public.remplacements_seance r
      CROSS JOIN LATERAL (VALUES (r.enseignant_titulaire_id), (r.enseignant_remplacant_id))
        AS x(enseignant_id)
      WHERE p_type = 'remplacement' AND r.id = p_objet_id AND x.enseignant_id IS NOT NULL
    UNION
    SELECT 'profil', p.id, 'equipe', NULL
      FROM public.profiles p
      WHERE p_type = 'profilPaiement' AND p.id = p_objet_id AND p.role = 'teacher'
    UNION
    SELECT 'profil', cd.profile_id, 'equipe', NULL
      FROM public.candidatures cd
      WHERE p_type = 'candidature' AND cd.id = p_objet_id
        AND cd.type_code = 'enseignant' AND cd.profile_id IS NOT NULL
        AND cd.issue = 'en_cours' AND NOT cd.en_pause AND cd.etape <> 'confirmee'
        AND private.com_candidature_lisible(cd.id, auth.uid())
  )
  SELECT c.a_nature, c.a_id, c.b_nature, c.b_id
  FROM cibles c
  WHERE c.a_id IS NOT NULL
    AND (p_type = 'candidature' OR (CASE c.a_nature
          WHEN 'foyer' THEN private.com_foyer_valide(c.a_id)
          ELSE private.com_profil_valide(c.a_id, NULL) AND NOT private.com_est_mineur(c.a_id)
        END
    AND (c.b_nature = 'equipe'
         OR (private.com_profil_valide(c.b_id, 'teacher') AND c.b_id <> c.a_id))
    AND (c.b_nature = 'equipe'
         OR (c.a_nature = 'profil' AND private.acces_paye(c.a_id))
         OR (c.a_nature = 'foyer' AND EXISTS (
               SELECT 1 FROM membres mb
                WHERE mb.household_id = c.a_id
                  AND ((p_type = 'classe' AND mb.groupe_id = p_objet_id)
                       OR (p_type = 'eleve' AND mb.eleve_id = p_objet_id))
                  AND private.acces_paye(mb.eleve_id))))));
$function$;

-- et le corps de public.com_lister_fils d'avant (sans OFFSET 0).
DO $ancien$
BEGIN
  EXECUTE pg_catalog.replace(
    pg_catalog.pg_get_functiondef('public.com_lister_fils()'::regprocedure),
    E'\n    OFFSET 0', '');
  IF pg_catalog.strpos(
       pg_catalog.pg_get_functiondef('public.com_lister_fils()'::regprocedure), 'OFFSET 0') > 0 THEN
    RAISE EXCEPTION 'ROUGE : le corps d''avant n''a pas ete installe';
  END IF;
END $ancien$;

DO $avant$
DECLARE c record;
BEGIN
  FOR c IN SELECT * FROM callers LOOP
    PERFORM pg_temp.qui(c.id, c.role);
    INSERT INTO avant_lister VALUES (c.qui, public.com_lister_fils());
  END LOOP;
END $avant$;

\o
DO $verdict$
DECLARE
  n_avant int;
  n_apres int;
  c record;
  n_fils int := 0;
BEGIN
  -- com_paires : memes lignes, avant et apres, pour tous les (type, objet).
  SELECT count(*) INTO n_avant FROM (
    SELECT f.type_objet, f.objet_id, q.a_nature, q.a_id, q.b_nature, q.b_id
    FROM (SELECT 'classe' AS type_objet, id AS objet_id FROM public.groupes
          UNION ALL SELECT 'eleve', id FROM public.profiles WHERE role = 'student'
          UNION ALL SELECT 'dossier', id FROM public.profiles
          UNION ALL SELECT 'profilPaiement', id FROM public.profiles
          UNION ALL SELECT 'remplacement', id FROM public.profiles
          UNION ALL SELECT 'inconnu', id FROM public.profiles) f
    CROSS JOIN LATERAL private.com_paires(f.type_objet, f.objet_id) q) x;
  SELECT count(*) INTO n_apres FROM apres_paires;
  IF n_avant <> n_apres OR n_avant = 0 THEN
    RAISE EXCEPTION 'ROUGE : com_paires, % lignes avant, % apres', n_avant, n_apres;
  END IF;
  IF EXISTS (
    (SELECT * FROM apres_paires EXCEPT
       SELECT f.type_objet, f.objet_id, q.a_nature, q.a_id, q.b_nature, q.b_id
       FROM (SELECT 'classe' AS type_objet, id AS objet_id FROM public.groupes
             UNION ALL SELECT 'eleve', id FROM public.profiles WHERE role = 'student'
             UNION ALL SELECT 'dossier', id FROM public.profiles
             UNION ALL SELECT 'profilPaiement', id FROM public.profiles
             UNION ALL SELECT 'remplacement', id FROM public.profiles
             UNION ALL SELECT 'inconnu', id FROM public.profiles) f
       CROSS JOIN LATERAL private.com_paires(f.type_objet, f.objet_id) q)
  ) THEN
    RAISE EXCEPTION 'ROUGE : com_paires differe avant et apres la migration';
  END IF;
  RAISE NOTICE 'OK com_paires identique sur % lignes (classes, eleves, dossiers, paiements)', n_avant;
  -- com_lister_fils : le meme jsonb, octet pour octet, pour chaque appelant.
  FOR c IN SELECT a.qui, a.res AS apres, v.res AS avant
             FROM apres_lister a JOIN avant_lister v USING (qui) LOOP
    IF c.apres IS DISTINCT FROM c.avant THEN
      RAISE EXCEPTION 'ROUGE : com_lister_fils differe pour % : % <> %', c.qui, c.avant, c.apres;
    END IF;
    IF c.apres::text IS DISTINCT FROM c.avant::text THEN
      RAISE EXCEPTION 'ROUGE : com_lister_fils (texte) differe pour %', c.qui;
    END IF;
    n_fils := n_fils + pg_catalog.jsonb_array_length(c.apres);
  END LOOP;
  IF (SELECT count(*) FROM apres_lister) <> 7 OR n_fils < 10 THEN
    RAISE EXCEPTION 'ROUGE : fixture sans contenu (% fils lus au total)', n_fils;
  END IF;
  RAISE NOTICE 'OK com_lister_fils identique pour 7 appelants (% fils lus au total)', n_fils;
END $verdict$;

ROLLBACK;
