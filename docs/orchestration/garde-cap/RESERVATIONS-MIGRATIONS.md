# Réservations de numéros de migration (garde-cap, tenue à jour)

| Numéro | Lot | État (03/11 10:36 UTC) |
|---|---|---|
| 20261105100000 | FN-115c | sur main, en prod |
| 20261105150000 | PR 95 (B4), renumérotation | en attente |
| 20261105200000 | C1 | sur main |
| 20261105300000 | I1 | sur main, en prod |
| 20261105400000 | N1 | PR 147 |
| 20261105500000 | O1 | sur main, en prod (PR 152) ; observation ouverte le 03/11 à 11:12 (20261106900000) |
| 20261105600000 | (libéré le 03/11 : V1 renuméroté en 20261107700000 et 700001, ordre de la production) | libre |
| 20261105700000 | A3-bis | sur main, en prod (PR 156) |
| 20261105800000 | (libéré le 03/11 : N3-D3 renuméroté en 20261107800000, ordre de la production) | libre |
| 20261105900000 | PAY-UX | sur main, en prod (PR 153) |
| 20261106000000 | (libéré le 03/11, NIV1 renumérotée) | libre |
| 20261106100000 | REMB-14 (v2.1.0, 14 jours) | sur main, en prod (PR 157) |
| 20261106200000 | D1-bis | sur main, en prod (PR 164, 32034c79) |
| 20261106300000 | (libéré le 03/11 : N4 serveur en 20261108200000) | libre |
| 20261106400000 | Double vérification à la publication de la politique commerciale (aal2) | réservé |
| 20261106500000 | Séance non tenue à T+30, report et rattrapage (directeur 03/11, points 3-4) | sur main, en prod (PR 170, 1b5343af) |
| 20261106500001 | SNT, second fichier (B5 : DROP/ADD de notifications_evenement_check) | en prod, collé par le directeur (03/11 vers 11:22) |
| 20261106600000 | (libéré le 03/11, D1-ter renumérotée en 20261107200000) | libre |
| 20261106700000 | N2 : RPC `mon_role_foyer()` (titulaire, second adulte, aucun), additive | sur main, en prod (PR 165, 31471d47) |
| 20261106800000 | NIV1 (renumérotée par le pilote, après N2) | sur main, en prod (PR 172, e6d794b2) |
| 20261106900000 | O1 : ouvrir l'observation des parents (un UPDATE de app_config, après « secrets posés » à 11:09) | sur main, en prod (PR 169, 13ffefa5) |
| 20261107000000 | NIV1 reprise : profils existants dont le niveau est déjà connu (UPDATE et INSERT seulement, valeur d'avant gardée) | sur main, en prod (PR 175, eec033ed) : 2 profils repris, 4 intacts |
| 20261106600001 | (libéré le 03/11, renuméroté en 20261107200001) | libre |
| 20261107100000 | D1-bis correctif : `concern_famille_v` en lecture seule (REVOKE ALL, GRANT SELECT) + contrôle général des vues modifiables | en prod (version distante 20261103125410, vérifié en lecture : authenticated SELECT seul) ; PR 173 à fusionner après 172 ; filtre des mineurs déplacé dans D1-ter (écart accepté) |
| 20261107200000 | D1-ter : la famille lit ce qui lui est transmis (CREATE OR REPLACE VIEW seulement, filtre du correctif 1071) | sur main, en prod (version distante 20261103152253, PR 174, 6bf10a4e) |
| 20261107200001 | D1-ter, fichier B5 (contraintes des événements et des destinations) | en prod, collé par le directeur (vérifié par le pilote sur les contraintes, 14:29) |
| 20261107300000 | PHOTOS-1 : une photo par personne, lecture selon K-44 (camarades stricts) | sur main, en prod (version distante 20261103142523, PR 180, 82c3a789) |
| 20261107300001 | (libéré : PHOTOS-1 sans B5) | libre |
| 20261107400000 | (libéré le 03/11 : PHOTOS-2a renuméroté en 20261107900000) | libre |
| 20261107500000 (et 500001 et suivants si besoin) | FN-SERVEUR (FN-106, 107, puis 003, 019, 104), sans lib/ | sur main, en prod (version distante 20261103155624, PR 183, 54a64ff2) |
| 20261107600000 | M1-A8 : retrait du serveur du support actif (DROP), seulement si aucun autre lecteur ; fichier B5 collé par le directeur | réservé (03/11 16:10) |
| 20261107700000 | V1, fichier B5 : types seuls | collé par le directeur (03/11 vers 17:30), vérification du pilote en cours |
| 20261107700001 | (libéré : jamais installé, remplacé par V1-a 20261108000000) | libre |
| 20261107800000 | N3-D3 : compte rendu du contrôleur (renuméroté depuis 5800000) | réservé (03/11 16:47), branche claude/n3-d3-mission |
| 20261107900000 | PHOTOS-2a : fermeture du grant client de 0005 sur avatar_storage_key, avec le passage à poser_photo_eleve (renuméroté depuis 7400000) | **libre : jamais utilisé** ; PHOTOS-2a a été livré sous `20261109300000_photos_2a_fermer_ecriture_avatar.sql` (dans `main`, version `photos_2a_fermer_ecriture_avatar` en production) ; relevé du garde-cap, 08/11 vers 04:35 |
| 20261108000000 | V1-a : ADD VALUE participant_role intervieweur seul | réservé, installé par le pilote |
| 20261108000001 | V1-a : fonctions, coche fondateur, réglages entretiens.*, côté imposé (CAND-Q07) | réservé, installé par le pilote après 8000000 |
| 20261108100000 | COURRIELS-UX (UX-026, FN-108) | sur main, en prod (PR 192, 1fa9b98b) |
| 20261108200000 | N4, partie serveur (Bibliothèque, coffre R2 de la pièce, publication des évaluations, demande d'interface standard) | réservé (03/11 17:40), C1 proposé |
| 20261108300000 | Salle 3, partie serveur (« Bienvenue dans l'équipe », affectation) | réservé (03/11 17:40), N1 proposé |
| 20261108400000 | FN-DIVERS serveur : FN-102 (signer_contrat écrit signer_name depuis le compte + scénario), FN-101 (liste et plafond écrits posés sur le seau kyc) | réservé (03/11 17:42), I1 ; vérification du contenu et passage par piece-identite-depot → N4 (C1) |
| 20261108500000 | V1-b : créneaux d'entretien ouverts par la direction, réservés par le candidat | réservé (03/11 17:45) |
| 20261108600000 | SUPPRIMER, partie serveur (retrait, journal, anonymisation au délai, suppression par sélection) | réservé (03/11 17:55), premier agent libre ; DELETE dans les corps : règle du collage |

Règle (03/11 16:47) : toute migration nouvelle prend un numéro au-dessus de la dernière installée en production ; les réservations plus basses (N4 6300000, aal2 6400000, PR 95 5150000) sont renumérotées à l'usage.

Notes pour la fiche aal2 (20261106400000), relevées par I1 pendant REMB-14 (03/11) :
- `mfaRequise` ne vaut que pour le contrôleur (`lib/core/session/source_session.dart:119-120`) ;
- seule page TOTP : `/controleur/mfa` (`features/mfa_controleur`), à réutiliser pour la direction ;
- `publier_politique_commerciale` exige `app_aal() = 'aal2'` ;
- l'écran Politique commerciale affiche le refus 42501 (« Publication refusée ») : le remplacer par l'entrée en double vérification.
| 8700000 | DRAPEAUX BR-1 (teacher_country vues famille) | réservé |
| 8800000 | FUSEAUX serveur (fuseau interlocuteur) | réservé |
| 8900000 | SUPPRIMER-bis serveur (restaurer, lister les retraits), I1 | réservé |
| 9000000 | ANTI-ROBOT réglage securite.turnstile_cle_site | réservé |
| 9100000 | V1-a-bis super-admin des deux côtés (FdS) | réservé |
| 8500000 | (libéré, V1-b renuméroté) | libre |
| 9200000 | V1-b créneaux (FdS) | réservé |
| 7900000, 8700000, 8800000 | (libérés, renumérotés) | libre |
| 9300000 | PHOTOS-2a (proposé C1) | réservé |
| 9400000 | DRAPEAUX BR-1 (proposé N1) | réservé |
| 9500000 | FUSEAUX serveur | réservé |
| 9600000 | V2-e fondateurs_personnel() lecture (FdS) | réservé |
| 7600000 | (libéré) | libre |
| 9700000 | M1-A8 B5 (C1, collage directeur) | réservé |
| 9800000 | V2-a écrans entretien, serveur (FdS) | réservé |
| 9800000 | (libéré : V2-a sans migration) | libre |
| 9800000 | V1-c chevauchement des entretiens (B5, FdS) | réservé |
| 9900000 | FUSEAUX-bis : private.fuseau_info + clé decalage_apres (I1), CREATE OR REPLACE, préflight md5 prod 87106c2bcf428f5fb2deaf92d993c935 | réservé |
| 9900000 | FUSEAUX-bis (+ mon_horloge) | prod (20261104120735), vérifié 12:09 |
| 10000000 (20261110000000) | PHOTO-CAPACITE public.peut_poser_photo() (N1) | réservé |
| 10000000 (20261110000000) | (libéré : PHOTO-CAPACITE réutilise photo_adulte_moi() de PHOTOS-1) | libre |
| 10000000 (20261110000000) | GARDE-PROFIL : guard_profile_privileged_columns étendue (préflight md5 prod 3b32b937a6d3e4525cc02850e93ad7be) | réservé |
| 10000000 (20261110000000) | GARDE-PROFIL | prod 14:45, vérifié 14:50 (md5 ac83ecc4…) |
| 10100000 à 10199999 (20261110100000-20261110199999) | CAHIER-C1 (22 e), position de la dernière page présentée ; réservé par le garde-cap successeur le 06/11 | réservé |
| 10200000 à 10299999 (20261110200000-20261110299999) | REVENUS-VERITE suite (22 j), retrait de base, plafond et siegesEligibles de `mes_revenus_enseignant` ; préflight md5 prod obligatoire (fonction déjà retouchée) | réservé |
| 10300000 à 10399999 (20261110300000-20261110399999) | CANDIDATS-FLUX (22 k), réglage `courriels.non_essentiels_par_jour` et étalement de la file ; `courriels_reserver` et `courriel_enfiler` déjà en production : préflight md5 prod obligatoire | réservé |
| 10100000 (20261110100000) | CAHIER-C1 | prod 06/11 (version distante 20261106115118), vérifié par le garde-cap à 11:55 UTC : 4 fonctions SECURITY DEFINER, search_path vide, propriétaire postgres, EXECUTE à authenticated seul (aucun à anon ni PUBLIC), md5 24f287e3 / 0f5bdca5 / 861ab7e1 / 4f28cd1f ; table RLS active, 0 politique, droits postgres et service_role seuls |
| 10300000 (20261110300000) | CANDIDATS-FLUX PR A | prod 06/11, vérifié par le garde-cap vers 13:55 UTC : md5 courriels_reserver 35376dda, prevenir_par_courriel 6e153695, apercu_prevenir_par_courriel 34b4269a, etat_file_courriels c8372b30 (identiques au pilote) ; DEFINER, search_path vide, propriétaire postgres, aucun droit anon ni PUBLIC (courriels_reserver : service_role seul) ; langues poular, francais, english, man, ar, pt ; questionnaire courant salle-examen-2 ; courriels.non_essentiels_par_jour 300 ; recrutement non essentielle ; inscription_publique_ouverte false (attend la PR B) |
| 10400000 (20261110400000) | TURNSTILE-CLE : UPDATE de securite.turnstile_cle_site (clé publique du widget), une ligne, aucun effacement ; installé seulement après la phrase de confidentialité en production (arbitrage du garde-cap, 06/11) | réservé |
| 10500000 à 10599999 (20261110500000-20261110599999) | COULEUR-PROFIL (22 i) : une clé d'accent par profil (jamais une couleur libre, K-62) ; réservé par le garde-cap le 06/11 à 21:40 UTC | réservé |
| 10600000 à 10699999 (20261110600000-20261110699999) | CAHIER-C2 à C8 (22 f) ; réservé le 06/11 à 21:50 UTC | réservé |
| 10700000 à 10799999 (20261110700000-20261110799999) | FINANCE-ENSEIGNANT (22 h) ; réservé le 06/11 à 21:50 UTC | réservé |
| 10800000 à 10899999 (20261110800000-20261110899999) | FN-DIVERS (rang 21) ; réservé le 06/11 à 21:50 UTC | réservé |
| 10310000 (20261110310000) | CANDIDATS-FLUX PR B : candidatures.confidentialite_version de "2026-10-v1" vers "2026-11-v1" (bloquait toute inscription candidat : confidentialite_perimee), UPDATE idempotent ; accepté par le garde-cap le 06/11 à 21:50 UTC | réservé |
| 20261111000000 | INVITATION-COMPTE (A) : invitation_foyer_code ; relu par le garde-cap le 07/11 (SHA-256 8e19d97b, corrections exigées) | réservé |
| 20261111100000 | PROFIL-TITULAIRE (B) : profils_du_foyer_v ; préflight md5 prod 118e7897 ; relu le 07/11 (SHA-256 29e6e330) | réservé |
| 20261111200000 | PHOTO-CANDIDATURE figée (A) | réservé, **jamais livré** : code sur la branche `claude/photo-candidature-figee` (968d57c1), aucune PR ouverte, absent de `main` (ALERTE-LOTS-NON-LIVRES, PR 345) ; relevé du garde-cap, 08/11 vers 04:35 |
| 20261111300000 | LANGUES (langue du compte) : EN ATTENTE sur ordre du directeur (07/11), `docs/current/A-FAIRE-LANGUES.md` | réservé |
| 20261112000000 à 20261112000200 | PUSH-1 (E) : contraintes (page collée), file et abonnements, notifications par rôle ; ordre à revoir (garde-cap, 07/11) | réservé |
| 20261113000000 à 20261113999999 | CAHIER-C3 (B), « Cahiers à remplir » par séance ; réservé le 07/11 | réservé |
| 20261114000000 à 20261114999999 | NOUVEAUTES (A), badge « Nouveau » ; réservé le 07/11 | réservé |
| 20261115000000 à 20261115999999 | SUIVI-ELEVE, `/eleve/suivi` (lecture serveur seulement) ; réservé par le garde-cap le 07/11 vers 12:00 UTC | réservé |
| 20261116000000 | SECU-ANON : retirer à anon l'exécution de `groupes_admin`, `personnes_observables`, `profil_de_mon_foyer` (petites dettes de sécurité, accord du directeur le 07/11) ; réservé par le garde-cap vers 12:35 UTC | installé le 07/11 à 13:26 (20261107132641) |
| 20261117000000 | CODE-INVITATION-CANDIDAT (H) : `inscrire_candidat` normalise le code comme `verifier_invitation_enseignant` (`app_private.code_invitation_normalise`) ; serveur seul ; réservé par le garde-cap le 07/11 vers 13:40 UTC | réservé |
| 20261118000000 | CADRE-RELIGIEUX (schéma) : élargir `contract_texts_contract_kind_check` (+ `teacher_religious_framework`) et `contract_texts_locale_check` (+ `ar`), remplacer la policy `contract_texts_published_read` (locale fr seule) ; contient DROP CONSTRAINT/POLICY, donc **page de collage du directeur** ; réservé le 07/11 vers 15:45 UTC | réservé |
| 20261118000100 | CADRE-RELIGIEUX (publication) : `contract_texts` (`teacher_religious_framework`, `2026-11-07`, `fr` et `ar`, sha256 vérifiée par la contrainte) puis `contract_required_versions` ; texte exact de `docs/current/TEXTES-VALIDES/CADRE-RELIGIEUX-ENSEIGNANT.md` ; 0 mot d'effacement, apply_migration ; réservé le 07/11 vers 15:42 UTC | réservé |
| 20261118000200 | CADRE-LANGUES : élargir `contract_texts_locale_check` (en, es, pt : langues de l'application et du site, K-41) puis publier le cadre `2026-11-07` dans ces langues, texte de `docs/current/TEXTES-VALIDES/CADRE-RELIGIEUX-TRADUCTIONS.md` (ordre du directeur, 07/11 vers 21:40 UTC) ; DROP CONSTRAINT, donc page collée ; réservé par le garde-cap le 07/11 vers 21:45 UTC | réservé |
| 20261119000000 à 20261119099999 | SALLE-3-ACCUEIL (H) : à la fin réussie de `valider_piece_candidat`, une notification « Bienvenue dans l'équipe » ; le courriel d'activation existant (`courriel_compte_enseignant_valide`) est revu, sans second courriel ; réservé par le garde-cap le 07/11 vers 17:20 UTC | réservé |
| 20261119100000 à 20261119199999 | SALLE-1-TOUT-ICI (E) : accords et pièce autorisés en salle 1 ; réservé par le garde-cap le 07/11 vers 17:20 UTC | réservé |
| 20261119200000 à 20261119299999 | SALLE-2-ENTRETIEN (A) : notifications et courriels de l'entretien (créneau réservé, rappel la veille et 15 min avant, résultat), modèles en 5 langues ; réutilise V1-a/V1-b ; réservé par le garde-cap le 07/11 vers 17:30 UTC | réservé |
| 20261119300000 à 20261119399999 | REMPLACEMENT-TEMPS-REEL (E, après le lot 4 et PUSH-1 en production) : alerte à toute l'équipe, préférence de genre dans une fenêtre de 5 à 10 s (`DECISION-REMPLACEMENT-2026-11-07.md`) ; réservé le 07/11 vers 17:30 UTC | réservé |
| 20261119400000 à 20261119499999 | MESSAGES-CANDIDAT (H, lot 6 du plan des trois salles) : messages entre le candidat et la direction, en réutilisant la messagerie existante (inventaire d'abord) ; réservé par le garde-cap le 07/11 vers 19:15 UTC | réservé |
| 20261120000000 à 20261120099999 | INVITATIONS-PERSONNELLES (B, lot 7) : invitations à code pour les candidats enseignants importés (réutilise invitations_enseignant et le courriel invitation_enseignant), aperçu, étalement par geste ; réservé par le garde-cap le 07/11 vers 21:00 UTC | réservé |
| 20261120100000 à 20261120199999 | HARMONISATION B : plafond des invitations de candidats dans app_config, aperçu « déjà inscrits » (dettes 3 et 4) ; réservé par le garde-cap le 07/11 vers 23:05 UTC | réservé |
| 20261120200000 à 20261120299999 | HARMONISATION H : état de la photo dans etat_dossier (dette 1), purge de cron.job_run_details (dette 9), et PERF-ATTENTE (index et corrections, un fichier par cause) ; réservé par le garde-cap le 07/11 vers 23:05 UTC | réservé |
| 20261120300000 à 20261120399999 | HARMONISATION A : pré-alerte « prêt » passée à la fonction unique de rang (dette 2), fuseau invalide de l'avis d'entretien (dette 8) ; réservé par le garde-cap le 07/11 vers 23:05 UTC | réservé |
| 20261120400000 à 20261120499999 | PHOTO-FOYER (E) : un tuteur pose la photo de tout membre de son foyer sans connexion propre (mineur ou adulte créé par lui) et la sienne quand il étudie aussi ; une seule clé de photo par personne (student_profiles.avatar_storage_key), reprise sans effacement de profiles.photo_storage_key ; défaut signalé par le directeur le 07/11 ; réservé par le garde-cap le 07/11 vers 23:35 UTC | réservé |
| 20261120500000 à 20261120599999 | RLS-PRIVATE : ENABLE ROW LEVEL SECURITY sur remplacements_prets_candidats, remplacements_acceptations, entretien_avis_envoyes, rech_d1_curseurs (schéma private, sans accès client, invariant « RLS sur toutes les tables ») ; 0 mot d'effacement ; réservé par le garde-cap le 08/11 vers 02:00 UTC | réservé |
| 20261121000000 à 20261121099999 | NOTIF-RETENU (H) : événement retenu_entretien ajouté au CHECK des notifications (21000000, DROP CONSTRAINT, page collée), notification et push posés dans admettre_salle_verification à la clé du courriel existant (21000100, 0 mot d'effacement) ; réservé par le garde-cap le 08/11 vers 02:02 UTC | réservé |
| 20261121100000 à 20261121199999 | NOMS-CLASSES (B) : banque des noms de classes (`private.noms_classes`), `groupes.nom_banque_id`, nom choisi par déclencheur quand le libellé est vide ; liste des noms à valider par le directeur avant toute installation (décision du 25/10) ; préflight à recalibrer sur la production ; réservé par le garde-cap le 08/11 vers 05:25 UTC | réservé |
| 20261121200000 à 20261121299999 | REVENUS-2 (E) : un fichier `_revenus_presence.sql`, retouche par ancres de `public.mes_revenus_enseignant(date)` (branche `claude/revenus` reprise sur main ; l'ancien numéro 20261110220000 est abandonné) ; ARGENT : aucune valeur ni règle nouvelle, seules DECISION-TARIFS-2026-10-18 et `private.pai_due_seance` font foi ; préflight md5 à recalibrer en production au réveil ; réservé par le garde-cap le 08/11 vers 06:20 UTC | réservé |
| 20261110220000 | revenus_presence (branche `claude/revenus`, 4cbee9d0) | **abandonné** (repris par REVENUS-2 sous 20261121200000) ; **jamais livré** : absent de `main` et de ce registre jusqu'ici, ni PR ouverte (ALERTE-LOTS-NON-LIVRES, PR 345) ; à réserver formellement avant toute reprise ; relevé du garde-cap, 08/11 vers 04:35 | réservé (rétroactif) |
