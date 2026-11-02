-- N1 (02/11/2026) : capacites Communications et regles de portee des annonces.
--
-- Fichier SANS mot d'effacement (B5) : le pilote l'installe. Migration
-- additive (B6) : deux fonctions nouvelles, rien de modifie ni de retire ;
-- l'ancien code de production ne les appelle pas et continue de marcher.
--
-- Constat : personne ne pouvait ecrire un message ni publier une annonce dans
-- l'application, car `lib/core/communications/capacites_communication.dart`
-- n'avait aucune source serveur (port neutre, tout ferme). Les barrieres
-- serveur, elles, existent : `com_envoyer_message` (20261016090000) et
-- `com_annonce_publier` (20261016090100). Cette migration ne les touche pas ;
-- elles restent la seule autorisation. Ce qui suit dit seulement a l'ecran
-- quoi RENDRE, pour qu'un bouton qui va etre refuse ne soit pas montre.
--
-- 1. `public.com_mes_capacites(p_type text, p_objet_id uuid)` : les capacites
--    de la personne connectee, par role, et, si un objet est donne, par objet.
--    * publier_annonce : la direction ; un enseignant qui a au moins une Classe
--      active (sur un objet `classe` : `private.com_publie_classe`, la regle
--      exacte de `com_annonce_publier`) ;
--    * programmer : la direction seule (meme regle que `com_annonce_publier`) ;
--    * ecrire_dans_fil : tout appelant valide de `private.com_appelant()`
--      (jamais un mineur), sauf le controleur (ses fils sont ceux de sa
--      mission, B-12, hors `com_*`) ; sur un objet, seulement s'il est partie
--      d'une paire autorisee MAINTENANT (`private.com_paires`), comme
--      `com_envoyer_message` ;
--    * envoyer_vocal : toujours faux, le transport des vocaux (COM-BR-03)
--      n'existe pas cote serveur.
-- 2. `public.com_regles_audience()` : la matrice de portee montree a la
--    direction (COM-BR-11), en codes (l'application redige les mots). Elle
--    redit les regles de `com_annonce_publier` ; le scenario
--    `scenarios_n1_communications.sql` verifie que chaque ligne correspond a
--    ce que la publication accepte ou refuse.
--
-- Lecteurs : nouvelles fonctions, aucun lecteur existant (B1 sans objet).
-- Securite : SECURITY DEFINER, search_path vide, proprietaire postgres,
-- EXECUTE a authenticated seulement ; aucune politique RLS ne les appelle,
-- donc aucun droit a agent_ro (B3 sans objet).
BEGIN;

CREATE FUNCTION public.com_mes_capacites(p_type text DEFAULT NULL, p_objet_id uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  moi record;
  v_publier boolean;
  v_ecrire boolean;
BEGIN
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL THEN
    RAISE EXCEPTION 'N1 capacites non autorisees' USING ERRCODE = '42501';
  END IF;
  IF (p_type IS NULL) <> (p_objet_id IS NULL)
     OR (p_type IS NOT NULL AND p_type NOT IN
         ('classe', 'eleve', 'dossier', 'remplacement', 'profilPaiement')) THEN
    RAISE EXCEPTION 'N1 objet invalide' USING ERRCODE = '22023';
  END IF;

  IF p_type = 'classe' THEN
    v_publier := coalesce(private.com_publie_classe(p_objet_id), false);
  ELSIF p_type IS NULL THEN
    v_publier := moi.role = 'admin'
      OR (moi.role = 'teacher' AND EXISTS (
            SELECT 1 FROM public.groupes g
             WHERE g.teacher_id = moi.id AND g.ended_at IS NULL));
  ELSE
    v_publier := false;
  END IF;

  IF p_type IS NULL THEN
    v_ecrire := moi.role IN ('admin', 'teacher', 'guardian', 'student', 'accountant');
  ELSE
    v_ecrire := moi.role <> 'controller' AND EXISTS (
      SELECT 1 FROM private.com_paires(p_type, p_objet_id) q
       WHERE private.com_est_partie(moi.id, moi.role, moi.foyer, p_type, q.a_nature, q.a_id)
          OR private.com_est_partie(moi.id, moi.role, moi.foyer, p_type, q.b_nature, q.b_id));
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'publier_annonce', coalesce(v_publier, false),
    'programmer', moi.role = 'admin',
    'ecrire_dans_fil', coalesce(v_ecrire, false),
    'envoyer_vocal', false);
END;
$function$;

CREATE FUNCTION public.com_regles_audience()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  moi record;
BEGIN
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL OR moi.role <> 'admin' THEN
    RAISE EXCEPTION 'N1 regles non autorisees' USING ERRCODE = '42501';
  END IF;
  -- Codes de portee : 'toute_audience' (toute l'academie, un public ou une
  -- Classe active), 'sa_classe' (ses Classes actives seulement), 'aucune'.
  RETURN pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('id', 'direction', 'auteurs', 'direction',
      'peut_publier', true, 'portee', 'toute_audience'),
    pg_catalog.jsonb_build_object('id', 'enseignants', 'auteurs', 'enseignants',
      'peut_publier', true, 'portee', 'sa_classe'),
    pg_catalog.jsonb_build_object('id', 'familles', 'auteurs', 'familles',
      'peut_publier', false, 'portee', 'aucune'),
    pg_catalog.jsonb_build_object('id', 'eleves', 'auteurs', 'eleves',
      'peut_publier', false, 'portee', 'aucune'),
    pg_catalog.jsonb_build_object('id', 'comptables', 'auteurs', 'comptables',
      'peut_publier', false, 'portee', 'aucune'),
    pg_catalog.jsonb_build_object('id', 'controleurs', 'auteurs', 'controleurs',
      'peut_publier', false, 'portee', 'aucune'));
END;
$function$;

DO $acl$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.com_mes_capacites(text,uuid)'::regprocedure,
    'public.com_regles_audience()'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-11-02. N1 : capacites a rendre, la barriere reste com_envoyer_message et com_annonce_publier.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$acl$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.com_mes_capacites(text,uuid)'::regprocedure,
    'public.com_regles_audience()'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(v_oid, 'pg_proc'), '')
            NOT LIKE '%' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)) || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'N1 : empreinte F86, DEFINER ou droits invalides sur %', v_oid::text;
    END IF;
  END LOOP;
END;
$postflight$;

COMMIT;
