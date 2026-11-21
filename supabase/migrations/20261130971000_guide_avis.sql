-- GUIDE-AVIS (21/11/2026) : les « J'aime » et « Pas clair » du guide de l'enseignant (directeur, 21/11/2026 : « il faut
-- ajouter les "j'aime" et l'autre »). Lot : docs/current/CANDIDATURES/LETTRE-CANDIDATS/LOT.md, decisions du 21/11.
-- Contrat de la reponse : lib/features/candidature/lettre/port_interactions_guide.dart (en tete du fichier ; il fait foi).
--
-- LIVRE ICI :
--   1. private.guide_avis : un avis par lecteur et par partie (« jaime », « pas_clair », ou NULL quand le lecteur l'a
--      retire : jamais d'effacement). Schema prive, RLS activee, AUCUNE politique, aucun droit pour les roles clients.
--   2. public.lire_interactions_guide() -> jsonb, STABLE, SECURITY DEFINER, search_path vide : pour chaque partie du guide,
--      les totaux publics (« jaime », « pas_clair ») et l'avis du lecteur ; « commentaires » vide et
--      « commentaires_ouverts » faux tant que la direction n'a aucun ecran pour lire les commentaires et y repondre.
--   3. public.donner_avis_guide(p_partie text, p_avis text) -> jsonb, VOLATILE, SECURITY DEFINER, search_path vide : pose
--      ou retire (p_avis NULL) l'avis du lecteur sur une partie, rend la ligne de la partie a jour.
--   Qui peut appeler les deux : exactement qui peut lire le guide, decide par public.lire_lettre_candidats() (garde positive
--   du role enseignant dans le jeton, profil enseignant ouvert, compte actif ou candidature en cours avec ses accords).
--   Les candidats en attente (pending_kyc) lisent le guide : public.app_account_valid() les refuserait, elle n'est donc pas
--   la garde ici. Sinon : 42501, sans une ligne.
--
-- MOTS D'EFFACEMENT : ZERO. Aucune fonction existante n'est remplacee. Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.lire_lettre_candidats(text)') IS NULL
     OR pg_catalog.to_regclass('private.lettre_candidats_parties') IS NULL THEN
    RAISE EXCEPTION 'GUIDE-AVIS : le guide (20261130970000) n''est pas installe ; rien n''est modifie';
  END IF;
  IF pg_catalog.to_regclass('private.guide_avis') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.lire_interactions_guide()') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.donner_avis_guide(text,text)') IS NOT NULL THEN
    RAISE EXCEPTION 'GUIDE-AVIS : deja installe ; rien n''est modifie';
  END IF;
END
$preflight$;

-- 1. La table des avis -------------------------------------------------------------------------------------------------------
CREATE TABLE private.guide_avis (
  profil_id uuid NOT NULL,
  partie text NOT NULL CHECK (partie ~ '^p[1-9][0-9]?$'),
  avis text CHECK (avis IN ('jaime', 'pas_clair')),
  maj_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT guide_avis_pkey PRIMARY KEY (profil_id, partie)
);
COMMENT ON TABLE private.guide_avis IS
  'GUIDE-AVIS (21/11/2026) : un avis par lecteur et par partie du guide de l''enseignant ; avis NULL = retire (jamais '
  'd''effacement). Lue et ecrite seulement par public.lire_interactions_guide() et public.donner_avis_guide(text,text). '
  'RLS activee sans politique, aucun droit pour les roles clients.';
ALTER TABLE private.guide_avis ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.guide_avis FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 2. Les aides privees -------------------------------------------------------------------------------------------------------
-- Le droit de l'appelant : celui de lire le guide, decide par la seule fonction qui le decide deja.
CREATE FUNCTION private.guide_avis_acces()
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN false;
  END IF;
  RETURN coalesce((public.lire_lettre_candidats('fr') ->> 'acces')::boolean, false);
END;
$function$;
REVOKE ALL ON FUNCTION private.guide_avis_acces() FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- La ligne d'une partie : ses totaux publics et l'avis de l'appelant.
CREATE FUNCTION private.guide_avis_ligne(p_partie text)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'code', p_partie,
    'jaime', (SELECT count(*) FROM private.guide_avis a WHERE a.partie = p_partie AND a.avis = 'jaime'),
    'pas_clair', (SELECT count(*) FROM private.guide_avis a WHERE a.partie = p_partie AND a.avis = 'pas_clair'),
    'mon_avis', (SELECT a.avis FROM private.guide_avis a WHERE a.partie = p_partie AND a.profil_id = auth.uid()));
$function$;
REVOKE ALL ON FUNCTION private.guide_avis_ligne(text) FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 3. La lecture --------------------------------------------------------------------------------------------------------------
CREATE FUNCTION public.lire_interactions_guide()
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
    'commentaires', '[]'::jsonb,
    'commentaires_ouverts', false);
END;
$function$;
REVOKE ALL ON FUNCTION public.lire_interactions_guide() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.lire_interactions_guide() TO authenticated;

-- 4. L'avis ------------------------------------------------------------------------------------------------------------------
CREATE FUNCTION public.donner_avis_guide(p_partie text, p_avis text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.guide_avis_acces() THEN
    RAISE EXCEPTION 'GUIDE-AVIS : reserve aux lecteurs du guide' USING ERRCODE = '42501';
  END IF;
  IF p_avis IS NOT NULL AND p_avis NOT IN ('jaime', 'pas_clair') THEN
    RAISE EXCEPTION 'GUIDE-AVIS : avis inconnu' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM private.lettre_candidats_parties t WHERE t.langue = 'fr' AND t.code = p_partie) THEN
    RAISE EXCEPTION 'GUIDE-AVIS : partie inconnue' USING ERRCODE = '22023';
  END IF;
  INSERT INTO private.guide_avis AS a (profil_id, partie, avis, maj_le)
  VALUES (auth.uid(), p_partie, p_avis, pg_catalog.now())
  ON CONFLICT (profil_id, partie) DO UPDATE SET avis = EXCLUDED.avis, maj_le = EXCLUDED.maj_le;
  RETURN private.guide_avis_ligne(p_partie);
END;
$function$;
REVOKE ALL ON FUNCTION public.donner_avis_guide(text, text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.donner_avis_guide(text, text) TO authenticated;

-- 5. F86 : les empreintes en commentaire ---------------------------------------------------------------------------------------
DO $f86$
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.lire_interactions_guide() IS %L',
    'F86 candidate allowlist: signature=public.lire_interactions_guide(); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.lire_interactions_guide()'::regprocedure))
    || '; guard_type=SAME_AS_LIRE_LETTRE_CANDIDATS; owner=postgres; search_path=""; date=2026-11-21. GUIDE-AVIS. '
    || 'Ne rend que des totaux par partie et l''avis de l''appelant ; jamais qui a donne quel avis. '
    || 'Must-pass: supabase/tests/scenarios_guide_avis.sql.');
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.donner_avis_guide(text, text) IS %L',
    'F86 candidate allowlist: signature=public.donner_avis_guide(p_partie text, p_avis text); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.donner_avis_guide(text,text)'::regprocedure))
    || '; guard_type=SAME_AS_LIRE_LETTRE_CANDIDATS; owner=postgres; search_path=""; date=2026-11-21. GUIDE-AVIS. '
    || 'N''ecrit qu''une ligne de private.guide_avis, celle de l''appelant (auth.uid()) pour une partie existante. '
    || 'Must-pass: supabase/tests/scenarios_guide_avis.sql.');
END
$f86$;

-- 6. Controle final ----------------------------------------------------------------------------------------------------------
DO $controle$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.guide_avis'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'GUIDE-AVIS : RLS non activee';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_policy p WHERE p.polrelid = 'private.guide_avis'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'GUIDE-AVIS : la table ne doit porter aucune politique';
  END IF;
  IF has_table_privilege('anon', 'private.guide_avis', 'SELECT,INSERT,UPDATE,REFERENCES,TRIGGER')
     OR has_table_privilege('authenticated', 'private.guide_avis', 'SELECT,INSERT,UPDATE,REFERENCES,TRIGGER')
     OR has_table_privilege('agent_ro', 'private.guide_avis', 'SELECT,INSERT,UPDATE,REFERENCES,TRIGGER') THEN
    RAISE EXCEPTION 'GUIDE-AVIS : un role client garde un droit sur la table';
  END IF;
  IF has_function_privilege('anon', 'public.lire_interactions_guide()', 'EXECUTE')
     OR has_function_privilege('anon', 'public.donner_avis_guide(text,text)', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.donner_avis_guide(text,text)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.guide_avis_acces()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.guide_avis_ligne(text)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.lire_interactions_guide()', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.donner_avis_guide(text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'GUIDE-AVIS : droits d''execution inattendus';
  END IF;
END
$controle$;
