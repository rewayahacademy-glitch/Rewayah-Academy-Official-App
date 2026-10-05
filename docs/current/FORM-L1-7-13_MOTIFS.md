# FORM-L1, L7, L13 : motifs proposés, phrases-types, valeurs proposées

Étape FORM-L1-7-13 (board5), branche `corrections/form-l1-7-13`. Recensement d'origine :
`origin/pilotage/tuteur-v1:05_recette/FORM-AUTO-1/RECENSEMENT.md` §7-§8.

**Décidé par délégation le 05/10** (décision « motifs » du 05/10, règle DIR-REP-1) : les listes
ci-dessous sont rédigées par l'agent à partir du vocabulaire déjà présent dans l'application et
dans `docs/current` (01, 06, 07). Aucune règle métier n'est créée : une puce n'est qu'un raccourci
de saisie. Statut : `présent dans le code`, `testé localement` ; ni staging ni déploiement.

## Mécanique commune

- Composant partagé `SelecteurMotif` (`lib/core/widgets/selecteur_motif.dart`) : une rangée de
  puces qui passe à la ligne, toutes les puces d'une même ligne à la même hauteur (jamais moins
  que la cible tactile), contenu centré (K-54), « Autre » toujours en dernier, qui ouvre la saisie
  libre. Sans motif proposé, le champ libre s'affiche seul.
- **Le motif reste une chaîne** : la puce choisie part telle quelle vers la même RPC qu'avant
  (aucun contrat serveur modifié). « Autre » sans texte = motif vide.
- **Aucun bouton grisé** (K-56) : presser sans motif affiche « Il manque le motif : choisissez-en
  un dans la liste, ou touchez « Autre » et écrivez-le. » ; si « Autre » est retenu et vide, le
  champ dit « Vous avez choisi « Autre » : écrivez le motif en quelques mots. ».
- Listes : `lib/core/formulaires/motifs_proposes.dart` ; libellés `motifs.*` et `formulaire.*`
  dans `assets/i18n/fr.i18n.json`, déclarés dans `tool/libelles_sources.json`.
- Réserve reprise du recensement (L1) : le journal d'audit reçoit la phrase dans la langue de
  l'écran (français ; ces écrans ne sont pas traduits en arabe).

## L1 : les treize champs « motif »

Aucun de ces écrans n'appartient aux voies Communications, Finance, Comptable ou Tableau :
**aucun champ relayé**.

### 1. Ajouter un élève à une classe (A2)
Écran : Opérations > Classes, feuille « Ajouter un élève » — `lib/features/admin_groupes/groupes_page.dart:716`.

| Motif | Source |
|---|---|
| Placement après diagnostic | 01 « Diagnostic pédagogique à l'entrée… placer au groupe » ; `admin.diagnostics.intro` (« placement ») |
| Sortie de la liste d'attente | 01 / 06 « liste d'attente » |
| Transfert depuis une autre classe | 06 « transfert documentés » ; 07 « transfert humain » |
| Demande de la famille | 01 « choix familial » ; vocabulaire des demandes (`admin.demandes`) |

### 2. Retirer un élève d'une classe (A4)
Feuille « Retirer » — `groupes_page.dart:344` (liste), rendu `groupes_page.dart:900`.

| Motif | Source |
|---|---|
| Demande de la famille | idem 1 |
| Transfert vers une autre classe | 06, 07 « transfert » |
| Écart de niveau durable | 07 « transfert humain si écart durable » |
| Fin de l'inscription | 01 / 06 « inscription » |

### 3. Clore une classe (A4)
Feuille « Clôturer » — `groupes_page.dart:404`, rendu `groupes_page.dart:900`.

| Motif | Source |
|---|---|
| Fin du cycle de la classe | 07 « cycles » ; `admin.progression.filtreTousCycles` |
| Faible remplissage | 07 « faible remplissage commercial » |
| Élèves transférés dans d'autres classes | 06, 07 « transfert » |
| Enseignant absent sans remplacement | 07 « absence enseignant sans remplacement » ; 06 « remplacement » |
| Classe créée par erreur | raisonnement : correction d'une saisie administrative |

### 4. Attribution hors heure posée (A5)
Écran : Attribution, « Pourquoi passer outre ? » — `lib/features/admin_attribution/attribution_page.dart:758`.

| Motif | Source |
|---|---|
| Heure confirmée avec la famille | `admin.attribution.motifRequis` (« n'a pas posé cette heure ») |
| Aucune heure commune | `admin.attribution.sansHeureCommune` |
| Continuité avec le même enseignant | 01 « L'élève suit durablement le même enseignant » |
| Demande de la famille | idem 1 |

### 5. Refus d'une demande (A6)
Écran : Demandes et règles, « Refuser » — `lib/features/admin_demandes/demandes_page.dart:236`. La phrase part à la partie.

| Motif | Source |
|---|---|
| Aucun enseignant disponible sur cet horaire | 01 « collisions d'enseignant » ; `admin.attribution` (disponibilités) |
| Un changement d'enseignant reste exceptionnel | 01 « Un changement de professeur est un événement exceptionnel » |
| La règle de la plateforme s'applique | `admin.demandes.sansSurcharge` / `clore` (« règle de la plateforme ») |
| Plafond d'élèves déjà atteint | `admin.demandes.reglePlafond`, `admin.attribution.complet` |
| Informations insuffisantes pour trancher | `tuteur.reglages.demandeMotifRequis` (« permet de trancher ») |

### 6. Poser une règle individuelle (A6), et la clore
Feuille `FeuilleRegle` — `demandes_page.dart:675` (poser : `poserRegle`, clore : `cloreSurcharge`).

Poser :

| Motif | Source |
|---|---|
| Demande de la famille accordée | `admin.demandes.accorder` |
| Besoin pédagogique de l'élève | 07 « progression individuelle » |
| Durée adaptée à l'âge | 07 « enfants … 60 minutes, adultes … 90 minutes » |
| Charge de l'enseignant | 07 « charge enseignants » |
| Correction d'une erreur de saisie | raisonnement : correction administrative |

Clore (revenir à la règle de la plateforme) :

| Motif | Source |
|---|---|
| Besoin ponctuel terminé | raisonnement : une surcharge est une exception datée (`admin.demandes.historiqueLigne`) |
| Demande de la famille | idem 1 |
| Changement de classe ou d'enseignant | 01 « changement de professeur » ; 06 « transfert » |
| Règle posée par erreur | raisonnement : correction administrative |

### 7. Annuler une évaluation (A8)
Écran : Pédagogie > Évaluations — `lib/features/admin_pedagogie_evaluations/evaluations_page.dart:312`, rendu `:666`.

| Motif | Source |
|---|---|
| Absence de l'élève | 06 « absence » |
| Absence de l'enseignant | 06 « absence, remplacement » |
| Élève pas encore prêt | 07 « prérequis stables », « Gate » |
| Report à une autre date | 01 « Annulations, reports » |
| Évaluation planifiée par erreur | raisonnement : correction administrative |

### 8. Changer le niveau, promotion (A9)
Écran : Pédagogie > Progression, « Changer de niveau » — `lib/features/admin_pedagogie_progression/progression_page.dart:429`.

| Motif | Source |
|---|---|
| Évaluation réussie | `admin.evaluations.resultatReussi` |
| Unité acquise et stable | 07 « `Acquis`, `Stable` » |
| Décision de l'enseignant | 07 « L'enseignant décide » |
| Réévaluation demandée par la famille | 07 « la famille peut demander réévaluation » |
| Correction du niveau de placement | `admin.diagnostics.champNiveau` (« Niveau de placement ») |

### 9. Exception : blocage, dérogation, clôture (A9)
`progression_page.dart:283` (blocage / dérogation), `:310` (clore), rendu `:547`.

Blocage :

| Motif | Source |
|---|---|
| Prérequis pas encore stables | 07 « prérequis stables » |
| Renforcement nécessaire avant d'avancer | 07 « renforcement ciblé » |
| Évaluation à revoir | `admin.evaluations.resultatARevoir` |
| Absences répétées | 06 « absence » |

Dérogation :

| Motif | Source |
|---|---|
| Aucun groupe approprié | 01 « exception documentée si aucun groupe approprié » |
| Progression plus rapide que le groupe | 07 « progression individuelle bornée » |
| Décision de l'enseignant | 07 « motive brièvement une exception » |
| Accord de la direction pédagogique | 07 « approbation académique » |

Clore l'exception :

| Motif | Source |
|---|---|
| Prérequis désormais stables | 07 |
| Élève placé dans un groupe adapté | 01 « placer au groupe existant » |
| Exception plus nécessaire | raisonnement |
| Exception posée par erreur | raisonnement : correction administrative |

### 10. Décider un placement (A11)
Écran : Pédagogie > Diagnostics — `lib/features/admin_pedagogie_diagnostics/diagnostics_page.dart:282`.

| Motif | Source |
|---|---|
| Débutant : parcours de base | 01 « Débutant : parcours de base » |
| Niveau constaté à la lecture | 07 « lecture/récitation réelle » |
| Pré-diagnostic déclaratif confirmé | 06 « Pré-diagnostic déclaratif » |
| Groupe le plus proche du niveau évalué | 01 « placer au groupe existant le plus proche du niveau évalué » |
| Placement provisoire, à réévaluer | 07 « réévaluation » |

### 11. Refuser un dossier (A12)
Écran : Personnes > Dossiers à valider, surface de refus — `lib/features/admin_dossiers/surfaces_decision.dart:261`. La phrase est montrée à la personne.

| Motif | Source |
|---|---|
| Pièce d'identité illisible | `dossiers.pointLisible` |
| Pièce d'identité expirée | `dossiers.pointValidite` |
| Nom différent de celui du compte | `dossiers.pointNom` |
| Pièce requise non transmise | `dossiers.revue.pieceNonTransmise` |
| Accord requis manquant | `dossiers.revue.etats.accordManquant` |

### 12. Correction de présence (E2)
Écran : cahier de transmission, « Corriger la présence » / « Excuser l'absence » — `lib/features/presence_correction/presence_correction_page.dart:304`, listes passées par `lib/features/cahier/cahier_page.dart:1383`.

Corriger la présence :

| Motif | Source |
|---|---|
| Présence non détectée par l'application | 06 « Présence … incident réseau identifié » |
| Coupure réseau pendant le cours | 06 « incident réseau » |
| Arrivée en retard | 06 « retard » |
| Connexion depuis un autre appareil | 06 « gestion des appareils » |
| Erreur de saisie | raisonnement : correction auditée (06) |

Excuser l'absence :

| Motif | Source |
|---|---|
| Absence prévenue à l'avance | 06 « absence » ; L7 « prévenir l'académie » |
| Coupure réseau signalée | 06 « incident réseau » |
| Jour férié ou congé | 01 « jours fériés » ; 06 « congés » |
| Raison familiale | raisonnement ; aucun motif de santé proposé (donnée sensible) |

### 13. Réglages enfant, demande du tuteur (T3)
Écran : Réglages par enfant, « Demander un changement » — `lib/features/reglages_enfant/reglages_enfant_page.dart:418` (liste choisie `:448`).

Changer d'enseignant :

| Motif | Source |
|---|---|
| Horaire qui ne convient plus | 01 « horaires » |
| Niveau qui ne correspond plus | 01 « niveau » |
| Changement de fuseau horaire | 01 « fuseau » |
| Réunir les enfants du foyer | 06 « Tuteur et plusieurs enfants » |

Changer la durée des cours :

| Motif | Source |
|---|---|
| Durée trop longue pour l'âge | 07 durées enfants / adultes |
| Besoin de plus de temps | raisonnement |
| Pause nécessaire pendant le cours | 07 « 60 minutes dont pause » |
| Contraintes d'horaire de la famille | 01 « horaires » |

Changer la durée minimale payable :

| Motif | Source |
|---|---|
| Séances souvent écourtées | `admin.regles.dureeMinimalePayeeDetail` (« séance écourtée ») |
| Coupures réseau fréquentes | 06 « réseau faible », « incident réseau » |
| Durée des cours modifiée | `tuteur.reglages.demandeDuree` |
| Contraintes d'horaire de la famille | 01 « horaires » |

## L7 : phrases-types des signalements enseignant

Même composant, mêmes listes pour les deux écrans, par catégorie ; facultatif (rien retenu
d'office). Une phrase-type de l'ancienne catégorie s'efface quand la catégorie change ; un texte
écrit à la main reste. Catégorie « Autre » : pas de phrase-type, champ libre seul.

- Fiche de l'élève, « Résumé partageable » — `lib/features/fiche_groupe/fiche_eleve_enseignant.dart:601`.
- Signalement de séance, « Message pour la famille » — `lib/features/tc_flux_academique/feuille_signalement.dart:173`
  (la note interne y devient obligatoire sans bouton grisé : l'erreur s'affiche sous le champ).

| Catégorie | Phrase-type | Source |
|---|---|---|
| Pédagogique | Un renforcement est conseillé sur la leçon en cours. | 07 « renforcement ciblé » |
| Pédagogique | Un peu de révision à la maison aidera avant le prochain cours. | 07 « `Avant le prochain cours` », « Révision » |
| Pédagogique | La régularité du travail à la maison fera la différence. | 07 « Tuteur soutient la régularité » |
| Pédagogique | Un échange avec l'académie est proposé. | 01 « Aucun contact privé des familles » : l'académie transmet |
| Présence | Plusieurs absences récentes : la régularité aide à progresser. | 06 « absence » ; 07 « régularité » |
| Présence | Arrivées en retard lors des dernières séances. | 06 « retard » |
| Présence | Merci de prévenir l'académie en cas d'absence. | 06 « absence » |
| Technique | Le son ou la connexion a gêné le cours. | 01 « qualité audio prioritaire » ; 06 « réseau faible » |
| Technique | Un essai de l'appareil avant le cours est conseillé. | 06 « gestion des appareils » ; pré-vol de salle |
| Technique | La caméra ou le micro n'a pas fonctionné. | 01 « Micro/caméra » |
| Changement | Un changement de classe est à l'étude. | 07 « transfert humain » |
| Changement | Le niveau de la classe ne semble plus adapté. | 07 « écart durable » |
| Changement | L'académie reviendra vers vous pour en parler. | 01 « information de la famille » |

## L13 : valeurs proposées des treize réglages entiers

Feuille commune `ConfigLigneEntiere` (`lib/core/admin/config_edition.dart:198`, table
`reglagesEntiersProposes`). Choix dans les puces, valeur courante retenue d'office ; « Autre »
ouvre une saisie bornée (« Entre min et max ») et disparaît quand les puces couvrent déjà tout
l'intervalle. Hors bornes : « Choisissez une valeur entre … et …, ou l'une des valeurs
proposées. ». **Le serveur n'impose aucune borne** : elles ne protègent que la saisie. Une valeur
courante hors bornes s'affiche sans puce retenue et ne peut pas être réenregistrée telle quelle :
la changer au-delà demande une décision datée.

| Réglage (écran) | Clé | Proposées | Bornes | Source / raisonnement |
|---|---|---|---|---|
| Seuil d'absence (Règles) | `absence_threshold_minutes` | 5, 10, 15 | 1 à 30 | Défaut 5 (`0001_fondations`). 10 et 15 : multiples sans source ; max 30 = moitié d'une séance par défaut de 60 min, au-delà l'élève a manqué l'essentiel. |
| Durée de séance | `session_duration_minutes` | 30, 45, 60, 90 | 30 à 90 | Défaut 60 (`0005`) ; 45, 60, 90 : 07 ; liste déjà proposée par `FeuilleRegle.proposees`. Bornes = valeurs documentées. |
| Durée minimale payée | `session_paid_minimum_minutes` | 30, 45, 60 | 15 à 90 | Défaut 45 (`0005`) ; liste de `FeuilleRegle`. Max = plus longue durée documentée ; min 15 sans source (prudent : jamais nul). |
| Pause entre deux séances | `break_minutes_between_sessions` | 15, 30, 45 | 15 à 60 | Défaut 30 (`0005`) ; liste de `FeuilleRegle`. Min 15 = plus petite valeur déjà proposée (prudent pour l'enseignant) ; max 60 = une séance. |
| Élèves par enseignant | `max_students_per_teacher` | 3, 4, 5, 6 | 1 à 6 | Défaut 5 (`0005`) ; liste de `FeuilleRegle` ; 6 = capacité adultes maximale (07). |
| Horizon d'affectation | `matching_horizon_weeks` | 2, 4, 8 | 1 à 12 | Défaut 4 (`0005`, `0033`). 2 et 8 : moitié et double, sans source ; max 12 ≈ un trimestre (prudent : génération des séances bornée). |
| Âge minimum caméra automatique | `camera_auto_allow_min_age` | 11, 15, 18 | 5 à 18 | Défaut 11 (`0001`) ; 15 et 18 : bornes des tranches d'âge `cohortes_age` (`0043`). Min 5 = plus jeune tranche. |
| Âge maximum interface enfant | `child_ui_mode_max_age` | 7, 8, 10 | 5 à 10 | Défaut 8 (`0001`, « à trancher ») ; 10 relevé le 22/09 (`0043`) ; 7 : fin de la tranche 5-7. Max 10 = dernière tranche en interface `child`. |
| Appareils par élève | `max_devices_per_student` | 1, 2 | 1 à 2 | Défaut 2, règle C11 (`0001`) « deux appareils actifs max ». Pas de « Autre ». |
| Séances simultanées par profil | `max_concurrent_sessions_per_profile` | 1, 2 | 1 à 2 | Défaut 1 (`0001`). 2 = plafond d'appareils, sans autre source. Pas de « Autre ». |
| Participants maximum (Fonctionnalités) | `max_participants_per_session` | 2, 5, 6, 7 | 2 à 7 | Défaut 2 (`0001`), porté à 7 (`0017`) ; 5 et 6 = capacités 4 et 5 de 07 plus l'enseignant. |
| Enregistrements de séance (Conservation) | `recording_retention_days` | 7, 15, 30 | 1 à 30 | Défaut 30 (`0001`, 06 « rétention 30 jours »). Seulement plus court, par prudence : l'arbitrage enregistrement (06, 07) est ouvert. |
| Documents d'identité (Conservation) | `kyc_retention_days` | 30, 60, 90 | 1 à 90 | Défaut 90 (`0004`). Seulement plus court, par prudence (données d'identité). |
