-- HARMONISATION-A (08/11/2026, plan valide par le garde-cap) : deux dettes,
-- sans aucun mot d'effacement.
--
-- 1. Dette 8 : le fuseau de l'avis d'entretien. private.entretien_heure_locale
--    (20261119200000) faisait AT TIME ZONE sur le fuseau de la fiche
--    enseignant, sinon sur celui de la candidature. Un nom invalide levait
--    22023 dans private.entretien_avis_passer : l'avis restait du et se
--    relancait chaque minute (jusqu'a 30 jours). Desormais chaque fuseau est
--    essaye (fiche, puis candidature) ; un fuseau invalide est passe ; sans
--    fuseau valide, l'heure part sans fuseau ('{}') et l'avis est pose une
--    seule fois. Meme signature, memes droits ; preflight md5 du corps de
--    production.
--
-- 2. Sortie rapide de private.remplacement_auto_passer (cron chaque minute ;
--    10 342 appels, 35 ms en moyenne, jusqu'a 1,5 s, mesure du 07/11). Une
--    fonction privee, private.remplacement_auto_a_faire, dit s'il existe au
--    moins une seance dans l'une des cinq fenetres que la fonction lit deja
--    (a. pre-alerte, b. titulaire entre pendant la pre-alerte, c. perte
--    d'acces, d. alerte de la direction, e. seance non tenue). C'est le
--    sur-ensemble exact de ces fenetres, jamais un sous-ensemble ; sinon la
--    fonction rend aussitot ses compteurs a zero, sans rien lire d'autre.
--    Remplacement par ancre, preflight md5 de la version retouchee par
--    PUSH-1 (20261112000200), egalite exacte apres.
--
-- Rejeu : stub_auth, toutes les migrations, puis
-- supabase/tests/scenarios_harmonisation_a_fuseau_sortie.sql.

-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
       WHERE p.oid = 'private.entretien_heure_locale(uuid,timestamptz)'::regprocedure)
     <> '517ef7c876e4a073c919189d0f18ebcd' THEN
    RAISE EXCEPTION 'HARMONISATION-A : private.entretien_heure_locale a change depuis le depot';
  END IF;
  IF pg_catalog.to_regprocedure('private.remplacement_auto_a_faire(timestamptz,integer,integer,integer)') IS NOT NULL THEN
    RAISE EXCEPTION 'HARMONISATION-A : deja installee';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Dette 8 : le fuseau de l'avis d'entretien
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.entretien_heure_locale(p_profil uuid, p_debut timestamptz)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_fuseau text;
BEGIN
  -- La fiche enseignant d'abord, puis la candidature la plus recente.
  FOR v_fuseau IN
    SELECT x.fuseau FROM (
      SELECT 1 AS ordre, tp.timezone_iana AS fuseau
        FROM public.teacher_profiles tp WHERE tp.profile_id = p_profil
      UNION ALL
      SELECT 2, d.fuseau_iana FROM (
        SELECT c.fuseau_iana FROM public.candidatures c
         WHERE c.profile_id = p_profil AND c.fuseau_iana IS NOT NULL
         ORDER BY c.recue_le DESC NULLS LAST LIMIT 1) d
    ) x
     WHERE x.fuseau IS NOT NULL
     ORDER BY x.ordre
  LOOP
    BEGIN
      RETURN pg_catalog.jsonb_build_object(
        'debut_local', pg_catalog.to_char(p_debut AT TIME ZONE v_fuseau, 'YYYY-MM-DD"T"HH24:MI'),
        'fuseau', v_fuseau);
    EXCEPTION WHEN invalid_parameter_value THEN
      -- Fuseau inconnu : on essaie le suivant ; jamais d'erreur dans l'avis.
      NULL;
    END;
  END LOOP;
  -- Aucun fuseau valide : l'heure part sans fuseau.
  RETURN '{}'::jsonb;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Sortie rapide : y a-t-il quelque chose a faire ?
-- ---------------------------------------------------------------------------
-- Les memes conditions que les cinq boucles de remplacement_auto_passer,
-- reunies sans ce qui n'en fait que retirer des lignes (sous-requetes NOT
-- EXISTS) : le resultat est un sur-ensemble. Les reglages sont ceux deja lus
-- par la fonction appelante.
CREATE FUNCTION private.remplacement_auto_a_faire(
  p_maintenant timestamptz, p_avert integer, p_alerte integer, p_non_tenue integer
) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT EXISTS (
    -- a, c, d : seance commencee depuis le plus petit seuil, pas finie.
    -- e : seance commencee depuis seance_non_tenue (finie ou non), pas reportee.
    SELECT 1
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id AND g.ended_at IS NULL
     WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight', 'in_progress')
       AND s.teacher_id IS NOT NULL
       AND ((s.started_at + pg_catalog.make_interval(mins => LEAST(p_avert, p_alerte)) <= p_maintenant
             AND s.ended_at > p_maintenant)
            OR (s.started_at + pg_catalog.make_interval(mins => p_non_tenue) <= p_maintenant
                AND NOT EXISTS (SELECT 1 FROM public.seances_reportees x WHERE x.session_id = s.id)))
  ) OR EXISTS (
    -- b : une pre-alerte ouverte (sans borne de temps, comme la boucle b).
    SELECT 1
      FROM public.sessions s
      JOIN public.remplacements_preparation pa ON pa.session_id = s.id AND pa.evenement = 'pre_alerte'
     WHERE s.deleted_at IS NULL
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_preparation x
                        WHERE x.session_id = s.id AND x.evenement = 'remplacement_inutile')
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_seance r WHERE r.session_id = s.id)
  );
$function$;
ALTER FUNCTION private.remplacement_auto_a_faire(timestamptz, integer, integer, integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.remplacement_auto_a_faire(timestamptz, integer, integer, integer)
  FROM PUBLIC;
DO $droits$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = r) THEN
      EXECUTE pg_catalog.format(
        'REVOKE ALL ON FUNCTION private.remplacement_auto_a_faire(timestamptz, integer, integer, integer) FROM %I', r);
    END IF;
  END LOOP;
END
$droits$;

-- ---------------------------------------------------------------------------
-- 3. remplacement_auto_passer : la sortie rapide, par ancre
-- ---------------------------------------------------------------------------
DO $ancre$
DECLARE
  c_f CONSTANT regprocedure := 'private.remplacement_auto_passer(timestamptz)'::regprocedure;
  c_ancre CONSTANT text :=
    E'    RAISE EXCEPTION ''reglages remplacement.* incoherents'' USING ERRCODE = ''22023'';\n  END IF;\n';
  c_neuf CONSTANT text :=
    E'    RAISE EXCEPTION ''reglages remplacement.* incoherents'' USING ERRCODE = ''22023'';\n  END IF;\n'
    || E'  -- HARMONISATION-A : rien dans aucune fenetre, sortie aussitot.\n'
    || E'  IF NOT private.remplacement_auto_a_faire(p_maintenant, v_avert, v_alerte, v_non_tenue) THEN\n'
    || E'    RETURN pg_catalog.jsonb_build_object(\n'
    || E'      ''reportees'', 0, ''alertes_direction'', 0,\n'
    || E'      ''pre_alertes'', 0, ''inutiles'', 0,\n'
    || E'      ''absences'', 0, ''prises'', 0, ''erreurs'', 0);\n'
    || E'  END IF;\n';
  v_avant record;
  v_def text;
  v_apres text;
BEGIN
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, pg_catalog.md5(p.prosrc) AS empreinte
    INTO v_avant FROM pg_catalog.pg_proc p WHERE p.oid = c_f;
  IF v_avant.empreinte <> 'e7a48a4c9e57f17495fdf04ef6988377' THEN
    RAISE EXCEPTION 'HARMONISATION-A : remplacement_auto_passer a change depuis le depot (md5 %)', v_avant.empreinte;
  END IF;
  v_def := pg_catalog.pg_get_functiondef(c_f);
  IF (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, c_ancre, '')))
     / pg_catalog.length(c_ancre) <> 1 THEN
    RAISE EXCEPTION 'HARMONISATION-A : ancre introuvable ou multiple dans remplacement_auto_passer';
  END IF;
  EXECUTE pg_catalog.replace(v_def, c_ancre, c_neuf);
  v_apres := pg_catalog.pg_get_functiondef(c_f);
  IF pg_catalog.replace(v_apres, c_neuf, c_ancre) <> v_def THEN
    RAISE EXCEPTION 'HARMONISATION-A : remplacement_auto_passer differe ailleurs que par la sortie rapide';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = c_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl) THEN
    RAISE EXCEPTION 'HARMONISATION-A : proprietaire, DEFINER, search_path ou droits modifies';
  END IF;
END
$ancre$;

-- ---------------------------------------------------------------------------
-- 4. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF (SELECT p.prolang FROM pg_catalog.pg_proc p
       WHERE p.oid = 'private.entretien_heure_locale(uuid,timestamptz)'::regprocedure)
     <> (SELECT l.oid FROM pg_catalog.pg_language l WHERE l.lanname = 'plpgsql')
     OR private.entretien_heure_locale(NULL, pg_catalog.now()) <> '{}'::jsonb
     OR pg_catalog.has_function_privilege('authenticated',
          'private.remplacement_auto_a_faire(timestamptz,integer,integer,integer)', 'EXECUTE') THEN
    RAISE EXCEPTION 'HARMONISATION-A : postflight en echec';
  END IF;
END
$postflight$;
