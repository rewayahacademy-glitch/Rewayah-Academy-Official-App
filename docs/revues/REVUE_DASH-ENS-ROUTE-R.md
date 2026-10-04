# Revue croisée DASH-ENS-ROUTE-R : une adresse pour la liste « À terminer »

- **Objet revu** : `corrections/c2-ens-route` @ `66cf818f` (base `c427e551`), 2 commits, 15 fichiers (+267 −26), dont 6 captures et le source du test de capture.
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit DASH-ENS-ROUTE (auteur : `b061fd81`, exclue).
- **Date** : 4 octobre 2026.
- **Références** : `DASH_STRATEGIE.md` (ligne DASH-ENS-ROUTE, §5 et D10), lu sur `origin/corrections/c2-dash1` ; `lib/CLAUDE.md`.
- **Méthode** :
  - lecture du diff ;
  - contrôles relancés dans le worktree `/home/user/rv-ens-route` ;
  - deux mutations ciblées, remises en place ;
  - trois tests temporaires (retour, barre basse), retirés ensuite ;
  - quatre captures ouvertes ;
  - fusion à blanc sur `origin/corrections/revue-directeur-2026-10`.
- `git status` est propre à la fin.

## Verdict

**Acceptée avec réserves.** Le défaut est corrigé. « Voir tout » n'ouvre plus une page sans adresse. La liste vit à `/enseignant/journee/a-terminer`, sous la Journée, dans la coquille enseignant. Elle lit elle-même ses données et a ses états. Le retour marche dans les deux cas : après « Voir tout » et sur l'adresse ouverte directement. Les tests passent par le vrai routeur et sont discriminants.

Il n'y a aucun défaut majeur. Les réserves sont mineures : le retour n'a pas de test dans la branche, il n'y a ni capture ni test du chargement et du hors ligne, et la fusion a un conflit trivial dans `tool/libelles_sources.json`.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK |
| `dart analyze --fatal-infos` | **0 problème** |
| `dart run tool/verifier_jetons.dart \| grep -c "\["` | **39**, le chiffre attendu |
| `test/router/parcours_enseignant_test.dart` | **18 réussis, 0 échec** (dont 4 nouveaux) |
| `test/features/journee_test.dart`, `test/planning/journee_test.dart`, `test/features/enseignant_recette/navigation_reelle_test.dart` | **91 réussis, 0 échec** |
| Mutation 1 : « Voir tout » revient à `Navigator.push(MaterialPageRoute(ListeATerminerPage))` | échec de « « Voir tout » ouvre l adresse » : attendu `/enseignant/journee/a-terminer`, obtenu `/enseignant/journee` |
| Mutation 2 : la branche erreur est supprimée (une lecture ratée tombe dans « vide ») | échec de « une lecture ratee le dit et propose de relire » : la phrase d'erreur est introuvable |
| Test temporaire : retour après « Voir tout » | réussi : retour à `/enseignant/journee`, la liste disparaît |
| Test temporaire : retour sur l'adresse ouverte directement | réussi : `canPop` puis `go(Routes.enseignantJournee)`, on arrive à la Journée |
| Test temporaire : la barre basse (`NavShell`) est là sur l'adresse | réussi |
| Fusion à blanc sur `revue-directeur-2026-10` | **1 conflit** : `tool/libelles_sources.json` (deux ajouts en fin d'objet). `fr.i18n.json` et `strings_fr.g.dart` fusionnent seuls |

## Points de la fiche, un par un

1. **Route sous la Journée.** ✅ `routes.dart:282-284` déclare `enseignantATerminer = '$enseignantJournee/a-terminer'`. `app_router.dart:736-743` en fait une sous-route de la Journée, donc dans la branche enseignant de la coquille. Mesuré : `matchedLocation` vaut l'adresse et `NavShell` est présent.
2. **« Voir tout » ne pousse plus de page sans adresse.** ✅ `journee_page.dart:903-904` appelle `GoRouter.of(context).go(Routes.enseignantATerminer)`. L'ancien `_ListeATerminer` privé qui recevait la liste en paramètre est remplacé par `ListeATerminerPage`, qui lit `cahiersEnRetardProvider`. Un rechargement Web ou un lien rend donc la page avec ses données. La mutation 1 le prouve.
3. **États de `ListeATerminerPage`.** ✅ `journee_page.dart:946-972` :
   - chargement : `Skeleton.liste(lignes: 3)` ;
   - erreur : `EtatSysteme` `echecServeur`, avec « Réessayer » qui invalide le provider. Une lecture ratée ne dit jamais « rien à terminer » (D10) ;
   - vide : `EmptyState` avec une phrase et l'icône cahier ;
   - contenu : les lignes triées, relues au retour d'un cahier ;
   - hors ligne : le bandeau de `PageShell`.
   Les deux nouveaux textes sont dans `fr.i18n.json` et ont leur source dans `tool/libelles_sources.json`, « à faire valider par le directeur ».
4. **Retour.** ✅ en comportement, ⚠ sans test dans la branche. `journee_page.dart:974-981` : `pop` si possible, sinon `go(Routes.enseignantJournee)`. Mes deux tests temporaires passent. Aucun test commité ne tape le disque retour.
5. **Tests sur le vrai routeur.** ✅ `parcours_enseignant_test.dart:286-394` monte `routeurProvider` réel. Le premier test tape « Voir tout » depuis la vraie coquille, à 390 px. Il vérifie l'adresse et les quatre classes. Les autres couvrent l'ouverture directe, le vide, l'erreur puis la relecture (`lectures == 2`).
6. **Captures `docs/current/captures/DASH-ENS-ROUTE` (K-61).** ✅ Six PNG plus le source du test. J'en ai ouvert quatre :
   - `a_terminer_contenu_320x2_sombre.png` : titre « À / terminer » coupé entre les mots, jamais dans un mot. Les quatre cahiers sont lisibles, triés du plus ancien (22 sept.) au plus récent (26 sept.). Chevrons à la fin. Contraste correct en sombre ;
   - `a_terminer_erreur_390_clair.png` : carte d'erreur avec icône, titre, la phrase propre à la page et un seul bouton contour « Réessayer ». Pas de bouton plein ;
   - `a_terminer_vide_390_sombre.png` : icône cahier et « Aucun cahier de transmission à terminer. », centrés ;
   - `a_terminer_contenu_1440_clair.png` : liste bornée à `largeurReglages`, alignée au début, sans étirement.
   Les captures sont prises hors coquille (pas de barre basse). C'est le choix du harnais de capture, pas un défaut de la page.

## Règles du projet

- 5 états : chargement, contenu, vide et erreur sont codés. Le hors ligne passe par le bandeau de `PageShell`. Pas de capture de chargement ni de hors ligne (mineur).
- 320 px et texte ×2 : aucun mot coupé sur la capture.
- Un seul bouton plein : aucun bouton plein sur la page, aucun bouton dans un bouton.
- Aucune couleur ni valeur inventée : jetons à 39, comme la base.
- Aucun texte en dur : deux clés i18n, avec leur source.
- Rôle : le widget ne lit aucun rôle.
- Port neutre : aucun port nouveau. La page lit le provider existant.
- RTL : les alignements sont en `AlignmentDirectional`. Pas de capture RTL de cette page (mineur).
- Composants partagés : aucun composant partagé modifié. Seuls `journee_page.dart`, `routes.dart` et `app_router.dart` changent côté code. Les tests de la Journée et de la navigation enseignant passent (91).

## Défauts retenus

Aucun défaut majeur.

Mineurs :

1. Le retour (`pop`, sinon `go` vers la Journée) n'a pas de test commité. Mes deux tests temporaires montrent qu'il marche, mais rien ne protège ce comportement d'une régression.
2. Ni le squelette de chargement ni le hors ligne n'ont de capture ou de test pour cette page.
3. Hors ligne sans cache, la carte dit « échec serveur » sous le bandeau hors ligne. Ce n'est pas faux, mais la nature `horsLigne` serait plus juste.
4. Fusion : conflit trivial dans `tool/libelles_sources.json`. Il faut garder les deux ajouts, puis relancer `dart run slang` pour régénérer `strings_fr.g.dart`.
5. K-61 n'apparaît pas dans la branche. On le trouve seulement dans `DASH_STRATEGIE.md` de la branche commune (K-61.8).

## Pour accepter

L'étape peut passer à « fait ». À la fusion :

- résoudre le conflit de `tool/libelles_sources.json` en gardant les deux blocs ;
- relancer `slang` et les tests ciblés.

Il est recommandé, sans en faire une condition, d'ajouter au groupe DASH-ENS-ROUTE deux tests de retour (après « Voir tout », et sur l'adresse ouverte directement) et une capture du chargement.

## Contre-vérification

Sceptique indépendant, session `01KyPAZg`, non auteur. Même worktree, même commit `66cf818f`.

**Relancé :**

- `dart analyze --fatal-infos` sur `lib/features/journee` et `lib/core/router` : 0 problème.
- `test/router/parcours_enseignant_test.dart` : 18 réussis.
- Mutation 3 : le retour devient `go(Routes.enseignantClasses)`, sans `pop`. J'ai lancé les quatre fichiers ciblés : parcours enseignant, deux fichiers Journée, navigation réelle. Résultat : **109 réussis, 0 échec**. La mutation survit, donc aucun test commité ne garde le retour. Fichier remis en place avec `git checkout`.
- Fusion à blanc : un seul conflit, dans `tool/libelles_sources.json`. C'est confirmé.
- Capture `a_terminer_contenu_320x2_clair.png` ouverte : « À / terminer » passe à la ligne entre deux mots. Aucun mot coupé dans les lignes ni dans les légendes. Les chevrons et les icônes restent en place.

**Majeurs de la première revue :** il n'y en a aucun, donc rien à réfuter.

**Mineurs confirmés :** les cinq. La mutation 3 apporte la preuve directe du mineur 1. Il reste mineur, car le cœur du changement est l'adresse, et cette adresse est bien gardée par les mutations 1 et 2.

**Majeur oublié cherché, aucun trouvé :**

- Bouton dans un bouton : la page n'en a pas. Les lignes sont des `LigneRubrique` dans un `GroupeReglages`, et `LienFleche` n'a pas été modifié.
- Mot coupé à 320 ×2 : aucun.
- États : chargement, erreur, vide et contenu sont codés. Le hors ligne passe par le bandeau de `PageShell`. Le hors ligne sans cache s'affiche comme un échec serveur, ce qui est déjà le mineur 3.
- Tests : ils sont discriminants pour l'adresse et l'erreur, pas pour le retour (mineur 1).
- Composants partagés : aucun n'est modifié. Le diff touche seulement `journee_page.dart`, `routes.dart` et `app_router.dart`, plus les fichiers i18n générés. Dans `strings_fr.g.dart`, deux blocs de clés changent de place, d'un `switch` au suivant. Ce découpage est produit par slang et ne change pas les valeurs.
- Texte en dur : aucun. Les deux clés sont dans `fr.i18n.json` et dans `libelles_sources.json`.
- Ouvrir un cahier depuis la liste fait un `push` sur le routeur, comme avant. Au retour, les providers sont relus : pas de régression.

**Verdict final : ACCEPTÉE AVEC RÉSERVES**, celui de la première revue, sans changement.

## Fusion d'essai des douze branches CORR-2 (relu par 01KyPAZg)

Branche locale `integ-c2-essai`, jamais poussée, sur `corrections/revue-directeur-2026-10` @ f6ac3658. Ordre : elv-err, bento3b, ea-prod, tuile-tuteur, obs-coupe, coupe2, ens-route, ens-listes, ma-prod, tut-cta, adm-echus, hors-ligne.

- Conflits : chaînes i18n et `libelles_sources.json` (triviaux, régénérés par `dart run slang`) ; routeur `/eleve` entre DASH-EA-PROD et DASH-MA-PROD, composable : la redirection adulte d'EA-PROD (`redirectionAccueilEleve(capaciteAccueilAdulte: …)`) est gardée, le constructeur devient `AccueilEleveSelonPresentation` de MA-PROD, suivi de `...routesAccueilAdulte()`.
- Mesures sur la fusion (df122065) : `dart analyze --fatal-infos` 0 problème ; jetons 39 ; suite dossier par dossier 5573 réussis, 0 échec (27 dossiers ; captures ignorées 657).
