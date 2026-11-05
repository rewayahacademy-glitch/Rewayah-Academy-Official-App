# PHOTOS-B (05/11/2026) : bilan du lot

Fiche PHOTOS-PARTOUT du garde-cap, part famille et gestion. Demande du directeur (04/11) : « leur photo, même si maintenant on peut l'ajouter, elle ne s'affiche pas partout, elle ne synchronise pas. »

## Ce qui est faux, bloqué ou non prouvé

- **Le Foyer et `compte_page.dart` ne sont pas faits.** Ils attendent la fusion de FOYER-ÉLÈVE (ordre du pilote). C'est le cas de la carte d'un membre, de la fiche de l'enfant, de Couleur, des Finances et Mouvements du foyer, de l'éditeur de photo et de la Recharge (bénéficiaires, récapitulatif, résultat).
- **Comptes de la direction, dans le navigateur : non prouvé.** Sur la pile locale, la direction ne reçoit aucune photo dans Comptes, ni au téléphone ni au bureau. La ligne de bureau de main (PHOTOS-2a) est dans le même cas. Aucune requête `photos_personnes` ne part, alors que la règle du serveur l'autorise (`photo_visible_par` = vrai). Cause non trouvée.
  - Le code du téléphone est prouvé par `test/features/photos/photos_b_test.dart` : rouge sur main, vert ici.
  - Le robot mesure Comptes, mais Comptes n'entre pas dans son verdict.
- **Constat hors lot, sur main 1eee5c3b : au téléphone, l'envoi de la photo d'un enfant échoue** (« La photo n'a pas pu être envoyée. Rien n'a changé sur le profil. »). Aucune requête ne part. Le cas se produit quand un écran du tuteur (Accueil, Suivi) a été ouvert à la largeur d'un téléphone avant l'envoi, dans le même document. Ouverte directement, la fiche envoie la photo. L'envoi lui-même échoue aussi par intermittence sur la pile locale. Le robot pose donc la photo à la largeur du bureau, puis revient à 390 dans le même document, sans rechargement. Il saute aussi la capture « sans photo » à 390.
- **Mon espace guidé** (`mon_espace_accessibilite.dart`) n'est pas branché en production (`tool/branchement_tolere.txt`, étape 3, FN-112). Il reçoit un `personneId` facultatif, que la démonstration ne passe pas.
- **« Vous » dans une réponse en attente** et **le profil de paiement du comptable** ne sont pas parcourus par le robot. Le second n'a d'adaptateur que dans la démonstration. Le profil de paiement est prouvé par test de widget ; « Vous » ne l'est par aucun test.
- **Rien n'est prouvé par le directeur en production.**

## Ce que fait le lot

Chaque portrait lit la photo de la personne par `photoPersonneProvider(son id)`, jamais par une clé copiée. Le lot passe par le composant existant `PhotoEleve(personneId:)`, ou passe l'URL lue au composant. Il ne touche ni `avatar_nom.dart` ni `lib/core/photos/` (zone d'I1).

| Écran | Avant | Après |
|---|---|---|
| Suivi du foyer, sélecteur des enfants | aucune photo passée | la photo de l'enfant |
| Accueil famille, carte de la classe et sélecteur | `avatarUrlProvider(cleAvatar)`, clé copiée | `photoPersonneProvider(eleveId)` |
| Mes finances (élève adulte) | `cleAvatar` du serveur des finances | `PhotoEleve(personneId: profilId)` |
| Comptable, profil de paiement | initiales seulement | la photo de l'enseignant ; un contractuel garde ses initiales |
| Communauté, « Vous » d'une réponse en attente | initiales seulement | sa propre photo |
| Mon espace guidé | initiales seulement | `personneId` facultatif |
| Comptes de la direction, au téléphone | aucun cercle (texte seul) | le cercle et la photo, comme au bureau |

Aucune migration. Aucun texte nouveau.

## Preuves

- **Robot `tool/e2e/photos_b.mjs`** : avant (main 1eee5c3b) et après (cette branche), à 390 et 1440, en FR et AR. Les huit passages sont verts.
  - Le tuteur pose la photo de Hakim par l'écran, sans recharger l'application, puis ouvre l'Accueil et le Suivi.
  - Le capteur compte, dans une capture brute (`brut/`, couleurs pleines), les pixels du portrait factice vert.

  | Passage | Accueil après la photo | Suivi après la photo | Comptes (direction) |
  |---|---|---|---|
  | avant 1440 FR / AR | 3822 / 3825 | **0 / 0** | 782 / 782 (voir plus haut) |
  | avant 390 FR / AR | 1999 / 1998 | **0 / 0** | 0 / 0 |
  | après 1440 FR / AR | 3822 / 3825 | **1912 / 1913** | 1173 / 1173 |
  | après 390 FR / AR | 1999 / 1998 | **1005 / 1005** | 0 / 0 |

- **Test de widget `test/features/photos/photos_b_test.dart`** : Comptes à 390 et 1440, profil de paiement (enseignant et contractuel), Mon espace guidé. Contre-épreuve : avec `comptes_page.dart` de main, le test du téléphone échoue.
- **Vérifications** :
  - `dart analyze --fatal-infos` : aucun problème ;
  - `verifier_jetons` : aucune violation ;
  - `verifier_branchement` : rien de nouveau ;
  - tests des écrans touchés et des photos : 828 verts ;
  - `test/accessibilite` et `test/tool` : 778 verts.
