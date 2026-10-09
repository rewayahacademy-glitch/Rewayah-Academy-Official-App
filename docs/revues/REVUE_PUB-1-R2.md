<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Relecture adverse PUB-1 : branche `corrections/c2-pub`, commit `8dc0f7c8`

**Verdict : la fusion est acceptée, avec réserves.** Il ne reste aucun défaut majeur prouvé et la demande est remplie. Quatre réserves mineures sont listées à la fin.

La relecture a été faite en lecture seule, dans un worktree jetable détaché sur `origin/corrections/c2-pub`, retiré à la fin. Je n'ai rien poussé ni modifié. Le lot PUB-1 est le diff `6e2c91c4..8dc0f7c8`, soit 8 commits.

## Périmètre et interdits
- Fichiers touchés :
  - la page `lib/features/bienvenue/bienvenue_page.dart` ;
  - les préférences `lib/core/preferences/presentation_vue.dart`, `stockage_cle_valeur.dart` et `stockage_navigateur*.dart` ;
  - le routeur `redirection.dart` et `app_router.dart` ;
  - `MarquePage` ;
  - les libellés i18n en français ;
  - `tool/libelles_sources.json`, la fiche, les captures et les tests.
- Rien n'est touché dans `supabase/`, `.github/`, `pubspec.yaml`, `vercel.json`, le thème, le rendu du Coran ni dart_define. Aucun branchement serveur.
- Commits en français, tous terminés par les deux lignes demandées.

## Conformité à la demande

| Exigence | Constat |
|---|---|
| 3 à 5 pages, une idée par page | 5 pages : le service, la classe stable à horaire fixe, l'enseignant attitré, le parcours selon le niveau, le suivi de la famille. Chacune a un titre, une phrase et un pictogramme existant. |
| Aucun nouvel asset | Seuls des `AppIcons` existants sont utilisés. |
| Contenu sourcé, sans promesse non tenue | Les textes viennent de l'ancien accueil et de `01_PRODUIT_ET_PARCOURS.md` (lignes 5, 19 et 35 : parcours de base « lecture de l'arabe et Coran »). Aucun prix, aucun chiffre. |
| Défilement automatique | Toutes les 6 s, avec une ligne d'état segmentée qui se charge. |
| Pause | Au toucher et au focus. Jamais de défilement si « réduire les animations » est actif ou si un lecteur d'écran est ouvert. Il s'arrête au premier geste et à la dernière page, sans boucler. |
| Glissement manuel | Oui. Des flèches, absentes aux bornes et jamais grisées, ainsi que le clavier, gauche et droite inversés en RTL. |
| Croix en haut | Elle est nommée « Passer la présentation », c'est le premier arrêt de tabulation, et Entrée l'active. |
| Vue une fois par appareil | La préférence `presentation.vue` est écrite dans le localStorage sur le web, dans Drift ailleurs. Une panne ne bloque jamais l'entrée. |
| Routeur | Pour un visiteur sans session à la racine : rien tant que l'appareil n'a pas été lu (écran de démarrage), puis `/bienvenue`, puis `/connexion` une fois vue. Le lien « Découvrir Rewayah Academy » de la connexion y ramène. |
| 5 états | Chargement (démarrage), contenu, vide et erreur sans objet ou absorbés, hors ligne (bandeau `PageShell`, capture). |
| Interface guidée | Sans objet avant la connexion. |
| i18n | Français seulement. `ar.i18n.json` n'a aucune clé `bienvenue` : c'est vérifié, la décision D7 est fondée. |
| Mention des libellés | Les 13 clés portent exactement « rédigé par l'agent, validé par délégation le 05/10 ». |
| Fiche et décisions | Fiche dans `UX_REVIEW_PUB-1.md`, décisions D1 à D13 marquées « décidé par délégation le 05/10 », statut de preuve honnête, ligne de catalogue présente (voir la réserve 1). |

## Vérifications exécutées
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_jetons` : 39, aucune entrée sur les fichiers du lot.
- `verifier_revue` : 1539, aucune entrée sur les fichiers du lot.
- `flutter test --concurrency=2` :
  - `test/features/bienvenue`, `test/core/preferences` et `test/router` : +328, 0 échec ;
  - régressions sur les autres appelants (`MarquePage`, redirection), dans `test/accessibilite`, `test/agent`, `test/widgets`, `test/capture`, `test/features` et `test/core` : +4253 (~2940 sautés), **0 échec**.

## Mutations faites par le relecteur
J'ai annulé chaque correction une par une ; à chaque fois, au moins un test échoue :
- pause au toucher ;
- pause au focus ;
- exclusion de « réduire les animations » ;
- exclusion du lecteur d'écran ;
- `marquerVue` de la croix ;
- prise de main au glissement ;
- boucle en fin de présentation ;
- isolat de la position en RTL ;
- redirection « vue » vers `/bienvenue` au lieu de `/connexion` ;
- pause au survol réintroduite (`onPointerHover`) ;
- flèches du clavier inversées ;
- flèche « suivant » qui ne donne plus la main au visiteur ;
- `thumbVisibility` à false ;
- `lire` au lieu de `ecrire` dans le stockage ;
- `MarquePage` repassée en `Text` (échec du test 320 x2 RTL) ;
- `setItem` supprimé dans `StockagePreferencesCleValeur`.

**Une mutation survit :** la suppression du secours en mémoire quand le stockage est lisible (réserve 2).

## Captures ouvertes
J'ai ouvert :
- p1 et p4 en 320 x2 clair LTR ;
- p1 et p5 en 320 x2 sombre RTL ;
- p5 en 390 clair ;
- p4 en 390 RTL ;
- p5 en 1440 sombre ;
- p1 en 1440 avec la souris posée depuis 3 s ;
- 390 hors ligne.

Ce que j'y vois :
- aucun mot coupé ;
- la croix et la marque ne se chevauchent pas ;
- en RTL, la position se lit « 1 / 5 » et la ligne d'état se remplit de droite à gauche ;
- à 320 x2, la barre de défilement signale la suite ;
- à 1440, les boutons ont la largeur de leur libellé, au bord de fin, avec un seul bouton plein ;
- la ligne avance bien avec la souris posée.

## Réserves (mineures, à lever sans bloquer la fusion)
1. `docs/current/REVUE-DIRECTEUR-2026-10.md:28` mentionne encore une pause « au survol », retirée par D10 : la ligne de catalogue est à corriger.
2. Ajouter un test « lecture possible, écriture en échec » pour garder le secours en mémoire (`stockage_cle_valeur.dart:41`).
3. La persistance du localStorage reste à constater dans un vrai navigateur, sur l'aperçu Vercel : passer la croix, recharger, la connexion doit s'afficher directement.
4. Les captures ne montrent que les pages 1, 4 et 5. Il manque, à 320 x2, le sombre en LTR et le clair en RTL. Les tests couvrent ces cas.

## Statut de preuve
Spécifié, présent dans le code, testé localement, compilé pour le web (selon le rédacteur, non rejoué ici). Pas exécuté dans un navigateur, pas testé sur staging, pas déployé.
