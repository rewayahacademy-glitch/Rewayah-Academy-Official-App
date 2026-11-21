-- GUIDE-COMMENTAIRES (21/11/2026) : les commentaires du guide de l'enseignant et la page de la direction qui les lit et y
-- repond (directeur, 21/11/2026 : « il faut ouvrir la page des commentaires cote admin »). Decisions du 20 et du 21/11
-- (docs/current/CANDIDATURES/LETTRE-CANDIDATS/LOT.md) : commentaires prives (le lecteur ne voit que son fil), lus par la
-- direction, circuit a part hors de la messagerie ; la liste de la direction met en tete les parties les plus « Pas clair ».
-- Contrats : lib/features/candidature/lettre/port_interactions_guide.dart (lecteur) et
-- lib/features/admin_guide/port_commentaires_guide.dart (direction).
--
-- LIVRE ICI :
--   1. private.guide_commentaires : un message par ligne (fil d'un lecteur sur une partie) ; auteur « lecteur »,
--      « direction » ou « praxis » ; RLS activee, AUCUNE politique, aucun droit pour les roles clients.
--   2. public.commenter_guide(p_partie text, p_corps text) -> jsonb, VOLATILE : le lecteur ecrit dans son fil. Garde : le
--      droit de lire le guide (private.guide_avis_acces(), 20261130971000), sinon 42501.
--   3. public.lire_interactions_guide() remplacee : rend aussi le fil de l'appelant, et « commentaires_ouverts » vrai.
--   4. public.commentaires_guide_direction() -> jsonb, STABLE : la direction lit toutes les parties (totaux, fils, noms des
--      lecteurs), triees par « Pas clair » decroissant. Garde positive : app_role() = 'admin' ET app_account_valid().
--   5. public.repondre_commentaire_guide(p_commentaire uuid, p_corps text) -> jsonb, VOLATILE : la direction repond dans le
--      fil du lecteur. Meme garde.
--
-- MOTS D'EFFACEMENT : ZERO. Une seule fonction remplacee (lire_interactions_guide), par CREATE OR REPLACE, droits redits.
-- Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.guide_avis_acces()') IS NULL
     OR pg_catalog.to_regprocedure('public.lire_interactions_guide()') IS NULL THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : les avis du guide (20261130971000) ne sont pas installes ; rien n''est modifie';
  END IF;
  IF pg_catalog.to_regclass('private.guide_commentaires') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.commenter_guide(text,text)') IS NOT NULL THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : deja installe ; rien n''est modifie';
  END IF;
END
$preflight$;

-- 1. La table ----------------------------------------------------------------------------------------------------------------
CREATE TABLE private.guide_commentaires (
  id uuid NOT NULL DEFAULT pg_catalog.gen_random_uuid() PRIMARY KEY,
  lecteur_id uuid NOT NULL,
  partie text NOT NULL CHECK (partie ~ '^p[1-9][0-9]?$'),
  corps text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(corps)) BETWEEN 1 AND 2000),
  auteur text NOT NULL CHECK (auteur IN ('lecteur', 'direction', 'praxis')),
  auteur_id uuid,
  parent_id uuid REFERENCES private.guide_commentaires (id),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE INDEX guide_commentaires_lecteur_idx ON private.guide_commentaires (lecteur_id, cree_le);
CREATE INDEX guide_commentaires_partie_idx ON private.guide_commentaires (partie, cree_le);
COMMENT ON TABLE private.guide_commentaires IS
  'GUIDE-COMMENTAIRES (21/11/2026) : les fils prives des lecteurs du guide de l''enseignant, par partie ; lus par le seul '
  'lecteur du fil et par la direction. RLS activee sans politique, aucun droit pour les roles clients.';
ALTER TABLE private.guide_commentaires ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.guide_commentaires FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Un message vu par son lecteur.
CREATE FUNCTION private.guide_commentaire_lecteur(c private.guide_commentaires)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', c.id, 'partie', c.partie, 'corps', c.corps, 'cree_le', c.cree_le,
    'auteur', CASE c.auteur WHEN 'lecteur' THEN 'moi' ELSE c.auteur END,
    'parent_id', c.parent_id);
$function$;
REVOKE ALL ON FUNCTION private.guide_commentaire_lecteur(private.guide_commentaires)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- La garde de la direction.
CREATE FUNCTION private.guide_direction()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(public.app_role() = 'admin'::public.app_role AND public.app_account_valid(), false);
$function$;
REVOKE ALL ON FUNCTION private.guide_direction() FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 2. Le lecteur ecrit --------------------------------------------------------------------------------------------------------
CREATE FUNCTION public.commenter_guide(p_partie text, p_corps text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ligne private.guide_commentaires;
BEGIN
  IF NOT private.guide_avis_acces() THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : reserve aux lecteurs du guide' USING ERRCODE = '42501';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM private.lettre_candidats_parties t WHERE t.langue = 'fr' AND t.code = p_partie) THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : partie inconnue' USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.length(pg_catalog.btrim(coalesce(p_corps, ''))) NOT BETWEEN 1 AND 2000 THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : un commentaire de 1 a 2000 caracteres' USING ERRCODE = '22023';
  END IF;
  INSERT INTO private.guide_commentaires (lecteur_id, partie, corps, auteur, auteur_id)
  VALUES (auth.uid(), p_partie, pg_catalog.btrim(p_corps), 'lecteur', auth.uid())
  RETURNING * INTO v_ligne;
  RETURN private.guide_commentaire_lecteur(v_ligne);
END;
$function$;
REVOKE ALL ON FUNCTION public.commenter_guide(text, text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.commenter_guide(text, text) TO authenticated;

-- 3. La lecture du lecteur, avec son fil -------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.lire_interactions_guide()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_version text;
BEGIN
  IF NOT private.guide_avis_acces() THEN
    RAISE EXCEPTION 'GUIDE-AVIS : reserve aux lecteurs du guide' USING ERRCODE = '42501';
  END IF;
  SELECT max(t.version) INTO v_version FROM private.lettre_candidats_parties t WHERE t.langue = 'fr';
  RETURN pg_catalog.jsonb_build_object(
    'parties', coalesce((SELECT pg_catalog.jsonb_agg(private.guide_avis_ligne(t.code) ORDER BY t.rang)
                           FROM private.lettre_candidats_parties t
                          WHERE t.langue = 'fr' AND t.version = v_version), '[]'::jsonb),
    'commentaires', coalesce((SELECT pg_catalog.jsonb_agg(private.guide_commentaire_lecteur(c) ORDER BY c.cree_le, c.id)
                                FROM private.guide_commentaires c
                               WHERE c.lecteur_id = auth.uid()), '[]'::jsonb),
    'commentaires_ouverts', true);
END;
$function$;
REVOKE ALL ON FUNCTION public.lire_interactions_guide() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.lire_interactions_guide() TO authenticated;

-- 4. La direction lit --------------------------------------------------------------------------------------------------------
CREATE FUNCTION public.commentaires_guide_direction()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_version text;
BEGIN
  IF NOT private.guide_direction() THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : reserve a la direction' USING ERRCODE = '42501';
  END IF;
  SELECT max(t.version) INTO v_version FROM private.lettre_candidats_parties t WHERE t.langue = 'fr';
  RETURN pg_catalog.jsonb_build_object('parties', coalesce((
    SELECT pg_catalog.jsonb_agg(x.ligne ORDER BY x.pas_clair DESC, x.rang)
      FROM (
        SELECT t.rang,
               (SELECT count(*) FROM private.guide_avis a WHERE a.partie = t.code AND a.avis = 'pas_clair') AS pas_clair,
               pg_catalog.jsonb_build_object(
                 'code', t.code,
                 'titre', t.titre,
                 'jaime', (SELECT count(*) FROM private.guide_avis a WHERE a.partie = t.code AND a.avis = 'jaime'),
                 'pas_clair', (SELECT count(*) FROM private.guide_avis a WHERE a.partie = t.code AND a.avis = 'pas_clair'),
                 'fils', coalesce((
                   SELECT pg_catalog.jsonb_agg(f.fil ORDER BY f.dernier DESC)
                     FROM (
                       SELECT max(c.cree_le) AS dernier,
                              pg_catalog.jsonb_build_object(
                                'lecteur_id', c.lecteur_id,
                                'lecteur', coalesce(nullif(pg_catalog.btrim(
                                  coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')), ''), '?'),
                                'messages', pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                                  'id', c.id, 'corps', c.corps, 'cree_le', c.cree_le, 'auteur', c.auteur,
                                  'parent_id', c.parent_id) ORDER BY c.cree_le, c.id)) AS fil
                         FROM private.guide_commentaires c
                         LEFT JOIN public.profiles p ON p.id = c.lecteur_id
                        WHERE c.partie = t.code
                        GROUP BY c.lecteur_id, p.first_name, p.last_name) f), '[]'::jsonb)) AS ligne
          FROM private.lettre_candidats_parties t
         WHERE t.langue = 'fr' AND t.version = v_version) x), '[]'::jsonb));
END;
$function$;
REVOKE ALL ON FUNCTION public.commentaires_guide_direction() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.commentaires_guide_direction() TO authenticated;

-- 5. La direction repond -----------------------------------------------------------------------------------------------------
CREATE FUNCTION public.repondre_commentaire_guide(p_commentaire uuid, p_corps text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_source private.guide_commentaires;
  v_ligne private.guide_commentaires;
BEGIN
  IF NOT private.guide_direction() THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : reserve a la direction' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_source FROM private.guide_commentaires c WHERE c.id = p_commentaire;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : commentaire inconnu' USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.length(pg_catalog.btrim(coalesce(p_corps, ''))) NOT BETWEEN 1 AND 2000 THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : une reponse de 1 a 2000 caracteres' USING ERRCODE = '22023';
  END IF;
  INSERT INTO private.guide_commentaires (lecteur_id, partie, corps, auteur, auteur_id, parent_id)
  VALUES (v_source.lecteur_id, v_source.partie, pg_catalog.btrim(p_corps), 'direction', auth.uid(),
          coalesce(v_source.parent_id, v_source.id))
  RETURNING * INTO v_ligne;
  RETURN pg_catalog.jsonb_build_object(
    'id', v_ligne.id, 'corps', v_ligne.corps, 'cree_le', v_ligne.cree_le, 'auteur', v_ligne.auteur,
    'parent_id', v_ligne.parent_id);
END;
$function$;
REVOKE ALL ON FUNCTION public.repondre_commentaire_guide(uuid, text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.repondre_commentaire_guide(uuid, text) TO authenticated;

-- 6. F86 : les empreintes en commentaire ---------------------------------------------------------------------------------------
DO $f86$
DECLARE
  f text;
BEGIN
  FOREACH f IN ARRAY ARRAY['public.lire_interactions_guide()', 'public.commenter_guide(text,text)',
                           'public.commentaires_guide_direction()', 'public.repondre_commentaire_guide(uuid,text)'] LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
      'F86 candidate allowlist: signature=' || f || '; md5_functiondef='
      || pg_catalog.md5(pg_catalog.pg_get_functiondef(f::regprocedure))
      || '; owner=postgres; search_path=""; date=2026-11-21. GUIDE-COMMENTAIRES. Lecteur : garde de lecture du guide ; '
      || 'direction : app_role() = admin et app_account_valid(). Must-pass: supabase/tests/scenarios_guide_commentaires.sql.');
  END LOOP;
END
$f86$;

-- 7. Controle final ----------------------------------------------------------------------------------------------------------
DO $controle$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'private.guide_commentaires'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : RLS non activee';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_policy p WHERE p.polrelid = 'private.guide_commentaires'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : la table ne doit porter aucune politique';
  END IF;
  IF has_table_privilege('authenticated', 'private.guide_commentaires', 'SELECT,INSERT,UPDATE,REFERENCES,TRIGGER')
     OR has_table_privilege('anon', 'private.guide_commentaires', 'SELECT,INSERT,UPDATE,REFERENCES,TRIGGER') THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : un role client garde un droit sur la table';
  END IF;
  IF has_function_privilege('anon', 'public.commenter_guide(text,text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.commentaires_guide_direction()', 'EXECUTE')
     OR has_function_privilege('anon', 'public.repondre_commentaire_guide(uuid,text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.lire_interactions_guide()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.guide_direction()', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.commenter_guide(text,text)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.commentaires_guide_direction()', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.repondre_commentaire_guide(uuid,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES : droits d''execution inattendus';
  END IF;
END
$controle$;
