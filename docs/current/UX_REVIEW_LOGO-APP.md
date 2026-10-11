# LOGO-APP : afficher le logo (revue UX, DESIGN-GOV §4.2)

Ordre du directeur du 10/10/2026 : « fais le nécessaire pour afficher le logo, au bon
moment, au bon endroit, à la bonne taille et surtout à la bonne couleur ». Corrections du
même jour : aucun logo sur l'écran de démarrage (animation à venir), favicon et icônes PWA
copiés depuis le site public et jamais rastérisés, rendu strictement issu des SVG livrés.
Branche `claude/logo-app`.

Statut : présent dans le code, testé localement. Ni staging, ni déploiement.

## Sources et date

Consultation le 10/10/2026.

| Source | Accès | Usage |
| :--- | :--- | :--- |
| `assets/brand/logo/README.md` (règles d'usage livrées avec les SVG du directeur) | lu | source qui fait foi : variantes, couleurs, tailles minimales, zone de protection, placement, sémantique |
| `docs/current/03_DESIGN_SYSTEM_ET_UX.md`, `lib/CLAUDE.md`, `DESIGN-GOV-2026-09-26.md` | lus | jetons seulement, cibles de 48, RTL, une tâche par écran, format de cette preuve |
| Material Design 3, Apple HIG (Branding), WCAG 2.2 | **non relus en ligne dans cette session** ; rien n'en est cité mot pour mot | le seul critère chiffré employé (3:1 pour un élément graphique, WCAG 1.4.11) est déjà repris par le README et par `app_palette.dart` |

## Propositions contrôlées

| Proposition | Règle utile | Conclusion | Modification |
| :--- | :--- | :--- | :--- |
| Logo vertical sur la connexion, centré, 96 de haut (64 sous 720 de hauteur de fenêtre) | README : « Connexion, splash, onboarding : `logo-vertical`, centré, dans un espace dégagé », minimum 56 | conforme | `MarquePage(logo: true)` ; image nommée « Rewayah Academy » et titre de section, le nom n'étant plus écrit en texte |
| Aucun logo au démarrage | décision du directeur du 10/10 (animation propre à venir) | ajustée | `EcranDemarrage` garde le mot-marque texte ; test qui vérifie l'absence de logo |
| Logo horizontal en tête de la barre latérale (bureau, rôles et admin) et du tiroir admin, 32 de haut, cliquable vers l'accueil du rôle | README : en-tête large = `logo-horizontal`, début de ligne, seul logo cliquable, libellé « Rewayah Academy, accueil » | conforme | remplace le mot-symbole texte « Rewayah » ; lien `Pressable` (cible ≥ 48, focus clavier) |
| Symbole seul en tête des rails repliés (rôles et admin), 32 de haut | README : barre étroite = `symbole-plein`, minimum 24 | conforme | rail des rôles : au-dessus du bouton de dépli ; rail admin : `leading` du `NavigationRail` |
| Aucun logo sur téléphone dans la barre basse ni dans la barre mobile admin | README : jamais dans un bouton ni une liste, un seul logo par écran ; la barre basse est une navigation, pas un en-tête ; la barre mobile admin tient déjà quatre cibles de 72 à 320 px (PAGESHELL-200-1e) | ajustée | le tiroir admin porte le logo ; les pages gardent leur titre comme seule tête |
| Couleur | README : violet #8652E6 sur fond clair et sombre, blanc sur bande violette, encre pour l'impression, jamais une autre teinte de violet | conforme | violet = `surfacePrimary.background` de la palette claire, aussi en thème sombre (3,58:1 sur `surfaceCanvas` sombre, 3,27:1 sur `surfaceRaised` sombre) ; aucun jeton modifié |
| Zone de protection et proportions | README : 25 % de la hauteur de chaque côté, mise à l'échelle homogène, repli vers le symbole sous le minimum | conforme | appliqués dans `BrandLogo` une fois pour toutes, jamais dans un écran |
| RTL | README : le logo suit le sens de lecture, ne se retourne jamais | conforme | posé en `start` ; aucun miroir ; test en arabe |

## Ce qui n'est pas fait

- Favicon et icônes PWA de `web/` : le site public (`site-public/`, branche
  `codex/site-public-preview-main`) ne contient que des SVG, aucun PNG aux tailles
  attendues par `web/manifest.json` (favicon, 192, 512, maskable 192 et 512). Rien n'est
  généré, sur décision du directeur ; `web/` est inchangé.
- Récupération d'accès : mot-marque texte gardé. Avec le logo, le bouton d'envoi sortait de
  la vue d'une fenêtre de 800 x 600 (mesuré par `bienvenue_connexion_navigation_test.dart`) ;
  la page est une tâche secondaire à retour, le logo vient d'être vu sur la connexion.
- Présentation publique (`/bienvenue`, K-64) et dépôt de pièce : mot-marque texte
  inchangé ; `MarquePage(logo: true)` est prêt pour la session qui tient ces pages.

## LOGO-1 : état des surfaces au 11/10/2026

Vérifié sur `ccr` @ 87c43aa0 :

| Surface | État |
| :--- | :--- |
| Barre latérale et rail (`NavShell`, `_EnteteColonne`) | fait : `BrandLogo` horizontal (déplié) ou symbole (replié), seul logo de l'écran, ramène à l'accueil ; test `nav_shell_adaptatif_test.dart` |
| Coque administration (`AdminShell`) | fait : logo horizontal en tête de la barre latérale, symbole en tête du rail ; test `admin_shell_test.dart` |
| Connexion (`MarquePage(logo: true)`) | fait |
| Récupération d'accès, bienvenue (K-64), dépôt de pièce, états du routeur (`MarquePage()`) | mot-marque texte gardé ; pour la bienvenue publique, session qui tient ces pages (K-64) ; récupération : le bouton d'envoi sortait de la vue à 800 x 600 avec le logo (voir ci-dessus) |
| Favicon web | fait : `web/favicon.svg` est le symbole plein violet du directeur, octet pour octet (test `test/core/marque/favicon_test.dart`), déclaré dans `web/index.html` |

Restes, volontairement non traités ici (pubspec.yaml et copie depuis le site public, jamais de rastérisation par un agent, README du logo) :

- `web/favicon.png` et `web/icons/*` (PWA) : ne viennent pas du logo ; à copier depuis les fichiers produits pour le site public (décision du directeur du 10/10) ;
- icônes Android et iOS natives (`android/app/src/main/res/mipmap-*`, `ios/.../AppIcon`) : `flutter_launcher_icons` exige `pubspec.yaml`, interdit aux sessions ;
- écran de démarrage, e-mails, fiches des stores ;
- versions carrée, claire et sombre de l'icône, couleur de fond, zone de protection de l'icône : à demander au directeur le moment venu.
