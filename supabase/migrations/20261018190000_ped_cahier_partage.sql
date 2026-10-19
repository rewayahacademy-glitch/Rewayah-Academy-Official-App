-- PED-APRES-BACK (18/10/2026) : le partage pedagogique avec les familles, cote
-- serveur. Contrat : docs/current/PED-APRES/CONTRAT_PORTS_PED_APRES.md.
--
-- Existait deja (X2-20, X2-21) : publier_resume_seance, revoquer_resume_seance,
-- comptes_rendus_classe, lire_cahier_admin, resume_seance_famille.
-- Manquait : la regle de classe et l'exception d'un eleve, la regle effective,
-- le compte rendu structure de la famille, l'apercu de la direction, la liste
-- des comptes rendus d'un eleve.
--
-- Regle effective (priorite) : exception de l'eleve, puis classe, puis defaut
-- ACTIF. Une famille ne lit un compte rendu que s'il est publie, non revoque,
-- et soit publie a la main par la direction, soit partage automatiquement.
--
-- Pas de publication retroactive : `auto_partage` est fixe UNE fois, au moment
-- ou le compte rendu est publie par l'enseignant, selon la regle de cet instant.
-- Desactiver le partage masque tout de suite (lecture), le reactiver ne
-- montre que les comptes rendus deja partages automatiquement.
--
-- Rien d'ecrit ici ne touche au cahier K-45 (lesson_reports) ni a la paie.
BEGIN;

-- 1. Reglages -----------------------------------------------------------------

CREATE TABLE public.partage_pedagogique_classe (
  groupe_id uuid PRIMARY KEY REFERENCES public.groupes(id) ON DELETE CASCADE,
  actif boolean NOT NULL DEFAULT true,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  modifie_le timestamptz,
  modifie_par uuid REFERENCES public.profiles(id) ON DELETE SET NULL
);
ALTER TABLE public.partage_pedagogique_classe ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.partage_pedagogique_classe FROM PUBLIC, anon, authenticated, agent_ro, service_role;

CREATE TABLE public.partage_pedagogique_eleve (
  groupe_id uuid NOT NULL REFERENCES public.groupes(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  regle text NOT NULL CHECK (regle IN ('toujours', 'jamais')),
  modifie_le timestamptz NOT NULL DEFAULT now(),
  modifie_par uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  PRIMARY KEY (groupe_id, student_id)
);
ALTER TABLE public.partage_pedagogique_eleve ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.partage_pedagogique_eleve FROM PUBLIC, anon, authenticated, agent_ro, service_role;

-- auto_partage : le compte rendu etait partageable automatiquement quand
-- l'enseignant l'a publie (fige, jamais recalcule : pas de retroactif).
-- regle_ouverte : la regle effective de l'eleve est ouverte MAINTENANT (tenue a
-- jour par private.partage_ecrire). Lisible = publication manuelle, ou les deux.
ALTER TABLE public.seance_resumes
  ADD COLUMN auto_partage boolean NOT NULL DEFAULT false,
  ADD COLUMN regle_ouverte boolean NOT NULL DEFAULT true;
-- Les comptes rendus deja publies avant ce lot restent lisibles (defaut actif).
UPDATE public.seance_resumes SET auto_partage = true WHERE publie_le IS NOT NULL;

-- 2. Aides internes (schema private, jamais appelables par un compte) ----------

CREATE OR REPLACE FUNCTION private.partage_regle_effective(p_groupe uuid, p_student uuid)
RETURNS TABLE (actif boolean, source text)
LANGUAGE sql STABLE SET search_path = ''
AS $function$
  SELECT
    CASE WHEN e.regle IS NOT NULL THEN e.regle = 'toujours'
         ELSE coalesce(c.actif, true) END,
    CASE WHEN e.regle IS NOT NULL THEN 'exceptionEleve'
         WHEN c.groupe_id IS NOT NULL THEN 'classe'
         ELSE 'defaut' END
  FROM (SELECT 1) un
  LEFT JOIN public.partage_pedagogique_classe c ON c.groupe_id = p_groupe
  LEFT JOIN public.partage_pedagogique_eleve e
    ON e.groupe_id = p_groupe AND e.student_id = p_student;
$function$;

CREATE OR REPLACE FUNCTION private.partage_etat(
  p_confirme boolean, p_publie timestamptz, p_revoque timestamptz,
  p_manuel boolean, p_auto boolean
)
RETURNS text
LANGUAGE sql IMMUTABLE SET search_path = ''
AS $function$
  SELECT CASE
    WHEN NOT coalesce(p_confirme, false) THEN 'nonValide'
    WHEN p_revoque IS NOT NULL THEN 'revoque'
    WHEN coalesce(p_manuel, false) AND p_publie IS NOT NULL THEN 'partageManuel'
    WHEN p_publie IS NOT NULL AND coalesce(p_auto, false) THEN 'partageAuto'
    ELSE 'confirmeNonPartage'
  END;
$function$;

-- La projection familiale : uniquement des champs partageables. Elle ne lit ni
-- `motif_exception`, ni la note du groupe, ni les autres eleves. L'appreciation
-- est ramenee aux deux etats montres aux familles (docs/current/REGISTRE-
-- RECONCILIATION-2026-10-14.md) ; les mots sont ceux de l'application.
CREATE OR REPLACE FUNCTION private.partage_projection(
  p_texte text, p_entree jsonb, p_corrige timestamptz
)
RETURNS jsonb
LANGUAGE sql IMMUTABLE SET search_path = ''
AS $function$
  SELECT jsonb_build_object(
    'travaille', nullif(btrim(coalesce(p_texte, '')), ''),
    'appreciation', CASE p_entree ->> 'performance'
      WHEN 'aRevoir' THEN 'a_renforcer'
      WHEN 'enProgres' THEN 'a_renforcer'
      WHEN 'acquis' THEN 'acquis'
      WHEN 'maitrise' THEN 'acquis'
      ELSE NULL END,
    'a_renforcer', coalesce((
      SELECT jsonb_agg(f.v ORDER BY f.n)
      FROM (
        SELECT x.v, min(x.n) AS n
        FROM jsonb_array_elements_text(
          CASE WHEN jsonb_typeof(p_entree -> 'faiblesses') = 'array'
            THEN p_entree -> 'faiblesses' ELSE '[]'::jsonb END
        ) WITH ORDINALITY AS x(v, n)
        WHERE x.v IN ('makharij', 'madd', 'ghunna', 'waqf', 'fluidite', 'memorisation')
        GROUP BY x.v
      ) f
    ), '[]'::jsonb),
    'a_preparer', coalesce((
      SELECT jsonb_agg(l.t ORDER BY l.n)
      FROM (
        SELECT left(btrim(x.t), 300) AS t, x.n
        FROM regexp_split_to_table(coalesce(p_entree ->> 'travail_maison', ''), E'\\r?\\n')
          WITH ORDINALITY AS x(t, n)
        WHERE btrim(x.t) <> ''
        ORDER BY x.n
        LIMIT 10
      ) l
    ), '[]'::jsonb),
    'commentaire_partage', NULL,
    'corrige_le', p_corrige
  );
$function$;

-- Chaque eleve d'un cahier de la classe, avec l'etat de diffusion de son compte
-- rendu. Meme perimetre que X2-21 (comptes_rendus_classe), factorise.
CREATE OR REPLACE FUNCTION private.partage_cahiers_classe(p_classe uuid)
RETURNS TABLE (session_id uuid, student_id uuid, first_name text,
               ended_at timestamptz, etat text)
LANGUAGE sql STABLE SET search_path = ''
AS $function$
  SELECT DISTINCT ON (s.id, p.id)
    s.id, p.id, p.first_name, s.ended_at,
    private.partage_etat(
      coalesce((e.value ->> 'confirme')::boolean, false),
      r.publie_le, r.revoque_le, r.publication_manuelle, r.auto_partage AND r.regle_ouverte)
  FROM public.sessions s
  JOIN public.lesson_reports lr ON lr.session_id = s.id AND lr.deleted_at IS NULL
  CROSS JOIN LATERAL pg_catalog.jsonb_array_elements(
    CASE WHEN jsonb_typeof(lr.content -> 'eleves') = 'array'
      THEN lr.content -> 'eleves' ELSE '[]'::jsonb END
  ) e(value)
  JOIN public.profiles p ON p.id = (e.value ->> 'student_id')::uuid
    AND p.deleted_at IS NULL
  JOIN public.groupe_membres m ON m.groupe_id = s.groupe_id AND m.student_id = p.id
    AND m.joined_at <= s.ended_at
    AND (m.left_at IS NULL OR m.left_at >= s.started_at)
  LEFT JOIN public.seance_resumes r ON r.session_id = s.id AND r.student_id = p.id
  WHERE s.groupe_id = p_classe AND s.deleted_at IS NULL
  ORDER BY s.id, p.id, lr.updated_at DESC, lr.id DESC;
$function$;

-- La regle de l'instant est figee sur le compte rendu quand l'enseignant le
-- publie : jamais de publication retroactive.
CREATE OR REPLACE FUNCTION private.fixer_auto_partage_resume()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_groupe uuid;
BEGIN
  IF NEW.publie_le IS NOT NULL
     AND (TG_OP = 'INSERT' OR OLD.publie_le IS NULL) THEN
    SELECT s.groupe_id INTO v_groupe FROM public.sessions s WHERE s.id = NEW.session_id;
    NEW.auto_partage := coalesce(
      (SELECT r.actif FROM private.partage_regle_effective(v_groupe, NEW.student_id) r),
      true);
    NEW.regle_ouverte := NEW.auto_partage;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS seance_resume_auto_partage ON public.seance_resumes;
CREATE TRIGGER seance_resume_auto_partage
BEFORE INSERT OR UPDATE OF publie_le ON public.seance_resumes
FOR EACH ROW EXECUTE FUNCTION private.fixer_auto_partage_resume();

DO $aides$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.partage_regle_effective(uuid,uuid)'::regprocedure,
    'private.partage_etat(boolean,timestamptz,timestamptz,boolean,boolean)'::regprocedure,
    'private.partage_projection(text,jsonb,timestamptz)'::regprocedure,
    'private.partage_cahiers_classe(uuid)'::regprocedure,
    'private.fixer_auto_partage_resume()'::regprocedure
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
END;
$aides$;

-- 3. Lecture famille : un compte rendu non partage n'est lisible nulle part ----

DROP POLICY seance_resumes_lecture ON public.seance_resumes;
CREATE POLICY seance_resumes_lecture
  ON public.seance_resumes
  FOR SELECT TO authenticated
  USING (
    (
      coalesce(public.app_role() = 'teacher' AND public.app_account_valid(), false)
      AND EXISTS (
        SELECT 1 FROM public.sessions s
        WHERE s.id = seance_resumes.session_id
          AND s.teacher_id = auth.uid()
          AND s.deleted_at IS NULL
      )
    )
    OR
    (
      seance_resumes.publie_le IS NOT NULL
      AND seance_resumes.revoque_le IS NULL
      AND (seance_resumes.publication_manuelle
           OR (seance_resumes.auto_partage AND seance_resumes.regle_ouverte))
      AND coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false)
      AND EXISTS (
        SELECT 1
        FROM public.profiles p
        JOIN public.student_profiles sp ON sp.profile_id = p.id
        WHERE p.id = seance_resumes.student_id
          AND p.deleted_at IS NULL
          AND sp.deleted_at IS NULL
          AND (
            (p.role = 'student' AND p.household_id IS NOT NULL
              AND p.household_id = public.app_household_id())
            OR (p.id = auth.uid() AND sp.titulaire_profile_id = auth.uid())
          )
      )
    )
  );

-- 4. Lectures famille existantes, sous la meme condition de partage
CREATE OR REPLACE FUNCTION public.resume_seance_famille(
  p_session_id uuid,
  p_student_id uuid
)
RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_resume text;
BEGIN
  IF v_user IS NULL OR p_session_id IS NULL OR p_student_id IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false)
     OR NOT EXISTS (
       SELECT 1 FROM public.profiles p
       JOIN public.student_profiles sp ON sp.profile_id = p.id
       WHERE p.id = p_student_id AND p.deleted_at IS NULL AND sp.deleted_at IS NULL
         AND ((p.role = 'student' AND p.household_id IS NOT NULL
               AND p.household_id = public.app_household_id())
              OR (p.id = v_user AND sp.titulaire_profile_id = v_user))
     ) THEN
    RAISE EXCEPTION 'resume indisponible';
  END IF;
  SELECT r.texte_famille INTO v_resume
    FROM public.seance_resumes r
   WHERE r.session_id = p_session_id AND r.student_id = p_student_id
     AND r.publie_le IS NOT NULL AND r.revoque_le IS NULL AND (r.publication_manuelle OR (r.auto_partage AND r.regle_ouverte));
  RETURN v_resume;
END;
$function$;
ALTER FUNCTION public.resume_seance_famille(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.resume_seance_famille(uuid, uuid) FROM PUBLIC, anon, agent_ro, service_role;
GRANT EXECUTE ON FUNCTION public.resume_seance_famille(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.progression_famille(
  p_student_id uuid,
  p_limit integer DEFAULT 20
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_level text;
  v_niveau_humain text;
  v_jalon_humain text;
  v_jalons jsonb;
  v_seances jsonb;
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
BEGIN
  IF v_user IS NULL OR p_student_id IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'progression indisponible';
  END IF;
  SELECT sp.level INTO v_level
    FROM public.profiles p JOIN public.student_profiles sp ON sp.profile_id = p.id
   WHERE p.id = p_student_id AND p.deleted_at IS NULL AND sp.deleted_at IS NULL
     AND ((p.role = 'student' AND p.household_id IS NOT NULL
           AND p.household_id = public.app_household_id())
          OR (p.id = v_user AND sp.titulaire_profile_id = v_user));
  IF NOT FOUND THEN RAISE EXCEPTION 'progression indisponible'; END IF;

  SELECT CASE WHEN count(DISTINCT n.nom_humain) = 1 THEN min(n.nom_humain) ELSE NULL END
    INTO v_niveau_humain
    FROM public.programme_niveaux n
    JOIN public.programme_versions v ON v.id = n.version_id
   WHERE n.code_technique = v_level AND v.statut = 'publiee';

  SELECT n.nom_humain INTO v_jalon_humain
    FROM public.seance_resumes r
    JOIN public.programme_niveaux n ON n.id = r.jalon_atteint
   WHERE r.student_id = p_student_id AND r.publie_le IS NOT NULL
     AND r.revoque_le IS NULL AND (r.publication_manuelle OR (r.auto_partage AND r.regle_ouverte)) AND r.jalon_atteint IS NOT NULL
   ORDER BY r.publie_le DESC LIMIT 1;

  SELECT coalesce(jsonb_agg(q.nom_humain ORDER BY q.derniere_publication DESC), '[]'::jsonb)
    INTO v_jalons
    FROM (
      SELECT n.nom_humain, max(r.publie_le) AS derniere_publication
        FROM public.seance_resumes r
        JOIN public.programme_niveaux n ON n.id = r.jalon_atteint
       WHERE r.student_id = p_student_id AND r.publie_le IS NOT NULL
         AND r.revoque_le IS NULL AND (r.publication_manuelle OR (r.auto_partage AND r.regle_ouverte))
       GROUP BY n.nom_humain
    ) q;

  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'session_id', q.session_id, 'texte_famille', q.texte_famille,
    'publie_le', q.publie_le, 'jalon_humain', q.jalon_humain
  ) ORDER BY q.publie_le DESC), '[]'::jsonb)
    INTO v_seances
    FROM (
      SELECT r.session_id, r.texte_famille, r.publie_le, n.nom_humain AS jalon_humain
        FROM public.seance_resumes r
        LEFT JOIN public.programme_niveaux n ON n.id = r.jalon_atteint
       WHERE r.student_id = p_student_id AND r.publie_le IS NOT NULL
         AND r.revoque_le IS NULL AND (r.publication_manuelle OR (r.auto_partage AND r.regle_ouverte))
       ORDER BY r.publie_le DESC LIMIT v_limit
    ) q;

  RETURN jsonb_build_object('niveau_humain', v_niveau_humain,
    'jalon_humain', v_jalon_humain, 'jalons', v_jalons, 'seances', v_seances);
END;
$function$;
ALTER FUNCTION public.progression_famille(uuid, integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.progression_famille(uuid, integer) FROM PUBLIC, anon, agent_ro, service_role;
GRANT EXECUTE ON FUNCTION public.progression_famille(uuid, integer) TO authenticated;

-- 5. Les RPC du port PortPartagePedagogique ------------------------------------

-- Comptes rendus d'une classe : meme sortie que X2-21, etat de diffusion tenant
-- compte du partage automatique.
CREATE OR REPLACE FUNCTION public.comptes_rendus_classe(
  p_classe_id uuid,
  p_page integer DEFAULT 1,
  p_filtre_etat text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  -- Garde page * 50 dans l'entier positif utilise par row_number().
  v_page integer := least(greatest(coalesce(p_page, 1), 1), 42949672);
  v_etat text := nullif(p_filtre_etat, '');
  v_lignes jsonb;
  v_total integer;
BEGIN
  IF auth.uid() IS NULL OR p_classe_id IS NULL
     OR NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'lecture administrative refusee';
  END IF;
  IF v_etat IS NOT NULL AND v_etat NOT IN (
    'nonValide', 'confirmeNonPartage', 'partageAuto', 'partageManuel', 'revoque',
    'corrigeApresPartageManuel'
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'filtre de diffusion invalide';
  END IF;

  SELECT count(*)::integer,
    coalesce(jsonb_agg(jsonb_build_object(
      'seance_id', q.session_id, 'eleve_id', q.student_id,
      'eleve_prenom', q.first_name, 'seance_le', q.ended_at, 'etat', q.etat
    ) ORDER BY q.ended_at DESC, q.student_id)
    FILTER (WHERE q.rang BETWEEN ((v_page - 1) * 50 + 1) AND (v_page * 50)), '[]'::jsonb)
  INTO v_total, v_lignes
  FROM (
    SELECT f.*, row_number() OVER (ORDER BY f.ended_at DESC, f.student_id) AS rang
    FROM private.partage_cahiers_classe(p_classe_id) f
    WHERE v_etat IS NULL OR f.etat = v_etat
  ) q;

  RETURN jsonb_build_object('lignes', v_lignes, 'total', v_total, 'page', v_page);
END;
$function$;
ALTER FUNCTION public.comptes_rendus_classe(uuid, integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.comptes_rendus_classe(uuid, integer, text) FROM PUBLIC, anon, agent_ro, service_role;
GRANT EXECUTE ON FUNCTION public.comptes_rendus_classe(uuid, integer, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.comptes_rendus_eleve(
  p_classe_id uuid,
  p_eleve_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL OR p_classe_id IS NULL OR p_eleve_id IS NULL
     OR NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'lecture administrative refusee';
  END IF;
  RETURN jsonb_build_object('lignes', coalesce((
    SELECT jsonb_agg(jsonb_build_object(
      'seance_id', f.session_id, 'seance_le', f.ended_at, 'etat', f.etat
    ) ORDER BY f.ended_at DESC)
    FROM (
      SELECT * FROM private.partage_cahiers_classe(p_classe_id) c
      WHERE c.student_id = p_eleve_id
      ORDER BY c.ended_at DESC LIMIT 200
    ) f
  ), '[]'::jsonb));
END;
$function$;
ALTER FUNCTION public.comptes_rendus_eleve(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.comptes_rendus_eleve(uuid, uuid) FROM PUBLIC, anon, agent_ro, service_role;
GRANT EXECUTE ON FUNCTION public.comptes_rendus_eleve(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.partage_classe(
  p_classe_id uuid,
  p_page integer DEFAULT 1,
  p_recherche text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_page integer := least(greatest(coalesce(p_page, 1), 1), 1000000);
  v_recherche text := lower(btrim(coalesce(p_recherche, '')));
  v_classe public.partage_pedagogique_classe%ROWTYPE;
  v_eleves jsonb;
  v_total integer;
BEGIN
  IF auth.uid() IS NULL OR p_classe_id IS NULL
     OR NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'partage pedagogique refuse';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = p_classe_id) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'classe introuvable';
  END IF;
  SELECT c.* INTO v_classe FROM public.partage_pedagogique_classe c WHERE c.groupe_id = p_classe_id;

  SELECT count(*)::integer,
    coalesce(jsonb_agg(jsonb_build_object(
      'eleve_id', q.student_id, 'libelle', q.libelle,
      'regle', coalesce(q.regle, 'regleClasse'),
      'source', q.source, 'visible', q.visible,
      'situation', CASE WHEN q.membre_actif THEN 'actif' ELSE 'retire' END,
      'modifie_le', q.modifie_le
    ) ORDER BY q.rang) FILTER (WHERE q.rang BETWEEN ((v_page - 1) * 50 + 1) AND (v_page * 50)),
    '[]'::jsonb)
  INTO v_total, v_eleves
  FROM (
    SELECT m.*, row_number() OVER (ORDER BY m.membre_actif DESC, m.libelle, m.student_id) AS rang
    FROM (
      SELECT p.id AS student_id,
        btrim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')) AS libelle,
        bool_or(gm.left_at IS NULL) AS membre_actif,
        (SELECT e.regle FROM public.partage_pedagogique_eleve e
          WHERE e.groupe_id = p_classe_id AND e.student_id = p.id) AS regle,
        (SELECT e.modifie_le FROM public.partage_pedagogique_eleve e
          WHERE e.groupe_id = p_classe_id AND e.student_id = p.id) AS modifie_le,
        (SELECT r.source FROM private.partage_regle_effective(p_classe_id, p.id) r) AS source,
        (SELECT r.actif FROM private.partage_regle_effective(p_classe_id, p.id) r) AS visible
      FROM public.groupe_membres gm
      JOIN public.profiles p ON p.id = gm.student_id AND p.deleted_at IS NULL
      WHERE gm.groupe_id = p_classe_id
      GROUP BY p.id, p.first_name, p.last_name
    ) m
    WHERE v_recherche = '' OR position(v_recherche IN lower(m.libelle)) > 0
  ) q;

  RETURN jsonb_build_object(
    'classe_id', p_classe_id,
    'actif', coalesce(v_classe.actif, true),
    'version', coalesce(v_classe.version, 1)::text,
    'eleves', v_eleves,
    'total', v_total,
    'page', v_page,
    'modifie_le', v_classe.modifie_le
  );
END;
$function$;
ALTER FUNCTION public.partage_classe(uuid, integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.partage_classe(uuid, integer, text) FROM PUBLIC, anon, agent_ro, service_role;
GRANT EXECUTE ON FUNCTION public.partage_classe(uuid, integer, text) TO authenticated;

-- Pose la regle de classe (p_eleve_id NULL) ou l'exception d'un eleve.
-- p_regle : 'actif' | 'inactif' pour la classe ; 'regleClasse' | 'toujours' |
-- 'jamais' pour un eleve. Une seule version de concurrence pour la classe.
CREATE OR REPLACE FUNCTION private.partage_ecrire(
  p_operation text, p_classe_id uuid, p_eleve_id uuid, p_regle text,
  p_version_attendue text, p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_actor uuid := auth.uid();
  v_request jsonb;
  v_previous public.pedagogie_partage_idempotence%ROWTYPE;
  v_classe public.partage_pedagogique_classe%ROWTYPE;
  v_result jsonb;
  v_change boolean := false;
BEGIN
  IF v_actor IS NULL OR p_classe_id IS NULL
     OR coalesce(length(btrim(p_cle_idempotence)), 0) NOT BETWEEN 1 AND 200
     OR NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'partage pedagogique refuse';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = p_classe_id) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'classe introuvable';
  END IF;
  IF p_eleve_id IS NULL AND p_regle NOT IN ('actif', 'inactif') THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'regle de classe invalide';
  END IF;
  IF p_eleve_id IS NOT NULL AND p_regle NOT IN ('regleClasse', 'toujours', 'jamais') THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'regle d eleve invalide';
  END IF;
  IF p_eleve_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.groupe_membres m
     WHERE m.groupe_id = p_classe_id AND m.student_id = p_eleve_id
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'eleve hors de la classe';
  END IF;

  v_request := jsonb_build_object('classe_id', p_classe_id, 'eleve_id', p_eleve_id,
    'regle', p_regle, 'version_attendue', p_version_attendue);
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_actor::text || ':' || p_cle_idempotence, 0));
  SELECT i.* INTO v_previous FROM public.pedagogie_partage_idempotence i
   WHERE i.actor_id = v_actor AND i.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF v_previous.operation <> p_operation OR v_previous.requete IS DISTINCT FROM v_request THEN
      RAISE EXCEPTION USING ERRCODE = '23505', MESSAGE = 'cle idempotence reutilisee';
    END IF;
    RETURN v_previous.resultat;
  END IF;

  INSERT INTO public.partage_pedagogique_classe (groupe_id) VALUES (p_classe_id)
    ON CONFLICT (groupe_id) DO NOTHING;
  SELECT c.* INTO v_classe FROM public.partage_pedagogique_classe c
   WHERE c.groupe_id = p_classe_id FOR UPDATE;
  IF p_version_attendue IS DISTINCT FROM v_classe.version::text THEN
    RAISE EXCEPTION USING ERRCODE = '40001', MESSAGE = 'conflit_partage';
  END IF;

  IF p_eleve_id IS NULL THEN
    v_change := v_classe.actif IS DISTINCT FROM (p_regle = 'actif');
    IF v_change THEN
      UPDATE public.partage_pedagogique_classe
         SET actif = (p_regle = 'actif'), version = version + 1,
             modifie_le = now(), modifie_par = v_actor
       WHERE groupe_id = p_classe_id;
    END IF;
  ELSIF p_regle = 'regleClasse' THEN
    DELETE FROM public.partage_pedagogique_eleve
     WHERE groupe_id = p_classe_id AND student_id = p_eleve_id;
    v_change := FOUND;
  ELSE
    INSERT INTO public.partage_pedagogique_eleve AS e (groupe_id, student_id, regle, modifie_par)
    VALUES (p_classe_id, p_eleve_id, p_regle, v_actor)
    ON CONFLICT (groupe_id, student_id) DO UPDATE
      SET regle = EXCLUDED.regle, modifie_le = now(), modifie_par = v_actor
      WHERE e.regle IS DISTINCT FROM EXCLUDED.regle;
    v_change := FOUND;
  END IF;
  IF v_change THEN
    -- La regle effective change : les comptes rendus deja crees la suivent.
    UPDATE public.seance_resumes r
       SET regle_ouverte = coalesce((
         SELECT x.actif FROM private.partage_regle_effective(s.groupe_id, r.student_id) x), true)
      FROM public.sessions s
     WHERE s.id = r.session_id AND s.groupe_id = p_classe_id
       AND (p_eleve_id IS NULL OR r.student_id = p_eleve_id);
    IF p_eleve_id IS NOT NULL THEN
      UPDATE public.partage_pedagogique_classe
         SET version = version + 1, modifie_le = now(), modifie_par = v_actor
       WHERE groupe_id = p_classe_id;
    END IF;
    PERFORM public.log_sensitive_access(
      CASE WHEN p_eleve_id IS NULL THEN 'partage_classe_modifie' ELSE 'partage_eleve_modifie' END,
      'partage_pedagogique', p_classe_id::text || coalesce(':' || p_eleve_id::text, ''),
      jsonb_build_object('classe_id', p_classe_id, 'eleve_id', p_eleve_id, 'regle', p_regle));
  END IF;

  v_result := public.partage_classe(p_classe_id, 1, NULL);
  INSERT INTO public.pedagogie_partage_idempotence
    (actor_id, cle_idempotence, operation, requete, resultat)
  VALUES (v_actor, p_cle_idempotence, p_operation, v_request, v_result);
  RETURN v_result;
END;
$function$;
ALTER FUNCTION private.partage_ecrire(text, uuid, uuid, text, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.partage_ecrire(text, uuid, uuid, text, text, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE OR REPLACE FUNCTION public.definir_partage_classe(
  p_classe_id uuid, p_actif boolean, p_version_attendue text, p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL OR p_actif IS NULL
     OR NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'partage pedagogique refuse';
  END IF;
  RETURN private.partage_ecrire('definir_classe', p_classe_id, NULL,
    CASE WHEN p_actif THEN 'actif' ELSE 'inactif' END, p_version_attendue, p_cle_idempotence);
END;
$function$;
ALTER FUNCTION public.definir_partage_classe(uuid, boolean, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.definir_partage_classe(uuid, boolean, text, text) FROM PUBLIC, anon, agent_ro, service_role;
GRANT EXECUTE ON FUNCTION public.definir_partage_classe(uuid, boolean, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.definir_regle_partage_eleve(
  p_classe_id uuid, p_eleve_id uuid, p_regle text, p_version_attendue text, p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL OR p_eleve_id IS NULL
     OR NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'partage pedagogique refuse';
  END IF;
  RETURN private.partage_ecrire('definir_eleve', p_classe_id, p_eleve_id, p_regle,
    p_version_attendue, p_cle_idempotence);
END;
$function$;
ALTER FUNCTION public.definir_regle_partage_eleve(uuid, uuid, text, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.definir_regle_partage_eleve(uuid, uuid, text, text, text) FROM PUBLIC, anon, agent_ro, service_role;
GRANT EXECUTE ON FUNCTION public.definir_regle_partage_eleve(uuid, uuid, text, text, text) TO authenticated;

-- Ce que la famille lit d'une seance : la projection, jamais le cahier brut.
CREATE OR REPLACE FUNCTION public.compte_rendu_famille(
  p_seance_id uuid,
  p_eleve_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_session public.sessions%ROWTYPE;
  v_entree jsonb;
  v_corrige timestamptz;
  v_resume public.seance_resumes%ROWTYPE;
  v_actif boolean;
  v_a_resume boolean;
  v_projection jsonb;
BEGIN
  IF v_user IS NULL OR p_seance_id IS NULL OR p_eleve_id IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false)
     OR NOT EXISTS (
       SELECT 1 FROM public.profiles p
       JOIN public.student_profiles sp ON sp.profile_id = p.id
       WHERE p.id = p_eleve_id AND p.deleted_at IS NULL AND sp.deleted_at IS NULL
         AND ((p.role = 'student' AND p.household_id IS NOT NULL
               AND p.household_id = public.app_household_id())
              OR (p.id = v_user AND sp.titulaire_profile_id = v_user))
     ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'compte rendu indisponible';
  END IF;

  SELECT s.* INTO v_session FROM public.sessions s
   WHERE s.id = p_seance_id AND s.deleted_at IS NULL AND s.groupe_id IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM public.groupe_membres m
        WHERE m.groupe_id = s.groupe_id AND m.student_id = p_eleve_id
          AND m.joined_at <= s.ended_at
          AND (m.left_at IS NULL OR m.left_at >= s.started_at));
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'compte rendu indisponible';
  END IF;

  -- Le cahier confirme de cet eleve (le plus recent), ou rien.
  SELECT e.value,
         CASE WHEN lr.updated_at > lr.created_at THEN lr.updated_at ELSE NULL END
    INTO v_entree, v_corrige
    FROM public.lesson_reports lr
    CROSS JOIN LATERAL pg_catalog.jsonb_array_elements(
      CASE WHEN jsonb_typeof(lr.content -> 'eleves') = 'array'
        THEN lr.content -> 'eleves' ELSE '[]'::jsonb END
    ) e(value)
   WHERE lr.session_id = p_seance_id AND lr.deleted_at IS NULL
     AND e.value ->> 'student_id' = p_eleve_id::text
     AND coalesce((e.value ->> 'confirme')::boolean, false)
   ORDER BY lr.updated_at DESC, lr.id DESC
   LIMIT 1;
  IF v_entree IS NULL THEN
    RETURN jsonb_build_object('etat', 'enAttente');
  END IF;

  SELECT r.* INTO v_resume FROM public.seance_resumes r
   WHERE r.session_id = p_seance_id AND r.student_id = p_eleve_id;
  v_a_resume := FOUND;
  IF v_a_resume AND v_resume.publie_le IS NOT NULL AND v_resume.revoque_le IS NULL
     AND (v_resume.publication_manuelle
          OR (v_resume.auto_partage AND v_resume.regle_ouverte)) THEN
    v_projection := private.partage_projection(v_resume.texte_famille, v_entree, v_corrige);
    RETURN v_projection || jsonb_build_object(
      'etat', CASE WHEN v_projection ->> 'travaille' IS NULL
                    AND v_projection ->> 'appreciation' IS NULL
                    AND jsonb_array_length(v_projection -> 'a_renforcer') = 0
                    AND jsonb_array_length(v_projection -> 'a_preparer') = 0
                   THEN 'aucunChamp' ELSE 'partage' END);
  END IF;

  -- Non visible. Revoque ou partage coupe : la famille ne distingue pas.
  v_actif := coalesce(
    (SELECT r.actif FROM private.partage_regle_effective(v_session.groupe_id, p_eleve_id) r), true);
  IF (v_a_resume AND v_resume.revoque_le IS NOT NULL)
     OR (NOT v_actif)
     OR (v_a_resume AND v_resume.publie_le IS NOT NULL) THEN
    RETURN jsonb_build_object('etat', 'nonPartage');
  END IF;
  -- Partage actif, mais l'enseignant n'a pas (encore) publie de resume.
  RETURN jsonb_build_object('etat', 'aucunChamp');
END;
$function$;
ALTER FUNCTION public.compte_rendu_famille(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.compte_rendu_famille(uuid, uuid) FROM PUBLIC, anon, agent_ro, service_role;
GRANT EXECUTE ON FUNCTION public.compte_rendu_famille(uuid, uuid) TO authenticated;

-- L'apercu de la direction : exactement ce que la famille recevra, et l'etat.
CREATE OR REPLACE FUNCTION public.apercu_familial(
  p_seance_id uuid,
  p_eleve_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_session public.sessions%ROWTYPE;
  v_classe text;
  v_prenom text;
  v_enseignant text;
  v_entree jsonb;
  v_corrige timestamptz;
  v_resume public.seance_resumes%ROWTYPE;
  v_regle record;
  v_historique jsonb;
BEGIN
  IF auth.uid() IS NULL OR p_seance_id IS NULL OR p_eleve_id IS NULL
     OR NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'lecture administrative refusee';
  END IF;

  SELECT s.* INTO v_session
    FROM public.sessions s
   WHERE s.id = p_seance_id AND s.deleted_at IS NULL AND s.groupe_id IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM public.groupe_membres m
        WHERE m.groupe_id = s.groupe_id AND m.student_id = p_eleve_id
          AND m.joined_at <= s.ended_at
          AND (m.left_at IS NULL OR m.left_at >= s.started_at));
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'compte rendu introuvable';
  END IF;
  SELECT g.libelle INTO v_classe FROM public.groupes g WHERE g.id = v_session.groupe_id;
  SELECT p.first_name INTO v_prenom FROM public.profiles p
   WHERE p.id = p_eleve_id AND p.deleted_at IS NULL;
  SELECT tp.first_name INTO v_enseignant FROM public.profiles tp
   WHERE tp.id = v_session.teacher_id AND tp.deleted_at IS NULL;

  SELECT e.value,
         CASE WHEN lr.updated_at > lr.created_at THEN lr.updated_at ELSE NULL END
    INTO v_entree, v_corrige
    FROM public.lesson_reports lr
    CROSS JOIN LATERAL pg_catalog.jsonb_array_elements(
      CASE WHEN jsonb_typeof(lr.content -> 'eleves') = 'array'
        THEN lr.content -> 'eleves' ELSE '[]'::jsonb END
    ) e(value)
   WHERE lr.session_id = p_seance_id AND lr.deleted_at IS NULL
     AND e.value ->> 'student_id' = p_eleve_id::text
   ORDER BY lr.updated_at DESC, lr.id DESC
   LIMIT 1;
  IF v_entree IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'compte rendu introuvable';
  END IF;

  SELECT r.* INTO v_resume FROM public.seance_resumes r
   WHERE r.session_id = p_seance_id AND r.student_id = p_eleve_id;
  SELECT * INTO v_regle FROM private.partage_regle_effective(v_session.groupe_id, p_eleve_id);

  SELECT coalesce(jsonb_agg(jsonb_build_object(
      'quand', a.created_at,
      'type', CASE a.action
        WHEN 'resume_seance_famille_publie_manuellement' THEN 'publication'
        WHEN 'resume_seance_famille_revoque' THEN 'revocation'
        ELSE 'partage_automatique' END,
      'auteur', CASE WHEN a.action = 'resume_seance_famille_publie' THEN NULL
                     ELSE (SELECT ap.first_name FROM public.profiles ap WHERE ap.id = a.actor) END
    ) ORDER BY a.created_at DESC), '[]'::jsonb)
    INTO v_historique
    FROM public.audit_logs a
   WHERE a.table_name = 'seance_resumes'
     AND a.row_id = p_seance_id::text || ':' || p_eleve_id::text
     AND a.action IN ('resume_seance_famille_publie',
       'resume_seance_famille_publie_manuellement', 'resume_seance_famille_revoque');

  RETURN jsonb_build_object(
    'seance_id', p_seance_id,
    'eleve_id', p_eleve_id,
    'eleve_prenom', v_prenom,
    'classe_libelle', v_classe,
    'seance_le', v_session.ended_at,
    'enseignant', v_enseignant,
    'etat', private.partage_etat(
      coalesce((v_entree ->> 'confirme')::boolean, false),
      v_resume.publie_le, v_resume.revoque_le,
      v_resume.publication_manuelle, v_resume.auto_partage AND v_resume.regle_ouverte),
    'regle_effective', v_regle.actif,
    'source_regle', v_regle.source,
    'apercu', private.partage_projection(v_resume.texte_famille, v_entree, v_corrige),
    'version', coalesce(v_resume.version_partage, 0)::text,
    'historique', v_historique,
    'mis_a_jour_le', v_resume.updated_at
  );
END;
$function$;
ALTER FUNCTION public.apercu_familial(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.apercu_familial(uuid, uuid) FROM PUBLIC, anon, agent_ro, service_role;
GRANT EXECUTE ON FUNCTION public.apercu_familial(uuid, uuid) TO authenticated;

-- 6. Empreintes F86 et postflight ----------------------------------------------

DO $allowlist$
DECLARE
  v_sig text;
BEGIN
  FOREACH v_sig IN ARRAY ARRAY[
    'public.comptes_rendus_classe(uuid,integer,text)',
    'public.comptes_rendus_eleve(uuid,uuid)',
    'public.partage_classe(uuid,integer,text)',
    'public.definir_partage_classe(uuid,boolean,text,text)',
    'public.definir_regle_partage_eleve(uuid,uuid,text,text,text)',
    'public.compte_rendu_famille(uuid,uuid)',
    'public.apercu_familial(uuid,uuid)',
    'public.resume_seance_famille(uuid,uuid)',
    'public.progression_famille(uuid,integer)'
  ] LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_sig, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18; PED-APRES-BACK : partage pedagogique, la famille ne lit que ce que la direction a choisi de partager.',
      v_sig,
      pg_catalog.md5(pg_catalog.pg_get_functiondef(v_sig::regprocedure)),
      CASE WHEN v_sig IN ('public.compte_rendu_famille(uuid,uuid)',
                          'public.resume_seance_famille(uuid,uuid)',
                          'public.progression_famille(uuid,integer)')
           THEN 'ROLE_POSITIVE_TEMPLATE_GUARDIAN_HOUSEHOLD'
           ELSE 'ROLE_POSITIVE_TEMPLATE_ADMIN' END));
  END LOOP;
END;
$allowlist$;

DO $postflight$
DECLARE
  v_sig text;
BEGIN
  FOREACH v_sig IN ARRAY ARRAY[
    'public.comptes_rendus_classe(uuid,integer,text)',
    'public.comptes_rendus_eleve(uuid,uuid)',
    'public.partage_classe(uuid,integer,text)',
    'public.definir_partage_classe(uuid,boolean,text,text)',
    'public.definir_regle_partage_eleve(uuid,uuid,text,text,text)',
    'public.compte_rendu_famille(uuid,uuid)',
    'public.apercu_familial(uuid,uuid)'
  ] LOOP
    IF NOT pg_catalog.has_function_privilege('authenticated', v_sig::regprocedure, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_sig::regprocedure, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_sig::regprocedure, 'EXECUTE') THEN
      RAISE EXCEPTION 'PED-APRES-BACK postflight : droits invalides pour %', v_sig;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.partage_ecrire(text,uuid,uuid,text,text,text)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.partage_pedagogique_classe', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.partage_pedagogique_eleve', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.partage_pedagogique_classe', 'SELECT') THEN
    RAISE EXCEPTION 'PED-APRES-BACK postflight : reglages de partage ouverts';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_policy p
        WHERE p.polrelid = 'public.seance_resumes'::regclass
          AND p.polname = 'seance_resumes_lecture'
          AND pg_catalog.pg_get_expr(p.polqual, p.polrelid) LIKE '%auto_partage%') THEN
    RAISE EXCEPTION 'PED-APRES-BACK postflight : la lecture famille ne tient pas compte du partage';
  END IF;
END;
$postflight$;

COMMIT;
