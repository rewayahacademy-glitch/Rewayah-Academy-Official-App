-- PAYS-DECISIONS (directeur, 16/11/2026) : decision par pays du referentiel de paiement, virement
-- bancaire, sur les pages publiques de wise.com lues le 16/11/2026 (guides EGP, MAD, GHS, KES ;
-- « where can I use Wise »). Ordre du directeur : « tu peux tout faire sans autorisation pour le
-- moment ».
--
-- * confirme (virement bancaire) : EG, MA, GH, KE ;
-- * indisponible : BJ, BF, ML, NE (le franc CFA XOF ne s'envoie pas encore par Wise) et SD, TD (Wise ne
--   dessert pas ces pays) ;
-- * inchange, en verification : DZ, GN, LR.
-- Mobile money : AUCUNE ligne n'est ecrite. Les operateurs de la table
-- referentiel_paiement_operateurs sont moov_money, orange_money et wave : MTN, AirtelTigo, Telecel et
-- M-Pesa n'y sont pas, et aucune ligne mobile_money n'existe pour GH ni KE. Les ajouter est un autre
-- geste (nouveaux operateurs, nouvelles lignes), a decider.
--
-- Meme voie que CAND-BANQUE (20261110320000, decision du 06/11) : UPDATE de public.referentiel_paiement,
-- methode virement_bancaire, aucune ligne retiree, idempotent (une ligne deja a la valeur cible n'est pas
-- reecrite : sa version ne bouge pas). L'Afrique est deja ouverte par la decision du 06/11 : la garde de
-- table (private.paiement_garde_afrique) laisse passer ces lignes. Aucune decision Afrique n'est ajoutee.
--
-- Effets voulus, portes par le declencheur referentiel_paiement_effets (toute voie d'ecriture) : chaque
-- ligne changee est journalisee (referentiel_paiement_journal, audit_logs) ; les candidatures en cours
-- dont le pays de versement est l'un de ces quatre pays confirmes sont recalculees ; celles qui attendaient
-- le paiement reviennent a a_completer (transition 9, L6-9 : la carte « versement » est a refaire) avec
-- l'avis « paiement possible », MEME SI leur propre moyen ne croise pas la ligne (par exemple sans compte
-- bancaire) : c'est la conception de CAND-L6 (scenarios_cand_l6, L6-9), pas un effet de ce fichier. Pour les
-- pays devenus indisponibles, le declencheur ne recalcule rien (il ne traite que les lignes qui deviennent
-- ou quittent confirme). Aucun recalcul de masse supplementaire.
--
-- CHECK de la table respectes : confirme exige verifie_le et source decision_directeur ; decision_directeur
-- exige source_ref ; notes de 1 a 2000 caracteres ; source_ref de 1 a 200. Ce fichier ne contient aucun mot
-- d'effacement ni de transaction.

-- ============================================================
-- 1. Preflight : les lignes lues sont bien celles que l'on attend
-- ============================================================
DO $preflight$
DECLARE
  v_n integer;
  v_hors text;
BEGIN SELECT pg_catalog.count(*)::integer INTO v_n
    FROM public.referentiel_paiement l
   WHERE l.methode = 'virement_bancaire' AND l.operateur IS NULL
     AND l.pays IN ('EG', 'MA', 'GH', 'KE', 'BJ', 'BF', 'ML', 'NE', 'SD', 'TD', 'DZ', 'GN', 'LR');
  IF v_n <> 13 THEN
    RAISE EXCEPTION 'PAYS-DECISIONS : % lignes virement_bancaire sur les 13 pays (13 attendues)', v_n;
  END IF;
  -- Chaque ligne est en verification, ou deja a la valeur cible (rejeu) ; DZ, GN, LR le restent.
  SELECT pg_catalog.string_agg(l.pays || '=' || l.etat, ', ' ORDER BY l.pays) INTO v_hors
    FROM public.referentiel_paiement l
   WHERE l.methode = 'virement_bancaire' AND l.operateur IS NULL
     AND ((l.pays IN ('DZ', 'GN', 'LR') AND l.etat <> 'en_verification')
          OR (l.pays IN ('EG', 'MA', 'GH', 'KE') AND l.etat NOT IN ('en_verification', 'confirme'))
          OR (l.pays IN ('BJ', 'BF', 'ML', 'NE', 'SD', 'TD') AND l.etat NOT IN ('en_verification', 'indisponible')));
  IF v_hors IS NOT NULL THEN
    RAISE EXCEPTION 'PAYS-DECISIONS : etat inattendu avant la decision (%)', v_hors;
  END IF;
  IF NOT private.paiement_afrique_ouverte() THEN
    RAISE EXCEPTION 'PAYS-DECISIONS : l''Afrique n''est pas ouverte (decision du 06/11 absente)';
  END IF;
END
$preflight$;

-- ============================================================
-- 2. Les dix lignes
-- ============================================================
UPDATE public.referentiel_paiement l
SET etat = 'confirme',
    source = 'decision_directeur',
    source_ref = 'Wise (wise.com, pages publiques lues le 16/11/2026), directeur 16/11/2026',
    verifie_le = DATE '2026-11-16',
    notes = 'Décision du directeur du 16/11/2026 : le virement bancaire vers ce pays est possible (pages publiques de wise.com lues le 16/11/2026 : guide de la devise du pays et « where can I use Wise »).'
WHERE l.pays IN ('EG', 'MA', 'GH', 'KE') AND l.methode = 'virement_bancaire' AND l.operateur IS NULL
  AND (l.etat, l.source, l.source_ref, l.verifie_le) IS DISTINCT FROM
      ('confirme', 'decision_directeur', 'Wise (wise.com, pages publiques lues le 16/11/2026), directeur 16/11/2026', DATE '2026-11-16');

UPDATE public.referentiel_paiement l
SET etat = 'indisponible',
    source = 'decision_directeur',
    source_ref = 'Wise (wise.com, pages publiques lues le 16/11/2026), directeur 16/11/2026',
    verifie_le = DATE '2026-11-16',
    notes = 'Décision du directeur du 16/11/2026 : le franc CFA (XOF) ne s''envoie pas encore par Wise (pages publiques de wise.com lues le 16/11/2026). Un compte d''un proche dans un autre pays reste possible.'
WHERE l.pays IN ('BJ', 'BF', 'ML', 'NE') AND l.methode = 'virement_bancaire' AND l.operateur IS NULL
  AND (l.etat, l.source, l.source_ref, l.verifie_le) IS DISTINCT FROM
      ('indisponible', 'decision_directeur', 'Wise (wise.com, pages publiques lues le 16/11/2026), directeur 16/11/2026', DATE '2026-11-16');

UPDATE public.referentiel_paiement l
SET etat = 'indisponible',
    source = 'decision_directeur',
    source_ref = 'Wise (wise.com, pages publiques lues le 16/11/2026), directeur 16/11/2026',
    verifie_le = DATE '2026-11-16',
    notes = 'Décision du directeur du 16/11/2026 : Wise ne dessert pas ce pays (« where can I use Wise », pages publiques de wise.com lues le 16/11/2026). Un compte d''un proche dans un autre pays reste possible.'
WHERE l.pays IN ('SD', 'TD') AND l.methode = 'virement_bancaire' AND l.operateur IS NULL
  AND (l.etat, l.source, l.source_ref, l.verifie_le) IS DISTINCT FROM
      ('indisponible', 'decision_directeur', 'Wise (wise.com, pages publiques lues le 16/11/2026), directeur 16/11/2026', DATE '2026-11-16');

-- ============================================================
-- 3. Postflight
-- ============================================================
DO $postflight$
DECLARE
  v_n integer;
BEGIN SELECT pg_catalog.count(*)::integer INTO v_n
    FROM public.referentiel_paiement l
   WHERE l.methode = 'virement_bancaire' AND l.operateur IS NULL
     AND l.source = 'decision_directeur' AND l.verifie_le = DATE '2026-11-16'
     AND l.source_ref = 'Wise (wise.com, pages publiques lues le 16/11/2026), directeur 16/11/2026'
     AND ((l.pays IN ('EG', 'MA', 'GH', 'KE') AND l.etat = 'confirme')
          OR (l.pays IN ('BJ', 'BF', 'ML', 'NE', 'SD', 'TD') AND l.etat = 'indisponible'));
  IF v_n <> 10 THEN
    RAISE EXCEPTION 'PAYS-DECISIONS postflight : % lignes a la valeur cible (10 attendues)', v_n;
  END IF;
  IF EXISTS (SELECT 1 FROM public.referentiel_paiement l
              WHERE l.pays IN ('DZ', 'GN', 'LR') AND l.etat <> 'en_verification') THEN
    RAISE EXCEPTION 'PAYS-DECISIONS postflight : DZ, GN et LR devaient rester en verification';
  END IF;
END
$postflight$;
