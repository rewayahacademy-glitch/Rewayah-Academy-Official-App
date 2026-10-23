-- CPT-SUPPR-EXPORT (18/10/2026) : copie des donnees et demande de suppression
-- du compte. Migration 20261018150000.
--   1. l'export ne contient que les donnees de l'appelant (et, pour un tuteur,
--      celles de son foyer), jamais celles d'un autre foyer ; aucun secret ni
--      note interne ; refus de l'eleve mineur, de la direction, de l'anonyme ;
--   2. la demande : delai lu dans la configuration, une seule en cours, invisible
--      aux autres personnes, annulable, situation (solde, seances a venir) ;
--   3. la direction : lecture, traitement en double verification, delai
--      respecte, seances a venir refusees ;
--   4. l'anonymisation : nom, courriel, genre, photo, coordonnees de paiement,
--      appareils effaces ; matricule et lignes financieres gardes.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL, p_aal text DEFAULT 'aal1')
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object('aal', p_aal)::text
                ELSE pg_catalog.json_build_object('aal', p_aal, 'app_metadata',
                       pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'ROUGE : % (%, % au lieu de %)', p_label, SQLSTATE, SQLERRM, p_code;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid, text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures : direction, deux enseignants (T porte une classe a venir, T2
-- non), deux foyers (G1 et son eleve E1 ; G2 et son eleve E2), un eleve
-- adulte autonome (A1).
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('cd000000-0000-4000-8000-0000000000a1','cd-admin@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000b1','cd-ens1@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000b2','cd-ens2@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000d1','cd-tut1@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000d2','cd-tut2@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000e1','cd-e1@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000e2','cd-e2@test.invalid'),
 ('cd000000-0000-4000-8000-0000000000f1','cd-adulte@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('cd000000-0000-4000-8000-00000000aaf1','Europe/Paris'),
 ('cd000000-0000-4000-8000-00000000aaf2','Europe/Paris'),
 ('cd000000-0000-4000-8000-00000000aaf3','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('cd000000-0000-4000-8000-0000000000a1','CD-ADM-0001','admin',NULL,'Direction','CD','active','female'),
 ('cd000000-0000-4000-8000-0000000000b1','CD-ENS-0001','teacher',NULL,'Maryam','EnseignanteUn','provisional_active','female'),
 ('cd000000-0000-4000-8000-0000000000b2','CD-ENS-0002','teacher',NULL,'Khadija','EnseignanteDeux','provisional_active','female'),
 ('cd000000-0000-4000-8000-0000000000d1','CD-TUT-0001','guardian','cd000000-0000-4000-8000-00000000aaf1','Amina','TuteurUn','active','female'),
 ('cd000000-0000-4000-8000-0000000000d2','CD-TUT-0002','guardian','cd000000-0000-4000-8000-00000000aaf2','Sara','TuteurDeux','active','female'),
 ('cd000000-0000-4000-8000-0000000000e1','CD-ELV-0001','student','cd000000-0000-4000-8000-00000000aaf1','Yasmine','EleveUn','active','female'),
 ('cd000000-0000-4000-8000-0000000000e2','CD-ELV-0002','student','cd000000-0000-4000-8000-00000000aaf2','Bilal','EleveDeux','active','male'),
 ('cd000000-0000-4000-8000-0000000000f1','CD-ELV-0003','student','cd000000-0000-4000-8000-00000000aaf3','Omar','AdulteUn','active','male');
UPDATE public.households SET primary_guardian_id = 'cd000000-0000-4000-8000-0000000000d1'
 WHERE id = 'cd000000-0000-4000-8000-00000000aaf1';
UPDATE public.households SET primary_guardian_id = 'cd000000-0000-4000-8000-0000000000d2'
 WHERE id = 'cd000000-0000-4000-8000-00000000aaf2';
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, objectif, avatar_storage_key) VALUES
 ('cd000000-0000-4000-8000-0000000000e1','minor','child','memoriser','cle/avatar-secret-e1'),
 ('cd000000-0000-4000-8000-0000000000e2','minor','standard','memoriser','cle/avatar-secret-e2'),
 ('cd000000-0000-4000-8000-0000000000f1','autonomous','standard','indecis',NULL);
INSERT INTO public.teacher_profiles(profile_id, country, photo_storage_key, titre) VALUES
 ('cd000000-0000-4000-8000-0000000000b1','FR','cle/photo-secret-t1','sayyida'),
 ('cd000000-0000-4000-8000-0000000000b2','MA','cle/photo-secret-t2','sayyida');

-- Une classe de T avec E1 et une seance a venir ; une classe de T2 avec E2, seances passees.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('cd000000-0000-4000-8000-000000000c01','cd000000-0000-4000-8000-0000000000b1','enfant',5,'Classe CD Un',1,9,'Europe/Paris'),
 ('cd000000-0000-4000-8000-000000000c02','cd000000-0000-4000-8000-0000000000b2','enfant',5,'Classe CD Deux',2,9,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 ('cd000000-0000-4000-8000-000000000c01','cd000000-0000-4000-8000-0000000000e1', now() - interval '30 days'),
 ('cd000000-0000-4000-8000-000000000c02','cd000000-0000-4000-8000-0000000000e2', now() - interval '30 days');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id) VALUES
 ('cd000000-0000-4000-8000-000000000501','cd000000-0000-4000-8000-0000000000b1', now() + interval '3 days', now() + interval '3 days 1 hour', 'planned','cd000000-0000-4000-8000-000000000c01'),
 ('cd000000-0000-4000-8000-000000000502','cd000000-0000-4000-8000-0000000000b1', now() - interval '10 days', now() - interval '10 days' + interval '1 hour', 'ended','cd000000-0000-4000-8000-000000000c01'),
 ('cd000000-0000-4000-8000-000000000601','cd000000-0000-4000-8000-0000000000b2', now() - interval '9 days', now() - interval '9 days' + interval '1 hour', 'ended','cd000000-0000-4000-8000-000000000c02');
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
 ('cd000000-0000-4000-8000-000000000502','cd000000-0000-4000-8000-0000000000e1','student'),
 ('cd000000-0000-4000-8000-000000000601','cd000000-0000-4000-8000-0000000000e2','student');

-- Finance : G1 doit 45 USD ; une facture annulee porte une note interne ; une bourse aussi.
INSERT INTO public.factures_mensuelles(id, profile_id, household_id, mois, politique_version, devise, lignes, total_mineur, statut) VALUES
 ('cd000000-0000-4000-8000-000000000f01','cd000000-0000-4000-8000-0000000000e1','cd000000-0000-4000-8000-00000000aaf1','2026-09-01','v1.0.0','USD','[]',4500,'a_financer'),
 ('cd000000-0000-4000-8000-000000000f02','cd000000-0000-4000-8000-0000000000e2','cd000000-0000-4000-8000-00000000aaf2','2026-09-01','v1.0.0','USD','[]',4500,'a_financer');
INSERT INTO public.factures_mensuelles(id, profile_id, household_id, mois, politique_version, devise, lignes, total_mineur, statut, annulee_le, motif_annulation) VALUES
 ('cd000000-0000-4000-8000-000000000f03','cd000000-0000-4000-8000-0000000000e1','cd000000-0000-4000-8000-00000000aaf1','2026-08-01','v1.0.0','USD','[]',4500,'annulee', now(), 'NOTE-INTERNE-ANNULATION');
INSERT INTO public.bourses_eleves(profile_id, pour_mille, mois_debut, mois_fin, motif, accordee_par) VALUES
 ('cd000000-0000-4000-8000-0000000000e1', 500, '2026-09-01', '2026-12-01', 'NOTE-INTERNE-BOURSE', 'cd000000-0000-4000-8000-0000000000a1');
INSERT INTO public.contract_acceptances(profile_id, contract_kind, version, signer_name) VALUES
 ('cd000000-0000-4000-8000-0000000000d1','guardian_terms','v1','Amina TuteurUn'),
 ('cd000000-0000-4000-8000-0000000000d2','guardian_terms','v1','Sara TuteurDeux');

-- Secrets et traces qui ne doivent jamais sortir.
INSERT INTO public.devices(profile_id, device_fingerprint, platform, token_hash, label) VALUES
 ('cd000000-0000-4000-8000-0000000000e1','EMPREINTE-SECRETE','android','HASH-SECRET-APPAREIL','Tablette de Yasmine');
INSERT INTO public.device_tokens(profile_id, token, platform) VALUES
 ('cd000000-0000-4000-8000-0000000000d1','JETON-PUSH-SECRET','android');
INSERT INTO public.payout_methods(profile_id, kind, details) VALUES
 ('cd000000-0000-4000-8000-0000000000b2','virement','{"iban":"FR76-IBAN-SECRET"}'),
 ('cd000000-0000-4000-8000-0000000000b1','virement','{"iban":"FR76-IBAN-AUTRE"}');
INSERT INTO public.prayer_settings(teacher_id, latitude, longitude, place_label) VALUES
 ('cd000000-0000-4000-8000-0000000000b2', 33.5, -7.6, 'Casablanca');
INSERT INTO public.weekly_availability(profile_id, weekday, hour_local, timezone_iana) VALUES
 ('cd000000-0000-4000-8000-0000000000b2', 1, 10, 'Africa/Casablanca'),
 ('cd000000-0000-4000-8000-0000000000b1', 2, 10, 'Europe/Paris');
INSERT INTO public.kyc_documents(profile_id, doc_type, gender, object_key, status, purge_at) VALUES
 ('cd000000-0000-4000-8000-0000000000b2','passport','female','kyc/CLE-OBJET-SECRETE', 'pending', now() + interval '60 days');
INSERT INTO public.invitations_foyer(foyer_id, email_invite, invite_par, cle_envoi, expire_le) VALUES
 ('cd000000-0000-4000-8000-00000000aaf1','conjoint-tiers@example.com','cd000000-0000-4000-8000-0000000000d1', gen_random_uuid(), now() + interval '7 days');

-- ------------------------------------------------------------------
-- 1. L'export
-- ------------------------------------------------------------------
CREATE TEMP TABLE sortie(nom text PRIMARY KEY, j jsonb);
GRANT ALL ON sortie TO authenticated;

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d1', 'guardian', 'cd000000-0000-4000-8000-00000000aaf1');
INSERT INTO sortie SELECT 'g1', public.mes_donnees_export();
RESET ROLE;

SELECT pg_temp.vrai((SELECT j ->> 'format' = 'rewayah-export-v1'
                         AND j ->> 'perimetre' = 'personne_et_foyer'
                         AND j #>> '{profil,matricule}' = 'CD-TUT-0001'
                         AND j #>> '{profil,courriel}' = 'cd-tut1@test.invalid'
                    FROM sortie WHERE nom = 'g1'),
  'export tuteur : son profil, son matricule et son courriel, perimetre personne et foyer');
SELECT pg_temp.vrai((SELECT jsonb_array_length(j #> '{foyer,eleves}') = 1
                         AND j #>> '{foyer,eleves,0,prenom}' = 'Yasmine'
                         AND jsonb_array_length(j -> 'factures') = 2
                         AND jsonb_array_length(j -> 'classes') = 1
                         AND j -> 'seances' @> '[{"seance_id":"cd000000-0000-4000-8000-000000000502"}]'::jsonb
                         AND jsonb_array_length(j -> 'bourses') = 1
                         AND jsonb_array_length(j -> 'contrats_acceptes') = 1
                    FROM sortie WHERE nom = 'g1'),
  'export tuteur : l''eleve du foyer, ses factures, sa classe, sa seance, sa bourse, le contrat du tuteur');
SELECT pg_temp.vrai((SELECT NOT (j::text ~ 'EleveDeux|TuteurDeux|CD-ELV-0002|CD-TUT-0002|cd-tut2|Classe CD Deux|f02|EnseignanteDeux')
                    FROM sortie WHERE nom = 'g1'),
  'export tuteur : rien d''un autre foyer (ni nom, ni matricule, ni courriel, ni facture, ni classe)');
SELECT pg_temp.vrai((SELECT NOT (j::text ~ 'JETON-PUSH-SECRET|EMPREINTE-SECRETE|HASH-SECRET-APPAREIL|avatar-secret|IBAN|NOTE-INTERNE|CLE-OBJET|photo-secret')
                    FROM sortie WHERE nom = 'g1'),
  'export tuteur : aucun secret (jeton, empreinte, cle de stockage) ni note interne (motifs)');
SELECT pg_temp.vrai((SELECT j #>> '{appareils,0,nom}' = 'Tablette de Yasmine'
                         AND jsonb_array_length(j -> 'appareils_notifications') = 1
                    FROM sortie WHERE nom = 'g1'),
  'export tuteur : les appareils de son foyer, sans empreinte ni jeton');

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000b2', 'teacher');
INSERT INTO sortie SELECT 't2', public.mes_donnees_export();
RESET ROLE;
SELECT pg_temp.vrai((SELECT j ->> 'perimetre' = 'personne'
                         AND j #>> '{profil,matricule}' = 'CD-ENS-0002'
                         AND j #>> '{profil_enseignant,pays}' = 'MA'
                         AND j -> 'foyer' = 'null'::jsonb
                         AND jsonb_array_length(j -> 'disponibilites') = 1
                         AND j #>> '{reglage_priere,lieu}' = 'Casablanca'
                         AND j #>> '{moyens_de_paiement_recus,0,coordonnees_enregistrees}' = 'true'
                         AND jsonb_array_length(j -> 'documents_identite') = 1
                    FROM sortie WHERE nom = 't2'),
  'export enseignant : son profil, ses disponibilites, son lieu de priere, l''existence de ses coordonnees de paiement');
SELECT pg_temp.vrai((SELECT NOT (j::text ~ 'IBAN|CLE-OBJET|photo-secret|EleveUn|TuteurUn|CD-ENS-0001|CD-TUT-0001|Classe CD Un|-7.6')
                    FROM sortie WHERE nom = 't2'),
  'export enseignant : ni coordonnees bancaires, ni cle de piece, ni rien d''une autre personne');

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000f1', 'student');
INSERT INTO sortie SELECT 'adulte', public.mes_donnees_export();
RESET ROLE;
SELECT pg_temp.vrai((SELECT j #>> '{profil,matricule}' = 'CD-ELV-0003' AND j ->> 'perimetre' = 'personne'
                    FROM sortie WHERE nom = 'adulte'),
  'export eleve adulte autonome : sa seule personne');

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000e1', 'student', 'cd000000-0000-4000-8000-00000000aaf1');
SELECT pg_temp.refus($q$SELECT public.mes_donnees_export()$q$, '42501', 'export : l''eleve mineur est refuse (c''est son tuteur qui demande)');
SELECT pg_temp.refus($q$SELECT public.demander_suppression_compte('x')$q$, '42501', 'suppression : l''eleve mineur est refuse');
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal2');
SELECT pg_temp.refus($q$SELECT public.mes_donnees_export()$q$, '42501', 'export : la direction est refusee');
SELECT pg_temp.qui(NULL, NULL);
SELECT pg_temp.refus($q$SELECT public.mes_donnees_export()$q$, '42501', 'export : sans session, refuse');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.refus($q$SELECT public.mes_donnees_export()$q$, '42501', 'anon : export sans EXECUTE');
SELECT pg_temp.refus($q$SELECT public.demander_suppression_compte('x')$q$, '42501', 'anon : demande sans EXECUTE');
SELECT pg_temp.refus($q$SELECT public.annuler_suppression_compte()$q$, '42501', 'anon : annulation sans EXECUTE');
SELECT pg_temp.refus($q$SELECT public.ma_situation_suppression()$q$, '42501', 'anon : situation sans EXECUTE');
SELECT pg_temp.refus($q$SELECT public.demandes_suppression_lister()$q$, '42501', 'anon : liste sans EXECUTE');
SELECT pg_temp.refus($q$SELECT public.traiter_demande_suppression(gen_random_uuid())$q$, '42501', 'anon : traitement sans EXECUTE');
SELECT pg_temp.refus($q$SELECT count(*) FROM public.demandes_suppression_compte$q$, '42501', 'anon : table sans SELECT');
RESET ROLE;

SELECT pg_temp.vrai((SELECT count(*) = 3 FROM public.audit_logs WHERE action = 'export_donnees_personnelles'),
  'journal : chaque export est trace (trois exports reussis, aucun refus)');

-- ------------------------------------------------------------------
-- 2. La demande
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(public.app_config_int('compte.suppression_delai_jours', -1) = 14,
  'configuration : le delai de reflexion existe, 14 jours par defaut');

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d1', 'guardian', 'cd000000-0000-4000-8000-00000000aaf1');
INSERT INTO sortie SELECT 'dem1', public.demander_suppression_compte('  Je pars  ');
SELECT pg_temp.vrai((SELECT j ->> 'statut' = 'en_attente' AND j ->> 'motif' = 'Je pars' AND (j ->> 'delai_jours')::int = 14
                         AND (j ->> 'echeance_le')::timestamptz - (j ->> 'demandee_le')::timestamptz = interval '14 days'
                         AND j #>> '{situation,solde_du}' = 'true'
                         AND j #>> '{situation,montants_dus,0,total_mineur}' = '4500'
                         AND j #>> '{situation,montants_dus,0,devise}' = 'USD'
                         AND (j #>> '{situation,seances_a_venir}')::int >= 1
                    FROM sortie WHERE nom = 'dem1'),
  'demande : en attente, motif nettoye, delai de 14 jours lu en base, solde du et seance a venir signales (la demande reste possible)');
INSERT INTO sortie SELECT 'dem1bis', public.demander_suppression_compte('autre motif');
RESET ROLE;
SELECT pg_temp.vrai((SELECT a.j ->> 'id' = b.j ->> 'id' AND b.j ->> 'motif' = 'Je pars'
                    FROM sortie a, sortie b WHERE a.nom = 'dem1' AND b.nom = 'dem1bis')
  AND (SELECT count(*) = 1 FROM public.demandes_suppression_compte WHERE profile_id = 'cd000000-0000-4000-8000-0000000000d1'),
  'demande : une seule en cours, un second appel rend la meme');

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d2', 'guardian', 'cd000000-0000-4000-8000-00000000aaf2');
SELECT pg_temp.vrai((SELECT count(*) = 0 FROM public.demandes_suppression_compte),
  'RLS : un autre utilisateur ne voit pas ma demande');
SELECT pg_temp.vrai((public.ma_situation_suppression() -> 'demande') = 'null'::jsonb
  AND (public.ma_situation_suppression() ->> 'delai_jours')::int = 14,
  'situation : un autre utilisateur n''a pas de demande');
SELECT pg_temp.refus($q$SELECT public.annuler_suppression_compte()$q$, 'P0002', 'annulation : rien a annuler sans demande');
SELECT pg_temp.refus($q$SELECT public.demander_suppression_compte(repeat('x', 501))$q$, '22023', 'demande : motif trop long refuse');
SELECT pg_temp.refus($q$INSERT INTO public.demandes_suppression_compte(profile_id, role_au_depot, delai_jours, echeance_le) VALUES ('cd000000-0000-4000-8000-0000000000d2','guardian',0,now())$q$,
  '42501', 'ecriture directe : aucune insertion hors de la fonction');
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d1', 'guardian', 'cd000000-0000-4000-8000-00000000aaf1');
SELECT pg_temp.vrai((SELECT count(*) = 1 FROM public.demandes_suppression_compte)
  AND (public.ma_situation_suppression() #>> '{demande,statut}') = 'en_attente',
  'situation : ma demande en cours est lisible par moi');
SELECT pg_temp.refus($q$UPDATE public.demandes_suppression_compte SET statut = 'traitee'$q$, '42501', 'ecriture directe : aucune mise a jour hors des fonctions');
RESET ROLE;

-- La direction lit.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d1', 'guardian', 'cd000000-0000-4000-8000-00000000aaf1');
SELECT pg_temp.refus($q$SELECT public.demandes_suppression_lister()$q$, '42501', 'liste : un tuteur est refuse');
SELECT pg_temp.refus($q$SELECT public.traiter_demande_suppression(gen_random_uuid())$q$, '42501', 'traitement : un tuteur est refuse');
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000a1', 'admin');
INSERT INTO sortie SELECT 'liste1', public.demandes_suppression_lister();
SELECT pg_temp.refus($q$SELECT public.traiter_demande_suppression((SELECT id FROM public.demandes_suppression_compte LIMIT 1))$q$,
  '42501', 'traitement : la direction sans double verification est refusee');
RESET ROLE;
SELECT pg_temp.vrai((SELECT jsonb_array_length(j) = 1 AND j #>> '{0,matricule}' = 'CD-TUT-0001'
                         AND j #>> '{0,prenom}' = 'Amina' AND j #>> '{0,delai_ecoule}' = 'false'
                         AND (j #>> '{0,eleves_du_foyer}')::int = 1
                         AND j #>> '{0,situation,solde_du}' = 'true'
                    FROM sortie WHERE nom = 'liste1'),
  'liste : la direction voit la demande, le matricule, le delai, le foyer, le solde');

-- Annulation, puis nouvelle demande.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d2', 'guardian', 'cd000000-0000-4000-8000-00000000aaf2');
INSERT INTO sortie SELECT 'dem2', public.demander_suppression_compte(NULL);
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d1', 'guardian', 'cd000000-0000-4000-8000-00000000aaf1');
INSERT INTO sortie SELECT 'ann1', public.annuler_suppression_compte();
SELECT pg_temp.refus($q$SELECT public.annuler_suppression_compte()$q$, 'P0002', 'annulation : deux fois, la seconde est refusee');
RESET ROLE;
SELECT pg_temp.vrai((SELECT j ->> 'statut' = 'annulee' AND j ->> 'annulee_le' IS NOT NULL FROM sortie WHERE nom = 'ann1')
  AND (SELECT statut FROM public.demandes_suppression_compte WHERE id = (SELECT (j ->> 'id')::uuid FROM sortie WHERE nom = 'dem1')) = 'annulee'
  AND (SELECT statut FROM public.demandes_suppression_compte WHERE profile_id = 'cd000000-0000-4000-8000-0000000000d2') = 'en_attente',
  'annulation : ma demande est annulee, celle d''un autre reste en attente');

-- Le delai suit la configuration, rien n'est en dur.
UPDATE public.app_config SET value = '3'::jsonb WHERE key = 'compte.suppression_delai_jours';
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d1', 'guardian', 'cd000000-0000-4000-8000-00000000aaf1');
INSERT INTO sortie SELECT 'dem3', public.demander_suppression_compte('Je repars');
RESET ROLE;
SELECT pg_temp.vrai((SELECT (j ->> 'delai_jours')::int = 3
                         AND (j ->> 'echeance_le')::timestamptz - (j ->> 'demandee_le')::timestamptz = interval '3 days'
                    FROM sortie WHERE nom = 'dem3'),
  'configuration : le delai suit la valeur de app_config (3 jours)');
SELECT pg_temp.vrai((SELECT count(*) = 2 FROM public.demandes_suppression_compte WHERE profile_id = 'cd000000-0000-4000-8000-0000000000d1'),
  'trace : l''ancienne demande annulee est gardee, la nouvelle est a cote');

-- ------------------------------------------------------------------
-- 3. Le traitement par la direction
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal2');
SELECT pg_temp.refus($q$SELECT public.traiter_demande_suppression(gen_random_uuid())$q$, 'P0002', 'traitement : demande inconnue');
SELECT pg_temp.refus($q$SELECT public.traiter_demande_suppression((SELECT (j ->> 'id')::uuid FROM sortie WHERE nom = 'dem3'))$q$,
  '55000', 'traitement : refuse tant que le delai de reflexion court');
SELECT pg_temp.refus($q$SELECT public.traiter_demande_suppression((SELECT (j ->> 'id')::uuid FROM sortie WHERE nom = 'dem1'))$q$,
  '55000', 'traitement : une demande annulee ne se traite pas');
RESET ROLE;

-- Le delai est ecoule (on recule les dates de la demande de G1).
UPDATE public.demandes_suppression_compte
   SET demandee_le = now() - interval '5 days', echeance_le = now() - interval '2 days'
 WHERE profile_id = 'cd000000-0000-4000-8000-0000000000d1' AND statut = 'en_attente';

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal2');
SELECT pg_temp.refus($q$SELECT public.traiter_demande_suppression((SELECT (j ->> 'id')::uuid FROM sortie WHERE nom = 'dem3'))$q$,
  '55000', 'traitement : refuse tant qu''une seance a venir existe');
RESET ROLE;

-- La seance a venir est annulee : le traitement passe.
UPDATE public.sessions SET status = 'canceled' WHERE groupe_id = 'cd000000-0000-4000-8000-000000000c01' AND status IN ('planned', 'preflight');
SELECT count(*) AS avant_factures FROM public.factures_mensuelles WHERE household_id = 'cd000000-0000-4000-8000-00000000aaf1' \gset
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal2');
INSERT INTO sortie SELECT 'trait1', public.traiter_demande_suppression(
  (SELECT (j ->> 'id')::uuid FROM sortie WHERE nom = 'dem3'));
RESET ROLE;

SELECT pg_temp.vrai((SELECT j ->> 'statut' = 'traitee' AND j ->> 'traitee_le' IS NOT NULL AND j ->> 'motif' IS NULL
                    FROM sortie WHERE nom = 'trait1'), 'traitement : demande traitee, motif libre efface');
SELECT pg_temp.vrai((SELECT first_name = 'Compte' AND last_name = 'supprimé' AND gender IS NULL
                         AND account_status = 'disabled' AND immutable_id = 'CD-TUT-0001'
                    FROM public.profiles WHERE id = 'cd000000-0000-4000-8000-0000000000d1'),
  'anonymisation : nom et genre effaces, compte desactive, matricule garde (jamais reattribue)');
SELECT pg_temp.vrai((SELECT email = 'efface-cd000000-0000-4000-8000-0000000000d1@invalide.rewayah.invalid'
                    FROM auth.users WHERE id = 'cd000000-0000-4000-8000-0000000000d1'),
  'anonymisation : le courriel de connexion est efface');
SELECT pg_temp.vrai((SELECT count(*) = 0 FROM public.device_tokens WHERE profile_id = 'cd000000-0000-4000-8000-0000000000d1')
  AND (SELECT email_invite NOT LIKE '%example.com' FROM public.invitations_foyer WHERE invite_par = 'cd000000-0000-4000-8000-0000000000d1'),
  'anonymisation : jetons de notification et adresse du tiers invite effaces');
SELECT pg_temp.vrai((SELECT count(*) = :avant_factures FROM public.factures_mensuelles WHERE household_id = 'cd000000-0000-4000-8000-00000000aaf1')
  AND (SELECT count(*) = 1 FROM public.contract_acceptances WHERE profile_id = 'cd000000-0000-4000-8000-0000000000d1')
  AND (SELECT first_name = 'Yasmine' FROM public.profiles WHERE id = 'cd000000-0000-4000-8000-0000000000e1'),
  'conservation : factures du foyer et contrat signe gardes, l''eleve du foyer n''est pas touche');
SELECT pg_temp.vrai((SELECT first_name = 'Sara' FROM public.profiles WHERE id = 'cd000000-0000-4000-8000-0000000000d2')
  AND (SELECT statut = 'en_attente' FROM public.demandes_suppression_compte WHERE profile_id = 'cd000000-0000-4000-8000-0000000000d2'),
  'isolation : un autre compte et sa demande ne sont pas touches');

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal2');
SELECT pg_temp.refus($q$SELECT public.traiter_demande_suppression((SELECT (j ->> 'id')::uuid FROM sortie WHERE nom = 'dem3'))$q$,
  '55000', 'traitement : une demande deja traitee ne se rejoue pas');
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000d1', 'guardian', 'cd000000-0000-4000-8000-00000000aaf1');
SELECT pg_temp.refus($q$SELECT public.mes_donnees_export()$q$, '42501', 'apres anonymisation : le compte efface n''exporte plus');
RESET ROLE;

-- Un enseignant : photo, coordonnees, lieu, disponibilites, piece d'identite.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000b2', 'teacher');
INSERT INTO sortie SELECT 'dem4', public.demander_suppression_compte('Je quitte');
RESET ROLE;
UPDATE public.demandes_suppression_compte
   SET demandee_le = now() - interval '5 days', echeance_le = now() - interval '2 days'
 WHERE profile_id = 'cd000000-0000-4000-8000-0000000000b2';
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal2');
SELECT pg_temp.vrai(((SELECT j FROM sortie WHERE nom = 'dem4') #>> '{situation,seances_a_venir}')::int >= 1,
  'enseignant : les seances a venir de sa classe sont signalees');
SELECT pg_temp.refus($q$SELECT public.traiter_demande_suppression((SELECT (j ->> 'id')::uuid FROM sortie WHERE nom = 'dem4'))$q$,
  '55000', 'traitement : l''enseignant avec des seances a venir est refuse');
RESET ROLE;
UPDATE public.sessions SET status = 'canceled' WHERE groupe_id = 'cd000000-0000-4000-8000-000000000c02' AND status IN ('planned', 'preflight');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('cd000000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal2');
SELECT public.traiter_demande_suppression((SELECT (j ->> 'id')::uuid FROM sortie WHERE nom = 'dem4'));
RESET ROLE;
SELECT pg_temp.vrai((SELECT photo_storage_key IS NULL AND country IS NULL AND titre IS NULL
                    FROM public.teacher_profiles WHERE profile_id = 'cd000000-0000-4000-8000-0000000000b2')
  AND (SELECT details = '{}'::jsonb AND deleted_at IS NOT NULL FROM public.payout_methods WHERE profile_id = 'cd000000-0000-4000-8000-0000000000b2')
  AND (SELECT count(*) = 0 FROM public.prayer_settings WHERE teacher_id = 'cd000000-0000-4000-8000-0000000000b2')
  AND (SELECT count(*) = 0 FROM public.weekly_availability WHERE profile_id = 'cd000000-0000-4000-8000-0000000000b2')
  AND (SELECT purge_at <= clock_timestamp() FROM public.kyc_documents WHERE profile_id = 'cd000000-0000-4000-8000-0000000000b2')
  AND (SELECT first_name = 'Compte' AND immutable_id = 'CD-ENS-0002' FROM public.profiles WHERE id = 'cd000000-0000-4000-8000-0000000000b2')
  AND (SELECT count(*) = 1 FROM public.sessions WHERE teacher_id = 'cd000000-0000-4000-8000-0000000000b2' AND status = 'ended'),
  'anonymisation enseignant : photo, pays, coordonnees, lieu, disponibilites effaces ; piece d''identite a purger ; seances gardees');
SELECT pg_temp.vrai((SELECT first_name = 'Maryam' FROM public.profiles WHERE id = 'cd000000-0000-4000-8000-0000000000b1')
  AND (SELECT details ->> 'iban' = 'FR76-IBAN-AUTRE' FROM public.payout_methods WHERE profile_id = 'cd000000-0000-4000-8000-0000000000b1'),
  'isolation : l''autre enseignant n''est pas touche');

-- La table ne se lit qu'avec RLS : le droit de table est borne.
SELECT pg_temp.vrai(NOT has_table_privilege('anon', 'public.demandes_suppression_compte', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.demandes_suppression_compte', 'INSERT')
  AND has_table_privilege('authenticated', 'public.demandes_suppression_compte', 'SELECT'),
  'droits de table : lecture par RLS seulement, aucune ecriture directe');

\o
SELECT 'CPT-SUPPR-EXPORT : tous les controles sont verts' AS bilan;
ROLLBACK;
