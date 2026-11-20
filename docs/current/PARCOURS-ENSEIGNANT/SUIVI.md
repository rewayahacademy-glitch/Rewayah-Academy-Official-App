# Suivi du parcours de l'enseignant : la check-liste

Statuts permis : `pas commencé`, `en cours` (branche), `PR ouverte` (numéro), `dans main` (numéro),
`prouvé par le directeur` (date). Aucun autre mot. Une case n'est cochée que « prouvée par le
directeur en production ». Mis à jour le 19/11/2026 : **tout est `pas commencé`. Une maquette qui marche attend la confirmation du directeur
(`maquettes/maquette-vivante.html`).**

Détail de chaque lot : `PLAN.md` (le paragraphe entre parenthèses). Hors périmètre, sur ordre du
directeur du 19/11 : **l'espace de l'élève**, qui viendra après.

## À faire aujourd'hui, sans code (le directeur ou Praxis)

- [ ] Répondre aux 12 fils de courriels de candidats restés sans réponse (captcha, 2 créneaux, 2
      versements, parcours élève, « que faire », caméra, pays absent, double compte, statut).
- [ ] Rouvrir ou trancher les 13 candidatures retirées par leur candidat et toujours retirées.
- [ ] Ouvrir des créneaux d'entretien, ou annoncer une date : 166 candidats attendent.

## Vague P. Fluidité (à mener en parallèle, la mesure d'abord)

| | Lot | Contenu | Dépend de | Statut |
| :-- | :--- | :--- | :--- | :--- |
| [ ] | PE-P1 | Mesurer : premier écran, cinq écrans, images par seconde, poids, sur les trois appareils du directeur (§10.3) | l'aide du directeur | pas commencé |
| [ ] | PE-P2 | L'éclair de la ligne déformée et l'éclair de l'écran du code : chercher dans le code les sorties citées et la correction déjà faite ailleurs (§10.2, §12.1) | | pas commencé |
| [ ] | PE-P3 | Gains sans risque : chargement à la demande par rôle, polices d'icônes réduites | PE-P1 | pas commencé |
| [ ] | PE-P4 | Essai de la construction WebAssembly sur un aperçu, comparé à PE-P1 | Q9 | pas commencé |
| [x] | PE-P5 | Vraie application Android puis iPhone | **écarté par le directeur le 19/11** (commission des boutiques) | fermé |

## Vague A. Les blocages d'aujourd'hui

| | Lot | Contenu | Déjà commencé ailleurs | Statut |
| :-- | :--- | :--- | :--- | :--- |
| [ ] | PE-A1 | Courriels dans la langue de la personne : sujet et corps du lien de connexion et de la confirmation ; invitation personnelle ; « retenue pour un entretien » ; nom du formulaire et lien de désinscription (§2.1) | R10 (à faire depuis le 14/11) | pas commencé |
| [ ] | PE-A2 | Le lien qui me connaît : la marque « candidat » voyage dans le lien, l'adresse est déjà là, l'écran d'arrivée dit « votre candidature vous attend », jamais la page de connexion ordinaire ; `invitation=1` lu comme candidat (§2.2, A-standard « lien magique ») | PR #524 (marque dans l'adresse de retour) : à relire d'abord | PR ouverte (#643) ; non prouvé en production |
| [ ] | PE-A3 | La porte « Apprendre » ou « Enseigner » pour tout nouveau compte ; l'espace porte son nom ; les inscriptions des élèves fermées le disent (§2.2) | PR #523 (lien « Postulez ici ») dans main | PR ouverte (#643) ; non prouvé en production |
| [ ] | PE-A4 | Geste du bureau « Ce compte est un candidat enseignant », pour les comptes famille qui portent une candidature | Q1 | pas commencé |
| [ ] | PE-A5 | « The check did not complete » : diagnostic, message qui dit quoi faire, sortie de secours (§0) | | pas commencé |
| [ ] | PE-A6 | Le retrait se défait seul pendant 7 jours ; le lien quitte le pied de l'accueil (A8) | décidé : 7 jours, avec un écran qui explique (§13.2) | pas commencé |
| [ ] | PE-A7 | Avis automatique au candidat quand un créneau d'entretien s'ouvre | R22, « à construire » depuis le 16/11 | pas commencé |
| [ ] | PE-A8 | « Vouliez-vous dire gmail.com ? » à la saisie de l'adresse | R25 | pas commencé |
| [ ] | PE-A9 | Membre invité : plus d'écran « Pour qui créez-vous ce compte ? » avant le code ; le code d'un associé mène à l'écran de l'associé, pas à celui des enseignants (§14.4) | BE-2a-2 ASSOCIE | PR ouverte (#643), partie écran seulement ; le rôle associé côté serveur reste à faire |

## Vague B. Le parcours du candidat

| | Lot | Contenu | Déjà commencé ailleurs | Statut |
| :-- | :--- | :--- | :--- | :--- |
| [ ] | PE-B1 | Juz (tout, rien, un nombre exact) et riwayat (une, toutes, les sept, quelques-unes en grille rangée) ; anciennes réponses gardées (A10) | `claude/candidature-ux` (riwayat « toutes » en tête) ; décidé le 19/11 (§12.1) | pas commencé |
| [ ] | PE-B2 | Un seul nom par élément, une table lue par le dossier, le complément, le portail et les accords (A11, §2.6) | nom décidé : « عقد معلم » (§12.1) | pas commencé |
| [ ] | PE-B3 | Chaque saisie a sa sortie : nom latin, ville, téléphone dans le dossier (§2.7) | | pas commencé |
| [ ] | PE-B4 | Accueil du candidat à trois onglets : Dossier, Messages, Académie ; annonce en une ligne fermable puis rangée (A9) | fil d'annonces de ANNONCES-SIMPLES déjà dans main | pas commencé |
| [ ] | PE-B5 | État du dossier redessiné : ligne d'étapes, un seul « à faire maintenant », « rien à faire, on vous écrira » | maquette à valider | pas commencé |
| [ ] | PE-B6 | Partager l'académie : nouvelles cartes | références du directeur (Q8) ; `claude/partage-et-nom-arabe` | pas commencé |
| [ ] | PE-B7 | Modifier après l'envoi ce qui ne change pas la décision (A12) | BE-1e « panier de demandes », pas commencé | pas commencé |
| [ ] | PE-B8 | Aides à côté des questions (ijaza), tous les pays dans l'indicatif téléphonique | | pas commencé |
| [ ] | PE-B9 | Réponses toutes prêtes dans le portail : combien gagne un enseignant (exemple chiffré), versement par pays, compte d'un proche | `DECISION-TARIFS`, `DECISION-QUESTIONS-VERSEMENT` | pas commencé |
| [ ] | PE-B10 | Réparer le dépôt de pièce qui échoue, puis ranger en un geste une image du chat comme pièce ; avertissement dans la saisie (A13) | `IMAGES-MESSAGERIE.md` | pas commencé |

## Vague C. Le bureau de la direction

| | Lot | Contenu | Déjà commencé ailleurs | Statut |
| :-- | :--- | :--- | :--- | :--- |
| [ ] | PE-C1 | Un seul dossier : les onze entrées du §3.1 mènent à l'écran A ; « Fichiers à valider » devient une file ; la même carte d'aperçu partout (A1, A2) | BE-0c, BE-1c dans main | PR ouverte (#639), **partiel** : messagerie et liste des enseignants ouvrent A ; Comptes, Espace de traitement et notifications mènent encore à B (bloqué : le serveur ne donne pas la candidature depuis un profil) |
| [ ] | PE-C2 | Synthèse en tête : ce qui manque, pièce vérifiée ou non, dernière connexion, ancienneté ; accepter exige la pièce vérifiée (A7) | vérifier `accueil_separe` en production ; Q4 | pas commencé |
| [ ] | PE-C3 | La pièce d'identité toujours affichée de la même façon (§3.2) | PIECE-DANS-DOSSIER (#532) | pas commencé |
| [ ] | PE-C4 | Liste : tri de l'ancien au récent ; filtres « dossier complet » et « dernière connexion » ; « sélectionner les N résultats » ; gestes groupés utiles (admettre, accueillir, demander un complément, écrire, épingler) avec aperçu avant d'exécuter | lots serveur `executer_lot_candidats` ; vague 3 du bureau | pas commencé |
| [ ] | PE-C5 | Épingler un profil : marque qui le suit partout, vue « Épinglés », gestes groupés (inviter, écrire au groupe) (manuscrit, partie 3) | rien | pas commencé |
| [ ] | PE-C6 | Tableau de bord refait : À faire, Ce qui a changé, Santé ; chaque chiffre ouvre sa liste filtrée (A5) | `DASH_STRATEGIE.md` à relire ; références du directeur | pas commencé |
| [ ] | PE-C7 | En-tête : icônes fixes, panneaux légers (messages avec réponse rapide, notifications, annonces), recherche qui trouve les personnes (A6) | | PR ouverte (#639), partiel : l’icône des messages reste à zéro ; panneaux légers et recherche non faits |
| [ ] | PE-C8 | Trois pages : Accueil, Personnes, Messages ; le reste dans « Plus » ; types de personnes en vues d'une seule liste ; famille qui se déplie (A3, A4) | LP-1 à LP-7 (`SPEC-LISTE-PERSONNES`) | pas commencé |
| [ ] | PE-C9 | Lenteur du bureau : pages pour les comptes et la file des pièces, conversations lues une fois, selon PE-P1 (§3.7) | `STRATEGIE-BASE-ECONOME` | pas commencé |
| [ ] | PE-C10 | « Demander un complément » s'ouvre avec tous les éléments manquants déjà cochés ; on décoche ce qu'on veut (§12.1) | R15 (liste des éléments) | pas commencé |

## Vague D. Les outils de l'échange et les pages secondaires

| | Lot | Contenu | Déjà commencé ailleurs | Statut |
| :-- | :--- | :--- | :--- | :--- |
| [ ] | PE-D1 | Messagerie : rapprochement par clé d'envoi (plus de copie en échec qui reste), réessai automatique, chargement par pages (§4.1) | `MESSAGERIE-CHECKLIST.md` | pas commencé |
| [ ] | PE-D2 | Supprimer un message, pour moi et pour tous (A14) | Q5 | pas commencé |
| [ ] | PE-D3 | **Le composant des feuilles** : 90 % de hauteur au plus, poignée toujours atteignable, filtres en pleine largeur, « Effacer » visible ; puis revue des feuilles les plus employées (§4.3) | R17 (`FormeModale.panneau`) | pas commencé |
| [ ] | PE-D4 | Retour et glissement : un détail s'empile, le retour revient d'où l'on vient, y compris dans le bureau (§3.6, §4.3) | `DECISION-MOUVEMENT` | PR ouverte (#639), bureau seulement ; précédent et suivant non faits |
| [ ] | PE-D5 | Profil dans la conversation = la carte d'aperçu de PE-C1, avec ses gestes | PE-C1 | pas commencé |
| [ ] | PE-D6 | Annonces : « Annoncer à ces N personnes » depuis la liste filtrée ou la sélection (A15) | PE-C4 | pas commencé |
| [ ] | PE-D7 | Aperçu de lien, PDF lisible dans la conversation | | pas commencé |
| [ ] | PE-D8 | **Les avis flottants** : remplacer les bandeaux qui poussent la page par un avis posé par-dessus, aux couleurs de la marque, animé, fermable ; « messages pas en direct » devient un signe discret (§12.2) | références du directeur | PR ouverte (#641) ; non prouvé en production |
| [ ] | PE-D9 | Mise à jour : « Maintenant » ou « Plus tard », puis automatique à la prochaine ouverture ; l'avis reste (§12.2) | | PR ouverte (#641) ; non prouvé en production |
| [ ] | PE-D10 | Gestes de glissement : retour par glissement, glisser une ligne pour agir, glisser pour répondre (§12.2) | PE-D4 | pas commencé |
| [ ] | PE-D11 | Texte copiable sans menu « Tout sélectionner » au moindre toucher (§12.2) | à reproduire sur le téléphone du directeur | PR ouverte (#641) ; non prouvé en production |
| [ ] | PE-D12 | **Tirer vers le bas pour actualiser**, partout, dans le composant de page commun ; et le bouton figé après la validation d'une pièce (régression) (§12.2) | | PR ouverte (#639), partiel : délai du bouton figé ; tirer pour actualiser non fait |

## Vague E. L'espace de l'enseignant

| | Lot | Contenu | Déjà commencé ailleurs | Statut |
| :-- | :--- | :--- | :--- | :--- |
| [ ] | PE-E1 | Accueil vivant : événements et annonces de la direction avec miniature, cartes des cours (§5) | références du directeur (Q8) ; `A-FAIRE-LUMIERE-ACCUEILS.md` | pas commencé |
| [ ] | PE-E2 | Cartes des Classes, liste des élèves, bibliothèque | références du directeur (Q8) | pas commencé |
| [ ] | PE-E3 | **Barre du bas, composant commun** : hauteur ramenée à celle de la capsule, zone tactile qui remplit la colonne de l'onglet, sans chevauchement | dette BARRE-UNE-SOURCE | pas commencé |

## Vague F. Les icônes

| | Lot | Contenu | Dépend de | Statut |
| :-- | :--- | :--- | :--- | :--- |
| [ ] | PE-F1 | Nouvelle famille d'icônes fixes, dans le seul fichier `app_icons.dart` | Q7 | pas commencé |
| [ ] | PE-F2 | Une quinzaine d'icônes animées (barre du bas, cloche, envoyer, succès, épingler) | Q7 (paquet Lottie, `pubspec.yaml`) ; licence à vérifier | pas commencé |
| [ ] | PE-F3 | Le langage de mouvement : ressort, rebond, élastique, liquide, reflet ; décision datée qui amende `DECISION-MOUVEMENT`, puis les composants communs (§12.3) | références du directeur ; PE-P1 | pas commencé |
| [ ] | PE-F4 | Les coins justes : courbe continue et rayon intérieur = rayon extérieur − marge, dans `AppRadius` et les composants communs (§13.2) | | pas commencé |
| [ ] | PE-F5 | Praxis, mascotte animée : dessin vectoriel, émotions, regard, entrées ; règles de présence (§13.2) | maquette à confirmer | pas commencé |
| [ ] | PE-F6 | La compétence (skill) du mouvement, pour toute l'application et hors d'elle (§13.2) | maquette confirmée | pas commencé |
| [ ] | PE-F7 | Composants vivants communs dans `lib/core/` : ressort au toucher, avis flottant, file d'avatars, jauge d'eau, bulle, capsule liquide, chiffre qui tressaute (§13) | PE-P1 ; maquette confirmée | pas commencé |

## Vague G. Praxis

| | Lot | Contenu | Déjà commencé ailleurs | Statut |
| :-- | :--- | :--- | :--- | :--- |
| [ ] | PE-G1 | Praxis lit les réponses du questionnaire et ce qui manque à un dossier | outils prévus `dossier`, `ce_qui_manque` (`SECRETAIRE-IA.md`) | pas commencé |
| [ ] | PE-G2 | Praxis range chaque dossier dans une pile, avec sa raison ; propose entretien ou dispense (A17) | `preparer` (PX-2) à étendre à la dispense | pas commencé |
| [ ] | PE-G3 | Le directeur valide par pile, en groupe | PE-C4 | pas commencé |
| [ ] | PE-G4 | Mise en service sur les données réelles | attend le directeur (`PRAXIS/CHECKLIST-PRAXIS.md`) | pas commencé |

## Journal

- 19/11/2026 : demande du directeur et manuscrit reçus. Recherche faite (code, production,
  messages, courriels). Plan et check-liste écrits. Rien de codé. Neuf questions posées (§9).
- 19/11/2026 (même jour) : le directeur ajoute la fluidité, l'éclair de la ligne déformée, la
  liste des noms d'éléments (§10, §11), et exclut l'espace de l'élève pour l'instant.
- 19/11/2026 (soir) : le directeur ferme Q2 (« عقد معلم ») et Q3 (riwayat), ajoute les avis flottants, la mise à jour au choix, les gestes de glissement, la sélection de texte, tirer pour actualiser, le complément précoché et le langage de mouvement (§12). Lots PE-C10, PE-D8 à PE-D12, PE-F3. Une page lisible lui est remise dans la conversation (noms des éléments à chercher).
- 19/11/2026 (nuit) : le directeur répond sur la page des références (10 commentaires) et donne la vision « objet vivant » (§13). Maquette qui marche remise (Bureau, Candidat, Atelier). Boutiques écartées ; 7 jours confirmés ; lots PE-F4 à PE-F7 ; consigne 25. Deux recherches de causes lancées dans le code (sélection de texte et bouton figé ; éclair coloré et écran du code).
- 19/11/2026 (nuit) : causes trouvées dans le code et écrites au plan §14 : sélection de texte (prouvée), bouton figé (hypothèse forte), éclair coloré (halo et éléments HTML, très probable), écran avant le code d'un invité (prouvée, avec un second défaut : le code d'un associé part vers l'écran des enseignants). Lot PE-A9.
- 20/11/2026 : le directeur demande si Flutter sait faire ces mouvements. Preuve compilée en vrai Flutter 3.47.9 et remise (plan §15) ; fluidité sur ses appareils non prouvée. 28 retours sur la maquette inscrits (plan §15.2) : tableau de bord à refaire, aucun émoji, lavande sur fond sombre, Praxis précisé. Flutter devient installable dans une session.
- 20/11/2026 : tableau de bord écrit en vrai Flutter et remis au directeur (plan §16) ; non confirmé. Règles ajoutées : pas de bulles comme structure, style familier perfectionné, aucune couleur hors palette. Réponse sur l'installation hors boutiques (Android, Windows) inscrite au §16.3.
- 20/11/2026 : le directeur valide la maquette du tableau de bord (« on valide cette maquette pour aller vite ») et ordonne de lancer les chantiers. Écrits : `CONTRAT-NAVIGATION.md` et `PLAN-DE-LANCEMENT.md`. Quatre agents lancés : RACINE (`claude/pe-racine` : PE-D8, PE-D9, PE-D11), ENTRÉE (`claude/pe-entree` : PE-A2, PE-A3, PE-A9 écran), BUREAU-NAV (`claude/pe-bureau-nav` : PE-C1, PE-D4, PE-C7, PE-D12), VIVANT (`claude/pe-vivant` : PE-F7, PE-F4, PE-C6). Statut de ces lots : en cours.
- 20/11/2026 : ordre du directeur de mettre Praxis au travail (plan §17). Lu en production : Praxis allumé et autonome, mais en mode essai (2 conversations, données réelles fermées, 5 messages par heure). Fait : consigne de la routine horaire complétée, point du jour créé, chantier serveur PRAXIS-TRAVAIL lancé (`claude/praxis-travail`). Reste au directeur : trois interrupteurs à l'écran. Consigne 26 écrite.
- 20/11/2026 (02:30 UTC) : rapport de BUREAU-NAV (PR #639), testé en local seulement. Bloqué côté serveur : ajouter la référence de candidature à la lecture des comptes et à `read_kyc_documents`, et envoyer `/admin/personnes/candidatures/<référence>` comme destination des notifications (à mettre dans la série de migrations). Praxis : premier passage réel terminé à 02:16 UTC, 19 conversations sur 35, 19 messages, 0 refus, 7 questions à la direction, 3 propositions ; 16 conversations encore en attente.
- 20/11/2026 (03:05 UTC) : rapports de RACINE (PR #641) et d'ENTRÉE (PR #643). RACINE : sélection de texte limitée au cadre et au contrat, plus rien ne pousse la page, Échap ferme l'avis ; ouverts : sélection partielle dans un message (décision du directeur), avis d'observation sans croix, Échap ferme tous les avis. ENTRÉE : écran parasite retiré, deux portes, nom de l'espace sur l'écran du code, textes arabes corrigés ; ouverts : le nom arabe de l'académie n'est pas une décision écrite ; préremplissage de l'adresse, rôle associé et marque dans le lien attendent le serveur. Praxis : PX-3 (PR #640) déclaré installable par son relecteur, fusion en attente de la décision du directeur ; PX-4 (PR #644) en relecture ; texte de confidentialité validé par le directeur, publication en cours.
- 20/11/2026 (03:55 UTC) : fusionnées dans `main` par le pilote : #640 (PX-3, installé 03:11), #639 (BUREAU-NAV), #641 (RACINE), #644 (PX-4, installé 03:39), #643 (ENTRÉE, `f5191907`). Restent ouvertes : #642 (VIVANT, tests rouges et conflit, agent relancé), #645 (confidentialité, à fusionner avec sa migration de version), PX-5 en écriture. **Échéance : la clé de la routine de Praxis expire le 24/11/2026 à 11:53 UTC** ; le directeur doit en émettre une nouvelle (double authentification) et la ranger dans les secrets réseau de l'environnement `praxis-routine`, sinon Praxis s'arrête. Dettes transmises par l'autre session de pilotage : scénarios Praxis absents de `ci.yml` ; purge des pièces d'identité échues jamais exécutée (contient un DELETE : accord du directeur) ; copie de la politique de confidentialité sur le site public à aligner.
- 20/11/2026 (04:25 UTC) : **texte de confidentialité de l'assistant publié.** PR #645 fusionnée (`9ca1929f`), application déployée à 04:24, migration `20261130400000_confidentialite_version_v2.sql` installée à 04:24:27 (version enregistrée `20261120042427` ; texte identique au fichier, 2 524 octets, même md5) ; `candidatures.confidentialite_version` vaut `2026-11-v2` en production, 110 réglages comme avant. PR #609 fermée (doublon). Reste au directeur : désactiver l'entraînement sur le compte Claude de Praxis ; annoncer la modification aux personnes déjà inscrites (aucun avis automatique). **Dette** : le workflow « Deploy Supabase » échoue par intermittence sur l'étape `supabase/setup-cli@v1` (2 fois sur 6 cette nuit) ; fichier `.github/` fermé aux agents ; vérifier le déploiement après chaque fusion qui touche une fonction Edge.
- 20/11/2026 (05:35 UTC) : **PX-5 (PR #646) fusionné (`7de2a4f0`) et installé à 05:29 UTC** (version enregistrée `20261120052916`, nom `praxis_px5` ; texte identique au fichier, 65 452 octets ; 13 fonctions aux empreintes attendues ; réglages : 100 ouvertures par fenêtre de 5 heures). `praxis-mcp` redéployée, 24 outils, vérifié par appel : `boite` rend l'objet `dossier`, `questions_ouvertes` répond, `etat` rend 75 ouvertures restantes. **Rattrapage commencé** : au passage de 05:24 UTC, Praxis a écrit à 25 candidats admis (annonce dans les mots du directeur, puis entretien écrit ; 25 textes distincts, questions adaptées au dossier ; 21 conversations ouvertes pour la première fois ; 19 en arabe, 4 en anglais, 1 en français, 1 candidate saluée au féminin) et noté 10 impressions. Passage supplémentaire déclenché à 05:31 UTC pour continuer jusqu'au nouveau plafond et reprendre lui-même ses questions à réponse connue. Ouvertes : PR #647 (travail de Praxis visible, CI en cours), #648 (avis flottant refait par le pilote, CI en cours), #642 (tableau de bord : non fusionné, repris par le modèle le plus capable pour rejoindre la maquette validée).
