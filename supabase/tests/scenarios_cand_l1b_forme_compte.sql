-- CAND-L1B : forme en base du compte candidat (role teacher, statut
-- pending_kyc, fiche teacher_profiles vide), la meme pour le lien public et
-- l'invitation, et son confinement. Migration
-- 20261021220000_cand_l1b_forme_compte_candidat.sql.
--
-- Les sujets, tous de genre feminin, du meme cote que la directrice :
--   A  compte candidat AVEC une candidature (salle 2, decision en attente) ;
--   B  compte candidat SANS candidature (invitation d'avant le module) ;
--   C  enseignante active (temoin), C2 enseignante active sans disponibilite
--      (temoin des remplacements et du jeton) ;
--   D  compte candidat en Salle d'examen (salle 1) ;
--   E  enseignante desactivee qui a encore une classe en cours ; H enseignante
--      desactivee qui n'a plus qu'un historique (classe close, seance annulee).
-- La direction : la directrice (meme cote), un directeur (autre cote), une
-- direction au genre inconnu, un super-admin homme (exception de 0088).
-- A et B naissent par la seule porte qui existe (inscrire_enseignant_invite),
-- puis recoivent "le pire cas" (langue de la classe, fuseau, piece approuvee
-- dans teacher_profiles, disponibilite au creneau de la classe) : seul le
-- statut du compte les separe de C, et chaque refus lui est imputable.
--
-- Chaque controle leve 'CAND-L1B ROUGE : ...' s'il echoue. A rejouer sur une
-- base NEUVE (stub_auth puis toutes les migrations) ; tout est annule a la fin.
-- Contre-epreuve : PGOPTIONS='-c cand_l1b.mode=releve' sur une base sans la
-- migration ; chaque controle rouge est alors note au lieu d'arreter, l'effet
-- d'une ecriture qui aurait du etre refusee est annule, et la fin leve
-- l'exception avec la liste.
-- La concurrence (deux sessions qui se croisent) est prouvee a part :
-- supabase/tests/scenarios_cand_l1b_concurrence.sql.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Un controle rouge : arret (mode normal) ou releve (contre-epreuve).
CREATE FUNCTION pg_temp.rouge(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF coalesce(pg_catalog.current_setting('cand_l1b.mode', true), '') = 'releve' THEN
    PERFORM pg_catalog.set_config('test.rouges',
      coalesce(nullif(pg_catalog.current_setting('test.rouges', true), ''), '') || ' | ' || p_label, true);
    RAISE NOTICE 'ROUGE (releve) %', p_label;
  ELSE
    RAISE EXCEPTION 'CAND-L1B ROUGE : %', p_label;
  END IF;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    PERFORM pg_temp.rouge(p_label);
  ELSE
    PERFORM pg_temp.ok(p_label);
  END IF;
END $$;

-- Refus attendu : SQLSTATE exact, et message exact quand il est donne. Une
-- ecriture qui passe est annulee (sous-transaction), refus ou non.
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_etat text;
  v_msg text;
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'aucun refus' USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_etat = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
  END;
  IF v_etat = 'XX999' THEN
    PERFORM pg_temp.rouge(p_label || ' (aucun refus)');
  ELSIF v_etat <> p_code OR (p_message IS NOT NULL AND v_msg <> p_message) THEN
    PERFORM pg_temp.rouge(pg_catalog.format('%s (%s %s au lieu de %s %s)', p_label, v_etat, v_msg,
                                            p_code, coalesce(p_message, '')));
  ELSE
    PERFORM pg_temp.ok(p_label);
  END IF;
END $$;

-- Ecriture attendue : elle passe et son effet reste.
CREATE FUNCTION pg_temp.passe(p_sql text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_etat text;
  v_msg text;
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_etat = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
  END;
  IF v_etat IS NOT NULL THEN
    PERFORM pg_temp.rouge(pg_catalog.format('%s (refus %s %s)', p_label, v_etat, v_msg));
  ELSE
    PERFORM pg_temp.ok(p_label);
  END IF;
END $$;

-- Ecriture attendue, puis annulee : elle passe, son effet ne reste pas.
CREATE FUNCTION pg_temp.passe_annule(p_sql text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_etat text;
  v_msg text;
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'annule' USING ERRCODE = 'XX998';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_etat = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
  END;
  IF v_etat <> 'XX998' THEN
    PERFORM pg_temp.rouge(pg_catalog.format('%s (refus %s %s)', p_label, v_etat, v_msg));
  ELSE
    PERFORM pg_temp.ok(p_label);
  END IF;
END $$;

-- Les identifiants rendus par une requete.
CREATE FUNCTION pg_temp.ids(p_sql text) RETURNS uuid[]
LANGUAGE plpgsql AS $$
DECLARE v uuid[];
BEGIN
  EXECUTE 'SELECT coalesce(array_agg(x), ''{}'') FROM (' || p_sql || ') q(x)' INTO v;
  RETURN v;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.ok(text), pg_temp.rouge(text),
  pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text, text), pg_temp.passe(text, text),
  pg_temp.passe_annule(text, text), pg_temp.ids(text)
  TO authenticated, anon, service_role, agent_ro;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES
 ('cb1b0000-0000-4000-8000-0000000000a1', 'cand-l1b-direction@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000a2', 'cand-l1b-direction-h@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000a3', 'cand-l1b-direction-x@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000a4', 'cand-l1b-super@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000c5', 'cand-l1b-d@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000c6', 'cand-l1b-e@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000c7', 'cand-l1b-h@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000c1', 'cand-l1b-a@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000c2', 'cand-l1b-b@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000c3', 'cand-l1b-c@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000c4', 'cand-l1b-c2@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000d1', 'cand-l1b-sans-profil@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000e1', 'cand-l1b-tuteur@test.invalid'),
 ('cb1b0000-0000-4000-8000-0000000000e2', 'cand-l1b-eleve@test.invalid');
INSERT INTO public.households (id, timezone)
VALUES ('cb1bffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('cb1b0000-0000-4000-8000-0000000000a1', 'CL1B-ADM-0001', 'admin', NULL, 'Direction', 'Essai', 'active', 'female'),
 ('cb1b0000-0000-4000-8000-0000000000a2', 'CL1B-ADM-0002', 'admin', NULL, 'Direction', 'Autre', 'active', 'male'),
 ('cb1b0000-0000-4000-8000-0000000000a3', 'CL1B-ADM-0003', 'admin', NULL, 'Direction', 'Inconnu', 'active', NULL),
 ('cb1b0000-0000-4000-8000-0000000000a4', 'CL1B-ADM-0004', 'admin', NULL, 'Super', 'Admin', 'active', 'male'),
 ('cb1b0000-0000-4000-8000-0000000000c5', 'CL1B-ENS-0005', 'teacher', NULL, 'Dalia', 'Examen', 'pending_kyc', 'female'),
 ('cb1b0000-0000-4000-8000-0000000000c6', 'CL1B-ENS-0006', 'teacher', NULL, 'Essai', 'Enseigne', 'disabled', 'female'),
 ('cb1b0000-0000-4000-8000-0000000000c7', 'CL1B-ENS-0007', 'teacher', NULL, 'Hiba', 'Historique', 'disabled', 'female'),
 ('cb1b0000-0000-4000-8000-0000000000c3', 'CL1B-ENS-0003', 'teacher', NULL, 'Temoin', 'Active', 'provisional_active', 'female'),
 ('cb1b0000-0000-4000-8000-0000000000c4', 'CL1B-ENS-0004', 'teacher', NULL, 'Temoin', 'Remplacante', 'provisional_active', 'female'),
 ('cb1b0000-0000-4000-8000-0000000000e1', 'CL1B-TUT-0001', 'guardian', 'cb1bffff-ffff-4fff-8fff-000000000001',
  'Tuteur', 'Essai', 'active', 'female'),
 ('cb1b0000-0000-4000-8000-0000000000e2', 'CL1B-ELV-0001', 'student', 'cb1bffff-ffff-4fff-8fff-000000000001',
  'Eleve', 'Essai', 'active', 'female');
UPDATE public.households SET primary_guardian_id = 'cb1b0000-0000-4000-8000-0000000000e1'
 WHERE id = 'cb1bffff-ffff-4fff-8fff-000000000001';
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
VALUES ('cb1b0000-0000-4000-8000-0000000000e2', 'minor', 'child', 'forbidden');
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
VALUES
 ('cb1b0000-0000-4000-8000-0000000000c3', 'France', ARRAY['francais'], 10, 'approved', 'Europe/Paris'),
 ('cb1b0000-0000-4000-8000-0000000000c4', 'France', ARRAY['francais'], 10, 'approved', 'Europe/Paris'),
 ('cb1b0000-0000-4000-8000-0000000000c5', NULL, '{}', 10, 'pending', 'Europe/Paris'),
 ('cb1b0000-0000-4000-8000-0000000000c6', 'France', ARRAY['francais'], 10, 'approved', 'Europe/Paris'),
 ('cb1b0000-0000-4000-8000-0000000000c7', 'France', ARRAY['francais'], 10, 'approved', 'Europe/Paris');
-- Le super-admin : l'exception de 0088, active.
INSERT INTO private.super_admin_kyc (profile_id) VALUES ('cb1b0000-0000-4000-8000-0000000000a4');
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
-- E enseigne encore (classe non close) ; H n'a qu'un historique (classe close,
-- seance annulee).
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public, etat)
VALUES
  ('cb1b0000-0000-4000-8000-000000000102', 'cb1b0000-0000-4000-8000-0000000000c6', 'enfant', 5, 'CL1B classe de E',
   2, 9, 'Europe/Paris', 'femmes', 'active');
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public, etat,
   ended_at, ended_by, end_reason)
VALUES
  ('cb1b0000-0000-4000-8000-000000000103', 'cb1b0000-0000-4000-8000-0000000000c7', 'enfant', 5, 'CL1B classe close de H',
   3, 9, 'Europe/Paris', 'femmes', 'active', now() - interval '30 days', 'cb1b0000-0000-4000-8000-0000000000a1',
   'classe close (fixture)');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type)
VALUES ('cb1b0000-0000-4000-8000-000000000203', 'cb1b0000-0000-4000-8000-0000000000c7',
        now() - interval '40 days', now() - interval '40 days' + interval '1 hour', 'canceled', 'standard');
-- D : candidature en Salle d'examen (posee comme le fera L3).
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, source)
VALUES ('cb1bcccc-0000-4000-8000-000000000004', 'enseignant', 'cb1b0000-0000-4000-8000-0000000000c5',
        'female', 'Dalia Examen', 'prequalification', 'a_completer', 'lien_public');
-- Un type de fixture d'un autre role de compte (spec 1.2 : un type ne touche
-- pas l'autre), pour la branche du changement de type. Sans la colonne
-- role_compte (contre-epreuve), le type nait sans elle.
DO $type$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'public.candidature_types'::regclass
               AND attname = 'role_compte' AND NOT attisdropped) THEN
    EXECUTE $q$INSERT INTO public.candidature_types (code, role_compte) VALUES ('essai_comptable', 'accountant')$q$;
  ELSE
    INSERT INTO public.candidature_types (code) VALUES ('essai_comptable');
  END IF;
END $type$;
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
VALUES ('cb1b0000-0000-4000-8000-0000000000c3', 1, 18, 'Europe/Paris');

-- C et C2 deviennent actives par le chemin reel : contrat, avis et code de
-- conduite signes, puis activation sous la garde 0089.
DO $temoins$
DECLARE
  v_id uuid;
BEGIN
  FOREACH v_id IN ARRAY ARRAY['cb1b0000-0000-4000-8000-0000000000c3',
                              'cb1b0000-0000-4000-8000-0000000000c4']::uuid[] LOOP
    PERFORM pg_temp.qui(v_id, 'teacher');
    PERFORM public.signer_contrat((SELECT version FROM public.contract_texts
                                    WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current),
                                  'Temoin Essai');
    INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
    VALUES (v_id, 'recording_and_control_notice',
            (SELECT version FROM public.contract_required_versions
              WHERE contract_kind = 'recording_and_control_notice')),
           (v_id, 'teacher_conduct_code', public.code_conduite_version_requise());
    UPDATE public.profiles SET account_status = 'active' WHERE id = v_id;
  END LOOP;
  PERFORM pg_temp.qui(NULL, NULL);
END $temoins$;

-- La classe en attente : enfants, public feminin, francais, lundi 18 h Paris.
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
   timezone_iana, langue_code, genre_public, etat)
VALUES
  ('cb1b0000-0000-4000-8000-000000000101', NULL, 'enfant', 5, 'CL1B classe', 1, 18,
   'Europe/Paris', 'francais', 'femmes', 'en_attente_enseignant');
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('cb1b0000-0000-4000-8000-000000000101', 'cb1b0000-0000-4000-8000-0000000000e2');

-- Deux invitations, une par compte candidat.
INSERT INTO public.invitations_enseignant (code, email, cree_par, expire_le) VALUES
 ('CBAA-2345-6789', 'cand-l1b-a@test.invalid', 'cb1b0000-0000-4000-8000-0000000000a1', now() + interval '14 days'),
 ('CBAB-2345-6789', 'cand-l1b-b@test.invalid', 'cb1b0000-0000-4000-8000-0000000000a1', now() + interval '14 days');

-- ------------------------------------------------------------
-- (a) La forme : ce que fabrique la porte de l'invitation
-- ------------------------------------------------------------
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c1', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.inscrire_enseignant_invite('CBAA-2345-6789', 'Amina', 'Candidate', 'female')
                    ->> 'resultat' = 'consommee', 'A : invitation consommee');
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c2', NULL);
SELECT pg_temp.vrai(public.inscrire_enseignant_invite('CBAB-2345-6789', 'Bouchra', 'Ancienne', 'female')
                    ->> 'resultat' = 'consommee', 'B : invitation consommee');
-- La porte publique sans code n'existe pas encore (L3) : creer_profil_inscription
-- refuse toujours le role teacher.
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000d1', NULL);
SELECT pg_temp.refus($$SELECT public.creer_profil_inscription('teacher', 'Sans', 'Code', 'female')$$,
  '23514', 'inscription enseignant sur invitation seulement',
  'aucune porte publique ne fabrique encore un compte candidat sans code (L3)');
RESET ROLE;

SELECT pg_temp.vrai((SELECT count(*) = 2
                       AND bool_and(p.role = 'teacher' AND p.account_status = 'pending_kyc'
                                    AND p.gender = 'female' AND p.deleted_at IS NULL
                                    AND p.access_until IS NULL AND p.household_id IS NULL)
                     FROM public.profiles p
                     WHERE p.id IN ('cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000000c2')),
  'forme : role teacher, statut pending_kyc, genre pose, sans foyer ni echeance');
SELECT pg_temp.vrai((SELECT count(*) = 2
                       AND bool_and(t.kyc_status = 'pending' AND t.languages = '{}'
                                    AND t.country IS NULL AND t.photo_storage_key IS NULL
                                    AND t.titre IS NULL AND t.deleted_at IS NULL)
                     FROM public.teacher_profiles t
                     WHERE t.profile_id IN ('cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000000c2')),
  'forme : fiche teacher_profiles vide (piece en attente, aucune langue, ni pays, ni photo, ni titre)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.weekly_availability
                                WHERE profile_id IN ('cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000000c2'))
  AND NOT EXISTS (SELECT 1 FROM public.kyc_documents
                  WHERE profile_id IN ('cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000000c2'))
  AND NOT EXISTS (SELECT 1 FROM public.contract_acceptances
                  WHERE profile_id IN ('cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000000c2')),
  'forme : aucune disponibilite, aucune piece, aucun accord fabriques a la place de la personne');

-- ------------------------------------------------------------
-- (b) Le lien en base entre candidature et forme du compte
-- ------------------------------------------------------------
-- La candidature de A (posee comme le fera L3), en salle 2.
SELECT pg_temp.passe($$INSERT INTO public.candidatures
  (id, type_code, profile_id, genre, nom_complet, etape, etat, source)
  VALUES ('cb1bcccc-0000-4000-8000-000000000001', 'enseignant', 'cb1b0000-0000-4000-8000-0000000000c1',
          'female', 'Amina Candidate', 'verifications', 'decision_en_attente', 'invitation')$$,
  'candidature enseignant rattachee au compte candidat (teacher, pending_kyc) : acceptee');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, source)
  VALUES ('enseignant', 'cb1b0000-0000-4000-8000-0000000000e1', 'female', 'Tuteur Essai', 'lien_public')$$,
  '23514', 'compte_candidat_role_du_type',
  'candidature enseignant rattachee a un tuteur : refusee');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source)
  VALUES ('enseignant', 'cb1b0000-0000-4000-8000-0000000000c3', 'female', 'Temoin Active', 'prequalification',
          'a_completer', 'lien_public')$$,
  '23514', 'compte_candidat_actif_avant_salle_3',
  'candidature en salle d''examen rattachee a une enseignante active : refusee');
SELECT pg_temp.passe($$INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, source)
  VALUES ('cb1bcccc-0000-4000-8000-000000000003', 'enseignant', 'cb1b0000-0000-4000-8000-0000000000c3', 'female',
          'Temoin Active', 'confirmee', 'invitation')$$,
  'candidature confirmee rattachee a une enseignante active : acceptee (reprise de la salle 3)');
-- La forme candidat ne vaut que jusqu'a la salle 3 : une enseignante confirmee
-- change de role comme tout compte (DECISION-IMMATRICULATION, l. 23).
SELECT pg_temp.passe_annule($$UPDATE public.profiles SET role = 'controller'
  WHERE id = 'cb1b0000-0000-4000-8000-0000000000c3'$$,
  'enseignante confirmee (salle 3) : son role change (controleuse), la regle du role ne la tient plus');
DELETE FROM public.candidatures WHERE id = 'cb1bcccc-0000-4000-8000-000000000003';
-- Un compte qui enseigne encore ne recoit pas de candidature avant la salle 3
-- (F5 cote candidature) ; un historique n'empeche pas de candidater.
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source)
  VALUES ('enseignant', 'cb1b0000-0000-4000-8000-0000000000c6', 'female', 'Essai Enseigne', 'prequalification',
          'a_completer', 'lien_public')$$,
  '23514', 'compte_candidat_non_affectable',
  'E (desactivee, une classe en cours) : candidature rattachee refusee tant que la classe n''est pas reaffectee');
SELECT pg_temp.passe_annule($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source)
  VALUES ('enseignant', 'cb1b0000-0000-4000-8000-0000000000c7', 'female', 'Hiba Historique', 'prequalification',
          'a_completer', 'lien_public')$$,
  'H (classe close, seance annulee : historique seulement) : candidature rattachee acceptee');
-- Branche du changement de type : vers un type d'un autre role de compte.
SELECT pg_temp.refus($$UPDATE public.candidatures SET type_code = 'essai_comptable'
  WHERE id = 'cb1bcccc-0000-4000-8000-000000000001'$$,
  '23514', 'compte_candidat_role_du_type',
  'A : sa candidature changee en un type d''un autre role de compte (accountant) : refuse');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, source)
  VALUES ('enseignant', 'cb1b0000-0000-4000-8000-0000000000c1', 'female', 'Amina Candidate', 'lien_public')$$,
  '23505', NULL, 'deux candidatures du meme type pour un compte : refusees (CAND-L1, unicite)');
UPDATE public.candidatures SET issue = 'refusee' WHERE id = 'cb1bcccc-0000-4000-8000-000000000001';
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, source)
  VALUES ('enseignant', 'cb1b0000-0000-4000-8000-0000000000c1', 'female', 'Amina Candidate', 'lien_public')$$,
  '23505', NULL, 'nouvelle candidature apres un refus : refusee, la premiere se rouvre par geste (L2)');
UPDATE public.candidatures SET issue = 'en_cours' WHERE id = 'cb1bcccc-0000-4000-8000-000000000001';

-- ------------------------------------------------------------
-- Pire cas : A et B ont tout ce que C a, sauf le statut du compte.
-- ------------------------------------------------------------
UPDATE public.teacher_profiles
   SET country = 'France', languages = ARRAY['francais'], weekly_hours_cap = 10,
       kyc_status = 'approved', timezone_iana = 'Europe/Paris'
 WHERE profile_id IN ('cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000000c2');
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana) VALUES
 ('cb1b0000-0000-4000-8000-0000000000c1', 1, 18, 'Europe/Paris'),
 ('cb1b0000-0000-4000-8000-0000000000c2', 1, 18, 'Europe/Paris');

-- ------------------------------------------------------------
-- (c) Permis : accords de l'etape, depot de la piece, son propre etat
-- ------------------------------------------------------------
DO $accords$
DECLARE
  v_id uuid;
  -- Lue avant de prendre le role : contract_required_versions n'est lisible
  -- que par la direction.
  v_avis text := (SELECT version FROM public.contract_required_versions
                   WHERE contract_kind = 'recording_and_control_notice');
BEGIN
  FOREACH v_id IN ARRAY ARRAY['cb1b0000-0000-4000-8000-0000000000c1',
                              'cb1b0000-0000-4000-8000-0000000000c2']::uuid[] LOOP
    PERFORM pg_temp.qui(v_id, 'teacher');
    SET LOCAL ROLE authenticated;
    PERFORM pg_temp.passe($q$SELECT public.signer_contrat((SELECT version FROM public.contract_texts
                                    WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current), 'Nom Saisi')$q$,
      v_id || ' : contrat teacher_nda signe par le compte candidat');
    PERFORM pg_temp.passe(pg_catalog.format($q$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
      VALUES (%L, 'recording_and_control_notice', %L)$q$, v_id, v_avis),
      v_id || ' : avis recording_and_control_notice accepte');
    PERFORM pg_temp.passe(pg_catalog.format($q$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
      VALUES (%L, 'teacher_conduct_code', public.code_conduite_version_requise())$q$, v_id),
      v_id || ' : code de conduite accepte');
    PERFORM pg_temp.passe(pg_catalog.format($q$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
      VALUES (%L, 'passport', %L)$q$, v_id, v_id || '/piece.jpg'),
      v_id || ' : piece deposee par la policy (en attente)');
    RESET ROLE;
  END LOOP;
END $accords$;

SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key, status)
  VALUES ('cb1b0000-0000-4000-8000-0000000000c1', 'passport', 'x/approuvee.jpg', 'approved')$$,
  '42501', 'depot_piece_sans_decision', 'A : piece deposee deja approuvee : refusee');
SELECT pg_temp.refus($$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key, verified_at, verified_by)
  VALUES ('cb1b0000-0000-4000-8000-0000000000c1', 'passport', 'x/verifiee.jpg', now(),
          'cb1b0000-0000-4000-8000-0000000000a1')$$,
  '42501', 'depot_piece_sans_decision', 'A : piece deposee avec verificateur et date : refusee');
SELECT pg_temp.refus($$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key, status, rejection_reason)
  VALUES ('cb1b0000-0000-4000-8000-0000000000c1', 'passport', 'x/refusee.jpg', 'rejected', 'motif')$$,
  '42501', 'depot_piece_sans_decision', 'A : piece deposee deja refusee : refusee');
SELECT pg_temp.vrai(public.peut_deposer_piece_identite('cb1b0000-0000-4000-8000-0000000000c1'),
  'A : la porte du depot R2 s''ouvre au compte candidat (comme kyc_staff_self_insert)');
SELECT pg_temp.vrai(NOT public.peut_deposer_piece_identite('cb1b0000-0000-4000-8000-0000000000c3')
  AND NOT public.peut_deposer_piece_identite('cb1b0000-0000-4000-8000-0000000000e2'),
  'A : la porte du depot R2 reste fermee pour autrui');
SELECT pg_temp.passe($$SELECT public.preparer_depot_piece_identite('cb1b0000-0000-4000-8000-0000000000c1', 'passport')$$,
  'A : reservation R2 de sa piece acceptee');
DO $etat_a$
DECLARE r jsonb := public.etat_dossier();
BEGIN
  PERFORM pg_temp.vrai(r ->> 'role' = 'teacher' AND r ->> 'statut' = 'pending_kyc'
    AND (r ->> 'piece_deposee')::boolean AND r ->> 'piece_statut' = 'pending'
    AND (r ->> 'contrat_signe')::boolean AND (r ->> 'accuse_signe')::boolean
    AND (r ->> 'code_conduite_signe')::boolean,
    'A : etat_dossier() rend son propre etat (pending_kyc, piece en attente, trois accords)');
END $etat_a$;
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c2', 'teacher');
SELECT pg_temp.vrai(public.peut_deposer_piece_identite('cb1b0000-0000-4000-8000-0000000000c2')
  AND public.etat_dossier() ->> 'statut' = 'pending_kyc',
  'B : porte du depot R2 ouverte, etat_dossier() lisible');
-- Le tuteur aussi : un depot n'est jamais une decision.
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000e1', 'guardian');
SELECT pg_catalog.set_config('test.jwt', '{"sub":"cb1b0000-0000-4000-8000-0000000000e1","role":"authenticated","app_metadata":{"role":"guardian","household_id":"cb1bffff-ffff-4fff-8fff-000000000001"}}', true);
SELECT pg_catalog.set_config('request.jwt.claims', current_setting('test.jwt'), true);
SELECT pg_temp.refus($$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key, status)
  VALUES ('cb1b0000-0000-4000-8000-0000000000e2', 'id_card', 'x/enfant.jpg', 'approved')$$,
  '42501', 'depot_piece_sans_decision', 'tuteur : piece de son enfant deposee deja approuvee : refusee');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) = 2 AND bool_and(status = 'pending' AND verified_at IS NULL AND verified_by IS NULL)
                     FROM public.kyc_documents
                     WHERE profile_id IN ('cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000000c2')
                       AND storage_backend = 'supabase'),
  'pieces de A et B : une chacune, en attente, sans decision');

-- La piece se depose en Salle de verification et d'entretien ou apres (spec
-- 2.1) : D, en Salle d'examen, ne la depose par aucune voie.
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c5', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
  VALUES ('cb1b0000-0000-4000-8000-0000000000c5', 'passport', 'c5/piece.jpg')$$,
  '42501', 'depot_piece_hors_etape', 'D (salle d''examen) : piece deposee par la policy : refusee');
SELECT pg_temp.vrai(NOT public.peut_deposer_piece_identite('cb1b0000-0000-4000-8000-0000000000c5'),
  'D (salle d''examen) : la porte du depot R2 reste fermee');
SELECT pg_temp.refus($$SELECT public.preparer_depot_piece_identite('cb1b0000-0000-4000-8000-0000000000c5', 'passport')$$,
  '42501', 'depot refuse pour ce profil', 'D (salle d''examen) : reservation R2 refusee');
RESET ROLE;
SELECT pg_temp.refus($$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
  VALUES ('cb1b0000-0000-4000-8000-0000000000c5', 'passport', 'c5/service.jpg')$$,
  '42501', 'depot_piece_hors_etape', 'D (salle d''examen) : piece posee par la cle de service : refusee');
-- Apres un refus, la porte se ferme aussi pour A.
UPDATE public.candidatures SET issue = 'refusee' WHERE id = 'cb1bcccc-0000-4000-8000-000000000001';
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
  VALUES ('cb1b0000-0000-4000-8000-0000000000c1', 'passport', 'c1/apres-refus.jpg')$$,
  '42501', 'depot_piece_hors_etape', 'A refusee : piece deposee par la policy : refusee');
RESET ROLE;
UPDATE public.candidatures SET issue = 'en_cours' WHERE id = 'cb1bcccc-0000-4000-8000-000000000001';

-- ------------------------------------------------------------
-- (d) Refuse : le jeton de cours
-- ------------------------------------------------------------
-- Une seance de C2 ouverte maintenant ; A y figure comme participante
-- enseignante (une seule par seance, session_participants_one_teacher_uidx).
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, join_opens_at)
VALUES ('cb1b0000-0000-4000-8000-000000000201', 'cb1b0000-0000-4000-8000-0000000000c4',
        clock_timestamp() + interval '10 minutes', clock_timestamp() + interval '70 minutes',
        'planned', 'standard', clock_timestamp() - interval '1 minute');
INSERT INTO public.session_participants (session_id, profile_id, role) VALUES
 ('cb1b0000-0000-4000-8000-000000000201', 'cb1b0000-0000-4000-8000-0000000000c1', 'teacher');
-- Une seance dont B est l'enseignante (B n'a pas de candidature : la base
-- l'accepte) ; la meme pour A est refusee en (f).
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, join_opens_at)
VALUES ('cb1b0000-0000-4000-8000-000000000202', 'cb1b0000-0000-4000-8000-0000000000c2',
        clock_timestamp() + interval '2 days', clock_timestamp() + interval '2 days 1 hour',
        'planned', 'standard', clock_timestamp() - interval '1 minute');

SET LOCAL ROLE service_role;
SELECT pg_temp.vrai(public.autoriser_jeton_video('cb1b0000-0000-4000-8000-000000000201',
  'cb1b0000-0000-4000-8000-0000000000c4', 'wss://x', 'wss://y') ->> 'role' = 'teacher',
  'temoin C2 : jeton enseignant pour sa seance ouverte');
SELECT pg_temp.refus($$SELECT public.autoriser_jeton_video('cb1b0000-0000-4000-8000-000000000201',
  'cb1b0000-0000-4000-8000-0000000000c1', 'wss://x', 'wss://y')$$, '42501', 'compte non valide',
  'A : jeton de cours refuse (compte non valide), meme inscrite a la seance');
SELECT pg_temp.refus($$SELECT public.autoriser_jeton_video('cb1b0000-0000-4000-8000-000000000201',
  'cb1b0000-0000-4000-8000-0000000000c2', 'wss://x', 'wss://y')$$, '42501', 'compte non valide',
  'B : jeton de cours refuse (compte non valide) pour la seance d''une autre');
SELECT pg_temp.refus($$SELECT public.autoriser_jeton_video('cb1b0000-0000-4000-8000-000000000202',
  'cb1b0000-0000-4000-8000-0000000000c2', 'wss://x', 'wss://y')$$, '42501', 'compte non valide',
  'B : jeton refuse meme pour une seance a son nom');
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.video_token_grants
                                WHERE profile_id IN ('cb1b0000-0000-4000-8000-0000000000c1',
                                                     'cb1b0000-0000-4000-8000-0000000000c2')),
  'aucun jeton journalise pour A ni B');

-- ------------------------------------------------------------
-- (e) Absente de toute liste ou recherche d'enseignants
-- ------------------------------------------------------------
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
DO $listes$
DECLARE
  v_a uuid := 'cb1b0000-0000-4000-8000-0000000000c1';
  v_b uuid := 'cb1b0000-0000-4000-8000-0000000000c2';
  v_c uuid := 'cb1b0000-0000-4000-8000-0000000000c3';
  v_c2 uuid := 'cb1b0000-0000-4000-8000-0000000000c4';
  v uuid[];
  r jsonb;
BEGIN
  v := pg_temp.ids($q$SELECT teacher_id FROM public.enseignants_pour_classe('cb1b0000-0000-4000-8000-000000000101')$q$);
  PERFORM pg_temp.vrai(v = ARRAY[v_c], 'enseignants_pour_classe : C seule, ni A ni B (meme langue, genre et creneau)');
  v := pg_temp.ids($q$SELECT teacher_id FROM public.enseignants_pour_public('enfant')$q$);
  PERFORM pg_temp.vrai(v @> ARRAY[v_c, v_c2] AND NOT v && ARRAY[v_a, v_b],
    'enseignants_pour_public : C et C2, ni A ni B');
  v := pg_temp.ids($q$SELECT teacher_id FROM public.enseignants_pour('cb1b0000-0000-4000-8000-0000000000e2')$q$);
  PERFORM pg_temp.vrai(v @> ARRAY[v_c, v_c2] AND NOT v && ARRAY[v_a, v_b],
    'enseignants_pour (attribution manuelle) : C et C2, ni A ni B');
  v := pg_temp.ids($q$SELECT (c ->> 'id')::uuid FROM jsonb_array_elements(public.candidats_cible_tirage() -> 'cibles') c
                      WHERE c ->> 'type' = 'enseignant'$q$);
  PERFORM pg_temp.vrai(v @> ARRAY[v_c, v_c2] AND NOT v && ARRAY[v_a, v_b],
    'candidats_cible_tirage (controle) : C et C2, ni A ni B');
  v := pg_temp.ids($q$SELECT id FROM public.personnes_observables()$q$);
  PERFORM pg_temp.vrai(v @> ARRAY[v_c, v_c2] AND NOT v && ARRAY[v_a, v_b],
    'personnes_observables : C et C2, ni A ni B');
  r := public.pilotage_admin_page(1, 100, 'enfant', 1, 18, 'Europe/Paris', NULL);
  PERFORM pg_temp.vrai((SELECT (g ->> 'libres')::int FROM jsonb_array_elements(r -> 'lignes') l,
                               jsonb_array_elements(l -> 'par_genre') g
                         WHERE l ->> 'id' = 'enfant|1|18|Europe/Paris' AND g ->> 'genre' = 'femmes') = 1,
    'pilotage : une enseignante libre au creneau (C), A et B non comptees malgre leur disponibilite');
  PERFORM pg_temp.vrai((SELECT count(*) = 3 AND bool_and(role = 'teacher' AND etat_compte = 'pending_kyc')
                        FROM public.comptes_admin()
                        WHERE profile_id IN (v_a, v_b, 'cb1b0000-0000-4000-8000-0000000000c5')),
    'comptes_admin (ADM-08, registre des comptes) : A, B et D y sont pour la directrice du meme cote, au statut pending_kyc');
  v := pg_temp.ids($q$SELECT DISTINCT profile_id FROM public.dossiers_en_attente()$q$);
  PERFORM pg_temp.vrai(v @> ARRAY[v_a, v_b] AND NOT v && ARRAY['cb1b0000-0000-4000-8000-0000000000c5']::uuid[],
    'dossiers_en_attente (ADM-02) : A (salle 2) et B y sont pour la directrice du meme cote ; D (salle d''examen) non');
  PERFORM pg_catalog.set_config('test.ind_meme_cote',
    (SELECT i.dossiers_en_attente FROM public.indicateurs_admin() i)::text, true);
  PERFORM pg_temp.vrai(current_setting('test.ind_meme_cote')::int
                       = (SELECT count(DISTINCT d.profile_id)::int FROM public.dossiers_en_attente() d
                          WHERE d.account_status = 'pending_kyc'),
    'indicateurs_admin (ADM-01) : le compteur des dossiers compte ce que la file d''ADM-02 montre');
END $listes$;
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c1', 'teacher');
SELECT pg_temp.refus($$SELECT public.offres_remplacement()$$, '42501', 'RemplacementNonAutorise',
  'A : aucune offre de remplacement');
RESET ROLE;

-- ------------------------------------------------------------
-- (e bis) La direction de l'autre cote ne lit ni n'ecrit un compte candidat
-- ------------------------------------------------------------
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000a2', 'admin');
SET LOCAL ROLE authenticated;
DO $autre_cote$
DECLARE
  v_a uuid := 'cb1b0000-0000-4000-8000-0000000000c1';
  v_b uuid := 'cb1b0000-0000-4000-8000-0000000000c2';
  v_d uuid := 'cb1b0000-0000-4000-8000-0000000000c5';
  v_n integer;
  v_etat text;
  v_msg text;
BEGIN
  PERFORM pg_temp.vrai((public.lister_candidatures('{}'::jsonb, 'recente', 1) ->> 'total')::int = 0,
    'directeur : le module ne lui rend aucune candidature de l''autre cote (CAND-L1)');
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.comptes_admin() WHERE profile_id IN (v_a, v_d))
    AND EXISTS (SELECT 1 FROM public.comptes_admin() WHERE profile_id = v_b),
    'directeur : comptes_admin (ADM-08) ne rend ni A ni D ; B, sans candidature, y reste');
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.dossiers_en_attente() WHERE profile_id = v_a)
    AND EXISTS (SELECT 1 FROM public.dossiers_en_attente() WHERE profile_id = v_b),
    'directeur : la file d''ADM-02 ne rend pas A ; B y reste');
  PERFORM pg_temp.vrai((SELECT i.dossiers_en_attente FROM public.indicateurs_admin() i)
                       = current_setting('test.ind_meme_cote')::int - 1,
    'directeur : le compteur d''ADM-01 ne compte pas A');
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id IN (v_a, v_d))
    AND EXISTS (SELECT 1 FROM public.profiles WHERE id = v_b),
    'directeur : profiles (profiles_admin_all) ne rend ni A ni D');
  -- Une ecriture touche 0 ligne : aucun message ne revele la candidature.
  BEGIN
    UPDATE public.profiles SET account_status = 'provisional_active' WHERE id = v_a;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RAISE EXCEPTION 'annule' USING ERRCODE = 'XX998';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_etat = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
  END;
  PERFORM pg_temp.vrai(v_etat = 'XX998' AND v_n = 0,
    pg_catalog.format('directeur : passer A provisional_active touche 0 ligne, sans message (%s %s)', v_etat, v_msg));
END $autre_cote$;
RESET ROLE;
-- L'agent qui observe le directeur (0014) a le meme plafond.
SET LOCAL ROLE agent_ro;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1')
  AND EXISTS (SELECT 1 FROM public.profiles WHERE id = 'cb1b0000-0000-4000-8000-0000000000c2'),
  'agent qui observe le directeur : profiles ne rend pas A');
RESET ROLE;
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000a3', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.comptes_admin()
                                WHERE profile_id IN ('cb1b0000-0000-4000-8000-0000000000c1',
                                                     'cb1b0000-0000-4000-8000-0000000000c5'))
  AND NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1'),
  'direction au genre inconnu : ni comptes_admin ni profiles ne rendent A ou D');
RESET ROLE;
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000a4', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.comptes_admin()
                     WHERE profile_id IN ('cb1b0000-0000-4000-8000-0000000000c1',
                                          'cb1b0000-0000-4000-8000-0000000000c5')) = 2
  AND EXISTS (SELECT 1 FROM public.profiles WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1'),
  'super-admin de l''autre cote (exception de 0088) : comptes_admin et profiles rendent A et D');
RESET ROLE;
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c2', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c2', 'teacher');
SELECT pg_temp.refus($$SELECT public.offres_remplacement()$$, '42501', 'RemplacementNonAutorise',
  'B : aucune offre de remplacement');
RESET ROLE;

-- ------------------------------------------------------------
-- (f) Refuse : l'affectation, par toute voie
-- ------------------------------------------------------------
SELECT pg_temp.refus($$SELECT public.tc_verifier_affectation_enseignant('cb1b0000-0000-4000-8000-000000000101',
  'cb1b0000-0000-4000-8000-0000000000c1')$$, 'P0001', 'enseignant indisponible ou genre inconnu',
  'A : tc_verifier_affectation_enseignant refuse');
SELECT pg_temp.refus($$SELECT public.tc_verifier_affectation_enseignant('cb1b0000-0000-4000-8000-000000000101',
  'cb1b0000-0000-4000-8000-0000000000c2')$$, 'P0001', 'enseignant indisponible ou genre inconnu',
  'B : tc_verifier_affectation_enseignant refuse');
SELECT pg_temp.refus($$SELECT app_private.verifier_affectation_enseignant('cb1b0000-0000-4000-8000-000000000101',
  'cb1b0000-0000-4000-8000-0000000000c1', false)$$, 'P0001', 'enseignant indisponible ou genre inconnu',
  'A : predicat d''affectation refuse, meme sans exiger les disponibilites');
SELECT pg_temp.passe($$SELECT public.tc_verifier_affectation_enseignant('cb1b0000-0000-4000-8000-000000000101',
  'cb1b0000-0000-4000-8000-0000000000c3')$$, 'temoin C : le predicat accepte');

SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.affecter_enseignant_classe_c11bis('cb1b0000-0000-4000-8000-000000000101',
  'cb1b0000-0000-4000-8000-0000000000c1')$$, 'P0001', 'enseignant indisponible ou genre inconnu',
  'A : affecter_enseignant_classe_c11bis refuse');
SELECT pg_temp.refus($$SELECT public.affecter_enseignant_classe_c11bis('cb1b0000-0000-4000-8000-000000000101',
  'cb1b0000-0000-4000-8000-0000000000c2')$$, 'P0001', 'enseignant indisponible ou genre inconnu',
  'B : affecter_enseignant_classe_c11bis refuse');
SELECT pg_temp.refus($$SELECT public.creer_groupe('cb1b0000-0000-4000-8000-0000000000c1', 'enfant', 'CL1B A',
  2::smallint, 9::smallint, NULL::smallint, 'Europe/Paris', NULL::smallint)$$,
  'P0001', 'cet enseignant n''existe pas ou son compte n''est pas valide', 'A : creer_groupe refuse');
SELECT pg_temp.refus($$SELECT public.creer_groupe('cb1b0000-0000-4000-8000-0000000000c2', 'enfant', 'CL1B B',
  2::smallint, 9::smallint, NULL::smallint, 'Europe/Paris', NULL::smallint)$$,
  'P0001', 'cet enseignant n''existe pas ou son compte n''est pas valide', 'B : creer_groupe refuse');
-- La direction par la table : sessions_admin_all le permet, la base refuse A.
SELECT pg_temp.refus($$INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type)
  VALUES ('cb1b0000-0000-4000-8000-0000000000c1', now() + interval '3 days', now() + interval '3 days 1 hour',
          'planned', 'standard')$$,
  '23514', 'compte_candidat_non_affectable', 'A : seance de cours a son nom posee par la direction : refusee');
RESET ROLE;

-- attribuer_eleve et prendre_eleve sont fermees aux comptes (L3-02) ; leur
-- garde, appelee hors de ce role, refuse A et laisse passer C jusqu'au creneau.
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.refus($$SELECT public.attribuer_eleve('cb1b0000-0000-4000-8000-0000000000e2',
  'cb1b0000-0000-4000-8000-0000000000c1', 1, 18, 'essai')$$,
  'P0001', 'cet enseignant n''existe pas ou son compte n''est pas valide', 'A : attribuer_eleve refuse');
SELECT pg_temp.refus($$SELECT public.attribuer_eleve('cb1b0000-0000-4000-8000-0000000000e2',
  'cb1b0000-0000-4000-8000-0000000000c3', 1, 18, 'essai')$$,
  'P0001', 'ce creneau n''est pas propose par ce foyer', 'temoin C : attribuer_eleve passe la garde du compte');
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c1', 'teacher');
SELECT pg_temp.refus($$SELECT public.prendre_eleve('cb1b0000-0000-4000-8000-0000000000e2', 1, 18)$$,
  'P0001', 'seul un enseignant au compte valide prend un eleve', 'A : prendre_eleve refuse');
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c3', 'teacher');
SELECT pg_temp.refus($$SELECT public.prendre_eleve('cb1b0000-0000-4000-8000-0000000000e2', 1, 18)$$,
  'P0001', 'ce creneau n''est pas propose par ce foyer', 'temoin C : prendre_eleve passe la garde du compte');
SELECT pg_temp.qui(NULL, NULL);

-- Les ecritures directes (cle de service, import) : refusees pour A.
SELECT pg_temp.refus($$UPDATE public.groupes SET teacher_id = 'cb1b0000-0000-4000-8000-0000000000c1', etat = 'active'
  WHERE id = 'cb1b0000-0000-4000-8000-000000000101'$$,
  '23514', 'compte_candidat_non_affectable', 'A : classe posee a son nom par ecriture directe : refusee');
SELECT pg_temp.refus($$INSERT INTO public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
  timezone_iana, genre_public) VALUES ('cb1b0000-0000-4000-8000-0000000000c1', 'enfant', 5, 'CL1B directe', 4, 9,
  'Europe/Paris', 'femmes')$$,
  '23514', 'compte_candidat_non_affectable', 'A : classe creee a son nom par ecriture directe : refusee');
SELECT pg_temp.refus($$INSERT INTO public.teacher_student_assignments (teacher_id, student_id, weekday, hour_local,
  timezone_iana) VALUES ('cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000000e2', 1, 18,
  'Europe/Paris')$$,
  '23514', 'compte_candidat_non_affectable', 'A : affectation individuelle par ecriture directe : refusee');

-- Temoin : C recoit la classe, la famille la voit (carte et recherche de la
-- famille lisent mes_groupes_famille_v).
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.affecter_enseignant_classe_c11bis('cb1b0000-0000-4000-8000-000000000101',
  'cb1b0000-0000-4000-8000-0000000000c3') = 'affecte', 'temoin C : classe affectee par c11bis');
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000e1', 'guardian');
SELECT pg_catalog.set_config('test.jwt', '{"sub":"cb1b0000-0000-4000-8000-0000000000e1","role":"authenticated","app_metadata":{"role":"guardian","household_id":"cb1bffff-ffff-4fff-8fff-000000000001"}}', true);
SELECT pg_catalog.set_config('request.jwt.claims', current_setting('test.jwt'), true);
SELECT pg_temp.vrai(pg_temp.ids($q$SELECT teacher_id FROM public.mes_groupes_famille_v$q$)
                    = ARRAY['cb1b0000-0000-4000-8000-0000000000c3']::uuid[],
  'famille : la carte de l''enseignante est celle de C, aucune de A ni B');
RESET ROLE;

-- ------------------------------------------------------------
-- (g) Refuse : les remplacements
-- ------------------------------------------------------------
SELECT pg_catalog.set_config('test.s1', (SELECT id::text FROM public.sessions
  WHERE groupe_id = 'cb1b0000-0000-4000-8000-000000000101' AND started_at > now()
  ORDER BY started_at LIMIT 1), true);
SELECT pg_temp.vrai(current_setting('test.s1', true) IS NOT NULL
  AND NOT public.remplacement_enseignant_compatible(current_setting('test.s1')::uuid, 'cb1b0000-0000-4000-8000-0000000000c1')
  AND NOT public.remplacement_enseignant_compatible(current_setting('test.s1')::uuid, 'cb1b0000-0000-4000-8000-0000000000c2')
  AND public.remplacement_enseignant_compatible(current_setting('test.s1')::uuid, 'cb1b0000-0000-4000-8000-0000000000c4'),
  'remplacement compatible : C2 oui, ni A ni B');
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus(pg_catalog.format($q$SELECT public.designer_remplacant_admin(%L,
  'cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000003a2')$q$, current_setting('test.s1')),
  '22023', 'RemplacantIncompatible', 'A : designee remplacante par la direction : refusee');
SELECT pg_temp.refus(pg_catalog.format($q$SELECT public.designer_remplacant_admin(%L,
  'cb1b0000-0000-4000-8000-0000000000c2', 'cb1b0000-0000-4000-8000-0000000003a3')$q$, current_setting('test.s1')),
  '22023', 'RemplacantIncompatible', 'B : designee remplacante par la direction : refusee');
RESET ROLE;
INSERT INTO public.remplacements_seance (session_id, evenement, enseignant_titulaire_id, acteur_id, cle_idempotence)
VALUES (current_setting('test.s1')::uuid, 'absence_declaree', 'cb1b0000-0000-4000-8000-0000000000c3',
        'cb1b0000-0000-4000-8000-0000000000c3', 'cb1b0000-0000-4000-8000-0000000003a4');
SELECT pg_temp.vrai((SELECT count(*) FROM public.notifications WHERE evenement = 'remplacement_propose'
                       AND destinataire = 'cb1b0000-0000-4000-8000-0000000000c4') = 1
  AND NOT EXISTS (SELECT 1 FROM public.notifications WHERE evenement = 'remplacement_propose'
                    AND destinataire IN ('cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000000c2')),
  'absence declaree : C2 prevenue, ni A ni B');
SELECT pg_temp.refus(pg_catalog.format($q$INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence)
  VALUES (%L, 'remplacement_designe_admin', 'cb1b0000-0000-4000-8000-0000000000c3',
          'cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000000a1',
          'cb1b0000-0000-4000-8000-0000000003a5')$q$, current_setting('test.s1')),
  '23514', 'compte_candidat_non_affectable', 'A : remplacante par ecriture directe : refusee');

-- Les branches UPDATE des declencheurs (ecritures directes) : une seance et
-- une affectation de C passees au nom de A.
SELECT pg_temp.refus(pg_catalog.format($q$UPDATE public.sessions SET teacher_id = 'cb1b0000-0000-4000-8000-0000000000c1'
  WHERE id = %L$q$, current_setting('test.s1')),
  '23514', 'compte_candidat_non_affectable', 'A : seance de cours de C passee a son nom par ecriture directe : refusee');
INSERT INTO public.teacher_student_assignments (teacher_id, student_id, weekday, hour_local, timezone_iana)
VALUES ('cb1b0000-0000-4000-8000-0000000000c3', 'cb1b0000-0000-4000-8000-0000000000e2', 1, 18, 'Europe/Paris');
SELECT pg_temp.refus($$UPDATE public.teacher_student_assignments SET teacher_id = 'cb1b0000-0000-4000-8000-0000000000c1'
  WHERE teacher_id = 'cb1b0000-0000-4000-8000-0000000000c3' AND ended_at IS NULL$$,
  '23514', 'compte_candidat_non_affectable', 'A : affectation individuelle de C passee a son nom par ecriture directe : refusee');
-- La branche du type de seance : une seance 'entretien' (forme de L4,
-- simulee ici en levant la CHECK du type le temps du controle) changee en
-- seance de cours.
ALTER TABLE public.sessions DROP CONSTRAINT sessions_session_type_check;
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type)
VALUES ('cb1b0000-0000-4000-8000-000000000204', 'cb1b0000-0000-4000-8000-0000000000c1',
        now() + interval '4 days', now() + interval '4 days 1 hour', 'planned', 'entretien');
SELECT pg_temp.refus($$UPDATE public.sessions SET session_type = 'standard'
  WHERE id = 'cb1b0000-0000-4000-8000-000000000204'$$,
  '23514', 'compte_candidat_non_affectable', 'A : sa seance d''entretien changee en seance de cours : refusee');
DELETE FROM public.sessions WHERE id = 'cb1b0000-0000-4000-8000-000000000204';
ALTER TABLE public.sessions ADD CONSTRAINT sessions_session_type_check
  CHECK (session_type = ANY (ARRAY['standard'::text, 'child'::text]));

-- ------------------------------------------------------------
-- (h) Refuse : les prerequis de travail
-- ------------------------------------------------------------
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT SELECT, INSERT ON storage.objects TO authenticated;
INSERT INTO storage.buckets (id, name) VALUES ('photos_enseignants', 'photos_enseignants') ON CONFLICT (id) DO NOTHING;
DO $prerequis$
DECLARE
  v_id uuid;
BEGIN
  FOREACH v_id IN ARRAY ARRAY['cb1b0000-0000-4000-8000-0000000000c1',
                              'cb1b0000-0000-4000-8000-0000000000c2']::uuid[] LOOP
    PERFORM pg_temp.qui(v_id, 'teacher');
    SET LOCAL ROLE authenticated;
    PERFORM pg_temp.refus($q$SELECT public.prerequis_enseignant()$q$, '42501',
      'prerequis reserves a un enseignant actif', v_id || ' : prerequis_enseignant refuse');
    PERFORM pg_temp.refus($q$SELECT public.maj_profil_enseignant('Maroc', ARRAY['arabe'], 'Africa/Casablanca')$q$,
      '42501', 'profil enseignant reserve a un enseignant au compte valide',
      v_id || ' : maj_profil_enseignant (pays, langues, fuseau) refuse');
    PERFORM pg_temp.refus(pg_catalog.format($q$INSERT INTO public.weekly_availability (profile_id, weekday, hour_local,
      timezone_iana) VALUES (%L, 3, 10, 'Europe/Paris')$q$, v_id), '42501', NULL,
      v_id || ' : disponibilite hebdomadaire refusee');
    PERFORM pg_temp.refus(pg_catalog.format($q$INSERT INTO storage.objects (bucket_id, name)
      VALUES ('photos_enseignants', %L)$q$, v_id || '/photo.jpg'), '42501', NULL,
      v_id || ' : photo publique refusee');
    RESET ROLE;
  END LOOP;
END $prerequis$;
SELECT pg_temp.vrai((SELECT count(*) = 2 AND bool_and(country = 'France' AND languages = ARRAY['francais']
                                                       AND timezone_iana = 'Europe/Paris')
                     FROM public.teacher_profiles
                     WHERE profile_id IN ('cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000000c2'))
  AND (SELECT count(*) FROM public.weekly_availability
        WHERE profile_id IN ('cb1b0000-0000-4000-8000-0000000000c1', 'cb1b0000-0000-4000-8000-0000000000c2')) = 2,
  'A et B : fiche et disponibilites inchangees');
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c3', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.passe($$SELECT public.prerequis_enseignant()$$, 'temoin C : prerequis lisibles');
SELECT pg_temp.passe($$SELECT public.maj_profil_enseignant('France', ARRAY['francais'], 'Europe/Paris')$$,
  'temoin C : maj_profil_enseignant accepte');
SELECT pg_temp.passe($$INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
  VALUES ('cb1b0000-0000-4000-8000-0000000000c3', 3, 10, 'Europe/Paris')$$, 'temoin C : disponibilite posee');
SELECT pg_temp.passe($$INSERT INTO storage.objects (bucket_id, name)
  VALUES ('photos_enseignants', 'cb1b0000-0000-4000-8000-0000000000c3/photo.jpg')$$, 'temoin C : photo deposee');
RESET ROLE;

-- ------------------------------------------------------------
-- (i) Refuse : sortir de la forme par soi-meme
-- ------------------------------------------------------------
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000c1', 'teacher');
SET LOCAL ROLE authenticated;
-- provisional_active : la garde 0089 ne joue pas, seule la garde des colonnes
-- privilegiees repond.
SELECT pg_temp.refus($$UPDATE public.profiles SET account_status = 'provisional_active'
  WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1'$$, '42501', NULL, 'A : se passer provisional_active soi-meme : refuse');
SELECT pg_temp.refus($$UPDATE public.profiles SET role = 'admin'
  WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1'$$, '42501', NULL, 'A : changer son role soi-meme : refuse');
-- Aucune policy d'ecriture sur teacher_profiles pour le titulaire : 0 ligne,
-- ou refus du privilege selon les droits de la table.
DO $fiche$
BEGIN
  UPDATE public.teacher_profiles SET weekly_hours_cap = 99
   WHERE profile_id = 'cb1b0000-0000-4000-8000-0000000000c1';
EXCEPTION WHEN insufficient_privilege THEN
  NULL;
END $fiche$;
RESET ROLE;
SELECT pg_temp.vrai((SELECT weekly_hours_cap FROM public.teacher_profiles
                      WHERE profile_id = 'cb1b0000-0000-4000-8000-0000000000c1') = 10
  AND (SELECT account_status FROM public.profiles WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1') = 'pending_kyc',
  'A : aucune ecriture de sa fiche enseignant, statut inchange');

-- ------------------------------------------------------------
-- (j) Refuse : l'activation avant la Salle des prets a enseigner
-- ------------------------------------------------------------
SELECT pg_catalog.set_config('test.piece_a', (SELECT id::text FROM public.kyc_documents
  WHERE profile_id = 'cb1b0000-0000-4000-8000-0000000000c1' AND storage_backend = 'supabase'), true);
SELECT pg_catalog.set_config('test.piece_b', (SELECT id::text FROM public.kyc_documents
  WHERE profile_id = 'cb1b0000-0000-4000-8000-0000000000c2' AND storage_backend = 'supabase'), true);
SELECT pg_temp.qui('cb1b0000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus(pg_catalog.format($q$SELECT public.decider_dossier(%L, true)$q$, current_setting('test.piece_a')),
  '23514', 'compte_candidat_actif_avant_salle_3',
  'A : valider sa piece en salle 2 ne l''active pas (contrats signes : seule la forme refuse)');
SELECT pg_temp.refus($$UPDATE public.profiles SET account_status = 'active'
  WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1'$$, '23514', 'compte_candidat_actif_avant_salle_3',
  'A : la direction la passe active par la table : refuse');
SELECT pg_temp.refus($$UPDATE public.profiles SET account_status = 'provisional_active'
  WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1'$$, '23514', 'compte_candidat_actif_avant_salle_3',
  'A : la direction la passe provisional_active par la table : refuse');
SELECT pg_temp.refus($$UPDATE public.profiles SET role = 'controller'
  WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1'$$, '23514', 'compte_candidat_role_du_type',
  'A : la direction change son role : refuse tant que sa candidature est en cours avant la salle 3');
-- Non-regression : sans candidature, l'approbation de la piece active comme avant.
SELECT pg_temp.passe(pg_catalog.format($q$SELECT public.decider_dossier(%L, true)$q$, current_setting('test.piece_b')),
  'B (sans candidature) : approbation de la piece inchangee');
RESET ROLE;
SELECT pg_temp.vrai((SELECT status FROM public.kyc_documents WHERE id = current_setting('test.piece_a')::uuid) = 'pending'
  AND (SELECT account_status FROM public.profiles WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1') = 'pending_kyc'
  AND (SELECT account_status FROM public.profiles WHERE id = 'cb1b0000-0000-4000-8000-0000000000c2') = 'active',
  'apres coup : piece de A en attente, A pending_kyc ; B active');

-- La transaction d'entree en salle 3 (L2) : l'ordre ne compte pas une fois la
-- verification differee ; un compte actif sans salle 3 reste refuse a la fin.
SELECT pg_temp.refus($o$DO $x$ BEGIN
    SET CONSTRAINTS public.profiles_forme_compte_candidat, public.candidatures_forme_compte DEFERRED;
    UPDATE public.profiles SET account_status = 'active' WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1';
    SET CONSTRAINTS public.profiles_forme_compte_candidat, public.candidatures_forme_compte IMMEDIATE;
  END $x$ $o$, '23514', 'compte_candidat_actif_avant_salle_3',
  'verification differee : activee sans salle 3, refusee au point de controle');
SELECT pg_temp.passe($o$DO $x$ BEGIN
    SET CONSTRAINTS public.profiles_forme_compte_candidat, public.candidatures_forme_compte DEFERRED;
    UPDATE public.profiles SET account_status = 'active' WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1';
    UPDATE public.candidatures SET etape = 'confirmee', etat = NULL WHERE id = 'cb1bcccc-0000-4000-8000-000000000001';
    SET CONSTRAINTS public.profiles_forme_compte_candidat, public.candidatures_forme_compte IMMEDIATE;
  END $x$ $o$, 'verification differee : activation puis salle 3 dans la meme transaction, acceptee');
SELECT pg_temp.vrai((SELECT account_status FROM public.profiles WHERE id = 'cb1b0000-0000-4000-8000-0000000000c1') = 'active'
  AND (SELECT etape FROM public.candidatures WHERE id = 'cb1bcccc-0000-4000-8000-000000000001') = 'confirmee',
  'en salle 3, le compte est actif : la forme candidat ne vaut que jusque-la');
SELECT pg_temp.refus($$UPDATE public.candidatures SET etape = 'verifications', etat = 'decision_en_attente'
  WHERE id = 'cb1bcccc-0000-4000-8000-000000000001'$$, '23514', 'compte_candidat_actif_avant_salle_3',
  'retour d''etape d''un compte actif : refuse');

-- ------------------------------------------------------------
-- (j bis) Le role d'une candidature close ; le retour d'une confirmee qui enseigne
-- ------------------------------------------------------------
UPDATE public.candidatures SET issue = 'refusee' WHERE id = 'cb1bcccc-0000-4000-8000-000000000004';
SELECT pg_temp.refus($$UPDATE public.profiles SET account_status = 'provisional_active'
  WHERE id = 'cb1b0000-0000-4000-8000-0000000000c5'$$, '23514', 'compte_candidat_actif_avant_salle_3',
  'D refusee, toujours enseignante : passage provisional_active refuse (un refus ne fait pas un enseignant)');
SELECT pg_temp.passe_annule($o$DO $x$ BEGIN
    UPDATE public.profiles SET role = 'controller' WHERE id = 'cb1b0000-0000-4000-8000-0000000000c5';
    UPDATE public.profiles SET account_status = 'active' WHERE id = 'cb1b0000-0000-4000-8000-0000000000c5';
  END $x$ $o$, 'D refusee : devient controleuse et active, comme tout compte qui change de role');
SELECT pg_temp.refus($o$DO $x$ BEGIN
    UPDATE public.profiles SET role = 'controller' WHERE id = 'cb1b0000-0000-4000-8000-0000000000c5';
    UPDATE public.candidatures SET issue = 'en_cours' WHERE id = 'cb1bcccc-0000-4000-8000-000000000004';
  END $x$ $o$, '23514', 'compte_candidat_role_du_type',
  'D controleuse : rouvrir sa candidature enseignant est refuse (la regle du role se rejoue)');
UPDATE public.candidatures SET issue = 'en_cours' WHERE id = 'cb1bcccc-0000-4000-8000-000000000004';
-- C a une classe (affectee en f) : confirmee, compte sorti d'active, puis
-- ramenee en salle 2.
SELECT pg_temp.refus($o$DO $x$ BEGIN
    INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, source)
    VALUES ('cb1bcccc-0000-4000-8000-000000000005', 'enseignant', 'cb1b0000-0000-4000-8000-0000000000c3',
            'female', 'Temoin Active', 'confirmee', 'invitation');
    UPDATE public.profiles SET account_status = 'pending_kyc' WHERE id = 'cb1b0000-0000-4000-8000-0000000000c3';
    UPDATE public.candidatures SET etape = 'verifications', etat = 'decision_en_attente'
     WHERE id = 'cb1bcccc-0000-4000-8000-000000000005';
  END $x$ $o$, '23514', 'compte_candidat_non_affectable',
  'C confirmee qui enseigne, compte sorti d''active puis ramenee en salle 2 : refuse');

-- ------------------------------------------------------------
-- (k) Catalogue : objets, droits, empreintes F86
-- ------------------------------------------------------------
DO $catalogue$
DECLARE
  f regprocedure;
  r text;
BEGIN
  PERFORM pg_temp.vrai(EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'public.candidature_types'::regclass
                                 AND attname = 'role_compte' AND attnotnull)
    AND (SELECT count(*) FROM public.candidature_types WHERE code = 'enseignant'
           AND to_jsonb(candidature_types) ->> 'role_compte' = 'teacher') = 1,
    'le type enseignant porte le role du compte : teacher, obligatoire');
  PERFORM pg_temp.vrai((SELECT count(*) FROM pg_trigger t
                        WHERE NOT t.tgisinternal AND t.tgenabled = 'O' AND (
                          (t.tgrelid = 'public.candidatures'::regclass AND t.tgname = 'candidatures_forme_compte'
                             AND t.tgconstraint <> 0 AND t.tgdeferrable AND NOT t.tginitdeferred)
                          OR (t.tgrelid = 'public.profiles'::regclass AND t.tgname = 'profiles_forme_compte_candidat'
                             AND t.tgconstraint <> 0 AND t.tgdeferrable AND NOT t.tginitdeferred)
                          OR (t.tgrelid = 'public.groupes'::regclass AND t.tgname = 'groupes_candidat_non_affectable')
                          OR (t.tgrelid = 'public.sessions'::regclass AND t.tgname = 'sessions_candidat_non_affectable')
                          OR (t.tgrelid = 'public.teacher_student_assignments'::regclass
                              AND t.tgname = 'teacher_student_assignments_candidat_non_affectable')
                          OR (t.tgrelid = 'public.remplacements_seance'::regclass
                              AND t.tgname = 'remplacements_seance_candidat_non_affectable')
                          OR (t.tgrelid = 'public.kyc_documents'::regclass AND t.tgname = 'kyc_documents_depot_etape')
                          OR (t.tgrelid = 'public.kyc_documents'::regclass AND t.tgname = 'kyc_documents_depot_sans_decision'))) = 8,
    'huit declencheurs actifs, les deux de la forme differables et immediats par defaut');
  PERFORM pg_temp.vrai((SELECT pg_get_triggerdef(t.oid) FROM pg_trigger t
                        WHERE t.tgrelid = 'public.candidatures'::regclass AND t.tgname = 'candidatures_forme_compte')
                       LIKE '%UPDATE OF profile_id, etape, type_code, issue%',
    'cote candidature : rattachement, etape, type et issue surveilles');
  FOREACH f IN ARRAY ARRAY[to_regprocedure('public.maj_profil_enseignant(text,text[],text)'),
                           to_regprocedure('public.peut_deposer_piece_identite(uuid)'),
                           to_regprocedure('public.comptes_admin()'),
                           to_regprocedure('public.dossiers_en_attente()'),
                           to_regprocedure('public.indicateurs_admin()')] LOOP
    PERFORM pg_temp.vrai(f IS NOT NULL
      AND (SELECT prosecdef AND pg_get_userbyid(proowner) = 'postgres'
                  AND coalesce(proconfig @> ARRAY['search_path=""'], false) FROM pg_proc WHERE oid = f)
      AND coalesce(obj_description(f, 'pg_proc'), '') LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
      AND coalesce(obj_description(f, 'pg_proc'), '') LIKE '%CAND-L1B%'
      AND NOT app_private.has_unsafe_role_guard((SELECT prosrc FROM pg_proc WHERE oid = f))
      AND has_function_privilege('authenticated', f, 'EXECUTE')
      AND NOT has_function_privilege('anon', f, 'EXECUTE')
      AND NOT has_function_privilege('service_role', f, 'EXECUTE')
      AND NOT has_function_privilege('agent_ro', f, 'EXECUTE'),
      coalesce(f::text, 'fonction absente') || ' : DEFINER postgres, search_path vide, empreinte F86 CAND-L1B, garde positive, authenticated seul');
  END LOOP;
  PERFORM pg_temp.vrai(coalesce((SELECT p.prosecdef AND p.provolatile = 's' AND pg_get_userbyid(p.proowner) = 'postgres'
                                        AND coalesce(p.proconfig @> ARRAY['search_path=""'], false)
                                        AND has_function_privilege('authenticated', p.oid, 'EXECUTE')
                                        AND has_function_privilege('agent_ro', p.oid, 'EXECUTE')
                                        AND NOT has_function_privilege('anon', p.oid, 'EXECUTE')
                                        AND NOT has_function_privilege('service_role', p.oid, 'EXECUTE')
                                 FROM pg_proc p
                                 WHERE p.oid = to_regprocedure('app_private.compte_candidat_hors_portee(uuid)')), false),
    'aide de la policy (app_private, non exposee) : DEFINER STABLE postgres, authenticated et agent_ro seuls');
  PERFORM pg_temp.vrai(EXISTS (SELECT 1 FROM pg_policies
                               WHERE schemaname = 'public' AND tablename = 'profiles'
                                 AND policyname = 'profiles_compte_candidat_portee'
                                 AND permissive = 'RESTRICTIVE' AND cmd = 'ALL'
                                 AND roles @> ARRAY['authenticated', 'agent_ro']::name[]
                                 AND roles <@ ARRAY['authenticated', 'agent_ro']::name[]),
    'policy restrictive de profiles : toutes commandes, authenticated et agent_ro');
  PERFORM pg_temp.vrai((SELECT count(*) FROM pg_proc p
                        WHERE p.oid IN (to_regprocedure('private.candidat_engagement_en_cours(uuid)'),
                                        to_regprocedure('private.candidature_compte_conforme(uuid)'),
                                        to_regprocedure('private.candidature_forme_compte_trg()'),
                                        to_regprocedure('private.profil_forme_compte_candidat_trg()'),
                                        to_regprocedure('private.candidat_non_affectable_trg()'),
                                        to_regprocedure('private.candidature_permet_depot_piece(uuid)'),
                                        to_regprocedure('private.kyc_depot_etape_trg()'),
                                        to_regprocedure('private.kyc_depot_sans_decision_trg()'))
                          AND pg_get_userbyid(p.proowner) = 'postgres'
                          AND coalesce(p.proconfig @> ARRAY['search_path=""'], false)
                          AND NOT has_function_privilege('anon', p.oid, 'EXECUTE')
                          AND NOT has_function_privilege('authenticated', p.oid, 'EXECUTE')
                          AND NOT has_function_privilege('service_role', p.oid, 'EXECUTE')
                          AND NOT has_function_privilege('agent_ro', p.oid, 'EXECUTE')) = 8,
    'huit aides internes : proprietaire postgres, search_path vide, appelables par aucun compte');
  PERFORM pg_temp.vrai((SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace
                          AND proname LIKE 'cand\_%') = 9,
    'aucune aide nouvelle sous le prefixe cand_ de CAND-L1 (son scenario en compte neuf)');
END $catalogue$;

DO $fin$
BEGIN
  IF coalesce(nullif(current_setting('test.rouges', true), ''), '') <> '' THEN
    RAISE EXCEPTION 'CAND-L1B ROUGE (releve) : % controles verts ; rouges :%',
      current_setting('test.n', true), current_setting('test.rouges');
  END IF;
  IF current_setting('test.n')::int <> 132 THEN
    RAISE EXCEPTION 'CAND-L1B ROUGE : % controles executes, 132 attendus', current_setting('test.n');
  END IF;
  RAISE NOTICE 'CAND-L1B forme du compte : % controles verts', current_setting('test.n');
END $fin$;

ROLLBACK;
