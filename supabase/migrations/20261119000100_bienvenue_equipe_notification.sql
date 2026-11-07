-- SALLE-3-ACCUEIL (07/11/2026) : « Bienvenue dans l'equipe » dans l'application.
-- Quand un compte enseignant passe de pending_kyc a active (valider_piece_candidat,
-- decider_dossier), une notification est posee pour lui, une seule fois, dans la
-- boite existante (celle que PUSH-1 enverra sur l'appareil). Le courriel
-- d'activation existe deja (courriel_compte_enseignant_valide) : aucun second
-- courriel, son texte est revu dans les modeles.
--
-- FICHIER SANS EFFACEMENT (B5) ; additif (B6) : une fonction et un declencheur.
-- Pas de BEGIN ni de COMMIT de premier niveau. Plage 20261119000000-099999.
-- Precondition : 20261119000000 est installee (l'evenement est dans la
-- contrainte) ; sinon la migration s'arrete et le dit.
--
-- Un echec de la notification ne doit JAMAIS empecher d'accueillir une
-- personne : toute erreur (contrainte, ou declencheur AFTER INSERT de la boite :
-- courriel, accuse, clore_gestes, ecart serveur, push) est dite en avertissement
-- et journalisee dans le journal de PUSH-1 s'il est installe
-- (private.push1_journaliser, teste par to_regprocedure), puis l'activation
-- continue. Sans cela, l'erreur annulerait l'activation faite par
-- decider_dossier / valider_piece_candidat.
--
-- Un enseignant qui passe de provisional_active a active ne recoit pas
-- « Bienvenue dans l'equipe » : c'est voulu (arbitrage du garde-cap,
-- 07/11/2026), il est deja dans l'equipe. Seul pending_kyc -> active en recoit
-- une.

DO $preflight$
BEGIN
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_constraint c
        WHERE c.conrelid = 'public.notifications'::regclass
          AND c.conname = 'notifications_evenement_check'
          AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''bienvenue_equipe''%') THEN
    RAISE EXCEPTION 'bienvenue_equipe : installer d''abord 20261119000000_bienvenue_equipe_evenement.sql';
  END IF;
END
$preflight$;

CREATE FUNCTION private.notification_bienvenue_equipe()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF EXISTS (SELECT 1 FROM public.notifications n
              WHERE n.destinataire = new.id AND n.evenement = 'bienvenue_equipe') THEN
    RETURN NULL;
  END IF;
  BEGIN
    INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
    VALUES (new.id, NULL, 'bienvenue_equipe', '{}'::jsonb, '/enseignant/journee');
  EXCEPTION WHEN OTHERS THEN
    -- Le sous-bloc annule l'insertion et ses declencheurs ; l'activation reste.
    RAISE WARNING 'bienvenue_equipe : notification non posee (SQLSTATE %), activation poursuivie', SQLSTATE;
    IF pg_catalog.to_regprocedure('private.push1_journaliser(text,text,text)') IS NOT NULL THEN
      BEGIN
        EXECUTE 'SELECT private.push1_journaliser($1, $2, $3)'
          USING 'notification:bienvenue_equipe', new.id::text, SQLSTATE;
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
    END IF;
  END;
  RETURN NULL;
END;
$function$;

COMMENT ON FUNCTION private.notification_bienvenue_equipe() IS
  'SALLE-3-ACCUEIL (07/11/2026) : pose la notification « Bienvenue dans l''equipe » au passage d''un compte enseignant de pending_kyc a active, une seule fois par personne.';

REVOKE ALL ON FUNCTION private.notification_bienvenue_equipe() FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION private.notification_bienvenue_equipe() FROM agent_ro';
  END IF;
END
$agent_ro$;

CREATE TRIGGER profiles_notification_bienvenue_equipe
  AFTER UPDATE OF account_status ON public.profiles
  FOR EACH ROW
  WHEN (old.account_status = 'pending_kyc'
        AND new.account_status = 'active'
        AND new.role = 'teacher')
  EXECUTE FUNCTION private.notification_bienvenue_equipe();

DO $postflight$
BEGIN
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = 'private.notification_bienvenue_equipe()'::regprocedure
          AND p.prosecdef AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
          AND coalesce(p.proconfig @> ARRAY['search_path=""'], false))
     OR pg_catalog.has_function_privilege('authenticated',
          'private.notification_bienvenue_equipe()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
          'private.notification_bienvenue_equipe()'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'bienvenue_equipe : la fonction n''a pas la forme attendue (proprietaire, SECURITY DEFINER, search_path, droits)';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_trigger t
        WHERE t.tgrelid = 'public.profiles'::regclass
          AND t.tgname = 'profiles_notification_bienvenue_equipe' AND NOT t.tgisinternal
          AND t.tgenabled = 'O') THEN
    RAISE EXCEPTION 'bienvenue_equipe : le declencheur est absent ou desactive';
  END IF;
END
$postflight$;
