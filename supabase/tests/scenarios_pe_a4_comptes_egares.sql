-- PE-A4 COMPTES-EGARES (ordre du directeur, 22/11/2026) : un compte famille ou eleve adulte non accepte
-- devient un candidat enseignant, dans l'etat que fabrique inscrire_candidat (lien public) ; la demande est
-- retiree avec son motif, jamais effacee ; le formulaire papier du meme courriel est rattache ; les refus
-- sont nommes et n'ecrivent rien ; l'application par reference est tout ou rien, rejouable, et laisse les
-- references exclues intactes ; aucun role client n'execute la conversion.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations, depuis la racine du depot (le
-- scenario relit le fichier de migration par \i). Fixtures sans donnee personnelle ; tout est annule a la fin.
-- Un echec leve 'PE-A4 ROUGE : ...'.
\set ON_ERROR_STOP 1
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

-- La direction (auteur du lot d'import) ; ses identifiants ne servent qu'aux fixtures.
INSERT INTO auth.users (id, email, email_confirmed_at) VALUES
  ('a4000000-0000-4000-8000-000000000001', 'pea4-direction@example.test', now());
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES ('a4000000-0000-4000-8000-000000000001', 'PEA4ADMIN0000001', 'admin', 'Fixture', 'Direction', 'active', 'male');

-- Un compte famille ou eleve adulte par la vraie porte (inscrire_titulaire), sans session restante.
CREATE FUNCTION pg_temp.inscrire(p_id uuid, p_courriel text, p_usage text, p_genre public.gender)
RETURNS void LANGUAGE plpgsql AS $f$
BEGIN
  INSERT INTO auth.users (id, email, email_confirmed_at) VALUES (p_id, p_courriel, now());
  PERFORM set_config('test.uid', p_id::text, true);
  IF p_usage = 'moi' THEN
    PERFORM public.inscrire_titulaire('moi', 'Fixture', 'Egare', p_genre, 'Europe/Paris', false,
      '[{"est_titulaire": true, "niveau": "lecture_courante", "objectif": "devenir_fluide"}]'::jsonb);
  ELSE
    PERFORM public.inscrire_titulaire('famille', 'Fixture', 'Egare', p_genre, 'Europe/Paris', true,
      '[{"prenom": "Enfant", "age": 9, "genre": "male", "niveau": "debut_lettres", "objectif": "apprendre_a_lire"},
        {"est_titulaire": true, "niveau": "lecture_courante", "objectif": "devenir_fluide"}]'::jsonb);
  END IF;
  PERFORM set_config('test.uid', '', true);
END
$f$;

CREATE FUNCTION pg_temp.refus(p_id uuid, p_attendu text) RETURNS void LANGUAGE plpgsql AS $f$
DECLARE
  v_avant text;
  v_apres text;
BEGIN
  SELECT md5(concat_ws('|', p.role, p.household_id, p.account_status,
           (SELECT string_agg(concat_ws(',', c.type_code, c.etape, c.issue, c.version), ';' ORDER BY c.type_code)
              FROM public.candidatures c WHERE c.profile_id = p.id),
           (SELECT s.deleted_at FROM public.student_profiles s WHERE s.profile_id = p.id)))
    INTO v_avant FROM public.profiles p WHERE p.id = p_id;
  BEGIN
    PERFORM private.convertir_compte_en_candidat_enseignant(p_id, 'motif de test');
    RAISE EXCEPTION 'PE-A4 ROUGE : conversion acceptee, % attendu', p_attendu;
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM <> p_attendu THEN
      RAISE EXCEPTION 'PE-A4 ROUGE : refus « % » au lieu de « % »', SQLERRM, p_attendu;
    END IF;
  END;
  SELECT md5(concat_ws('|', p.role, p.household_id, p.account_status,
           (SELECT string_agg(concat_ws(',', c.type_code, c.etape, c.issue, c.version), ';' ORDER BY c.type_code)
              FROM public.candidatures c WHERE c.profile_id = p.id),
           (SELECT s.deleted_at FROM public.student_profiles s WHERE s.profile_id = p.id)))
    INTO v_apres FROM public.profiles p WHERE p.id = p_id;
  IF v_avant IS DISTINCT FROM v_apres THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : le refus % a laisse une ecriture', p_attendu;
  END IF;
END
$f$;

-- ---------------------------------------------------------------------------
-- 1. Droits : aucun role client n'execute la conversion
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['public', 'anon', 'authenticated', 'service_role'] LOOP
    IF has_function_privilege(v_role, 'private.convertir_compte_en_candidat_enseignant(uuid,text)', 'EXECUTE') THEN
      RAISE EXCEPTION 'PE-A4 ROUGE : % execute la conversion', v_role;
    END IF;
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM pg_proc p
                  WHERE p.oid = 'private.convertir_compte_en_candidat_enseignant(uuid,text)'::regprocedure
                    AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : la conversion n''est pas DEFINER a search_path vide';
  END IF;
END
$droits$;

-- ---------------------------------------------------------------------------
-- 2. Une conversion : eleve adulte, avec un formulaire papier du meme courriel
-- ---------------------------------------------------------------------------
SELECT pg_temp.inscrire('a4000000-0000-4000-8000-000000000010', 'pea4-adulte@example.test', 'moi', 'female');
SELECT pg_temp.inscrire('a4000000-0000-4000-8000-000000000011', 'pea4-famille@example.test', 'famille', 'male');

INSERT INTO public.formulaires_lots (id, cle, auteur_id, classeur, onglet, empreinte, compteurs, rapport)
VALUES ('a4000000-0000-4000-8000-0000000000f0', 'pea4-lot-de-test', 'a4000000-0000-4000-8000-000000000001',
        'Classeur', 'Onglet', md5('pea4'), '{}', '{}');
INSERT INTO public.formulaires_reponses
  (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel, reponses, contenu_empreinte)
VALUES
  -- Meme courriel, meme genre : rattachee.
  ('a4000000-0000-4000-8000-0000000000f1', 'pea4|onglet|1', 'a4000000-0000-4000-8000-0000000000f0',
   now() - interval '30 days', 'female', 'Fixture Egare', 'pea4-adulte@example.test', '{}', md5('f1')),
  -- Courriel voisin (points d'une adresse gmail) : jamais rattachee par le circuit normal.
  ('a4000000-0000-4000-8000-0000000000f2', 'pea4|onglet|2', 'a4000000-0000-4000-8000-0000000000f0',
   now() - interval '30 days', 'male', 'Fixture Egare', 'pea4.fa.mille@example.test', '{}', md5('f2'));

DO $conversion$
DECLARE
  v_res jsonb;
  v_demande public.candidatures;
  v_ens public.candidatures;
  v_p public.profiles;
  v_foyer uuid;
BEGIN
  SELECT p.household_id INTO v_foyer FROM public.profiles p WHERE p.id = 'a4000000-0000-4000-8000-000000000010';
  SELECT c.* INTO v_demande FROM public.candidatures c WHERE c.profile_id = 'a4000000-0000-4000-8000-000000000010';
  IF v_demande.type_code <> 'eleve_adulte' OR v_demande.etape <> 'recue' OR v_foyer IS NULL THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : fixture eleve adulte mal formee';
  END IF;

  v_res := private.convertir_compte_en_candidat_enseignant('a4000000-0000-4000-8000-000000000010',
    'compte enseignant cree par erreur dans l''espace eleve');
  IF NOT (v_res ->> 'formulaireLie')::boolean OR NOT (v_res ->> 'ficheEleveRetiree')::boolean THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : retour inattendu %', v_res;
  END IF;

  -- Le compte : celui d'un candidat inscrit par le lien public.
  SELECT p.* INTO v_p FROM public.profiles p WHERE p.id = 'a4000000-0000-4000-8000-000000000010';
  IF v_p.role <> 'teacher' OR v_p.account_status <> 'pending_kyc' OR v_p.household_id IS NOT NULL
     OR v_p.deleted_at IS NOT NULL
     OR NOT EXISTS (SELECT 1 FROM public.teacher_profiles t WHERE t.profile_id = v_p.id) THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : le compte n''a pas la forme d''un candidat enseignant';
  END IF;
  IF EXISTS (SELECT 1 FROM public.student_profiles s WHERE s.profile_id = v_p.id AND s.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : la fiche eleve du titulaire reste active';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.student_profiles s WHERE s.profile_id = v_p.id) THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : la fiche eleve a disparu';
  END IF;

  -- La candidature enseignant : etape d'entree, contact, evenement creee.
  SELECT c.* INTO v_ens FROM public.candidatures c
   WHERE c.profile_id = v_p.id AND c.type_code = 'enseignant';
  IF v_ens.id IS NULL OR v_ens.etape <> 'prequalification' OR v_ens.etat <> 'a_completer'
     OR v_ens.issue <> 'en_cours' OR v_ens.source <> 'lien_public' OR v_ens.genre <> 'female'
     OR v_ens.nom_complet <> 'Fixture Egare' OR v_ens.reference <> v_res ->> 'candidature' THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : candidature enseignant mal formee';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.candidature_contacts k
                  WHERE k.candidature_id = v_ens.id AND k.courriel = 'pea4-adulte@example.test' AND k.telephone IS NULL)
     OR NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
                     WHERE e.candidature_id = v_ens.id AND e.type = 'creee' AND e.etape_apres = 'prequalification'
                       AND e.details ->> 'depuis' = v_demande.reference) THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : contact ou evenement de creation absent';
  END IF;

  -- La demande : retiree, jamais effacee, motif ecrit ; ses apprenants restent.
  SELECT c.* INTO v_demande FROM public.candidatures c WHERE c.id = v_demande.id;
  IF v_demande.issue <> 'retiree' OR v_demande.etape <> 'recue'
     OR NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
                     WHERE e.candidature_id = v_demande.id AND e.type = 'transition'
                       AND e.issue_avant = 'en_cours' AND e.issue_apres = 'retiree'
                       AND e.motif_interne = 'compte enseignant cree par erreur dans l''espace eleve')
     OR NOT EXISTS (SELECT 1 FROM public.candidature_apprenants a WHERE a.candidature_id = v_demande.id) THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : la demande n''est pas close proprement';
  END IF;

  -- Le foyer reste, sans membre.
  IF NOT EXISTS (SELECT 1 FROM public.households h WHERE h.id = v_foyer)
     OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.household_id = v_foyer) THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : le foyer n''est pas laisse inerte';
  END IF;

  -- Le formulaire papier : rattache comme a l'inscription (cle courriel), journalise.
  IF NOT EXISTS (SELECT 1 FROM public.formulaires_reponses r
                  WHERE r.id = 'a4000000-0000-4000-8000-0000000000f1' AND r.candidature_id = v_ens.id
                    AND r.rattachement = 'courriel' AND r.rattachee_le IS NOT NULL)
     OR NOT EXISTS (SELECT 1 FROM public.formulaires_journal j
                     WHERE j.reponse_id = 'a4000000-0000-4000-8000-0000000000f1' AND j.type = 'rattachement') THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : le formulaire du meme courriel n''est pas rattache';
  END IF;

  -- Le journal d'audit.
  IF NOT EXISTS (SELECT 1 FROM public.audit_logs l
                  WHERE l.action = 'compte_converti_candidat_enseignant' AND l.row_id = v_p.id::text
                    AND l.payload ->> 'demande' = v_demande.reference) THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : la conversion n''est pas journalisee';
  END IF;
END
$conversion$;

-- Une famille (parent qui suit des cours, un enfant declare) ; le courriel voisin n'est pas rattache.
DO $famille$
DECLARE
  v_res jsonb;
BEGIN
  v_res := private.convertir_compte_en_candidat_enseignant('a4000000-0000-4000-8000-000000000011', 'motif famille');
  IF (v_res ->> 'formulaireLie')::boolean THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : un courriel seulement voisin a ete rattache';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.candidatures c JOIN public.profiles p ON p.id = c.profile_id
                  WHERE c.profile_id = 'a4000000-0000-4000-8000-000000000011' AND c.type_code = 'enseignant'
                    AND c.etape = 'prequalification' AND p.role = 'teacher' AND p.household_id IS NULL)
     OR NOT EXISTS (SELECT 1 FROM public.candidatures c
                     WHERE c.profile_id = 'a4000000-0000-4000-8000-000000000011' AND c.type_code = 'famille'
                       AND c.issue = 'retiree') THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : la famille n''est pas convertie';
  END IF;
  IF EXISTS (SELECT 1 FROM public.formulaires_reponses r
              WHERE r.id = 'a4000000-0000-4000-8000-0000000000f2' AND r.candidature_id IS NOT NULL) THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : le formulaire voisin a ete rattache';
  END IF;
END
$famille$;

-- ---------------------------------------------------------------------------
-- 3. Les refus nommes, sans ecriture
-- ---------------------------------------------------------------------------
-- Deja converti : ce n'est plus un compte famille.
SELECT pg_temp.refus('a4000000-0000-4000-8000-000000000010', 'pe_a4_pas_un_compte_famille');
-- Motif vide.
SELECT pg_temp.inscrire('a4000000-0000-4000-8000-000000000020', 'pea4-r1@example.test', 'moi', 'male');
DO $m$ BEGIN
  PERFORM private.convertir_compte_en_candidat_enseignant('a4000000-0000-4000-8000-000000000020', '  ');
  RAISE EXCEPTION 'PE-A4 ROUGE : motif vide accepte';
EXCEPTION WHEN OTHERS THEN
  IF SQLERRM <> 'pe_a4_motif_requis' THEN RAISE EXCEPTION 'PE-A4 ROUGE : motif vide : %', SQLERRM; END IF;
END $m$;
-- Compte introuvable.
DO $m$ BEGIN
  PERFORM private.convertir_compte_en_candidat_enseignant('a4000000-0000-4000-8000-0000000000ee', 'motif');
  RAISE EXCEPTION 'PE-A4 ROUGE : compte introuvable accepte';
EXCEPTION WHEN OTHERS THEN
  IF SQLERRM <> 'pe_a4_compte_introuvable' THEN RAISE EXCEPTION 'PE-A4 ROUGE : introuvable : %', SQLERRM; END IF;
END $m$;
-- Accepte : la demande confirmee et le compte actif.
SELECT pg_temp.inscrire('a4000000-0000-4000-8000-000000000021', 'pea4-r2@example.test', 'moi', 'male');
UPDATE public.candidatures SET etape = 'confirmee' WHERE profile_id = 'a4000000-0000-4000-8000-000000000021';
UPDATE public.profiles SET account_status = 'active' WHERE id = 'a4000000-0000-4000-8000-000000000021';
SELECT pg_temp.refus('a4000000-0000-4000-8000-000000000021', 'pe_a4_compte_accepte');
-- Demande confirmee, compte encore en attente.
SELECT pg_temp.inscrire('a4000000-0000-4000-8000-000000000022', 'pea4-r3@example.test', 'famille', 'female');
UPDATE public.candidatures SET etape = 'confirmee' WHERE profile_id = 'a4000000-0000-4000-8000-000000000022';
SELECT pg_temp.refus('a4000000-0000-4000-8000-000000000022', 'pe_a4_demande_acceptee');
-- Compte retire.
UPDATE public.profiles SET deleted_at = now() WHERE id = 'a4000000-0000-4000-8000-000000000020';
SELECT pg_temp.refus('a4000000-0000-4000-8000-000000000020', 'pe_a4_compte_retire');
-- Un paiement (engagement de prepaiement).
SELECT pg_temp.inscrire('a4000000-0000-4000-8000-000000000023', 'pea4-r4@example.test', 'moi', 'male');
INSERT INTO public.engagements_prepaiement (profile_id, formule, mois_debut, nb_mois, total_mineur, devise)
VALUES ('a4000000-0000-4000-8000-000000000023', 'trimestriel', date_trunc('month', now())::date, 3, 16500, 'USD');
SELECT pg_temp.refus('a4000000-0000-4000-8000-000000000023', 'pe_a4_paiement');
-- Une ligne importee « pour suivi » attend ce courriel.
SELECT pg_temp.inscrire('a4000000-0000-4000-8000-000000000024', 'pea4-r5@example.test', 'moi', 'male');
WITH c AS (
  INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, source, source_ref)
  VALUES ('enseignant', NULL, 'male', 'Fixture Suivie', 'import', 'pea4-suivi-1') RETURNING id)
INSERT INTO public.candidature_contacts (candidature_id, courriel) SELECT id, 'pea4-r5@example.test' FROM c;
SELECT pg_temp.refus('a4000000-0000-4000-8000-000000000024', 'pe_a4_ligne_suivie_existe');
-- Un compte enseignant n'est jamais converti.
SELECT pg_temp.refus('a4000000-0000-4000-8000-000000000001', 'pe_a4_pas_un_compte_famille');

-- ---------------------------------------------------------------------------
-- 4. L'application de la migration : tout ou rien, rejouable, exclues intactes
-- ---------------------------------------------------------------------------
-- Les fixtures ci-dessus ont recu des references de la sequence (CAND-000NN sur une base neuve) :
-- elles passent hors de la plage de l'ordre.
UPDATE public.candidatures c SET reference = 'CAND-8' || lpad(x.n::text, 5, '0')
  FROM (SELECT id, row_number() OVER (ORDER BY id) AS n FROM public.candidatures
         WHERE profile_id::text LIKE 'a4000000-%' OR source_ref = 'pea4-suivi-1') x
 WHERE c.id = x.id;
-- Les references de l'ordre doivent etre libres dans cette base pour monter la fixture.
SELECT NOT EXISTS (
  SELECT 1 FROM public.candidatures c
   WHERE c.reference IN ('CAND-00040', 'CAND-00146', 'CAND-00165', 'CAND-00205', 'CAND-00226', 'CAND-00258',
                         'CAND-00303', 'CAND-00326', 'CAND-00420', 'CAND-00425', 'CAND-00436', 'CAND-00451',
                         'CAND-00463', 'CAND-00478', 'CAND-00481', 'CAND-00492', 'CAND-00554', 'CAND-00617',
                         'CAND-00001', 'CAND-00002', 'CAND-00628', 'CAND-00645')) AS pea4_refs_libres \gset
\if :pea4_refs_libres
-- Les candidatures creees ensuite (fixtures, conversions) prennent des references au-dela de la plage de
-- l'ordre, comme en production (sequence a 648 le 22/11/2026). Sans cela, apres les autres scenarios de la CI,
-- la sequence passe dans la plage et une conversion recevrait une reference deja prise.
SELECT setval('public.candidatures_reference_seq',
              greatest((SELECT last_value FROM public.candidatures_reference_seq), 900000)) \gset pea4_seq_
DO $fixtures$
DECLARE
  v_refs text[] := ARRAY[
    'CAND-00040', 'CAND-00146', 'CAND-00165', 'CAND-00205', 'CAND-00226', 'CAND-00258',
    'CAND-00303', 'CAND-00326', 'CAND-00420', 'CAND-00425', 'CAND-00436', 'CAND-00451',
    'CAND-00463', 'CAND-00478', 'CAND-00481', 'CAND-00492', 'CAND-00554', 'CAND-00617'];
  v_i integer;
  v_id uuid;
BEGIN
  FOR v_i IN 1 .. 18 LOOP
    v_id := ('a4000000-0000-4000-8000-0000000001' || lpad(v_i::text, 2, '0'))::uuid;
    PERFORM pg_temp.inscrire(v_id, 'pea4-ordre-' || v_i || '@example.test',
                             CASE WHEN v_i = 4 THEN 'famille' ELSE 'moi' END, 'male');
    UPDATE public.candidatures SET reference = 'CAND-81' || lpad(v_i::text, 4, '0') WHERE profile_id = v_id;
  END LOOP;
  -- Les 4 exclues : acceptees (actives, confirmees) ou retiree.
  FOR v_i IN 1 .. 4 LOOP
    v_id := ('a4000000-0000-4000-8000-0000000002' || lpad(v_i::text, 2, '0'))::uuid;
    PERFORM pg_temp.inscrire(v_id, 'pea4-exclue-' || v_i || '@example.test',
                             CASE WHEN v_i IN (1, 4) THEN 'famille' ELSE 'moi' END, 'female');
    UPDATE public.candidatures SET etape = 'confirmee', reference = 'CAND-82' || lpad(v_i::text, 4, '0')
     WHERE profile_id = v_id;
    UPDATE public.profiles SET account_status = CASE WHEN v_i = 3 THEN 'disabled' ELSE 'active' END::public.account_status,
           deleted_at = CASE WHEN v_i = 3 THEN now() END
     WHERE id = v_id;
  END LOOP;
  -- Les references de l'ordre, une fois toutes les fixtures creees (la sequence ne les croise plus).
  FOR v_i IN 1 .. 18 LOOP
    UPDATE public.candidatures SET reference = v_refs[v_i] WHERE reference = 'CAND-81' || lpad(v_i::text, 4, '0');
  END LOOP;
  FOR v_i IN 1 .. 4 LOOP
    UPDATE public.candidatures SET reference = (ARRAY['CAND-00001', 'CAND-00002', 'CAND-00628', 'CAND-00645'])[v_i]
     WHERE reference = 'CAND-82' || lpad(v_i::text, 4, '0');
  END LOOP;
END
$fixtures$;

-- Le formulaire papier de CAND-00303 (meme courriel, meme genre) : rattache par l'application.
INSERT INTO public.formulaires_reponses
  (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel, reponses, contenu_empreinte)
VALUES ('a4000000-0000-4000-8000-0000000000f3', 'pea4|onglet|3', 'a4000000-0000-4000-8000-0000000000f0',
        now() - interval '30 days', 'male', 'Fixture Egare', 'pea4-ordre-7@example.test', '{}', md5('f3'));

-- Tout ou rien : l'une des 18 a un paiement, la migration refuse et rien n'est converti.
SAVEPOINT pea4_tout_ou_rien;
INSERT INTO public.engagements_prepaiement (profile_id, formule, mois_debut, nb_mois, total_mineur, devise)
VALUES ('a4000000-0000-4000-8000-000000000118', 'annuel', date_trunc('month', now())::date, 12, 60000, 'USD');
\set ON_ERROR_STOP 0
\i supabase/migrations/20261130984000_pe_a4_comptes_egares.sql
\set pea4_refus :ERROR
\set ON_ERROR_STOP 1
-- Le refus a annule la transaction jusqu'au point de reprise : rien n'est converti.
ROLLBACK TO SAVEPOINT pea4_tout_ou_rien;
\if :pea4_refus
\else
DO $t$ BEGIN RAISE EXCEPTION 'PE-A4 ROUGE : la migration a accepte une liste dont un compte a un paiement'; END $t$;
\endif

-- L'application : les 18 converties, les 4 exclues intactes (postflight de la migration).
\i supabase/migrations/20261130984000_pe_a4_comptes_egares.sql
-- Rejeu : rien ne change.
\i supabase/migrations/20261130984000_pe_a4_comptes_egares.sql
DO $applique$
BEGIN
  IF (SELECT count(*) FROM public.profiles p JOIN public.candidatures c ON c.profile_id = p.id
       WHERE p.id::text LIKE 'a4000000-0000-4000-8000-0000000001%' AND p.role = 'teacher'
         AND c.type_code = 'enseignant' AND c.etape = 'prequalification') <> 18 THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : les 18 ne sont pas convertis une fois chacun';
  END IF;
  IF (SELECT count(*) FROM public.candidatures c
       WHERE c.profile_id::text LIKE 'a4000000-0000-4000-8000-0000000001%' AND c.type_code = 'enseignant') <> 18 THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : le rejeu a cree une candidature de plus';
  END IF;
  IF EXISTS (SELECT 1 FROM public.profiles p WHERE p.id::text LIKE 'a4000000-0000-4000-8000-0000000002%'
              AND p.role <> 'guardian')
     OR EXISTS (SELECT 1 FROM public.candidatures c WHERE c.profile_id::text LIKE 'a4000000-0000-4000-8000-0000000002%'
                 AND (c.type_code = 'enseignant' OR c.issue <> 'en_cours' OR c.etape <> 'confirmee')) THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : une reference exclue a change';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.formulaires_reponses r JOIN public.candidatures c ON c.id = r.candidature_id
                  WHERE r.id = 'a4000000-0000-4000-8000-0000000000f3' AND c.type_code = 'enseignant'
                    AND c.profile_id = 'a4000000-0000-4000-8000-000000000107' AND r.rattachement = 'courriel') THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : le formulaire de CAND-00303 n''est pas rattache par l''application';
  END IF;
  IF (SELECT count(*) FROM public.audit_logs l WHERE l.action = 'compte_converti_candidat_enseignant'
        AND l.row_id LIKE 'a4000000-0000-4000-8000-0000000001%') <> 18 THEN
    RAISE EXCEPTION 'PE-A4 ROUGE : journal d''audit incomplet';
  END IF;
END
$applique$;
\else
\echo 'PE-A4 : references de l''ordre deja prises dans cette base, application non rejouee ici'
\endif

DO $fin$ BEGIN RAISE NOTICE 'PE-A4 VERT : conversion, refus, application tout ou rien et rejeu'; END $fin$;
ROLLBACK;
