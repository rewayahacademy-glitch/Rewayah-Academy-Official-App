# Revue croisée EA-HORS-LIGNE-1-R : texte du bandeau hors ligne partagé

- **Objet revu** : `corrections/c2-hors-ligne` @ `a6b0ef22` (base `f6ac3658`), 2 commits, 6 fichiers (+17 −5), dont 2 captures.
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit EA-HORS-LIGNE-1 (auteur : `b061fd81`).
- **Date** : 4 octobre 2026.
- **Défaut à corriger** : `reseau.horsLigne` disait « Pas de réseau. Tout reste consultable, l'envoi attendra. ». La page d'invitation du conjoint dit « Rien n'est envoyé ». Les deux textes se contredisaient sur le même écran.
- **Méthode** :
  - lecture du diff ;
  - recherche de tous les usages de `t.reseau.horsLigne` et de `OfflineBanner` ;
  - contrôles relancés sur le worktree `/home/user/rv-hors-ligne` ;
  - une mutation ciblée, remise en place ;
  - les 2 captures ouvertes ;
  - fusion à blanc sur `corrections/revue-directeur-2026-10`.

## Verdict

**Acceptée avec réserves.** Le bandeau dit maintenant « Pas de réseau. Tout reste consultable. ». Il ne promet plus d'envoi. Il ne contredit plus l'invitation du conjoint. Les écrans qui mettent en file (cahier enseignant) disent eux-mêmes « En attente d'envoi ». Le bouton « Envoyer l'invitation » est bien grisé hors ligne. Quatre réserves mineures, aucune bloquante.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang` | OK, aucun écart avec le fichier généré versionné (`git status` propre) |
| `dart run build_runner build --delete-conflicting-outputs` | OK |
| `dart analyze --fatal-infos` | **0 problème** |
| `dart run tool/verifier_jetons.dart \| grep -c "\["` | **39**, le chiffre attendu |
| `offline_banner_test`, `test/i18n`, `inviter_conjoint_test`, et les 6 écrans qui testent `t.reseau.horsLigne` (admin_observations, classe_tuteur (2), historique, notifications, compte_tuteur) | **226 réussis, 54 sautés, 0 échec** |
| `test/features/cahier`, `cahier_test`, `demandes_admin_test` | **29 réussis, 42 sautés, 0 échec** |
| Mutation : remettre « Tout reste consultable, l'envoi attendra. » dans `fr.i18n.json`, puis `slang` | Échec de « le bandeau ne promet aucun envoi » : `Expected: not contains 'envoi'`. Fichiers remis en place, `git status` propre |
| Fusion à blanc sur `origin/corrections/revue-directeur-2026-10` | **1 conflit** : `tool/libelles_sources.json` (les deux côtés ajoutent une dernière clé, `reseau.horsLigne` ici, `eleve.accueil.erreurCours` en face). `fr.i18n.json` et `strings_fr.g.dart` fusionnent seuls |

La suite complète n'a pas été lancée (consigne : 4 cœurs, suite unique sur la fusion).

## Points de la fiche, un par un

1. **Texte du bandeau partagé vrai sur tous les écrans.** ✅
   - `assets/i18n/fr.i18n.json:133` : « Pas de réseau. Tout reste consultable. ».
   - Le bandeau est rendu par `lib/core/widgets/offline_banner.dart:91`, monté par `page_shell.dart:211`, `ecran_a_construire.dart:28` et `scanner_page.dart:478`. Un seul texte, un seul endroit.
   - Les écrans de séance utilisent `OfflineBanner.message` avec leur propre texte : non touchés.
   - L'arabe n'a pas de clé `reseau` : repli sur le français, comme avant.
2. **Écrans qui mettent en file, cahier enseignant.** ✅
   - Le bandeau ne promet plus l'envoi. La promesse reste là où elle est vraie : `cahier_page.dart:1352-1356` affiche « En attente d'envoi » et « Le cahier de transmission sera envoyé lorsque la connexion reviendra. » (`enFileTitre`, `enFileDetail`).
   - La feuille d'exception dit aussi « Le cahier de transmission, lui, part quand même » (`fr.i18n.json:3219`).
   - Voir la réserve m2 : avant le dépôt, rien ne le dit plus.
3. **Test.** ✅ `test/core/widgets/offline_banner_test.dart:96-101` refuse « envoi », « attendra », « partira » et exige « consultable ». La mutation le fait échouer : le test est discriminant.
4. **Captures `docs/current/captures/EA-HORS-LIGNE-1`.** ✅ avec réserve.
   - `ea6_inviter_conjoint_390_light_hors_ligne.png` : bandeau ambre doux en tête, « Pas de réseau. Tout reste consultable. ». Sous la carte, « Vous êtes hors ligne. Rien n'est envoyé. Vous pourrez envoyer l'invitation vous-même… ». Plus de contradiction.
   - `ea6_inviter_conjoint_390_dark_hors_ligne.png` : même rendu en sombre, contraste lisible, bandeau brun doré.
   - Les deux viennent du test existant `test/features/adulte_recette/captures_ea6_test.dart:221-240` (cas `hors_ligne`). Elles sont donc reproductibles.
   - Il n'y a que 2 captures : aucune à 320 px ×2, aucune du cahier enseignant hors ligne (réserve m3).
5. **Bouton « Envoyer l'invitation » grisé hors ligne.** ✅
   - `lib/features/foyer/invitation_conjoint.dart:566-574` : `onPress` vaut `null` quand `horsLigne`. Le gestionnaire se protège aussi (`:333`).
   - Test `inviter_conjoint_test.dart:609-641` : « hors ligne : « Envoyer » attend, dit pourquoi » vérifie `onPress` nul et la note. Vert.
   - Captures : le bouton s'affiche en état inactif (encre grise, filet gris), dans les deux thèmes.

## Règles du projet

- Aucun texte en dur : la clé reste dans `fr.i18n.json`, sa source est tracée dans `tool/libelles_sources.json` (« a faire valider par le directeur »). ✅
- Aucune couleur ni valeur ajoutée : le diff ne touche aucun widget. ✅ (39 relevés, inchangé)
- Composant partagé : seul son texte change. Les 6 écrans qui le testent passent. ✅
- 320 px et texte ×2 : le texte est plus court qu'avant, le risque baisse. Non mesuré par capture (m3).
- 5 états, RTL, bouton plein unique, capacité plutôt que rôle : non concernés par ce diff.

## Défauts retenus

Aucun majeur.

- **m1 (mineur, antérieur, hors diff)** : `lib/features/admin_demandes/demandes_page.dart:132` réutilise le texte du bandeau comme détail d'erreur. L'écran affiche alors « L'opération n'a pas abouti : Pas de réseau. Tout reste consultable. ». C'est faux à deux titres : la liste n'a justement pas pu être lue, et l'erreur n'est pas forcément réseau. Le défaut existait déjà avec l'ancien texte. Correction proposée : une clé d'erreur propre à cet écran (par exemple « Les demandes n'ont pas pu être lues. »).
- **m2 (mineur)** : le cahier enseignant, hors ligne et avant le dépôt, ne dit plus que le cahier partira plus tard. Le bandeau le disait. La clé `enseignant.cahier.enFileDetailHorsLigne` existe (`fr.i18n.json:3186`) mais aucun écran ne l'affiche. Proposition : l'afficher sous le bouton de dépôt quand `horsLigne`.
- **m3 (mineur)** : le dossier de captures n'a que 390 px clair et sombre de l'invitation. Il manque une capture à 320 px ×2 et une du cahier enseignant hors ligne, l'écran cité par la fiche.
- **m4 (cosmétique, fusion)** : conflit trivial en fin de `tool/libelles_sources.json`. Résolution : garder les deux clés, ajouter la virgule.

## Pour accepter

Rien n'est exigé avant la fusion. Au moment de fusionner, résoudre m4 en gardant les deux clés. Ouvrir une petite étape pour m1 et m2 (textes d'écran), et compléter les captures (m3) lors de la prochaine passe hors ligne.

## Contre-vérification

Sceptique indépendant, session `01KyPAZg`, non auteur. Même worktree `/home/user/rv-hors-ligne` @ `a6b0ef22`.

**Majeurs de la première revue** : aucun. Il n'y a rien à réfuter.

**Mineurs vérifiés** :
- m1 confirmé. `demandes_page.dart:132` passe bien `t.reseau.horsLigne` dans l'état d'erreur. Le défaut est antérieur au diff. Il reste mineur.
- m2 confirmé. `cahier_page.dart` ne lit `horsLigne` qu'à la ligne 1315, pour la feuille d'exception. Avant le dépôt, l'écran ne dit plus rien du départ différé. `enFileDetailHorsLigne` n'est lu par aucun fichier de `lib/`. Il reste mineur : le dépôt reste possible, et après le dépôt l'écran affiche « En attente d'envoi ».
- m3 confirmé. La capture claire à 390 px est ouverte : bandeau « Pas de réseau. Tout reste consultable. », note « Rien n'est envoyé » sous la carte, bouton « Envoyer l'invitation » inactif. Il n'y a ni capture à 320 px ×2 ni capture du cahier.
- m4 : je reprends le constat de la fusion à blanc de la première revue. Je ne l'ai pas relancée.

**Recherche d'un majeur oublié** :
- Bouton dans un bouton, couleur, rôle, 5 états : le diff ne touche aucun widget. Il change une chaîne, le fichier généré, un test et la trace de la source. Non concernés.
- Mot coupé à 320 px ×2 : le texte passe de 57 à 38 caractères. Le risque baisse. Rien n'a été mesuré par capture (m3).
- Texte en dur : aucun dans `lib/`. La clé est tracée dans `tool/libelles_sources.json`.
- Test discriminant : la première revue l'a prouvé par mutation. Je relance `offline_banner_test` et `repere_demonstration_test` : **8 réussis, 0 échec**.
- Composant partagé : seul le texte change. Les tests des écrans qui affichent le bandeau passent (première revue).
- **Nouveau, cosmétique (m5)** : il reste deux copies de l'ancien texte. `test/features/demo/repere_demonstration_test.dart:16-18` passe encore « Tout reste consultable, l envoi attendra » à `OfflineBanner.message`. Le commentaire de `lib/core/widgets/offline_banner.dart:19-22` dit encore qu'« un rapport se met en file d'attente », ce que le bandeau ne dit plus. Le test reste vert, puisqu'il mesure seulement la place prise par le texte. À aligner lors de la prochaine passe.

**Verdict final** : **acceptée avec réserves**. Le verdict en tête ne change pas. Il n'y a aucun majeur. Les réserves sont m1 à m4, plus m5. `git status` est propre.

## Fusion d'essai des douze branches CORR-2 (relu par 01KyPAZg)

Branche locale `integ-c2-essai`, jamais poussée, sur `corrections/revue-directeur-2026-10` @ f6ac3658. Ordre : elv-err, bento3b, ea-prod, tuile-tuteur, obs-coupe, coupe2, ens-route, ens-listes, ma-prod, tut-cta, adm-echus, hors-ligne.

- Conflits : chaînes i18n et `libelles_sources.json` (triviaux, régénérés par `dart run slang`) ; routeur `/eleve` entre DASH-EA-PROD et DASH-MA-PROD, composable : la redirection adulte d'EA-PROD (`redirectionAccueilEleve(capaciteAccueilAdulte: …)`) est gardée, le constructeur devient `AccueilEleveSelonPresentation` de MA-PROD, suivi de `...routesAccueilAdulte()`.
- Mesures sur la fusion (df122065) : `dart analyze --fatal-infos` 0 problème ; jetons 39 ; suite dossier par dossier 5573 réussis, 0 échec (27 dossiers ; captures ignorées 657).
