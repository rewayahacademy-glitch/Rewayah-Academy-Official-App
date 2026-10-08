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
                  qu'un doigt touche, que la souris survole ou que le focus
                  clavier est dans la page ; aucun défilement si « réduire
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
| D4 | Un geste du visiteur arrête le défilement pour la visite ; pas de boucle | WCAG 2.2.2 (le mouvement s'arrête) ; Nielsen, contrôle de l'utilisateur. Le toucher immobile, le survol et le focus mettent en pause, puis reprennent. |
| D5 | Pas de défilement sous lecteur d'écran | Un changement de page imposé couperait la lecture en cours. |
| D6 | La visite est notée à la sortie (croix ou boutons), pas à l'affichage | Une présentation interrompue (application fermée) revient une fois ; jamais de connexion sans avoir pu la passer. |
| D7 | Libellés FR seulement | `ar.i18n.json` ne couvre pas l'accueil public (aucune clé `bienvenue`) ; l'arabe retombe sur le français (base_locale), en RTL. |
| D8 | Persistance web par `localStorage` (dart:js_interop, sans dépendance) | Le stockage commun des préférences est en mémoire sur le web : la PWA reverrait la présentation à chaque visite. Limité à cette seule clé : le thème garde son comportement. |
| D9 | `MarquePage` passe par `TexteSansCoupure` | À 320 px texte ×2, « Rewayah Academy » se coupait dans le mot à côté de la croix ; correction dans le composant partagé (lib/CLAUDE.md), sans effet à l'échelle 1. |

## Revue UX (DESIGN-GOV §4)

Date : 08/10/2026. **Limite de preuve** : les pages officielles n'ont pas pu être relues en
ligne pendant cette session (`www.w3.org` refusé par le proxy réseau ; la page Apple HIG
« Onboarding » est rendue sans son texte). Les règles ci-dessous sont citées de mémoire de
leur texte publié ; chaque conclusion dit sa conséquence concrète, vérifiée par un test.

| Proposition contrôlée | Source | Règle utile | Conclusion | Modification / preuve |
|---|---|---|---|---|
| Défilement automatique | WCAG 2.2, SC 2.2.2 Pause, Stop, Hide (AA) | Un contenu qui bouge ou se met à jour seul plus de 5 s, en parallèle d'autre contenu, doit pouvoir être mis en pause, arrêté ou masqué | ajustée | Pause au toucher, survol, focus ; arrêt définitif au premier geste ; arrêt en fin de cycle (30 s au plus) ; tests « en pause tant qu'un doigt touche », « … focus clavier », « s'arrête à la dernière page » |
| Mouvement réduit | WCAG 2.2, SC 2.3.3 (AAA, appliqué par prudence) ; `AppMouvement.mouvementReduit` | Une animation non essentielle se désactive | conforme | Aucun défilement, ligne d'état fixe, passage de page sans glissement (durée 0) ; test « jamais quand réduire les animations est actif » |
| Glissement manuel | WCAG 2.2, SC 2.5.7 Dragging Movements (AA) | Une action par glissement a une alternative à un seul pointeur | conforme | Flèches précédent / suivant (`BarrePrecedentSuivant`, cible 48) ; test « les flèches et le clavier changent de page » |
| Croix pour tout passer | WCAG 2.2, SC 2.1.1 Clavier, 4.1.2 Nom, rôle, valeur ; Apple HIG Onboarding (passer l'accueil) ; Nielsen n°3 | Atteignable au clavier, nommée ; l'accueil se passe | conforme | `BoutonIcone` nommé « Passer la présentation », premier arrêt de tabulation ; tests « la croix … clavier … Entrée » |
| Une idée par page, 5 pages | Hick ; Apple HIG Onboarding (bref) ; Nielsen n°8 (minimalisme) | Peu de choix et peu de texte par écran | conforme | Un titre, une phrase, un pictogramme ; une seule action pleine en fin |
| Position et ligne d'état | Nielsen n°1 (visibilité de l'état) ; WCAG 1.4.1 (pas la couleur seule) | L'état se lit autrement que par la couleur | conforme | Ligne d'état décorative + position écrite « 2 / 5 », annoncée « Présentation, page 2 sur 5 » |
| Sorties en fin | DESIGN-GOV Contrat B ; K-56 | Un seul CTA plein ; trailing ; pas pleine largeur sur bureau ; objet vers CTA : 16 | conforme | `Ecart.vLg` sous le texte ; bureau : tertiaire puis principal au bord de fin, largeur du libellé ; test 1440 et `verifierUnSeulBoutonPlein` |
| Reflow 320 px, texte ×2 | WCAG 2.2, SC 1.4.10 et 1.4.4 | Pas de perte de contenu, pas de défilement horizontal | ajustée | Chaque page défile verticalement si besoin ; `TexteSansCoupure` ; marque corrigée (D9) ; test 320 ×2 LTR et RTL |
| RTL | Material 3, bidirectionnalité | Le sens du glissement et des flèches suit la langue | conforme | `PageView` et `BarrePrecedentSuivant` en `Directionality` ; test « en arabe, le glissement vers la droite avance » |

## Besoin serveur

Aucun. La présentation ne lit ni n'écrit rien côté serveur.

## Statut de preuve

- spécifié : oui (cette fiche) ;
- présent dans le code : oui ;
- testé localement : oui (`flutter test`, voir le bilan de l'étape) ;
- testé sur staging, déployé : non.
