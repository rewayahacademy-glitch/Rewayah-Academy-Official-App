# UX_REVIEW_COM-STU-2 : revue UX des dispositions proposées pour Le Studio, Aujourd'hui (COM-W00, COM-M04)

Écrite le 05/10/2026, après coup, sur décision prise par délégation du directeur le 05/10 (D-FUS-9 = a ; artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW). Cadre : `docs/current/DESIGN-GOV-2026-09-26.md` §4.1 à §4.3, §4 bis et §4 bis.6 (skeletons). Document seulement : chaque « Modification » est une demande pour le tour de correction.

**Code relu (lecture seule)** : `origin/ui/communications-v1` @ `27689f94` : `lib/features/com_studio/aujourdhui_page.dart`, `activite.dart`, `brouillons_studio.dart`, `elements_enregistres_studio.dart`, `port_activite_studio.dart` ; `lib/core/widgets/vue_etat_communication.dart`, `espace_travail_adaptatif.dart` (`colonnesPour`), `lib/core/theme/app_spacing.dart`.

**Aucune maquette COM-W00 ni COM-M04** dans `19_communications/V/` (QUESTIONS Q3, retirée) : la composition suit le texte de la spec (§7, §8.1, §8.2, §8.3) et la navigation de la maquette sombre. Toutes les dispositions ci-dessous sont donc des PROPOSITIONS d'agent.

**Limite §4.3.** Aucun standard ne fait exécuter une action métier depuis Le Studio (R-COM-11 : chaque ligne ouvre son module canonique) ni n'invente une donnée d'activité.

**Statut** : présent dans le code, testé localement (`test/features/com_studio/aujourdhui_*_test.dart`) ; ni staging, ni déployé.

## Sources

Mêmes codes que `UX_REVIEW_COM-STU-1.md` (AND-WSC, AND-LD lues le 05/10/2026 ; WCAG 2.2 et NN/g relevés le 26/09/2026, non relus le 05/10 : w3.org et nngroup.com bloqués par le proxy de la session ; DESIGN-GOV et `lib/CLAUDE.md` relus le 05/10/2026), plus :

| Code | Source | URL | Date et vérification |
|---|---|---|---|
| NN-SK | NN/g, « Skeleton screens 101 » : skeleton pour une page entière, rien sous 1 s | https://www.nngroup.com/articles/skeleton-screens/ | lue le 26/09/2026 (`10_classe/UX_REVIEW_CL-4.md`) ; non relue le 05/10 |
| DG-SK | DESIGN-GOV §4 bis.6 : `Skeleton` + `BlocAsynchrone`, 180 ms, géométrie du contenu attendu, 8 s puis 20 s | `docs/current/DESIGN-GOV-2026-09-26.md` | relu le 05/10/2026 |
| HICK | Loi de Hick (le temps de choix croît avec le nombre d'options) | voir `10_classe/UX_REVIEW_CL-4.md` | relevée le 26/09/2026 ; non relue le 05/10 |

## Dispositions contrôlées

| # | Disposition proposée (où) | Source | Date | Règle utile | Conclusion | Modification |
|---|---|---|---|---|---|---|
| 1 | Aujourd'hui est l'accueil du Studio (`/admin/studio`), premier de sa navigation (`aujourdhui_page.dart:5-10`) | SPEC §14 ; W-323 | 05/10 ; 26/09 | Même place d'entrée à chaque visite | Conforme | Aucune. |
| 2 | Agrégateur d'attention, pas un second centre opérationnel : chaque ligne ouvre son module canonique ; aucune action métier exécutée ici (R-COM-11) (`aujourdhui_page.dart:6-10`, `activite.dart:10-14`) | SPEC §7 (règle anti-doublon) ; NN-10 n°4 ; DESIGN-GOV §4.3 | 05/10 ; 26/09 | Une fonction, un endroit ; un standard ne déplace pas une action métier | Conforme | Aucune. |
| 3 | Indicateurs d'attention en tête (À traiter, Mentions et réponses, Décisions en attente, Non lus), en `StatTile` ; à une colonne et texte ≥ 1,5, une tuile par rangée (R-09 corrigé) (`aujourdhui_page.dart:480-527`) | W-144 ; W-1410 ; NN-10 n°1 | 26/09 (relevé) | Pas de mot coupé ni de perte de contenu à 200 % et à 320 | Conforme (après COM-RC) | Aucune. Captures `com_studio_aujourdhui_320x2_clair.png`. |
| 4 | Écart entre les indicateurs et les blocs : `Ecart.vXxl` = 24 à toutes les largeurs (`aujourdhui_page.dart:328`) | DG-A | 05/10 | Section vers section : 24 en mobile, 32 en tablette et ordinateur | Ajustée | Demande : 32 à partir de 600 (jeton de section du contrat A), 24 en dessous. |
| 5 | Sept blocs (§7) : À traiter aujourd'hui, Mentions et réponses, Décisions en attente, Échéances proches, Activité récente, Brouillons, Accès rapides ; une ligne d'activité n'est rangée que dans un bloc (`aujourdhui_page.dart:12-15`, `:341-380`) | SPEC §7 ; HICK ; NN-10 n°8 | 05/10 ; 26/09 | Pas de doublon d'une même information ; peu de choix à la fois | Conforme | Aucune. |
| 6 | Disposition : ordinateur trois colonnes fonctionnelles, tablette deux, téléphone une, dans l'ordre de la spec ; même grille que l'espace adaptatif (`colonnesPour` : compacte 1, moyenne 2, étendue et large 3) (`aujourdhui_page.dart:21-25`, `espace_travail_adaptatif.dart:68-72`) | AND-WSC ; DG-D ; W-132 | 05/10 ; 26/09 | Colonnes décidées par la largeur reçue ; l'ordre de lecture reste celui du sens | Conforme | Aucune. À une colonne, l'ordre du `Column` est l'ordre de la spec (§7). |
| 7 | Chaque bloc est un `GroupeReglages` à filets (une surface par rubrique, jamais une carte par ligne) ; blocs empilés par `PileCartes` (`activite.dart:4-5`, `:120` ; `aujourdhui_page.dart:430-431`) | K-55 ; DG-C ; NN-GP | 05/10 ; 26/09 | Contenus liés = une carte à lignes fines ; cartes indépendantes séparées de 16 au moins | Conforme | Aucune. |
| 8 | Ligne d'activité : quoi, d'où (module ou canal), qui (si le serveur l'autorise), quand, et l'attention par un badge texte et icône (`activite.dart:6-9`) | W-141 ; NN-10 n°1 | 26/09 (relevé) | Jamais la couleur seule | Conforme | Aucune. |
| 9 | Ligne sans page (Finance, Planning) : nommée sans chevron ni geste, avec « Se traite dans Finance » ; rien n'est grisé (`activite.dart:10-14`) | K-56 (`bouton-grise`) ; NN-10 n°1 | 05/10 ; 26/09 | Un bouton qui ne peut pas aboutir n'est pas grisé ni rendu actif | Conforme | Aucune. |
| 10 | Accès rapides : seulement des modules déjà livrés (Messages, Annonces, Dossiers à valider, Classes, Demandes à trancher), en `LigneRubrique` d'un `GroupeReglages` (`aujourdhui_page.dart:533-552`) | K-56 ; NN-10 n°8 | 05/10 ; 26/09 | Aucun raccourci vers une impasse | Conforme | Aucune. |
| 11 | Brouillons : bloc des plus récents puis « Voir tous les brouillons ({nombre}) » en `LienFleche`, vue « Brouillons » dans la navigation ; mémoire de session seulement, dite à l'écran (« … le temps de la session, sans synchronisation ») (`brouillons_studio.dart:1-27`) | NN-10 n°1 ; K-56 ; DG-B | 26/09 ; 05/10 | Ne pas promettre ce qui n'existe pas ; action secondaire en lien | Conforme | Aucune. Un brouillon d'un canal fermé est nommé « un canal qui n'est plus disponible », sans chevron (R-COM-08). |
| 12 | Éléments enregistrés : liste de références, chacune ouverte à sa place d'origine ; on retire un élément là où il vit (panneau du canal) ; port neutre en production, sans « Réessayer » (`elements_enregistres_studio.dart:1-15`) | NN-10 n°4 ; SPEC §8.3 | 26/09 ; 05/10 | Une seule place pour une même action | Conforme | Aucune. |
| 13 | Vide : sans activité, l'état « Rien à traiter pour le moment » prend la place des cinq blocs d'activité ; Brouillons et Accès rapides restent (`aujourdhui_page.dart:410-420`) | NN-10 n°1 ; DESIGN-GOV (« un écran n'est fini qu'avec ses états ») | 26/09 ; 05/10 | L'état vide dit quoi faire et garde les sorties utiles | Conforme | Aucune. Captures `com_studio_aujourdhui_vide_*`. |
| 14 | Chargement : `VueEtatCommunication(chargement)` = `Skeleton.liste()` générique (`aujourdhui_page.dart:384-389`, `vue_etat_communication.dart:128-132`) | DG-SK ; NN-SK | 05/10 ; 26/09 | Le skeleton reproduit la géométrie du contenu attendu (ici : rangée d'indicateurs, puis colonnes de blocs), sans fausse donnée | Ajustée | Demande : un squelette à la forme d'Aujourd'hui (rangée de tuiles, puis 1, 2 ou 3 colonnes de groupes) au lieu de la liste générique ; délais 180 ms, 8 s, 20 s inchangés (`BlocAsynchrone`). |
| 15 | Erreur et hors ligne : erreur avec « Réessayer » ; hors ligne : bandeau des Communications, contenu déjà lu gardé ; capacité indisponible sans « Réessayer » (`aujourdhui_page.dart:27-32`, `:390-408`) | K-59 ; NN-10 n°9 ; W-413 | 05/10 ; 26/09 | Dire ce qui manque, la cause, quoi faire ; ne pas proposer une action qui ne peut pas aboutir | Conforme | Aucune. Le double bandeau hors ligne sur les pages Communications est tranché par D-FUS-3 = a (05/10) : masquer le bandeau générique de `PageShell`. |

## Dérogations

Aucune. Deux ajustements demandés (points 4 et 14), à rattacher au tour court décidé le 05/10 (COM-RC tour 5) ou à la passe d'harmonisation (DESIGN-GOV §4 bis.8), au choix de l'orchestrateur.
