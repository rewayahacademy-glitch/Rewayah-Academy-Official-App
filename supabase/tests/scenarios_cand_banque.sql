-- CAND-BANQUE : referentiel de paiement, virement bancaire (directeur,
-- 06/11/2026). Migration 20261110320000_cand_banque_referentiel.sql.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations).
-- Chaque controle leve 'CAND-BANQUE ROUGE : ...' s'il echoue ; le scenario
-- annule tout a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'CAND-BANQUE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'CAND-BANQUE ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'P0001' AND SQLERRM LIKE 'CAND-BANQUE ROUGE%' THEN
      RAISE;
    END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'CAND-BANQUE ROUGE : % (code % au lieu de %)', p_label, SQLSTATE, p_code;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.ligne(p_pays text) RETURNS public.referentiel_paiement
LANGUAGE sql AS $$
  SELECT l FROM public.referentiel_paiement l
  WHERE l.pays = p_pays AND l.methode = 'virement_bancaire' AND l.operateur IS NULL;
$$;

-- 1. Les quatre lignes de la decision du 06/11.
SELECT pg_temp.vrai((pg_temp.ligne('YE')).etat = 'indisponible', 'YE indisponible');
SELECT pg_temp.vrai((pg_temp.ligne('YE')).source = 'decision_directeur'
  AND (pg_temp.ligne('YE')).source_ref = 'Wise 2978049, directeur 06/11/2026'
  AND (pg_temp.ligne('YE')).notes LIKE 'Décision du directeur du 06/11/2026%', 'YE : source, reference et note en clair');
SELECT pg_temp.vrai((pg_temp.ligne(p)).etat = 'confirme'
  AND (pg_temp.ligne(p)).source = 'decision_directeur'
  AND (pg_temp.ligne(p)).source_ref = 'Wise 2974947, directeur 06/11/2026'
  AND (pg_temp.ligne(p)).verifie_le = DATE '2026-11-06', p || ' confirme, verifie le 06/11')
FROM pg_catalog.unnest(ARRAY['NG', 'CI', 'SN']) AS p;

-- 2. L'Arabie saoudite inchangee (etat initial de DEC:28).
SELECT pg_temp.vrai((pg_temp.ligne('SA')).etat = 'confirme'
  AND (pg_temp.ligne('SA')).source_ref = 'DEC:28 (CAND-Q05, 21/10/2026)'
  AND (pg_temp.ligne('SA')).verifie_le = DATE '2026-10-21'
  AND (pg_temp.ligne('SA')).version = 1, 'SA inchangee');

-- 3. Les autres pays d'Afrique restent en verification ; aucune ligne effacee.
SELECT pg_temp.vrai(NOT EXISTS (
  SELECT 1 FROM public.referentiel_paiement l
  JOIN public.referentiel_paiement_afrique a ON a.pays = l.pays
  WHERE l.pays NOT IN ('NG', 'CI', 'SN') AND l.etat <> 'en_verification'),
  'les 57 autres pays d''Afrique restent en_verification');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.referentiel_paiement
                     WHERE methode = 'virement_bancaire') = 249, '249 lignes de virement, aucune effacee');

-- 4. Une seule version de plus par ligne changee, et le journal la garde.
SELECT pg_temp.vrai((pg_temp.ligne(p)).version = 2, p || ' : une seule ecriture (idempotence)')
FROM pg_catalog.unnest(ARRAY['YE', 'NG', 'CI', 'SN']) AS p;
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.referentiel_paiement_journal j
                     JOIN public.referentiel_paiement l ON l.id = j.ligne_id
                     WHERE l.pays IN ('YE', 'NG', 'CI', 'SN')
                       AND j.apres ->> 'source_ref' LIKE 'Wise %') = 4,
  'le journal garde les quatre changements');

-- 5. La decision Afrique datee du 06/11 ouvre la garde, et la cle la recopie.
SELECT pg_temp.vrai(private.paiement_afrique_ouverte(), 'decision Afrique ouverte');
SELECT pg_temp.vrai((SELECT d.decide_le FROM public.referentiel_paiement_afrique_decisions d
                     ORDER BY d.id DESC LIMIT 1) = DATE '2026-11-06', 'decision datee du 06/11/2026');
SELECT pg_temp.vrai((SELECT c.value FROM public.app_config c WHERE c.key = 'paiement.afrique_ouverte')
                    = 'true'::jsonb, 'app_config paiement.afrique_ouverte vaut true');

-- 6. Les gardes de la table tiennent toujours.
SELECT pg_temp.refus(
  $q$UPDATE public.referentiel_paiement SET verifie_le = NULL
     WHERE pays = 'NG' AND methode = 'virement_bancaire' AND operateur IS NULL$q$,
  '23514', 'confirme sans date de verification : refuse (CHECK)');
SELECT pg_temp.refus(
  $q$DELETE FROM public.referentiel_paiement
     WHERE pays = 'YE' AND methode = 'virement_bancaire' AND operateur IS NULL$q$,
  '55000', 'une ligne ne s''efface pas');

\o
SELECT 'CAND-BANQUE : scenario vert' AS resultat;
ROLLBACK;
