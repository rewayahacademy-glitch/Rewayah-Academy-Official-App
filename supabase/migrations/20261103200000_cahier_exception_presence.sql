-- CAHIER-EXCEPTION-PRESENCE (31/10/2026) : l'exception de presence signalee
-- dans le cahier corrige enfin la presence calculee par le serveur
-- (parcours 6 « Presence et cahier » de la ligne d'arrivee).
--
-- DELETE / DROP / TRUNCATE : 0. Une fonction privee de declencheur creee, un
-- declencheur cree, droits, commentaires, verifications.
--
-- Le defaut : l'ecran du cahier (`lib/features/cahier/cahier_page.dart`,
-- `_consigner`) range le motif de l'exception dans
-- `lesson_reports.content.eleves[].motif_exception` et rien d'autre.
-- `session_presence_override` (0007), seule correction humaine lue par
-- `private.presence_temps_reel` (PRESENCE-MINUTES, 20261102900000 :
-- `corrigee_manuel` vaut presente) et donc par `private.pai_eleves_presents`,
-- l'historique de la famille et la paie, n'etait jamais ecrite. Aucune RPC ni
-- aucun adaptateur ne l'ecrivait (recherche du 31/10 : seules des lectures).
--
-- Une seule ecriture atteint la base pour une meme decision : le depot du
-- cahier (insert dans `lesson_reports`, cle d'idempotence, file hors ligne).
-- Ce declencheur en tire l'exception, cote serveur, dans la meme transaction.
-- Aucun second chemin client, aucune RPC nouvelle.
--
-- Regles (deja decidees, non rediscutees) :
--   * l'enseignant ne juge pas une absence (planche 4, R2 ; le panneau du
--     cahier n'offre que « corriger », `peutExcuser: false`) : une exception
--     du cahier vaut `corrigee_manuel`, jamais `excusee` ;
--   * une decision deja prise par la direction (`excusee`, `finalisee`) n'est
--     jamais ecrasee par le cahier ; une `corrigee_manuel` existante prend le
--     motif et l'auteur du dernier cahier (correction K-45, point 5, qui
--     depose un nouveau cahier) ;
--   * seul un eleve inscrit a la seance (`session_participants`, role
--     eleve, non retire) recoit l'exception ; une ligne etrangere est ignoree ;
--   * garde positive : l'auteur est l'appelant, et il est l'enseignant de la
--     seance, son enseignant effectif (remplacant, C-29) ou la direction ;
--     sinon le depot du cahier est refuse (`ExceptionNonAutorisee`). Sans
--     JWT (role de confiance : postgres, service_role), l'auteur decide ;
--   * journal : `log_sensitive_access('presence_exception_cahier')` par eleve.
-- Limite connue : retirer une exception deja appliquee demanderait une suppression ;
-- un cahier corrige sans motif laisse donc l'exception en place, et seule la
-- direction peut la retirer (politique `spo_ecriture`, inchangee).
BEGIN;

CREATE FUNCTION private.cahier_appliquer_exceptions()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_appelant uuid := auth.uid();
  v_decideur uuid := coalesce(auth.uid(), NEW.author_profile_id);
  v_autorise boolean;
  r record;
BEGIN
  IF NEW.deleted_at IS NOT NULL OR NOT EXISTS (
    SELECT 1 FROM pg_catalog.jsonb_array_elements(
             CASE WHEN pg_catalog.jsonb_typeof(NEW.content -> 'eleves') = 'array'
                  THEN NEW.content -> 'eleves' ELSE '[]'::jsonb END) e
     WHERE nullif(pg_catalog.btrim(e.value ->> 'motif_exception'), '') IS NOT NULL
  ) THEN
    RETURN NEW;
  END IF;

  -- Sans appelant (aucun JWT) : seul un role de confiance ecrit ici
  -- (postgres, service_role ; la RLS ferme `lesson_reports` a anon et exige
  -- auth.uid() = auteur pour authenticated). L'auteur du cahier decide.
  v_autorise := coalesce(
    v_appelant IS NULL
    OR v_appelant = NEW.author_profile_id
    AND public.app_account_valid()
    AND (
      public.app_role() = 'admin'
      OR (public.app_role() = 'teacher'
          AND (public.session_belongs_to_teacher(NEW.session_id, v_appelant)
               OR private.c29_enseignant_effectif_session(NEW.session_id) = v_appelant))
    ), false);
  IF NOT v_autorise THEN
    RAISE EXCEPTION 'ExceptionNonAutorisee' USING ERRCODE = '42501';
  END IF;

  FOR r IN
    SELECT DISTINCT ON (sp.profile_id) sp.profile_id,
           pg_catalog.btrim(e.value ->> 'motif_exception') AS motif
      FROM pg_catalog.jsonb_array_elements(NEW.content -> 'eleves') e
      JOIN public.session_participants sp
        ON sp.session_id = NEW.session_id
       AND sp.profile_id::text = e.value ->> 'student_id'
       AND sp.role = 'student'
       AND sp.deleted_at IS NULL
     WHERE nullif(pg_catalog.btrim(e.value ->> 'motif_exception'), '') IS NOT NULL
     ORDER BY sp.profile_id
  LOOP
    INSERT INTO public.session_presence_override AS o
           (session_id, profile_id, etat, motif, decide_par, decide_le)
    VALUES (NEW.session_id, r.profile_id, 'corrigee_manuel', r.motif, v_decideur, pg_catalog.now())
    ON CONFLICT (session_id, profile_id) DO UPDATE
       SET motif = EXCLUDED.motif, decide_par = EXCLUDED.decide_par, decide_le = EXCLUDED.decide_le
     WHERE o.etat = 'corrigee_manuel';

    IF FOUND THEN
      PERFORM public.log_sensitive_access(
        'presence_exception_cahier', 'session_presence_override',
        NEW.session_id::text || ':' || r.profile_id::text,
        pg_catalog.jsonb_build_object(
          'session_id', NEW.session_id,
          'profile_id', r.profile_id,
          'etat', 'corrigee_manuel',
          'motif', r.motif,
          'lesson_report_id', NEW.id));
    END IF;
  END LOOP;

  RETURN NEW;
END;
$function$;

ALTER FUNCTION private.cahier_appliquer_exceptions() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.cahier_appliquer_exceptions()
  FROM PUBLIC, anon, authenticated, service_role;

CREATE TRIGGER lesson_reports_appliquer_exceptions
  AFTER INSERT ON public.lesson_reports
  FOR EACH ROW EXECUTE FUNCTION private.cahier_appliquer_exceptions();

COMMENT ON FUNCTION private.cahier_appliquer_exceptions() IS
  'CAHIER-EXCEPTION-PRESENCE (31/10/2026) : applique a session_presence_override (corrigee_manuel) chaque motif_exception du cahier depose, pour les eleves inscrits a la seance ; ne remplace jamais une decision excusee ou finalisee ; journal presence_exception_cahier. Erreur : ExceptionNonAutorisee. guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path="".';

DO $verif$
BEGIN
  IF has_function_privilege('anon', 'private.cahier_appliquer_exceptions()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.cahier_appliquer_exceptions()', 'EXECUTE') THEN
    RAISE EXCEPTION 'CAHIER-EXCEPTION-PRESENCE : la fonction du declencheur est exposee';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.lesson_reports'::regclass
                    AND t.tgname = 'lesson_reports_appliquer_exceptions'
                    AND NOT t.tgisinternal) THEN
    RAISE EXCEPTION 'CAHIER-EXCEPTION-PRESENCE : declencheur absent';
  END IF;
END;
$verif$;

COMMIT;
