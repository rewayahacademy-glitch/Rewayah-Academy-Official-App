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
| 20261107900000 | PHOTOS-2a : fermeture du grant client de 0005 sur avatar_storage_key, avec le passage à poser_photo_eleve (renuméroté depuis 7400000) | réservé (03/11 16:45), installé après la fusion du client |
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
| 11200000 (20261111200000) | PHOTO-CANDIDATURE-FIGEE (agent A) : candidatures.photo_cle_figee, politiques du seau photos_enseignants, photo_dossier_candidat ; préflights vérifiés en prod par le pilote (07/11 11:37) | réservé par le pilote (07/11 11:41), branche claude/photo-candidature-figee ; après le train F |
