-- PERSONNES-PERF (20/11/2026) : des donnees FICTIVES a l'echelle de la
-- production du 20/11/2026 (environ 700 profils, 630 candidatures, leurs
-- reponses, evenements, contacts, pieces, accords, 360 fils et 800 messages),
-- pour mesurer les lectures des pages « Personnes » du bureau
-- (`EXPLAIN (ANALYZE, BUFFERS)`) et comparer leurs reponses avant et apres
-- `20261130968000_personnes_perf.sql`.
--
-- Les valeurs derivent du numero de ligne ; seuls quelques identifiants (messages,
-- pieces, reponses) viennent de leurs valeurs par defaut, tirees au hasard : pour
-- comparer avant et apres, on remplit UNE base puis on la copie
-- (`create database ... template ...`, voir supabase/tests/perf/). Aucun nom de
-- personne reelle : des noms faits de syllabes.
--
-- A charger sur une base locale jetable (jamais en production), apres toutes
-- les migrations. Les declencheurs sont coupes pendant le remplissage
-- (`session_replication_role = replica`) : le fichier pose lui-meme les lignes
-- que les declencheurs auraient posees et dont les lectures mesurees ont besoin.
\set ON_ERROR_STOP on
SET session_replication_role = replica;

-- Le temps fige : les « 7 derniers jours » et autres fenetres glissantes
-- rendent la meme chose avant et apres, a condition de comparer dans la meme
-- seance.
CREATE TEMP TABLE pp_base AS SELECT TIMESTAMPTZ '2026-11-20 12:00:00+00' AS t0;

-- Les comptes de la direction : d1 super-administrateur (homme, exception de
-- genre), d2 administratrice (femme).
INSERT INTO auth.users (id, email) VALUES
 ('9e900000-0000-4000-8000-0000000000d1', 'pp-direction-1@test.invalid'),
 ('9e900000-0000-4000-8000-0000000000d2', 'pp-direction-2@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES
 ('9e900000-0000-4000-8000-0000000000d1', 'PP-ADM-0001', 'admin', 'Direction', 'Une', 'active', 'male'),
 ('9e900000-0000-4000-8000-0000000000d2', 'PP-ADM-0002', 'admin', 'Direction', 'Deux', 'active', 'female');
INSERT INTO private.super_admin_kyc (profile_id) VALUES ('9e900000-0000-4000-8000-0000000000d1');
INSERT INTO private.candidature_lecteurs_contact (profile_id) VALUES
 ('9e900000-0000-4000-8000-0000000000d1'), ('9e900000-0000-4000-8000-0000000000d2');
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- Un nom fictif fait de syllabes, a partir d'un numero.
CREATE FUNCTION pg_temp.pp_nom(n integer, sel integer) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT initcap((ARRAY['ba','di','ko','mu','sa','te','li','ra','no','fe','zu','ha'])[1 + (n * 7 + sel) % 12]
              || (ARRAY['ri','ma','lo','ne','ku','si','da','vo','te','ja','pi','go'])[1 + (n * 5 + sel * 3) % 12]
              || (ARRAY['n','l','m','r','s','','d','k'])[1 + (n + sel) % 8]);
$$;
CREATE FUNCTION pg_temp.pp_uuid(prefixe text, n integer) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$
  SELECT (prefixe || '-0000-4000-8000-' || pg_catalog.lpad(n::text, 12, '0'))::uuid;
$$;

-- 630 candidats enseignants (comptes en attente), 3 candidats confirmes, et
-- 20 candidatures d'eleves adultes ou de familles (un foyer chacune).
INSERT INTO public.households (id, timezone)
SELECT pg_temp.pp_uuid('9e9f0000', 100 + n), 'Africa/Casablanca' FROM generate_series(631, 650) n;
INSERT INTO auth.users (id, email)
SELECT pg_temp.pp_uuid('9e9c0000', n), 'pp-candidat-' || n || '@test.invalid'
FROM generate_series(1, 650) n;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender, created_at)
SELECT pg_temp.pp_uuid('9e9c0000', n), 'PP-ENS-' || pg_catalog.lpad(n::text, 4, '0'),
       CASE WHEN n > 630 THEN 'guardian' ELSE 'teacher' END::public.app_role,
       CASE WHEN n > 630 THEN pg_temp.pp_uuid('9e9f0000', 100 + n) END,
       pg_temp.pp_nom(n, 1), pg_temp.pp_nom(n, 2),
       CASE WHEN n > 630 OR n % 10 = 1 THEN 'active' ELSE 'pending_kyc' END::public.account_status,
       CASE WHEN n % 17 = 0 THEN NULL WHEN n % 4 = 0 THEN 'female' ELSE 'male' END::public.gender,
       (SELECT t0 FROM pp_base) - make_interval(days => 60 - n % 60, mins => n)
FROM generate_series(1, 650) n;
INSERT INTO public.teacher_profiles (profile_id, country, pays_residence)
SELECT pg_temp.pp_uuid('9e9c0000', n), (ARRAY['MA','DZ','TN','SN','EG','FR'])[1 + n % 6],
       (ARRAY['MA','DZ','TN','SN','EG','FR'])[1 + n % 6]
FROM generate_series(1, 630) n
WHERE n % 13 <> 0;

INSERT INTO public.candidatures
  (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, paiement, source,
   pays_residence, recue_le, derniere_activite, nom_latin, nom_latin_confirme_le, ouverte_par_equipe_le,
   ouverte_par_equipe_par, versement_debloque_le, versement_debloque_par, reference)
SELECT pg_temp.pp_uuid('9e9ca000', n),
       CASE WHEN n > 630 THEN (CASE WHEN n % 2 = 0 THEN 'famille' ELSE 'eleve_adulte' END) ELSE 'enseignant' END,
       pg_temp.pp_uuid('9e9c0000', n),
       CASE WHEN n % 4 = 0 THEN 'female' ELSE 'male' END::public.gender,
       pg_temp.pp_nom(n, 1) || ' ' || pg_temp.pp_nom(n, 2),
       CASE WHEN n > 630 THEN 'recue'
            WHEN n % 100 < 30 THEN 'prequalification'
            WHEN n % 100 < 55 THEN 'prequalification'
            WHEN n % 100 < 83 THEN 'verifications'
            WHEN n % 100 < 98 THEN 'prequalification'
            ELSE 'confirmee' END,
       CASE WHEN n > 630 THEN NULL
            WHEN n % 100 < 30 THEN 'en_examen'
            WHEN n % 100 < 55 THEN 'a_completer'
            WHEN n % 100 < 83 THEN 'entretien_a_planifier'
            WHEN n % 100 < 98 THEN 'paiement_non_disponible'
            ELSE NULL END,
       CASE WHEN n % 37 = 0 THEN 'retiree' WHEN n % 53 = 0 THEN 'refusee' ELSE 'en_cours' END,
       n % 97 = 0,
       (ARRAY['inconnu','compatible','incompatible','a_verifier'])[1 + n % 4],
       'lien_public',
       (ARRAY['MA','DZ','TN','SN','EG','FR'])[1 + n % 6],
       (SELECT t0 FROM pp_base) - make_interval(days => 50 - n % 50, hours => n % 24),
       (SELECT t0 FROM pp_base) - make_interval(days => n % 20, mins => n * 3),
       CASE WHEN n % 3 = 0 THEN pg_temp.pp_nom(n, 1) || ' ' || pg_temp.pp_nom(n, 2) END,
       CASE WHEN n % 3 = 0 THEN (SELECT t0 FROM pp_base) - make_interval(days => 1) END,
       CASE WHEN n % 5 <> 0 THEN (SELECT t0 FROM pp_base) - make_interval(days => n % 10) END,
       CASE WHEN n % 5 <> 0 THEN '9e900000-0000-4000-8000-0000000000d1'::uuid END,
       -- Versement debloque (paiement compatible) pour une candidature sur trois : le compteur
       -- « bloquees » lit alors le second controle (profil unique).
       CASE WHEN n % 3 = 0 THEN (SELECT t0 FROM pp_base) - make_interval(days => 2) END,
       CASE WHEN n % 3 = 0 THEN '9e900000-0000-4000-8000-0000000000d1'::uuid END,
       'CAND-' || (90000 + n)::text
FROM generate_series(1, 650) n;

INSERT INTO public.candidature_contacts (candidature_id, courriel, telephone, telephone_brut)
SELECT pg_temp.pp_uuid('9e9ca000', n),
       CASE WHEN n % 9 <> 0 THEN 'pp-candidat-' || n || '@test.invalid' END,
       CASE WHEN n % 2 = 0 THEN '+21260000' || pg_catalog.lpad(n::text, 4, '0') END,
       CASE WHEN n % 2 = 1 AND n % 11 = 0 THEN '060000' || pg_catalog.lpad(n::text, 4, '0') END
FROM generate_series(1, 650) n;

-- Six evenements par candidature ; une demande de complement (aCompleter) pour
-- une candidature sur sept, dont une sur deux est close par la transition 6.
INSERT INTO public.candidature_evenements
  (candidature_id, type, etape_avant, etape_apres, etat_avant, etat_apres, details, cree_le)
SELECT pg_temp.pp_uuid('9e9ca000', n), 'transition',
       'prequalification', c.etape, NULL,
       CASE WHEN k = 6 THEN c.etat ELSE 'en_examen' END,
       CASE WHEN k = 4 AND n % 7 = 0 THEN '{"aCompleter": ["piece_identite", "photo"]}'::jsonb
            WHEN k = 5 AND n % 14 = 0 THEN '{"transition": "6"}'::jsonb
            ELSE pg_catalog.jsonb_build_object('transition', k::text) END,
       c.recue_le + make_interval(hours => k * 5)
FROM generate_series(1, 650) n
JOIN public.candidatures c ON c.id = pg_temp.pp_uuid('9e9ca000', n)
CROSS JOIN generate_series(1, 6) k;

INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le, envoye_le, brouillon)
SELECT pg_temp.pp_uuid('9e9ca000', n), 'v3',
       pg_catalog.jsonb_build_object('languesExplication', '["ar","fr"]'::jsonb, 'niveau', 'avance',
         'publics', '["enfants"]'::jsonb, 'fuseau', 'Africa/Casablanca',
         'disponibilites', '[{"jour": 1, "debut": "18:00", "fin": "20:00"}]'::jsonb),
       'candidat', (SELECT t0 FROM pp_base) - make_interval(days => n % 30 + k),
       CASE WHEN k = 1 THEN (SELECT t0 FROM pp_base) - make_interval(days => n % 30 + k) END,
       k = 2
FROM generate_series(1, 630) n
CROSS JOIN generate_series(1, 2) k
WHERE k = 1 OR n % 3 = 0;

-- Pieces : 460 pieces sur 430 comptes (en attente, approuvees, refusees).
INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key, status, created_at)
SELECT pg_temp.pp_uuid('9e9c0000', n), 'passport',
       CASE WHEN n % 4 = 0 THEN 'female' ELSE 'male' END::public.gender,
       'kyc/pp/' || n || '/' || k || '.jpg',
       (ARRAY['pending','approved','rejected'])[1 + (n + k) % 3]::public.kyc_doc_status,
       (SELECT t0 FROM pp_base) - make_interval(days => n % 40, hours => k)
FROM generate_series(1, 430) n
CROSS JOIN generate_series(1, 2) k
WHERE k = 1 OR n % 14 = 0;

-- Accords : quatre par compte enseignant.
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version, signed_sha256, accepted_at)
SELECT pg_temp.pp_uuid('9e9c0000', n), x.kind, 'v1', pg_catalog.md5(n::text || x.kind),
       (SELECT t0 FROM pp_base) - make_interval(days => n % 40)
FROM generate_series(1, 630) n
CROSS JOIN (VALUES ('teacher_nda'), ('recording_and_control_notice'), ('teacher_conduct_code'),
                   ('teacher_religious_framework')) AS x(kind);

-- Familles : 30 foyers, 30 tuteurs, 50 eleves.
INSERT INTO public.households (id, timezone)
SELECT pg_temp.pp_uuid('9e9f0000', h), 'Europe/Paris' FROM generate_series(1, 30) h;
INSERT INTO auth.users (id, email)
SELECT pg_temp.pp_uuid('9e9e0000', n), 'pp-famille-' || n || '@test.invalid' FROM generate_series(1, 80) n;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender, created_at)
SELECT pg_temp.pp_uuid('9e9e0000', n), 'PP-FAM-' || pg_catalog.lpad(n::text, 4, '0'),
       CASE WHEN n <= 30 THEN 'guardian' ELSE 'student' END::public.app_role,
       pg_temp.pp_uuid('9e9f0000', 1 + (n - 1) % 30),
       pg_temp.pp_nom(n + 1000, 1), pg_temp.pp_nom(n + 1000, 2), 'active',
       CASE WHEN n % 2 = 0 THEN 'female' ELSE 'male' END::public.gender,
       (SELECT t0 FROM pp_base) - make_interval(days => n)
FROM generate_series(1, 80) n;
UPDATE public.households h SET primary_guardian_id = pg_temp.pp_uuid('9e9e0000', x.h)
FROM generate_series(1, 30) x(h) WHERE h.id = pg_temp.pp_uuid('9e9f0000', x.h);
INSERT INTO public.student_profiles (profile_id, student_type)
SELECT pg_temp.pp_uuid('9e9e0000', n), 'minor' FROM generate_series(31, 80) n;

-- Messagerie : 330 fils candidature (le candidat et l'equipe), 30 fils
-- dossier (le tuteur et l'equipe), 800 messages, 650 lectures.
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id, cree_le, dernier_message_le)
SELECT pg_temp.pp_uuid('9e9d0000', n), 'candidature', pg_temp.pp_uuid('9e9ca000', n), 'profil',
       pg_temp.pp_uuid('9e9c0000', n), 'equipe', NULL,
       (SELECT t0 FROM pp_base) - make_interval(days => n % 15, hours => 1),
       (SELECT t0 FROM pp_base) - make_interval(days => n % 15)
FROM generate_series(1, 330) n;
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id, cree_le, dernier_message_le)
SELECT pg_temp.pp_uuid('9e9d0000', 1000 + h), 'dossier', pg_temp.pp_uuid('9e9e0000', h), 'foyer',
       pg_temp.pp_uuid('9e9f0000', h), 'equipe', NULL,
       (SELECT t0 FROM pp_base) - make_interval(days => h % 20, hours => 2),
       (SELECT t0 FROM pp_base) - make_interval(days => h % 20)
FROM generate_series(1, 30) h;
INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
SELECT pg_temp.pp_uuid('9e9d0000', n),
       CASE WHEN k % 2 = 1 THEN pg_temp.pp_uuid('9e9c0000', n) ELSE '9e900000-0000-4000-8000-0000000000d1'::uuid END,
       pg_temp.pp_uuid('9e9b0000', n * 10 + k),
       'Message fictif ' || k || ' du fil ' || n,
       (SELECT t0 FROM pp_base) - make_interval(days => n % 15, mins => 60 - k * 10)
FROM generate_series(1, 330) n
CROSS JOIN generate_series(1, 3) k
WHERE k <= 2 OR n % 3 = 0;
INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
SELECT pg_temp.pp_uuid('9e9d0000', 1000 + h),
       CASE WHEN k % 2 = 1 THEN pg_temp.pp_uuid('9e9e0000', h) ELSE '9e900000-0000-4000-8000-0000000000d2'::uuid END,
       pg_temp.pp_uuid('9e9b0000', 90000 + h * 10 + k), 'Message fictif ' || k || ' du dossier ' || h,
       (SELECT t0 FROM pp_base) - make_interval(days => h % 20, mins => 60 - k * 10)
FROM generate_series(1, 30) h CROSS JOIN generate_series(1, 3) k;
INSERT INTO public.com_lectures (fil_id, profile_id, lu_jusqu_au)
SELECT pg_temp.pp_uuid('9e9d0000', n), pg_temp.pp_uuid('9e9c0000', n),
       (SELECT t0 FROM pp_base) - make_interval(days => n % 15, mins => 30)
FROM generate_series(1, 330) n;
INSERT INTO public.com_lectures (fil_id, profile_id, lu_jusqu_au)
SELECT pg_temp.pp_uuid('9e9d0000', n), '9e900000-0000-4000-8000-0000000000d1',
       (SELECT t0 FROM pp_base) - make_interval(days => n % 15, mins => 45)
FROM generate_series(1, 330) n WHERE n % 2 = 0;
INSERT INTO public.com_lectures (fil_id, profile_id, lu_jusqu_au)
SELECT pg_temp.pp_uuid('9e9d0000', 1000 + h), '9e900000-0000-4000-8000-0000000000d2',
       (SELECT t0 FROM pp_base) - make_interval(days => h % 20)
FROM generate_series(1, 30) h;

SET session_replication_role = origin;
ANALYZE;
