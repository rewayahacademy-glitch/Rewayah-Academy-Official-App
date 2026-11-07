# PUSH-1 : Réglages des notifications sur l'appareil (revue UX)

Lot du 07/11/2026, branche `claude/push-1`, décision `DECISION-PUSH-2026-11-01.md` §6
(amendement du 07/11). Revue exigée par `DESIGN-GOV-2026-09-26.md` §4.

**État :** présent dans le code, testé localement (tests Flutter, captures d'outil à 390 et 1440,
en français et en arabe, dans `docs/current/captures/E2E/push-1/`). Ni testé sur staging, ni
déployé. **Aucun push réel n'a été reçu sur un appareil** : c'est la preuve du directeur.

## Demande

Le directeur, le 07/11 : « le vrai user a besoin des notifications. Moi personnellement j'en ai
besoin. Je ne reçois pas de notifications. » Tous les rôles qui ont un compte.

## Ce qui est fait

1. **Entrée.** Un lien « Notifications sur cet appareil » en tête de la page Notifications, que
   tous les rôles atteignent par leur cloche. Il reste visible quand la liste est vide ou en
   erreur (le cas du directeur le 07/11 : aucune notification). Aucune route nouvelle.
2. **Feuille.** `AppBottomSheet` (feuille au téléphone, boîte à 840 et plus) : une phrase de
   contexte, l'état de cet appareil en une phrase, les cinq catégories en un `GroupeReglages`
   à bascules, une phrase sur l'effet d'une catégorie coupée. Le seul bouton (« Recevoir les
   notifications sur cet appareil », ou « Ne plus les recevoir sur cet appareil » en contour)
   est dans la zone d'actions, collée au pied.
3. **Autorisation après un geste.** Le navigateur ne demande rien à l'ouverture de la page ni de
   la feuille ; la demande part du toucher du bouton. La clé publique est lue d'avance pour que
   la demande suive le geste sans attente (Safari l'exige).
4. **Cas sans bouton** (le bouton n'est pas rendu, une phrase dit quoi faire) : navigateur sans
   push ; iPhone ou iPad hors écran d'accueil ; notifications bloquées dans le navigateur ;
   compte sans push (enfant, compte inactif).

## Contrôle par règle

| Règle | Source | Date | Conclusion | Modification |
|---|---|---|---|---|
| Demander une permission en contexte, après un geste, jamais au lancement | web.dev « Permission UX » ; Apple HIG « Notifications » (demander quand la personne comprend le bénéfice) | relu le 07/11/2026 | conforme : demande au toucher du bouton seulement | clé publique lue d'avance, appel au navigateur sans attente avant |
| Une action principale visible sans défilement | Material 3, Bottom sheets (actions en pied) ; K-56 | 07/11/2026 | **non conforme dans la première version** : à 390 en français, le bouton était sous les cinq catégories | bouton déplacé dans la zone d'actions de la feuille (capture 02 avant/après) |
| Un état ne se dit pas par la couleur seule | WCAG 2.2, 1.4.1 | 07/11/2026 | conforme : la bascule a sa position et son libellé, l'état de l'appareil est une phrase | aucune |
| Tout échec dit quoi faire | K-59 ; Nielsen, heuristique 9 | 07/11/2026 | conforme : refus, demande ignorée, échec d'inscription, hors ligne, lecture en erreur ont chacun leur phrase | aucune |
| iPhone : le Web Push n'existe que pour une application ajoutée à l'écran d'accueil | WebKit, « Web Push for Web Apps on iOS and iPadOS » (iOS 16.4) | 07/11/2026 | la feuille le dit et n'affiche aucun bouton | phrase `push1.reglages.iosEcranAccueil` |
| Sur l'écran verrouillé, aucune donnée sensible | consigne du garde-cap, 07/11 | 07/11/2026 | conforme : textes du push sans nom, montant ni motif ; la feuille le dit dans sa phrase de contexte | aucune |
| Arabe : miroir de la mise en page | Material 3, Bidirectionality | 07/11/2026 | conforme sur les captures 05 à 08 (bascules à gauche, flèche du lien miroir) | aucune |

## Limites connues

- Le contenu d'une catégorie dépend du rôle (un tuteur ne reçoit jamais « Demandes et
  dossiers ») ; les cinq catégories s'affichent pour tous, parce que l'écran lit une capacité et
  jamais un rôle. À revoir avec le directeur s'il le souhaite.
- La page Préférences du tuteur garde sa ligne « Notifications » sans lien : ce fichier est dans
  la zone d'un autre agent.
