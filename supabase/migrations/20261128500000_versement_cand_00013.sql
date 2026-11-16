-- VERSEMENT-QUESTIONS, correction de donnees pour CAND-00013 (directeur, 16/11/2026).
--
-- Decision du directeur, 16/11/2026 : « oui pour le paiement, corrige sa reponse et lance le lot »
-- (docs/current/DECISION-QUESTIONS-VERSEMENT-2026-11-16.md, cas CAND-00013). Message de la
-- candidate, messagerie, 16/11/2026 : « j'ai choisi l'Arabie saoudite comme pays de versement
-- parce que mon mari y est ». Elle a repondu « non » au compte bancaire, puis a pris le pays du
-- compte de son mari : son compte bancaire est celui d'un proche, donc la reponse est « oui ».
--
-- Effet, une seule fois : une NOUVELLE ligne de reponses (source candidat, envoyee), copie de la
-- derniere reponse envoyee, avec seulement compteBancaire = true (a la maniere de
-- modifier_mon_pays_versement : l'historique est garde, rien n'est reecrit) ; un evenement
-- `controle` qui cite la decision et le message ; puis le recalcul du paiement, comme
-- 20261128200100_be_versement_recalcul.sql (une candidature en paiement_non_disponible dont le
-- calcul devient compatible revient a a_completer par la transition 9).
--
-- Rejouable : si la derniere reponse envoyee dit deja compteBancaire = true, ou si la candidature
-- n'existe pas (base neuve, CI), il ne se passe rien. Ce fichier ne contient aucun mot
-- d'effacement ni de transaction.

DO $correction$
DECLARE
  v_id uuid := '4bf5377e-a3bb-4d97-9623-63b380fd9b22';
  v_c public.candidatures;
  v_doc public.candidature_reponses;
  v_ramene boolean;
  v_res jsonb;
BEGIN
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id FOR UPDATE;
  IF v_c.id IS NULL THEN
    RAISE NOTICE 'VERSEMENT-QUESTIONS : CAND-00013 absente de cette base, rien a corriger';
    RETURN;
  END IF;
  SELECT r.* INTO v_doc
    FROM public.candidature_reponses r
   WHERE r.candidature_id = v_id AND r.source = 'candidat' AND NOT r.brouillon
   ORDER BY r.soumis_le DESC, r.id DESC
   LIMIT 1;
  IF v_doc.id IS NULL THEN
    RAISE NOTICE 'VERSEMENT-QUESTIONS : CAND-00013 n''a aucune reponse envoyee, rien a corriger';
    RETURN;
  END IF;
  IF pg_catalog.jsonb_typeof(v_doc.reponses -> 'compteBancaire') = 'boolean'
     AND (v_doc.reponses ->> 'compteBancaire')::boolean THEN
    RAISE NOTICE 'VERSEMENT-QUESTIONS : CAND-00013 a deja repondu oui au compte bancaire, rien a corriger';
    RETURN;
  END IF;

  INSERT INTO public.candidature_reponses
    (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le)
  VALUES (v_id, v_doc.questionnaire_version,
          v_doc.reponses || pg_catalog.jsonb_build_object('compteBancaire', true),
          'candidat', false, pg_catalog.clock_timestamp());

  INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, motif_interne, details)
  VALUES (v_id, 'controle', NULL,
          'Réponse « compte bancaire » corrigée de non à oui : décision écrite du directeur du 16/11/2026 (DECISION-QUESTIONS-VERSEMENT-2026-11-16) et message de la candidate du 16/11/2026 (le pays de versement est celui du compte de son mari).',
          pg_catalog.jsonb_build_object(
            'controle', 'compte_bancaire_corrige',
            'decision', 'directeur, 16/11/2026',
            'compteBancaireAvant', v_doc.reponses -> 'compteBancaire',
            'compteBancaireApres', true,
            'paysVersement', v_doc.reponses ->> 'paysVersement',
            'auteur', 'systeme'));

  -- Le recalcul, comme le recalcul unique de BE-VERSEMENT : le dossier en attente de paiement
  -- revient a a_completer seulement si le nouveau calcul est compatible.
  v_ramene := v_c.etat = 'paiement_non_disponible' AND private.paiement_etat(v_id) = 'compatible';
  v_res := private.paiement_recalculer(v_id, 'referentiel', NULL, NULL, NULL, v_ramene);
  RAISE NOTICE 'VERSEMENT-QUESTIONS : CAND-00013 corrigee, paiement % -> %, effet %',
    v_res ->> 'paiementAvant', v_res ->> 'paiementApres', v_res ->> 'effet';
END;
$correction$;
