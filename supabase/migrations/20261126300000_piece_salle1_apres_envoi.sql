-- RECRUTEMENT-SANS-SORTIE, point 3 (directeur, 14/11/2026) : « un candidat
-- veut deposer sa piece d'identite mais ne trouve plus de page ».
--
-- Constat en production (lecture seule, 14/11/2026, candidatures enseignant) :
--   prequalification / a_completer             24, dont 22 sans piece : depot accepte
--   prequalification / en_examen               27, dont 22 sans piece : depot REFUSE
--   prequalification / paiement_non_disponible  8, dont  5 sans piece : depot REFUSE
--   verifications (salle 2)                     0
-- La piece est demandee en salle 1 (SALLE-1-TOUT-ICI, 20261119100000 :
-- « ils font tout ici »), mais l'envoi de la candidature ne l'exige pas. Une
-- fois la candidature envoyee, `private.candidature_accepte_depot_piece`
-- refusait le depot jusqu'a l'admission en salle 2 : 27 personnes encore en
-- salle 1, a qui la piece a ete demandee en salle 1, ne pouvaient plus la
-- donner. Le refus est a tort : la demande reste a sa place (salle 1), elle
-- n'est ni deplacee ni ajoutee ; seule la porte reste ouverte tant que la
-- personne est en salle 1, candidature en cours.
--
-- Changement : la branche « salle 1 » de la regle accepte toute candidature
-- enseignant en prequalification EN COURS (a completer, en examen, versement
-- pas encore possible), au lieu de « a completer » seulement. Rien d'autre :
--   - la regle CAND-L1B (`candidature_permet_depot_piece`, salle 2 en cours ou
--     salle 3) ne change pas, ni la file d'ADM-02 qui la lit ;
--   - refusee ou retiree : toujours refuse ; autres sortes de candidatures
--     (familles) : non touchees ;
--   - les deux portes du depot (declencheur `kyc_depot_etape_trg`, porte R2
--     `peut_deposer_piece_identite`) appellent deja cette regle : elles
--     suivent sans etre reecrites.
-- Une piece deposee ainsi entre dans « Dossiers a valider » comme une piece
-- de salle 1 (INCIDENT-CANDIDATS) et se lit sur la fiche (`piece_candidature`).
--
-- Preflight : empreinte md5(prosrc) de la regle, relue en production le
-- 14/11/2026 : 1cfb2056e7efd50f2d0728efe13304cd. Rejouable : deja applique,
-- rien n'est refait.
--
-- Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement.

DO $preflight$
DECLARE
  v_m text;
BEGIN
  SELECT pg_catalog.md5(p.prosrc) INTO v_m
    FROM pg_catalog.pg_proc p
   WHERE p.oid = 'private.candidature_accepte_depot_piece(uuid)'::pg_catalog.regprocedure;
  IF pg_catalog.strpos(
       pg_catalog.pg_get_functiondef(
         'private.candidature_accepte_depot_piece(uuid)'::pg_catalog.regprocedure),
       'RECRUTEMENT-SANS-SORTIE') > 0 THEN
    RAISE NOTICE 'PIECE-SALLE1-APRES-ENVOI : deja applique';
  ELSIF v_m IS DISTINCT FROM '1cfb2056e7efd50f2d0728efe13304cd' THEN
    RAISE EXCEPTION 'PIECE-SALLE1-APRES-ENVOI : la regle a change (md5 %), migration a revoir', v_m;
  END IF;
END;
$preflight$;

CREATE OR REPLACE FUNCTION private.candidature_accepte_depot_piece(p_profile_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  SELECT private.candidature_permet_depot_piece(p_profile_id)
      OR coalesce(
           -- SALLE-1 (07/11/2026), elargi par RECRUTEMENT-SANS-SORTIE
           -- (14/11/2026) : la candidature enseignant de ce compte est en
           -- salle 1, en cours, quel que soit son etat (a completer, en
           -- examen, versement pas encore possible) ; et aucune autre
           -- candidature de ce compte n'est hors des etapes permises.
           EXISTS (SELECT 1 FROM public.candidatures c
                    WHERE c.profile_id = p_profile_id
                      AND c.type_code = 'enseignant'
                      AND c.etape = 'prequalification'
                      AND c.issue = 'en_cours')
           AND NOT EXISTS (SELECT 1 FROM public.candidatures c
                            WHERE c.profile_id = p_profile_id
                              AND NOT (c.etape = 'confirmee'
                                       OR (c.etape = 'verifications' AND c.issue = 'en_cours')
                                       OR (c.type_code = 'enseignant'
                                           AND c.etape = 'prequalification'
                                           AND c.issue = 'en_cours'))),
           false);
$function$;

REVOKE ALL ON FUNCTION private.candidature_accepte_depot_piece(uuid) FROM PUBLIC, anon;
