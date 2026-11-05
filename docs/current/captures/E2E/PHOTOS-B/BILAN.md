# PHOTOS-B (05/11/2026) : bilan du lot

Fiche PHOTOS-PARTOUT du garde-cap, part famille et gestion. Demande du directeur (04/11) : « leur photo, même si maintenant on peut l'ajouter, elle ne s'affiche pas partout, elle ne synchronise pas. »

## Bilan en quatre états

- **Fait** :
  - le Foyer : carte d'un membre, fiche, Couleur, Finances, Mouvements (filtre et reçu), éditeur de photo, Recharge (bénéficiaires, récapitulatif, résultat) ;
  - Suivi, Accueil famille, Mes finances, profil de paiement, « Vous », Mon espace guidé (`personneId` facultatif), Comptes au téléphone ;
  - `compte_page.dart` passait déjà par `personneId` : rien à y changer.
- **Non fait** : rien de la fiche, hors les deux constats ci-dessous, laissés à I1 (pilote, 05/11).
- **Bloqué** : rien.
- **Non prouvé** :
  - **Comptes au téléphone, dans le navigateur.** Une session ouverte à 390 ne demande aucune photo (`photos_personnes` jamais appelé), même après avoir élargi la fenêtre à 1440. Une session ouverte à 1440 en demande, et la photo s'affiche, sur main comme ici. La cause tient donc à la largeur au démarrage de la session, et je ne l'ai pas trouvée. Le code de la ligne au téléphone est prouvé par `test/features/photos/photos_b_test.dart` : rouge sur main, vert ici.
  - Le robot reste donc rouge à 390, sur ce seul point. Tout le reste y est vert.
  - Correction d'un relevé précédent : « aucune photo au bureau » était faux. Mon écoute (`response`) manquait les requêtes, et le robot visait une autre ligne.
  - « Vous » (Communauté) n'est couvert ni par le robot ni par un test ; le profil de paiement l'est par test de widget seulement (adaptateur de démonstration seul).
  - Rien n'est prouvé par le directeur en production.

## Constats hors lot (pour I1, décision du pilote)

- **Au téléphone, l'envoi de la photo d'un enfant échoue** (« La photo n'a pas pu être envoyée »), par intermittence. L'échec suit le même motif que Comptes : une session ouverte à la largeur d'un téléphone.
  - Le message vient de `_Phase.echecEnvoi`, donc d'une exception de `ServiceAvatarSupabase.televerser`, soit `uploadBinary` dans `lib/core/appairage/service_avatar.dart:158`.
  - Mon relevé « aucune requête ne part » reposait sur la même écoute fautive : il est à refaire avec les événements `request` et `requestfinished`.
- **Le même motif de démarrage pour Comptes**, décrit plus haut.

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

- **Robot `tool/e2e/photos_b.mjs`** : avant (main 5cbe8bec, FOYER-ÉLÈVE compris) et après (cette branche), à 390 et 1440, en FR et AR. Après : vert à 1440 ; rouge à 390, sur Comptes seul.
  - Le tuteur pose la photo de Hakim par l'écran, sans recharger l'application, puis ouvre l'Accueil et le Suivi.
  - Le capteur compte, dans une capture brute (`brut/`, couleurs pleines), les pixels du portrait factice vert.

  | Passage | Accueil | Suivi | Foyer | Fiche | Comptes (direction) |
  |---|---|---|---|---|---|
  | avant 1440 FR / AR | 3822 / 3825 | **0 / 0** | 1913 / 1913 | 1913 / 1913 | 782 / 782 |
  | avant 390 FR / AR | 1999 / 1998 | **0 / 0** | 1913 / 1913 | 1913 / 1913 | 0 / 0 |
  | après 1440 FR / AR | 3822 / 3825 | **1912 / 1913** | 1913 / 1913 | 1913 / 1913 | 782 / 782 |
  | après 390 FR / AR | 1999 / 1998 | **1005 / 1005** | 1913 / 1913 | 1913 / 1913 | **0 / 0** (non prouvé) |

  Au Foyer, main montrait déjà la photo après l'envoi : l'éditeur relit la clé copiée. Le lot y unifie la source, sans défaut visible avant.

- **Test de widget `test/features/photos/photos_b_test.dart`** : Comptes à 390 et 1440, profil de paiement (enseignant et contractuel), Mon espace guidé. Contre-épreuve : avec `comptes_page.dart` de main, le test du téléphone échoue.
- **Vérifications** :
  - `dart analyze --fatal-infos` : aucun problème ;
  - `verifier_jetons` : aucune violation ;
  - `verifier_branchement` : rien de nouveau ;
  - tests des écrans touchés et des photos : 828 verts ;
  - `test/accessibilite` et `test/tool` : 778 verts.
