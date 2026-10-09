<!-- verdict : REFUSEE -->
# SUPERPOS-1 : refusée

**Verdict : REFUSEE.** Ce qui a été livré est solide et prouvé. Mais un point exprès de la demande n'est pas fait : « en-tête compact selon l'échelle HIER-1 ». Le rédacteur le renvoie à HIER-1, alors que ce lot est déjà clos. Et l'audit oublie un panneau flottant posé sur un contenu à lire : les commandes du lecteur du Coran en Mode Accessibilité.

## Cadre de la relecture

- J'ai relu dans le worktree jetable `rv-SUPERPOS-1-23`, détaché sur `origin/corrections/c2-superpos` (commit 2b42d97d). Mon point de comparaison est la base 6e2c91c4.
- Les mutations ont été faites dans une copie séparée. Les deux répertoires ont été retirés à la fin.
- Je n'ai rien poussé.

## Contrôles rejoués

| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` (après slang et build_runner) | No issues found |
| `tool/verifier_jetons.dart` | 37, le chiffre annoncé (base 39) |
| `tool/verifier_revue.dart` | 1548, sous la base de 1550 annoncée : aucune régression |
| `flutter test --concurrency=2` sur test/core/widgets, cartes_collees, test/features/demo, controleur, cahier, admin_dossiers et test/widgets | 920 réussis. Le seul échec vient d'un chemin inexistant que j'avais moi-même passé : il n'est pas imputable au lot. |
| `flutter test --concurrency=2` sur test/features, test/teaching_core, test/accessibilite, test/router et test/theme | All tests passed : 4982 réussis, 2324 sautés |

## Mutations : la correction annulée, les tests doivent échouer

| Mutation | Test qui échoue |
|---|---|
| M1 : `repere_demonstration.dart` remis à la base | repere_demonstration_test, en échec de chargement : faible, d'où M1b et M1c |
| M1b : la bande ne se ferme plus clavier ouvert | « clavier ouvert : la bande se ferme… » |
| M1c : bande peinte par-dessus, dans un Stack | « la bande porte la zone sûre du haut et pousse l'application dessous » |
| M2 : `fil_discussion.dart` remis à la base | zone_saisie_test et echanges_controleur_test (plus de 10 échecs) |
| M3 : `choice_card_group.dart` remis à la base | choix_cote_a_cote_superpos_test (320 ×2 RTL) |
| M4 : `groupes_page.dart` remis à la base | zone_saisie_unique_test |
| M5 : bouton d'envoi rendu même champ vide | zone_saisie_test (plus de 8 échecs) |
| M6 : bouton d'envoi décentré de 40 px | zone_saisie_test (plus de 8 échecs) |
| M6b : hauteur du champ figée à une ligne | zone_saisie_test |
| M7 : les cartes Genre ne s'empilent jamais | choix_cote_a_cote_superpos_test |
| M8 : le contexte compact des Échanges ne se déclenche jamais | « fil 320 x2 : contexte compact » |
| M9 : `cahier_page.dart` remis à la base | cahier_en7c_test (« l'aide n'est jamais coupée ») |

Les dix mutations à effet visible sont toutes détectées. Les tests ajoutés sont de vraies contre-épreuves.

## Captures ouvertes

J'ai ouvert neuf captures avant et après :

- fil à 320 ×2 clair, avec et sans clavier ;
- fil à 320 ×2 sombre RTL ;
- fil à 390 clavier ouvert et à 1440 ;
- étape Genre à 320 ×2 sombre RTL ;
- repère à 320 ×2 ;
- cahier, avant et après.

Ce que les captures confirment :

- **Repère « Démonstration »** : c'est maintenant une bande dans le flux. Le ruban d'angle ne couvre plus le bouton du compte.
- **Zone d'envoi** : le bouton est intégré au champ et centré. Il n'apparaît que lorsqu'il y a du texte, sinon une phrase explique pourquoi il manque (vu à 1440). La flèche se retourne en RTL.
- **Étape Genre** : le radio a sa propre ligne et les cartes s'empilent ; « Un homme » s'affiche en entier.
- **Cahier** : l'aide de la reprise est entière et le texte passe à la ligne.

Ce qu'elles font apparaître de défaillant :

- **Fil à 320 ×2, premier écran** : le titre « Classe Al- / Badr · Jeudi 24 septembre » prend 4 lignes. Le contexte qui suit redit la classe et la date. Le premier écran ne montre qu'une ligne coupée d'une bulle, et la zone de saisie est sous la pliure.
- **Repère à 320 ×2** : l'en-tête « Dossiers à valider » et son sous-titre prennent la moitié de l'écran.

## Défauts

### 1. Majeur : en-tête compact non fait

C'est un point exprès de la demande. `entete_page.dart` n'a pas de mode compact, et la fiche renvoie ce point à HIER-1. Seul le contexte des Échanges a été compacté, et le titre de cet écran reste en taille de titre d'écran sur 4 lignes. Résultat : l'écran même de la zone de saisie n'est ni lisible ni utilisable sans défiler, en texte agrandi.

### 2. Moyen : audit non exhaustif

Il manque `CommandesMasquables`, la rangée de commandes du lecteur du Coran en Mode Accessibilité (`lib/core/accessibilite/commandes_masquables.dart:154`, `lib/features/accueil_eleve/coran_accessibilite.dart:500`).

- Les commandes sont posées par-dessus le bas du Mushaf, dans un `Stack`.
- Avec lecteur d'écran ou clavier, elles sont toujours visibles, et c'est le mode par défaut au clavier sur le web de bureau.
- Elles recouvrent donc en permanence le texte coranique.

C'est en conflit avec la décision MA-CMD-1 du 02/10. Il fallait au minimum l'inscrire au tableau d'audit et arbitrer par délégation. Une correction éventuelle passerait par réserver la place en bas sans toucher au rendu.

### 3. Mineur : « un seul point d'attention »

La fiche ne donne aucun verdict sur ce point.

### 4. Mineur : relais sans défaut constaté

Finance, Comptable et Salle sont notés « non audités » ou « non mesurés ». La demande voulait un défaut constaté pour chacun. Exemples relevables sans rien toucher :

- étiquette flottante dans `origin/ui/comptable-v1:…/nouvelle_obligation_page.dart:477` ;
- éléments en Stack dans `salle_page.dart:1475-1481`, `scene_classe.dart:148-152` et `panneau_eleves.dart:290-298`.

Le relais COM, lui, est exact. Je l'ai vérifié sur `origin/ui/com-msg` : bouton `ActionPrincipale` à côté du champ, `onPress: vide ? null`, étiquette flottante.

### 5. Mineur : minimum de la liste trop bas

`FilDiscussion.minimumListe` vaut 96 px, alors qu'une bulle à 320 ×2 en fait environ 200. La promesse « au moins une bulle lisible » n'est donc pas tenue.

### 6. Mineur : vérifications manquantes

- Aucune capture en Interface guidée, alors que les réglages de l'enfant sont passés sur ZoneSaisie.
- Les aides bornées à 2 ou 3 lignes ne sont pas mesurées à 320 ×2 (`foyer/formulaire_profil_eleve.dart`, `foyer/invitation_conjoint.dart`, `eleve_connexion/saisie_code_page.dart`).
- « Al- / Badr » se coupe dans le titre à 320 ×2 (défaut préexistant).

## Ce qui est acquis et à garder tel quel

- **ZoneSaisie** :
  - style du thème ;
  - étiquette au-dessus du champ ;
  - hauteur qui grandit, plafonnée aux 2/5 de la vue visible ;
  - envoi intégré et centré, jamais grisé ;
  - touche d'action du clavier paramétrable ;
  - garde de source qui interdit tout champ multiligne hors de ZoneSaisie.
- **Repère dans le flux**, qui se ferme clavier ouvert.
- **Cartes Genre** : radio dans le flux, empilement quand un mot ne tient pas.
- **Cahier** : reprise corrigée.
- **Fil** : le débordement clavier ouvert est supprimé.
- **Qualité** : tests et contre-épreuves sérieux, aucune régression, analyze propre, jetons en baisse.

## Pour lever le refus

1. **En-tête compact sur téléphone en texte agrandi**, dans EntetePage (hors `page_shell.dart`) ou au niveau des écrans à saisie, selon l'échelle HIER-1.
   - Sur le fil, ne pas redire classe et date sous le titre.
   - Garantir qu'à l'arrivée à 320 ×2 on voie une bulle entière, ou la saisie.
   - Ajouter un test par rectangles et des captures.
2. **CommandesMasquables** : l'ajouter à l'audit, avec un arbitrage noté « décidé par délégation le 05/10 ».
3. **Fiche** : donner le verdict « un seul point d'attention » et compléter les relais Finance, Comptable et Salle avec un défaut constaté pour chacun.
4. Optionnel : porter `minimumListe` à au moins une bulle à l'échelle courante, et ajouter les captures en Interface guidée.

**Statut** : présent dans le code et testé localement par le relecteur. Ni testé sur staging, ni déployé.
