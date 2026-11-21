-- PE-A7 (lot COURRIELS-CANDIDAT, 20/11/2026) : migration 20261130942000. NE PAS FUSIONNER sans decision du directeur.
--
-- Cinq groupes de 100 candidats hommes qui attendent leur entretien, separes par leur langue (ar, en, ff, es, pt) ;
-- chaque creneau ne parle qu'une langue, donc ne concerne qu'un groupe. Les nombres de courriels sont dits a chaque pas.
--   S1. un creneau pour 100 candidats : 100 avis (un par candidat, une seule place) ;
--   S2. dix creneaux ouverts dans la meme transaction : 100 avis, pas 1000 (seul le premier compte) ;
--   S3. le lendemain : un nouveau creneau alors que celui de la veille est encore libre : 0 avis de plus ; celui de
--       la veille annule puis un nouveau : 0 avis de plus (un avis par 7 jours) ;
--   S4. annulation du creneau avant l'envoi : les 100 avis en file sont ecartes a l'envoi, 0 part ; temoin : un avis
--       dont le creneau est toujours ouvert n'est pas ecarte ;
--   S5. un creneau choisissable existait deja (ouvert plus tot) : un nouveau creneau ne previent personne ;
--   S6. l'avis reste dans le plafond ; fonctions fermees aux clients ; la porte du travailleur est au service_role.
-- Le declencheur est differe : le scenario le fait jouer par SET CONSTRAINTS ... IMMEDIATE.
-- Chaque controle leve 'PE-A7 ROUGE : ...' s'il echoue. Transaction annulee a la fin.
\set ON_ERROR_STOP on
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'PE-A7 ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.p(p_g text, p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS
  $$ SELECT ('ce7' || p_g || '0000-0000-4000-8000-' || pg_catalog.lpad(p_n::text, 12, '0'))::uuid $$;
-- Les avis d'un groupe (langue).
CREATE FUNCTION pg_temp.avis(p_g text, p_statut text DEFAULT NULL) RETURNS integer LANGUAGE sql AS $$
  SELECT count(*)::int FROM public.courriels_sortants s
   WHERE s.modele = 'entretien_creneau_ouvert'
     AND s.destinataire_profil::text LIKE 'ce7' || p_g || '%'
     AND (p_statut IS NULL OR s.statut = p_statut) $$;
CREATE FUNCTION pg_temp.creneau(p_id text, p_langue text, p_jours integer, p_ouvert timestamptz DEFAULT NULL) RETURNS void
LANGUAGE sql AS $$
  INSERT INTO public.entretien_creneaux (id, cote, debut, duree_minutes, langues, ouvert_par, ouvert_le)
  VALUES (('ce7c0000-0000-4000-8000-0000000' || p_id)::uuid, 'male', now() + pg_catalog.make_interval(days => p_jours), 30,
          ARRAY[p_langue], 'ce7a0000-0000-4000-8000-000000000001', coalesce(p_ouvert, pg_catalog.clock_timestamp()));
  INSERT INTO public.entretien_creneau_participants (creneau_id, profile_id)
  VALUES (('ce7c0000-0000-4000-8000-0000000' || p_id)::uuid, 'ce7f0000-0000-4000-8000-000000000001'),
         (('ce7c0000-0000-4000-8000-0000000' || p_id)::uuid, 'ce7f0000-0000-4000-8000-000000000002');
$$;

SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email) VALUES
  ('ce7a0000-0000-4000-8000-000000000001', 'pe7-direction@test.invalid'),
  ('ce7f0000-0000-4000-8000-000000000001', 'pe7-f1@test.invalid'),
  ('ce7f0000-0000-4000-8000-000000000002', 'pe7-f2@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
  ('ce7a0000-0000-4000-8000-000000000001', 'PE7-ADM-0001', 'admin', 'Direction', 'Fictive', 'active', 'male'),
  ('ce7f0000-0000-4000-8000-000000000001', 'PE7-FON-0001', 'admin', 'Fondateur', 'Un', 'active', 'male'),
  ('ce7f0000-0000-4000-8000-000000000002', 'PE7-FON-0002', 'admin', 'Fondateur', 'Deux', 'active', 'male');
INSERT INTO public.personnel_fondateurs (profile_id, fondateur, modifie_par) VALUES
  ('ce7f0000-0000-4000-8000-000000000001', true, 'ce7a0000-0000-4000-8000-000000000001'),
  ('ce7f0000-0000-4000-8000-000000000002', true, 'ce7a0000-0000-4000-8000-000000000001');
-- Groupes : 1 = ar, 2 = en, 3 = ff, 4 = es, 5 = pt ; 100 candidats chacun.
CREATE TEMP TABLE groupes (g text, langue text) ON COMMIT DROP;
INSERT INTO groupes VALUES ('1', 'ar'), ('2', 'en'), ('3', 'ff'), ('4', 'es'), ('5', 'pt');
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(g.g, n), 'pe7-' || g.g || '-' || n || '@test.invalid' FROM groupes g, generate_series(1, 100) n;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(g.g, n), 'PE7-' || g.g || '-' || pg_catalog.lpad(n::text, 4, '0'), 'teacher', 'Essai', 'Fictif', 'pending_kyc', 'male'
  FROM groupes g, generate_series(1, 100) n;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, langue)
SELECT pg_temp.p(g.g, n), 'enseignant', pg_temp.p(g.g, n), 'male', 'Fixture ' || g.g || '-' || n,
       'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public', 'fr'
  FROM groupes g, generate_series(1, 100) n;
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le)
SELECT pg_temp.p(g.g, n), 'v1-2026-10', pg_catalog.jsonb_build_object('langueMaternelle', g.langue), 'candidat', now() - interval '1 day'
  FROM groupes g, generate_series(1, 100) n;
SET LOCAL session_replication_role = origin;

-- S1. Un creneau pour 100 candidats.
SELECT pg_temp.creneau('00011', 'ar', 2);
SET CONSTRAINTS entretien_creneau_ouvert_avis IMMEDIATE;
SET CONSTRAINTS entretien_creneau_ouvert_avis DEFERRED;
SELECT pg_temp.vrai(pg_temp.avis('1') = 100, 'S1 : un creneau, 100 candidats compatibles sans creneau : 100 avis');

-- S2. Dix creneaux dans la meme transaction.
SELECT pg_temp.creneau(pg_catalog.lpad((20 + n)::text, 5, '0'), 'en', 2 + n) FROM generate_series(1, 10) n;
SET CONSTRAINTS entretien_creneau_ouvert_avis IMMEDIATE;
SET CONSTRAINTS entretien_creneau_ouvert_avis DEFERRED;
SELECT pg_temp.vrai(pg_temp.avis('2') = 100, 'S2 : dix creneaux d''un coup : 100 avis (un par candidat), pas 1000');

-- S3. La veille, un creneau a ete ouvert (avis partis) ; le lendemain, un nouveau.
SELECT pg_temp.creneau('00031', 'ff', 3, now() - interval '1 day');
SET CONSTRAINTS entretien_creneau_ouvert_avis IMMEDIATE;
SET CONSTRAINTS entretien_creneau_ouvert_avis DEFERRED;
SELECT pg_temp.vrai(pg_temp.avis('3') = 100, 'S3a : le creneau de la veille : 100 avis');
SELECT pg_temp.creneau('00032', 'ff', 4);
SET CONSTRAINTS entretien_creneau_ouvert_avis IMMEDIATE;
SET CONSTRAINTS entretien_creneau_ouvert_avis DEFERRED;
SELECT pg_temp.vrai(pg_temp.avis('3') = 100, 'S3b : le lendemain, celui de la veille encore libre : 0 avis de plus');
UPDATE public.entretien_creneaux SET annule_le = now(), annule_par = 'ce7a0000-0000-4000-8000-000000000001'
 WHERE id IN ('ce7c0000-0000-4000-8000-000000000031', 'ce7c0000-0000-4000-8000-000000000032');
SELECT pg_temp.creneau('00033', 'ff', 5);
SET CONSTRAINTS entretien_creneau_ouvert_avis IMMEDIATE;
SET CONSTRAINTS entretien_creneau_ouvert_avis DEFERRED;
SELECT pg_temp.vrai(pg_temp.avis('3') = 100, 'S3c : creneaux de la veille annules, un nouveau : 0 avis de plus (7 jours)');

-- S4. Annulation avant l'envoi : le travailleur reserve les avis (statut envoi) puis demande s'il faut les ecarter.
SELECT pg_temp.creneau('00041', 'es', 2);
SET CONSTRAINTS entretien_creneau_ouvert_avis IMMEDIATE;
SET CONSTRAINTS entretien_creneau_ouvert_avis DEFERRED;
SELECT pg_temp.vrai(pg_temp.avis('4') = 100, 'S4a : 100 avis en file');
UPDATE public.entretien_creneaux SET annule_le = now(), annule_par = 'ce7a0000-0000-4000-8000-000000000001'
 WHERE id = 'ce7c0000-0000-4000-8000-000000000041';
UPDATE public.courriels_sortants SET statut = 'envoi', reserve_le = now(), tentatives = 1
 WHERE modele = 'entretien_creneau_ouvert' AND destinataire_profil::text LIKE 'ce74%';
SELECT set_config('test.ids', (SELECT array_agg(s.id)::text FROM public.courriels_sortants s
                                WHERE s.modele = 'entretien_creneau_ouvert' AND s.destinataire_profil::text LIKE 'ce74%'), true);
-- Le travailleur appelle la porte avec la cle de service.
SET LOCAL ROLE service_role;
SELECT set_config('test.ecartes', (SELECT count(*) FILTER (WHERE public.courriel_avis_creneau_ecarter(x))::text
                                     FROM unnest(current_setting('test.ids')::uuid[]) x), true);
RESET ROLE;
SELECT pg_temp.vrai(current_setting('test.ecartes') = '100' AND pg_temp.avis('4', 'annule') = 100 AND pg_temp.avis('4', 'envoi') = 0,
  'S4b : creneau annule avant l''envoi : 100 avis ecartes, 0 part');
-- Temoin : groupe 1, creneau toujours ouvert : l'avis n'est pas ecarte.
UPDATE public.courriels_sortants SET statut = 'envoi', reserve_le = now(), tentatives = 1
 WHERE id = (SELECT id FROM public.courriels_sortants WHERE modele = 'entretien_creneau_ouvert'
              AND destinataire_profil = pg_temp.p('1', 1));
SELECT pg_temp.vrai(NOT public.courriel_avis_creneau_ecarter(
    (SELECT id FROM public.courriels_sortants WHERE modele = 'entretien_creneau_ouvert' AND destinataire_profil = pg_temp.p('1', 1))),
  'S4c : temoin, le creneau est toujours ouvert : l''avis part');
-- Un candidat dont l'entretien est deja fixe : ecarte.
UPDATE public.candidatures SET etat = 'entretien_planifie' WHERE id = pg_temp.p('1', 1);
SELECT pg_temp.vrai(public.courriel_avis_creneau_ecarter(
    (SELECT id FROM public.courriels_sortants WHERE modele = 'entretien_creneau_ouvert' AND destinataire_profil = pg_temp.p('1', 1))),
  'S4d : entretien deja fixe : l''avis est ecarte');

-- S5. Un creneau choisissable existait deja (pose sans declencheur, donc sans avis) : le nouveau ne previent personne.
SET LOCAL session_replication_role = replica;
SELECT pg_temp.creneau('00051', 'pt', 2, now() - interval '2 hours');
SET LOCAL session_replication_role = origin;
SELECT pg_temp.creneau('00052', 'pt', 3);
SET CONSTRAINTS entretien_creneau_ouvert_avis IMMEDIATE;
SET CONSTRAINTS entretien_creneau_ouvert_avis DEFERRED;
SELECT pg_temp.vrai(pg_temp.avis('5') = 0, 'S5 : un creneau choisissable existait deja : 0 avis');

-- S6.
SELECT pg_temp.vrai(NOT private.courriel_hors_plafond(false, 'entretien_creneau_ouvert'),
  'S6a : l''avis reste dans le plafond et l''etalement ordinaires');
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated', 'private.entretien_creneau_ouvert_prevenir()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.entretien_creneau_ouvert_prevenir()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'public.courriel_avis_creneau_ecarter(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.courriel_avis_creneau_ecarter(uuid)', 'EXECUTE')
  AND pg_catalog.has_function_privilege('service_role', 'public.courriel_avis_creneau_ecarter(uuid)', 'EXECUTE'),
  'S6b : fonctions fermees aux clients ; la porte du travailleur au service_role seul');
SELECT pg_temp.vrai((SELECT count(*) FROM public.courriels_sortants WHERE modele = 'entretien_creneau_ouvert') = 400
  AND (SELECT bool_and(donnees ? 'jeton_desinscription' AND categorie = 'recrutement')
         FROM public.courriels_sortants WHERE modele = 'entretien_creneau_ouvert'),
  'S6c : 400 avis au total pour 500 candidats et 16 creneaux ; categorie recrutement, lien de desinscription');

ROLLBACK;
