-- Une classe a plusieurs creneaux par semaine, et la mixite (decisions du
-- directeur du 29/10/2026, D1 et D2 ; fiche docs/current/FICHE-CRENEAUX-2026-10-29.md,
-- arbitree le 29/10 par le pilote sur delegation du directeur).
--
-- Constat en production (lecture seule, 29/10) : `groupe_creneaux` porte deja
-- N creneaux par classe ; `materialiser_seances_groupe` les lit tous ;
-- « Creer la classe » depuis un regroupement pose un creneau par jour ;
-- `ajouter_creneau_classe_admin` existe. Manquaient : la creation a la main
-- avec plusieurs creneaux, le retrait et la modification d'un creneau, et le
-- reglage du genre d'une classe.
--
-- 1. sessions.motif_annulation : une seance annulee par la direction garde
--    son motif (Q3 : on annule, on ne supprime jamais ; l'historique reste).
-- 2. private.annuler_seances_creneau : les seances prevues, a venir, non
--    supprimees, d'un creneau d'une classe passent a 'canceled' avec le
--    motif. Une seance passee ou commencee ne change jamais. Le declencheur
--    des notifications previent familles et enseignant (seance_annulee).
-- 3. public.retirer_creneau_classe_admin : annule puis retire le creneau ;
--    le dernier creneau ne se retire pas. Retirer le creneau d'ancrage
--    (`groupes.weekday` / `hour_local`) deplace l'ancre sur un autre creneau
--    de la classe (le declencheur de 0043 retire l'ancienne ligne).
-- 4. public.modifier_creneau_classe_admin : annule les seances a venir de
--    l'ancien creneau, deplace le creneau (le predicat d'affectation repasse),
--    puis genere les nouvelles seances. Familles et enseignant prevenus
--    (seance_annulee, creneau_change).
-- 5. public.creer_classe_creneaux_admin : cree une classe a la main avec 1 a
--    7 creneaux (3 par defaut a l'ecran), dans une seule transaction, avec le
--    meme predicat de creation que creer_groupe (disponibilites non exigees,
--    D4), passe sur l'ensemble des creneaux.
-- 6. Mixite (D1) : groupes.mixte ; public.regler_genre_classe_admin pose
--    hommes, femmes ou mixte, par un reglage explicite de la direction. Une
--    classe mixte accepte un enseignant des deux genres (genre_public
--    'indetermine', deja compris ainsi par le predicat). Les eleves deja
--    inscrits ne sont jamais touches (Q1).
--
-- Rien n'est recopie : le creneau unique de chaque classe existante est deja
-- dans `groupe_creneaux` (rattrapage de 0043) et devient le premier des N.

BEGIN;

ALTER TABLE public.sessions
  ADD COLUMN IF NOT EXISTS motif_annulation text NULL
    CHECK (motif_annulation IS NULL
           OR pg_catalog.length(pg_catalog.btrim(motif_annulation)) BETWEEN 1 AND 300);
COMMENT ON COLUMN public.sessions.motif_annulation IS
  'Motif d''une annulation par la direction (retrait ou modification d''un creneau, 29/10/2026). Nul pour les autres seances.';

ALTER TABLE public.groupes
  ADD COLUMN IF NOT EXISTS mixte boolean NOT NULL DEFAULT false;
COMMENT ON COLUMN public.groupes.mixte IS
  'D1 (29/10/2026) : classe rendue mixte par un reglage explicite de la direction (public.regler_genre_classe_admin). Une classe mixte a genre_public = ''indetermine''. Par defaut, une classe n''est pas mixte.';

-- 2. Les seances a venir d'un creneau.
CREATE FUNCTION private.annuler_seances_creneau(
  p_groupe_id uuid, p_weekday integer, p_hour_local integer, p_motif text)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_fuseau text;
  v_n integer;
BEGIN
  SELECT g.timezone_iana INTO v_fuseau FROM public.groupes g WHERE g.id = p_groupe_id;
  UPDATE public.sessions s
     SET status = 'canceled',
         motif_annulation = pg_catalog.btrim(p_motif),
         updated_at = pg_catalog.now()
   WHERE s.groupe_id = p_groupe_id
     AND s.deleted_at IS NULL
     AND s.status = 'planned'
     AND s.started_at > pg_catalog.now()
     AND pg_catalog.date_part('isodow', s.started_at AT TIME ZONE v_fuseau) = p_weekday
     AND pg_catalog.date_part('hour', s.started_at AT TIME ZONE v_fuseau) = p_hour_local;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

-- La garde commune : la direction active, une classe ouverte, un motif.
CREATE FUNCTION private.classe_creneau_garde(p_groupe_id uuid, p_motif text)
RETURNS public.groupes
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'CreneauNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_groupe_id IS NULL OR coalesce(pg_catalog.btrim(p_motif), '') = '' THEN
    RAISE EXCEPTION 'CreneauParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_g FROM public.groupes
   WHERE id = p_groupe_id AND ended_at IS NULL
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ClasseIndisponible' USING ERRCODE = 'P0002';
  END IF;
  RETURN v_g;
END;
$function$;

-- 3. Retirer un creneau. Rend le nombre de seances annulees.
CREATE FUNCTION public.retirer_creneau_classe_admin(
  p_groupe_id uuid, p_weekday integer, p_hour_local integer, p_motif text)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_autre public.groupe_creneaux%ROWTYPE;
  v_n integer;
BEGIN
  v_g := private.classe_creneau_garde(p_groupe_id, p_motif);
  IF NOT EXISTS (SELECT 1 FROM public.groupe_creneaux gc
                  WHERE gc.groupe_id = p_groupe_id
                    AND gc.weekday = p_weekday AND gc.hour_local = p_hour_local) THEN
    RAISE EXCEPTION 'CreneauIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  SELECT * INTO v_autre FROM public.groupe_creneaux gc
   WHERE gc.groupe_id = p_groupe_id
     AND NOT (gc.weekday = p_weekday AND gc.hour_local = p_hour_local)
   ORDER BY gc.weekday, gc.hour_local
   LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'DernierCreneau' USING ERRCODE = '22023';
  END IF;

  v_n := private.annuler_seances_creneau(p_groupe_id, p_weekday, p_hour_local, p_motif);

  IF v_g.weekday = p_weekday AND v_g.hour_local = p_hour_local THEN
    -- L'ancre passe sur un autre creneau ; le declencheur de 0043 retire
    -- l'ancienne ligne de groupe_creneaux.
    UPDATE public.groupes
       SET weekday = v_autre.weekday, hour_local = v_autre.hour_local
     WHERE id = p_groupe_id;
  ELSE
    DELETE FROM public.groupe_creneaux gc
     WHERE gc.groupe_id = p_groupe_id
       AND gc.weekday = p_weekday AND gc.hour_local = p_hour_local;
  END IF;

  PERFORM public.log_sensitive_access(
    'classe_creneau_retire', 'groupes', p_groupe_id::text,
    pg_catalog.jsonb_build_object('weekday', p_weekday, 'hour_local', p_hour_local,
      'motif', pg_catalog.btrim(p_motif), 'seances_annulees', v_n));
  RETURN v_n;
END;
$function$;

-- 4. Modifier un creneau. Rend le nombre de seances creees.
CREATE FUNCTION public.modifier_creneau_classe_admin(
  p_groupe_id uuid, p_weekday integer, p_hour_local integer,
  p_nouveau_weekday integer, p_nouvelle_heure integer, p_motif text)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_n integer;
BEGIN
  v_g := private.classe_creneau_garde(p_groupe_id, p_motif);
  IF p_nouveau_weekday IS NULL OR p_nouvelle_heure IS NULL
     OR p_nouveau_weekday NOT BETWEEN 1 AND 7 OR p_nouvelle_heure NOT BETWEEN 0 AND 23 THEN
    RAISE EXCEPTION 'CreneauParametresInvalides' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.groupe_creneaux gc
                  WHERE gc.groupe_id = p_groupe_id
                    AND gc.weekday = p_weekday AND gc.hour_local = p_hour_local) THEN
    RAISE EXCEPTION 'CreneauIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  IF p_weekday = p_nouveau_weekday AND p_hour_local = p_nouvelle_heure THEN
    RETURN 0;
  END IF;
  IF EXISTS (SELECT 1 FROM public.groupe_creneaux gc
              WHERE gc.groupe_id = p_groupe_id
                AND gc.weekday = p_nouveau_weekday AND gc.hour_local = p_nouvelle_heure) THEN
    RAISE EXCEPTION 'CreneauExistant' USING ERRCODE = '23505';
  END IF;

  -- D'abord l'annulation : l'enseignant redevient libre a l'ancien horaire,
  -- et le predicat du nouveau creneau ne bute pas sur ses propres seances.
  PERFORM private.annuler_seances_creneau(p_groupe_id, p_weekday, p_hour_local, p_motif);

  IF v_g.weekday = p_weekday AND v_g.hour_local = p_hour_local THEN
    -- L'ancre : le declencheur de 0043 deplace la ligne, le predicat de la
    -- classe repasse, et la cloche de 0055 genere les seances.
    UPDATE public.groupes
       SET weekday = p_nouveau_weekday, hour_local = p_nouvelle_heure
     WHERE id = p_groupe_id;
  ELSE
    UPDATE public.groupe_creneaux gc
       SET weekday = p_nouveau_weekday, hour_local = p_nouvelle_heure
     WHERE gc.groupe_id = p_groupe_id
       AND gc.weekday = p_weekday AND gc.hour_local = p_hour_local;
  END IF;

  v_n := public.materialiser_seances_groupe(p_groupe_id);

  PERFORM public.log_sensitive_access(
    'classe_creneau_modifie', 'groupes', p_groupe_id::text,
    pg_catalog.jsonb_build_object('weekday', p_weekday, 'hour_local', p_hour_local,
      'nouveau_weekday', p_nouveau_weekday, 'nouvelle_heure', p_nouvelle_heure,
      'motif', pg_catalog.btrim(p_motif)));
  RETURN v_n;
END;
$function$;

-- 5. Creer une classe a la main avec plusieurs creneaux. Rend l'id.
CREATE FUNCTION public.creer_classe_creneaux_admin(
  p_teacher_profile_id uuid,
  p_type_public text,
  p_libelle text,
  p_seuil_max smallint,
  p_timezone_iana text,
  p_creneaux jsonb,
  p_genre text,
  p_couleur_jeton smallint DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_premier jsonb;
  v_c jsonb;
  v_jour integer;
  v_heure integer;
  v_seuil smallint;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'CreneauNonAutorise' USING ERRCODE = '42501';
  END IF;
  -- D1 : le genre se choisit a la creation (hommes, femmes), ou la classe
  -- est rendue mixte explicitement ; jamais « indetermine » pour une
  -- classe nouvelle.
  IF NOT coalesce(p_genre IN ('hommes', 'femmes', 'mixte'), false) THEN
    RAISE EXCEPTION 'GenreInvalide' USING ERRCODE = '22023';
  END IF;
  IF p_creneaux IS NULL OR pg_catalog.jsonb_typeof(p_creneaux) <> 'array'
     OR pg_catalog.jsonb_array_length(p_creneaux) NOT BETWEEN 1 AND 7 THEN
    RAISE EXCEPTION 'CreneauxInvalides' USING ERRCODE = '22023';
  END IF;
  -- Chaque creneau : un jour de 1 a 7, une heure de 0 a 23, jamais deux fois.
  FOR v_c IN SELECT e FROM pg_catalog.jsonb_array_elements(p_creneaux) AS e LOOP
    v_jour := (v_c ->> 'jour')::integer;
    v_heure := (v_c ->> 'heure')::integer;
    IF v_jour IS NULL OR v_heure IS NULL
       OR v_jour NOT BETWEEN 1 AND 7 OR v_heure NOT BETWEEN 0 AND 23 THEN
      RAISE EXCEPTION 'CreneauxInvalides' USING ERRCODE = '22023';
    END IF;
  END LOOP;
  IF (SELECT pg_catalog.count(DISTINCT (e ->> 'jour', e ->> 'heure'))
        FROM pg_catalog.jsonb_array_elements(p_creneaux) AS e)
     <> pg_catalog.jsonb_array_length(p_creneaux) THEN
    RAISE EXCEPTION 'CreneauxEnDouble' USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
       SELECT 1 FROM public.profiles p
        WHERE p.id = p_teacher_profile_id AND p.role = 'teacher'
          AND p.deleted_at IS NULL
          AND p.account_status IN ('active', 'provisional_active')) THEN
    RAISE EXCEPTION 'cet enseignant n''existe pas ou son compte n''est pas valide';
  END IF;
  IF p_timezone_iana IS NOT NULL THEN
    PERFORM 1 FROM pg_catalog.pg_timezone_names WHERE name = p_timezone_iana;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'fuseau IANA inconnu : %', p_timezone_iana;
    END IF;
  END IF;
  v_seuil := coalesce(p_seuil_max,
    CASE p_type_public WHEN 'enfant' THEN 5 WHEN 'adulte' THEN 6 ELSE NULL END);
  IF v_seuil IS NULL THEN
    RAISE EXCEPTION 'type de public inconnu : %', p_type_public;
  END IF;

  -- Comme creer_groupe (CAND-Q15) : la classe nait en attente, sans
  -- enseignant, avec TOUS ses creneaux (le premier est l'ancre) ; puis le
  -- predicat de creation (disponibilites non exigees, D4) passe sur
  -- l'ensemble, et l'enseignant est affecte. Un refus annule tout.
  v_premier := p_creneaux -> 0;
  INSERT INTO public.groupes
    (teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local,
     timezone_iana, couleur_jeton, genre_public, mixte)
  VALUES
    (NULL, 'en_attente_enseignant', p_type_public, v_seuil, p_libelle,
     ((v_premier ->> 'jour')::integer)::smallint,
     ((v_premier ->> 'heure')::integer)::smallint,
     coalesce(p_timezone_iana, 'Europe/Paris'), p_couleur_jeton,
     CASE WHEN p_genre = 'mixte' THEN 'indetermine' ELSE p_genre END,
     p_genre = 'mixte')
  RETURNING id INTO v_id;

  INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local)
  SELECT v_id, (x.e ->> 'jour')::smallint, (x.e ->> 'heure')::smallint
    FROM pg_catalog.jsonb_array_elements(p_creneaux) WITH ORDINALITY AS x(e, rang)
   WHERE x.rang > 1
  ON CONFLICT (groupe_id, weekday, hour_local) DO NOTHING;

  PERFORM app_private.verifier_affectation_enseignant(v_id, p_teacher_profile_id, false);

  UPDATE public.groupes
     SET teacher_id = p_teacher_profile_id, etat = 'active'
   WHERE id = v_id;

  PERFORM public.log_sensitive_access(
    'groupe_cree', 'groupes', v_id::text,
    pg_catalog.jsonb_build_object('teacher_id', p_teacher_profile_id,
      'type_public', p_type_public, 'seuil_max', v_seuil, 'genre', p_genre,
      'creneaux', pg_catalog.jsonb_array_length(p_creneaux)));

  PERFORM public.materialiser_seances_groupe(v_id);
  RETURN v_id;
END;
$function$;

-- 6. Le genre d'une classe, par la direction : 'hommes', 'femmes' ou 'mixte'.
CREATE FUNCTION public.regler_genre_classe_admin(
  p_groupe_id uuid, p_genre text, p_motif text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
BEGIN
  v_g := private.classe_creneau_garde(p_groupe_id, p_motif);
  IF NOT coalesce(p_genre IN ('hommes', 'femmes', 'mixte'), false) THEN
    RAISE EXCEPTION 'GenreInvalide' USING ERRCODE = '22023';
  END IF;
  UPDATE public.groupes
     SET mixte = (p_genre = 'mixte'),
         genre_public = CASE WHEN p_genre = 'mixte' THEN 'indetermine' ELSE p_genre END
   WHERE id = p_groupe_id;
  -- L'enseignant attitre doit rester compatible : sinon, rien n'est ecrit.
  IF v_g.teacher_id IS NOT NULL AND p_genre <> 'mixte' THEN
    PERFORM app_private.verifier_affectation_enseignant_base(p_groupe_id, v_g.teacher_id, false);
  END IF;
  PERFORM public.log_sensitive_access(
    'classe_genre_regle', 'groupes', p_groupe_id::text,
    pg_catalog.jsonb_build_object('genre', p_genre, 'motif', pg_catalog.btrim(p_motif)));
END;
$function$;

-- 7. La liste des classes de la direction dit « mixte » pour une classe
--    mixte (au lieu de « indetermine », son genre_public). Le corps est
--    remplace a l'identique ailleurs ; le bloc refuse de continuer s'il ne
--    trouve pas l'expression telle quelle. L'empreinte F86 suit.
DO $liste$
DECLARE
  v_f pg_catalog.regprocedure :=
    'public.classes_admin_page(integer,integer,text,text,text,integer,integer,text,text,uuid,boolean,text)'::pg_catalog.regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_avant text := 'coalesce(g.genre_public, ''indetermine'') AS genre';
  v_apres text := 'CASE WHEN g.mixte THEN ''mixte'' ELSE coalesce(g.genre_public, ''indetermine'') END AS genre';
BEGIN
  IF pg_catalog.strpos(v_def, v_avant) = 0 THEN
    RAISE EXCEPTION 'classes_admin_page : l''expression du genre a change, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f,
    pg_catalog.regexp_replace(pg_catalog.obj_description(v_f, 'pg_proc'),
      'md5_functiondef=[0-9a-f]{32}',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f))));
END;
$liste$;

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.annuler_seances_creneau(uuid,integer,integer,text)'::pg_catalog.regprocedure,
    'private.classe_creneau_garde(uuid,text)'::pg_catalog.regprocedure
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.retirer_creneau_classe_admin(uuid,integer,integer,text)'::pg_catalog.regprocedure,
    'public.modifier_creneau_classe_admin(uuid,integer,integer,integer,integer,text)'::pg_catalog.regprocedure,
    'public.creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint)'::pg_catalog.regprocedure,
    'public.regler_genre_classe_admin(uuid,text,text)'::pg_catalog.regprocedure
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ADMIN_ONLY; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-29. Classe a plusieurs creneaux et mixite (D1, D2).',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.retirer_creneau_classe_admin(uuid,integer,integer,text)'::pg_catalog.regprocedure,
    'public.modifier_creneau_classe_admin(uuid,integer,integer,integer,integer,text)'::pg_catalog.regprocedure,
    'public.creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint)'::pg_catalog.regprocedure,
    'public.regler_genre_classe_admin(uuid,text,text)'::pg_catalog.regprocedure
  ] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::pg_catalog.regrole
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'CRENEAUX : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.annuler_seances_creneau(uuid,integer,integer,text)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'CRENEAUX : annuler_seances_creneau executable par un client';
  END IF;
END;
$postflight$;

COMMIT;
