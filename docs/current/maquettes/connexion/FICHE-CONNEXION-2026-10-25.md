# Fiche d'écran : Connexion (`/connexion`), 25/10/2026

Décision 6 de `docs/orchestration/ETUDE-ACCUEIL-ET-CLASSES-2026-10-25.md`, précisée par le
directeur le 25/10 à 16:20 (capture de la page « Ne plus recevoir ces e-mails » sur téléphone).
État : **validée par le directeur** (choix D1 à D4 délégués au pilote, tranchés ci-dessous).
Une seule PR, poussée après la fusion de la PR 57, sur la branche de travail rebasée sur `main`.

## 1. En une phrase

La connexion prend, à l'identique, la page « Ne plus recevoir ces e-mails » du site public : fond
violet de marque uni, logo horizontal blanc centré en haut, l'illustration de la porte
(celle des pages 404 et de désinscription, telle quelle), titre, texte, puis le formulaire posé
directement sur la page, aucun rectangle emboîté. On ajoute seulement les champs et les boutons
de la connexion ; rien d'autre ne change.

## 2. Ce qui ne change pas (vérifié dans le code le 25/10)

- Les textes : tous existent déjà dans `assets/i18n` sous `connexion.*` (« Se connecter », « J'ai
  déjà un compte » / « Créer un compte », intro, « Votre adresse électronique », « Recevoir le
  lien », « ou », « Continuer avec Google », « Connecter l'appareil d'un élève », « Lien expiré ou
  jamais reçu ? », « Lien envoyé », erreurs, hors ligne). Aucun mot nouveau, aucune clé nouvelle.
- Le comportement : lien par courriel sans mot de passe, Google, appareil de l'élève, récupération,
  mode démonstration hors production, lien « Mentions » en bas. Aucune règle d'accès ne bouge.
- Les composants : `BrandLogo`, `PorteLumiere`, `ActionPrincipale`, `LienFleche`,
  `ControleSegmente`, `PageShell`. Rien de recréé, aucune couleur ni police hors de la palette.

## 3. Téléphone (moins de 840 points de large) : la capture du directeur, plus le formulaire

De haut en bas, page qui défile, sur fond violet uni :
1. logo horizontal blanc (`BrandLogo`, `horizontal`, `FondLogo.violet`), centré (décision du
   directeur du 25/10, 16:40), zone de protection respectée ;
2. l'illustration de la porte, centrée, exactement celle du site : symbole blanc, vide de la porte
   en dégradé, faisceau de lumière, pas en pointillés, lanterne ; scène immobile, comme sur la
   capture du directeur ; aucune animation, règle des durées gelées et WCAG 2.2.2 ;
3. le titre « Se connecter » (ou « Créer votre compte »), blanc, comme le titre du modèle ;
4. la phrase d'intro, blanche ;
5. le choix « J'ai déjà un compte » / « Créer un compte » (contrôle segmenté existant, en blanc
   sur violet) ;
6. le champ adresse, posé sur la page : fond blanc, encre sombre, étiquette blanche au-dessus ;
7. **le seul bouton plein** « Recevoir le lien » : blanc, texte violet, pleine largeur, comme le
   premier bouton du modèle ;
8. « Continuer avec Google » : bouton à contour blanc, comme le second bouton du modèle ;
9. en liens avec flèche, blancs : « Connecter l'appareil d'un élève », « Lien expiré ou jamais
   reçu ? », « Mentions ».
Espacements de l'échelle gelée : 12 entre champs, 16 entre le champ et son bouton, 8 entre les
deux boutons, 24 entre sections.

## 4. Ordinateur (840 points et plus) : deux volets, l'image au début de ligne

- **Volet image, 50 %, au début de ligne** (gauche en français, **droite en arabe** : `Row` avec
  `start` / `end`, jamais `left` / `right`) : fond violet uni, logo horizontal blanc centré en
  haut, l'illustration centrée dessous.
- **Volet formulaire, 50 %** : les points 3 à 9 du téléphone, largeur de lecture 400 au plus,
  centré verticalement, sur fond caramel clair ; encre sombre, bouton plein violet à texte blanc
  (couleur d'action de l'application), largeur du contenu et non pleine largeur ; bouton Google à
  contour sombre ; liens avec flèche en encre d'accent.

## 5. Décisions tranchées (déléguées par le directeur le 25/10)

| # | Décision |
|---|---|
| D1 | Caramel clair = `surfaceQuran` (`#F3EAD9`, parchemin de la page de Coran), déjà dans la palette ; aucune teinte nouvelle. |
| D2 | L'écran est identique en thème clair et sombre, comme la page modèle qui force son rendu : une seule composition à tester. |
| D3 | L'illustration est celle du site, telle quelle (la porte du logo est toujours ouverte) : aucune variante. |
| D4 | Téléphone : l'image au-dessus du titre, comme sur la capture ; la page défile, l'image ne disparaît jamais. |
| Logo | Le guide du logo prévoyait « connexion : logo vertical centré » ; demande du directeur du 25/10 : horizontal, centré en haut (16:40). Le guide (`assets/brand/logo/README.md`, ligne « Connexion, splash, onboarding ») est mis à jour dans la même PR. |

## 6. États obligatoires

Chargement (envoi du lien : bouton en attente, jamais grisé sans mot) ; contenu ; « Lien envoyé »
(même page, le formulaire remplacé par le texte, « Renvoyer le lien », « Utiliser une autre
adresse ») ; erreur (phrase sous le champ, lisible sur le fond : blanc sur violet, encre d'alerte
sur caramel) ; hors ligne : la phrase existante `horsLigne` sous le champ après la tentative, et
le bandeau de `PageShell`.
Contraste mesuré en test : blanc sur `#6538E4` 6,5:1 ; encre sur `surfaceQuran` à mesurer ;
jamais de texte lavande sur violet sous 4,5:1.

## 7. Ce que le code doit ajouter (faits vérifiés par le worker le 25/10)

1. **Palette** : le violet `#6538E4` n'est qu'une encre (`inkAccent`) ; ajouter dans
   `app_palette.dart` la surface pleine de marque (fond `#6538E4`, encre blanche), même valeur en
   clair et sombre. Pas de dégradé : le logo ne se pose jamais sur une zone non uniforme.
2. **`PageShell`** : une option de fond plein (surface de marque) ; jamais une coquille recréée.
3. **`PorteLumiere`** (`lib/core/widgets/porte_lumiere.dart`) existe, peint le symbole, le faisceau
   et les pas ; compléter : symbole blanc sur fond violet (`FondLogo.violet`), dégradé du vide de la
   porte (`VIDE_PORTE` de `site-public/scene_porte.py`), lanterne et son halo ; mêmes formes que le
   site, à l'unité près du `viewBox`. Aucune dépendance nouvelle.
4. **Tests** : `connexion_test.dart` vérifie la carte blanche, à réécrire ; la trentaine d'autres
   tests qui montent `ConnexionPage` restent verts.

## 8. Preuve avant la PR

`UX_REVIEW_CONNEXION.md` dans `docs/current/maquettes/connexion/` (règle gelée DESIGN-GOV §4) :
Material 3 fenêtre « expanded » à 840 pour les deux volets, WCAG 2.2 contraste et focus visible,
Baymard pour le champ unique et l'erreur sous le champ. Tests de rendu à 320 et 1440, texte ×1 et
×2, clair et sombre, français et arabe (image à droite) ; `verifierUnSeulBoutonPlein`,
`verifierSansChevauchement`, garde du logo (fond violet = logo blanc), contraste mesuré.
