# PUB-1 : présentation publique avant la connexion (fiche et revue UX)

Étape PUB-1, branche `corrections/c2-pub` (issue de `corrections/revue-directeur-2026-10`).
Décision du 05/10/2026 (déléguée, choix b) : **codé directement, inscrit au catalogue par la
session**. Règle permanente DIR-REP-1 : aucune question au directeur ; chaque choix ci-dessous
est **décidé par délégation le 05/10**, selon la recommandation ou le choix le plus prudent.

Faute de catalogue des écrans actif dans `docs/current` (voir `DASH_STRATEGIE.md`, annexe A,
écart déjà acté), la fiche vit ici, au même format, avec la revue UX exigée par
`DESIGN-GOV-2026-09-26.md` §4.2.

## Demande du directeur

Avant la page de connexion, 3 à 5 pages (5 au plus) qui expliquent clairement et élégamment
l'application et le programme ; une idée principale par page ; pictogrammes existants du
système de design, aucun nouvel asset ; défilement automatique à un rythme de 5 à 7 s, en
pause au toucher, au focus et si « réduire les animations » est actif, avec une petite ligne
d'état qui se charge ; glissement manuel ; une croix en haut pour tout passer, accessible au
clavier et au lecteur d'écran ; l'accueil public actuel, trop chargé, est découpé sur ces
pages ; vue une seule fois par appareil, puis connexion.

## Fiche

```
CODE              PUB-01
Nom               Présentation publique
Rôle              Visiteur sans session (avant connexion ; aucune capacité,
                  aucun rôle lu)
Route             /bienvenue (remplace l'ancien accueil public, même route)
Entrées           racine d'un visiteur sans session, PREMIÈRE visite sur cet
                  appareil ; lien « Découvrir Rewayah Academy » de /connexion
                  (toujours, même après la première visite)
Sorties           croix « Passer la présentation » (toutes les pages) ;
                  « Commencer » et « J'ai déjà un compte » (dernière page) ;
                  les trois mènent à /connexion et notent la visite
Question          À quel service vais-je m'inscrire ?
Pages (une idée)  1 Le Coran en classe, en visio        pictogramme caméra
                  2 Une classe stable, à horaire fixe   pictogramme classes
                  3 Un enseignant attitré               pictogramme profil
                  4 Un parcours selon le niveau         pictogramme livre ouvert
                  5 Le suivi de la famille              pictogramme foyer
                    + sorties (16 sous le texte)
Action principale     « Commencer », dernière page seulement (un seul bouton
                      plein, K-56) ; « J'ai déjà un compte » en tertiaire
Actions secondaires   croix (BoutonIcone, en haut, bord de fin) ; flèches
                      précédent / suivant (BarrePrecedentSuivant, position
                      « 2 / 5 » au centre, flèche absente aux bornes)
Défilement        6 s par page (rythmePresentation) ; ligne d'état : un
                  segment par page, la page courante se charge ; pause tant
                  qu'un doigt touche ou que le focus clavier est dans la
                  page (le survol de la souris ne met pas en pause, D10) ;
                  aucun défilement si « réduire
                  les animations » ou lecteur d'écran ; un geste du visiteur
                  (glissement, flèche, touche) arrête le défilement pour la
                  visite ; arrêt à la dernière page, sans boucle
Clavier           Tab : croix, flèches, sorties ; flèches gauche / droite
                  (inversées en arabe) dès que le focus est dans la page
États             chargement  écran de démarrage du routeur, le temps de lire
                              la préférence locale (EtatPresentation.inconnu) ;
                              aucune donnée serveur lue
                  contenu     les cinq pages
                  vide        sans objet (contenu fixe)
                  erreur      préférence illisible : la présentation s'affiche
                              comme à une première visite ; écriture en échec :
                              la connexion suit quand même (rien à dire)
                  hors ligne  bandeau de PageShell ; le texte reste lisible ;
                              la connexion dit elle-même ce qui ne peut pas
                              aboutir
Interface guidée  sans objet (avant connexion, aucun profil)
Vue une fois      préférence locale `presentation.vue` : localStorage sur le
                  web (PWA), base locale Drift ailleurs ; rien n'est envoyé
Débordement       à 320 px texte ×2, une page dont la fin passe sous le bord
                  garde sa barre de défilement affichée (D12)
Invariants        aucun prix, aucun chiffre, aucune promesse hors
                  01_PRODUIT_ET_PARCOURS ; aucun bouton grisé ; aucun mot
                  coupé à 320 px texte ×2, LTR et RTL
```

Fichiers : `lib/features/bienvenue/bienvenue_page.dart`,
`lib/core/preferences/presentation_vue.dart`, `lib/core/preferences/stockage_navigateur*.dart`,
`lib/core/router/redirection.dart` (paramètre `presentation`), `lib/core/router/app_router.dart`,
`lib/core/widgets/marque_page.dart` (mot-marque sans coupure). Tests :
`test/features/bienvenue/presentation_test.dart`. Captures : `docs/current/captures/PUB-1/`.

## Décisions prises par délégation le 05/10

| # | Décision | Pourquoi (choix le plus prudent ou recommandé) |
|---|---|---|
| D1 | 5 pages | Les quatre notions exigées (classes stables en visio, enseignant attitré, horaire récurrent, suivi des familles) + le programme demandé (« l'app et le programme ») ; limite haute de la demande. |
| D2 | La présentation remplace l'accueil public sur `/bienvenue` | Le directeur juge l'accueil trop chargé et demande d'en découper la description ; garder les deux doublerait l'entrée. Le lien « Découvrir Rewayah Academy » de la connexion y mène toujours. |
| D3 | Rythme 6 s | Milieu de la fourchette 5 à 7 s. |
| D4 | Un geste du visiteur arrête le défilement pour la visite ; pas de boucle | WCAG 2.2.2 (le mouvement s'arrête) ; Nielsen, contrôle de l'utilisateur. Le toucher immobile et le focus mettent en pause, puis reprennent (le survol non, D10). |
| D5 | Pas de défilement sous lecteur d'écran | Un changement de page imposé couperait la lecture en cours. |
| D6 | La visite est notée à la sortie (croix ou boutons), pas à l'affichage | Une présentation interrompue (application fermée) revient une fois ; jamais de connexion sans avoir pu la passer. |
| D7 | Libellés FR seulement | `ar.i18n.json` ne couvre pas l'accueil public (aucune clé `bienvenue`) ; l'arabe retombe sur le français (base_locale), en RTL. |
| D8 | Persistance web par `localStorage` (dart:js_interop, sans dépendance) | Le stockage commun des préférences est en mémoire sur le web : la PWA reverrait la présentation à chaque visite. Limité à cette seule clé : le thème garde son comportement. Reprise : la logique (secours en mémoire, pannes absorbées) vit dans `stockage_cle_valeur.dart`, testée hors navigateur ; le fichier web ne fait que brancher `localStorage` (voir « Statut de preuve »). |
| D10 | Le survol de la souris ne met **pas** en pause (reprise après revue adverse, décidé par délégation le 05/10) | La demande nomme toucher, focus et mouvement réduit, pas le survol ; la page occupant tout l'écran, une pause au survol empêchait tout défilement sur ordinateur. La pause reste offerte à la souris : un clic maintenu (toucher), une flèche ou Tab (focus), et tout geste arrête le défilement (D4). Test « 1440 : la souris posée sur la page ne bloque pas le défilement » ; capture `pub1_p1_1440_souris_3s_clair.png`. |
| D11 | Titres et textes isolés dans leur propre sens (`isolerSens`, FSI…PDI) | Sans clé arabe (D7), le français s'affiche en RTL et son point final passait en tête de ligne. Même outil que COUPE-MOTS-2. Test « RTL : la ponctuation finale reste en fin de phrase ». |
| D12 | Barre de défilement toujours affichée quand une page déborde | À 320 px texte ×2, la fin du texte et les sorties de la dernière page passent sous le bord ; la barre dit qu'une suite existe dans une page qui se glisse de côté. Elle ne se dessine pas quand tout tient. La croix, toujours visible en haut, mène aussi à la connexion. Test « 320 px, texte x2 : la barre de défilement dit la suite ». |
| D13 | La position « 1 / 5 » est isolée elle aussi | Trouvé en ouvrant les captures RTL de la reprise : sans caractère fort, « 1 / 5 » s'affichait « 5 / 1 » dans la barre en sens arabe. Test « RTL : la position se lit 1 / 5, pas 5 / 1 ». La barre partagée `BarrePrecedentSuivant` n'est pas modifiée (correction locale, autres écrans hors périmètre). |
| D9 | `MarquePage` passe par `TexteSansCoupure` | À 320 px texte ×2, « Rewayah Academy » se coupait dans le mot à côté de la croix ; correction dans le composant partagé (lib/CLAUDE.md), sans effet à l'échelle 1. |

## Revue UX (DESIGN-GOV §4)

Date : 08/10/2026, sources relues le 09/10/2026 (reprise après revue adverse).

Sources relues dans leur texte publié :

- **WCAG 2.2** : `www.w3.org` reste refusé par le proxy réseau ; le texte normatif de chaque
  critère cité a été relu dans la source officielle du W3C, dépôt `w3c/wcag`, branche `main`,
  `guidelines/sc/<version>/<critère>.html` (pause-stop-hide, dragging-movements, reflow,
  resize-text, keyboard, name-role-value, use-of-color, animation-from-interactions).
  Correction issue de la relecture : 2.2.2 est de niveau **A** (et non AA) ; 2.3.3 porte sur
  le mouvement **déclenché par une interaction** (ici, le passage de page par flèche ou
  glissement), pas sur le défilement automatique, qui relève de 2.2.2.
- **Apple HIG, Onboarding** : relue par le flux de données de la page
  (`developer.apple.com/tutorials/data/design/human-interface-guidelines/onboarding.json`).
  Règles utiles : un parcours d'accueil « fast, fun, and optional » ; « If you let people skip
  the tutorial when they first launch your app or game, don't present it again on subsequent
  launches, but make sure it's easy for people to find if they want to view it later » ;
  « design a brief, enjoyable experience that doesn't require people to memorize a lot of
  information ».
- **Nielsen, dix heuristiques** : **non relues** pendant cette session (`www.nngroup.com`
  refusé par le proxy) ; citées de mémoire, à titre d'appui seulement : aucune conclusion ne
  repose sur elles seules.

| Proposition contrôlée | Source | Règle utile | Conclusion | Modification / preuve |
|---|---|---|---|---|
| Défilement automatique | WCAG 2.2, SC 2.2.2 Pause, Stop, Hide (A) | « For any moving, blinking or scrolling information that (1) starts automatically, (2) lasts more than five seconds, and (3) is presented in parallel with other content, there is a mechanism for the user to pause, stop, or hide it » | ajustée | Pause au toucher et au focus ; arrêt définitif au premier geste (glissement, flèche, touche) ; arrêt en fin de cycle (30 s au plus) ; le survol ne gèle plus le défilement (D10) ; tests « en pause tant qu'un doigt touche », « … focus clavier », « s'arrête à la dernière page », « 1440 : la souris posée… » |
| Mouvement réduit | `AppMouvement.mouvementReduit` (contrat du dépôt) ; WCAG 2.2, SC 2.3.3 Animation from Interactions (AAA, appliqué par prudence au passage de page) | 2.3.3 : « Motion animation triggered by interaction can be disabled » | conforme | Aucun défilement automatique, ligne d'état fixe, passage de page sans glissement (durée 0) ; test « jamais quand réduire les animations est actif » |
| Glissement manuel | WCAG 2.2, SC 2.5.7 Dragging Movements (AA) | « All functionality that uses a dragging movement for operation can be achieved by a single pointer without dragging » | conforme | Flèches précédent / suivant (`BarrePrecedentSuivant`, cible 48) ; test « les flèches et le clavier changent de page » |
| Croix pour tout passer | WCAG 2.2, SC 2.1.1 Keyboard (A), 4.1.2 Name, Role, Value (A) ; Apple HIG Onboarding | 2.1.1 : « All functionality of the content is operable through a keyboard interface » ; HIG : accueil « optional », non reproposé une fois passé, retrouvable ensuite | conforme | `BoutonIcone` nommé « Passer la présentation », premier arrêt de tabulation ; vue une fois par appareil ; lien « Découvrir Rewayah Academy » de la connexion pour la revoir ; tests « la croix … clavier … Entrée », « routeur réel : déjà vue… » |
| Une idée par page, 5 pages | Apple HIG Onboarding (« brief », sans « memorize a lot of information ») ; Nielsen n°8 (non relue) | Peu de texte par écran | conforme | Un titre, une phrase, un pictogramme ; une seule action pleine en fin |
| Position et ligne d'état | WCAG 2.2, SC 1.4.1 Use of Color (A) ; Nielsen n°1 (non relue) | « Color is not used as the only visual means of conveying information » | conforme | Ligne d'état décorative + position écrite « 2 / 5 », annoncée « Présentation, page 2 sur 5 » |
| Sorties en fin | DESIGN-GOV Contrat B ; K-56 | Un seul CTA plein ; trailing ; pas pleine largeur sur bureau ; objet vers CTA : 16 | conforme | `Ecart.vLg` sous le texte ; bureau : tertiaire puis principal au bord de fin, largeur du libellé ; test 1440 et `verifierUnSeulBoutonPlein` |
| Reflow 320 px, texte ×2 | WCAG 2.2, SC 1.4.10 Reflow (AA), 1.4.4 Resize Text (AA) | 1.4.10 : « without loss of information or functionality, and without requiring scrolling in two dimensions » à 320 px ; 1.4.4 : texte à 200 % « without loss of content or functionality » | ajustée | Chaque page défile verticalement si besoin, barre de défilement affichée quand elle déborde (D12) ; `TexteSansCoupure` ; marque corrigée (D9) ; tests 320 ×2 LTR et RTL, « … la barre de défilement dit la suite » |
| RTL | Bidirectionnalité (UAX #9, isolats FSI/PDI, outil `isolerSens` du dépôt) | Le sens du glissement et des flèches suit la langue ; un texte d'une autre écriture garde sa ponctuation à sa place | ajustée | `PageView` et `BarrePrecedentSuivant` en `Directionality` ; textes isolés (D11) ; tests « en arabe, le glissement vers la droite avance », « RTL : la ponctuation finale reste en fin de phrase » |

## Besoin serveur

Aucun. La présentation ne lit ni n'écrit rien côté serveur.

## Reprise après revue adverse (09/10/2026)

| Point levé | Correction | Preuve |
|---|---|---|
| Majeur : le survol de la souris gelait le défilement sur ordinateur | Pause au survol retirée (D10) | Test « 1440 : la souris posée sur la page ne bloque pas le défilement » (échoue sur l'ancien code : « 5 / 5 » introuvable) ; capture `pub1_p1_1440_souris_3s_clair.png` |
| Mention des libellés | Formule exacte « rédigé par l'agent, validé par délégation le 05/10 » sur les 13 clés `bienvenue.*` | `tool/libelles_sources.json` |
| Point final en tête de ligne en RTL | Isolats de sens (D11) ; position aussi (D13) | Tests « RTL : la ponctuation finale… » et « RTL : la position… » (échouent sur l'ancien code) ; captures `*_rtl.png` |
| Fin de page invisible à 320 ×2 | Barre de défilement affichée quand la page déborde (D12) | Test « 320 px, texte x2 : la barre de défilement dit la suite » (échoue sur l'ancien code) ; captures `*_320x2_*.png` |
| Persistance web non prouvée ; sources citées de mémoire | Logique séparée et testée (D8) ; compilation web faite ; sources relues (section Revue UX) | Voir ci-dessous |

## Statut de preuve

- spécifié : oui (cette fiche) ;
- présent dans le code : oui ;
- testé localement : oui (`flutter test`, voir le bilan de l'étape). La persistance « vue une
  fois » de la PWA est testée sur la logique réelle du web (`StockagePreferencesCleValeur`,
  dont hérite `StockagePreferencesNavigateur`) avec un `localStorage` simulé qui survit au
  rechargement, bloqué ou absent (`test/core/preferences/stockage_cle_valeur_test.dart`) ;
- compilé pour le web : oui, `flutter build web --release` réussi le 09/10 (hors dépôt) ; le
  JavaScript produit contient bien `v.G.localStorage` → `getItem("presentation.vue")` et
  `setItem`, sous garde `try`, avec le secours en mémoire ;
- **non exécuté dans un navigateur** : aucun navigateur n'est installable sur la machine de
  l'agent (téléchargements Chromium refusés par le proxy). La lecture et l'écriture réelles du
  `localStorage` restent à constater sur l'aperçu Vercel (recette : ouvrir la racine, passer la
  présentation par la croix, recharger : la connexion s'affiche directement) ;
- testé sur staging, déployé : non.
