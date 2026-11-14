-- MESSAGERIE-TEMPS-REEL (14/11/2026, retour du directeur en production) : la
-- messagerie entre un candidat et la direction (et toute la messagerie metier
-- COM-BACK-1) n'etait ni en direct ni signalee : il fallait rouvrir les
-- messages pour voir qu'il s'etait passe quelque chose.
--
-- FICHIER SANS MOT D'EFFACEMENT (compte : 0) ; sans BEGIN ni COMMIT de premier
-- niveau. S'installe par apply_migration, sans collage.
--
-- Pourquoi un SIGNAL et pas la publication de public.com_messages :
--   * com_messages, com_fils et com_lectures n'ont AUCUNE politique ni aucun
--     droit (lecture et ecriture par les RPC com_* seulement, COM-BACK-1). Les
--     publier dans Realtime demanderait d'ouvrir SELECT sur le texte des
--     messages au client : le modele de securite changerait. Non.
--   * public.notifications ne convient pas : un evenement de plus demande de
--     remplacer sa contrainte (mot d'effacement), et sa politique exige un
--     compte valide (app_account_valid) : un candidat (pending_kyc) n'y lit
--     rien.
--
-- Ce que fait ce fichier :
--   1. public.com_signaux : UNE ligne par personne (cle = destinataire), qui
--      dit « un fil vous concernant a bouge » : l'identifiant du fil, la
--      nature (message recu, ou lecture faite sur un autre appareil), un rang
--      qui monte, l'heure. AUCUN texte, aucun nom. La table ne grossit pas :
--      la ligne est remplacee (ON CONFLICT ... DO UPDATE), jamais empilee.
--      RLS : chacun ne lit que SA ligne ; aucun droit d'ecriture client.
--   2. private.com_signaler_message() : apres chaque message, une ligne pour
--      chaque personne de l'autre partie du fil (profil ; adultes du foyer,
--      jamais un mineur ; equipe = direction active, et pour une candidature
--      seulement la direction de SON cote, par private.com_candidature_lisible,
--      CAND-Q07), jamais l'auteur.
--   3. private.com_signaler_lecture() : une lecture (com_lectures) signale la
--      personne elle-meme, pour que ses autres appareils retirent le badge.
--   4. Publication dans supabase_realtime (si elle existe : sur un Postgres nu,
--      CI, rien a publier) ; la RLS est exigee partout.
--
-- Le signal ne decide d'aucun droit : l'application relit les fils par les
-- RPC habituelles (com_lister_fils, com_lire_fil), sous leurs gardes. Un
-- signal recu a tort ne montre donc rien de plus. Un echec du signal n'empeche
-- jamais l'envoi du message (EXCEPTION -> WARNING, sans SQLERRM).
--
-- Notification push et courriel : NON branches ici (dette nommee dans la PR).

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.com_messages') IS NULL
     OR pg_catalog.to_regclass('public.com_lectures') IS NULL THEN
    RAISE EXCEPTION 'messagerie temps reel : COM-BACK-1 (20261016090000) n''est pas installee';
  END IF;
  IF pg_catalog.to_regprocedure('private.com_candidature_lisible(uuid,uuid)') IS NULL THEN
    RAISE EXCEPTION 'messagerie temps reel : installer d''abord 20261119400100_messages_candidat.sql';
  END IF;
  IF pg_catalog.to_regprocedure('private.com_est_mineur(uuid)') IS NULL THEN
    RAISE EXCEPTION 'messagerie temps reel : private.com_est_mineur est absente';
  END IF;
END
$preflight$;

-- 1. La table des signaux -----------------------------------------------------

CREATE TABLE IF NOT EXISTS public.com_signaux (
  -- Sans cle etrangere : un signal ne retient jamais un profil.
  destinataire uuid PRIMARY KEY,
  fil_id uuid NOT NULL,
  nature text NOT NULL CHECK (nature IN ('message', 'lecture')),
  rang bigint NOT NULL DEFAULT 1,
  change_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);

ALTER TABLE public.com_signaux ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.com_signaux FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.com_signaux TO authenticated;

DO $politique$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policy p
                  WHERE p.polrelid = 'public.com_signaux'::regclass
                    AND p.polname = 'com_signaux_destinataire_lecture') THEN
    -- Pas de app_account_valid() : un candidat (pending_kyc) doit recevoir le
    -- signal de SON fil. La ligne ne porte ni texte ni nom.
    CREATE POLICY com_signaux_destinataire_lecture ON public.com_signaux
      FOR SELECT TO authenticated
      USING (coalesce(destinataire = auth.uid(), false));
  END IF;
END
$politique$;

COMMENT ON TABLE public.com_signaux IS
  'MESSAGERIE-TEMPS-REEL : une ligne par personne, remplacee a chaque message '
  'recu ou lecture faite ; signal de relecture publie dans Realtime, sans texte. '
  'Ecrite par les declencheurs de com_messages et com_lectures seulement.';

-- 2 et 3. Les emetteurs -------------------------------------------------------

-- Pose (ou remplace) le signal de [p_qui].
CREATE OR REPLACE FUNCTION private.com_signal_poser(p_qui uuid, p_fil uuid, p_nature text)
RETURNS void
LANGUAGE sql VOLATILE SECURITY INVOKER SET search_path = '' AS $function$
  INSERT INTO public.com_signaux AS s (destinataire, fil_id, nature, rang, change_le)
  VALUES (p_qui, p_fil, p_nature, 1, pg_catalog.clock_timestamp())
  ON CONFLICT (destinataire) DO UPDATE
    SET fil_id = EXCLUDED.fil_id,
        nature = EXCLUDED.nature,
        rang = s.rang + 1,
        change_le = EXCLUDED.change_le;
$function$;

-- Les personnes a prevenir d'un nouveau message du fil [p_fil], hors [p_auteur].
CREATE OR REPLACE FUNCTION private.com_destinataires_signal(p_fil uuid, p_auteur uuid)
RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  WITH f AS (
    SELECT * FROM public.com_fils WHERE id = p_fil
  ), parties AS (
    SELECT f.partie_a_nature AS nature, f.partie_a_id AS pid, f.type_objet, f.objet_id FROM f
    UNION ALL
    SELECT f.partie_b_nature, f.partie_b_id, f.type_objet, f.objet_id FROM f
  ), qui AS (
    -- Un profil nomme.
    SELECT p.pid AS id FROM parties p WHERE p.nature = 'profil'
    UNION
    -- Les adultes du foyer, jamais un mineur.
    SELECT pr.id FROM parties p
      JOIN public.profiles pr ON pr.household_id = p.pid
     WHERE p.nature = 'foyer' AND pr.deleted_at IS NULL
       AND NOT private.com_est_mineur(pr.id)
    UNION
    -- L'equipe : la direction active ; pour une candidature, celle de son
    -- cote seulement (CAND-Q07).
    SELECT a.id FROM parties p
      JOIN public.profiles a ON a.role = 'admin' AND a.account_status = 'active'
                            AND a.deleted_at IS NULL
     WHERE p.nature = 'equipe'
       AND (p.type_objet <> 'candidature'
            OR private.com_candidature_lisible(p.objet_id, a.id))
  )
  SELECT q.id FROM qui q WHERE q.id IS NOT NULL AND q.id IS DISTINCT FROM p_auteur;
$function$;

CREATE OR REPLACE FUNCTION private.com_signaler_message()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_qui uuid;
BEGIN
  BEGIN
    FOR v_qui IN SELECT d FROM private.com_destinataires_signal(NEW.fil_id, NEW.auteur_id) AS d LOOP
      PERFORM private.com_signal_poser(v_qui, NEW.fil_id, 'message');
    END LOOP;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'messagerie temps reel : signal du message non pose (%)', SQLSTATE;
  END;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION private.com_signaler_lecture()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $function$
BEGIN
  BEGIN
    PERFORM private.com_signal_poser(NEW.profile_id, NEW.fil_id, 'lecture');
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'messagerie temps reel : signal de lecture non pose (%)', SQLSTATE;
  END;
  RETURN NULL;
END;
$function$;

REVOKE ALL ON FUNCTION private.com_signal_poser(uuid, uuid, text),
  private.com_destinataires_signal(uuid, uuid),
  private.com_signaler_message(), private.com_signaler_lecture()
  FROM PUBLIC, anon, authenticated, service_role;

DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON public.com_signaux FROM agent_ro';
    EXECUTE 'REVOKE ALL ON FUNCTION private.com_signal_poser(uuid, uuid, text), '
         || 'private.com_destinataires_signal(uuid, uuid), '
         || 'private.com_signaler_message(), private.com_signaler_lecture() FROM agent_ro';
  END IF;
END
$agent_ro$;

CREATE OR REPLACE TRIGGER com_messages_signal
  AFTER INSERT ON public.com_messages
  FOR EACH ROW EXECUTE FUNCTION private.com_signaler_message();

CREATE OR REPLACE TRIGGER com_lectures_signal
  AFTER INSERT OR UPDATE OF lu_jusqu_au ON public.com_lectures
  FOR EACH ROW EXECUTE FUNCTION private.com_signaler_lecture();

-- 4. Publication Realtime -----------------------------------------------------
-- Meme modele que 20261027100000 : rien sur un Postgres sans publication.
-- replica identity reste celle par defaut (cle primaire).

DO $realtime$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_publication p WHERE p.pubname = 'supabase_realtime')
     AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_publication_tables p
                      WHERE p.pubname = 'supabase_realtime'
                        AND p.schemaname = 'public' AND p.tablename = 'com_signaux') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.com_signaux;
  END IF;
END
$realtime$;

DO $postflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                  WHERE c.oid = 'public.com_signaux'::regclass AND c.relrowsecurity) THEN
    RAISE EXCEPTION 'messagerie temps reel : com_signaux sans RLS';
  END IF;
  IF pg_catalog.has_table_privilege('anon', 'public.com_signaux', 'select')
     OR pg_catalog.has_table_privilege('authenticated', 'public.com_signaux', 'insert')
     OR pg_catalog.has_table_privilege('authenticated', 'public.com_signaux', 'update')
     OR NOT pg_catalog.has_table_privilege('authenticated', 'public.com_signaux', 'select') THEN
    RAISE EXCEPTION 'messagerie temps reel : droits de com_signaux inattendus';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'private.com_signaler_message()', 'execute')
     OR pg_catalog.has_function_privilege('anon', 'private.com_signaler_message()', 'execute')
     OR pg_catalog.has_function_privilege('authenticated', 'private.com_signal_poser(uuid,uuid,text)', 'execute') THEN
    RAISE EXCEPTION 'messagerie temps reel : un emetteur est executable par un client';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_publication p WHERE p.pubname = 'supabase_realtime')
     AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_publication_tables p
                      WHERE p.pubname = 'supabase_realtime'
                        AND p.schemaname = 'public' AND p.tablename = 'com_signaux') THEN
    RAISE EXCEPTION 'messagerie temps reel : com_signaux absente de supabase_realtime';
  END IF;
END
$postflight$;
