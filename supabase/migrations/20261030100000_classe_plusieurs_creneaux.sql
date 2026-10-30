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
-- 8. Duree par creneau (le directeur : « jour + heure + duree », consigne du
--    pilote du 30/10) : groupe_creneaux.duree_minutes, de 15 a 240, vide =
--    la duree de la Classe (son offre, sinon le reglage de son public) ;
--    rien ne change donc pour les creneaux existants.
--    app_private.creneaux_de_classe rend chaque creneau avec SA duree ; les
--    lecteurs de la duree d'une Classe la lisent desormais par creneau :
--    generation des seances (materialiser_seances_groupe, seance_a_rejoindre,
--    horloge_classe), predicat d'affectation de l'enseignant (charge,
--    couverture par les disponibilites, chevauchements), controle des
--    creneaux de la Classe entre eux et contre les seances deja generees,
--    proposition d'enseignants (leurs creneaux deja pris), transfert d'un
--    eleve (R5), realignement des seances a venir. Le declencheur de controle
--    de groupe_creneaux repasse aussi quand seule la duree change, y compris
--    pour le creneau d'ancrage ; le creneau d'ancrage deplace garde sa duree.
--    creer_classe_creneaux_admin lit « duree » dans chaque creneau ;
--    modifier_creneau_classe_admin recoit la nouvelle duree (une duree seule
--    modifiee realigne les seances a venir, sans les annuler) ;
--    ajouter_creneau_classe_admin a une variante a quatre arguments.
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

-- 8. La duree d'un creneau. Vide : la duree de la Classe.
ALTER TABLE public.groupe_creneaux
  ADD COLUMN IF NOT EXISTS duree_minutes smallint NULL
    CHECK (duree_minutes IS NULL OR duree_minutes BETWEEN 15 AND 240);
COMMENT ON COLUMN public.groupe_creneaux.duree_minutes IS
  'Duree des seances de ce creneau, de 15 a 240 minutes (30/10/2026). Nulle : la duree de la Classe, app_private.duree_seance_minutes(offre, public).';

-- Chaque creneau d'une Classe (l'ancre et les lignes de groupe_creneaux),
-- avec SA duree. Une Classe absente ne rend rien.
CREATE FUNCTION app_private.creneaux_de_classe(p_groupe_id uuid)
RETURNS TABLE(jour integer, heure integer, duree integer)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT s.jour, s.heure,
         coalesce(gc.duree_minutes::integer,
                  app_private.duree_seance_minutes(g.offre_id, g.type_public))
  FROM public.groupes g
  CROSS JOIN LATERAL (
    SELECT g.weekday::integer AS jour, g.hour_local::integer AS heure
    UNION
    SELECT c.weekday::integer, c.hour_local::integer
      FROM public.groupe_creneaux c WHERE c.groupe_id = g.id
  ) s
  LEFT JOIN public.groupe_creneaux gc
    ON gc.groupe_id = g.id AND gc.weekday = s.jour AND gc.hour_local = s.heure
  WHERE g.id = p_groupe_id;
$function$;

-- La duree d'une seance d'une Classe d'apres son debut : celle du creneau qui
-- tombe a ce jour et a cette heure (fuseau de la Classe), sinon celle de la
-- Classe (une seance d'un ancien horaire, laissee par un deplacement).
CREATE FUNCTION app_private.duree_seance_de_classe(p_groupe_id uuid, p_debut timestamptz)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT coalesce(
           (SELECT gc.duree_minutes::integer
              FROM public.groupe_creneaux gc
             WHERE gc.groupe_id = g.id
               AND gc.weekday = pg_catalog.date_part('isodow', p_debut AT TIME ZONE g.timezone_iana)
               AND gc.hour_local = pg_catalog.date_part('hour', p_debut AT TIME ZONE g.timezone_iana)),
           app_private.duree_seance_minutes(g.offre_id, g.type_public))
  FROM public.groupes g
  WHERE g.id = p_groupe_id;
$function$;

-- Outil de la migration (detruit avec la session) : remplace un passage du
-- corps d'une fonction, a condition de l'y trouver exactement p_n fois ; sinon
-- la migration s'arrete. Proprietaire, droits et commentaire sont gardes par
-- CREATE OR REPLACE ; l'empreinte F86 est remise a jour au point 8.
CREATE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

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

-- 4. Modifier un creneau : son jour, son heure, sa duree (vide : la duree de
--    la Classe). Rend le nombre de seances creees, ou realignees quand seule
--    la duree change.
CREATE FUNCTION public.modifier_creneau_classe_admin(
  p_groupe_id uuid, p_weekday integer, p_hour_local integer,
  p_nouveau_weekday integer, p_nouvelle_heure integer, p_nouvelle_duree integer,
  p_motif text)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_ancienne_duree smallint;
  v_n integer;
BEGIN
  v_g := private.classe_creneau_garde(p_groupe_id, p_motif);
  IF p_nouveau_weekday IS NULL OR p_nouvelle_heure IS NULL
     OR p_nouveau_weekday NOT BETWEEN 1 AND 7 OR p_nouvelle_heure NOT BETWEEN 0 AND 23
     OR NOT coalesce(p_nouvelle_duree IS NULL OR p_nouvelle_duree BETWEEN 15 AND 240, false) THEN
    RAISE EXCEPTION 'CreneauParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT gc.duree_minutes INTO v_ancienne_duree
    FROM public.groupe_creneaux gc
   WHERE gc.groupe_id = p_groupe_id
     AND gc.weekday = p_weekday AND gc.hour_local = p_hour_local;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CreneauIntrouvable' USING ERRCODE = 'P0002';
  END IF;

  IF p_weekday = p_nouveau_weekday AND p_hour_local = p_nouvelle_heure THEN
    IF v_ancienne_duree IS NOT DISTINCT FROM p_nouvelle_duree THEN
      RETURN 0;
    END IF;
    -- La duree seule : le declencheur de groupe_creneaux repasse le predicat
    -- de l'enseignant et le controle contre ses seances deja generees, puis
    -- les seances a venir prennent la nouvelle duree (elles ne sont pas
    -- annulees : meme jour, meme heure). Un chevauchement arrete tout.
    UPDATE public.groupe_creneaux gc
       SET duree_minutes = p_nouvelle_duree
     WHERE gc.groupe_id = p_groupe_id
       AND gc.weekday = p_weekday AND gc.hour_local = p_hour_local;
    v_n := app_private.aligner_seances_a_venir_sur_la_classe(p_groupe_id);
  ELSE
    IF EXISTS (SELECT 1 FROM public.groupe_creneaux gc
                WHERE gc.groupe_id = p_groupe_id
                  AND gc.weekday = p_nouveau_weekday AND gc.hour_local = p_nouvelle_heure) THEN
      RAISE EXCEPTION 'CreneauExistant' USING ERRCODE = '23505';
    END IF;

    -- D'abord l'annulation : l'enseignant redevient libre a l'ancien horaire,
    -- et le predicat du nouveau creneau ne bute pas sur ses propres seances.
    PERFORM private.annuler_seances_creneau(p_groupe_id, p_weekday, p_hour_local, p_motif);

    IF v_g.weekday = p_weekday AND v_g.hour_local = p_hour_local THEN
      -- L'ancre : le declencheur de 0043 deplace la ligne (avec son ancienne
      -- duree), le predicat de la classe repasse, et la cloche de 0055 genere
      -- les seances ; puis la nouvelle duree est posee (le predicat repasse)
      -- et les seances qui viennent d'etre generees la prennent.
      UPDATE public.groupes
         SET weekday = p_nouveau_weekday, hour_local = p_nouvelle_heure
       WHERE id = p_groupe_id;
      UPDATE public.groupe_creneaux gc
         SET duree_minutes = p_nouvelle_duree
       WHERE gc.groupe_id = p_groupe_id
         AND gc.weekday = p_nouveau_weekday AND gc.hour_local = p_nouvelle_heure
         AND gc.duree_minutes IS DISTINCT FROM p_nouvelle_duree;
    ELSE
      UPDATE public.groupe_creneaux gc
         SET weekday = p_nouveau_weekday, hour_local = p_nouvelle_heure,
             duree_minutes = p_nouvelle_duree
       WHERE gc.groupe_id = p_groupe_id
         AND gc.weekday = p_weekday AND gc.hour_local = p_hour_local;
    END IF;

    v_n := public.materialiser_seances_groupe(p_groupe_id);
    PERFORM app_private.aligner_seances_a_venir_sur_la_classe(p_groupe_id);
  END IF;

  PERFORM public.log_sensitive_access(
    'classe_creneau_modifie', 'groupes', p_groupe_id::text,
    pg_catalog.jsonb_build_object('weekday', p_weekday, 'hour_local', p_hour_local,
      'duree_minutes', v_ancienne_duree,
      'nouveau_weekday', p_nouveau_weekday, 'nouvelle_heure', p_nouvelle_heure,
      'nouvelle_duree', p_nouvelle_duree,
      'motif', pg_catalog.btrim(p_motif)));
  RETURN v_n;
END;
$function$;

-- 5. Creer une classe a la main avec plusieurs creneaux. Rend l'id. Chaque
--    creneau : {"jour": 1-7, "heure": 0-23, "duree": 15-240 ou absente (la
--    duree de la Classe)}.
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
  v_duree integer;
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
  -- Chaque creneau : un jour de 1 a 7, une heure de 0 a 23, une duree de 15
  -- a 240 minutes ou aucune, jamais deux fois le meme jour a la meme heure.
  FOR v_c IN SELECT e FROM pg_catalog.jsonb_array_elements(p_creneaux) AS e LOOP
    IF pg_catalog.jsonb_typeof(v_c) <> 'object' THEN
      RAISE EXCEPTION 'CreneauxInvalides' USING ERRCODE = '22023';
    END IF;
    v_jour := (v_c ->> 'jour')::integer;
    v_heure := (v_c ->> 'heure')::integer;
    v_duree := (v_c ->> 'duree')::integer;
    IF v_jour IS NULL OR v_heure IS NULL
       OR v_jour NOT BETWEEN 1 AND 7 OR v_heure NOT BETWEEN 0 AND 23
       OR NOT coalesce(v_duree IS NULL OR v_duree BETWEEN 15 AND 240, false) THEN
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

  -- L'ancre est ecrite par le declencheur de 0043 ; elle recoit sa duree.
  UPDATE public.groupe_creneaux gc
     SET duree_minutes = (v_premier ->> 'duree')::smallint
   WHERE gc.groupe_id = v_id
     AND gc.weekday = (v_premier ->> 'jour')::integer
     AND gc.hour_local = (v_premier ->> 'heure')::integer;

  INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local, duree_minutes)
  SELECT v_id, (x.e ->> 'jour')::smallint, (x.e ->> 'heure')::smallint,
         (x.e ->> 'duree')::smallint
    FROM pg_catalog.jsonb_array_elements(p_creneaux) WITH ORDINALITY AS x(e, rang)
   WHERE x.rang > 1
  ON CONFLICT (groupe_id, weekday, hour_local) DO NOTHING;

  -- Les creneaux de la Classe ne se chevauchent pas entre eux, chacun avec sa
  -- duree (sans enseignant encore, seul ce controle-la joue) ; puis le
  -- predicat de l'enseignant.
  PERFORM app_private.verifier_horaire_contre_seances_planifiees(v_id);
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

-- 8. Duree par creneau : les ecritures, puis les lecteurs.

-- Ajouter un creneau avec sa duree (vide : la duree de la Classe). La variante
-- a trois arguments reste, inchangee (duree de la Classe). Le declencheur de
-- groupe_creneaux repasse le predicat de l'enseignant avec cette duree.
CREATE FUNCTION public.ajouter_creneau_classe_admin(
  p_groupe_id uuid, p_weekday integer, p_hour_local integer, p_duree_minutes integer)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'CreneauNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_groupe_id IS NULL OR p_weekday IS NULL OR p_hour_local IS NULL
     OR p_weekday NOT BETWEEN 1 AND 7 OR p_hour_local NOT BETWEEN 0 AND 23
     OR NOT coalesce(p_duree_minutes IS NULL OR p_duree_minutes BETWEEN 15 AND 240, false) THEN
    RAISE EXCEPTION 'CreneauParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_g FROM public.groupes
  WHERE id = p_groupe_id AND ended_at IS NULL
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ClasseIndisponible' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local, duree_minutes)
  VALUES (p_groupe_id, p_weekday, p_hour_local, p_duree_minutes)
  ON CONFLICT (groupe_id, weekday, hour_local) DO NOTHING;
  IF NOT FOUND THEN
    RETURN 0;
  END IF;

  PERFORM public.log_sensitive_access(
    'classe_creneau_ajoute', 'groupes', p_groupe_id::text,
    pg_catalog.jsonb_build_object('weekday', p_weekday, 'hour_local', p_hour_local,
      'duree_minutes', p_duree_minutes));

  RETURN public.materialiser_seances_groupe(p_groupe_id);
END;
$function$;

-- Le creneau d'ancrage deplace (groupes.weekday / hour_local) garde sa duree.
-- Corps de 0043, a la duree pres.
CREATE OR REPLACE FUNCTION public.groupe_creneau_ancre()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_duree smallint;
begin
  if tg_op = 'UPDATE'
     and old.weekday = new.weekday
     and old.hour_local = new.hour_local then
    return new;
  end if;

  if tg_op = 'UPDATE' then
    delete from public.groupe_creneaux
    where groupe_id = new.id
      and weekday = old.weekday
      and hour_local = old.hour_local
    returning duree_minutes into v_duree;
  end if;

  insert into public.groupe_creneaux (groupe_id, weekday, hour_local, duree_minutes)
  values (new.id, new.weekday, new.hour_local, v_duree)
  on conflict (groupe_id, weekday, hour_local) do nothing;

  return new;
end;
$function$;

-- Le controle d'un creneau ecrit repasse aussi quand seule sa duree change,
-- y compris pour le creneau d'ancrage (que le declencheur de groupes ne voit
-- pas, l'horaire de la Classe ne changeant pas).
CREATE OR REPLACE TRIGGER groupe_creneaux_a_verrou_classe
  BEFORE INSERT OR UPDATE OF groupe_id, weekday, hour_local, duree_minutes ON public.groupe_creneaux
  FOR EACH ROW EXECUTE FUNCTION app_private.verrouiller_classe_du_creneau();
CREATE OR REPLACE TRIGGER groupe_creneaux_verifie_enseignant
  AFTER INSERT OR UPDATE OF groupe_id, weekday, hour_local, duree_minutes ON public.groupe_creneaux
  FOR EACH ROW EXECUTE FUNCTION app_private.verifier_creneau_classe_avec_enseignant();

SELECT pg_temp.remplacer(
  'app_private.verifier_creneau_classe_avec_enseignant()',
  $a$  IF NEW.weekday = v_g.weekday AND NEW.hour_local = v_g.hour_local THEN
    RETURN NULL;
  END IF;$a$,
  $b$  -- Duree par creneau (30/10) : sauf si seule sa duree change.
  IF NEW.weekday = v_g.weekday AND NEW.hour_local = v_g.hour_local
     AND (TG_OP = 'INSERT' OR OLD.duree_minutes IS NOT DISTINCT FROM NEW.duree_minutes) THEN
    RETURN NULL;
  END IF;$b$, 1);

-- La generation des seances : la duree du creneau.
SELECT pg_temp.remplacer('public.materialiser_seances_groupe(uuid)',
  $a$v_debut + make_interval(mins => v_duree),$a$,
  $b$v_debut + make_interval(mins => coalesce(v_creneau.duree_minutes::integer, v_duree)),$b$, 1);
SELECT pg_temp.remplacer('public.seance_a_rejoindre(uuid)',
  $a$pg_catalog.make_interval(mins => v_duree)$a$,
  $b$pg_catalog.make_interval(mins => coalesce(v_creneau.duree_minutes::integer, v_duree))$b$, 2);
SELECT pg_temp.remplacer('public.horloge_classe(uuid)',
  $a$pg_catalog.make_interval(mins => v_duree)$a$,
  $b$pg_catalog.make_interval(mins => coalesce(v_creneau.duree_minutes::integer, v_duree))$b$, 2);

-- Le realignement des seances a venir : la duree du creneau de la seance.
SELECT pg_temp.remplacer('app_private.seances_a_venir_a_realigner(uuid)',
  $a$SELECT app_private.duree_seance_minutes(g.offre_id, g.type_public) AS minutes$a$,
  $b$SELECT app_private.duree_seance_de_classe(g.id, s.started_at) AS minutes$b$, 1);

-- Le transfert d'un eleve (R5) : chaque creneau de la cible avec sa duree.
SELECT pg_temp.remplacer('public.transferer_eleve(uuid,uuid,uuid,text)',
  $a$    CROSS JOIN LATERAL (
      SELECT v_cible.weekday::integer AS jour, v_cible.hour_local::integer AS heure
      UNION
      SELECT gc.weekday, gc.hour_local FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_cible_id
    ) slot$a$,
  $b$    CROSS JOIN LATERAL app_private.creneaux_de_classe(p_cible_id) slot$b$, 1);
SELECT pg_temp.remplacer('public.transferer_eleve(uuid,uuid,uuid,text)',
  $a$slot.jour, slot.heure, v_cible.timezone_iana, v_duree, s.started_at$a$,
  $b$slot.jour, slot.heure, v_cible.timezone_iana, slot.duree, s.started_at$b$, 1);

-- Les creneaux de la Classe entre eux, et contre les seances deja generees.
SELECT pg_temp.remplacer('app_private.verifier_horaire_contre_seances_planifiees(uuid)',
  $a$    WITH c AS (
      SELECT v_g.weekday::integer AS jour, v_g.hour_local::integer AS heure
      UNION
      SELECT gc.weekday::integer, gc.hour_local::integer
        FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_groupe_id
    )$a$,
  $b$    WITH c AS (SELECT * FROM app_private.creneaux_de_classe(p_groupe_id))$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_horaire_contre_seances_planifiees(uuid)',
  $a$  WITH c AS (
    SELECT v_g.weekday::integer AS jour, v_g.hour_local::integer AS heure
    UNION
    SELECT gc.weekday::integer, gc.hour_local::integer
      FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_groupe_id
  )$a$,
  $b$  WITH c AS (SELECT * FROM app_private.creneaux_de_classe(p_groupe_id))$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_horaire_contre_seances_planifiees(uuid)',
  $a$            a.jour, a.heure, v_g.timezone_iana, v_duree,
            b.jour, b.heure, v_g.timezone_iana, v_duree)$a$,
  $b$            a.jour, a.heure, v_g.timezone_iana, a.duree,
            b.jour, b.heure, v_g.timezone_iana, b.duree)$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_horaire_contre_seances_planifiees(uuid)',
  $a$AND s.started_at < d.debut + pg_catalog.make_interval(mins => v_duree)$a$,
  $b$AND s.started_at < d.debut + pg_catalog.make_interval(mins => c.duree)$b$, 1);

-- Le predicat d'affectation de l'enseignant : charge, couverture, collisions.
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$        SELECT DISTINCT g.id, gs.weekday, gs.hour_local,
               app_private.duree_seance_minutes(g.offre_id, g.type_public) AS duree
        FROM public.groupes g
        CROSS JOIN LATERAL (
          SELECT g.weekday, g.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc
          WHERE gc.groupe_id = g.id
        ) gs$a$,
  $b$        SELECT DISTINCT g.id, gs.jour, gs.heure, gs.duree
        FROM public.groupes g
        CROSS JOIN LATERAL app_private.creneaux_de_classe(g.id) gs$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$      SELECT pg_catalog.count(*) * v_duree FROM (
        SELECT DISTINCT gs.weekday, gs.hour_local
        FROM public.groupes target
        CROSS JOIN LATERAL (
          SELECT target.weekday, target.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc
          WHERE gc.groupe_id = target.id
        ) gs
        WHERE target.id = p_groupe_id
      ) target_slots$a$,
  $b$      SELECT coalesce(pg_catalog.sum(target_slots.duree), 0)
        FROM app_private.creneaux_de_classe(p_groupe_id) target_slots$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$SELECT DISTINCT slots.weekday, slots.hour_local, v_g.timezone_iana
$a$,
  $b$SELECT DISTINCT slots.weekday, slots.hour_local, v_g.timezone_iana, slots.duree
$b$, 2);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$      FROM (
        SELECT v_g.weekday AS weekday, v_g.hour_local AS hour_local
        UNION
        SELECT gc.weekday, gc.hour_local
        FROM public.groupe_creneaux gc
        WHERE gc.groupe_id = p_groupe_id
      ) slots$a$,
  $b$      FROM app_private.creneaux_de_classe(p_groupe_id) AS slots(weekday, hour_local, duree)$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$    FROM (
      SELECT v_g.weekday AS weekday, v_g.hour_local AS hour_local
      UNION
      SELECT gc.weekday, gc.hour_local
      FROM public.groupe_creneaux gc
      WHERE gc.groupe_id = p_groupe_id
    ) slots$a$,
  $b$    FROM app_private.creneaux_de_classe(p_groupe_id) AS slots(weekday, hour_local, duree)$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$v_fin := v_debut + pg_catalog.make_interval(mins => v_duree);$a$,
  $b$v_fin := v_debut + pg_catalog.make_interval(mins => v_c.duree);$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$              v_duree,
              coalesce((SELECT pg_catalog.max(p.fin)$a$,
  $b$              v_c.duree,
              coalesce((SELECT pg_catalog.max(p.fin)$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$        SELECT slots.weekday, slots.hour_local, g.timezone_iana,
               app_private.duree_seance_minutes(g.offre_id, g.type_public) AS duree
        FROM public.groupes g
        CROSS JOIN LATERAL (
          SELECT g.weekday, g.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc
          WHERE gc.groupe_id = g.id
        ) slots$a$,
  $b$        SELECT slots.jour AS weekday, slots.heure AS hour_local, g.timezone_iana,
               slots.duree
        FROM public.groupes g
        CROSS JOIN LATERAL app_private.creneaux_de_classe(g.id) slots$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$AND v_busy_debut < v_debut + pg_catalog.make_interval(mins => v_duree) THEN$a$,
  $b$AND v_busy_debut < v_debut + pg_catalog.make_interval(mins => v_c.duree) THEN$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$    CROSS JOIN LATERAL (
      SELECT public.instant_creneau(v_g.weekday, v_g.hour_local, v_g.timezone_iana, w.n) AS starts_at
      UNION
      SELECT public.instant_creneau(gc.weekday, gc.hour_local, v_g.timezone_iana, w.n)
      FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_groupe_id
    ) target$a$,
  $b$    CROSS JOIN LATERAL (
      SELECT public.instant_creneau(cc.jour, cc.heure, v_g.timezone_iana, w.n) AS starts_at,
             cc.duree
      FROM app_private.creneaux_de_classe(p_groupe_id) cc
    ) target$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$AND s.started_at < target.starts_at + pg_catalog.make_interval(mins => v_duree)$a$,
  $b$AND s.started_at < target.starts_at + pg_catalog.make_interval(mins => target.duree)$b$, 1);

-- La proposition d'enseignants : leurs creneaux deja pris, chacun avec sa duree.
SELECT pg_temp.remplacer('public.enseignants_pour_classe(uuid)',
  $a$        CROSS JOIN LATERAL (
          SELECT g.weekday, g.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
        ) slots
        WHERE g.teacher_id = v_teacher.id
          AND g.ended_at IS NULL AND g.etat = 'active'
          AND app_private.creneaux_recurrents_se_chevauchent_durees(
            wa.weekday, wa.hour_local, wa.timezone_iana, v_duree,
            slots.weekday, slots.hour_local, g.timezone_iana,
            app_private.duree_seance_minutes(g.offre_id, g.type_public)
          )$a$,
  $b$        CROSS JOIN LATERAL app_private.creneaux_de_classe(g.id) slots
        WHERE g.teacher_id = v_teacher.id
          AND g.ended_at IS NULL AND g.etat = 'active'
          AND app_private.creneaux_recurrents_se_chevauchent_durees(
            wa.weekday, wa.hour_local, wa.timezone_iana, v_duree,
            slots.jour, slots.heure, g.timezone_iana, slots.duree
          )$b$, 1);
SELECT pg_temp.remplacer('public.enseignants_pour_public(text)',
  $a$               CROSS JOIN LATERAL (
                 SELECT g.weekday, g.hour_local
                 UNION SELECT gc.weekday, gc.hour_local FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
               ) s
               WHERE g.teacher_id = p.id AND g.ended_at IS NULL AND g.etat = 'active'
                 AND app_private.creneaux_recurrents_se_chevauchent_durees(
                       wa.weekday, wa.hour_local, wa.timezone_iana, v_duree,
                       s.weekday, s.hour_local, g.timezone_iana,
                       app_private.duree_seance_minutes(g.offre_id, g.type_public)))$a$,
  $b$               CROSS JOIN LATERAL app_private.creneaux_de_classe(g.id) s
               WHERE g.teacher_id = p.id AND g.ended_at IS NULL AND g.etat = 'active'
                 AND app_private.creneaux_recurrents_se_chevauchent_durees(
                       wa.weekday, wa.hour_local, wa.timezone_iana, v_duree,
                       s.jour, s.heure, g.timezone_iana, s.duree))$b$, 1);

-- Les empreintes F86 des fonctions reecrites ici suivent leur nouveau corps.
DO $empreintes$
DECLARE
  v_f pg_catalog.regprocedure;
  v_com text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'public.materialiser_seances_groupe(uuid)'::pg_catalog.regprocedure,
    'public.seance_a_rejoindre(uuid)'::pg_catalog.regprocedure,
    'public.horloge_classe(uuid)'::pg_catalog.regprocedure,
    'public.transferer_eleve(uuid,uuid,uuid,text)'::pg_catalog.regprocedure,
    'public.enseignants_pour_classe(uuid)'::pg_catalog.regprocedure,
    'public.enseignants_pour_public(text)'::pg_catalog.regprocedure,
    'public.groupe_creneau_ancre()'::pg_catalog.regprocedure,
    'app_private.seances_a_venir_a_realigner(uuid)'::pg_catalog.regprocedure,
    'app_private.verifier_horaire_contre_seances_planifiees(uuid)'::pg_catalog.regprocedure,
    'app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)'::pg_catalog.regprocedure,
    'app_private.verifier_creneau_classe_avec_enseignant()'::pg_catalog.regprocedure
  ] LOOP
    v_com := pg_catalog.obj_description(v_f, 'pg_proc');
    IF v_com ~ 'md5_functiondef=[0-9a-f]{32}' THEN
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f,
        pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9a-f]{32}',
          'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f))));
    END IF;
  END LOOP;
END;
$empreintes$;

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.annuler_seances_creneau(uuid,integer,integer,text)'::pg_catalog.regprocedure,
    'private.classe_creneau_garde(uuid,text)'::pg_catalog.regprocedure,
    'app_private.creneaux_de_classe(uuid)'::pg_catalog.regprocedure,
    'app_private.duree_seance_de_classe(uuid,timestamptz)'::pg_catalog.regprocedure
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.retirer_creneau_classe_admin(uuid,integer,integer,text)'::pg_catalog.regprocedure,
    'public.modifier_creneau_classe_admin(uuid,integer,integer,integer,integer,integer,text)'::pg_catalog.regprocedure,
    'public.ajouter_creneau_classe_admin(uuid,integer,integer,integer)'::pg_catalog.regprocedure,
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
    'public.modifier_creneau_classe_admin(uuid,integer,integer,integer,integer,integer,text)'::pg_catalog.regprocedure,
    'public.ajouter_creneau_classe_admin(uuid,integer,integer,integer)'::pg_catalog.regprocedure,
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
