-- NOTIF-RETENU (08/11/2026, ordre du directeur relaye par le pilote le 07/11 vers
-- 23:59 UTC) : « Votre candidature est retenue pour un entretien » dans
-- l'application, au passage d'une candidature d'enseignant de la salle 1
-- (etape prequalification) a la salle 2 (etape verifications). Le courriel du
-- meme nom existe deja (SALLE-1, 20261119100000, enfile par
-- admettre_salle_verification) : aucun second courriel.
--
-- Deux choses, toutes additives :
--   1. une ligne dans private.push_evenements : categorie `admissions` (« Demandes
--      et dossiers »), que la personne peut couper ; sans etiquette ;
--   2. une fonction et un declencheur AFTER UPDATE OF etape sur
--      public.candidatures, comme bienvenue_equipe sur profiles.
-- Aucune ligne dans private.notification_courriel : depuis FN-114a
-- (20261103700000), un evenement absent de cette table ne part PAS par courriel
-- (application seulement), donc cette notification n'enfile aucun second
-- courriel ; le scenario le prouve. Le push, lui, est actif par defaut
-- (private.notification_avec_push : evenement absent = oui).
--
-- Le declencheur couvre toute voie d'admission (le geste de la direction comme
-- tout autre), une fois par passage. Un echec de la notification ne doit JAMAIS
-- empecher d'admettre : l'erreur est dite en avertissement, journalisee dans le
-- journal de PUSH-1 s'il est installe, puis l'admission continue.
--
-- PUSH : le push ne part que si le compte est autorise (private.push_compte_autorise
-- : compte `active` ou `provisional_active`). Un candidat est `pending_kyc` : il
-- recoit la notification dans l'application, PAS sur l'appareil, tant que cette
-- regle ne change pas (decision du directeur, hors de ce lot).
--
-- Preconditions : 20261121000000 installee (evenement dans la contrainte) ;
-- 20261119200000 (destination /attente/entretien) ; PUSH-1 (push_evenements).
-- Sinon la migration s'arrete et le dit.
--
-- FICHIER SANS MOT D'EFFACEMENT (B5) ; sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_constraint c
        WHERE c.conrelid = 'public.notifications'::regclass
          AND c.conname = 'notifications_evenement_check'
          AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''retenu_entretien''%') THEN
    RAISE EXCEPTION 'retenu_entretien : installer d''abord 20261121000000_notif_retenu_evenement.sql';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_constraint c
        WHERE c.conrelid = 'public.notifications'::regclass
          AND c.conname = 'notifications_destination_check'
          AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''/attente/entretien''%') THEN
    RAISE EXCEPTION 'retenu_entretien : la destination /attente/entretien manque (installer 20261119200000)';
  END IF;
  IF pg_catalog.to_regclass('private.push_evenements') IS NULL
     THEN
    RAISE EXCEPTION 'retenu_entretien : PUSH-1 n''est pas installe';
  END IF;
END
$preflight$;

-- 1. Categorie du push.
INSERT INTO private.push_evenements (evenement, categorie, tag)
VALUES ('retenu_entretien', 'admissions', NULL)
ON CONFLICT (evenement) DO UPDATE SET categorie = EXCLUDED.categorie, tag = EXCLUDED.tag;

-- 2. La notification, au passage en salle 2.
CREATE FUNCTION private.notification_retenu_entretien()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF new.profile_id IS NULL THEN
    RETURN NULL;
  END IF;
  BEGIN
    INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
    VALUES (new.profile_id, NULL, 'retenu_entretien', '{}'::jsonb, '/attente/entretien');
  EXCEPTION WHEN OTHERS THEN
    -- Le sous-bloc annule l'insertion et ses declencheurs ; l'admission reste.
    RAISE WARNING 'retenu_entretien : notification non posee (SQLSTATE %), admission poursuivie', SQLSTATE;
    IF pg_catalog.to_regprocedure('private.push1_journaliser(text,text,text)') IS NOT NULL THEN
      BEGIN
        EXECUTE 'SELECT private.push1_journaliser($1, $2, $3)'
          USING 'notification:retenu_entretien', new.id::text, SQLSTATE;
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
    END IF;
  END;
  RETURN NULL;
END;
$function$;

COMMENT ON FUNCTION private.notification_retenu_entretien() IS
  'NOTIF-RETENU (08/11/2026) : pose la notification « retenu pour un entretien » quand une candidature d''enseignant passe de prequalification a verifications, une par passage.';

REVOKE ALL ON FUNCTION private.notification_retenu_entretien() FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION private.notification_retenu_entretien() FROM agent_ro';
  END IF;
END
$agent_ro$;

CREATE TRIGGER candidatures_notification_retenu_entretien
  AFTER UPDATE OF etape ON public.candidatures
  FOR EACH ROW
  WHEN (old.etape = 'prequalification'
        AND new.etape = 'verifications'
        AND new.type_code = 'enseignant')
  EXECUTE FUNCTION private.notification_retenu_entretien();

DO $postflight$
BEGIN
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = 'private.notification_retenu_entretien()'::regprocedure
          AND p.prosecdef AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
          AND coalesce(p.proconfig @> ARRAY['search_path=""'], false))
     OR pg_catalog.has_function_privilege('authenticated',
          'private.notification_retenu_entretien()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
          'private.notification_retenu_entretien()'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'retenu_entretien : la fonction n''a pas la forme attendue (proprietaire, SECURITY DEFINER, search_path, droits)';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_trigger t
        WHERE t.tgrelid = 'public.candidatures'::regclass
          AND t.tgname = 'candidatures_notification_retenu_entretien' AND NOT t.tgisinternal
          AND t.tgenabled = 'O') THEN
    RAISE EXCEPTION 'retenu_entretien : le declencheur est absent ou desactive';
  END IF;
END
$postflight$;
