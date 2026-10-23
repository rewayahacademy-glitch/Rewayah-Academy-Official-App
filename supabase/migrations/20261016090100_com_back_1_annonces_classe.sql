-- COM-BACK-1 (2/2) : Annonces (COM-BR-10).
--
-- Contrat : lib/features/com_annonces/port_annonces.dart (PortAnnonces).
-- Spec : Communications V1, sections 13.3 et 13.4 ; libelle du publieur
-- « Seules les familles et les eleves de cette Classe la recoivent. »
-- (com.annonces.publieur.nature.classe).
--
-- * Une annonce part dans un seul sens ; elle ne devient jamais un fil.
-- * Publier : l'enseignant pour SA Classe active seulement ; l'Administration
--   pour une Classe active, un public (familles, enseignants) ou toute
--   l'academie. Tuteur, eleve, controleur, comptable : aucune publication.
-- * Programmer : l'Administration seule (« programmation si capability
--   existante ») ; l'instant est un timestamptz UTC ; une annonce programmee
--   devient visible des que son instant est passe, sans tache de fond.
-- * Lire une annonce de Classe : l'enseignant de la Classe, l'Administration,
--   les tuteurs d'un foyer dont un eleve est membre actif, et les eleves
--   membres actifs (mineurs compris : un mineur ne lit que les annonces de
--   SA Classe, jamais un fil). La lecture se recalcule a chaque appel.
-- * Ordre : la plus recente d'abord (instant de diffusion, puis identifiant).
--
-- Choix par defaut, a confirmer :
-- * A1 programmation entre 5 minutes et 14 jours apres l'appel (les trois
--   creneaux proposes par le publieur tombent avant 8 jours) ;
-- * A2 titre de 1 a 120 caracteres, texte de 1 a 5000 ;
-- * A3 ni modification ni suppression apres publication (ajout seul), meme
--   programmee ; une correction se publie comme nouvelle annonce ;
-- * A4 la vue de l'Administration montre les annonces publiees des 30
--   derniers jours et toutes les planifiees ;
-- * A5 les annonces « public » et « toute l'academie » sont enregistrees et
--   listees pour l'Administration ; leur lecture par les destinataires
--   attend un contrat d'ecran (PortAnnonces ne porte que des annonces de
--   Classe) et une notification B-09 ;
-- * A6 conservation : aucun effacement automatique dans ce lot (meme regle
--   que C2 des messages).

BEGIN;

CREATE TABLE public.com_annonces (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  auteur_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  audience text NOT NULL CHECK (audience IN ('classe', 'familles', 'enseignants', 'toutes')),
  groupe_id uuid REFERENCES public.groupes(id) ON DELETE RESTRICT,
  titre text NOT NULL CHECK (pg_catalog.btrim(titre) <> '' AND pg_catalog.length(titre) <= 120),
  texte text NOT NULL CHECK (pg_catalog.btrim(texte) <> '' AND pg_catalog.length(texte) <= 5000),
  diffusee_le timestamptz NOT NULL,
  programmee boolean NOT NULL,
  cle_idempotence uuid NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT com_annonces_classe_coherente CHECK ((audience = 'classe') = (groupe_id IS NOT NULL)),
  CONSTRAINT com_annonces_idempotence UNIQUE (auteur_id, cle_idempotence)
);
CREATE INDEX com_annonces_groupe_idx ON public.com_annonces (groupe_id, diffusee_le DESC, id DESC)
  WHERE groupe_id IS NOT NULL;
CREATE INDEX com_annonces_diffusion_idx ON public.com_annonces (diffusee_le);

CREATE TABLE public.com_annonce_lectures (
  annonce_id uuid NOT NULL REFERENCES public.com_annonces(id) ON DELETE RESTRICT,
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  lue_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  PRIMARY KEY (annonce_id, profile_id)
);

ALTER TABLE public.com_annonces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.com_annonce_lectures ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.com_annonces, public.com_annonce_lectures
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER com_annonces_ajout_seul BEFORE UPDATE OR DELETE ON public.com_annonces
  FOR EACH ROW EXECUTE FUNCTION private.com_refuser_mutation();

COMMENT ON TABLE public.com_annonces IS
  'COM-BACK-1 : annonces en ajout seul (A3). Lecture et publication par les '
  'RPC com_annonce* seulement, aucune policy.';

-- L'appelant lit-il les annonces de la Classe ? Compte valide, y compris
-- un eleve mineur membre actif (lecture seule).
CREATE FUNCTION private.com_lit_classe(p_groupe_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT coalesce(public.app_account_valid(), false)
    AND private.com_profil_valide(auth.uid(), public.app_role()::text)
    AND EXISTS (
      SELECT 1 FROM public.groupes g
      WHERE g.id = p_groupe_id AND g.ended_at IS NULL
        AND (
          (public.app_role() = 'admin')
          OR (public.app_role() = 'teacher' AND g.teacher_id = auth.uid())
          OR EXISTS (
            SELECT 1 FROM public.groupe_membres m
            JOIN public.profiles s ON s.id = m.student_id AND s.deleted_at IS NULL
            JOIN public.profiles moi ON moi.id = auth.uid()
            WHERE m.groupe_id = g.id AND m.left_at IS NULL
              AND (s.id = moi.id
                   OR (moi.role = 'guardian' AND moi.household_id IS NOT NULL
                       AND s.household_id = moi.household_id)))));
$function$;

-- L'appelant publie-t-il pour cette Classe ? Enseignant de la Classe ou
-- Administration, jamais un mineur.
CREATE FUNCTION private.com_publie_classe(p_groupe_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT EXISTS (SELECT 1 FROM private.com_appelant() a WHERE a.role IN ('admin', 'teacher'))
    AND EXISTS (
      SELECT 1 FROM public.groupes g
      WHERE g.id = p_groupe_id AND g.ended_at IS NULL
        AND (public.app_role() = 'admin'
             OR (public.app_role() = 'teacher' AND g.teacher_id = auth.uid())));
$function$;

CREATE FUNCTION private.com_annonce_json(p_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', a.id, 'titre', a.titre, 'texte', a.texte,
    'publiee_le', a.diffusee_le,
    'classe', pg_catalog.jsonb_build_object('id', g.id, 'libelle', g.libelle),
    'auteur', CASE WHEN auteur.role = 'teacher'
                THEN private.com_participant('profil', auteur.id, 'classe', g.id)
                ELSE private.com_participant('equipe', NULL, 'classe', g.id) END,
    'lue', EXISTS (SELECT 1 FROM public.com_annonce_lectures l
                    WHERE l.annonce_id = a.id AND l.profile_id = auth.uid()))
  FROM public.com_annonces a
  JOIN public.groupes g ON g.id = a.groupe_id
  JOIN public.profiles auteur ON auteur.id = a.auteur_id
  WHERE a.id = p_id;
$function$;

REVOKE ALL ON FUNCTION private.com_lit_classe(uuid), private.com_publie_classe(uuid),
  private.com_annonce_json(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Les annonces diffusees d'une Classe, et la capacite de publier.
CREATE FUNCTION public.com_annonces_de_classe(p_groupe_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
BEGIN
  IF p_groupe_id IS NULL OR NOT private.com_lit_classe(p_groupe_id) THEN
    RAISE EXCEPTION 'COM-BACK-1 annonces non autorisees' USING ERRCODE = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'annonces', coalesce((
      SELECT pg_catalog.jsonb_agg(private.com_annonce_json(a.id) ORDER BY a.diffusee_le DESC, a.id DESC)
      FROM public.com_annonces a
      WHERE a.groupe_id = p_groupe_id AND a.diffusee_le <= pg_catalog.clock_timestamp()), '[]'::jsonb),
    'peut_publier', private.com_publie_classe(p_groupe_id));
END;
$function$;

-- Une annonce diffusee, ou null (absente, programmee ou non autorisee).
CREATE FUNCTION public.com_annonce_lire(p_annonce_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v_groupe uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  SELECT a.groupe_id INTO v_groupe FROM public.com_annonces a
  WHERE a.id = p_annonce_id AND a.groupe_id IS NOT NULL
    AND a.diffusee_le <= pg_catalog.clock_timestamp();
  IF v_groupe IS NULL OR NOT private.com_lit_classe(v_groupe) THEN RETURN NULL; END IF;
  RETURN private.com_annonce_json(p_annonce_id);
END;
$function$;

CREATE FUNCTION public.com_annonce_marquer_lue(p_annonce_id uuid)
RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
BEGIN
  IF public.com_annonce_lire(p_annonce_id) IS NULL THEN
    RAISE EXCEPTION 'COM-BACK-1 annonce indisponible' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.com_annonce_lectures (annonce_id, profile_id)
  VALUES (p_annonce_id, auth.uid())
  ON CONFLICT (annonce_id, profile_id) DO NOTHING;
END;
$function$;

-- Les audiences ouvertes a l'appelant (identifiants opaques revalides a la
-- publication) : 'classe:<uuid>', 'familles', 'enseignants', 'toutes'.
CREATE FUNCTION public.com_annonces_cibles(p_groupe_id uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  moi record;
  v_resultat jsonb;
BEGIN
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(c.cible ORDER BY c.rang, c.cible ->> 'libelle', c.cible ->> 'id'), '[]'::jsonb)
    INTO v_resultat
  FROM (
    SELECT 0 AS rang, pg_catalog.jsonb_build_object('id', x.code, 'nature',
             CASE x.code WHEN 'toutes' THEN 'toutes' ELSE 'public' END, 'libelle', x.code) AS cible
      FROM (VALUES ('toutes'), ('familles'), ('enseignants')) AS x(code)
      WHERE moi.role = 'admin' AND p_groupe_id IS NULL
    UNION ALL
    SELECT 1, pg_catalog.jsonb_build_object('id', 'classe:' || g.id::text, 'nature', 'classe',
             'classe_id', g.id, 'libelle', g.libelle)
      FROM public.groupes g
      WHERE g.ended_at IS NULL
        AND (p_groupe_id IS NULL OR g.id = p_groupe_id)
        AND private.com_publie_classe(g.id)
  ) c;
  RETURN v_resultat;
END;
$function$;

-- Publie ou programme. Rend l'accuse ; une cle rejouee rend le meme accuse.
CREATE FUNCTION public.com_annonce_publier(
  p_cible text, p_titre text, p_texte text, p_programmee_le timestamptz, p_cle_idempotence uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  moi record;
  v_audience text;
  v_groupe uuid;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
  v_ligne public.com_annonces%ROWTYPE;
BEGIN
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL OR moi.role NOT IN ('admin', 'teacher') THEN
    RAISE EXCEPTION 'COM-BACK-1 publication non autorisee' USING ERRCODE = '42501';
  END IF;
  IF p_cle_idempotence IS NULL OR p_cible IS NULL
     OR p_titre IS NULL OR pg_catalog.btrim(p_titre) = '' OR pg_catalog.length(pg_catalog.btrim(p_titre)) > 120
     OR p_texte IS NULL OR pg_catalog.btrim(p_texte) = '' OR pg_catalog.length(pg_catalog.btrim(p_texte)) > 5000 THEN
    RAISE EXCEPTION 'COM-BACK-1 annonce invalide' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_ligne FROM public.com_annonces a
  WHERE a.auteur_id = moi.id AND a.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    RETURN pg_catalog.jsonb_build_object('id', v_ligne.id,
      'etat', CASE WHEN v_ligne.diffusee_le > v_maintenant THEN 'planifiee' ELSE 'publiee' END,
      'le', v_ligne.diffusee_le);
  END IF;
  IF p_cible LIKE 'classe:%' THEN
    BEGIN
      v_groupe := pg_catalog.substr(p_cible, 8)::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'COM-BACK-1 audience invalide' USING ERRCODE = '22023';
    END;
    IF NOT private.com_publie_classe(v_groupe) THEN
      RAISE EXCEPTION 'COM-BACK-1 audience non autorisee' USING ERRCODE = '42501';
    END IF;
    v_audience := 'classe';
  ELSIF p_cible IN ('toutes', 'familles', 'enseignants') THEN
    IF moi.role <> 'admin' THEN
      RAISE EXCEPTION 'COM-BACK-1 audience non autorisee' USING ERRCODE = '42501';
    END IF;
    v_audience := p_cible;
  ELSE
    RAISE EXCEPTION 'COM-BACK-1 audience invalide' USING ERRCODE = '22023';
  END IF;
  IF p_programmee_le IS NOT NULL THEN
    IF moi.role <> 'admin' THEN
      RAISE EXCEPTION 'COM-BACK-1 programmation non autorisee' USING ERRCODE = '42501';
    END IF;
    IF p_programmee_le < v_maintenant + interval '5 minutes'
       OR p_programmee_le > v_maintenant + interval '14 days' THEN
      RAISE EXCEPTION 'COM-BACK-1 date de diffusion hors bornes' USING ERRCODE = '22023';
    END IF;
  END IF;
  INSERT INTO public.com_annonces
    (auteur_id, audience, groupe_id, titre, texte, diffusee_le, programmee, cle_idempotence)
  VALUES (moi.id, v_audience, v_groupe, pg_catalog.btrim(p_titre), pg_catalog.btrim(p_texte),
          coalesce(p_programmee_le, v_maintenant), p_programmee_le IS NOT NULL, p_cle_idempotence)
  RETURNING * INTO v_ligne;
  PERFORM public.log_sensitive_access('com_annonce_publier', 'com_annonces', v_ligne.id::text,
    pg_catalog.jsonb_build_object('audience', v_audience));
  RETURN pg_catalog.jsonb_build_object('id', v_ligne.id,
    'etat', CASE WHEN v_ligne.programmee THEN 'planifiee' ELSE 'publiee' END,
    'le', v_ligne.diffusee_le);
END;
$function$;

-- La vue de l'Administration (A4).
CREATE FUNCTION public.com_annonces_administration()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  moi record;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
BEGIN
  SELECT * INTO moi FROM private.com_appelant();
  IF moi.id IS NULL OR moi.role <> 'admin' THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  RETURN (
    WITH a AS (
      SELECT x.*, pg_catalog.jsonb_build_object(
        'id', x.id, 'titre', x.titre, 'texte', x.texte, 'le', x.diffusee_le,
        'etat', CASE WHEN x.diffusee_le > v_maintenant THEN 'planifiee' ELSE 'publiee' END,
        'cible', CASE WHEN x.audience = 'classe'
          THEN pg_catalog.jsonb_build_object('id', 'classe:' || g.id::text, 'nature', 'classe',
                 'classe_id', g.id, 'libelle', g.libelle)
          ELSE pg_catalog.jsonb_build_object('id', x.audience,
                 'nature', CASE x.audience WHEN 'toutes' THEN 'toutes' ELSE 'public' END,
                 'libelle', x.audience) END) AS j
      FROM public.com_annonces x LEFT JOIN public.groupes g ON g.id = x.groupe_id
      WHERE x.diffusee_le > v_maintenant - interval '30 days'
    )
    SELECT pg_catalog.jsonb_build_object(
      'publiees', coalesce((SELECT pg_catalog.jsonb_agg(a.j ORDER BY a.diffusee_le DESC, a.id DESC)
                              FROM a WHERE a.diffusee_le <= v_maintenant), '[]'::jsonb),
      'planifiees', coalesce((SELECT pg_catalog.jsonb_agg(a.j ORDER BY a.diffusee_le, a.id)
                                FROM a WHERE a.diffusee_le > v_maintenant), '[]'::jsonb)));
END;
$function$;

DO $acl$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.com_annonces_de_classe(uuid)',
    'public.com_annonce_lire(uuid)',
    'public.com_annonce_marquer_lue(uuid)',
    'public.com_annonces_cibles(uuid)',
    'public.com_annonce_publier(text,text,text,timestamptz,uuid)',
    'public.com_annonces_administration()'
  ] LOOP
    EXECUTE format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', f);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$acl$;

-- @@F86_DEBUT_ANNONCES@@
COMMENT ON FUNCTION public.com_annonces_de_classe(uuid) IS
  'F86: signature=public.com_annonces_de_classe(uuid); md5_functiondef=f1c53477ac8da499a419cc639844d0aa; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: lecteur de la Classe active (enseignant, Administration, foyer, eleve membre).';
COMMENT ON FUNCTION public.com_annonce_lire(uuid) IS
  'F86: signature=public.com_annonce_lire(uuid); md5_functiondef=1b5a2c4057008664d794e416e5c6d356; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: null si absente, programmee ou non autorisee.';
COMMENT ON FUNCTION public.com_annonce_marquer_lue(uuid) IS
  'F86: signature=public.com_annonce_marquer_lue(uuid); md5_functiondef=eaa2aafc59c4d8179a6f6742d43e2d72; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: lecture individuelle, annonce lisible requise.';
COMMENT ON FUNCTION public.com_annonces_cibles(uuid) IS
  'F86: signature=public.com_annonces_cibles(uuid); md5_functiondef=99ec46d31f836be3ed30cb83c4d82db8; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: enseignant: sa Classe; Administration: publics et Classes.';
COMMENT ON FUNCTION public.com_annonce_publier(text,text,text,timestamptz,uuid) IS
  'F86: signature=public.com_annonce_publier(text,text,text,timestamptz,uuid); md5_functiondef=75a43d0b3f19a440d37067e54cde8f33; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: enseignant sa Classe seulement; publics et programmation Administration; bornes A1 A2.';
COMMENT ON FUNCTION public.com_annonces_administration() IS
  'F86: signature=public.com_annonces_administration(); md5_functiondef=8b62a0001b39c0ceb6635568b261a6b9; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-10-16. Garde: Administration seule.';
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM (VALUES
    ('public.com_annonces_de_classe(uuid)'::regprocedure, 'f1c53477ac8da499a419cc639844d0aa'),
    ('public.com_annonce_lire(uuid)'::regprocedure, '1b5a2c4057008664d794e416e5c6d356'),
    ('public.com_annonce_marquer_lue(uuid)'::regprocedure, 'eaa2aafc59c4d8179a6f6742d43e2d72'),
    ('public.com_annonces_cibles(uuid)'::regprocedure, '99ec46d31f836be3ed30cb83c4d82db8'),
    ('public.com_annonce_publier(text,text,text,timestamptz,uuid)'::regprocedure, '75a43d0b3f19a440d37067e54cde8f33'),
    ('public.com_annonces_administration()'::regprocedure, '8b62a0001b39c0ceb6635568b261a6b9')
    ) AS e(oid, attendu)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> e.attendu
       OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || e.attendu || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'COM-BACK-1 ANNONCES : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_ANNONCES@@

COMMIT;
