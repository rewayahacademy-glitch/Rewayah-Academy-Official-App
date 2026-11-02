-- NOTIFS-L6 (pilote, 02/11/2026 ; demande du directeur du 02/11) : la section
-- « A faire » de la page Notifications. Une notification qui demande un geste
-- y reste, lue ou non, jusqu'a ce que le geste soit fait ou que la personne
-- l'ecarte ; jamais effacee par la seule ouverture de la page.
--
-- Contenu, approuve par le pilote le 02/11 :
--   1. trois colonnes : geste_requis, ecartee_le, geste_fait_le ;
--   2. geste_requis pose a l'insertion selon l'evenement, en un seul endroit ;
--   3. « Ecarter » : le destinataire pose ecartee_le (heure du serveur, sans
--      retour) ;
--   4. « geste fait », pose seulement la ou le serveur le sait deja :
--      - paiement_recu ou acces_retabli_paiement clot les relances et la
--        suspension du meme destinataire ;
--      - remplacement_pris ou remplacement_inutile clot les propositions et
--        pre-alertes de la meme seance (params.session_id) ;
--      - litige_clos (portee direction) clot le litige_ouvert de la meme
--        commande (params.commande_id) pour le meme destinataire ;
--   5. rattrapage des lignes existantes (UPDATE seulement) ;
-- Aucune ligne n'est effacee ; aucune contrainte ni colonne n'est retiree.
BEGIN;

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS geste_requis boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS ecartee_le timestamptz,
  ADD COLUMN IF NOT EXISTS geste_fait_le timestamptz;

-- La tete de la page : « A faire » ouvertes, et les non lues.
CREATE INDEX IF NOT EXISTS notifications_a_faire_idx
  ON public.notifications (destinataire, cree_le DESC)
  WHERE geste_requis AND ecartee_le IS NULL AND geste_fait_le IS NULL;
CREATE INDEX IF NOT EXISTS notifications_non_lues_idx
  ON public.notifications (destinataire, cree_le DESC)
  WHERE lu_le IS NULL;

-- ---------------------------------------------------------------------------
-- 1. Quels evenements demandent un geste (Q1 du pilote, 02/11).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.notification_geste_requis(p_evenement text, p_params jsonb)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT p_evenement IN (
           'paiement_relance',
           'acces_suspendu_paiement',
           'remplacement_propose',
           'remplacement_pre_alerte',
           'demande_presentation',
           'controle_mission_attribuee')
      -- La famille est seulement informee d'une contestation ; la direction
      -- doit la traiter.
      OR (p_evenement = 'litige_ouvert'
          AND coalesce(p_params ->> 'portee', '') = 'direction');
$function$;
ALTER FUNCTION private.notification_geste_requis(text, jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.notification_geste_requis(text, jsonb)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- SECURITY DEFINER (relecture du pilote, PR 137) : la fonction appelle
-- private.notification_geste_requis, fermee a tous ; en INVOKER, toute
-- insertion par un autre role que postgres (service_role d'une fonction Edge,
-- fonction INVOKER) echouerait faute d'EXECUTE.
CREATE OR REPLACE FUNCTION private.notifications_poser_geste()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  -- Toujours decide par le serveur, jamais par l'auteur de l'insertion.
  NEW.geste_requis := private.notification_geste_requis(NEW.evenement, NEW.params);
  NEW.ecartee_le := NULL;
  NEW.geste_fait_le := NULL;
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.notifications_poser_geste() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.notifications_poser_geste()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER notifications_geste_requis
  BEFORE INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION private.notifications_poser_geste();

-- ---------------------------------------------------------------------------
-- 2. « Geste fait », la ou le serveur le sait deja.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.notifications_clore_gestes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.evenement IN ('paiement_recu', 'acces_retabli_paiement') THEN
    UPDATE public.notifications n
       SET geste_fait_le = pg_catalog.now()
     WHERE n.destinataire = NEW.destinataire
       AND n.evenement IN ('paiement_relance', 'acces_suspendu_paiement')
       AND n.geste_requis
       AND n.geste_fait_le IS NULL
       AND n.id <> NEW.id;
  ELSIF NEW.evenement IN ('remplacement_pris', 'remplacement_inutile')
        AND NEW.params ? 'session_id' THEN
    -- Toutes les propositions de la seance, quel que soit leur destinataire :
    -- le remplacant lui-meme ne recoit pas remplacement_pris.
    UPDATE public.notifications n
       SET geste_fait_le = pg_catalog.now()
     WHERE n.evenement IN ('remplacement_propose', 'remplacement_pre_alerte')
       AND n.params ->> 'session_id' = NEW.params ->> 'session_id'
       AND n.geste_requis
       AND n.geste_fait_le IS NULL;
  ELSIF NEW.evenement = 'litige_clos'
        AND coalesce(NEW.params ->> 'portee', '') = 'direction'
        AND NEW.params ? 'commande_id' THEN
    UPDATE public.notifications n
       SET geste_fait_le = pg_catalog.now()
     WHERE n.destinataire = NEW.destinataire
       AND n.evenement = 'litige_ouvert'
       AND coalesce(n.params ->> 'portee', '') = 'direction'
       AND n.params ->> 'commande_id' = NEW.params ->> 'commande_id'
       AND n.geste_requis
       AND n.geste_fait_le IS NULL;
  END IF;
  RETURN NULL;
END;
$function$;
ALTER FUNCTION private.notifications_clore_gestes() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.notifications_clore_gestes()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER notifications_clore_gestes
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION private.notifications_clore_gestes();

-- ---------------------------------------------------------------------------
-- 3. « Ecarter » : le destinataire seul (politique de mise a jour de 0063),
--    a l'heure du serveur, une seule fois.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.notifications_ecart_serveur()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  NEW.ecartee_le := coalesce(OLD.ecartee_le, pg_catalog.now());
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.notifications_ecart_serveur() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.notifications_ecart_serveur()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER notifications_ecart_serveur
  BEFORE UPDATE OF ecartee_le ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION private.notifications_ecart_serveur();

GRANT UPDATE (ecartee_le) ON public.notifications TO authenticated;

-- ---------------------------------------------------------------------------
-- 4. Rattrapage des lignes existantes (UPDATE seulement).
-- ---------------------------------------------------------------------------
UPDATE public.notifications
   SET geste_requis = true
 WHERE NOT geste_requis
   AND private.notification_geste_requis(evenement, params);

-- Un geste deja fait avant la migration ne reste pas « A faire » : une
-- relance suivie d'un paiement recu pour le meme destinataire.
UPDATE public.notifications n
   SET geste_fait_le = pg_catalog.now()
 WHERE n.geste_requis
   AND n.geste_fait_le IS NULL
   AND n.evenement IN ('paiement_relance', 'acces_suspendu_paiement')
   AND EXISTS (SELECT 1 FROM public.notifications p
                WHERE p.destinataire = n.destinataire
                  AND p.evenement IN ('paiement_recu', 'acces_retabli_paiement')
                  AND p.cree_le >= n.cree_le);
UPDATE public.notifications n
   SET geste_fait_le = pg_catalog.now()
 WHERE n.geste_requis
   AND n.geste_fait_le IS NULL
   AND n.evenement IN ('remplacement_propose', 'remplacement_pre_alerte')
   AND EXISTS (SELECT 1 FROM public.notifications p
                WHERE p.evenement IN ('remplacement_pris', 'remplacement_inutile')
                  AND p.params ->> 'session_id' = n.params ->> 'session_id');
UPDATE public.notifications n
   SET geste_fait_le = pg_catalog.now()
 WHERE n.geste_requis
   AND n.geste_fait_le IS NULL
   AND n.evenement = 'litige_ouvert'
   AND EXISTS (SELECT 1 FROM public.notifications p
                WHERE p.destinataire = n.destinataire
                  AND p.evenement = 'litige_clos'
                  AND p.params ->> 'commande_id' = n.params ->> 'commande_id');

-- ---------------------------------------------------------------------------
-- 5. Garde : la migration est en place.
-- ---------------------------------------------------------------------------
DO $garde$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger
                  WHERE tgrelid = 'public.notifications'::regclass
                    AND tgname = 'notifications_geste_requis')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger
                     WHERE tgrelid = 'public.notifications'::regclass
                       AND tgname = 'notifications_clore_gestes')
     OR NOT pg_catalog.has_column_privilege('authenticated', 'public.notifications',
                                            'ecartee_le', 'UPDATE')
     OR pg_catalog.has_column_privilege('authenticated', 'public.notifications',
                                        'geste_requis', 'UPDATE')
     OR pg_catalog.has_column_privilege('authenticated', 'public.notifications',
                                        'geste_fait_le', 'UPDATE') THEN
    RAISE EXCEPTION 'NOTIFS-L6 : migration incomplete';
  END IF;
END
$garde$;

COMMIT;
