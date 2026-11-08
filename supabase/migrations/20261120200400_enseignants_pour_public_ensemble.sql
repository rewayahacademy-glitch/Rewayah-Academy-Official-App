-- PERF-ATTENTE (b) (garde-cap, 07/11/2026 : feu vert) : public.enseignants_pour_public
-- reecrite EN ENSEMBLE, meme resultat.
--
-- Constat (production, lecture seule, 07/11/2026) : 52 appels, moyenne 1 797 ms,
-- maximum 6 757 ms ; la production ne compte pourtant qu'UN enseignant eligible,
-- 24 disponibilites et 21 creneaux de classes actives. Cause : pour chaque
-- disponibilite, la fonction appelle app_private.creneaux_recurrents_se_chevauchent_durees
-- contre chaque creneau de classe (et chaque disponibilite d'un eleve en cours
-- particulier) ; chaque appel calcule 52 x 3 paires de semaines, soit environ
-- 600 appels a public.instant_creneau : 24 x 21 x 600 = plus de 300 000 calculs
-- de fuseau pour UN enseignant. Le cout croit comme enseignants x disponibilites
-- x creneaux : 20 enseignants, c'est une demi-minute.
--
-- Correction : l'instant de chaque creneau distinct (52 semaines) n'est calcule
-- QU'UNE FOIS (une serie par creneau, environ 2 300 calculs au lieu de 300 000), puis
-- chaque paire est comparee sur ces series par app_private.series_se_chevauchent,
-- qui reprend a l'identique la regle de creneaux_recurrents_se_chevauchent_durees :
-- la semaine n du creneau A contre les semaines n-1, n et n+1 du creneau B,
-- chevauchement strict (debut A < fin B et debut B < fin A). AUCUNE regle metier ne
-- change : memes lignes, memes colonnes, meme tri (nom, prenom, identifiant) ; les
-- creneaux libres gardent leur tri (jour, heure) ; la garde, les erreurs et les
-- droits sont ceux d'avant. Seule difference, dite : a jour et heure egaux, les
-- creneaux libres se departagent maintenant par fuseau (l'ancien ordre etait
-- indetermine dans ce cas).
--
-- Remplacement de la fonction complete, sur la definition en place relue en
-- production le 07/11/2026 (md5 de pg_get_functiondef b992c501b63163c7f0a48b23adfad93b,
-- le meme que celui d'une base rejouee depuis le depot) ; le preflight s'arrete sur
-- tout autre etat (sauf une fonction deja remplacee : rejouable).
--
-- Aucun mot d'effacement. Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('public.enseignants_pour_public(text)'::regprocedure);
BEGIN
  IF pg_catalog.md5(v_def) <> 'b992c501b63163c7f0a48b23adfad93b'
     AND pg_catalog.strpos(v_def, 'series_se_chevauchent') = 0 THEN
    RAISE EXCEPTION 'PERF-ENSEIGNANTS : enseignants_pour_public a change (md5 %), migration a revoir',
      pg_catalog.md5(v_def);
  END IF;
  IF pg_catalog.to_regprocedure('app_private.creneaux_de_classe(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('app_private.creneau_couvert_par_disponibilites(uuid,integer,integer,text,integer)') IS NULL
     OR pg_catalog.to_regprocedure('public.instant_creneau(integer,integer,text,integer)') IS NULL THEN
    RAISE EXCEPTION 'PERF-ENSEIGNANTS : une fonction de creneaux attendue est absente, arret';
  END IF;
END;
$preflight$;

-- Deux creneaux hebdomadaires, donnes par la serie de leurs instants sur 52
-- semaines (indices 1 a 52), se chevauchent-ils ? Meme regle que
-- app_private.creneaux_recurrents_se_chevauchent_durees (qui calcule les instants
-- a chaque appel) : la semaine n de A contre les semaines n-1, n, n+1 de B.
CREATE OR REPLACE FUNCTION app_private.series_se_chevauchent(
  p_serie_a timestamptz[], p_duree_a integer, p_serie_b timestamptz[], p_duree_b integer)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM pg_catalog.generate_series(1, 52) AS semaine_a(n)
    CROSS JOIN LATERAL pg_catalog.generate_series(
      greatest(1, semaine_a.n - 1), least(52, semaine_a.n + 1)
    ) AS semaine_b(n)
    WHERE p_serie_a[semaine_a.n] < p_serie_b[semaine_b.n] + pg_catalog.make_interval(mins => p_duree_b)
      AND p_serie_b[semaine_b.n] < p_serie_a[semaine_a.n] + pg_catalog.make_interval(mins => p_duree_a)
  );
$function$;

CREATE OR REPLACE FUNCTION public.enseignants_pour_public(p_type_public text)
 RETURNS TABLE(teacher_id uuid, first_name text, last_name text, immutable_id text, country text, titre_public text, timezone_iana text, classes_actives integer, creneaux_pris jsonb, creneaux_libres jsonb)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_duree integer;
  v_duree_individuelle integer;
  v_masque boolean;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'proposition d''enseignants reservee a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_type_public IS NULL OR p_type_public NOT IN ('enfant', 'adulte') THEN
    RAISE EXCEPTION 'public invalide' USING ERRCODE = '22023';
  END IF;
  -- CLASSES-DUREE (23/10) : la duree du public demande (aucune offre, aucune
  -- Classe encore) ; les affectations individuelles gardent la duree unique.
  v_duree := app_private.duree_seance_minutes(NULL, p_type_public);
  v_duree_individuelle := public.app_config_int('session_duration_minutes', 60);
  v_masque := coalesce(public.agent_identite_masquee(), false);

  RETURN QUERY
  WITH eligibles AS MATERIALIZED (
    SELECT p.id, p.first_name, p.last_name, p.immutable_id, p.gender, tp.country, tp.timezone_iana
    FROM public.profiles p
    JOIN public.teacher_profiles tp ON tp.profile_id = p.id
    WHERE p.role = 'teacher' AND p.deleted_at IS NULL
      AND p.account_status IN ('active', 'provisional_active')
      AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
      AND tp.deleted_at IS NULL AND tp.kyc_status = 'approved'
  ),
  -- Les creneaux des Classes actives de ces enseignants, avec leur duree.
  classes AS MATERIALIZED (
    SELECT g.teacher_id AS enseignant, g.timezone_iana AS fuseau, s.jour, s.heure, s.duree
    FROM public.groupes g
    CROSS JOIN LATERAL app_private.creneaux_de_classe(g.id) s
    WHERE g.teacher_id IN (SELECT e.id FROM eligibles e)
      AND g.ended_at IS NULL AND g.etat = 'active'
  ),
  dispos AS MATERIALIZED (
    SELECT wa.profile_id, wa.weekday, wa.hour_local, wa.timezone_iana
    FROM public.weekly_availability wa
    WHERE wa.profile_id IN (SELECT e.id FROM eligibles e)
  ),
  -- Les heures declarees par les eleves en cours particulier de ces enseignants.
  occupes AS MATERIALIZED (
    SELECT tsa.teacher_id AS enseignant, busy.weekday, busy.hour_local, busy.timezone_iana
    FROM public.teacher_student_assignments tsa
    JOIN public.weekly_availability busy ON busy.profile_id = tsa.student_id
    WHERE tsa.teacher_id IN (SELECT e.id FROM eligibles e) AND tsa.ended_at IS NULL
  ),
  -- Une serie d'instants (52 semaines) par creneau DISTINCT : calculee une fois.
  series AS MATERIALIZED (
    SELECT x.jour, x.heure, x.fuseau,
           ARRAY(SELECT public.instant_creneau(x.jour, x.heure, x.fuseau, n)
                   FROM pg_catalog.generate_series(0, 51) AS n ORDER BY n) AS instants
    FROM (SELECT d.weekday::integer, d.hour_local::integer, d.timezone_iana FROM dispos d
          UNION SELECT c.jour, c.heure, c.fuseau FROM classes c
          UNION SELECT o.weekday::integer, o.hour_local::integer, o.timezone_iana FROM occupes o
         ) AS x(jour, heure, fuseau)
  )
  SELECT e.id,
         CASE WHEN v_masque THEN NULL ELSE e.first_name END,
         CASE WHEN v_masque THEN NULL ELSE e.last_name END,
         e.immutable_id, e.country,
         CASE e.gender WHEN 'female' THEN 'sayyida' WHEN 'male' THEN 'sayyid' END,
         e.timezone_iana,
         (SELECT count(*)::integer FROM public.groupes g
           WHERE g.teacher_id = e.id AND g.ended_at IS NULL AND g.etat = 'active'),
         coalesce((
           SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                    'weekday', b.weekday, 'hour_local', b.hour_local, 'timezone_iana', b.timezone_iana)
                  ORDER BY b.weekday, b.hour_local, b.timezone_iana)
           FROM (
             SELECT DISTINCT s.weekday, s.hour_local, g.timezone_iana
             FROM public.groupes g
             CROSS JOIN LATERAL (
               SELECT g.weekday, g.hour_local
               UNION SELECT gc.weekday, gc.hour_local FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
             ) s
             WHERE g.teacher_id = e.id AND g.ended_at IS NULL AND g.etat = 'active'
           ) b), '[]'::jsonb),
         coalesce((
           SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                    'weekday', wa.weekday, 'hour_local', wa.hour_local, 'timezone_iana', wa.timezone_iana)
                  ORDER BY wa.weekday, wa.hour_local, wa.timezone_iana)
           FROM dispos wa
           JOIN series sa ON sa.jour = wa.weekday AND sa.heure = wa.hour_local AND sa.fuseau = wa.timezone_iana
           WHERE wa.profile_id = e.id
             AND app_private.creneau_couvert_par_disponibilites(
                   wa.profile_id, wa.weekday, wa.hour_local, wa.timezone_iana, v_duree)
             AND NOT EXISTS (
               SELECT 1 FROM classes c
               JOIN series sc ON sc.jour = c.jour AND sc.heure = c.heure AND sc.fuseau = c.fuseau
               WHERE c.enseignant = e.id
                 AND app_private.series_se_chevauchent(sa.instants, v_duree, sc.instants, c.duree))
             AND NOT EXISTS (
               SELECT 1 FROM occupes o
               JOIN series so ON so.jour = o.weekday AND so.heure = o.hour_local AND so.fuseau = o.timezone_iana
               WHERE o.enseignant = e.id
                 AND app_private.series_se_chevauchent(sa.instants, v_duree, so.instants, v_duree_individuelle))), '[]'::jsonb)
  FROM eligibles e
  ORDER BY e.last_name, e.first_name, e.id;
END;
$function$;

-- Droits restates (le remplacement les garde ; on les relit), empreinte F86 a jour.
DO $droits$
DECLARE
  v_oid regprocedure := 'public.enseignants_pour_public(text)'::regprocedure;
  v_helper regprocedure := 'app_private.series_se_chevauchent(timestamptz[],integer,timestamptz[],integer)'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-11-07. PortEnseignantsClasse.pourClasse. CLASSES-DUREE : les creneaux libres comptent la duree du public demande. PERF-ATTENTE (b) : reecrite en ensemble, meme resultat (les instants de chaque creneau distinct sont calcules une fois). Garde: direction active.',
    'enseignants_pour_public(text)', pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_helper);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_helper);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_helper,
    'PERF-ATTENTE (b) : deux creneaux hebdomadaires, donnes par la serie de leurs instants sur 52 semaines, se chevauchent-ils ? Meme regle que app_private.creneaux_recurrents_se_chevauchent_durees (semaine n de A contre n-1, n, n+1 de B, chevauchement strict). IMMUTABLE, INVOKER, aucun EXECUTE client.');
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure := 'public.enseignants_pour_public(text)'::regprocedure;
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_oid), 'series_se_chevauchent') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_oid), 'creneaux_recurrents_se_chevauchent_durees') > 0 THEN
    RAISE EXCEPTION 'PERF-ENSEIGNANTS : enseignants_pour_public n''est pas la version en ensemble';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                   AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'app_private.series_se_chevauchent(timestamptz[],integer,timestamptz[],integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'app_private.series_se_chevauchent(timestamptz[],integer,timestamptz[],integer)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PERF-ENSEIGNANTS : droits ou search_path invalides';
  END IF;
END;
$postflight$;
