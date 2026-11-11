-- LUMIERE-RETARD (11/11/2026) : le rouge « retard » des accueils (directeur, 09-10/11/2026).
--
-- Constat : aucune lecture ne dit « la seance est en direct et cet eleve n'est pas encore entre,
-- au-dela du seuil ». `etat_presence()` dit `en_retard` pour un eleve qui est ENTRE apres l'heure
-- plus le seuil : il est dans la salle, ce n'est pas l'alerte voulue. L'etat voulu est l'autre
-- cote du meme seuil : `en_attente` ou `en_connexion` (jamais entre) alors que la seance est
-- `in_progress` et que `started_at + presence.seuil_retard_secondes` est depasse.
--
-- Cette fonction ne recalcule pas la presence : elle fixe seulement la porte (seance en direct,
-- seuil du reglage `presence.seuil_retard_secondes`, le MEME que `etat_presence`, aucun seuil
-- ecrit ici) puis demande l'etat a `etat_presence()`, qui rend deja la derogation de la
-- direction (`session_presence_override`), le jeton video recent (`en_connexion`) et la
-- sortie. Une presence deja jugee (derogation, excusee) n'allume donc rien.
--
-- Qui lit : l'eleve pour lui-meme, le tuteur pour les enfants de son foyer (`est_du_foyer`),
-- l'enseignant effectif de la seance (C-29, titulaire ou remplacant), la direction et le
-- controleur. Une ligne n'est rendue que si l'appelant peut la lire ; un autre foyer ne recoit
-- AUCUNE ligne (jamais d'erreur qui dirait que la seance existe). Aucune ecriture.
--
-- Les lignes d'une seance qui n'est pas en direct, ou avant le seuil, n'existent pas.
-- Sans mot d'effacement.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.retard_en_direct(uuid)') IS NOT NULL THEN
    RAISE EXCEPTION 'LUMIERE-RETARD : deja installee';
  END IF;
  -- Les fonctions appelees existent ; les deux relues en production gardent leur empreinte.
  IF pg_catalog.to_regprocedure('public.etat_presence(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.est_du_foyer(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.app_config_int(text,integer)') IS NULL
     OR pg_catalog.to_regprocedure('private.c29_enseignant_effectif_session(uuid)') IS NULL THEN
    RAISE EXCEPTION 'LUMIERE-RETARD : une fonction appelee est absente';
  END IF;
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.app_role()'::pg_catalog.regprocedure))
       <> 'b20471b9c758fed68602f39e075717c1'
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef('public.app_account_valid()'::pg_catalog.regprocedure))
       <> '25ef4708ed7b2d0b81a58f3c13675f95' THEN
    RAISE EXCEPTION 'LUMIERE-RETARD : app_role ou app_account_valid a change depuis la relecture, migration a revoir';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM information_schema.columns
       WHERE table_schema = 'public'
         AND (table_name, column_name) IN (
           ('sessions', 'id'), ('sessions', 'status'), ('sessions', 'started_at'), ('sessions', 'deleted_at'),
           ('session_participants', 'session_id'), ('session_participants', 'profile_id'),
           ('session_participants', 'role'), ('session_participants', 'deleted_at'))) <> 8 THEN
    RAISE EXCEPTION 'LUMIERE-RETARD : une colonne lue est absente';
  END IF;
END
$preflight$;

CREATE FUNCTION public.retard_en_direct(p_session_id uuid)
RETURNS TABLE (
  student_id uuid,
  started_at timestamp with time zone,
  retard_secondes integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH candidats AS MATERIALIZED (
    -- La porte : compte valide, seance en direct, seuil du reglage depasse, puis seulement
    -- les eleves que l'appelant peut lire. `etat_presence` n'est appele que sur ces lignes
    -- (il leve « acces refuse » pour une ligne illisible).
    SELECT sp.profile_id AS eleve,
           s.id AS seance,
           s.started_at AS debut
      FROM public.sessions s
      JOIN public.session_participants sp
        ON sp.session_id = s.id
       AND sp.role = 'student'
       AND sp.deleted_at IS NULL
     WHERE public.app_account_valid()
       AND s.id = p_session_id
       AND s.deleted_at IS NULL
       AND s.status = 'in_progress'
       AND s.started_at IS NOT NULL
       AND pg_catalog.now() > s.started_at
             + pg_catalog.make_interval(secs => public.app_config_int('presence.seuil_retard_secondes', 300))
       AND coalesce(
             public.app_role() = ANY (ARRAY['admin', 'controller']::public.app_role[])
             OR private.c29_enseignant_effectif_session(s.id) = auth.uid()
             OR (public.app_role() = 'guardian' AND public.est_du_foyer(sp.profile_id))
             OR sp.profile_id = auth.uid(),
             false)
  )
  SELECT c.eleve,
         c.debut,
         pg_catalog.floor(extract(epoch FROM (pg_catalog.now() - c.debut)))::integer
    FROM candidats c
   WHERE public.etat_presence(c.seance, c.eleve)::text IN ('en_attente', 'en_connexion')
   ORDER BY c.eleve
$function$;
ALTER FUNCTION public.retard_en_direct(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.retard_en_direct(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.retard_en_direct(uuid) TO authenticated;

COMMENT ON FUNCTION public.retard_en_direct(uuid) IS
  'LUMIERE-RETARD (11/11/2026) : les eleves lisibles par l''appelant qui ne sont pas encore entres '
  'dans une seance en direct, au-dela de presence.seuil_retard_secondes. Lecture seule ; la presence '
  'vient de etat_presence (derogations comprises).';

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.retard_en_direct(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.retard_en_direct(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.retard_en_direct(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.retard_en_direct(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'LUMIERE-RETARD : droits d''execution inattendus';
  END IF;
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.retard_en_direct(uuid)'::pg_catalog.regprocedure))
       <> '3634cd22d6e12c7c44bb5665ac8bf4cf' THEN
    RAISE EXCEPTION 'LUMIERE-RETARD : l''empreinte de la fonction installee n''est pas celle attendue';
  END IF;
END
$postflight$;
