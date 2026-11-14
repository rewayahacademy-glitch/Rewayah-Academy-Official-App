# UX_REVIEW salle2-entretien (14/11/2026)

Lots SALLE2-ENTRETIEN et SALLE2-FICHE, PR #480. Ce que le directeur a fixé, et qui n'est pas une
question d'UX (relayé par le pilote le 14/11) :
- cinq étapes au plus, un clic par décision ;
- aucune re-saisie de ce que le candidat a déclaré ;
- documents consultés et décidés sans quitter l'écran ;
- décisions « Accepter / Refuser / Demander une précision », puis « Concluant / Non concluant /
  À refaire », puis « Accueillir / Ne pas accueillir » ;
- vraie interface d'ordinateur, rien de vide affiché.

Cette note justifie les choix de disposition (DESIGN-GOV §4). Elle ne change ni permission, ni règle
KYC, ni état serveur (§4.3).

| # | Règle | Source | Conclusion | Modification |
| :-: | :-- | :-- | :-- | :-- |
| 1 | Disposition par tailles de fenêtre : une colonne sous 840 dp, deux volets au-delà (*list-detail / supporting pane*) | Material 3, Canonical layouts et Window size classes (consultés 14/11/2026) | La fiche a deux rôles : lire ce que le candidat a déclaré, puis décider. Deux volets égaux à partir de 840 dp correspondent au volet « contenu + volet d'appui ». Trois colonnes laisseraient les réponses à moins de 45 caractères par ligne à 1440, en dessous de la longueur de lecture confortable | `candidature_page.dart` : à gauche, situation, photo, réponses, compétences, responsable, contact, historique ; à droite, décision, pièce et entretien, contrôles servis, messages |
| 2 | La commande se place près de l'objet qu'elle concerne ; distance et taille de la cible | Loi de Fitts ; Apple HIG, *Layout* | La décision et la pièce sont dans le même volet. La pièce se lit et se décide juste sous la décision de la candidature, sans changer d'écran. La visionneuse s'ouvre par-dessus la fiche, que l'on retrouve en la fermant | `PieceSurPlace` réutilise `RevueDossier` (visionneuse, cases « lisible / nom conforme / non expirée », Valider ou Refuser par `decider_dossier`), sans copie |
| 3 | Moins de choix cachés, temps de décision réduit | Loi de Hick ; Nielsen n° 6 « Reconnaître plutôt que se souvenir » | Les issues d'une décision étaient dans un menu « … ». Elles sont maintenant visibles côte à côte : 2 ou 3 boutons, un seul plein (K-56). Le menu ne garde que les gestes rares (pause, retrait, responsable) | `BlocProchaineAction` : Accepter (plein), Demander une précision, Refuser ; puis Accueillir dans l'équipe (plein), Ne pas accueillir |
| 4 | Un clic par décision, sans formalité inutile ; action sensible confirmée | DECISION-FLUIDITE-2026-11-07 ; Nielsen n° 5 « Prévention des erreurs » | Le résultat de l'entretien part au clic : le compte rendu court est écrit pour la personne qui a mené l'entretien. Refuser et Ne pas accueillir gardent leur feuille avec motif et modèle : c'est irréversible et la famille reçoit un message (règle métier, §4.3) | `ResultatEntretien` : Concluant, Non concluant, À refaire, sans feuille ; « Autre issue » (annulé, absence) reste en lien discret |
| 5 | Ne jamais afficher un état vide sans valeur | Nielsen n° 8 « Esthétique et design minimaliste » ; directeur, 14/11 « rien de vide affiché » | Six cartes affichaient « Disponible au branchement serveur » | Les blocs non servis (blocages et contrôles sans données, affectation, courriels, pièce sans état) ne sont plus rendus |
| 6 | Navigation par sections adaptée à la largeur | ONGLETS-1 ; Material 3, *Navigation* ; directeur, 14/11 « ces onglets ne sont pas pour le web » | `SelecteurSection` passait en menu déroulant sur tablette et ordinateur dès que le plus long libellé ne tenait pas dans une part égale, même quand chaque mot tenait | Correction faite une fois, dans le composant : à 840 dp et plus, jusqu'à sept sections restent en ligne. Le menu est réservé au téléphone et au texte très agrandi |
| 7 | Bouton pleine largeur interdit sur ordinateur sans justification | DESIGN-GOV contrat B | « Rejoindre l'entretien avec … » prenait toute la largeur à 1440 | Largeur naturelle, aligné au début |
| 8 | L'urgence se voit sans dépendre de la seule couleur | WCAG 2.2, 1.4.1 ; LUMIERE-ACCUEILS | La carte de l'entretien du candidat dit le temps restant en mots (région vivante pour le lecteur d'écran), en plus de sa lumière : orange dans l'heure, verte quand la salle est ouverte. Le bouton « Rejoindre » n'apparaît que lorsqu'il aboutit | `CarteEntretienProche` ; état fourni par le serveur (`mon_entretien.etat`) |
| 9 | Cibles de 48 au moins, contenu centré | WCAG 2.2, 2.5.8 ; K-54 | Tous les boutons passent par `ActionPrincipale`, jamais recomposés | Aucun bouton recomposé |

## Ce qui n'est pas prouvé

- Rien n'a été vu par le directeur en production.
- Les migrations `20261125820000` et `20261125900000` ne sont pas installées.
- La fiche à 1024 en paysage (iPad) n'a pas été capturée.
- La visionneuse de la pièce s'ouvre par-dessus la fiche, pas dans le volet lui-même. Un volet de
  lecture intégré reste à faire, si le directeur le demande après l'avoir vu.

## Captures

`docs/current/captures/E2E/salle2-entretien/` : fiche (décision, accueil) à 1440 et 390, carte du
candidat (proche, ouvert) à 390, entretiens du jour à 1440. Elles sont produites par
`test/capture/salle2_entretien_capture_test.dart`.
