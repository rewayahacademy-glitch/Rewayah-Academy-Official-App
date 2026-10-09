<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Relecture adverse PUB-1b : branche `corrections/c2-pub-b`, commit `028a7e88`

**Verdict : la fusion est acceptée, avec réserves.** Les quatre réserves de REVUE_PUB-1-R2 sont levées. Je les ai vérifiées par les preuves et je ne me suis pas fié au compte rendu du rédacteur. Il ne reste aucun défaut majeur imputable à ce lot.

J'ai en revanche trouvé un défaut **préexistant** et important, que je signale à part : sur le web réel, la touche Entrée n'active pas les boutons bâtis sur `Pressable`.

## Conditions de la relecture
- Lecture seule, dans un worktree jetable détaché sur `origin/corrections/c2-pub-b` : `scratchpad/rv-PUB-1b-80`.
- Le worktree est retiré à la fin. Je n'ai rien poussé.

## Périmètre
- Le diff `origin/corrections/revue-directeur-2026-10...HEAD` compte 2 commits et 64 fichiers :
  - deux documents : `REVUE-DIRECTEUR-2026-10.md` et `UX_REVIEW_PUB-1.md` ;
  - deux tests : `test/core/preferences/stockage_cle_valeur_test.dart` et `test/capture/pub1b_capture_test.dart` ;
  - les captures et le script dans `docs/current/captures/PUB-1b/`.
- **Aucun fichier de `lib/` n'est modifié.** Rien n'est touché dans `supabase/`, `.github/`, `pubspec.yaml`, `vercel.json`, le thème, le Coran ni dart_define.
- Les commits sont en français et se terminent par les deux lignes exactes demandées.
- Aucune clé versionnée : la configuration Supabase n'est passée qu'en option de build, hors dépôt.

## Réserve 1 : catalogue aligné sur le code
- La ligne 28 de `REVUE-DIRECTEUR-2026-10.md` dit maintenant : pause « au toucher et au focus, jamais au survol de la souris (D10) », puis arrêt au premier geste et à la dernière page, sans boucle. Elle cite PUB-1b, les captures et les deux fichiers de test.
- Le code est cohérent : `bienvenue_page.dart` ne contient ni `MouseRegion` ni `Hover`. Seul un commentaire, ligne 13, dit que le survol ne met pas en pause.
- Il ne reste aucune mention d'une pause au survol dans `docs/current` en dehors de l'historique de D10.
- **Levée.**

## Réserve 2 : test du secours en mémoire
- Le nouveau test « lecture possible, ecriture en echec » simule une panne d'écriture seule (`ecritureEnPanne`).
- Mutations faites par moi :
  - `return _acces?.lire(clef);`, c'est-à-dire sans `?? _secours[clef]` : le test échoue (`Expected: 'oui'`, `Actual: <null>`) ;
  - suppression de `_secours[clef] = valeur;` : ce test et « stockage bloque » échouent.
- Le code est restauré : `test/core/preferences` passe au vert.
- **Levée.**

## Réserve 3 : captures
- J'ai relancé `CAPTURE_DIR=… flutter test --concurrency=2 test/capture/pub1b_capture_test.dart` : 34 tests passent et 54 PNG sont produits.
- **Les 54 sont identiques octet pour octet aux PNG versionnés** (vérifié avec `cmp`). Les captures sont donc reproductibles et non retouchées.
- Couverture :
  - les 5 pages à 320 texte ×2, en LTR et RTL, clair et sombre, chacune avec une vue `_fin` défilée jusqu'en bas ;
  - les 5 pages à 1440, clair et sombre ;
  - les pages 2 et 3 à 390, en LTR et RTL.
- Captures ouvertes par moi :
  - p2 320×2 sombre RTL, et sa vue `_fin` ;
  - p3 320×2 clair LTR ;
  - p5 320×2 clair RTL `_fin` ;
  - p1 320×2 sombre LTR `_fin` ;
  - p5 1440 sombre ;
  - p3 390 clair RTL ;
  - la capture de connexion prise par le navigateur.
- Ce que j'y vois :
  - aucun mot coupé ;
  - la croix et la marque ne se chevauchent pas ;
  - en RTL, la ligne d'état se remplit de droite à gauche ;
  - les boutons « Commencer » et « J'ai déjà un compte » sont entiers ;
  - aucune flèche « suivant » en page 5, aucun bouton grisé ;
  - à 1440, un seul bouton plein, au bord de fin.
- L'Interface guidée est sans objet avant la connexion (décision de PUB-1).
- **Levée.**

## Réserve 4 : persistance réelle du localStorage
J'ai fait ma **propre** preuve, avec un script écrit par moi, hors dépôt :
- `flutter build web --release` dans le worktree, avec une URL Supabase en `.invalid` et une clé au format publishable inventée.
- Ma première clé contenait « factice ». `Env.cleSupabaseValide` l'a refusée et l'application est restée sur une page vide. J'ai recompilé avec une autre clé : c'est un garde-fou attendu, pas un défaut.
- build/web est servi par un serveur node local. Toute requête externe est refusée et CanvasKit est servi depuis le build. Chromium 141 est préinstallé ; je n'ai rien installé.

Résultat : **PASS** sur 8 vérifications.
1. Première visite : la racine mène à `#/bienvenue`.
2. Après la croix : `#/connexion`, et `localStorage['presentation.vue'] = oui`.
3. **Nouvel onglet** dans le même profil : `#/connexion` directement. Aucune adresse `/bienvenue` dans l'historique de navigation.
4. Rechargement (F5) : `#/connexion`.
5. **Profil neuf, avec la clé posée à la main avant le chargement** : `#/connexion`. Cela prouve que la lecture du stockage durable suffit, sans aucun secours en mémoire.
6. Profil neuf vide : `#/bienvenue`.

Le script archivé du rédacteur et sa sortie (10 vérifications sur 10) concordent avec ce que j'obtiens. **Levée.** Elle reste à rejouer sur l'aperçu Vercel.

## Défaut trouvé hors périmètre : la touche Entrée sur le web
- Dans le même build, Tab place bien le focus sur la croix : l'anneau de focus est visible.
- **Entrée ne fait rien** : l'adresse reste `#/bienvenue` et `localStorage` vaut null, sur deux essais. **Espace** mène bien à la connexion.
- La cause est dans `lib/core/widgets/pressable.dart:349-351`. Le composant ne déclare que `ActivateIntent`, alors que sur le web Flutter lie Entrée à `ButtonActivateIntent` (`widgets/app.dart:1316-1318`).
- Le test de widget « … s active par Entree » passe uniquement parce que `kIsWeb` vaut false en test.
- Le défaut touche **tous** les boutons bâtis sur `Pressable` dans l'application, pas seulement la présentation. Le clavier reste utilisable par Espace, donc ce n'est pas un blocage strict de SC 2.1.1. Mais l'affirmation « Entrée l'active » de la fiche PUB-1 (ligne 132) est fausse sur le web.
- Ce n'est pas introduit par PUB-1b, qui ne touche aucun code. **À traiter dans un lot dédié sur le composant partagé :** ajouter `ButtonActivateIntent` aux actions de `Pressable`, recenser ses appelants, et ajouter un test sous `Shortcuts(WidgetsApp.defaultWebShortcuts)`.

## Contrôles
| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | aucun problème |
| `verifier_jetons` | 37, plafond inchangé |
| `verifier_revue` | 1533, identique au chiffre annoncé |
| `dart format` sur les 2 fichiers de test | aucun changement |
| `flutter test --concurrency=2` sur `test/core/preferences`, `test/features/bienvenue`, `test/router` et `test/capture` | +329 ~946, 0 échec |
| Captures PUB-1b | +34, 54 PNG identiques aux PNG versionnés |

Aucun code de production n'a changé : il n'y a donc pas de régression possible sur les autres appelants.

## Réserves (sans blocage de la fusion)
1. Le défaut de la touche Entrée sur le web, dans `Pressable` : préexistant, à corriger dans un lot dédié. Il faut aussi corriger la ligne 132 de la fiche PUB-1.
2. Rejouer la recette de persistance sur l'aperçu Vercel ou en staging lors de la PR.
3. Les deux observations hors périmètre déjà consignées : la langue `en-US@posix` qui arrête le démarrage, et le « ? » isolé sur /connexion. Je vois ce dernier sur la capture du navigateur.

## Statut de preuve
Spécifié, présent dans le code (inchangé), testé localement, exécuté dans un vrai navigateur en local (rejoué indépendamment par le relecteur). Pas testé sur staging, pas déployé.
