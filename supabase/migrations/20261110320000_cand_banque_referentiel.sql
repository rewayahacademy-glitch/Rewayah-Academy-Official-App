-- CAND-BANQUE : referentiel de paiement, virement bancaire (directeur, 06/11/2026).
--
-- Decision du directeur du 06/11/2026, relayee par le garde-cap :
-- * Yemen (YE) : le virement bancaire n'est pas possible (Wise, dossier
--   2978049) : la ligne passe indisponible ;
-- * Nigeria (NG), Cote d'Ivoire (CI), Senegal (SN) : le virement bancaire est
--   possible (Wise, dossier 2974947) : les lignes passent confirme ;
-- * Arabie saoudite (SA) : inchangee (aucun UPDATE ne la vise ; le preflight
--   et le postflight verifient qu'elle est confirme).
--
-- UPDATE seulement de public.referentiel_paiement, methode virement_bancaire,
-- plus une decision ajoutee (section 2) ; aucune ligne retiree. Idempotent :
-- une ligne deja a la valeur cible n'est pas reecrite (sa version ne bouge
-- pas), et la decision ne s'ajoute que si l'Afrique est encore fermee.
--
-- CHECK de la table respectes : referentiel_paiement_confirme_verifie (confirme
-- exige verifie_le, et source decision_directeur ou un responsable) ;
-- referentiel_paiement_decision_reference (decision_directeur exige
-- source_ref) ; notes de 1 a 2000 caracteres ; source_ref de 1 a 200.
--
-- Effets voulus, portes par les declencheurs de CAND-L6 (toute voie
-- d'ecriture) : chaque ligne changee est journalisee
-- (referentiel_paiement_journal, audit_logs) ; les candidatures en cours dont
-- le pays de versement est YE, NG, CI ou SN sont recalculees (transition 8 ou
-- 9, restriction automatique « paiement a reverifier » en salle 3 pour YE),
-- avec un evenement controle, auteur systeme.
--
-- Decision Afrique (garde-cap, 06/11/2026, sur les faits du directeur du
-- meme jour : « nos enseignants : Nigeria, Cote d'Ivoire, Senegal, les autres
-- en Arabie saoudite et au Yemen » ; « on laisse ceux du Yemen et partout ou
-- on ne peut pas envoyer » ; Wise choisi, USD par SWIFT, dossier 2974947) :
-- ces faits valent l'ouverture de CAND-Q05 pour NG, CI et SN. NG, CI et SN
-- sont dans la liste des pays d'Afrique (ONU M49) ; la garde de table
-- private.paiement_garde_afrique refuse toute ligne d'Afrique hors
-- en_verification tant que la derniere decision de
-- public.referentiel_paiement_afrique_decisions est « fermee » (DEC:80-83,
-- 21/10/2026). La section 2 enregistre donc une decision « ouverte » datee du
-- 06/11/2026. Les 57 autres pays d'Afrique restent en_verification (controle
-- par le postflight) ; la direction et la comptabilite pourront en confirmer
-- d'autres par la RPC enregistrer_ligne_referentiel_paiement, ce qui est leur
-- role. La cle app_config paiement.afrique_ouverte passe a true (recopie).

-- ============================================================
-- 1. Preflight : les lignes lues sont bien celles que l'on attend
-- ============================================================
DO $preflight$
DECLARE
  v_n integer;
BEGIN
  SELECT pg_catalog.count(*)::integer INTO v_n
  FROM public.referentiel_paiement l
  WHERE l.methode = 'virement_bancaire' AND l.operateur IS NULL
    AND l.pays IN ('YE', 'NG', 'CI', 'SN', 'SA');
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CAND-BANQUE : % lignes virement_bancaire sur YE, NG, CI, SN, SA (5 attendues)', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.referentiel_paiement l
                 WHERE l.pays = 'SA' AND l.methode = 'virement_bancaire' AND l.operateur IS NULL
                   AND l.etat = 'confirme') THEN
    RAISE EXCEPTION 'CAND-BANQUE : la ligne SA n''est pas confirme avant la migration';
  END IF;
  SELECT pg_catalog.count(*)::integer INTO v_n
  FROM public.referentiel_paiement_afrique a WHERE a.pays IN ('NG', 'CI', 'SN', 'YE', 'SA');
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CAND-BANQUE : NG, CI, SN attendus seuls en Afrique parmi les cinq pays (% trouves)', v_n;
  END IF;
END
$preflight$;

-- ============================================================
-- 2. Decision Afrique (voir l'en-tete)
-- ============================================================
INSERT INTO public.referentiel_paiement_afrique_decisions (ouverte, decision_ref, decide_le)
SELECT true,
       'Directeur 06/11/2026 : virement bancaire vers NG, CI, SN (Wise 2974947) ; autres pays d''Afrique en verification',
       DATE '2026-11-06'
WHERE NOT private.paiement_afrique_ouverte();

-- ============================================================
-- 3. Les quatre lignes
-- ============================================================
UPDATE public.referentiel_paiement l
SET etat = 'indisponible',
    source = 'decision_directeur',
    source_ref = 'Wise 2978049, directeur 06/11/2026',
    verifie_le = DATE '2026-11-06',
    notes = 'Décision du directeur du 06/11/2026 : Wise ne verse pas au Yémen (dossier 2978049). Un compte d''un proche dans un autre pays reste possible.'
WHERE l.pays = 'YE' AND l.methode = 'virement_bancaire' AND l.operateur IS NULL
  AND (l.etat, l.source, l.source_ref, l.verifie_le) IS DISTINCT FROM
      ('indisponible', 'decision_directeur', 'Wise 2978049, directeur 06/11/2026', DATE '2026-11-06');

UPDATE public.referentiel_paiement l
SET etat = 'confirme',
    source = 'decision_directeur',
    source_ref = 'Wise 2974947, directeur 06/11/2026',
    verifie_le = DATE '2026-11-06',
    notes = 'Décision du directeur du 06/11/2026 (Wise, dossier 2974947) : le virement bancaire vers ce pays est possible.'
WHERE l.pays IN ('NG', 'CI', 'SN') AND l.methode = 'virement_bancaire' AND l.operateur IS NULL
  AND (l.etat, l.source, l.source_ref, l.verifie_le) IS DISTINCT FROM
      ('confirme', 'decision_directeur', 'Wise 2974947, directeur 06/11/2026', DATE '2026-11-06');

-- ============================================================
-- 4. Postflight
-- ============================================================
DO $postflight$
DECLARE
  v_n integer;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.referentiel_paiement l
    WHERE l.pays = 'YE' AND l.methode = 'virement_bancaire' AND l.operateur IS NULL
      AND l.etat = 'indisponible' AND l.source = 'decision_directeur'
      AND l.source_ref = 'Wise 2978049, directeur 06/11/2026') THEN
    RAISE EXCEPTION 'CAND-BANQUE postflight : YE n''est pas indisponible';
  END IF;
  SELECT pg_catalog.count(*)::integer INTO v_n
  FROM public.referentiel_paiement l
  WHERE l.pays IN ('NG', 'CI', 'SN') AND l.methode = 'virement_bancaire' AND l.operateur IS NULL
    AND l.etat = 'confirme' AND l.source = 'decision_directeur'
    AND l.source_ref = 'Wise 2974947, directeur 06/11/2026' AND l.verifie_le = DATE '2026-11-06';
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CAND-BANQUE postflight : % lignes confirme sur NG, CI, SN (3 attendues)', v_n;
  END IF;
  -- SA n'est vise par aucun UPDATE (WHERE pays IN ('NG', 'CI', 'SN') et
  -- pays = 'YE') ; il reste confirme.
  IF NOT EXISTS (SELECT 1 FROM public.referentiel_paiement l
                 WHERE l.pays = 'SA' AND l.methode = 'virement_bancaire' AND l.operateur IS NULL
                   AND l.etat = 'confirme') THEN
    RAISE EXCEPTION 'CAND-BANQUE postflight : la ligne SA n''est plus confirme';
  END IF;
  SELECT pg_catalog.count(*)::integer INTO v_n
  FROM public.referentiel_paiement l
  JOIN public.referentiel_paiement_afrique a ON a.pays = l.pays
  WHERE l.etat <> 'en_verification' AND l.pays NOT IN ('NG', 'CI', 'SN');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CAND-BANQUE postflight : % lignes d''Afrique hors NG, CI, SN ont quitte en_verification', v_n;
  END IF;
END
$postflight$;
