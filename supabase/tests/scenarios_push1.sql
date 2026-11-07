-- PUSH-1 (07/11/2026 ; migrations 20261112000000, 20261112000100,
-- 20261112000200) : les notifications par role et le push.
--
-- Ce que le scenario prouve :
--   1. chaque source manquante cree la bonne notification pour le bon role,
--      avec la bonne destination et le bon geste, et pour personne d'autre
--      (direction expiree ou supprimee : rien ; comptable : la finance
--      seulement) ; le geste se clot quand le serveur le sait ;
--   2. les candidatures ne notifient que quand la direction a un geste a
--      faire (au COMMIT : declencheur differe) ; un import n'en cree aucune ;
--   3. le comptable recoit la finance existante en plus de la direction, une
--      seule copie par ecriture meme avec deux directions ;
--   4. geste_requis etendu (titulaire_en_retard direction seulement,
--      remplacement_avertissement, litige_ouvert comptable) ;
--   5. un echec du notifieur ne bloque jamais le geste metier ET laisse une
--      trace dans private.notifications_echecs (correction 1 du garde-cap) ;
--   6. un compte enfant ne peut pas s'abonner ; un eleve adulte autonome oui ;
--      la RLS de abonnements_push : chacun les siens, sans les cles ;
--   7. la file : push par defaut, exclusions nommees, categorie coupee,
--      sans appareil = rien ; push_reserver rend le nombre regroupe sous
--      l'etiquette ; push_consigner retire un abonnement mort.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PUSH-1 ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$
  SELECT pg_catalog.md5('push1-' || p)::uuid
$$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'aal', 'aal1', 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

-- Le nombre de notifications d'un evenement pour une personne ;
-- avec p_ouvertes : seulement les gestes encore ouverts.
CREATE FUNCTION pg_temp.n(p_qui text, p_evenement text, p_ouvertes boolean DEFAULT false)
RETURNS integer LANGUAGE sql AS $$
  SELECT pg_catalog.count(*)::integer FROM public.notifications n
   WHERE n.destinataire = pg_temp.id(p_qui) AND n.evenement = p_evenement
     AND (NOT p_ouvertes OR (n.geste_requis AND n.geste_fait_le IS NULL AND n.ecartee_le IS NULL))
$$;

CREATE FUNCTION pg_temp.une(p_qui text, p_evenement text)
RETURNS public.notifications LANGUAGE sql AS $$
  SELECT n.* FROM public.notifications n
   WHERE n.destinataire = pg_temp.id(p_qui) AND n.evenement = p_evenement
   ORDER BY n.cree_le DESC LIMIT 1
$$;

-- Cles d'abonnement de forme valide (base64url : 87 et 22 caracteres).
CREATE FUNCTION pg_temp.p256(p text) RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT pg_catalog.rpad('B' || pg_catalog.md5(p), 87, 'x')
$$;
CREATE FUNCTION pg_temp.au(p text) RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT pg_catalog.left(pg_catalog.md5('auth' || p), 22)
$$;

-- ---------------------------------------------------------------------------
-- Fixtures
--   a1, a4 : direction active ; a2 : direction a l'acces expire ;
--   a3 : direction supprimee ; c1 : comptable actif ;
--   p1 : enseignant ; t1 : tuteur du foyer f1 ; e1 : enfant (minor) de f1 ;
--   e2 : eleve adulte autonome.
-- ---------------------------------------------------------------------------
INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'push1-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1', 'a2', 'a3', 'a4', 'c1', 'p1', 'p2', 't1', 't2', 't3', 'e1', 'e2']) AS x;
INSERT INTO public.households (id, timezone) VALUES (pg_temp.id('f1'), 'Europe/Paris'),
                                                   (pg_temp.id('f2'), 'Europe/Paris'), (pg_temp.id('f3'), 'Europe/Paris'), (pg_temp.id('f4'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name,
                             last_name, account_status, gender, access_until, deleted_at)
SELECT pg_temp.id(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NULL THEN NULL ELSE pg_temp.id(x.foyer) END,
       x.prenom, 'Push', x.statut::public.account_status, x.genre::public.gender,
       x.jusqu_au, x.supprime
  FROM (VALUES
    ('a1', 'P1-ADM-0001', 'admin', NULL, 'Direction', 'active', 'female', NULL::timestamptz, NULL::timestamptz),
    ('a2', 'P1-ADM-0002', 'admin', NULL, 'Expiree', 'active', 'female', now() - interval '1 day', NULL),
    ('a3', 'P1-ADM-0003', 'admin', NULL, 'Supprimee', 'active', 'female', NULL, now() - interval '1 day'),
    ('a4', 'P1-ADM-0004', 'admin', NULL, 'Seconde', 'active', 'male', NULL, NULL),
    ('c1', 'P1-CPT-0001', 'accountant', NULL, 'Compta', 'active', 'male', NULL, NULL),
    ('p1', 'P1-ENS-0001', 'teacher', NULL, 'Maryam', 'pending_kyc', 'female', NULL, NULL),
    ('p2', 'P1-ENS-0002', 'teacher', NULL, 'Salma', 'pending_kyc', 'female', NULL, NULL),
    ('t1', 'P1-TUT-0001', 'guardian', 'f1', 'Amina', 'active', 'female', NULL, NULL),
    ('t2', 'P1-TUT-0002', 'guardian', 'f3', 'Candidate', 'pending_kyc', 'female', NULL, NULL),
    ('t3', 'P1-TUT-0003', 'guardian', 'f4', 'Adulte', 'pending_kyc', 'male', NULL, NULL),
    ('e1', 'P1-ELE-0001', 'student', 'f1', 'Yasmine', 'active', 'female', NULL, NULL),
    ('e2', 'P1-ELE-0002', 'student', 'f2', 'Omar', 'active', 'male', NULL, NULL))
    AS x(id, mat, role, foyer, prenom, statut, genre, jusqu_au, supprime);
UPDATE public.households SET primary_guardian_id = pg_temp.id('t1') WHERE id = pg_temp.id('f1');
INSERT INTO public.student_profiles (profile_id, student_type)
VALUES (pg_temp.id('e1'), 'minor'), (pg_temp.id('e2'), 'autonomous');

-- ---------------------------------------------------------------------------
-- 1. Candidatures : famille (au COMMIT), import, enseignant (en_examen).
-- ---------------------------------------------------------------------------
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, source)
VALUES (pg_temp.id('cand-f'), 'famille', pg_temp.id('t2'), 'female', 'Amina Push', 'lien_public');
INSERT INTO public.candidature_apprenants (candidature_id, rang, prenom, age, genre)
VALUES (pg_temp.id('cand-f'), 1, 'Yasmine', 9, 'female');
SELECT pg_temp.vrai(pg_temp.n('a1', 'admission_recue') = 0,
  'admission : rien avant le COMMIT (declencheur differe)');
SET CONSTRAINTS push1_candidature IMMEDIATE;
SELECT pg_temp.vrai(pg_temp.n('a1', 'admission_recue', true) = 1
                    AND pg_temp.n('a4', 'admission_recue', true) = 1,
  'admission famille : chaque direction active a un geste ouvert');
SELECT pg_temp.vrai(pg_temp.n('a2', 'admission_recue') = 0 AND pg_temp.n('a3', 'admission_recue') = 0
                    AND pg_temp.n('c1', 'admission_recue') = 0,
  'admission : ni la direction expiree, ni la supprimee, ni le comptable');
SELECT pg_temp.vrai((pg_temp.une('a1', 'admission_recue')).destination = '/admin/personnes/demandes'
                    AND (pg_temp.une('a1', 'admission_recue')).params ->> 'apprenants' = '1'
                    AND (pg_temp.une('a1', 'admission_recue')).params ->> 'portee' = 'direction'
                    AND NOT ((pg_temp.une('a1', 'admission_recue')).params::text LIKE '%Amina%'
                             OR (pg_temp.une('a1', 'admission_recue')).params::text LIKE '%Yasmine%'),
  'admission : destination, apprenants comptes au COMMIT, aucun nom');
SET CONSTRAINTS push1_candidature DEFERRED;
UPDATE public.candidatures SET etape = 'prequalification', etat = 'a_completer'
 WHERE id = pg_temp.id('cand-f');
SET CONSTRAINTS push1_candidature IMMEDIATE;
SELECT pg_temp.vrai(pg_temp.n('a1', 'admission_recue', true) = 0
                    AND pg_temp.n('a4', 'admission_recue', true) = 0,
  'admission : precisions demandees, le geste est clos pour toute la direction');
SET CONSTRAINTS push1_candidature DEFERRED;

INSERT INTO public.candidatures (id, type_code, genre, nom_complet, source, source_ref)
VALUES (pg_temp.id('cand-i'), 'famille', 'male', 'Import Push', 'import', 'push1-import');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, source)
VALUES (pg_temp.id('cand-e'), 'enseignant', pg_temp.id('p1'), 'female', 'Maryam Push',
        'prequalification', 'a_completer', 'lien_public');
SET CONSTRAINTS push1_candidature IMMEDIATE;
SELECT pg_temp.vrai(pg_temp.n('a1', 'admission_recue') = 1
                    AND pg_temp.n('a1', 'candidature_enseignant_a_examiner') = 0,
  'import : aucune notification ; candidat enseignant a completer : aucune');
SET CONSTRAINTS push1_candidature DEFERRED;
UPDATE public.candidatures SET etat = 'en_examen' WHERE id = pg_temp.id('cand-e');
SET CONSTRAINTS push1_candidature IMMEDIATE;
SELECT pg_temp.vrai(pg_temp.n('a1', 'candidature_enseignant_a_examiner', true) = 1
                    AND (pg_temp.une('a1', 'candidature_enseignant_a_examiner')).destination
                        = '/admin/personnes/candidatures',
  'candidat enseignant : reponses envoyees, la salle d''examen attend la direction');
SET CONSTRAINTS push1_candidature DEFERRED;

-- ---------------------------------------------------------------------------
-- 2. Demande d'horaire, piece, signalement, suppression, creneau.
-- ---------------------------------------------------------------------------
INSERT INTO public.demandes_horaires_famille (id, eleve_id, type_public, langue_code, fuseau_iana,
                                              jours, heures_locales, source)
VALUES (pg_temp.id('dh'), pg_temp.id('e1'), 'enfant', 'francais', 'Europe/Paris', '{2}', '{18}', 'personnalisee');
SELECT pg_temp.vrai(pg_temp.n('a1', 'demande_horaire_recue', true) = 1
                    AND (pg_temp.une('a1', 'demande_horaire_recue')).destination = '/admin/operations/demandes',
  'demande d''horaire : geste de la direction');
UPDATE public.demandes_horaires_famille SET etat = 'refusee', motif = 'test' WHERE id = pg_temp.id('dh');
SELECT pg_temp.vrai(pg_temp.n('a1', 'demande_horaire_recue', true) = 0,
  'demande d''horaire traitee : geste clos');

INSERT INTO public.kyc_documents (id, profile_id, doc_type, gender, object_key)
VALUES (pg_temp.id('kyc'), pg_temp.id('p2'), 'passport', 'female', 'kyc/push1');
SELECT pg_temp.vrai(pg_temp.n('a1', 'piece_identite_deposee', true) = 1
                    AND (pg_temp.une('a1', 'piece_identite_deposee')).destination = '/admin/personnes/dossiers',
  'piece deposee : geste de la direction, vers les dossiers');
UPDATE public.kyc_documents SET status = 'approved', verified_by = pg_temp.id('a1'), verified_at = now()
 WHERE id = pg_temp.id('kyc');
SELECT pg_temp.vrai(pg_temp.n('a1', 'piece_identite_deposee', true) = 0,
  'piece verifiee : geste clos');

INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES (pg_temp.id('g'), pg_temp.id('p2'), 'enfant', 5, 'Classe PUSH1', 1, 18, 'Europe/Paris');
INSERT INTO public.student_concern (id, categorie, groupe_id, student_id, teacher_id, internal_details)
SELECT pg_temp.id('sc'), (pg_catalog.enum_range(NULL::public.concern_category))[1],
       pg_temp.id('g'), pg_temp.id('e1'), pg_temp.id('p2'), 'note interne de test';
SELECT pg_temp.vrai(pg_temp.n('a1', 'signalement_eleve_recu', true) = 1
                    AND (pg_temp.une('a1', 'signalement_eleve_recu')).destination = '/admin/alertes'
                    AND (pg_temp.une('a1', 'signalement_eleve_recu')).params::text NOT LIKE '%note interne%',
  'signalement : geste de la direction, sans le motif');
UPDATE public.student_concern SET statut = 'clos' WHERE id = pg_temp.id('sc');
SELECT pg_temp.vrai(pg_temp.n('a1', 'signalement_eleve_recu', true) = 0, 'signalement clos : geste clos');

INSERT INTO public.demandes_suppression_compte (id, profile_id, role_au_depot, delai_jours, echeance_le)
VALUES (pg_temp.id('sup'), pg_temp.id('t1'), 'guardian', 30, now() + interval '30 days');
SELECT pg_temp.vrai(pg_temp.n('a1', 'suppression_compte_demandee', true) = 1
                    AND (pg_temp.une('a1', 'suppression_compte_demandee')).destination = '/admin/personnes/suppressions',
  'suppression de compte demandee : geste de la direction');
UPDATE public.demandes_suppression_compte SET statut = 'annulee', annulee_le = now() WHERE id = pg_temp.id('sup');
SELECT pg_temp.vrai(pg_temp.n('a1', 'suppression_compte_demandee', true) = 0, 'suppression annulee : geste clos');

INSERT INTO public.demandes_creneau_personnalise (eleve_id, type_public, langue_code, fuseau_iana, jours, heure_locale)
VALUES (pg_temp.id('e1'), 'enfant', 'francais', 'Europe/Paris', '{3}', 17);
SELECT pg_temp.vrai(pg_temp.n('a1', 'creneau_personnalise_demande') = 1
                    AND NOT (pg_temp.une('a1', 'creneau_personnalise_demande')).geste_requis,
  'creneau personnalise : information, sans geste');

-- ---------------------------------------------------------------------------
-- 3. Finance : paiement echoue, coordonnees, remboursements, litiges.
-- ---------------------------------------------------------------------------
INSERT INTO public.recharges_recapitulatifs (id, titulaire, household_id, devise, total_mineur, expire_le)
VALUES (pg_temp.id('recap'), pg_temp.id('t1'), pg_temp.id('f1'), 'USD', 5500, now() + interval '1 hour');
INSERT INTO public.commandes_recharge (id, reference, recapitulatif_id, titulaire, household_id, cle, devise, total_mineur)
VALUES (pg_temp.id('cmd'), 'RCH-PUSH1-0001', pg_temp.id('recap'), pg_temp.id('t1'), pg_temp.id('f1'),
        pg_temp.id('cle-cmd'), 'USD', 5500);
UPDATE public.commandes_recharge SET etat = 'failed' WHERE id = pg_temp.id('cmd');
SELECT pg_temp.vrai(pg_temp.n('t1', 'paiement_echoue', true) = 1
                    AND (pg_temp.une('t1', 'paiement_echoue')).destination = '/tuteur/foyer/recharge',
  'paiement echoue : le tuteur a le geste Recharger');
SELECT pg_temp.vrai(pg_temp.n('e1', 'paiement_echoue') = 0, 'paiement echoue : jamais l''enfant');
SELECT pg_temp.vrai(pg_temp.n('a1', 'paiement_echoue', true) = 1 AND pg_temp.n('a4', 'paiement_echoue', true) = 1
                    AND pg_temp.n('c1', 'paiement_echoue', true) = 1
                    AND (pg_temp.une('c1', 'paiement_echoue')).destination = '/comptable/tresorerie/paiements-familles'
                    AND (pg_temp.une('c1', 'paiement_echoue')).params ->> 'portee' = 'comptable',
  'paiement echoue : direction ET un seul geste pour le comptable (deux directions)');
SELECT pg_temp.vrai((pg_temp.une('a1', 'paiement_echoue')).params::text NOT LIKE '%5500%',
  'paiement echoue : aucun montant dans la notification');
INSERT INTO public.notifications (destinataire, evenement, params, destination)
VALUES (pg_temp.id('t1'), 'paiement_recu', '{"portee":"foyer"}', '/tuteur/foyer/recharge');
SELECT pg_temp.vrai(pg_temp.n('t1', 'paiement_echoue', true) = 0, 'paiement recu : le paiement echoue du tuteur est clos');

INSERT INTO public.versement_coordonnees (id, profile_id, prestataire, devise_cible, compte_a_mon_nom)
VALUES (pg_temp.id('vc'), pg_temp.id('p2'), 'wise', 'EUR', true);
SELECT pg_temp.vrai(pg_temp.n('a1', 'versement_coordonnees_a_valider', true) = 1
                    AND pg_temp.n('c1', 'versement_coordonnees_a_valider', true) = 1
                    AND (pg_temp.une('a1', 'versement_coordonnees_a_valider')).destination = '/admin/finance/paiements'
                    AND (pg_temp.une('c1', 'versement_coordonnees_a_valider')).destination = '/comptable/paiements/beneficiaires',
  'coordonnees de versement : a valider, direction et comptable');
UPDATE public.versement_coordonnees SET valide_le = now(), valide_par = pg_temp.id('c1') WHERE id = pg_temp.id('vc');
SELECT pg_temp.vrai(pg_temp.n('a1', 'versement_coordonnees_a_valider', true) = 0
                    AND pg_temp.n('c1', 'versement_coordonnees_a_valider', true) = 0,
  'coordonnees validees : geste clos pour la direction et le comptable');
SELECT pg_temp.vrai(pg_temp.n('p2', 'versement_coordonnees_validees') = 1
                    AND (pg_temp.une('p2', 'versement_coordonnees_validees')).destination = '/compte/paiements-recus',
  'coordonnees validees : l''enseignant est prevenu');

INSERT INTO public.remboursements_demandes (id, commande_id, profile_id, montant_propose_mineur, montant_mineur,
                                            devise, detail, cle, demande_par)
VALUES (pg_temp.id('rb'), pg_temp.id('cmd'), pg_temp.id('t1'), 1000, 1000, 'USD', '{}', pg_temp.id('cle-rb'),
        pg_temp.id('a1'));
SELECT pg_temp.vrai(pg_temp.n('a1', 'remboursement_demande') = 1 AND pg_temp.n('c1', 'remboursement_demande') = 1
                    AND NOT (pg_temp.une('c1', 'remboursement_demande')).geste_requis,
  'remboursement demande : information, direction et comptable');
UPDATE public.remboursements_demandes SET etat = 'echec' WHERE id = pg_temp.id('rb');
SELECT pg_temp.vrai(pg_temp.n('a1', 'remboursement_echec', true) = 1 AND pg_temp.n('c1', 'remboursement_echec', true) = 1,
  'remboursement en echec : geste, direction et comptable');
UPDATE public.remboursements_demandes SET etat = 'envoyee' WHERE id = pg_temp.id('rb');
SELECT pg_temp.vrai(pg_temp.n('a1', 'remboursement_echec', true) = 0 AND pg_temp.n('c1', 'remboursement_echec', true) = 0,
  'remboursement reparti : geste clos');

-- Litige ecrit par l'emetteur existant (deux lignes direction, une par direction).
INSERT INTO public.notifications (destinataire, evenement, params, destination)
SELECT pg_temp.id(x), 'litige_ouvert',
       pg_catalog.jsonb_build_object('commande_id', pg_temp.id('cmd'), 'portee', 'direction'), '/admin/finance'
  FROM unnest(ARRAY['a1', 'a4']) AS x;
SELECT pg_temp.vrai(pg_temp.n('c1', 'litige_ouvert', true) = 1,
  'litige ouvert : une seule copie au comptable, avec geste');
INSERT INTO public.notifications (destinataire, evenement, params, destination)
SELECT pg_temp.id(x), 'litige_clos',
       pg_catalog.jsonb_build_object('commande_id', pg_temp.id('cmd'), 'portee', 'direction'), '/admin/finance'
  FROM unnest(ARRAY['a1', 'a4']) AS x;
SELECT pg_temp.vrai(pg_temp.n('c1', 'litige_clos') = 1 AND pg_temp.n('c1', 'litige_ouvert', true) = 0,
  'litige clos : copie au comptable, son litige ouvert est clos');

-- ---------------------------------------------------------------------------
-- 4. geste_requis etendu.
-- ---------------------------------------------------------------------------
INSERT INTO public.notifications (destinataire, evenement, params, destination)
VALUES (pg_temp.id('a1'), 'titulaire_en_retard', '{"portee":"direction"}', '/admin/operations/planning'),
       (pg_temp.id('t1'), 'titulaire_en_retard', '{"portee":"classe"}', '/tuteur'),
       (pg_temp.id('p1'), 'remplacement_avertissement', '{}', '/enseignant/journee');
SELECT pg_temp.vrai((pg_temp.une('a1', 'titulaire_en_retard')).geste_requis
                    AND NOT (pg_temp.une('t1', 'titulaire_en_retard')).geste_requis
                    AND (pg_temp.une('p1', 'remplacement_avertissement')).geste_requis,
  'geste : titulaire en retard pour la direction seulement ; avertissement de remplacement');

-- ---------------------------------------------------------------------------
-- 5. Abonnements : enfant refuse, RLS, colonnes, anon.
-- ---------------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('e1'), 'student');
DO $$
BEGIN
  PERFORM public.push_inscrire('https://fcm.googleapis.com/fcm/send/e1', pg_temp.p256('e1'), pg_temp.au('e1'), 'test');
  RAISE EXCEPTION 'PUSH-1 ROUGE : un enfant a pu s''abonner';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'OK enfant : abonnement refuse';
END $$;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.abonnements_push WHERE profile_id = pg_temp.id('e1')),
  'enfant : aucun abonnement');
SELECT pg_temp.qui(pg_temp.id('e2'), 'student');
SELECT pg_temp.vrai(public.push_inscrire('https://fcm.googleapis.com/fcm/send/e2', pg_temp.p256('e2'), pg_temp.au('e2'), NULL) IS NOT NULL,
  'eleve adulte autonome : abonnement accepte');
SELECT pg_temp.qui(pg_temp.id('t1'), 'guardian');
SELECT pg_temp.vrai(public.push_inscrire('https://fcm.googleapis.com/fcm/send/t1', pg_temp.p256('t1'), pg_temp.au('t1'), 'Android') IS NOT NULL,
  'tuteur : abonnement accepte');
DO $$
BEGIN
  PERFORM public.push_inscrire('https://attaquant.example/collecte', pg_temp.p256('x'), pg_temp.au('x'), NULL);
  RAISE EXCEPTION 'PUSH-1 ROUGE : un hote hors liste blanche a ete accepte';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'OK hote hors liste blanche refuse (22023)';
END $$;
DO $$
BEGIN
  PERFORM public.push_inscrire('https://fcm.googleapis.com.attaquant.example/x', pg_temp.p256('x'), pg_temp.au('x'), NULL);
  RAISE EXCEPTION 'PUSH-1 ROUGE : un faux sous-domaine a ete accepte';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'OK faux sous-domaine refuse (22023)';
END $$;
DO $$
BEGIN
  PERFORM public.push_inscrire('http://pas-https', pg_temp.p256('x'), pg_temp.au('x'), NULL);
  RAISE EXCEPTION 'PUSH-1 ROUGE : abonnement illisible accepte';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'OK abonnement illisible refuse';
END $$;

SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.abonnements_push) = 1,
  'RLS : le tuteur voit son seul abonnement');
DO $$
BEGIN
  PERFORM endpoint FROM public.abonnements_push;
  RAISE EXCEPTION 'PUSH-1 ROUGE : l''adresse de l''abonnement est lisible';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'OK RLS : adresse et cles illisibles';
END $$;
DO $$
BEGIN
  INSERT INTO public.abonnements_push (profile_id, endpoint, p256dh, auth)
  VALUES (pg_temp.id('t1'), 'https://fcm.googleapis.com/fcm/send/direct', pg_temp.p256('d'), pg_temp.au('d'));
  RAISE EXCEPTION 'PUSH-1 ROUGE : insertion directe permise';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'OK RLS : aucune ecriture directe';
END $$;
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.abonnements_push) = 0,
  'RLS : la direction ne voit pas les abonnements des autres');
RESET ROLE;
SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege('anon', 'public.push_inscrire(text,text,text,text)', 'EXECUTE')
                    AND NOT pg_catalog.has_function_privilege('authenticated', 'public.push_reserver(integer)', 'EXECUTE'),
  'droits : anon ne s''abonne pas ; personne ne vide la file sans la cle de service');

-- ---------------------------------------------------------------------------
-- 6. La file.
-- ---------------------------------------------------------------------------
INSERT INTO public.notifications (destinataire, evenement, params, destination)
VALUES (pg_temp.id('t1'), 'seance_annulee', '{"portee":"foyer"}', '/tuteur'),
       (pg_temp.id('t1'), 'seance_terminee', '{"portee":"foyer"}', '/tuteur'),
       (pg_temp.id('e1'), 'seance_annulee', '{"portee":"soi"}', '/eleve');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.push_sortants s JOIN public.notifications n ON n.id = s.notification_id
                             WHERE s.destinataire = pg_temp.id('t1') AND n.evenement = 'seance_annulee'),
  'file : seance annulee part en push (defaut)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.push_sortants
                                 WHERE destinataire = pg_temp.id('t1') AND evenement = 'seance_terminee'),
  'file : seance terminee reste dans l''application (exclusion nommee)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.push_sortants WHERE destinataire = pg_temp.id('e1')),
  'file : jamais un compte enfant');

SELECT pg_temp.qui(pg_temp.id('t1'), 'guardian');
SELECT public.push_regler_categorie('paiements', false);
SELECT pg_temp.vrai(((public.push_mes_reglages('https://fcm.googleapis.com/fcm/send/t1')) ->> 'cetAppareil')::boolean
                    AND (public.push_mes_reglages(NULL) -> 'categories' -> 2 ->> 'actif') = 'false',
  'reglages : cet appareil inscrit, paiements coupes');
INSERT INTO public.notifications (destinataire, evenement, params, destination)
VALUES (pg_temp.id('t1'), 'paiement_relance', '{"portee":"foyer"}', '/tuteur/foyer/recharge');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.push_sortants
                                 WHERE destinataire = pg_temp.id('t1') AND evenement = 'paiement_relance'),
  'file : categorie coupee, aucun push');

-- La direction sans appareil : rien ; avec un appareil : les candidatures
-- regroupees sous une etiquette.
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.push_sortants WHERE destinataire = pg_temp.id('a1')),
  'file : sans appareil, aucun push');
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SELECT public.push_inscrire('https://fcm.googleapis.com/fcm/send/a1', pg_temp.p256('a1'), pg_temp.au('a1'), 'iPhone');
SELECT public.push_inscrire('https://fcm.googleapis.com/fcm/send/a1-mort', pg_temp.p256('a1m'), pg_temp.au('a1m'), 'ancien');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, source)
VALUES (pg_temp.id('cand-f2'), 'eleve_adulte', pg_temp.id('t3'), 'male', 'Omar Push', 'lien_public');
SET CONSTRAINTS push1_candidature IMMEDIATE;
SET CONSTRAINTS push1_candidature DEFERRED;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.push_sortants
                             WHERE destinataire = pg_temp.id('a1') AND evenement = 'admission_recue'
                               AND tag = 'candidatures' AND portee = 'direction'),
  'file : admission a la direction, etiquette candidatures');

SET LOCAL ROLE service_role;
CREATE TEMP TABLE lot ON COMMIT DROP AS
  SELECT e FROM pg_catalog.jsonb_array_elements(public.push_reserver(50)) AS e;
RESET ROLE;
SELECT pg_temp.vrai((SELECT (e ->> 'nombre')::integer FROM lot
                      WHERE e ->> 'evenement' = 'admission_recue') = 2,
  'reserver : deux candidatures ouvertes sous l''etiquette (enseignant + eleve adulte)');
SELECT pg_temp.vrai((SELECT pg_catalog.jsonb_array_length(e -> 'abonnements') FROM lot
                      WHERE e ->> 'evenement' = 'admission_recue') = 2
                    AND (SELECT e ->> 'langue' FROM lot WHERE e ->> 'evenement' = 'admission_recue') = 'fr',
  'reserver : les deux appareils de la direction, et la langue');
CREATE TEMP TABLE morts ON COMMIT DROP AS
  SELECT ARRAY[(SELECT a.id FROM public.abonnements_push a WHERE a.endpoint = 'https://fcm.googleapis.com/fcm/send/a1-mort'),
               -- l'abonnement d'une autre personne n'est jamais retire par cette ligne
               (SELECT a.id FROM public.abonnements_push a WHERE a.endpoint = 'https://fcm.googleapis.com/fcm/send/t1')] AS ids,
         (SELECT (e ->> 'id')::uuid FROM lot WHERE e ->> 'evenement' = 'admission_recue') AS ligne;
GRANT SELECT ON morts TO service_role;
SET LOCAL ROLE service_role;
SELECT public.push_consigner((SELECT ligne FROM morts), true, NULL, (SELECT ids FROM morts));
RESET ROLE;
SELECT pg_temp.vrai((SELECT retire_le IS NOT NULL AND motif_retrait = 'expire' FROM public.abonnements_push
                      WHERE endpoint = 'https://fcm.googleapis.com/fcm/send/a1-mort')
                    AND (SELECT retire_le IS NULL FROM public.abonnements_push WHERE endpoint = 'https://fcm.googleapis.com/fcm/send/t1')
                    AND (SELECT statut FROM public.push_sortants
                          WHERE destinataire = pg_temp.id('a1') AND evenement = 'admission_recue') = 'envoye',
  'consigner : abonnement mort retire (le sien seulement), ligne envoyee');

SELECT pg_temp.qui(pg_temp.id('t1'), 'guardian');
SELECT pg_temp.vrai(public.push_desinscrire('https://fcm.googleapis.com/fcm/send/t1'), 'desinscrire : appel accepte');
SELECT pg_temp.vrai(NOT ((public.push_mes_reglages('https://fcm.googleapis.com/fcm/send/t1')) ->> 'cetAppareil')::boolean
                    AND EXISTS (SELECT 1 FROM public.abonnements_push WHERE endpoint = 'https://fcm.googleapis.com/fcm/send/t1'
                                   AND motif_retrait = 'personne'),
  'desinscrire : l''appareil n''est plus inscrit (ligne gardee)');

-- ---------------------------------------------------------------------------
-- 7. Un echec du notifieur : le geste metier passe, la trace est ecrite.
--    (Le notifieur est remplace le temps du scenario, annule a la fin.)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.push1_ajouter(
  p_destinataire uuid, p_evenement text, p_params jsonb, p_destination text, p_source_id text)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $f$
BEGIN
  RAISE EXCEPTION 'panne simulee';
END $f$;
INSERT INTO public.kyc_documents (id, profile_id, doc_type, gender, object_key)
VALUES (pg_temp.id('kyc2'), pg_temp.id('t1'), 'id_card', 'female', 'kyc/push1-2');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.kyc_documents WHERE id = pg_temp.id('kyc2')),
  'panne du notifieur : la piece est bien deposee');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM private.notifications_echecs
                             WHERE evenement = 'piece_identite_deposee'
                               AND source_id = pg_temp.id('kyc2')::text AND etat_sql = 'P0001'),
  'panne du notifieur : la trace est ecrite (evenement, source, SQLSTATE)');

ROLLBACK;
