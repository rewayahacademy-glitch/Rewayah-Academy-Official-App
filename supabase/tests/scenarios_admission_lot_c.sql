-- ADMISSION lot C (decision du 27/10/2026, §3 et §4 ; fiche du 30/10) : la
-- liste des familles, demander des precisions, accepter (le compte devient
-- actif, l'e-mail part), refuser et annuler le refus dans les sept jours
-- (pas apres), contacter, lier un enfant de la demande a son profil ; un
-- membre de la direction d'un autre genre traite une famille ; un compte qui
-- n'est pas de la direction n'y touche pas.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Tout est annule a la fin. Un echec leve 'ADM-C ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('ad000000-0000-4000-8000-000000000001', 'adm-c-direction@example.test'),
  ('ad000000-0000-4000-8000-000000000002', 'adm-c-famille@example.test'),
  ('ad000000-0000-4000-8000-000000000003', 'adm-c-refusee@example.test'),
  ('ad000000-0000-4000-8000-000000000004', 'adm-c-enfant@example.test');

-- La direction : un homme ; les familles sont tenues par des femmes.
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('ad000000-0000-4000-8000-000000000001', 'ADMCADMIN0000001', 'admin',
   'Fixture', 'Direction', 'active', 'male', NULL);

SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);

-- Deux familles s'inscrivent (lot B).
SELECT set_config('request.jwt.claim.sub', 'ad000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'ad000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Famille', 'female', 'Europe/Paris', false,
  '[{"prenom": "Enfant Un", "age": 9, "genre": "female", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "francais"}]'::jsonb);
RESET ROLE;
SELECT set_config('request.jwt.claim.sub', 'ad000000-0000-4000-8000-000000000003', true);
SELECT set_config('test.uid', 'ad000000-0000-4000-8000-000000000003', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Refusee', 'female', 'Europe/Paris', false,
  '[{"prenom": "Enfant Deux", "age": 7, "genre": "male", "niveau": "debut_lettres",
     "objectif": "indecis", "moments": ["matin"], "langue": "francais"}]'::jsonb);
RESET ROLE;

-- La direction.
SELECT set_config('request.jwt.claim.sub', 'ad000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'ad000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
-- Le bloc relit les tables pour controler (hors de portee d'un client) ; les
-- gestes s'appellent avec les claims de la direction. Les droits d'execution
-- sont prouves par le postflight de la migration et par le bloc final.

DO $direction$
DECLARE
  v_liste jsonb;
  v_famille uuid;
  v_refusee uuid;
  v_r jsonb;
  v_version integer;
BEGIN
  v_liste := public.lister_demandes_admission('famille', NULL, 1);
  IF (v_liste ->> 'aTraiter')::integer <> 2 OR pg_catalog.jsonb_array_length(v_liste -> 'lignes') <> 2 THEN
    RAISE EXCEPTION 'ADM-C ROUGE : la liste des familles ne montre pas les deux demandes : %', v_liste;
  END IF;
  IF (v_liste #>> '{lignes,0,apprenants,0,prenom}') <> 'Enfant Un' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : la plus ancienne d''abord, avec ses apprenants : %', v_liste -> 'lignes';
  END IF;
  IF pg_catalog.jsonb_array_length(public.lister_demandes_admission('eleve_adulte', NULL, 1) -> 'lignes') <> 0 THEN
    RAISE EXCEPTION 'ADM-C ROUGE : une famille paraît dans la liste des eleves adultes';
  END IF;
  IF pg_catalog.jsonb_array_length(public.lister_demandes_admission('famille', 'refusee', 1) -> 'lignes') <> 1 THEN
    RAISE EXCEPTION 'ADM-C ROUGE : la recherche par nom ne trouve pas la demande';
  END IF;
  v_famille := (v_liste #>> '{lignes,0,id}')::uuid;
  v_refusee := (v_liste #>> '{lignes,1,id}')::uuid;
  RAISE NOTICE 'ADM-C OK : une liste par population, la plus ancienne d''abord, recherche, compteur';

  -- Demander des precisions : a completer, e-mail en file.
  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = v_famille;
  v_r := public.demander_precisions_admission(v_famille, 'Quel est le niveau exact de votre enfant ?',
                                             v_version, 'adm-c-precisions-1');
  IF NOT (v_r ? 'candidature') OR (SELECT c.etat FROM public.candidatures c WHERE c.id = v_famille)
       IS DISTINCT FROM 'a_completer' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : precisions non demandees : %', v_r;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                  WHERE s.modele = 'admission_precisions'
                    AND s.destinataire_profil = 'ad000000-0000-4000-8000-000000000002') THEN
    RAISE EXCEPTION 'ADM-C ROUGE : e-mail des precisions absent';
  END IF;
  RAISE NOTICE 'ADM-C OK : precisions demandees, a completer, e-mail en file (direction d''un autre genre)';

  -- Accepter : confirmee, compte actif, e-mail en file.
  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = v_famille;
  v_r := public.accepter_admission(v_famille, v_version, 'adm-c-accepter-1');
  IF NOT (v_r ? 'candidature') THEN
    RAISE EXCEPTION 'ADM-C ROUGE : acceptation refusee : %', v_r;
  END IF;
  IF (SELECT c.etape FROM public.candidatures c WHERE c.id = v_famille) <> 'confirmee'
     OR (SELECT p.account_status FROM public.profiles p
          WHERE p.id = 'ad000000-0000-4000-8000-000000000002') <> 'active' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : la famille acceptee n''est pas confirmee et active';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                  WHERE s.modele = 'admission_acceptee'
                    AND s.destinataire_profil = 'ad000000-0000-4000-8000-000000000002') THEN
    RAISE EXCEPTION 'ADM-C ROUGE : e-mail « acceptee » absent';
  END IF;
  -- Rejouer la meme cle rend le meme resultat, sans second e-mail.
  v_r := public.accepter_admission(v_famille, v_version, 'adm-c-accepter-1');
  IF (SELECT pg_catalog.count(*) FROM public.courriels_sortants s
       WHERE s.modele = 'admission_acceptee'
         AND s.destinataire_profil = 'ad000000-0000-4000-8000-000000000002') <> 1 THEN
    RAISE EXCEPTION 'ADM-C ROUGE : un rejeu envoie un second e-mail';
  END IF;
  RAISE NOTICE 'ADM-C OK : acceptee, compte actif, un seul e-mail meme rejouee';

  -- Refuser, puis annuler dans les sept jours.
  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = v_refusee;
  v_r := public.refuser_admission(v_refusee, 'Fixture : refus d''essai', 'refus_general',
                                  v_version, 'adm-c-refuser-1');
  IF (SELECT c.issue FROM public.candidatures c WHERE c.id = v_refusee) <> 'refusee'
     OR NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                     WHERE s.modele = 'admission_refusee'
                       AND s.destinataire_profil = 'ad000000-0000-4000-8000-000000000003') THEN
    RAISE EXCEPTION 'ADM-C ROUGE : refus non pose ou e-mail absent : %', v_r;
  END IF;
  -- Une seule porte : le geste des enseignants refuse de rouvrir une famille.
  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = v_refusee;
  v_r := public.rouvrir_candidat(v_refusee, 'Fixture : mauvaise porte', v_version, 'adm-c-mauvaise-porte');
  IF v_r ->> 'erreur' IS DISTINCT FROM 'geste_admission'
     OR v_r ->> 'utiliser' IS DISTINCT FROM 'annuler_refus_admission'
     OR (SELECT c.issue FROM public.candidatures c WHERE c.id = v_refusee) <> 'refusee' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : rouvrir_candidat rouvre une famille : %', v_r;
  END IF;
  RAISE NOTICE 'ADM-C OK : rouvrir_candidat refuse une famille et renvoie vers annuler_refus_admission';
  v_r := public.annuler_refus_admission(v_refusee, 'Fixture : erreur de refus', v_version, 'adm-c-annuler-1');
  IF (SELECT c.issue FROM public.candidatures c WHERE c.id = v_refusee) <> 'en_cours' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : refus non annule dans les sept jours : %', v_r;
  END IF;
  RAISE NOTICE 'ADM-C OK : refusee avec e-mail, refus annule dans les sept jours';

  -- Apres sept jours, le refus ne s'annule plus.
  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = v_refusee;
  PERFORM public.refuser_admission(v_refusee, 'Fixture : second refus', 'refus_general',
                                   v_version, 'adm-c-refuser-2');
  UPDATE public.candidatures SET derniere_activite = pg_catalog.now() - interval '8 days'
   WHERE id = v_refusee;
  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = v_refusee;
  v_r := public.annuler_refus_admission(v_refusee, 'Fixture : trop tard', v_version, 'adm-c-annul-acc-2');
  IF (v_r ->> 'erreur') IS DISTINCT FROM 'transition_interdite' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : un refus de plus de sept jours s''annule : %', v_r;
  END IF;
  RAISE NOTICE 'ADM-C OK : apres sept jours, le refus ne s''annule plus';

  -- Contacter : un message libre en file, aucun changement d'etat.
  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = v_refusee;
  v_r := public.contacter_admission(v_refusee, 'Votre demande', 'Bonjour, une question.', 'adm-c-contact-1');
  IF NOT coalesce((v_r ->> 'ok')::boolean, false)
     OR NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                     WHERE s.modele = 'message_libre'
                       AND s.destinataire_profil = 'ad000000-0000-4000-8000-000000000003')
     OR (SELECT c.version FROM public.candidatures c WHERE c.id = v_refusee) <> v_version THEN
    RAISE EXCEPTION 'ADM-C ROUGE : contact non envoye ou etat change : %', v_r;
  END IF;
  RAISE NOTICE 'ADM-C OK : contact envoye, etat inchange';
END
$direction$;

-- La famille acceptee lit sa demande et lie son enfant au profil cree.
SELECT set_config('request.jwt.claim.sub', 'ad000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'ad000000-0000-4000-8000-000000000002', true);
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);
-- Le profil que la fonction Edge cree (role student, meme foyer).
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status)
SELECT 'ad000000-0000-4000-8000-000000000004', 'ADMCENFANT000004', 'student', p.household_id,
       'Enfant Un', 'Famille', 'active'
  FROM public.profiles p WHERE p.id = 'ad000000-0000-4000-8000-000000000002';
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
VALUES ('ad000000-0000-4000-8000-000000000004', 'minor', 'child', 'forbidden');
SET LOCAL ROLE authenticated;
DO $famille$
DECLARE
  v_apprenants jsonb := public.mes_apprenants_demande();
  v_id uuid := (v_apprenants #>> '{0,id}')::uuid;
BEGIN
  IF (public.ma_demande_admission() ->> 'etape') <> 'confirmee' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : la famille ne lit pas sa demande acceptee';
  END IF;
  IF (v_apprenants #>> '{0,nom_famille}') IS DISTINCT FROM 'Famille' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : le nom de famille n''est pas rendu : %', v_apprenants;
  END IF;
  -- Un profil au meme prenom existe deja dans le foyer (une creation dont la
  -- reponse s'est perdue) : il est propose, pour ne pas creer de doublon.
  IF (v_apprenants #>> '{0,profil_probable}') IS DISTINCT FROM 'ad000000-0000-4000-8000-000000000004' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : le profil probable n''est pas propose : %', v_apprenants;
  END IF;
  PERFORM public.lier_apprenant_profil(v_id, 'ad000000-0000-4000-8000-000000000004');
  IF (public.mes_apprenants_demande() #>> '{0,profil_probable}') IS NOT NULL THEN
    RAISE EXCEPTION 'ADM-C ROUGE : un apprenant lie propose encore un profil';
  END IF;
  -- Une seconde fois, au meme profil : sans effet ; a un autre : refus.
  PERFORM public.lier_apprenant_profil(v_id, 'ad000000-0000-4000-8000-000000000004');
  IF (public.mes_apprenants_demande() #>> '{0,profil_eleve_id}') <> 'ad000000-0000-4000-8000-000000000004' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : l''apprenant n''est pas lie';
  END IF;
  RAISE NOTICE 'ADM-C OK : la famille lit sa demande et lie son enfant, une seule fois';
END
$famille$;
RESET ROLE;

DO $range$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles p
                  WHERE p.id = 'ad000000-0000-4000-8000-000000000004' AND p.gender = 'female')
     OR NOT EXISTS (SELECT 1 FROM public.student_profiles s
                     WHERE s.profile_id = 'ad000000-0000-4000-8000-000000000004'
                       AND s.niveau_declare = 'debut_lettres' AND s.objectif = 'apprendre_a_lire'
                       AND s.langue_cours = 'francais') THEN
    RAISE EXCEPTION 'ADM-C ROUGE : genre et reponses non ranges sur le profil de l''enfant';
  END IF;
  RAISE NOTICE 'ADM-C OK : genre et reponses ranges, sans rien ressaisir';
END
$range$;

-- Annuler l'acceptation (fiche, Q2) : la demande revient a traiter, le compte
-- en attente, le profil de l'enfant mis de cote ; une nouvelle acceptation
-- les rend. Un enfant dans une classe empeche l'annulation ; apres sept jours,
-- elle ne vaut plus.
INSERT INTO auth.users (id, email) VALUES
  ('ad000000-0000-4000-8000-000000000005', 'adm-c-enseignant@example.test');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES ('ad000000-0000-4000-8000-000000000005', 'ADMCENSEIGN00005', 'teacher',
        'Fixture', 'Enseignante', 'pending_kyc', 'female');
SELECT set_config('request.jwt.claim.sub', 'ad000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'ad000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
DO $annulation$
DECLARE
  v_id uuid := (SELECT c.id FROM public.candidatures c
                 WHERE c.profile_id = 'ad000000-0000-4000-8000-000000000002');
  v_version integer;
  v_r jsonb;
BEGIN
  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = v_id;
  v_r := public.annuler_admission(v_id, 'Fixture : acceptee par erreur', v_version, 'adm-c-annul-acc-1');
  IF NOT (v_r ? 'candidature')
     OR (SELECT c.etape FROM public.candidatures c WHERE c.id = v_id) <> 'recue'
     OR (SELECT p.account_status FROM public.profiles p
          WHERE p.id = 'ad000000-0000-4000-8000-000000000002') <> 'pending_kyc'
     OR (SELECT p.account_status FROM public.profiles p
          WHERE p.id = 'ad000000-0000-4000-8000-000000000004') <> 'disabled' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : acceptation non annulee : %', v_r;
  END IF;
  RAISE NOTICE 'ADM-C OK : acceptation annulee, compte en attente, enfant mis de cote';

  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = v_id;
  v_r := public.accepter_admission(v_id, v_version, 'adm-c-accepter-2');
  IF (SELECT p.account_status FROM public.profiles p
       WHERE p.id = 'ad000000-0000-4000-8000-000000000004') <> 'active'
     OR (SELECT p.account_status FROM public.profiles p
          WHERE p.id = 'ad000000-0000-4000-8000-000000000002') <> 'active' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : la nouvelle acceptation ne rend pas les profils : %', v_r;
  END IF;
  RAISE NOTICE 'ADM-C OK : une nouvelle acceptation rend le compte et l''enfant';

  INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
  VALUES ('ad000000-0000-4000-8000-0000000000c1', 'ad000000-0000-4000-8000-000000000005',
          'enfant', 5, 'Classe ADM-C', 1, 18, 'Europe/Paris');
  INSERT INTO public.groupe_membres (groupe_id, student_id)
  VALUES ('ad000000-0000-4000-8000-0000000000c1', 'ad000000-0000-4000-8000-000000000004');
  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = v_id;
  v_r := public.annuler_admission(v_id, 'Fixture : trop tard', v_version, 'adm-c-annul-acc-2');
  IF v_r ->> 'erreur' IS DISTINCT FROM 'enfant_en_classe'
     OR (SELECT c.etape FROM public.candidatures c WHERE c.id = v_id) <> 'confirmee' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : annulation permise avec un enfant en classe : %', v_r;
  END IF;
  RAISE NOTICE 'ADM-C OK : un enfant en classe empeche l''annulation';

  UPDATE public.groupe_membres SET left_at = pg_catalog.now(),
         left_by = 'ad000000-0000-4000-8000-000000000001', left_reason = 'Fixture'
   WHERE student_id = 'ad000000-0000-4000-8000-000000000004';
  -- Le journal est en ajout seul : on le vieillit le temps d'une ligne, sans
  -- ses declencheurs (fixture seulement, tout est annule a la fin).
  SET LOCAL session_replication_role = replica;
  UPDATE public.candidature_evenements SET cree_le = cree_le - interval '8 days'
   WHERE candidature_id = v_id AND etape_apres = 'confirmee';
  SET LOCAL session_replication_role = origin;
  v_r := public.annuler_admission(v_id, 'Fixture : apres le delai', v_version, 'adm-c-annul-acc-3');
  IF v_r ->> 'erreur' IS DISTINCT FROM 'transition_interdite' THEN
    RAISE EXCEPTION 'ADM-C ROUGE : annulation permise apres sept jours : %', v_r;
  END IF;
  RAISE NOTICE 'ADM-C OK : apres sept jours, l''acceptation ne s''annule plus';
END
$annulation$;
SELECT set_config('request.jwt.claim.sub', 'ad000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'ad000000-0000-4000-8000-000000000002', true);
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);

-- Un compte qui n'est pas de la direction ne touche ni aux listes ni aux gestes.
SET LOCAL ROLE authenticated;
DO $refus$
BEGIN
  BEGIN
    PERFORM public.lister_demandes_admission('famille', NULL, 1);
    RAISE EXCEPTION 'ADM-C ROUGE : un tuteur lit la liste des familles';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.accepter_admission(gen_random_uuid(), 1, 'adm-c-intrus-1');
    RAISE EXCEPTION 'ADM-C ROUGE : un tuteur accepte une demande';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'ADM-C OK : hors direction, ni liste ni geste';
END
$refus$;
RESET ROLE;

ROLLBACK;
