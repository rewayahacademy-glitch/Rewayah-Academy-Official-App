# Définition de la page d'ordinateur (WEB-BUREAU, 06/11/2026)

Statut : **proposée**, à valider par le garde-cap avant le premier changement de code (PLAN-LOTS
§7 rang 22 n, méthode (a)). Une fois validée, elle est la règle que teste le garde-fou permanent
(méthode (c)) sur chaque route à 1440 × 900.

Pourquoi (directeur, 06/11/2026 vers 13:55 UTC) : « la racine du problème est seule et unique (c'est
une app mobile étirée sur web) […] sans oublier les en-têtes et pieds de page qui prennent la moitié
de l'écran ».

## 1. Ce qui existe déjà et que la définition réutilise

- **La grille** : `AppGabarit` (`lib/core/theme/app_gabarit.dart`). Téléphone sous 600, tablette de
  600 à 1199, **ordinateur à partir de 1200** (`ChromeNavigation.barreLaterale`). C'est le seul
  endroit qui compare une largeur à un nombre ; la définition n'en ajoute aucun.
- **Les largeurs** : `AppPage` (`lib/core/theme/app_spacing.dart`) : contenu 1200, gestion 1440,
  lecture 800, réglages 760, formulaire 640, dialogue 560, état vide 400 ; 68 caractères par ligne.
- **Les colonnes** : `EspaceTravailAdaptatif` (`lib/core/widgets/espace_travail_adaptatif.dart`) :
  une, deux ou trois colonnes selon `ClasseLargeur` ; branché aujourd'hui sur 4 écrans seulement
  (messages, communauté, studio, modération).
- **Les coquilles** : `NavShell` (rôles), `AdminShell` (direction), `_CoquilleSecondaire` (`/compte`).
- **Le fil** : `FilAriane` (branche `claude/fil-ariane`, généralise `FilArianeFiche`).

## 2. La règle : à partir de 1200 px de large, une page d'ordinateur

| N° | Règle | Mesure (garde-fou à 1440 × 900, texte × 1) |
|---|---|---|
| **B1** | La barre latérale du rôle est là ; jamais la barre du bas. | La barre latérale de `NavShell` ou d'`AdminShell` est rendue ; la barre basse ne l'est pas. |
| **B2** | Une sortie visible, toujours. | La barre latérale (B1), ou un segment du fil (`FilAriane`), ou le disque retour. |
| **B3** | Le chemin de la page, cliquable, en tête du contenu, sur toute page de niveau 2 ou plus. | `FilAriane` rendu au-dessus du titre ; chaque segment sauf le dernier mène quelque part. |
| **B4** | Une largeur de lecture bornée. | Aucun bloc de texte de plus de 68 caractères ne dépasse 800 px de large (`AppPage.largeurLecture`) ; la colonne de contenu ne dépasse pas 1200 px (1440 pour une liste de gestion, `listeBureau`). |
| **B5** | Aucun bouton ni aucune carte étirés sur toute la largeur. | Un bouton (`ActionPrincipale`) ne dépasse pas 640 px (`largeurFormulaire`), sauf dans une carte ou une feuille déjà bornée. Une carte (`AppCard`) seule sur sa rangée ne dépasse pas 800 px ; plus large, elle partage sa rangée (colonnes) ou c'est une table (`DataCollection`). |
| **B6** | Un en-tête compact. | La tête fixe de `PageShell` (fil, titre, actions, onglets) mesure au plus 160 px de haut. |
| **B7** | Un pied compact. | La zone d'action collée en bas mesure au plus 96 px de haut ; elle n'est pas étirée sur toute la largeur (son bouton suit B5). |
| **B8** | Liste et détail côte à côte quand l'écran s'y prête. | Revue, pas mesure : les écrans « liste puis fiche » (messages, demandes, classes, foyer, bibliothèque, dossiers) passent par `EspaceTravailAdaptatif`, et ne poussent pas une page de plus pour le détail. Liste tenue dans l'inventaire. |
| **B9** | Les feuilles et dialogues sont bornés. | Une feuille ou une boîte ne dépasse pas 560 px (`largeurDialogue`), sauf un contenu tiers (formulaire de paiement), qui prend la colonne de la page, avec sortie en haut et Échap. |
| **B10** | Le téléphone ne change pas. | Sous 600 px, le rendu reste celui d'avant le lot (captures 390 avant et après). |

Règles déjà en vigueur et qui s'ajoutent sans changer : une seule barre de défilement, celle de la
page (`DECISION-DEFILEMENT-2026-11-01.md`) ; les contrats A à E de `DESIGN-GOV-2026-09-26.md`
(échelle d'espacement, CTA au bord de fin, pas de bouton pleine largeur sur bureau sans
justification).

## 3. Exceptions admises par écrit (la liste ne peut que rétrécir)

- **Les pages d'entrée, sans rôle** : questionnaire, connexion, inscription, attente, textes
  juridiques, formulaire d'avis public. Elles n'ont pas de barre latérale (B1) ; elles gardent B2
  (un retour ou un lien vers l'entrée) et B4, B5, B9.
- **La salle** (`/salle`) et **la salle d'observation** : composition propre, validée par le
  directeur le 26/10 (`PLAN-SALLE-COMPOSITION-2026-10-26.md`), plein écran, avec Quitter.
- **La porte de double vérification** (`/controleur/mfa`) : pas de barre tant que le code n'est
  pas donné ; sortie par « Se déconnecter ».

Toute autre exception est écrite dans le fichier d'exceptions du garde-fou, avec sa raison et sa
date de fin ; ce fichier ne peut que rétrécir, comme `tool/branchement_tolere.txt`.

## 4. Standards publics sur lesquels la règle s'appuie

- **Material 3, tailles de fenêtre** : compacte < 600, moyenne 600-839, étendue 840-1199, large
  1200-1599 ; à partir d'« étendue », la navigation devient un rail ou un tiroir permanent, et le
  contenu passe en volets (liste-détail, panneau de soutien). `AppGabarit` et
  `EspaceTravailAdaptatif` en sont la transcription.
- **Material 3, mises en page canoniques** : liste-détail, panneau de soutien, flux. B8.
- **Apple HIG, barres latérales et fractionnement** : barre latérale persistante sur grand écran,
  détail à côté de la liste. B1, B8.
- **WCAG 2.2, 1.4.8 Présentation visuelle** (niveau AAA, pris comme cible de lecture) : lignes de
  80 caractères au plus. B4 (68 caractères, `AppPage.largeurLectureCaracteres`).
- **WCAG 2.2, 1.4.10 Redistribution** : pas de défilement horizontal à 320 px. B10.
- **Nielsen, heuristique 3 (contrôle et liberté de l'utilisateur)** : une sortie toujours visible.
  B2, B3.
- **Loi de Fitts** : un bouton n'a pas à faire 1 100 px de large pour être facile à toucher à la
  souris ; il est proche de ce sur quoi il agit. B5.

## 5. Ce que la définition ne fait pas

Elle ne change aucun droit, aucun état serveur, aucun texte métier (`DESIGN-GOV` §4.3). Elle ne
crée aucun écran. Elle se corrige dans les composants partagés (`PageShell`, coquilles,
`EspaceTravailAdaptatif`, `ActionPrincipale`, `AppCard`), jamais écran par écran (D9).
