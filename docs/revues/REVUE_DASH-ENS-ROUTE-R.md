# Revue DASH-ENS-ROUTE : acceptée avec réserves

## Verdict
**ACCEPTEE_AVEC_RESERVES.** Il n'y a aucun défaut bloquant ni majeur, seulement trois mineurs.

La fiche est remplie : « Voir tout » ouvre maintenant l'adresse `/enseignant/journee/a-terminer`, une sous-route de la Journée. Avant, il poussait une page sans adresse. `ListeATerminerPage` lit elle-même `cahiersEnRetardProvider` et gère quatre états : chargement (Skeleton), erreur (EtatSysteme avec relecture), vide (EmptyState) et contenu. L'état hors ligne est délégué au bandeau de PageShell. Si l'historique est vide, le retour renvoie à la Journée.

## Périmètre et commandes
- **Commits relus** : `c427e551..66cf818f`, soit dbe82379 (code, tests, libellés) et 66cf818f (captures).
- **Diff relu en entier hors PNG** : fr.i18n.json (+2 clés), strings*.g.dart (régénérés ; le déplacement de 4 clés entre les blocs switch n'est que du découpage slang), routes.dart, app_router.dart, journee_page.dart, parcours_enseignant_test.dart, libelles_sources.json, et le fichier de capture `.dart.txt` (convention déjà suivie par 5 lots).
- **Analyse et vérificateurs** :
  - `dart analyze --fatal-infos` : 0 problème.
  - `verifier_revue` : 1627 sur la tête comme sur la base, sorties identiques.
  - `verifier_jetons` : 39 sur la tête comme sur la base.
- **Tests** : parcours_enseignant_test 18/18 ; journee_test 73/73 (`--concurrency=2`).
- **Contre-épreuves**, toutes faites par moi puis restaurées :
  1. Retour à `Navigator.push` : le test « Voir tout » échoue (matchedLocation reste `/enseignant/journee`).
  2. Sous-route retirée du routeur : les 4 tests du lot échouent.
  3. Erreur traitée comme une liste vide (ancien comportement) : le test « lecture ratée » échoue.

## Règles
- **Jetons** : seulement AppSpacing, AppPage et Ecart, rien en dur.
- **Capacité, pas rôle** : aucune lecture de rôle.
- **D10** : une lecture ratée n'est jamais présentée comme « rien à terminer ».
- **Boutons** : aucun bouton grisé ni imbriqué.
- **Libellés** : les nouveaux sont déclarés dans libelles_sources.json.
- **Hors périmètre** : aucun branchement serveur ; le rendu du Coran n'est pas touché.

## Défauts
1. **Mineur, pas d'état hors ligne propre** (`journee_page.dart` ~953-960). Hors ligne et sans cache, la page affiche la carte « échec serveur ». Beaucoup d'écrans du dépôt affichent `NatureEtat.horsLigne` dans ce cas. Le bandeau PageShell évite toute contradiction.
2. **Mineur, couverture de test incomplète**. La nouvelle page n'a :
   - ni test `aucun_mot_coupe` à 320 px, texte à 200 % et RTL ;
   - ni capture RTL ou de chargement ;
   - ni test du bouton retour (canPop, sinon go Journée).
3. **Mineur, libellés à valider**. Les deux nouveaux libellés sont rédigés par l'agent et attendent la validation du directeur.

## Captures vues
J'ai ouvert les 6 PNG : 320x2 clair et sombre, 390 clair, 1440 clair, erreur 390, vide 390 sombre.
- Aucun mot coupé : le titre et les lignes reviennent à la ligne entre les mots.
- Ni chevauchement, ni texte trop petit, ni élément collé.
- À 1440, la colonne est bornée et alignée au début.

## Pour lever les réserves
- Afficher `NatureEtat.horsLigne` quand `horsLigneProvider` est vrai et qu'il n'y a pas de valeur.
- Ajouter un test `aucun_mot_coupe` sur ListeATerminerPage (320 px, texte à 200 %, LTR et RTL), plus un test du retour sur une adresse ouverte directement.
- Faire valider `aTerminerVide` et `aTerminerErreur` par le directeur.

## Contre-revue adverse

Verdict confirmé : non. Verdict final retenu : **REFUSEE**.

Je confirme les trois réserves mineures du premier relecteur. Ses résultats tiennent : parcours_enseignant_test donne 18/18 chez moi aussi, et les captures qu'il a ouvertes sont propres. Mais l'acceptation avec réserves seulement mineures ne tient pas, à cause d'un défaut majeur qu'il n'a pas vu.

**Le défaut.** L'état vide de la nouvelle page coupe le mot « transmission » en « tr / ansmission » à 320 px avec un texte à 200 %, en LTR comme en RTL. Deux preuves :
- un test motsCoupes en vraies polices, qui échoue sur ce seul cas ;
- une capture produite avec le harnais du lot, où la coupure se voit.

La règle du projet impose explicitement « aucun mot coupé » à 320 px et 200 %, et c'est ce lot qui crée cet état. La réserve du relecteur sur l'absence de test anti-coupure n'était donc pas théorique : elle cachait une vraie faute.

**Ce que j'ai écarté** (vérifié dans le code, rien à signaler) :
- La démonstration enseignant n'a qu'un seul cahier en retard. « Voir tout » n'y apparaît donc jamais, et le go() vers la vraie route ne peut pas faire sortir de la démo.
- Les données de la page sont les mêmes que celles de la carte Journée : même provider, même tri, sans filtre.
- Le bouton retour fonctionne dans les deux cas : la sous-route permet de revenir en arrière, et sinon il renvoie à la Journée.
- La sous-route reste dans la branche de la coquille, et la barre reste sur Journée (index de branche).

Verdict proposé : refus jusqu'à correction. Il faut réduire ou réécrire le libellé vide, ou corriger le style d'EmptyState pour qu'il passe à la ligne entre les mots. Il faut aussi ajouter un test aucun_mot_coupe sur ListeATerminerPage (320 px, 200 %, deux sens de lecture, trois états) et une capture de l'état vide à 320 px x2.

- Défaut manqué (majeur) — lib/features/journee/journee_page.dart:962-966 (branche vide de ListeATerminerPage : EmptyState avec t.enseignant.journee.aTerminerVide) ; libellé assets/i18n/fr.i18n.json « aTerminerVide » : L'état vide, nouveau dans ce lot, coupe un mot au milieu à 320 px avec un texte à 200 % : « Aucun cahier de transmission à terminer. » s'affiche « cahier de tr / ansmission ». Cela enfreint la règle « aucun mot coupé » à une taille que la règle impose (320 px, 200 %). Le défaut apparaît en LTR comme en RTL. L'ancien code n'avait pas cet état, puisque la page n'était poussée qu'au-delà de trois cahiers : c'est donc ce lot qui l'introduit. Le relecteur ne pouvait pas le voir. Le lot n'a pas de capture de l'état vide à 320 px x2 (l'état vide n'est capturé qu'à 390 px, échelle 1), et aucun test aucun_mot_coupe ne couvre la nouvelle page.
  Preuve : Je l'ai vérifié dans un worktree détaché sur 66cf818f, avec un test jetable (test/zz/cr6_test.dart). Il utilise setUpAll(chargerPolicesDuDepot), les vraies polices, comme coupe_mots1_test et journee_test. Il monte ListeATerminerPage avec les mêmes surcharges que dash_ens_route_capture_test, en TextScaler 2, dans les deux sens de lecture, à 320 et 390 px, puis appelle motsCoupes(tester, find.byType(Scaffold)). Résultat : 10 tests passent et 2 échouent. Les deux échecs sont « TextDirection.ltr vide 320.0 » et « TextDirection.rtl vide 320.0 », avec Actual: ['Aucun cahier de transmission à terminer. : transmission']. Les états contenu et erreur passent à 320 et 390 px, comme la cible tactile (androidTapTargetGuideline). J'ai aussi produit une capture avec le harnais de capture du lot lui-même, cas (Size(320, 900), light, 2, 'vide'). Le PNG a_terminer_vide_320x2_clair.png montre noir sur blanc « cahier de tr » puis « ansmission ». La capture d'erreur à 320 x2 est propre. Worktree retiré ensuite.
