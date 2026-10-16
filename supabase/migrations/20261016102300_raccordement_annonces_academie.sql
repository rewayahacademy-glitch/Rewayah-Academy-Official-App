-- RACCORDEMENT 16/10 (E) : les annonces « toute l'academie » et « public »
-- lues par leurs destinataires.
--
-- Constat sur STAGING : une annonce publiee pour 'toutes' (ou 'familles',
-- 'enseignants') est enregistree, listee pour l'Administration, et lue par
-- personne : `com_annonces_de_classe` ne rend que les annonces de la Classe,
-- et `com_annonce_lire` ecarte toute annonce sans Classe
-- (`a.groupe_id IS NOT NULL`), donc `com_annonce_marquer_lue` refuse aussi
-- (choix A5 de 20261016090100, laisse en attente).
--
-- * Destinataires (lecture recalculee a chaque appel, compte valide, role
--   du jeton) : 'toutes' : tout compte valide de l'academie ; 'familles' :
--   tuteurs et eleves ; 'enseignants' : enseignants ; l'Administration lit
--   tout. Une annonce programmee reste invisible avant son instant.
-- * `com_annonces_academie(p_groupe_id)` : les annonces generales lisibles
--   par l'appelant, la plus recente d'abord. Avec une Classe que l'appelant
--   lit, chaque annonce est rendue dans le contexte de cette Classe (meme
--   forme que les annonces de Classe : l'ecran de la Classe les liste sans
--   nouveau contrat) ; sinon sa Classe est nulle. Chaque annonce porte
--   'portee' ('toutes' | 'familles' | 'enseignants').
-- * `com_annonce_lire` couvre aussi les annonces generales (contexte : la
--   premiere Classe active que l'appelant lit, ou nulle) ; le reste du corps
--   est celui de 20261016090100. `com_annonce_marquer_lue`, qui s'appuie sur
--   elle, marque desormais une annonce generale lue.
-- * `com_annonces_de_classe` est inchangee (A5 y reste : la Classe ne liste
--   que ses annonces ; l'adaptateur client fusionne les deux lectures).
BEGIN;

-- L'appelant est-il destinataire d'une annonce generale de cette audience ?
CREATE FUNCTION private.com_lit_annonce_generale(p_audience text)
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT coalesce(public.app_account_valid(), false)
    AND private.com_profil_valide(auth.uid(), public.app_role()::text)
    AND CASE p_audience
          WHEN 'toutes' THEN public.app_role()::text IN
            ('admin', 'teacher', 'guardian', 'student', 'controller', 'accountant')
          WHEN 'familles' THEN public.app_role()::text IN ('admin', 'guardian', 'student')
          WHEN 'enseignants' THEN public.app_role()::text IN ('admin', 'teacher')
          ELSE false
        END;
$function$;

-- Une annonce generale, rendue dans le contexte d'une Classe (ou sans).
CREATE FUNCTION private.com_annonce_generale_json(p_id uuid, p_groupe_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', a.id, 'titre', a.titre, 'texte', a.texte,
    'publiee_le', a.diffusee_le,
    'portee', a.audience,
    'classe', CASE WHEN g.id IS NULL THEN NULL
                   ELSE pg_catalog.jsonb_build_object('id', g.id, 'libelle', g.libelle) END,
    'auteur', private.com_participant('equipe', NULL, 'classe', g.id),
    'lue', EXISTS (SELECT 1 FROM public.com_annonce_lectures l
                    WHERE l.annonce_id = a.id AND l.profile_id = auth.uid()))
  FROM public.com_annonces a
  LEFT JOIN public.groupes g ON g.id = p_groupe_id
  WHERE a.id = p_id AND a.groupe_id IS NULL;
$function$;

REVOKE ALL ON FUNCTION private.com_lit_annonce_generale(text),
  private.com_annonce_generale_json(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Les annonces generales lisibles par l'appelant.
CREATE FUNCTION public.com_annonces_academie(p_groupe_id uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v_contexte uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid()
                  AND private.com_profil_valide(auth.uid(), public.app_role()::text), false) THEN
    RAISE EXCEPTION 'COM annonces de l''academie non autorisees' USING ERRCODE = '42501';
  END IF;
  IF p_groupe_id IS NOT NULL THEN
    IF NOT private.com_lit_classe(p_groupe_id) THEN
      RAISE EXCEPTION 'COM annonces de l''academie non autorisees' USING ERRCODE = '42501';
    END IF;
    v_contexte := p_groupe_id;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'annonces', coalesce((
      SELECT pg_catalog.jsonb_agg(private.com_annonce_generale_json(a.id, v_contexte)
                                  ORDER BY a.diffusee_le DESC, a.id DESC)
      FROM public.com_annonces a
      WHERE a.groupe_id IS NULL
        AND a.diffusee_le <= pg_catalog.clock_timestamp()
        AND private.com_lit_annonce_generale(a.audience)), '[]'::jsonb));
END;
$function$;

-- Une annonce diffusee, ou null (absente, programmee ou non autorisee).
CREATE OR REPLACE FUNCTION public.com_annonce_lire(p_annonce_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_groupe uuid;
  v_audience text;
  v_contexte uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  SELECT a.groupe_id, a.audience INTO v_groupe, v_audience FROM public.com_annonces a
  WHERE a.id = p_annonce_id AND a.diffusee_le <= pg_catalog.clock_timestamp();
  IF v_audience IS NULL THEN RETURN NULL; END IF;
  IF v_groupe IS NOT NULL THEN
    IF NOT private.com_lit_classe(v_groupe) THEN RETURN NULL; END IF;
    RETURN private.com_annonce_json(p_annonce_id);
  END IF;
  IF NOT private.com_lit_annonce_generale(v_audience) THEN RETURN NULL; END IF;
  SELECT g.id INTO v_contexte FROM public.groupes g
   WHERE g.ended_at IS NULL AND private.com_lit_classe(g.id)
   ORDER BY g.libelle, g.id LIMIT 1;
  RETURN private.com_annonce_generale_json(p_annonce_id, v_contexte);
END;
$function$;

DO $acl$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.com_annonces_academie(uuid)',
    'public.com_annonce_lire(uuid)'
  ] LOOP
    EXECUTE format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', f);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$acl$;

-- @@F86_DEBUT_ANNONCES_ACADEMIE@@
COMMENT ON FUNCTION public.com_annonces_academie(uuid) IS
  'F86: signature=public.com_annonces_academie(uuid); md5_functiondef=a769350ce9d488d7314726de612b7172; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: compte valide; Classe de contexte lisible par l''appelant; audience recalculee par annonce.';
COMMENT ON FUNCTION public.com_annonce_lire(uuid) IS
  'F86: signature=public.com_annonce_lire(uuid); md5_functiondef=05c52ff053ab571fe9751d92596a90c8; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: null si absente, programmee ou non autorisee (Classe ou audience generale).';
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM (VALUES
      ('public.com_annonces_academie(uuid)'::regprocedure, 'a769350ce9d488d7314726de612b7172'),
      ('public.com_annonce_lire(uuid)'::regprocedure, '05c52ff053ab571fe9751d92596a90c8')
    ) AS e(oid, attendu)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> e.attendu
       OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || e.attendu || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) OR EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid IN ('private.com_lit_annonce_generale(text)'::regprocedure,
                    'private.com_annonce_generale_json(uuid,uuid)'::regprocedure)
      AND (p.prosecdef OR pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE'))
  ) THEN
    RAISE EXCEPTION 'RACCORDEMENT-1016 E : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_ANNONCES_ACADEMIE@@

COMMIT;
