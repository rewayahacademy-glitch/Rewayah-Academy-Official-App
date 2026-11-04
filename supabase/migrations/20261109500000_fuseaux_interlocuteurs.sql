-- FUSEAUX, partie serveur (garde-cap, 04/11/2026 ; PLAN-LOTS §12, releve du
-- 03/11). Mots du directeur : « chacun voit son fuseau et celui de son
-- interlocuteur : exemple, 08h chez vous (paris), et 06h chez "Sayyid/sayda"
-- (C.Ivoire) et vice versa ».
--
-- Defaut central : « Chez Sayyid X » affiche `groupes.timezone_iana`, le fuseau
-- de la CLASSE (`horloge_classe`, `horloge_seance`), pas celui de
-- l'interlocuteur. Aucune signature existante ne change (changer un type de
-- retour imposerait de retirer la fonction) : une fonction NOUVELLE,
-- `public.horloge_interlocuteurs(p_groupe uuid)`, rend selon l'appelant :
--   * famille ou eleve : l'enseignant effectif de la prochaine seance
--     (remplacant compris), son fuseau (`teacher_profiles.timezone_iana`), son
--     titre tel qu'il est enregistre (`teacher_profiles.titre`, jamais deduit),
--     son prenom (masque en observation, `agent_identite_masquee`) et son pays ;
--   * enseignant (titulaire ou remplacant de la prochaine seance) : les
--     fuseaux distincts des familles de la classe, chacun avec le nombre de
--     familles, sans aucun nom ;
--   * direction : les deux.
-- Pour chaque fuseau : le decalage UTC actuel (secondes) et l'instant du
-- prochain changement d'heure. Le client ne fait aucune conversion IANA (le
-- `pubspec` est gele) : il affiche « maintenant + decalage » et relit a la
-- bascule. Un fuseau d'enseignant vide rend le fuseau de la classe avec
-- `source = 'classe'` : le client dit alors « Heure de la classe ».
--
-- FICHIER SANS EFFACEMENT (regle B5) : deux fonctions creees ; rien n'est
-- retire ni remplace.

BEGIN;

-- 1. Le decalage actuel d'un fuseau et son prochain changement ---------------
-- Le decalage est la difference entre l'heure locale et l'heure UTC au meme
-- instant. Le prochain changement est cherche jour par jour sur 400 jours,
-- puis heure par heure, puis par quart d'heure : les changements d'heure
-- tombent tous sur un quart d'heure, l'instant rendu est donc exact. Aucun
-- changement sur 400 jours : `prochain_changement` nul. Un fuseau inconnu de
-- la base rend un objet nul (l'appelant dit alors ce qui manque).
CREATE FUNCTION private.fuseau_info(p_fuseau text, p_maintenant timestamptz DEFAULT pg_catalog.now())
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_decalage integer;
  v_jour timestamptz;
  v_heure timestamptz;
  v_quart timestamptz;
  v_changement timestamptz;
BEGIN
  IF p_fuseau IS NULL OR pg_catalog.btrim(p_fuseau) = '' THEN
    RETURN NULL;
  END IF;
  BEGIN
    v_decalage := EXTRACT(epoch FROM
      (p_maintenant AT TIME ZONE p_fuseau) - (p_maintenant AT TIME ZONE 'UTC'))::integer;
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;

  SELECT j INTO v_jour
    FROM pg_catalog.generate_series(p_maintenant + interval '1 day',
                                    p_maintenant + interval '400 days', interval '1 day') AS j
   WHERE EXTRACT(epoch FROM (j AT TIME ZONE p_fuseau) - (j AT TIME ZONE 'UTC'))::integer
         <> v_decalage
   ORDER BY j
   LIMIT 1;

  IF v_jour IS NOT NULL THEN
    SELECT h INTO v_heure
      FROM pg_catalog.generate_series(
             pg_catalog.date_trunc('hour', v_jour - interval '1 day'), v_jour, interval '1 hour') AS h
     WHERE EXTRACT(epoch FROM (h AT TIME ZONE p_fuseau) - (h AT TIME ZONE 'UTC'))::integer
           <> v_decalage
     ORDER BY h
     LIMIT 1;
    SELECT q INTO v_quart
      FROM pg_catalog.generate_series(v_heure - interval '1 hour', v_heure, interval '15 minutes') AS q
     WHERE EXTRACT(epoch FROM (q AT TIME ZONE p_fuseau) - (q AT TIME ZONE 'UTC'))::integer
           <> v_decalage
     ORDER BY q
     LIMIT 1;
    v_changement := v_quart;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'fuseau', p_fuseau,
    'decalage_secondes', v_decalage,
    'prochain_changement', v_changement);
END;
$function$;

-- 2. Les interlocuteurs d'une classe, selon l'appelant -------------------------
CREATE FUNCTION public.horloge_interlocuteurs(p_groupe uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_role text := public.app_role()::text;
  v_seance uuid;
  v_enseignant uuid;
  v_est_famille boolean := false;
  v_est_enseignant boolean := false;
  v_est_direction boolean := false;
  v_tp public.teacher_profiles%ROWTYPE;
  v_prof public.profiles%ROWTYPE;
  v_classe jsonb;
  v_resultat jsonb;
  v_ens jsonb := NULL;
  v_familles jsonb := NULL;
BEGIN
  IF p_groupe IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'horloge des interlocuteurs non autorisee' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_g FROM public.groupes g WHERE g.id = p_groupe;
  IF v_g.id IS NULL THEN
    RAISE EXCEPTION 'horloge des interlocuteurs non autorisee' USING ERRCODE = '42501';
  END IF;

  -- La prochaine seance vivante de la classe, et son enseignant effectif
  -- (remplacant compris) ; sans seance, le titulaire de la classe.
  SELECT s.id INTO v_seance
    FROM public.sessions s
   WHERE s.groupe_id = p_groupe
     AND s.deleted_at IS NULL
     AND s.status IN ('planned', 'preflight', 'in_progress')
     AND coalesce(s.ended_at, s.started_at + interval '1 hour') > pg_catalog.now()
   ORDER BY s.started_at
   LIMIT 1;
  v_enseignant := coalesce(
    CASE WHEN v_seance IS NULL THEN NULL ELSE private.salle_enseignant_effectif(v_seance) END,
    v_g.teacher_id);

  v_est_direction := v_role = 'admin';
  v_est_enseignant := v_role = 'teacher'
    AND (auth.uid() = v_g.teacher_id OR auth.uid() = v_enseignant);
  v_est_famille := EXISTS (
    SELECT 1 FROM public.groupe_membres m
     WHERE m.groupe_id = p_groupe AND m.left_at IS NULL
       AND (m.student_id = auth.uid()
            OR (v_role = 'guardian' AND public.est_du_foyer(m.student_id))));

  IF NOT (v_est_direction OR v_est_enseignant OR v_est_famille) THEN
    RAISE EXCEPTION 'horloge des interlocuteurs non autorisee' USING ERRCODE = '42501';
  END IF;

  v_classe := private.fuseau_info(v_g.timezone_iana);

  -- L'enseignant, pour la famille, l'eleve et la direction.
  IF v_est_famille OR v_est_direction THEN
    SELECT * INTO v_tp FROM public.teacher_profiles tp
     WHERE tp.profile_id = v_enseignant AND tp.deleted_at IS NULL;
    SELECT * INTO v_prof FROM public.profiles p WHERE p.id = v_enseignant;
    v_ens := pg_catalog.jsonb_build_object(
        'titre', v_tp.titre,
        'prenom', CASE WHEN v_prof.id IS NULL THEN NULL
                       WHEN public.agent_identite_masquee() THEN v_prof.immutable_id
                       ELSE nullif(pg_catalog.btrim(v_prof.first_name), '') END,
        'pays', v_tp.country,
        'remplacant', v_enseignant IS DISTINCT FROM v_g.teacher_id)
      || CASE
           WHEN private.fuseau_info(v_tp.timezone_iana) IS NOT NULL
             THEN private.fuseau_info(v_tp.timezone_iana)
                  || pg_catalog.jsonb_build_object('source', 'enseignant')
           ELSE coalesce(v_classe, '{}'::jsonb)
                  || pg_catalog.jsonb_build_object('source', 'classe')
         END;
  END IF;

  -- Les fuseaux des familles, pour l'enseignant et la direction : aucun nom,
  -- seulement le fuseau et le nombre de familles.
  IF v_est_enseignant OR v_est_direction THEN
    SELECT coalesce(pg_catalog.jsonb_agg(
             coalesce(private.fuseau_info(f.fuseau), pg_catalog.jsonb_build_object('fuseau', f.fuseau))
             || pg_catalog.jsonb_build_object('familles', f.n)
             ORDER BY f.n DESC, f.fuseau), '[]'::jsonb)
      INTO v_familles
      FROM (
        SELECT h.timezone AS fuseau, pg_catalog.count(DISTINCT h.id)::integer AS n
          FROM public.groupe_membres m
          JOIN public.profiles e ON e.id = m.student_id AND e.deleted_at IS NULL
          JOIN public.households h ON h.id = e.household_id AND h.deleted_at IS NULL
         WHERE m.groupe_id = p_groupe AND m.left_at IS NULL
         GROUP BY h.timezone
      ) f;
  END IF;

  v_resultat := pg_catalog.jsonb_build_object(
    'maintenant', pg_catalog.now(),
    'moi', private.fuseau_info(public.mon_fuseau()),
    'classe', v_classe);
  IF v_ens IS NOT NULL THEN
    v_resultat := v_resultat || pg_catalog.jsonb_build_object('enseignant', v_ens);
  END IF;
  IF v_familles IS NOT NULL THEN
    v_resultat := v_resultat || pg_catalog.jsonb_build_object('familles', v_familles);
  END IF;
  RETURN v_resultat;
END;
$function$;

-- Droits -----------------------------------------------------------------------
ALTER FUNCTION private.fuseau_info(text, timestamptz) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.fuseau_info(text, timestamptz) FROM PUBLIC;

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.horloge_interlocuteurs(uuid)'::pg_catalog.regprocedure;
  v_prive pg_catalog.regprocedure := 'private.fuseau_info(text,timestamptz)'::pg_catalog.regprocedure;
  v_role text;
BEGIN
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
  FOREACH v_role IN ARRAY ARRAY['anon', 'service_role', 'agent_ro', 'authenticated'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_prive, v_role);
      IF v_role <> 'authenticated' THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
      END IF;
    END IF;
  END LOOP;
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-04. FUSEAUX : le fuseau de chaque interlocuteur d''une classe (enseignant effectif pour la famille, fuseaux des familles pour l''enseignant, les deux pour la direction), decalage actuel et prochain changement d''heure.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

-- Postflight ----------------------------------------------------------------
-- Aucun nombre ecrit en dur : on lit les fonctions installees et leurs droits.
DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.horloge_interlocuteurs(uuid)'::pg_catalog.regprocedure;
  v_prive pg_catalog.regprocedure := 'private.fuseau_info(text,timestamptz)'::pg_catalog.regprocedure;
  v_p record;
BEGIN
  FOR v_p IN SELECT p.oid, p.prosecdef, p.proconfig, p.provolatile FROM pg_catalog.pg_proc p
              WHERE p.oid IN (v_oid, v_prive) LOOP
    IF NOT v_p.prosecdef OR NOT ('search_path=""' = ANY (v_p.proconfig)) OR v_p.provolatile <> 's' THEN
      RAISE EXCEPTION 'FUSEAUX : % doit etre SECURITY DEFINER, STABLE, search_path vide', v_p.oid::pg_catalog.regprocedure;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', v_prive, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_prive, 'EXECUTE') THEN
    RAISE EXCEPTION 'FUSEAUX : droits d''execution incorrects';
  END IF;
  -- Le calcul du prochain changement : Paris passe a l'heure d'hiver le
  -- dernier dimanche d'octobre a 01:00 UTC.
  IF (private.fuseau_info('Europe/Paris', '2026-10-01 12:00+00') ->> 'prochain_changement')::timestamptz
     IS DISTINCT FROM '2026-10-25 01:00+00'::timestamptz THEN
    RAISE EXCEPTION 'FUSEAUX : prochain changement d''heure mal calcule pour Europe/Paris';
  END IF;
END;
$postflight$;

COMMIT;
