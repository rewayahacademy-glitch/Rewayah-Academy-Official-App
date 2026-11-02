-- Lot (B), 02/11/2026 : sans paiement, ni seances ni ressources ; l'espace
-- reste ouvert. Scenario sur une base nue (stub + toutes les migrations).
--
-- Foyer F1 : tuteur d1, enfant e1 SUSPENDU pour paiement.
-- Foyer F3 : tuteur d3, enfant e2 a jour. Les deux enfants dans la Classe c1.
-- On verifie que F1 ne lit plus rien de ferme, que F3 lit tout, que
-- l'enseignant n'est pas touche, puis qu'une bourse de 100 % leve la
-- suspension tout de suite et rouvre tout.
\set ON_ERROR_STOP 1
BEGIN;
SET LOCAL client_min_messages = warning;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object('aal', 'aal1')::text
                ELSE pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                       pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'Lot B ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, false);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'Lot B ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'Lot B ROUGE : % (%, % au lieu de %)', p_label, SQLSTATE, SQLERRM, p_code;
    END IF;
  END;
  PERFORM pg_temp.vrai(true, p_label);
END $$;

-- Lignes visibles d'une requete, sous le role et le jeton courants.
CREATE FUNCTION pg_temp.nb(p_sql text) RETURNS integer LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  EXECUTE 'SELECT count(*)::integer FROM (' || p_sql || ') x' INTO v;
  RETURN v;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text), pg_temp.nb(text) TO authenticated, anon, service_role;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('8b000000-0000-4000-8000-0000000000a1','lb-admin@test.invalid'),
 ('8b000000-0000-4000-8000-0000000000b1','lb-ens@test.invalid'),
 ('8b000000-0000-4000-8000-0000000000d1','lb-tut1@test.invalid'),
 ('8b000000-0000-4000-8000-0000000000d3','lb-tut3@test.invalid'),
 ('8b000000-0000-4000-8000-0000000000e1','lb-e1@test.invalid'),
 ('8b000000-0000-4000-8000-0000000000e2','lb-e2@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('8b000000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('8b000000-0000-4000-8000-0000000000f3','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('8b000000-0000-4000-8000-0000000000a1','LB-ADM-0001','admin',NULL,'Direction','LB','active','female'),
 ('8b000000-0000-4000-8000-0000000000b1','LB-ENS-0001','teacher',NULL,'Maryam','LB','provisional_active','female'),
 ('8b000000-0000-4000-8000-0000000000d1','LB-TUT-0001','guardian','8b000000-0000-4000-8000-0000000000f1','Amina','F1','active','female'),
 ('8b000000-0000-4000-8000-0000000000d3','LB-TUT-0003','guardian','8b000000-0000-4000-8000-0000000000f3','Karim','F3','active','male'),
 ('8b000000-0000-4000-8000-0000000000e1','LB-ELV-0001','student','8b000000-0000-4000-8000-0000000000f1','Yasmine','F1','active','female'),
 ('8b000000-0000-4000-8000-0000000000e2','LB-ELV-0002','student','8b000000-0000-4000-8000-0000000000f3','Bilal','F3','active','male');
UPDATE public.households SET primary_guardian_id = '8b000000-0000-4000-8000-0000000000d1'
 WHERE id = '8b000000-0000-4000-8000-0000000000f1';
UPDATE public.households SET primary_guardian_id = '8b000000-0000-4000-8000-0000000000d3'
 WHERE id = '8b000000-0000-4000-8000-0000000000f3';
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('8b000000-0000-4000-8000-0000000000e1','minor','standard'),
 ('8b000000-0000-4000-8000-0000000000e2','minor','standard');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('8b000000-0000-4000-8000-000000000c01','8b000000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour LB',1,9,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 ('8b000000-0000-4000-8000-000000000c01','8b000000-0000-4000-8000-0000000000e1', now() - interval '20 days'),
 ('8b000000-0000-4000-8000-000000000c01','8b000000-0000-4000-8000-0000000000e2', now() - interval '20 days');

-- Le mois de e1 n'est pas paye : facture, puis suspension (comme le passage
-- quotidien des relances).
SELECT private.fac_portefeuille(h.id, 'USD') FROM public.households h WHERE h.id::text LIKE '8b000000-%';
INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial, lignes, total_mineur)
VALUES ('8b000000-0000-4000-8000-0000000000e1','8b000000-0000-4000-8000-0000000000f1',
        private.fac_mois_courant(), 'v2.0.0', 'USD', 1, '[]'::jsonb, 5500);
INSERT INTO public.acces_suspensions_paiement(profile_id, facture_id, jour)
SELECT f.profile_id, f.id, private.fac_aujourdhui() FROM public.factures_mensuelles f
 WHERE f.profile_id = '8b000000-0000-4000-8000-0000000000e1';

-- Bibliotheque : R1, en regle et attribue a la Classe.
INSERT INTO public.library_resource(id, title, short_title, resource_type, access_policy, offline_policy) VALUES
 ('8b000000-0000-4000-8000-000000000071','Support LB','S1','pdf','groupe_assigne','jamais');
INSERT INTO public.resource_version(id, resource_id, numero_version, statut) VALUES
 ('8b000000-0000-4000-8000-000000000081','8b000000-0000-4000-8000-000000000071',1,'brouillon');
INSERT INTO public.download_asset(id, resource_version_id, format, cle_stockage, taille_octets, origine) VALUES
 ('8b000000-0000-4000-8000-000000000091','8b000000-0000-4000-8000-000000000081','pdf',
  'supports/8b000000-0000-4000-8000-000000000091/1/un.pdf',128,'importe_tel_quel');
UPDATE public.resource_version SET download_asset_id = '8b000000-0000-4000-8000-000000000091'
 WHERE id = '8b000000-0000-4000-8000-000000000081';
INSERT INTO public.library_version_rights(resource_version_id, source_titre, titulaire, usages, attribution, approuve, revu_par, revu_le)
VALUES ('8b000000-0000-4000-8000-000000000081', 'Source essai', 'Titulaire essai', ARRAY['application','classe'],
        'Attribution essai', true, '8b000000-0000-4000-8000-0000000000a1', now());
SELECT set_config('request.jwt.claim.sub', '8b000000-0000-4000-8000-0000000000a1', true);
UPDATE public.resource_version SET statut = 'publiee' WHERE id = '8b000000-0000-4000-8000-000000000081';
UPDATE public.library_resource SET current_version_id = '8b000000-0000-4000-8000-000000000081'
 WHERE id = '8b000000-0000-4000-8000-000000000071';
INSERT INTO public.library_resource_groupe(resource_id, groupe_id) VALUES
 ('8b000000-0000-4000-8000-000000000071','8b000000-0000-4000-8000-000000000c01');

-- Travail a preparer pour toute la Classe.
INSERT INTO public.learning_assignment(id, group_id, student_id, resource_id, purpose, starts_at, due_at, created_by, status) VALUES
 ('8b000000-0000-4000-8000-0000000000a9','8b000000-0000-4000-8000-000000000c01',NULL,
  '8b000000-0000-4000-8000-000000000071','learn',now(),now() + interval '1 day','8b000000-0000-4000-8000-0000000000b1','a_faire');

-- S1 : seance en cours de la Classe, les deux enfants inscrits, un support
-- affiche ; S2 : seance passee ou seul e1 etait, avec son enregistrement.
INSERT INTO public.sessions(id, teacher_id, groupe_id, started_at, ended_at, status, session_type) VALUES
 ('8b000000-0000-4000-8000-000000000501','8b000000-0000-4000-8000-0000000000b1','8b000000-0000-4000-8000-000000000c01',
  now() - interval '10 minutes', now() + interval '50 minutes', 'planned', 'standard'),
 ('8b000000-0000-4000-8000-000000000502','8b000000-0000-4000-8000-0000000000b1','8b000000-0000-4000-8000-000000000c01',
  now() - interval '8 days', now() - interval '8 days' + interval '1 hour', 'ended', 'standard');
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
 ('8b000000-0000-4000-8000-000000000501','8b000000-0000-4000-8000-0000000000e1','student'),
 ('8b000000-0000-4000-8000-000000000501','8b000000-0000-4000-8000-0000000000e2','student'),
 ('8b000000-0000-4000-8000-000000000501','8b000000-0000-4000-8000-0000000000d1','guardian_observer'),
 ('8b000000-0000-4000-8000-000000000502','8b000000-0000-4000-8000-0000000000e1','student');
INSERT INTO public.session_shared_content(session_id, resource_id, resource_version_id, content_position, display_mode, revision, updated_by)
VALUES ('8b000000-0000-4000-8000-000000000501','8b000000-0000-4000-8000-000000000071',
        '8b000000-0000-4000-8000-000000000081','{"page": 1}'::jsonb,'page',1,'8b000000-0000-4000-8000-0000000000b1');
INSERT INTO public.session_recordings(id, session_id, object_key, duration_seconds, size_bytes, expires_at) VALUES
 ('8b000000-0000-4000-8000-000000000601','8b000000-0000-4000-8000-000000000502','enregistrements/lb/s2.ogg',
  3600, 1000, now() + interval '30 days');

-- ------------------------------------------------------------------
-- 1. La porte
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT private.acces_paye('8b000000-0000-4000-8000-0000000000e1')
  AND private.acces_paye('8b000000-0000-4000-8000-0000000000e2'),
  '1 : la porte dit e1 non paye, e2 paye');
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.acces_paye(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.acces_paye_seance(uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'private.acces_paye_seance(uuid)', 'EXECUTE'),
  '1 : la porte n''est pas appelable par un client ; les aides de l''appelant le sont');

-- ------------------------------------------------------------------
-- 2. Ce qui est ferme a F1, ouvert a F3, ouvert a l'enseignant
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('8b000000-0000-4000-8000-0000000000d1', 'guardian', '8b000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(pg_temp.nb('SELECT 1 FROM public.learning_assignment WHERE id = ''8b000000-0000-4000-8000-0000000000a9''') = 0,
  '2 : F1 ne lit plus le travail a preparer');
SELECT pg_temp.vrai(pg_temp.nb('SELECT 1 FROM public.library_resource WHERE id = ''8b000000-0000-4000-8000-000000000071''') = 0,
  '2 : F1 ne voit plus la ressource de la Classe');
SELECT pg_temp.vrai(pg_temp.nb('SELECT 1 FROM public.library_resource_groupe WHERE groupe_id = ''8b000000-0000-4000-8000-000000000c01''') = 0,
  '2 : F1 ne voit plus l''attribution de la ressource');
SELECT pg_temp.vrai(pg_temp.nb('SELECT 1 FROM public.session_recordings WHERE id = ''8b000000-0000-4000-8000-000000000601''') = 0,
  '2 : F1 ne voit plus l''enregistrement');
SELECT pg_temp.refus($q$SELECT public.autoriser_lecture_version('8b000000-0000-4000-8000-000000000081')$q$, '42501',
  '2 : F1 ne lit pas la ressource');
SELECT pg_temp.refus($q$SELECT public.autoriser_ecoute_archive('8b000000-0000-4000-8000-000000000601')$q$, '42501',
  '2 : F1 n''ecoute pas l''enregistrement');
SELECT pg_temp.refus($q$SELECT public.seance_a_rejoindre('8b000000-0000-4000-8000-000000000c01')$q$, '42501',
  '2 : F1 n''ouvre pas la seance de la Classe');
SELECT pg_temp.vrai(public.entrer_observation('8b000000-0000-4000-8000-000000000501', 'guardian_observer') ->> 'motif_refus'
                    = 'acces_suspendu',
  '2 : F1 n''entre pas en observation, motif « acces_suspendu »');

SELECT pg_temp.qui('8b000000-0000-4000-8000-0000000000e1', 'student', '8b000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(public.support_actif('8b000000-0000-4000-8000-000000000501') IS NULL,
  '2 : e1 ne recoit pas le support actif');

SELECT pg_temp.qui('8b000000-0000-4000-8000-0000000000d3', 'guardian', '8b000000-0000-4000-8000-0000000000f3');
SELECT pg_temp.vrai(pg_temp.nb('SELECT 1 FROM public.learning_assignment WHERE id = ''8b000000-0000-4000-8000-0000000000a9''') = 1
  AND pg_temp.nb('SELECT 1 FROM public.library_resource WHERE id = ''8b000000-0000-4000-8000-000000000071''') = 1,
  '2 : F3 (a jour) lit le travail et la ressource');
SELECT pg_temp.vrai(public.autoriser_lecture_version('8b000000-0000-4000-8000-000000000081') IS NOT NULL,
  '2 : F3 lit la ressource');
SELECT pg_temp.qui('8b000000-0000-4000-8000-0000000000e2', 'student', '8b000000-0000-4000-8000-0000000000f3');
-- Un eleve lit le support par support_actif (il ne lit pas sa propre ligne de
-- session_participants, donc jamais session_shared_content en direct).
SELECT pg_temp.vrai(public.support_actif('8b000000-0000-4000-8000-000000000501') IS NOT NULL,
  '2 : e2 (a jour) recoit le support actif');

SELECT pg_temp.qui('8b000000-0000-4000-8000-0000000000b1', 'teacher', NULL);
SELECT pg_temp.vrai(public.support_actif('8b000000-0000-4000-8000-000000000501') IS NOT NULL
  AND pg_temp.nb('SELECT 1 FROM public.session_recordings WHERE id = ''8b000000-0000-4000-8000-000000000601''') = 1
  AND pg_temp.nb('SELECT 1 FROM public.learning_assignment WHERE id = ''8b000000-0000-4000-8000-0000000000a9''') = 1,
  '2 : l''enseignant n''est pas touche');
RESET ROLE;

-- Jeton video de l'observateur-tuteur (sous service_role, comme create-room-token).
SET LOCAL ROLE service_role;
SELECT pg_temp.refus($q$SELECT public.autoriser_jeton_video('8b000000-0000-4000-8000-000000000501',
  '8b000000-0000-4000-8000-0000000000d1', 'wss://cloud.invalid', 'wss://self.invalid')$q$, '42501',
  '2 : F1 ne recoit pas de jeton d''observation');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Messages : le fil avec l'enseignant ferme, celui de la direction reste
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM private.com_paires('classe', '8b000000-0000-4000-8000-000000000c01') q
                                 WHERE q.a_id = '8b000000-0000-4000-8000-0000000000f1' AND q.b_nature = 'profil')
  AND EXISTS (SELECT 1 FROM private.com_paires('classe', '8b000000-0000-4000-8000-000000000c01') q
               WHERE q.a_id = '8b000000-0000-4000-8000-0000000000f1' AND q.b_nature = 'equipe')
  AND EXISTS (SELECT 1 FROM private.com_paires('classe', '8b000000-0000-4000-8000-000000000c01') q
               WHERE q.a_id = '8b000000-0000-4000-8000-0000000000f3' AND q.b_nature = 'profil'),
  '3 : F1 perd le fil avec l''enseignant, garde la direction ; F3 garde l''enseignant');
SELECT pg_temp.qui('8b000000-0000-4000-8000-0000000000d1', 'guardian', '8b000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(NOT private.com_lit_classe('8b000000-0000-4000-8000-000000000c01'),
  '3 : F1 ne lit plus les annonces de la Classe');
SELECT pg_temp.qui('8b000000-0000-4000-8000-0000000000d3', 'guardian', '8b000000-0000-4000-8000-0000000000f3');
SELECT pg_temp.vrai(private.com_lit_classe('8b000000-0000-4000-8000-000000000c01'),
  '3 : F3 lit les annonces de la Classe');

-- ------------------------------------------------------------------
-- 4. Une bourse de 100 % leve la suspension tout de suite
-- ------------------------------------------------------------------
INSERT INTO public.bourses_eleves(profile_id, pour_mille, mois_debut, mois_fin, motif, accordee_par)
VALUES ('8b000000-0000-4000-8000-0000000000e1', 1000, private.fac_mois_courant(),
        (private.fac_mois_courant() + interval '5 months')::date, 'Bourse de test',
        '8b000000-0000-4000-8000-0000000000a1');
SELECT pg_temp.vrai((SELECT retabli_motif = 'bourse' AND retabli_le IS NOT NULL
                       FROM public.acces_suspensions_paiement
                      WHERE profile_id = '8b000000-0000-4000-8000-0000000000e1')
  AND EXISTS (SELECT 1 FROM public.notifications n
               WHERE n.destinataire = '8b000000-0000-4000-8000-0000000000d1'
                 AND n.evenement = 'acces_retabli_paiement'),
  '4 : la bourse leve la suspension et previent le foyer');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('8b000000-0000-4000-8000-0000000000d1', 'guardian', '8b000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(pg_temp.nb('SELECT 1 FROM public.learning_assignment WHERE id = ''8b000000-0000-4000-8000-0000000000a9''') = 1
  AND pg_temp.nb('SELECT 1 FROM public.library_resource WHERE id = ''8b000000-0000-4000-8000-000000000071''') = 1
  AND pg_temp.nb('SELECT 1 FROM public.session_recordings WHERE id = ''8b000000-0000-4000-8000-000000000601''') = 1,
  '4 : F1 relit le travail, la ressource et l''enregistrement');
SELECT pg_temp.vrai(public.autoriser_lecture_version('8b000000-0000-4000-8000-000000000081') IS NOT NULL,
  '4 : F1 lit de nouveau la ressource');
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM private.com_paires('classe', '8b000000-0000-4000-8000-000000000c01') q
                             WHERE q.a_id = '8b000000-0000-4000-8000-0000000000f1' AND q.b_nature = 'profil'),
  '4 : F1 retrouve le fil avec l''enseignant');
-- Une bourse partielle ne leve rien (le mois reste a payer en partie).
SELECT pg_temp.vrai(pg_catalog.pg_get_functiondef('private.acces_lever_par_bourse()'::regprocedure)
                    LIKE '%pour_mille < 1000%',
  '4 : seule une bourse de 100 % leve la suspension');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 23,
  'au moins 23 controles ont passe (24 avec celui-ci)');
SELECT 'Lot B : scenarios verts' AS resultat;
ROLLBACK;
