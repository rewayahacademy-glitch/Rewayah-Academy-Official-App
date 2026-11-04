-- FN-114a, decision du directeur du 01/11/2026 (16:12 UTC), mot pour mot :
-- « OUI. je te l'avais deja demande. » Le defaut s'inverse : un evenement
-- absent de private.notification_courriel ne part plus que dans l'application.
-- Arbitrage du pilote et du garde-cap du meme jour (methode, regle 4) :
-- « urgent = un geste attendu dans l'heure d'une personne qui n'est
-- probablement pas dans l'application ».
--
-- Aucun mot de suppression (compte : 0). Un seul BEGIN; et un seul COMMIT;.
--
-- 1. private.notification_avec_courriel remplacee (CREATE OR REPLACE). Corps de
--    base : 20261103600000_seance_terminee_avis.sql, section 2, recopie
--    ci-dessous ; la seule difference est la valeur finale du coalesce, qui
--    passe de true a false.
--
--      SELECT coalesce(
--        (SELECT c.courriel FROM private.notification_courriel c
--          WHERE c.evenement = p_evenement AND c.portee = p_portee),
--        (SELECT c.courriel FROM private.notification_courriel c
--          WHERE c.evenement = p_evenement AND c.portee = '*'),
--        true);
--
-- 2. Lignes explicites qui GARDENT le courriel (liste blanche ajoutee) :
--      paiement_recu '*'               argent et trace (recu de la PR 116) ;
--      demande_presentation '*'        admission ;
--      remplacement_avertissement '*'  urgent (geste dans l'heure) ;
--      remplacement_pre_alerte '*'     urgent (geste dans l'heure) ;
--      controle_mission_attribuee '*'  urgent : donnee au debut de la seance,
--                                      echeance a sa fin (arbitrage du pilote,
--                                      16:17 UTC, meme regle) ;
--      classe_validee '*'              meme sort qu'avant pour la famille : le
--                                      chemin des demandes (0055, c11bis, 0078)
--                                      ecrit cet avis SANS portee ; sans cette
--                                      ligne, le nouveau defaut lui retirerait
--                                      le courriel que le §3 lui garde (soi,
--                                      foyer). Aucun autre chemin ne l'ecrit.
--
-- 3. Ce qui etait absent de la table et part desormais dans l'application
--    SEULEMENT (nouveau defaut), releve sur les 29 evenements de la contrainte :
--      remplacement_inutile             toutes portees ;
--      controle_mission_non_controlee   toutes portees ;
--      classe_supprimee                 toutes portees ;
--      eleve_retire                     soi, foyer, direction, sans portee ;
--      enseignant_affecte               soi, foyer, direction, sans portee ;
--      enseignant_change                soi, foyer, direction, sans portee ;
--      classe_creee                     classe, direction, sans portee ;
--      eleve_inscrit                    direction, sans portee.
--    Tout evenement cree apres ce fichier : application seulement, tant qu'une
--    ligne ne dit pas le contraire.
--
-- Rien ne change pour les lignes deja ecrites par 20261103600000.

BEGIN;

CREATE OR REPLACE FUNCTION private.notification_avec_courriel(p_evenement text, p_portee text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    (SELECT c.courriel FROM private.notification_courriel c
      WHERE c.evenement = p_evenement AND c.portee = p_portee),
    (SELECT c.courriel FROM private.notification_courriel c
      WHERE c.evenement = p_evenement AND c.portee = '*'),
    false);
$function$;

-- CREATE OR REPLACE garde les droits ; on les referme quand meme.
ALTER FUNCTION private.notification_avec_courriel(text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.notification_avec_courriel(text, text) FROM PUBLIC;
DO $droits$
DECLARE
  v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format(
        'REVOKE ALL ON FUNCTION private.notification_avec_courriel(text, text) FROM %I', v_role);
    END IF;
  END LOOP;
END;
$droits$;

COMMENT ON TABLE private.notification_courriel IS
  'DECISION-NOTIFICATIONS-COURRIEL (01/11/2026, amendee 16:12 UTC) : un courriel part en plus de la notification seulement si la ligne le dit ; portee « * » = toutes ; evenement absent = application seulement. Lue par public.courriel_depuis_notification.';

INSERT INTO private.notification_courriel (evenement, portee, courriel) VALUES
  ('paiement_recu', '*', true),
  ('demande_presentation', '*', true),
  ('remplacement_avertissement', '*', true),
  ('remplacement_pre_alerte', '*', true),
  ('classe_validee', '*', true),
  ('controle_mission_attribuee', '*', true)
ON CONFLICT (evenement, portee) DO UPDATE SET courriel = excluded.courriel;

-- Controles.
DO $postflight$
BEGIN
  IF has_function_privilege('authenticated', 'private.notification_avec_courriel(text,text)', 'EXECUTE')
     OR has_function_privilege('anon', 'private.notification_avec_courriel(text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FN-114a : notification_avec_courriel ouverte au client';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.notification_courriel) <> 31 THEN
    RAISE EXCEPTION 'FN-114a : la table devrait compter 31 lignes (25 + 6)';
  END IF;
  -- La liste blanche ajoutee par ce fichier, exactement.
  IF (SELECT pg_catalog.count(*) FROM private.notification_courriel c
       WHERE c.portee = '*' AND c.courriel
         AND c.evenement IN ('paiement_recu', 'demande_presentation', 'remplacement_avertissement',
                             'remplacement_pre_alerte', 'classe_validee',
                             'controle_mission_attribuee')) <> 6 THEN
    RAISE EXCEPTION 'FN-114a : la liste blanche ajoutee ne compte pas ses 6 lignes';
  END IF;
  IF NOT private.notification_avec_courriel('seance_annulee', 'soi')
     OR NOT private.notification_avec_courriel('paiement_recu', NULL)
     OR NOT private.notification_avec_courriel('demande_presentation', NULL)
     OR NOT private.notification_avec_courriel('remplacement_avertissement', NULL)
     OR NOT private.notification_avec_courriel('remplacement_pre_alerte', NULL)
     OR NOT private.notification_avec_courriel('classe_creee', 'foyer')
     OR NOT private.notification_avec_courriel('classe_validee', NULL)
     OR private.notification_avec_courriel('classe_creee', 'classe')
     OR private.notification_avec_courriel('enseignant_affecte', NULL)
     OR private.notification_avec_courriel('seance_terminee', 'foyer')
     OR private.notification_avec_courriel('classe_supprimee', 'soi')
     OR private.notification_avec_courriel('remplacement_inutile', NULL)
     OR NOT private.notification_avec_courriel('controle_mission_attribuee', NULL)
     OR private.notification_avec_courriel('controle_mission_non_controlee', NULL)
     OR private.notification_avec_courriel('eleve_retire', 'foyer')
     OR private.notification_avec_courriel('enseignant_affecte', 'soi')
     OR private.notification_avec_courriel('evenement_inconnu', NULL) THEN
    RAISE EXCEPTION 'FN-114a : le drapeau courriel ne suit pas la decision de 16:12';
  END IF;
END;
$postflight$;

COMMIT;
