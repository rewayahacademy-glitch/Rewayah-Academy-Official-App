# Suivi du parcours de l'enseignant : la check-liste

Statuts permis : `pas commencé`, `en cours` (branche), `PR ouverte` (numéro), `dans main` (numéro),
`prouvé par le directeur` (date). Aucun autre mot. Une case n'est cochée que « prouvée par le
directeur en production ». Mis à jour le 19/11/2026 : **tout est `pas commencé`, le plan n'est pas
encore validé.**

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
| [ ] | PE-P5 | Vraie application Android puis iPhone, du même code | décision du directeur (Q9) | pas commencé |

## Vague A. Les blocages d'aujourd'hui

| | Lot | Contenu | Déjà commencé ailleurs | Statut |
| :-- | :--- | :--- | :--- | :--- |
| [ ] | PE-A1 | Courriels dans la langue de la personne : sujet et corps du lien de connexion et de la confirmation ; invitation personnelle ; « retenue pour un entretien » ; nom du formulaire et lien de désinscription (§2.1) | R10 (à faire depuis le 14/11) | pas commencé |
| [ ] | PE-A2 | Le lien qui me connaît : la marque « candidat » voyage dans le lien, l'adresse est déjà là, l'écran d'arrivée dit « votre candidature vous attend », jamais la page de connexion ordinaire ; `invitation=1` lu comme candidat (§2.2, A-standard « lien magique ») | PR #524 (marque dans l'adresse de retour) : à relire d'abord | pas commencé |
| [ ] | PE-A3 | La porte « Apprendre » ou « Enseigner » pour tout nouveau compte ; l'espace porte son nom ; les inscriptions des élèves fermées le disent (§2.2) | PR #523 (lien « Postulez ici ») dans main | pas commencé |
| [ ] | PE-A4 | Geste du bureau « Ce compte est un candidat enseignant », pour les comptes famille qui portent une candidature | Q1 | pas commencé |
| [ ] | PE-A5 | « The check did not complete » : diagnostic, message qui dit quoi faire, sortie de secours (§0) | | pas commencé |
| [ ] | PE-A6 | Le retrait se défait seul pendant 7 jours ; le lien quitte le pied de l'accueil (A8) | Q6 | pas commencé |
| [ ] | PE-A7 | Avis automatique au candidat quand un créneau d'entretien s'ouvre | R22, « à construire » depuis le 16/11 | pas commencé |
| [ ] | PE-A8 | « Vouliez-vous dire gmail.com ? » à la saisie de l'adresse | R25 | pas commencé |

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
| [ ] | PE-C1 | Un seul dossier : les onze entrées du §3.1 mènent à l'écran A ; « Fichiers à valider » devient une file ; la même carte d'aperçu partout (A1, A2) | BE-0c, BE-1c dans main | pas commencé |
| [ ] | PE-C2 | Synthèse en tête : ce qui manque, pièce vérifiée ou non, dernière connexion, ancienneté ; accepter exige la pièce vérifiée (A7) | vérifier `accueil_separe` en production ; Q4 | pas commencé |
| [ ] | PE-C3 | La pièce d'identité toujours affichée de la même façon (§3.2) | PIECE-DANS-DOSSIER (#532) | pas commencé |
| [ ] | PE-C4 | Liste : tri de l'ancien au récent ; filtres « dossier complet » et « dernière connexion » ; « sélectionner les N résultats » ; gestes groupés utiles (admettre, accueillir, demander un complément, écrire, épingler) avec aperçu avant d'exécuter | lots serveur `executer_lot_candidats` ; vague 3 du bureau | pas commencé |
| [ ] | PE-C5 | Épingler un profil : marque qui le suit partout, vue « Épinglés », gestes groupés (inviter, écrire au groupe) (manuscrit, partie 3) | rien | pas commencé |
| [ ] | PE-C6 | Tableau de bord refait : À faire, Ce qui a changé, Santé ; chaque chiffre ouvre sa liste filtrée (A5) | `DASH_STRATEGIE.md` à relire ; références du directeur | pas commencé |
| [ ] | PE-C7 | En-tête : icônes fixes, panneaux légers (messages avec réponse rapide, notifications, annonces), recherche qui trouve les personnes (A6) | | pas commencé |
| [ ] | PE-C8 | Trois pages : Accueil, Personnes, Messages ; le reste dans « Plus » ; types de personnes en vues d'une seule liste ; famille qui se déplie (A3, A4) | LP-1 à LP-7 (`SPEC-LISTE-PERSONNES`) | pas commencé |
| [ ] | PE-C9 | Lenteur du bureau : pages pour les comptes et la file des pièces, conversations lues une fois, selon PE-P1 (§3.7) | `STRATEGIE-BASE-ECONOME` | pas commencé |
| [ ] | PE-C10 | « Demander un complément » s'ouvre avec tous les éléments manquants déjà cochés ; on décoche ce qu'on veut (§12.1) | R15 (liste des éléments) | pas commencé |

## Vague D. Les outils de l'échange et les pages secondaires

| | Lot | Contenu | Déjà commencé ailleurs | Statut |
| :-- | :--- | :--- | :--- | :--- |
| [ ] | PE-D1 | Messagerie : rapprochement par clé d'envoi (plus de copie en échec qui reste), réessai automatique, chargement par pages (§4.1) | `MESSAGERIE-CHECKLIST.md` | pas commencé |
| [ ] | PE-D2 | Supprimer un message, pour moi et pour tous (A14) | Q5 | pas commencé |
| [ ] | PE-D3 | **Le composant des feuilles** : 90 % de hauteur au plus, poignée toujours atteignable, filtres en pleine largeur, « Effacer » visible ; puis revue des feuilles les plus employées (§4.3) | R17 (`FormeModale.panneau`) | pas commencé |
| [ ] | PE-D4 | Retour et glissement : un détail s'empile, le retour revient d'où l'on vient, y compris dans le bureau (§3.6, §4.3) | `DECISION-MOUVEMENT` | pas commencé |
| [ ] | PE-D5 | Profil dans la conversation = la carte d'aperçu de PE-C1, avec ses gestes | PE-C1 | pas commencé |
| [ ] | PE-D6 | Annonces : « Annoncer à ces N personnes » depuis la liste filtrée ou la sélection (A15) | PE-C4 | pas commencé |
| [ ] | PE-D7 | Aperçu de lien, PDF lisible dans la conversation | | pas commencé |
| [ ] | PE-D8 | **Les avis flottants** : remplacer les bandeaux qui poussent la page par un avis posé par-dessus, aux couleurs de la marque, animé, fermable ; « messages pas en direct » devient un signe discret (§12.2) | références du directeur | pas commencé |
| [ ] | PE-D9 | Mise à jour : « Maintenant » ou « Plus tard », puis automatique à la prochaine ouverture ; l'avis reste (§12.2) | | pas commencé |
| [ ] | PE-D10 | Gestes de glissement : retour par glissement, glisser une ligne pour agir, glisser pour répondre (§12.2) | PE-D4 | pas commencé |
| [ ] | PE-D11 | Texte copiable sans menu « Tout sélectionner » au moindre toucher (§12.2) | à reproduire sur le téléphone du directeur | pas commencé |
| [ ] | PE-D12 | **Tirer vers le bas pour actualiser**, partout, dans le composant de page commun ; et le bouton figé après la validation d'une pièce (régression) (§12.2) | | pas commencé |

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
