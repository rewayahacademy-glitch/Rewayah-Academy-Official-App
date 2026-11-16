-- PAYS-DECISIONS (directeur, 16/11/2026) : migration 20261128600100_pays_decisions_wise.sql, rejouee ici
-- (commande psql d'inclusion, chemin relatif a la racine du depot) sur des donnees inventees.
--
-- La base neuve a deja joue les migrations (aucune candidature alors) : le scenario remet d'abord les 13 lignes
-- en verification, pose des candidatures, rejoue le fichier, puis verifie.
-- Cas couverts : (a) les dix lignes passent a la valeur voulue (confirme : EG, MA, GH, KE ; indisponible :
-- BJ, BF, ML, NE, SD, TD), DZ, GN et LR restent en verification ; (b) un journal par ligne changee, auteur
-- nul (voie directe) ; (c) une candidature en attente de paiement dont le virement devient possible revient
-- a a_completer avec l'avis paiement_possible (transition 9) ; sans compte bancaire elle revient aussi
-- (conception de CAND-L6, L6-9 : la carte versement est a refaire), son paiement reste incompatible ; un
-- dossier en examen devient compatible sans transition ; (d) un pays devenu indisponible : aucun recalcul (le declencheur ne
-- traite que les lignes qui deviennent ou quittent confirme), les dossiers ne bougent pas ; DZ, GN, LR, SA
-- inchanges ; (e) rejouer ne change rien (versions, journal, evenements) ; (f) aucune ligne mobile_money
-- n'est ecrite.
-- Chaque controle leve 'PAYS-DEC ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE, depuis la racine du
-- depot ; le scenario annule tout a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'PAYS-DEC ROUGE : %', p_label; END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.id(p text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('pays-decisions-' || p)::uuid $$;
CREATE FUNCTION pg_temp.vue(p_k text) RETURNS text LANGUAGE sql AS $$
  SELECT private.paiement_etat(c.id) || '/' || c.paiement || '/' || coalesce(c.etat, '-')
    FROM public.candidatures c WHERE c.id = pg_temp.id('c-' || p_k) $$;
CREATE FUNCTION pg_temp.etat_ligne(p_pays text) RETURNS text LANGUAGE sql AS $$
  SELECT l.etat FROM public.referentiel_paiement l
   WHERE l.pays = p_pays AND l.methode = 'virement_bancaire' AND l.operateur IS NULL $$;
CREATE FUNCTION pg_temp.version(p_k text) RETURNS integer LANGUAGE sql AS $$
  SELECT version FROM public.candidatures WHERE id = pg_temp.id('c-' || p_k) $$;

-- Les 13 lignes en verification (point de depart de la production).
UPDATE public.referentiel_paiement
   SET etat = 'en_verification', verifie_le = NULL, source = 'decision_directeur', source_ref = 'DEC:28 (CAND-Q05, 21/10/2026)'
 WHERE methode = 'virement_bancaire' AND operateur IS NULL
   AND pays IN ('EG', 'MA', 'GH', 'KE', 'BJ', 'BF', 'ML', 'NE', 'SD', 'TD', 'DZ', 'GN', 'LR');

-- Des candidats (inventes).
INSERT INTO auth.users (id, email)
SELECT pg_temp.id('u-' || k), 'pays-dec-' || k || '@test.invalid' FROM unnest(ARRAY['1','2','3','4','5','6','7','8']) AS k;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.id('u-' || k), 'PDW-ENS-000' || k, 'teacher', 'Essai' || k, 'Fictif', 'pending_kyc', 'male'
FROM unnest(ARRAY['1','2','3','4','5','6','7','8']) AS k;
-- 1 EG avec compte, en attente ; 2 EG sans compte, en attente ; 3 GH avec compte, en attente ;
-- 4 BJ avec compte, en attente ; 5 DZ avec compte, en attente ; 6 KE avec compte, en examen ;
-- 7 BJ avec compte, en examen ; 8 SA avec compte, en examen.
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.id('c-' || v.k), 'enseignant', pg_temp.id('u-' || v.k), 'male', 'Fixture ' || v.k,
       'prequalification', v.etat, 'en_cours', 'lien_public'
FROM (VALUES ('1','paiement_non_disponible'),('2','paiement_non_disponible'),('3','paiement_non_disponible'),
             ('4','paiement_non_disponible'),('5','paiement_non_disponible'),('6','en_examen'),
             ('7','en_examen'),('8','en_examen')) AS v(k, etat);
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, soumis_le)
SELECT pg_temp.id('c-' || v.k), 'salle-examen-2',
       pg_catalog.jsonb_build_object('paysVersement', v.p, 'compteBancaire', v.c), 'candidat', false, now() - interval '1 day'
FROM (VALUES ('1','EG',true),('2','EG',false),('3','GH',true),('4','BJ',true),('5','DZ',true),
             ('6','KE',true),('7','BJ',true),('8','SA',true)) AS v(k, p, c);
-- Aucun des huit n'a de moyen croisant une ligne confirmee, sauf SA (virement confirme).
SELECT private.paiement_recalculer(pg_temp.id('c-' || k), 'reponses') FROM unnest(ARRAY['1','2','3','4','5','6','7','8']) AS k;

-- 6 et 7 sont en examen avec un paiement encore a verifier (le recalcul initial les a mis en attente) :
-- on les remet en examen, la colonne paiement dit incompatible.
UPDATE public.candidatures SET etat = 'en_examen' WHERE id IN (pg_temp.id('c-6'), pg_temp.id('c-7'));
SELECT pg_temp.vrai(pg_temp.vue('1') = 'incompatible/incompatible/paiement_non_disponible'
  AND pg_temp.vue('6') = 'incompatible/incompatible/en_examen' AND pg_temp.vue('7') = 'incompatible/incompatible/en_examen'
  AND pg_temp.vue('8') LIKE 'compatible/compatible/%',
  'a0 : points de depart : EG, GH, BJ, DZ incompatibles en attente ; KE et BJ en examen incompatibles ; SA compatible');
SELECT set_config('test.v7', pg_temp.version('7')::text, true);
SELECT set_config('test.v4', pg_temp.version('4')::text, true);
SELECT set_config('test.v5', pg_temp.version('5')::text, true);
SELECT set_config('test.v2', pg_temp.version('2')::text, true);

SELECT set_config('test.journal0', (SELECT coalesce(max(id), 0)::text FROM public.referentiel_paiement_journal), true);
\i supabase/migrations/20261128600100_pays_decisions_wise.sql

SELECT pg_temp.vrai(
  (SELECT bool_and(pg_temp.etat_ligne(p) = 'confirme') FROM unnest(ARRAY['EG','MA','GH','KE']) AS p)
  AND (SELECT bool_and(pg_temp.etat_ligne(p) = 'indisponible') FROM unnest(ARRAY['BJ','BF','ML','NE','SD','TD']) AS p)
  AND (SELECT bool_and(pg_temp.etat_ligne(p) = 'en_verification') FROM unnest(ARRAY['DZ','GN','LR']) AS p),
  'a1 : EG, MA, GH, KE confirmes ; BJ, BF, ML, NE, SD, TD indisponibles ; DZ, GN, LR en verification');
SELECT pg_temp.vrai((SELECT count(*) FROM public.referentiel_paiement l
    WHERE l.source_ref LIKE 'Wise (wise.com%16/11/2026%' AND l.verifie_le = DATE '2026-11-16') = 10
  AND NOT EXISTS (SELECT 1 FROM public.referentiel_paiement l WHERE l.methode = 'mobile_money' AND l.pays IN ('GH','KE')),
  'a2 : dix lignes portent la decision du 16/11 avec sa source ; aucune ligne mobile_money n''a ete ecrite');
SELECT pg_temp.vrai((SELECT count(*) FROM public.referentiel_paiement_journal j
   WHERE j.id > current_setting('test.journal0')::bigint AND j.auteur_id IS NULL
     AND j.apres ->> 'source_ref' LIKE 'Wise (wise.com%16/11/2026%') = 10
  AND (SELECT count(DISTINCT j.ligne_id) FROM public.referentiel_paiement_journal j
        WHERE j.id > current_setting('test.journal0')::bigint) = 10,
  'b1 : un journal par ligne changee (voie directe, auteur nul)');
SELECT pg_temp.vrai(pg_temp.vue('1') = 'compatible/compatible/a_completer'
  AND pg_temp.vue('3') = 'compatible/compatible/a_completer',
  'c1 : EG et GH avec compte, en attente de paiement : compatibles, de retour a a_completer');
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements e
    WHERE e.type = 'transition' AND e.etat_apres = 'a_completer' AND e.details ->> 'aNotifier' = 'paiement_possible'
      AND e.candidature_id IN (pg_temp.id('c-1'), pg_temp.id('c-3'))) = 2
  AND (SELECT (j.impact -> 'parGenre' -> 'male' ->> 'aCompleter')::int FROM public.referentiel_paiement_journal j
        JOIN public.referentiel_paiement l ON l.id = j.ligne_id
       WHERE l.pays = 'EG' AND j.id > current_setting('test.journal0')::bigint) = 2,
  'c2 : l''avis « paiement possible » est pose pour ces deux candidats (transition 9) ; le journal d''EG compte 2 candidatures a_completer');
SELECT pg_temp.vrai(pg_temp.vue('2') = 'incompatible/incompatible/a_completer'
  AND (SELECT count(*) FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.id('c-2')
         AND e.type = 'transition' AND e.details ->> 'aNotifier' = 'paiement_possible') = 1,
  'c3 : EG sans compte bancaire (pas de ligne mobile money) : revient aussi a a_completer avec l''avis (conception de CAND-L6, L6-9), son paiement reste incompatible');
SELECT pg_temp.vrai(pg_temp.vue('6') = 'compatible/compatible/en_examen'
  AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.id('c-6')
                    AND e.type = 'transition' AND e.details ->> 'aNotifier' = 'paiement_possible'),
  'c4 : KE avec compte, en examen : compatible, sans avis (aucun changement d''etat)');
SELECT pg_temp.vrai(pg_temp.vue('4') = 'incompatible/incompatible/paiement_non_disponible'
  AND pg_temp.version('4')::text = current_setting('test.v4'),
  'd1 : BJ devenu indisponible, dossier deja en attente : ne bouge pas');
SELECT pg_temp.vrai(pg_temp.vue('7') = 'incompatible/incompatible/en_examen'
  AND pg_temp.version('7')::text = current_setting('test.v7'),
  'd2 : BJ devenu indisponible, dossier en examen : le declencheur ne recalcule que les lignes qui deviennent ou quittent confirme, il ne bouge pas');
SELECT pg_temp.vrai(pg_temp.vue('5') = 'incompatible/incompatible/paiement_non_disponible'
  AND pg_temp.version('5')::text = current_setting('test.v5')
  AND pg_temp.vue('8') = 'compatible/compatible/en_examen',
  'd3 : DZ (en verification) et SA (deja confirme) ne bougent pas');

-- Rejouer ne change plus rien.
SELECT set_config('test.journal', (SELECT count(*)::text FROM public.referentiel_paiement_journal), true);
SELECT set_config('test.evts', (SELECT count(*)::text FROM public.candidature_evenements), true);
SELECT set_config('test.vers', (SELECT string_agg(pg_temp.version(k)::text, ',' ORDER BY k) FROM unnest(ARRAY['1','2','3','4','5','6','7','8']) AS k), true);
\i supabase/migrations/20261128600100_pays_decisions_wise.sql
SELECT pg_temp.vrai((SELECT count(*)::text FROM public.referentiel_paiement_journal) = current_setting('test.journal')
  AND (SELECT count(*)::text FROM public.candidature_evenements) = current_setting('test.evts')
  AND (SELECT string_agg(pg_temp.version(k)::text, ',' ORDER BY k) FROM unnest(ARRAY['1','2','3','4','5','6','7','8']) AS k) = current_setting('test.vers'),
  'e1 : rejouee, la migration ne change rien (journal, evenements, versions)');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 12, 'z : au moins 12 controles passes');
DO $$ BEGIN RAISE NOTICE 'PAYS-DEC : % controles OK', current_setting('test.n'); END $$;
ROLLBACK;
