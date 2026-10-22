-- CAND-L6 (21/10/2026) : referentiel declaratif de compatibilite de paiement.
--
-- Decision du directeur : docs/current/DECISION-CANDIDATURES-2026-10-21.md,
-- ligne 28 (CAND-Q05) : inscription ouverte a tous les pays ; salles 2 et 3
-- seulement pour qui l'academie peut payer ; hors d'Afrique, Arabie saoudite
-- comprise, virement bancaire ; aucune integration de paiement. Restent
-- ouverts (lignes 80-83) : les pays et moyens d'Afrique, et le candidat qui vit
-- en Afrique avec un compte bancaire.
-- Specification consolidee : SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md,
-- sections 4.1 (dimension paiement), 4.2 (transitions 8, 9, 20, 24, 25), 5
-- (controle paiement_compatible), 5.1 (le referentiel), 8.1 (capacite
-- paiement.referentiel.ecrire : direction et comptabilite), 11 (ligne L6) et
-- 12.1 (cas L6-1 a L6-10). Contrat : CONTRAT_PORTS_CANDIDATURES.md section 4
-- (PortReferentielPaiement : lister, enregistrer, optionsConfirmees).
-- Besoin : DEPENDANCES_BACKEND.md, CAND-BR-13.
--
-- Ce lot pose :
-- * le referentiel public.referentiel_paiement (une ligne par pays, methode et
--   operateur), le catalogue ferme des operateurs, la liste des pays d'Afrique
--   et le journal en ajout seul des changements ;
-- * l'etat initial deduit de DEC:28 (voir Etat initial ci-dessous) ;
-- * le calcul de la dimension paiement d'une candidature (inconnu, a_verifier,
--   compatible, incompatible) a partir des reponses declarees ;
-- * la table des decisions de la direction sur un moyen declare
--   (public.candidature_paiement_decisions), que les gestes 24 et 25 du lot L2
--   rempliront : AUCUN geste de ce lot ne l'ecrit ;
-- * les effets automatiques d'un changement du referentiel, portes par un
--   DECLENCHEUR sur la table (toute voie d'ecriture) : transition 8 (en examen
--   vers paiement_non_disponible), transition 9 (paiement_non_disponible vers
--   a_completer), restriction automatique d'une candidature confirmee
--   (transition 20, cause paiement), controle qui tombe en salle 2 ; chacun
--   journalise dans candidature_evenements avec sa cause ;
-- * la table des decisions du directeur sur l'Afrique
--   (public.referentiel_paiement_afrique_decisions), seule source de la cle
--   app_config paiement.afrique_ouverte (R12) ;
-- * quatre RPC : capacites_referentiel_paiement, lire_referentiel_paiement
--   (direction et comptabilite), enregistrer_ligne_referentiel_paiement
--   (direction et comptabilite, rend l'impact), options_paiement_confirmees
--   (le candidat lit les seules lignes confirme d'un pays, sans note).
--
-- Reponses declarees (CAND-01, salle d'examen ; spec consolidee 2.1 et 5.1).
-- Les reponses vivent dans public.candidature_reponses.reponses (CAND-L1), un
-- document par questionnaire. Le calcul lit le document le plus recent de
-- source 'candidat' (jamais une reponse importee : le paiement n'est jamais
-- pre-rempli, spec consolidee 3.4). Cles lues, toutes facultatives :
-- * paysVersement : texte, code ISO 3166-1 alpha-2 en majuscules, pays ou la
--   personne recevra ses versements ;
-- * compteBancaire : booleen, compte bancaire qui recoit des virements ;
-- * operateurs : tableau de codes d'operateurs mobile money
--   (public.referentiel_paiement_operateurs.code), choisis parmi les lignes
--   confirme du pays de versement ; un code mal forme est ignore.
-- Une declaration existe quand paysVersement est un code valide ET
-- compteBancaire est un booleen ; sinon la dimension vaut inconnu.
-- paysResidence (CAND-L1) et accordRemuneration (booleen, lu par L2 a l'envoi)
-- ne sont pas lus par ce calcul. Jamais : numero de compte, IBAN, numero de
-- portefeuille, identifiant, code.
--
-- Calcul (spec consolidee 5.1) :
-- * les moyens declares : (virement_bancaire, sans operateur) si compteBancaire,
--   et (mobile_money, code) pour chaque operateur declare ;
-- * un moyen croise une ligne quand la ligne est du pays de versement, a l'etat
--   confirme, de la meme methode, et du meme operateur pour le mobile money
--   (pour le virement, toute ligne confirme de virement du pays) ;
-- * inconnu : aucune declaration ; incompatible : aucun moyen ne croise une
--   ligne confirme, ou tous les moyens croises sont infirmes par la derniere
--   decision de la direction ; compatible : un moyen croise et confirme par la
--   derniere decision de la direction (transition 24) ; a_verifier : sinon.
-- * une ligne en_verification ou indisponible ne rend jamais compatible, quelle
--   que soit une decision anterieure.
--
-- Etat initial, deduit de DEC:28 (spec consolidee 5.1) :
-- * chaque pays HORS d'Afrique, Arabie saoudite comprise : une ligne
--   virement_bancaire a confirme, source decision_directeur, reference DEC:28,
--   verifiee le 21/10/2026. Le directeur a decide une regle, il n'a pas verifie
--   chaque pays : un pays ou l'academie ne peut pas verser se signale au
--   directeur (la spec consolidee 5.1 en nomme les premiers) ;
-- * chaque pays d'Afrique : sa ligne virement_bancaire a en_verification,
--   compte bancaire compris, tant que CAND-Q05 est ouvert. Aucune ligne de
--   mobile money n'est posee : les operateurs d'un pays ne se supposent pas
--   (spec v1, section 4.4).
-- La liste des pays vient de lib/core/i18n/pays_iso.dart (249 codes ISO
-- 3166-1, la table que le candidat lit) : 189 lignes confirme, 60 en
-- verification.
--
-- Liste des pays d'Afrique : SOURCE NOMMEE, Division de statistique des
-- Nations unies, norme M49 (Standard country or area codes for statistical
-- use), region 002 Afrique, https://unstats.un.org/unsd/methodology/m49/overview/
-- lue le 21/10/2026 : 60 pays ou territoires.
-- * 015 Afrique du Nord (7) : DZ EG LY MA SD TN EH ;
-- * 014 Afrique orientale (22) : IO BI KM DJ ER ET TF KE MG MW MU YT MZ RE RW
--   SC SO SS UG TZ ZM ZW ;
-- * 017 Afrique centrale (9) : AO CM CF TD CG CD GQ GA ST ;
-- * 018 Afrique australe (5) : BW SZ LS NA ZA ;
-- * 011 Afrique de l'Ouest (17) : BJ BF CV CI GM GH GN GW LR ML MR NE NG SH SN
--   SL TG.
-- Proposee au directeur avec CAND-Q05 (spec consolidee 0.3) ; elle decide qui
-- entre en salle 2. Tant que la cle app_config paiement.afrique_ouverte ne
-- vaut pas true (CAND-Q05 ouvert), aucune ligne d'un pays de cette liste ne
-- quitte en_verification (spec consolidee 5.1 et 0.3 : toutes ses lignes
-- restent en_verification) : la RPC le refuse (refus rendu) et une garde de
-- table le leve pour toute autre voie. La cle elle-meme ne change que par la
-- table des decisions (R12), jamais par une ecriture directe dans app_config.
--
-- Choix faits dans ce lot, a relire :
-- * R1 droits (spec consolidee 8.1, paiement.referentiel.ecrire ; 8.2 ;
--   PORTS, regles transverses) : lire et ecrire le referentiel, pour la
--   comptabilite active et pour la direction active dont le genre est connu,
--   ou sous l'exception super-admin de 0088 (private.paiement_portee). Une
--   direction au genre inconnu est refusee (42501), comme en L1, avant tout
--   effet sur une candidature. Les lignes ne sont pas cloisonnees (une ligne
--   est un pays, pas une personne) et un changement agit sur les candidatures
--   des deux cotes ; ce qui sort vers un compte l'est : l'impact (PORTS
--   section 4 : nombre de candidatures confirmees que le changement met en
--   restriction) et les alertes rendent, a une direction, les restrictions de
--   son cote ; a l'exception super-admin, les deux cotes, journalise comme C13
--   de L1 ; a la comptabilite, le total (8.1 lui donne l'impact d'un
--   changement ; elle n'a pas de cote). Les autres compteurs (bloquees,
--   paiementNonDisponible, aCompleter, recalculees, et leur partage par genre)
--   restent dans le journal du referentiel, qu'aucun compte ne lit, jamais dans
--   une reponse ni dans audit_logs. Jamais une liste ni un identifiant de
--   personne (fiche ADM-24). Ecart a soumettre au directeur : spec consolidee
--   0.2 bis ;
-- * R2 le candidat (le titulaire d'une candidature en cours, compte non
--   supprime, en attente ou actif et non expire, comme L1-08) lit par
--   options_paiement_confirmees les seules lignes confirme d'un pays :
--   methode, operateur, nom de l'operateur, devise ; jamais une note, un
--   prestataire, une source ni un nom (L6-7) ;
-- * R3 confirme exige une date et un responsable (revue R8, PORTS section 4) :
--   contrainte de table (le compte qui enregistre, ou la decision datee du
--   directeur pour l'etat initial) et refus rendu confirmation_sans_verification
--   par la RPC ; verifie_par est toujours le compte qui enregistre ;
-- * R4 ecriture par versionAttendue et cleIdempotence (regles transverses de
--   PORTS) : version perimee ou ligne deja existante, refus rendu
--   conflit_referentiel avec la ligne relue ; meme cle rejouee par le meme
--   compte avec la meme demande, la ligne relue et l'impact d'origine, sans
--   effet ; meme cle pour une autre demande, refus rendu. Le pays, la methode
--   et l'operateur d'une ligne ne changent pas (une autre ligne se cree) ;
--   aucune ligne ne s'efface : elle passe indisponible. Les deux regles sont
--   des gardes de table, et la version augmente a chaque modification par
--   toute voie (declencheur), pour que versionAttendue reste sur ;
-- * R5 effets d'un changement (spec consolidee 5.1), portes par le
--   declencheur AFTER INSERT OR UPDATE de public.referentiel_paiement : toute
--   voie d'ecriture les produit (la RPC, l'editeur SQL, une migration qui
--   appliquerait la reponse a CAND-Q05). Chaque ecriture laisse une ligne de
--   journal et une entree audit_logs (sans auteur ni cle hors de la RPC). Les
--   effets ne jouent que quand une ligne passe confirme ou quitte confirme,
--   pour les candidatures en cours, avec compte, en salle 1, 2 ou 3, dont le
--   pays de versement declare est celui de la ligne :
--   - salle d'examen en_examen et paiement incompatible : transition 8 ;
--   - paiement_non_disponible et ligne qui passe confirme : transition 9, avec
--     moyen_paiement nomme a completer ;
--   - salle 2 dont le paiement n'est plus compatible : evenement controle, la
--     candidature compte dans bloquees (compteur du lot L2), sans retour ;
--   - salle 3 dont le paiement n'est pas compatible apres le changement, quelle
--     que soit la valeur gardee en colonne (une colonne perimee ne laisse
--     jamais une personne affectable) : restriction automatique, cause
--     paiement, motif paiement a reverifier ; une candidature deja en
--     restriction garde sa cause et recoit un evenement controle ;
--   - chaque changement de la dimension paiement : un evenement controle.
--   Auteur systeme (aucun) pour les effets du referentiel ; aucune levee
--   automatique de restriction (transition 21, direction, lot L2). La pause ne
--   bloque pas un effet automatique : son drapeau reste. derniere_activite ne
--   bouge pas (ce n'est pas une activite de la personne) ; version augmente ;
-- * R6 la restriction porte desormais sa cause (spec consolidee 4.1) :
--   colonne candidatures.restriction_cause (piece, paiement, manuelle),
--   presente si et seulement si restreinte ;
-- * R7 l'etat paiement_non_disponible (spec consolidee 4.1, salle 1) entre dans
--   les contraintes de candidatures et de candidature_evenements ;
-- * R8 decisions de la direction (transitions 24 et 25) : table en ajout seul,
--   une decision par moyen (pays, methode, operateur), la plus recente fait
--   foi ; une confirmation exige que le moyen soit declare et croise une ligne
--   confirme (garde de table : une ligne en_verification ne se confirme
--   jamais) ; une infirmation exige un motif. Le lot L2 y ecrit puis appelle
--   private.paiement_recalculer(candidature, 'moyen_confirme' ou
--   'moyen_infirme', auteur, motif) ; apres l'ecriture des reponses
--   (transition 6), il appelle private.paiement_recalculer(candidature,
--   'reponses') ; le controle paiement_compatible de
--   private.candidature_controles (L2) lit private.paiement_compatible ;
-- * R9 alerte a la direction et a la comptabilite : chaque changement est
--   journalise avec ses effets comptes ; lire_referentiel_paiement rend les
--   vingt derniers changements qui ont pose des restrictions dans la portee du
--   lecteur (alertes, fiche ADM-24 : l'alerte d'un changement qui pose des
--   restrictions), chacun avec son impact borne comme en R1. Les
--   notifications et les courriels sont du lot L5 : l'evenement de la
--   transition 9 porte aNotifier = paiement_possible, le nom du modele de la
--   liste fermee (CONTRAT_FILE_COURRIELS.md section 3), pour qu'il les derive,
--   et ce lot n'ecrit ni notification ni courriel ;
-- * R10 part de CPT-BR-10 (PORTS section 4) : chaque ligne rend capacitePayout,
--   le plafond que le referentiel donne a un corridor : confirme donne
--   prisEnCharge, en_verification verificationRequise, indisponible
--   nonPrisEnCharge ; l'activation et le solde du prestataire n'en viennent
--   jamais ;
-- * R11 type de decaissement : liste fermee proposee (virement_international,
--   virement_local, payout_portefeuille), null tant qu'il n'est pas precise ;
--   prestataire et devise sont des donnees (code en minuscules, ISO 4217), jamais
--   un nom dans le code metier ;
-- * R12 la cle app_config paiement.afrique_ouverte suit la table
--   public.referentiel_paiement_afrique_decisions (ajout seul : ouverte ou
--   fermee, reference de la decision datee du directeur, date), qu'aucun
--   compte ne peut ecrire (ni direction, ni comptabilite, ni service_role) :
--   seul le proprietaire de la base l'ecrit, par migration ou par l'editeur
--   SQL, sur decision datee du directeur. Une garde sur app_config refuse
--   (42501) toute ecriture directe de la cle, sur le modele de
--   private.c29_proteger_quota_controle (20261011220000), toute valeur autre
--   que la derniere decision, et son effacement ou son renommage. Une
--   decision de fermeture est refusee (23514) tant qu'une ligne d'Afrique
--   n'est pas revenue a en_verification ;
-- * R13 salle 3, lecture stricte du controle paiement_compatible (spec
--   consolidee section 5) : garder une autre ligne confirme veut dire garder
--   un moyen declare, CONFIRME PAR LA DIRECTION, qui croise une ligne
--   confirme. Qui n'a plus qu'un moyen declare non encore confirme (paiement
--   a_verifier) passe aussi en restriction : l'academie n'a pas verifie
--   qu'elle peut le payer (DEC:28). Une decision confirme se pose a toute
--   etape (la garde des decisions ne lit pas l'etape) ; le lot L2 ouvre la
--   transition 24 a une candidature confirmee en restriction de cause
--   paiement, puis la direction leve la restriction (21). Ecart a soumettre
--   au directeur : spec consolidee 0.2 bis.
--
-- Hors de ce lot :
-- * gestes de la direction confirmerMoyenPaiement et infirmerMoyenPaiement
--   (transitions 24 et 25, la 24 aussi en salle 3 sous restriction de cause
--   paiement, R13), compteur bloquees et controles nommes : lot L2 ;
-- * notifications et courriels (transition 9, alerte) : lot L5 ;
-- * capacites_candidatures (CAND-L1) rend toujours peutEcrireReferentiel a
--   false : l'ecran du referentiel (Finance, DEC:85) lit
--   capacites_referentiel_paiement ; le lot qui redefinira
--   capacites_candidatures l'alignera sur private.paiement_gestionnaire() ;
-- * les lectures de CAND-L1 ne connaissent pas encore ce que ce lot ajoute :
--   le filtre etat de lister_candidatures refuse paiement_non_disponible
--   (22023), et le filtre paiement incompatible ne le remplace pas (il rend
--   aussi des candidatures a_completer et des confirmees en restriction) ;
--   ni lire_candidature ni lister_candidatures ne rendent
--   candidatures.restriction_cause (seulement restreinte). Le lot qui
--   redefinira ces lectures les etend ;
-- * audit_logs est lisible par toute direction active (policy audit_logs_read,
--   hors module) : l'entree candidature_effet_paiement de chaque effet porte
--   l'identifiant de la candidature, comme les entrees de L1
--   (candidature_hors_portee) ; en les comptant, une direction peut deduire
--   le nombre d'effets de l'autre cote. Borner la lecture d'audit_logs par
--   genre est un lot hors module, a soumettre au directeur ;
-- * qui ajoute un operateur au catalogue : aujourd'hui par migration seulement.
BEGIN;

-- ============================================================
-- 1. Complements de CAND-L1 : etat paiement_non_disponible, cause de restriction
-- ============================================================

ALTER TABLE public.candidatures DROP CONSTRAINT candidatures_etat_check;
ALTER TABLE public.candidatures ADD CONSTRAINT candidatures_etat_check
  CHECK (etat IN ('a_completer', 'en_examen', 'paiement_non_disponible', 'entretien_a_planifier',
                  'entretien_planifie', 'decision_en_attente'));
ALTER TABLE public.candidatures DROP CONSTRAINT candidatures_etat_coherent;
ALTER TABLE public.candidatures ADD CONSTRAINT candidatures_etat_coherent CHECK (
  (etape IN ('recue', 'invitee', 'confirmee') AND etat IS NULL)
  OR (etape = 'prequalification' AND etat IS NOT NULL
      AND etat IN ('a_completer', 'en_examen', 'paiement_non_disponible'))
  OR (etape = 'verifications' AND etat IS NOT NULL
      AND etat IN ('en_examen', 'entretien_a_planifier', 'entretien_planifie',
                   'decision_en_attente')));
ALTER TABLE public.candidature_evenements DROP CONSTRAINT candidature_evenements_etat_avant_check;
ALTER TABLE public.candidature_evenements ADD CONSTRAINT candidature_evenements_etat_avant_check
  CHECK (etat_avant IN ('a_completer', 'en_examen', 'paiement_non_disponible',
                        'entretien_a_planifier', 'entretien_planifie', 'decision_en_attente'));
ALTER TABLE public.candidature_evenements DROP CONSTRAINT candidature_evenements_etat_apres_check;
ALTER TABLE public.candidature_evenements ADD CONSTRAINT candidature_evenements_etat_apres_check
  CHECK (etat_apres IN ('a_completer', 'en_examen', 'paiement_non_disponible',
                        'entretien_a_planifier', 'entretien_planifie', 'decision_en_attente'));

ALTER TABLE public.candidatures
  ADD COLUMN restriction_cause text NULL
    CHECK (restriction_cause IN ('piece', 'paiement', 'manuelle'));
-- Une restriction a toujours sa cause, et une cause n'existe qu'avec elle (R6).
ALTER TABLE public.candidatures ADD CONSTRAINT candidatures_restriction_cause
  CHECK (restreinte = (restriction_cause IS NOT NULL));

-- ============================================================
-- 2. Tables du referentiel
-- ============================================================

-- La liste des pays d'Afrique (ONU M49, region 002) : voir l'en-tete.
CREATE TABLE public.referentiel_paiement_afrique (
  pays text PRIMARY KEY CHECK (pays ~ '^[A-Z]{2}$'),
  -- Region M49 la plus fine : 015 (Afrique du Nord), 014, 017, 018, 011
  -- (regions intermediaires de l'Afrique subsaharienne).
  region_m49 text NOT NULL CHECK (region_m49 IN ('015', '014', '017', '018', '011'))
);

-- Les decisions du directeur sur l'Afrique (R12), en ajout seul ; la plus
-- recente fait foi et la cle app_config paiement.afrique_ouverte la recopie.
-- Aucun privilege client : seul le proprietaire de la base y ecrit.
CREATE TABLE public.referentiel_paiement_afrique_decisions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ouverte boolean NOT NULL,
  -- La decision datee du directeur, par exemple DEC:nn de son fichier.
  decision_ref text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(decision_ref)) BETWEEN 1 AND 200),
  decide_le date NOT NULL CHECK (pg_catalog.isfinite(decide_le)),
  enregistre_par text NOT NULL DEFAULT (SESSION_USER)::text,
  enregistre_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);

-- Le catalogue ferme des operateurs (fiche ADM-24 : les operateurs viennent
-- d'une liste rendue par le serveur). Un nom de marque, le meme en francais et
-- en arabe.
CREATE TABLE public.referentiel_paiement_operateurs (
  code text PRIMARY KEY CHECK (code ~ '^[a-z][a-z0-9_]{1,39}$'),
  methode text NOT NULL CHECK (methode IN ('virement_bancaire', 'mobile_money')),
  nom text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(nom)) BETWEEN 1 AND 80),
  actif boolean NOT NULL DEFAULT true,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT referentiel_paiement_operateurs_code_methode UNIQUE (code, methode)
);

CREATE TABLE public.referentiel_paiement (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pays text NOT NULL CHECK (pays ~ '^[A-Z]{2}$'),
  methode text NOT NULL CHECK (methode IN ('virement_bancaire', 'mobile_money')),
  -- Pour le virement, null veut dire tout compte bancaire du pays.
  operateur text NULL,
  prestataire text NULL CHECK (prestataire ~ '^[a-z][a-z0-9_]{1,39}$'),
  devise text NULL CHECK (devise ~ '^[A-Z]{3}$'),
  type_decaissement text NULL
    CHECK (type_decaissement IN ('virement_international', 'virement_local', 'payout_portefeuille')),
  etat text NOT NULL CHECK (etat IN ('confirme', 'en_verification', 'indisponible')),
  -- decision_directeur : ligne deduite d'une decision datee (DEC:28) ;
  -- verification : ligne enregistree par un compte de la direction ou de la
  -- comptabilite.
  source text NOT NULL CHECK (source IN ('decision_directeur', 'verification')),
  source_ref text NULL CHECK (pg_catalog.length(pg_catalog.btrim(source_ref)) BETWEEN 1 AND 200),
  verifie_le date NULL CHECK (verifie_le IS NULL OR pg_catalog.isfinite(verifie_le)),
  verifie_par uuid NULL REFERENCES public.profiles(id),
  -- Notes internes : jamais rendues au candidat (R2).
  notes text NULL CHECK (pg_catalog.length(pg_catalog.btrim(notes)) BETWEEN 1 AND 2000),
  version integer NOT NULL DEFAULT 1 CHECK (version >= 1),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  modifie_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT referentiel_paiement_operateur_connu FOREIGN KEY (operateur, methode)
    REFERENCES public.referentiel_paiement_operateurs (code, methode),
  CONSTRAINT referentiel_paiement_mobile_operateur CHECK (methode <> 'mobile_money' OR operateur IS NOT NULL),
  CONSTRAINT referentiel_paiement_decision_reference CHECK (source <> 'decision_directeur' OR source_ref IS NOT NULL),
  CONSTRAINT referentiel_paiement_compte_responsable CHECK (source <> 'verification' OR verifie_par IS NOT NULL),
  -- confirme exige une date et un responsable (R3).
  CONSTRAINT referentiel_paiement_confirme_verifie CHECK (
    etat <> 'confirme'
    OR (verifie_le IS NOT NULL AND (verifie_par IS NOT NULL OR source = 'decision_directeur')))
);
CREATE UNIQUE INDEX referentiel_paiement_ligne_uidx
  ON public.referentiel_paiement (pays, methode, (coalesce(operateur, '')));

-- Le journal des changements du referentiel (R4, R9), en ajout seul. Une ligne
-- de l'etat initial n'a ni auteur ni cle ; une ecriture par un compte a les
-- deux.
CREATE TABLE public.referentiel_paiement_journal (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ligne_id uuid NOT NULL REFERENCES public.referentiel_paiement(id) ON DELETE RESTRICT,
  avant jsonb NULL CHECK (avant IS NULL OR pg_catalog.jsonb_typeof(avant) = 'object'),
  apres jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(apres) = 'object'),
  auteur_id uuid NULL REFERENCES public.profiles(id),
  cle_idempotence text NULL UNIQUE
    CHECK (pg_catalog.length(cle_idempotence) BETWEEN 8 AND 200),
  empreinte text NULL CHECK (empreinte ~ '^[0-9a-f]{32}$'),
  impact jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (pg_catalog.jsonb_typeof(impact) = 'object'),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT referentiel_paiement_journal_auteur_cle CHECK (
    (auteur_id IS NULL AND cle_idempotence IS NULL AND empreinte IS NULL)
    OR (auteur_id IS NOT NULL AND cle_idempotence IS NOT NULL AND empreinte IS NOT NULL))
);
CREATE INDEX referentiel_paiement_journal_ligne_idx
  ON public.referentiel_paiement_journal (ligne_id, cree_le DESC);

-- Decisions de la direction sur un moyen declare (R8), ecrites par les gestes
-- 24 et 25 du lot L2. Ajout seul ; la plus recente par moyen fait foi.
CREATE TABLE public.candidature_paiement_decisions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  candidature_id uuid NOT NULL REFERENCES public.candidatures(id) ON DELETE RESTRICT,
  pays text NOT NULL CHECK (pays ~ '^[A-Z]{2}$'),
  methode text NOT NULL CHECK (methode IN ('virement_bancaire', 'mobile_money')),
  operateur text NULL CHECK (operateur ~ '^[a-z][a-z0-9_]{1,39}$'),
  decision text NOT NULL CHECK (decision IN ('confirme', 'infirme')),
  motif_interne text NULL
    CHECK (pg_catalog.length(pg_catalog.btrim(motif_interne)) BETWEEN 1 AND 2000),
  auteur_id uuid NOT NULL REFERENCES public.profiles(id),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  -- Le virement vaut pour tout compte bancaire : aucun operateur ; le mobile
  -- money nomme toujours le sien.
  CONSTRAINT candidature_paiement_decisions_operateur
    CHECK ((methode = 'virement_bancaire') = (operateur IS NULL)),
  -- Infirmer un moyen exige un motif (transition 25).
  CONSTRAINT candidature_paiement_decisions_motif
    CHECK (decision <> 'infirme' OR motif_interne IS NOT NULL)
);
CREATE INDEX candidature_paiement_decisions_moyen_idx
  ON public.candidature_paiement_decisions (candidature_id, pays, methode, cree_le DESC, id DESC);

ALTER TABLE public.referentiel_paiement_afrique ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referentiel_paiement_afrique_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referentiel_paiement_operateurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referentiel_paiement ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referentiel_paiement_journal ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidature_paiement_decisions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.referentiel_paiement_afrique, public.referentiel_paiement_afrique_decisions,
  public.referentiel_paiement_operateurs,
  public.referentiel_paiement, public.referentiel_paiement_journal,
  public.candidature_paiement_decisions
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON SEQUENCE public.referentiel_paiement_journal_id_seq,
  public.candidature_paiement_decisions_id_seq,
  public.referentiel_paiement_afrique_decisions_id_seq
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON TABLE public.referentiel_paiement IS
  'CAND-L6 : referentiel declaratif de compatibilite de paiement (CAND-Q05, DEC:28). Aucune '
  'policy : lecture et ecriture par les RPC du referentiel (direction et comptabilite), lecture '
  'des seules lignes confirme par le candidat (options_paiement_confirmees). Ne verse rien.';
COMMENT ON TABLE public.referentiel_paiement_afrique IS
  'CAND-L6 : pays d Afrique selon l ONU, norme M49, region 002 Afrique '
  '(https://unstats.un.org/unsd/methodology/m49/overview/, lue le 21/10/2026, 60 pays ou '
  'territoires). Proposee au directeur avec CAND-Q05 ; decide qui entre en salle 2.';
COMMENT ON TABLE public.referentiel_paiement_afrique_decisions IS
  'CAND-L6 : decisions datees du directeur sur l Afrique (CAND-Q05), ajout seul ; la plus recente '
  'fait foi et la cle app_config paiement.afrique_ouverte la recopie. Aucun privilege client : le '
  'seul proprietaire de la base y ecrit (migration ou editeur SQL).';
COMMENT ON TABLE public.referentiel_paiement_operateurs IS
  'CAND-L6 : catalogue ferme des operateurs, etendu par migration ; le nom est une marque.';
COMMENT ON TABLE public.referentiel_paiement_journal IS
  'CAND-L6 : journal en ajout seul des changements du referentiel, avec cle d idempotence et '
  'effets comptes (alerte a la direction et a la comptabilite).';
COMMENT ON TABLE public.candidature_paiement_decisions IS
  'CAND-L6 : decisions de la direction sur un moyen declare (transitions 24 et 25, gestes du lot '
  'L2). Ajout seul ; la plus recente par moyen fait foi ; aucune policy.';

-- ============================================================
-- 3. Aides internes (schema private, jamais appelables par un compte)
-- ============================================================

-- Ajout seul, pour le journal du referentiel et les decisions.
CREATE FUNCTION private.paiement_refuser_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'CAND-L6 : % en ajout seul', TG_TABLE_NAME USING ERRCODE = '55000';
END;
$function$;
CREATE TRIGGER referentiel_paiement_journal_ajout_seul
  BEFORE UPDATE OR DELETE ON public.referentiel_paiement_journal
  FOR EACH ROW EXECUTE FUNCTION private.paiement_refuser_mutation();
CREATE TRIGGER candidature_paiement_decisions_ajout_seul
  BEFORE UPDATE OR DELETE ON public.candidature_paiement_decisions
  FOR EACH ROW EXECUTE FUNCTION private.paiement_refuser_mutation();
CREATE TRIGGER referentiel_paiement_afrique_decisions_ajout_seul
  BEFORE UPDATE OR DELETE ON public.referentiel_paiement_afrique_decisions
  FOR EACH ROW EXECUTE FUNCTION private.paiement_refuser_mutation();

-- CAND-Q05 tranche ou non : la derniere decision du directeur (R12) ; sans
-- decision, ferme.
CREATE FUNCTION private.paiement_afrique_ouverte()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT coalesce((SELECT d.ouverte FROM public.referentiel_paiement_afrique_decisions d
                   ORDER BY d.id DESC LIMIT 1), false);
$function$;

-- Garde de table : tant que CAND-Q05 est ouvert, toute ligne d'un pays
-- d'Afrique reste en_verification (spec consolidee 5.1 et 0.3), par quelque
-- voie que ce soit.
CREATE FUNCTION private.paiement_garde_afrique()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.etat <> 'en_verification'
     AND EXISTS (SELECT 1 FROM public.referentiel_paiement_afrique a WHERE a.pays = NEW.pays)
     AND NOT private.paiement_afrique_ouverte() THEN
    RAISE EXCEPTION 'CAND-L6 : pays d''Afrique en verification tant que CAND-Q05 est ouvert (%)', NEW.pays
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER referentiel_paiement_garde_afrique
  BEFORE INSERT OR UPDATE ON public.referentiel_paiement
  FOR EACH ROW EXECUTE FUNCTION private.paiement_garde_afrique();

-- Garde de table (R4) : le pays, la methode et l'operateur d'une ligne ne
-- changent pas, aucune ligne ne s'efface ; toute modification augmente la
-- version, par quelque voie que ce soit.
CREATE FUNCTION private.paiement_ligne_identite()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'CAND-L6 : une ligne du referentiel ne s''efface pas, elle passe indisponible'
      USING ERRCODE = '55000';
  END IF;
  IF NEW.id <> OLD.id OR NEW.pays <> OLD.pays OR NEW.methode <> OLD.methode
     OR NEW.operateur IS DISTINCT FROM OLD.operateur THEN
    RAISE EXCEPTION 'CAND-L6 : pays, methode et operateur d''une ligne ne changent pas'
      USING ERRCODE = '55000';
  END IF;
  NEW.version := OLD.version + 1;
  NEW.cree_le := OLD.cree_le;
  NEW.modifie_le := pg_catalog.clock_timestamp();
  RETURN NEW;
END;
$function$;
CREATE TRIGGER referentiel_paiement_identite
  BEFORE UPDATE OR DELETE ON public.referentiel_paiement
  FOR EACH ROW EXECUTE FUNCTION private.paiement_ligne_identite();

-- La cle app_config paiement.afrique_ouverte (R12) : aucune ecriture directe,
-- seule la recopie de la derniere decision (declencheur de la table des
-- decisions, profondeur 2, comme c29_proteger_quota_controle) ; ni effacement
-- ni renommage.
CREATE FUNCTION private.paiement_proteger_cle_afrique()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.key = 'paiement.afrique_ouverte' THEN
      RAISE EXCEPTION 'la cle paiement.afrique_ouverte ne s''efface pas : elle suit la decision datee du directeur'
        USING ERRCODE = '42501';
    END IF;
    RETURN OLD;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.key = 'paiement.afrique_ouverte'
     AND NEW.key IS DISTINCT FROM 'paiement.afrique_ouverte' THEN
    RAISE EXCEPTION 'la cle paiement.afrique_ouverte ne se renomme pas' USING ERRCODE = '42501';
  END IF;
  IF NEW.key = 'paiement.afrique_ouverte' THEN
    IF pg_catalog.pg_trigger_depth() < 2 THEN
      RAISE EXCEPTION 'la cle paiement.afrique_ouverte suit la decision datee du directeur (referentiel_paiement_afrique_decisions)'
        USING ERRCODE = '42501';
    END IF;
    IF NEW.value IS DISTINCT FROM pg_catalog.to_jsonb(private.paiement_afrique_ouverte()) THEN
      RAISE EXCEPTION 'la cle paiement.afrique_ouverte vaut la derniere decision du directeur'
        USING ERRCODE = '42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER app_config_paiement_afrique_ouverte
  BEFORE INSERT OR UPDATE OR DELETE ON public.app_config
  FOR EACH ROW EXECUTE FUNCTION private.paiement_proteger_cle_afrique();

-- Une decision de fermeture exige que toutes les lignes d'Afrique soient
-- revenues a en_verification (R12) : la cle fermee ne coexiste jamais avec une
-- ligne d'Afrique confirme ou indisponible.
CREATE FUNCTION private.paiement_afrique_decision_valide()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_hors integer;
BEGIN
  IF NOT NEW.ouverte THEN
    SELECT pg_catalog.count(*)::integer INTO v_hors
    FROM public.referentiel_paiement l
    JOIN public.referentiel_paiement_afrique a ON a.pays = l.pays
    WHERE l.etat <> 'en_verification';
    IF v_hors > 0 THEN
      RAISE EXCEPTION 'CAND-L6 : fermer l''Afrique exige ses lignes en_verification (% hors en_verification)', v_hors
        USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER referentiel_paiement_afrique_decisions_valide
  BEFORE INSERT ON public.referentiel_paiement_afrique_decisions
  FOR EACH ROW EXECUTE FUNCTION private.paiement_afrique_decision_valide();

-- La recopie de la decision dans app_config, seule ecriture admise de la cle.
CREATE FUNCTION private.paiement_afrique_decision_appliquer()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  INSERT INTO public.app_config (key, value, updated_by, updated_at)
  VALUES ('paiement.afrique_ouverte', pg_catalog.to_jsonb(NEW.ouverte), NULL, pg_catalog.clock_timestamp())
  ON CONFLICT (key) DO UPDATE
    SET value = excluded.value, updated_by = NULL, updated_at = excluded.updated_at;
  RETURN NULL;
END;
$function$;
CREATE TRIGGER referentiel_paiement_afrique_decisions_appliquer
  AFTER INSERT ON public.referentiel_paiement_afrique_decisions
  FOR EACH ROW EXECUTE FUNCTION private.paiement_afrique_decision_appliquer();

-- Ce qu'un compte voit du referentiel (R1) : la comptabilite active (tout,
-- sans cote) ; la direction active, de son cote, ou les deux cotes sous
-- l'exception super-admin ; une direction au genre inconnu sans l'exception
-- n'est pas gestionnaire. Aucune ligne pour tout autre appelant.
CREATE FUNCTION private.paiement_portee()
RETURNS TABLE (gestionnaire boolean, tout boolean, genre public.gender, super_admin boolean)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT true, true, NULL::public.gender, false
  WHERE coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'accountant'
                 AND public.app_account_valid(), false)
  UNION ALL
  SELECT (l.genre IS NOT NULL OR l.super_admin), l.super_admin, l.genre, l.super_admin
  FROM private.cand_lecteur() l;
$function$;

-- La direction ou la comptabilite active, dans sa portee (R1).
CREATE FUNCTION private.paiement_gestionnaire()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT coalesce((SELECT p.gestionnaire FROM private.paiement_portee() p LIMIT 1), false);
$function$;

-- Les restrictions d'un changement que voit un lecteur (R1) : le total, ou
-- celles de son cote.
CREATE FUNCTION private.paiement_impact_lecteur(p_impact jsonb, p_tout boolean, p_genre public.gender)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE WHEN coalesce(p_tout, false)
              THEN coalesce((p_impact ->> 'restrictions')::integer, 0)
              ELSE coalesce((p_impact -> 'parGenre' -> (p_genre::text) ->> 'restrictions')::integer, 0)
         END;
$function$;

-- La forme d'une ligne pour la direction et la comptabilite (R10).
CREATE FUNCTION private.paiement_ligne_json(l public.referentiel_paiement)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', l.id,
    'pays', l.pays,
    'afrique', EXISTS (SELECT 1 FROM public.referentiel_paiement_afrique a WHERE a.pays = l.pays),
    'methode', l.methode,
    'operateur', l.operateur,
    'operateurNom', (SELECT o.nom FROM public.referentiel_paiement_operateurs o WHERE o.code = l.operateur),
    'prestataire', l.prestataire,
    'devise', l.devise,
    'typeDecaissement', l.type_decaissement,
    'etat', l.etat,
    'capacitePayout', CASE l.etat WHEN 'confirme' THEN 'prisEnCharge'
                                  WHEN 'en_verification' THEN 'verificationRequise'
                                  ELSE 'nonPrisEnCharge' END,
    'source', l.source,
    'sourceRef', l.source_ref,
    'verifieLe', l.verifie_le,
    'verifiePar', l.verifie_par,
    'verifieParNom', (SELECT nullif(pg_catalog.btrim(pg_catalog.concat_ws(' ', p.first_name, p.last_name)), '')
                      FROM public.profiles p WHERE p.id = l.verifie_par),
    'notes', l.notes,
    'version', l.version,
    'modifieLe', private.cand_instant(l.modifie_le));
$function$;

-- La declaration de paiement d'une candidature : le document de reponses le
-- plus recent de source candidat, ses trois cles normalisees, ou null.
CREATE FUNCTION private.paiement_declaration(p_candidature uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN d.reponses ->> 'paysVersement' ~ '^[A-Z]{2}$'
         AND pg_catalog.jsonb_typeof(d.reponses -> 'compteBancaire') = 'boolean'
    THEN pg_catalog.jsonb_build_object(
      'paysVersement', d.reponses ->> 'paysVersement',
      'compteBancaire', (d.reponses ->> 'compteBancaire')::boolean,
      'operateurs', coalesce((
        SELECT pg_catalog.jsonb_agg(DISTINCT o.code ORDER BY o.code)
        FROM pg_catalog.jsonb_array_elements_text(
               CASE WHEN pg_catalog.jsonb_typeof(d.reponses -> 'operateurs') = 'array'
                    THEN d.reponses -> 'operateurs' ELSE '[]'::jsonb END) AS o(code)
        WHERE o.code ~ '^[a-z][a-z0-9_]{1,39}$'), '[]'::jsonb))
  END
  FROM (SELECT (SELECT r.reponses FROM public.candidature_reponses r
                WHERE r.candidature_id = p_candidature AND r.source = 'candidat'
                ORDER BY r.soumis_le DESC, r.id DESC
                LIMIT 1) AS reponses) d;
$function$;

-- La dimension paiement (spec consolidee 5.1) : voir Calcul dans l'en-tete.
CREATE FUNCTION private.paiement_etat(p_candidature uuid)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_decl jsonb;
  v_pays text;
  v_croises integer;
  v_confirmes integer;
  v_infirmes integer;
BEGIN
  v_decl := private.paiement_declaration(p_candidature);
  IF v_decl IS NULL THEN
    RETURN 'inconnu';
  END IF;
  v_pays := v_decl ->> 'paysVersement';

  WITH moyens AS (
    SELECT 'virement_bancaire'::text AS methode, NULL::text AS operateur
    WHERE (v_decl ->> 'compteBancaire')::boolean
    UNION
    SELECT 'mobile_money', o.code
    FROM pg_catalog.jsonb_array_elements_text(v_decl -> 'operateurs') AS o(code)
  ), croises AS (
    SELECT m.methode, m.operateur,
           (SELECT d.decision FROM public.candidature_paiement_decisions d
            WHERE d.candidature_id = p_candidature AND d.pays = v_pays
              AND d.methode = m.methode AND d.operateur IS NOT DISTINCT FROM m.operateur
            ORDER BY d.cree_le DESC, d.id DESC
            LIMIT 1) AS decision
    FROM moyens m
    WHERE EXISTS (SELECT 1 FROM public.referentiel_paiement l
                  WHERE l.pays = v_pays AND l.etat = 'confirme' AND l.methode = m.methode
                    AND (m.methode = 'virement_bancaire' OR l.operateur = m.operateur))
  )
  SELECT pg_catalog.count(*)::integer,
         pg_catalog.count(*) FILTER (WHERE c.decision = 'confirme')::integer,
         pg_catalog.count(*) FILTER (WHERE c.decision = 'infirme')::integer
    INTO v_croises, v_confirmes, v_infirmes
  FROM croises c;

  IF v_croises = 0 THEN
    RETURN 'incompatible';
  ELSIF v_confirmes > 0 THEN
    RETURN 'compatible';
  ELSIF v_infirmes = v_croises THEN
    RETURN 'incompatible';
  END IF;
  RETURN 'a_verifier';
END;
$function$;

-- Le controle paiement_compatible (spec consolidee 5), lu par L2.
CREATE FUNCTION private.paiement_compatible(p_candidature uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT private.paiement_etat(p_candidature) = 'compatible';
$function$;

-- Une decision de la direction (R8) : une confirmation exige un moyen declare
-- du pays de versement qui croise une ligne confirme ; une ligne
-- en_verification ou indisponible ne se confirme jamais (transition 24).
CREATE FUNCTION private.paiement_decision_valide()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_decl jsonb;
BEGIN
  IF NEW.decision <> 'confirme' THEN
    RETURN NEW;
  END IF;
  v_decl := private.paiement_declaration(NEW.candidature_id);
  IF v_decl IS NULL
     OR v_decl ->> 'paysVersement' IS DISTINCT FROM NEW.pays
     OR NOT ((NEW.methode = 'virement_bancaire' AND (v_decl ->> 'compteBancaire')::boolean)
             OR (NEW.methode = 'mobile_money' AND (v_decl -> 'operateurs') ? NEW.operateur))
     OR NOT EXISTS (SELECT 1 FROM public.referentiel_paiement l
                    WHERE l.pays = NEW.pays AND l.etat = 'confirme' AND l.methode = NEW.methode
                      AND (NEW.methode = 'virement_bancaire' OR l.operateur = NEW.operateur)) THEN
    RAISE EXCEPTION 'CAND-L6 : moyen non declare ou sans ligne confirme, il ne se confirme pas'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER candidature_paiement_decisions_valide
  BEFORE INSERT ON public.candidature_paiement_decisions
  FOR EACH ROW EXECUTE FUNCTION private.paiement_decision_valide();

-- Recalcule la dimension paiement d'une candidature et applique les effets
-- automatiques (R5). Causes : referentiel (une ligne passe ou quitte
-- confirme), reponses (L2, apres l'ecriture des reponses), moyen_confirme et
-- moyen_infirme (L2, apres une decision ; motif exige pour moyen_infirme).
-- p_ligne_confirmee : la ligne p_ligne vient de passer confirme (transition 9).
-- Rend l'effet : aucun, paiement, a_completer, paiement_non_disponible,
-- bloquee, restriction, deja_restreinte.
CREATE FUNCTION private.paiement_recalculer(
  p_candidature uuid,
  p_cause text,
  p_auteur uuid DEFAULT NULL,
  p_motif text DEFAULT NULL,
  p_ligne uuid DEFAULT NULL,
  p_ligne_confirmee boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures;
  v_avant text;
  v_apres text;
  v_effet text := 'aucun';
  v_cause jsonb;
  v_motif text := nullif(pg_catalog.btrim(p_motif), '');
BEGIN
  IF p_cause IS NULL OR p_cause NOT IN ('referentiel', 'reponses', 'moyen_confirme', 'moyen_infirme') THEN
    RAISE EXCEPTION 'CAND-L6 : cause de recalcul inconnue' USING ERRCODE = '22023';
  END IF;
  IF p_cause = 'moyen_infirme' AND (v_motif IS NULL OR p_auteur IS NULL) THEN
    RAISE EXCEPTION 'CAND-L6 : un moyen infirme exige un auteur et un motif' USING ERRCODE = '22023';
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_candidature FOR UPDATE;
  IF v_c.id IS NULL THEN
    RAISE EXCEPTION 'CAND-L6 : candidature inconnue' USING ERRCODE = '22023';
  END IF;
  IF v_c.issue <> 'en_cours' OR v_c.profile_id IS NULL
     OR v_c.etape NOT IN ('prequalification', 'verifications', 'confirmee') THEN
    RETURN pg_catalog.jsonb_build_object('candidature', v_c.id, 'effet', 'aucun',
      'paiementAvant', v_c.paiement, 'paiementApres', v_c.paiement);
  END IF;

  v_avant := v_c.paiement;
  v_apres := private.paiement_etat(v_c.id);
  v_cause := pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
    'cause', p_cause, 'ligne', p_ligne, 'paiementAvant', v_avant, 'paiementApres', v_apres));

  IF v_apres IS DISTINCT FROM v_avant THEN
    INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, details)
    VALUES (v_c.id, 'controle', p_auteur, v_cause || pg_catalog.jsonb_build_object(
      'controle', 'paiement_compatible',
      'valeurAvant', v_avant = 'compatible',
      'valeurApres', v_apres = 'compatible'));
  END IF;

  IF v_c.etape = 'prequalification' AND v_c.etat = 'paiement_non_disponible'
     AND p_cause = 'referentiel' AND p_ligne_confirmee THEN
    -- Transition 9 : une ligne du pays passe confirme.
    UPDATE public.candidatures
       SET etat = 'a_completer', paiement = v_apres, version = version + 1
     WHERE id = v_c.id;
    INSERT INTO public.candidature_evenements
      (candidature_id, type, etape_avant, etape_apres, etat_avant, etat_apres, auteur_id, details)
    VALUES (v_c.id, 'transition', 'prequalification', 'prequalification',
            'paiement_non_disponible', 'a_completer', NULL,
            v_cause || pg_catalog.jsonb_build_object('transition', 9,
              'aCompleter', pg_catalog.jsonb_build_array('moyen_paiement'),
              'aNotifier', 'paiement_possible'));
    v_effet := 'a_completer';
  ELSIF v_c.etape = 'prequalification' AND v_c.etat = 'en_examen' AND v_apres = 'incompatible' THEN
    -- Transition 8 : aucun moyen ne croise une ligne confirme, moyen infirme ou
    -- ligne qui quitte confirme ; la cause et le motif eventuel sont traces.
    UPDATE public.candidatures
       SET etat = 'paiement_non_disponible', paiement = v_apres, version = version + 1
     WHERE id = v_c.id;
    INSERT INTO public.candidature_evenements
      (candidature_id, type, etape_avant, etape_apres, etat_avant, etat_apres, auteur_id,
       motif_interne, details)
    VALUES (v_c.id, 'transition', 'prequalification', 'prequalification',
            'en_examen', 'paiement_non_disponible', p_auteur, v_motif,
            v_cause || pg_catalog.jsonb_build_object('transition', 8));
    v_effet := 'paiement_non_disponible';
  ELSIF v_c.etape = 'confirmee' AND v_apres <> 'compatible' AND NOT v_c.restreinte THEN
    -- Transition 20, automatique : restriction cause paiement, etape gardee.
    -- Le calcul en direct seul decide, jamais la colonne paiement : une
    -- personne en salle 3 est toujours compatible ou restreinte (R5, R13).
    UPDATE public.candidatures
       SET restreinte = true, restriction_cause = 'paiement', paiement = v_apres,
           version = version + 1
     WHERE id = v_c.id;
    INSERT INTO public.candidature_evenements
      (candidature_id, type, etape_avant, etape_apres, auteur_id, motif_interne, details)
    VALUES (v_c.id, 'restriction', 'confirmee', 'confirmee', p_auteur,
            'Paiement à revérifier : aucun moyen confirmé ne croise plus une ligne confirmée du pays de versement.',
            v_cause || pg_catalog.jsonb_build_object('transition', 20, 'restrictionCause', 'paiement'));
    v_effet := 'restriction';
  ELSIF v_apres IS DISTINCT FROM v_avant THEN
    UPDATE public.candidatures
       SET paiement = v_apres, version = version + 1
     WHERE id = v_c.id;
    -- Salle 2 : le controle tombe, sauf si la colonne le disait deja faux.
    v_effet := CASE
      WHEN v_c.etape = 'verifications' AND v_apres <> 'compatible'
           AND v_avant IN ('compatible', 'inconnu') THEN 'bloquee'
      WHEN v_c.etape = 'confirmee' AND v_apres <> 'compatible' THEN 'deja_restreinte'
      ELSE 'paiement' END;
  END IF;

  IF v_effet IN ('a_completer', 'paiement_non_disponible', 'restriction') THEN
    PERFORM public.log_sensitive_access('candidature_effet_paiement', 'candidatures', v_c.id::text,
      v_cause || pg_catalog.jsonb_build_object('effet', v_effet));
  END IF;

  RETURN pg_catalog.jsonb_build_object('candidature', v_c.id, 'effet', v_effet,
    'paiementAvant', v_avant, 'paiementApres', v_apres);
END;
$function$;

-- Les compteurs d'une serie d'effets ({genre, effet}), tous ou d'un genre.
CREATE FUNCTION private.paiement_compteurs(p_resultats jsonb, p_genre text)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'restrictions', pg_catalog.count(*) FILTER (WHERE r.e ->> 'effet' = 'restriction'),
    'bloquees', pg_catalog.count(*) FILTER (WHERE r.e ->> 'effet' = 'bloquee'),
    'paiementNonDisponible', pg_catalog.count(*) FILTER (WHERE r.e ->> 'effet' = 'paiement_non_disponible'),
    'aCompleter', pg_catalog.count(*) FILTER (WHERE r.e ->> 'effet' = 'a_completer'),
    'recalculees', pg_catalog.count(*))
  FROM pg_catalog.jsonb_array_elements(coalesce(p_resultats, '[]'::jsonb)) AS r(e)
  WHERE p_genre IS NULL OR r.e ->> 'genre' = p_genre;
$function$;

-- Les effets d'une ligne qui passe ou quitte confirme (R5), comptes pour le
-- journal : restrictions (la valeur impact de PORTS), bloquees,
-- paiementNonDisponible, aCompleter, recalculees, et les memes par genre de
-- la candidature (parGenre), pour borner ce que lit chaque compte (R1).
CREATE FUNCTION private.paiement_appliquer_ligne(p_ligne uuid, p_etait_confirme boolean)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_l public.referentiel_paiement;
  v_passe boolean;
  v_c record;
  v_r jsonb;
  v_resultats jsonb := '[]'::jsonb;
BEGIN
  SELECT l.* INTO v_l FROM public.referentiel_paiement l WHERE l.id = p_ligne;
  IF v_l.id IS NULL THEN
    RAISE EXCEPTION 'CAND-L6 : ligne du referentiel inconnue' USING ERRCODE = '22023';
  END IF;
  v_passe := v_l.etat = 'confirme' AND NOT coalesce(p_etait_confirme, false);
  IF v_passe OR (coalesce(p_etait_confirme, false) AND v_l.etat <> 'confirme') THEN
    FOR v_c IN
      SELECT c.id, c.genre FROM public.candidatures c
      WHERE c.issue = 'en_cours' AND c.profile_id IS NOT NULL
        AND c.etape IN ('prequalification', 'verifications', 'confirmee')
        AND private.paiement_declaration(c.id) ->> 'paysVersement' = v_l.pays
      ORDER BY c.id
    LOOP
      v_r := private.paiement_recalculer(v_c.id, 'referentiel', NULL, NULL, v_l.id, v_passe);
      v_resultats := v_resultats || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'genre', v_c.genre::text, 'effet', v_r ->> 'effet'));
    END LOOP;
  END IF;
  RETURN private.paiement_compteurs(v_resultats, NULL)
    || pg_catalog.jsonb_build_object('parGenre', pg_catalog.jsonb_build_object(
         'female', private.paiement_compteurs(v_resultats, 'female'),
         'male', private.paiement_compteurs(v_resultats, 'male')));
END;
$function$;

-- Le declencheur du referentiel (R5) : chaque ecriture, par quelque voie que
-- ce soit, applique ses effets, se journalise et laisse une entree d'audit.
-- L'auteur, la cle et l'empreinte ne viennent que de la RPC, qui les pose
-- pour la seule ligne qu'elle ecrit (reglage local cand_l6.ecriture, consomme
-- ici) ; hors de la RPC, le journal n'a ni auteur ni cle (voie directe).
CREATE FUNCTION private.paiement_ligne_effets()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_ecriture jsonb := nullif(pg_catalog.current_setting('cand_l6.ecriture', true), '')::jsonb;
  v_auteur uuid;
  v_cle text;
  v_empreinte text;
  v_avant jsonb;
  v_effets jsonb;
BEGIN
  IF v_ecriture IS NOT NULL
     AND v_ecriture ->> 'pays' = NEW.pays AND v_ecriture ->> 'methode' = NEW.methode
     AND (v_ecriture ->> 'operateur') IS NOT DISTINCT FROM NEW.operateur THEN
    v_auteur := (v_ecriture ->> 'auteur')::uuid;
    v_cle := v_ecriture ->> 'cle';
    v_empreinte := v_ecriture ->> 'empreinte';
    PERFORM pg_catalog.set_config('cand_l6.ecriture', '', true);
  END IF;
  IF TG_OP = 'UPDATE' THEN
    v_avant := pg_catalog.to_jsonb(OLD);
  END IF;
  v_effets := private.paiement_appliquer_ligne(NEW.id, TG_OP = 'UPDATE' AND OLD.etat = 'confirme');
  INSERT INTO public.referentiel_paiement_journal
    (ligne_id, avant, apres, auteur_id, cle_idempotence, empreinte, impact)
  VALUES (NEW.id, v_avant, pg_catalog.to_jsonb(NEW), v_auteur, v_cle, v_empreinte, v_effets);
  -- audit_logs est lisible par toute direction active (audit_logs_read) : les
  -- compteurs restent dans le journal du referentiel, qu'aucun compte ne lit.
  PERFORM public.log_sensitive_access('referentiel_paiement_ecriture', 'referentiel_paiement',
    NEW.id::text, pg_catalog.jsonb_build_object(
      'pays', NEW.pays, 'methode', NEW.methode, 'operateur', NEW.operateur,
      'etatAvant', v_avant ->> 'etat', 'etatApres', NEW.etat,
      'voie', CASE WHEN v_cle IS NULL THEN 'directe' ELSE 'rpc' END));
  RETURN NULL;
END;
$function$;

REVOKE ALL ON FUNCTION private.paiement_refuser_mutation(), private.paiement_afrique_ouverte(),
  private.paiement_garde_afrique(), private.paiement_ligne_identite(),
  private.paiement_proteger_cle_afrique(), private.paiement_afrique_decision_valide(),
  private.paiement_afrique_decision_appliquer(), private.paiement_portee(),
  private.paiement_gestionnaire(), private.paiement_impact_lecteur(jsonb, boolean, public.gender),
  private.paiement_ligne_json(public.referentiel_paiement), private.paiement_declaration(uuid),
  private.paiement_etat(uuid), private.paiement_compatible(uuid), private.paiement_decision_valide(),
  private.paiement_recalculer(uuid, text, uuid, text, uuid, boolean),
  private.paiement_compteurs(jsonb, text), private.paiement_appliquer_ligne(uuid, boolean),
  private.paiement_ligne_effets()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 4. Etat initial (DEC:28) et liste des pays d'Afrique (ONU M49)
-- ============================================================

INSERT INTO public.referentiel_paiement_afrique (pays, region_m49)
SELECT v.pays, v.region FROM (VALUES
  ('DZ', '015'), ('EG', '015'), ('LY', '015'), ('MA', '015'), ('SD', '015'), ('TN', '015'), ('EH', '015'),
  ('IO', '014'), ('BI', '014'), ('KM', '014'), ('DJ', '014'), ('ER', '014'), ('ET', '014'), ('TF', '014'),
  ('KE', '014'), ('MG', '014'), ('MW', '014'), ('MU', '014'), ('YT', '014'), ('MZ', '014'), ('RE', '014'),
  ('RW', '014'), ('SC', '014'), ('SO', '014'), ('SS', '014'), ('UG', '014'), ('TZ', '014'), ('ZM', '014'),
  ('ZW', '014'),
  ('AO', '017'), ('CM', '017'), ('CF', '017'), ('TD', '017'), ('CG', '017'), ('CD', '017'), ('GQ', '017'),
  ('GA', '017'), ('ST', '017'),
  ('BW', '018'), ('SZ', '018'), ('LS', '018'), ('NA', '018'), ('ZA', '018'),
  ('BJ', '011'), ('BF', '011'), ('CV', '011'), ('CI', '011'), ('GM', '011'), ('GH', '011'), ('GN', '011'),
  ('GW', '011'), ('LR', '011'), ('ML', '011'), ('MR', '011'), ('NE', '011'), ('NG', '011'), ('SH', '011'),
  ('SN', '011'), ('SL', '011'), ('TG', '011')
) AS v(pays, region);

-- Les operateurs que nomme la spec v1 (section 4.2) ; leur disponibilite
-- n'est posee dans aucun pays.
INSERT INTO public.referentiel_paiement_operateurs (code, methode, nom) VALUES
  ('wave', 'mobile_money', 'Wave'),
  ('orange_money', 'mobile_money', 'Orange Money'),
  ('moov_money', 'mobile_money', 'Moov Money');

-- Les 249 codes de lib/core/i18n/pays_iso.dart, dans le meme ordre.
INSERT INTO public.referentiel_paiement (pays, methode, etat, source, source_ref, verifie_le, notes)
SELECT p.code, 'virement_bancaire',
       CASE WHEN a.pays IS NULL THEN 'confirme' ELSE 'en_verification' END,
       'decision_directeur', 'DEC:28 (CAND-Q05, 21/10/2026)',
       CASE WHEN a.pays IS NULL THEN DATE '2026-10-21' END,
       CASE WHEN a.pays IS NULL
         THEN 'Décision du directeur du 21/10, DEC:28 : virement bancaire hors d''Afrique, Arabie saoudite comprise. Règle décidée, pays non vérifié un à un : un pays où l''académie ne peut pas verser se signale au directeur.'
         ELSE 'Décision du directeur du 21/10, DEC:28 : pays d''Afrique (ONU, M49), en vérification tant que CAND-Q05 est ouvert, compte bancaire compris.'
       END
FROM pg_catalog.unnest(ARRAY[
  'AF','AX','AL','DZ','AS','AD','AO','AI','AQ','AG','AR','AM','AW','AU','AT','AZ','BS','BH','BD','BB',
  'BY','BE','BZ','BJ','BM','BT','BO','BQ','BA','BW','BV','BR','IO','BN','BG','BF','BI','CV','KH','CM',
  'CA','KY','CF','TD','CL','CN','CX','CC','CO','KM','CG','CD','CK','CR','CI','HR','CU','CW','CY','CZ',
  'DK','DJ','DM','DO','EC','EG','SV','GQ','ER','EE','SZ','ET','FK','FO','FJ','FI','FR','GF','PF','TF',
  'GA','GM','GE','DE','GH','GI','GR','GL','GD','GP','GU','GT','GG','GN','GW','GY','HT','HM','VA','HN',
  'HK','HU','IS','IN','ID','IR','IQ','IE','IM','IL','IT','JM','JP','JE','JO','KZ','KE','KI','KP','KR',
  'KW','KG','LA','LV','LB','LS','LR','LY','LI','LT','LU','MO','MG','MW','MY','MV','ML','MT','MH','MQ',
  'MR','MU','YT','MX','FM','MD','MC','MN','ME','MS','MA','MZ','MM','NA','NR','NP','NL','NC','NZ','NI',
  'NE','NG','NU','NF','MK','MP','NO','OM','PK','PW','PS','PA','PG','PY','PE','PH','PN','PL','PT','PR',
  'QA','RE','RO','RU','RW','BL','SH','KN','LC','MF','PM','VC','WS','SM','ST','SA','SN','RS','SC','SL',
  'SG','SX','SK','SI','SB','SO','ZA','GS','SS','ES','LK','SD','SR','SJ','SE','CH','SY','TW','TJ','TZ',
  'TH','TL','TG','TK','TO','TT','TN','TR','TM','TC','TV','UG','UA','AE','GB','US','UM','UY','UZ','VU',
  'VE','VN','VG','VI','WF','EH','YE','ZM','ZW'
]::text[]) WITH ORDINALITY AS p(code, rang)
LEFT JOIN public.referentiel_paiement_afrique a ON a.pays = p.code
ORDER BY p.rang;

-- L'etat initial est journalise comme tout changement, sans auteur ni cle.
-- Le declencheur des effets se pose ensuite : l'etat initial n'a aucune
-- candidature a recalculer et ne se journalise qu'une fois.
INSERT INTO public.referentiel_paiement_journal (ligne_id, avant, apres)
SELECT l.id, NULL, pg_catalog.to_jsonb(l) FROM public.referentiel_paiement l ORDER BY l.pays;
CREATE TRIGGER referentiel_paiement_effets
  AFTER INSERT OR UPDATE ON public.referentiel_paiement
  FOR EACH ROW EXECUTE FUNCTION private.paiement_ligne_effets();

-- CAND-Q05 ouvert (DEC:80-83) : premiere decision, fermee ; sa recopie pose la
-- cle app_config paiement.afrique_ouverte a false (R12).
INSERT INTO public.referentiel_paiement_afrique_decisions (ouverte, decision_ref, decide_le)
VALUES (false, 'DEC:80-83 (CAND-Q05 ouvert : pays et moyens d''Afrique, compte bancaire en Afrique)',
        DATE '2026-10-21');

-- ============================================================
-- 5. RPC
-- ============================================================

-- Ce que l'ecran du referentiel (Finance, DEC:85) peut offrir (R1) : la
-- comptabilite active, la direction active de genre connu ou sous l'exception
-- super-admin. Sans session : 42501.
CREATE FUNCTION public.capacites_referentiel_paiement()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_gestion boolean;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL, false) THEN
    RAISE EXCEPTION 'Acces refuse' USING ERRCODE = '42501';
  END IF;
  v_gestion := coalesce(public.app_role() IN ('admin', 'accountant') AND public.app_account_valid()
                        AND private.paiement_gestionnaire(), false);
  RETURN pg_catalog.jsonb_build_object('peutLire', v_gestion, 'peutEcrire', v_gestion);
END;
$function$;

-- Le referentiel pour la direction et la comptabilite (PORTS lister), tout ou
-- un pays, avec les listes de la fiche (operateurs, methodes, etats, types),
-- la liste des pays d'Afrique et sa source, la derniere decision sur
-- l'Afrique, et les alertes (R9) bornees au lecteur (R1). VOLATILE : une
-- lecture de l'autre cote par l'exception super-admin laisse une entree
-- audit_logs (C13 de L1).
CREATE FUNCTION public.lire_referentiel_paiement(p_pays text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_tout boolean;
  v_genre public.gender;
  v_super boolean;
  v_alertes jsonb;
  v_hors integer;
BEGIN
  IF NOT coalesce(public.app_role() IN ('admin', 'accountant') AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'referentiel de paiement reserve a la direction et a la comptabilite actives'
      USING ERRCODE = '42501';
  END IF;
  SELECT p.tout, p.genre, p.super_admin INTO v_tout, v_genre, v_super
  FROM private.paiement_portee() p WHERE p.gestionnaire LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : referentiel de paiement ferme tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF p_pays IS NOT NULL AND p_pays !~ '^[A-Z]{2}$' THEN
    RAISE EXCEPTION 'pays invalide : code ISO 3166-1 alpha-2 attendu' USING ERRCODE = '22023';
  END IF;

  -- Les alertes : les vingt derniers changements qui ont pose des
  -- restrictions dans la portee du lecteur, chacun avec ce nombre seul.
  WITH a AS (
    SELECT j.id, j.cree_le, j.ligne_id, j.avant, j.apres,
           private.paiement_impact_lecteur(j.impact, v_tout, v_genre) AS impact,
           coalesce((j.impact ->> 'restrictions')::integer, 0)
             - coalesce((j.impact -> 'parGenre' -> (v_genre::text) ->> 'restrictions')::integer, 0) AS hors
    FROM public.referentiel_paiement_journal j
    WHERE private.paiement_impact_lecteur(j.impact, v_tout, v_genre) > 0
    ORDER BY j.cree_le DESC, j.id DESC
    LIMIT 20
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', a.id,
           'quand', private.cand_instant(a.cree_le),
           'ligne', a.ligne_id,
           'pays', a.apres ->> 'pays',
           'methode', a.apres ->> 'methode',
           'operateur', a.apres ->> 'operateur',
           'etatAvant', a.avant ->> 'etat',
           'etatApres', a.apres ->> 'etat',
           'impact', a.impact) ORDER BY a.cree_le DESC, a.id DESC), '[]'::jsonb),
         coalesce(pg_catalog.sum(a.hors), 0)::integer
    INTO v_alertes, v_hors
  FROM a;
  IF v_super AND v_hors > 0 THEN
    PERFORM public.log_sensitive_access('referentiel_paiement_exception_super_admin', 'referentiel_paiement',
      NULL, pg_catalog.jsonb_build_object('lecture', 'alertes', 'restrictionsHorsGenre', v_hors,
                                          'motif', 'exception_super_admin_kyc'));
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'lignes', coalesce((
      SELECT pg_catalog.jsonb_agg(private.paiement_ligne_json(l)
               ORDER BY l.pays, l.methode, l.operateur NULLS FIRST)
      FROM public.referentiel_paiement l
      WHERE p_pays IS NULL OR l.pays = p_pays), '[]'::jsonb),
    'afriqueEnVerification', NOT private.paiement_afrique_ouverte(),
    'afrique', pg_catalog.jsonb_build_object(
      'source', 'ONU, Division de statistique, norme M49, region 002 Afrique, https://unstats.un.org/unsd/methodology/m49/overview/, lue le 21/10/2026',
      'pays', (SELECT pg_catalog.jsonb_agg(a.pays ORDER BY a.pays) FROM public.referentiel_paiement_afrique a),
      'decision', (SELECT pg_catalog.jsonb_build_object('ouverte', d.ouverte, 'reference', d.decision_ref,
                                                        'decideLe', d.decide_le)
                   FROM public.referentiel_paiement_afrique_decisions d ORDER BY d.id DESC LIMIT 1)),
    'options', pg_catalog.jsonb_build_object(
      'methodes', pg_catalog.jsonb_build_array('virement_bancaire', 'mobile_money'),
      'etats', pg_catalog.jsonb_build_array('confirme', 'en_verification', 'indisponible'),
      'typesDecaissement', pg_catalog.jsonb_build_array('virement_international', 'virement_local',
                                                         'payout_portefeuille'),
      'operateurs', coalesce((
        SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'code', o.code, 'methode', o.methode, 'nom', o.nom) ORDER BY o.nom, o.code)
        FROM public.referentiel_paiement_operateurs o WHERE o.actif), '[]'::jsonb)),
    'alertes', v_alertes);
END;
$function$;

-- Les moyens qu'un candidat peut declarer pour un pays de versement (PORTS
-- optionsConfirmees, R2) : les seules lignes confirme, sans note, sans
-- prestataire, sans source ni nom. Une liste vide dit : aucun moyen possible
-- dans ce pays. Titulaire d'une candidature en cours dont le compte est
-- valide au sens de L1-08 (en attente, provisoire ou actif, non supprime, non
-- expire), ou direction et comptabilite dans leur portee (R1).
CREATE FUNCTION public.options_paiement_confirmees(p_pays text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
       (public.app_role() IN ('admin', 'accountant') AND public.app_account_valid()
        AND private.paiement_gestionnaire())
       OR EXISTS (SELECT 1 FROM public.candidatures c
                  JOIN public.profiles p ON p.id = c.profile_id AND p.deleted_at IS NULL
                  WHERE c.profile_id = auth.uid() AND c.issue = 'en_cours'
                    AND p.account_status IN ('pending_kyc'::public.account_status,
                                             'provisional_active'::public.account_status,
                                             'active'::public.account_status)
                    AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())),
       false) THEN
    RAISE EXCEPTION 'moyens de paiement reserves au titulaire d''une candidature en cours'
      USING ERRCODE = '42501';
  END IF;
  IF p_pays IS NULL OR p_pays !~ '^[A-Z]{2}$' THEN
    RAISE EXCEPTION 'pays invalide : code ISO 3166-1 alpha-2 attendu' USING ERRCODE = '22023';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'pays', p_pays,
    'lignes', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'methode', l.methode,
               'operateur', l.operateur,
               'operateurNom', o.nom,
               'devise', l.devise) ORDER BY l.methode DESC, o.nom NULLS FIRST, l.operateur)
      FROM public.referentiel_paiement l
      LEFT JOIN public.referentiel_paiement_operateurs o ON o.code = l.operateur
      WHERE l.pays = p_pays AND l.etat = 'confirme'), '[]'::jsonb));
END;
$function$;

-- Enregistre une ligne (PORTS enregistrer, R3, R4, R5) : creation si p_id est
-- null, sinon modification de la ligne p_id a la version attendue. Refus rendus
-- (aucune ecriture) : confirmation_sans_verification, afrique_en_verification,
-- conflit_referentiel (avec la ligne relue), absente,
-- cle_idempotence_reutilisee. Parametre invalide : 22023 ; direction au genre
-- inconnu : 42501 (R1). L'ecriture declenche les effets et le journal (R5) ;
-- la RPC rend la ligne relue et l'impact relu dans le journal, borne au
-- lecteur (R1), jamais les autres compteurs.
CREATE FUNCTION public.enregistrer_ligne_referentiel_paiement(
  p_id uuid,
  p_pays text,
  p_methode text,
  p_operateur text,
  p_prestataire text,
  p_devise text,
  p_type_decaissement text,
  p_etat text,
  p_verifie_le date,
  p_notes text,
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_auteur uuid := auth.uid();
  v_tout boolean;
  v_genre public.gender;
  v_super boolean;
  v_notes text := nullif(pg_catalog.btrim(p_notes), '');
  v_empreinte text;
  v_j public.referentiel_paiement_journal;
  v_l public.referentiel_paiement;
  v_rejoue boolean := false;
  v_hors integer;
BEGIN
  IF NOT coalesce(public.app_role() IN ('admin', 'accountant') AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'referentiel de paiement reserve a la direction et a la comptabilite actives'
      USING ERRCODE = '42501';
  END IF;
  SELECT p.tout, p.genre, p.super_admin INTO v_tout, v_genre, v_super
  FROM private.paiement_portee() p WHERE p.gestionnaire LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : referentiel de paiement ferme tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF p_cle_idempotence IS NULL OR pg_catalog.length(p_cle_idempotence) NOT BETWEEN 8 AND 200 THEN
    RAISE EXCEPTION 'cle d''idempotence attendue (8 a 200 caracteres)' USING ERRCODE = '22023';
  END IF;

  v_empreinte := pg_catalog.md5(pg_catalog.jsonb_build_object(
    'id', p_id, 'pays', p_pays, 'methode', p_methode, 'operateur', p_operateur,
    'prestataire', p_prestataire, 'devise', p_devise, 'typeDecaissement', p_type_decaissement,
    'etat', p_etat, 'verifieLe', p_verifie_le, 'notes', v_notes,
    'versionAttendue', p_version_attendue)::text);

  -- Reprise : la meme cle rend l'effet d'origine, relu au serveur, sans
  -- nouvel effet.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('cand_l6_cle:' || p_cle_idempotence, 0));
  SELECT j.* INTO v_j FROM public.referentiel_paiement_journal j
  WHERE j.cle_idempotence = p_cle_idempotence;
  IF v_j.id IS NOT NULL THEN
    IF v_j.auteur_id IS DISTINCT FROM v_auteur OR v_j.empreinte IS DISTINCT FROM v_empreinte THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'cle_idempotence_reutilisee');
    END IF;
    v_rejoue := true;
  ELSE
    -- Parametres : formes et listes fermees (22023).
    IF p_pays IS NULL OR p_pays !~ '^[A-Z]{2}$'
       OR p_methode IS NULL OR p_methode NOT IN ('virement_bancaire', 'mobile_money')
       OR (p_methode = 'mobile_money' AND p_operateur IS NULL)
       OR (p_operateur IS NOT NULL AND NOT EXISTS (
             SELECT 1 FROM public.referentiel_paiement_operateurs o
             WHERE o.code = p_operateur AND o.methode = p_methode AND o.actif))
       OR (p_prestataire IS NOT NULL AND p_prestataire !~ '^[a-z][a-z0-9_]{1,39}$')
       OR (p_devise IS NOT NULL AND p_devise !~ '^[A-Z]{3}$')
       OR (p_type_decaissement IS NOT NULL AND p_type_decaissement NOT IN
             ('virement_international', 'virement_local', 'payout_portefeuille'))
       OR p_etat IS NULL OR p_etat NOT IN ('confirme', 'en_verification', 'indisponible')
       OR (p_verifie_le IS NOT NULL AND (NOT pg_catalog.isfinite(p_verifie_le)
             OR p_verifie_le > (pg_catalog.now() AT TIME ZONE 'UTC')::date + 1))
       OR pg_catalog.length(v_notes) > 2000 THEN
      RAISE EXCEPTION 'ligne du referentiel invalide' USING ERRCODE = '22023';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.referentiel_paiement l WHERE l.pays = p_pays) THEN
      RAISE EXCEPTION 'pays inconnu du referentiel' USING ERRCODE = '22023';
    END IF;

    -- confirme exige une date ; le responsable est le compte qui enregistre (R3).
    IF p_etat = 'confirme' AND p_verifie_le IS NULL THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'confirmation_sans_verification');
    END IF;
    -- Tant que CAND-Q05 est ouvert, une ligne d'Afrique reste en_verification.
    IF p_etat <> 'en_verification'
       AND EXISTS (SELECT 1 FROM public.referentiel_paiement_afrique a WHERE a.pays = p_pays)
       AND NOT private.paiement_afrique_ouverte() THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'afrique_en_verification', 'pays', p_pays);
    END IF;

    -- Un changement a la fois par pays : les effets se calculent sur un etat sur.
    PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('cand_l6_pays:' || p_pays, 0));

    IF p_id IS NULL THEN
      SELECT l.* INTO v_l FROM public.referentiel_paiement l
      WHERE l.pays = p_pays AND l.methode = p_methode
        AND coalesce(l.operateur, '') = coalesce(p_operateur, '');
      IF v_l.id IS NOT NULL OR p_version_attendue IS NOT NULL THEN
        RETURN pg_catalog.jsonb_build_object('erreur', 'conflit_referentiel',
          'ligne', CASE WHEN v_l.id IS NOT NULL THEN private.paiement_ligne_json(v_l) END);
      END IF;
    ELSE
      SELECT l.* INTO v_l FROM public.referentiel_paiement l WHERE l.id = p_id FOR UPDATE;
      IF v_l.id IS NULL THEN
        RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
      END IF;
      IF v_l.pays <> p_pays OR v_l.methode <> p_methode
         OR v_l.operateur IS DISTINCT FROM p_operateur THEN
        RAISE EXCEPTION 'pays, methode et operateur d''une ligne ne changent pas' USING ERRCODE = '22023';
      END IF;
      IF p_version_attendue IS DISTINCT FROM v_l.version THEN
        RETURN pg_catalog.jsonb_build_object('erreur', 'conflit_referentiel',
          'ligne', private.paiement_ligne_json(v_l));
      END IF;
    END IF;

    -- L'auteur, la cle et l'empreinte pour le declencheur (R5), pour cette
    -- seule ligne ; le declencheur les consomme.
    PERFORM pg_catalog.set_config('cand_l6.ecriture', pg_catalog.jsonb_build_object(
      'auteur', v_auteur, 'cle', p_cle_idempotence, 'empreinte', v_empreinte,
      'pays', p_pays, 'methode', p_methode, 'operateur', p_operateur)::text, true);
    IF p_id IS NULL THEN
      INSERT INTO public.referentiel_paiement
        (pays, methode, operateur, prestataire, devise, type_decaissement, etat, source,
         verifie_le, verifie_par, notes)
      VALUES (p_pays, p_methode, p_operateur, p_prestataire, p_devise, p_type_decaissement, p_etat,
              'verification', p_verifie_le, v_auteur, v_notes);
    ELSE
      UPDATE public.referentiel_paiement
         SET prestataire = p_prestataire, devise = p_devise, type_decaissement = p_type_decaissement,
             etat = p_etat, source = 'verification', source_ref = NULL,
             verifie_le = p_verifie_le, verifie_par = v_auteur, notes = v_notes
       WHERE id = v_l.id;
    END IF;
    PERFORM pg_catalog.set_config('cand_l6.ecriture', '', true);

    SELECT j.* INTO v_j FROM public.referentiel_paiement_journal j
    WHERE j.cle_idempotence = p_cle_idempotence;
    IF v_j.id IS NULL THEN
      RAISE EXCEPTION 'CAND-L6 : ecriture du referentiel sans journal' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  SELECT l.* INTO v_l FROM public.referentiel_paiement l WHERE l.id = v_j.ligne_id;
  -- Exception super-admin : des restrictions de l'autre cote rendues laissent
  -- une trace (C13 de L1).
  IF v_super THEN
    v_hors := coalesce((v_j.impact ->> 'restrictions')::integer, 0)
              - coalesce((v_j.impact -> 'parGenre' -> (v_genre::text) ->> 'restrictions')::integer, 0);
    IF v_hors > 0 THEN
      PERFORM public.log_sensitive_access('referentiel_paiement_exception_super_admin', 'referentiel_paiement',
        v_l.id::text, pg_catalog.jsonb_build_object('lecture', 'impact', 'restrictionsHorsGenre', v_hors,
                                                    'motif', 'exception_super_admin_kyc'));
    END IF;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'ligne', private.paiement_ligne_json(v_l),
    'impact', private.paiement_impact_lecteur(v_j.impact, v_tout, v_genre),
    'rejoue', v_rejoue);
END;
$function$;

-- ============================================================
-- 6. Droits, empreintes F86, controle final
-- ============================================================

DO $acl$
DECLARE
  f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.capacites_referentiel_paiement()',
    'public.lire_referentiel_paiement(text)',
    'public.options_paiement_confirmees(text)',
    'public.enregistrer_ligne_referentiel_paiement(uuid,text,text,text,text,text,text,text,date,text,integer,text)'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$acl$;

DO $droits$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT * FROM (VALUES
      ('public.capacites_referentiel_paiement()', 'SESSION_REQUIRED_CAPABILITY_READ',
       'Lecture seule : peutLire et peutEcrire pour la comptabilite active et la direction active de genre connu ou sous l exception super-admin (paiement.referentiel.ecrire). Sans session : 42501.'),
      ('public.lire_referentiel_paiement(text)', 'ROLE_POSITIVE_ADMIN_ACCOUNTANT_GENDER_SCOPED',
       'Comptabilite active, direction active de genre connu ou sous l exception super-admin, sinon 42501 ; pays invalide 22023 ; lignes avec notes et capacitePayout, liste des pays d Afrique, sa source et la derniere decision, options, alertes : restrictions de son cote (exception super-admin : deux cotes, journalise ; comptabilite : total), jamais une personne ni un autre compteur.'),
      ('public.options_paiement_confirmees(text)', 'POSITIVE_CANDIDATE_OR_ADMIN_ACCOUNTANT',
       'Titulaire d une candidature en cours au compte valide (L1-08 : en attente, provisoire ou actif, non expire, non supprime), ou direction et comptabilite dans leur portee, sinon 42501 ; seules les lignes confirme du pays, sans note, prestataire, source ni nom.'),
      ('public.enregistrer_ligne_referentiel_paiement(uuid,text,text,text,text,text,text,text,date,text,integer,text)', 'ROLE_POSITIVE_ADMIN_ACCOUNTANT_GENDER_SCOPED',
       'Comptabilite active, direction active de genre connu ou sous l exception super-admin, sinon 42501 ; parametre invalide 22023 ; refus rendus sans ecriture (confirmation sans date, Afrique en verification, conflit, absente, cle reutilisee) ; version attendue et cle d idempotence ; effets automatiques (transitions 8, 9 et 20), journal et audit par le declencheur de la table ; impact borne au lecteur.')
    ) AS t(signature, garde, note)
  LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v.signature, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-21. CAND-L6. %s Must-pass: supabase/tests/scenarios_cand_l6_referentiel_paiement.sql.',
      v.signature,
      pg_catalog.md5(pg_catalog.pg_get_functiondef(v.signature::regprocedure)),
      v.garde, v.note));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v record;
  v_role text;
BEGIN
  -- Les RPC : DEFINER, proprietaire postgres, search_path vide, volatilite
  -- attendue, empreinte F86 a jour, authenticated seul, garde positive.
  FOR v IN
    SELECT e.signature, e.volatilite, p.*
    FROM (VALUES
      ('public.capacites_referentiel_paiement()', 's'),
      ('public.lire_referentiel_paiement(text)', 'v'),
      ('public.options_paiement_confirmees(text)', 's'),
      ('public.enregistrer_ligne_referentiel_paiement(uuid,text,text,text,text,text,text,text,date,text,integer,text)', 'v')
    ) AS e(signature, volatilite)
    LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(e.signature)
  LOOP
    IF v.oid IS NULL
       OR NOT v.prosecdef
       OR pg_catalog.pg_get_userbyid(v.proowner) <> 'postgres'
       OR NOT coalesce(v.proconfig @> ARRAY['search_path=""'], false)
       OR v.provolatile::text <> v.volatilite
       OR coalesce(pg_catalog.obj_description(v.oid, 'pg_proc'), '')
          NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v.oid)) || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE')
       OR app_private.has_unsafe_role_guard(v.prosrc) THEN
      RAISE EXCEPTION 'CAND-L6 : DEFINER, proprietaire, search_path, volatilite, empreinte, ACL ou garde invalide : %',
        v.signature;
    END IF;
  END LOOP;

  -- Les aides internes : appelables par aucun compte.
  FOR v IN
    SELECT p.oid
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'private' AND p.proname LIKE 'paiement\_%'
  LOOP
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v.oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-L6 : aide interne % executable par %', v.oid::regprocedure, v_role;
      END IF;
    END LOOP;
  END LOOP;

  -- Les tables et les sequences : RLS active, aucun privilege client, aucune policy.
  FOR v IN
    SELECT c.oid, c.relkind, c.relrowsecurity
    FROM pg_catalog.pg_class c
    WHERE c.oid IN ('public.referentiel_paiement_afrique'::regclass,
                    'public.referentiel_paiement_afrique_decisions'::regclass,
                    'public.referentiel_paiement_afrique_decisions_id_seq'::regclass,
                    'public.referentiel_paiement_operateurs'::regclass,
                    'public.referentiel_paiement'::regclass,
                    'public.referentiel_paiement_journal'::regclass,
                    'public.candidature_paiement_decisions'::regclass,
                    'public.referentiel_paiement_journal_id_seq'::regclass,
                    'public.candidature_paiement_decisions_id_seq'::regclass)
  LOOP
    IF v.relkind = 'r' AND NOT v.relrowsecurity THEN
      RAISE EXCEPTION 'CAND-L6 : RLS inactive sur %', v.oid::regclass;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF (v.relkind = 'r' AND pg_catalog.has_table_privilege(v_role, v.oid,
            'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'))
         OR (v.relkind = 'S' AND pg_catalog.has_sequence_privilege(v_role, v.oid,
            'USAGE,SELECT,UPDATE')) THEN
        RAISE EXCEPTION 'CAND-L6 : % garde un privilege sur %', v_role, v.oid::regclass;
      END IF;
    END LOOP;
  END LOOP;
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('referentiel_paiement_afrique', 'referentiel_paiement_afrique_decisions',
                        'referentiel_paiement_operateurs',
                        'referentiel_paiement', 'referentiel_paiement_journal',
                        'candidature_paiement_decisions')
  ) THEN
    RAISE EXCEPTION 'CAND-L6 : une policy ouvre une table du referentiel';
  END IF;

  -- L'etat initial : 249 pays, 60 d'Afrique en verification, 189 confirme,
  -- Arabie saoudite comprise, une ligne de journal par ligne.
  IF (SELECT pg_catalog.count(*) FROM public.referentiel_paiement_afrique) <> 60
     OR (SELECT pg_catalog.count(*) FROM public.referentiel_paiement) <> 249
     OR (SELECT pg_catalog.count(DISTINCT pays) FROM public.referentiel_paiement) <> 249
     OR EXISTS (SELECT 1 FROM public.referentiel_paiement_afrique a
                WHERE NOT EXISTS (SELECT 1 FROM public.referentiel_paiement l WHERE l.pays = a.pays))
     OR (SELECT pg_catalog.count(*) FROM public.referentiel_paiement l
         WHERE l.etat = 'confirme'
           AND NOT EXISTS (SELECT 1 FROM public.referentiel_paiement_afrique a WHERE a.pays = l.pays)) <> 189
     OR (SELECT pg_catalog.count(*) FROM public.referentiel_paiement l
         JOIN public.referentiel_paiement_afrique a ON a.pays = l.pays
         WHERE l.etat = 'en_verification') <> 60
     OR NOT EXISTS (SELECT 1 FROM public.referentiel_paiement l
                    WHERE l.pays = 'SA' AND l.methode = 'virement_bancaire' AND l.etat = 'confirme')
     OR (SELECT pg_catalog.count(*) FROM public.referentiel_paiement_journal) <> 249 THEN
    RAISE EXCEPTION 'CAND-L6 : etat initial du referentiel inattendu';
  END IF;

  -- CAND-Q05 ouvert : une decision fermee, recopiee dans app_config (R12).
  IF (SELECT pg_catalog.count(*) FROM public.referentiel_paiement_afrique_decisions) <> 1
     OR private.paiement_afrique_ouverte()
     OR (SELECT c.value FROM public.app_config c WHERE c.key = 'paiement.afrique_ouverte')
        IS DISTINCT FROM 'false'::jsonb THEN
    RAISE EXCEPTION 'CAND-L6 : decision initiale sur l Afrique inattendue';
  END IF;

  -- Les declencheurs : effets et journal de toute ecriture, identite, Afrique,
  -- ajout seul, cle protegee.
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger t
      WHERE NOT t.tgisinternal AND t.tgenabled <> 'D'
        AND (t.tgrelid, t.tgname) IN (
          ('public.referentiel_paiement'::regclass, 'referentiel_paiement_effets'),
          ('public.referentiel_paiement'::regclass, 'referentiel_paiement_identite'),
          ('public.referentiel_paiement'::regclass, 'referentiel_paiement_garde_afrique'),
          ('public.referentiel_paiement_journal'::regclass, 'referentiel_paiement_journal_ajout_seul'),
          ('public.candidature_paiement_decisions'::regclass, 'candidature_paiement_decisions_ajout_seul'),
          ('public.candidature_paiement_decisions'::regclass, 'candidature_paiement_decisions_valide'),
          ('public.referentiel_paiement_afrique_decisions'::regclass,
           'referentiel_paiement_afrique_decisions_ajout_seul'),
          ('public.referentiel_paiement_afrique_decisions'::regclass,
           'referentiel_paiement_afrique_decisions_valide'),
          ('public.referentiel_paiement_afrique_decisions'::regclass,
           'referentiel_paiement_afrique_decisions_appliquer'),
          ('public.app_config'::regclass, 'app_config_paiement_afrique_ouverte'))) <> 10 THEN
    RAISE EXCEPTION 'CAND-L6 : declencheur du referentiel manquant ou desactive';
  END IF;
END;
$postflight$;

COMMIT;
