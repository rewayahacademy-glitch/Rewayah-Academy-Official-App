# Lot A11Y-1 (rang 13 de PLAN-LOTS : UX-004, UX-010, UX-021, UX-027), 06/11/2026

Statuts : `présent dans le code`, `testé localement` (flutter_test et robot de la pile locale).
Rien n'est `testé sur staging` ni `déployé` : la preuve du directeur en production reste à faire.

## Faux, non prouvé ou laissé à un autre lot (en premier)

- **UX-004 n'est pas corrigé ici.** Il est prouvé sur le web : à 1440 × 900, la barre latérale
  est absente de l'arbre d'accessibilité, en entier (ni « Navigation principale », ni le logo, ni
  les onglets), pour l'enseignant comme pour la famille. Le même compte à 390 a bien sa barre du bas
  (`group:Navigation principale` et 4 boutons). Dans flutter_test, la barre latérale a ses nœuds :
  l'écart vient du web. Le composant (`lib/core/widgets/nav_shell.dart`) appartient au lot 3
  WEB-BUREAU, qui a reçu le constat. Capture `17_enseignant_enseignant_barre_1440.png`.
- **UX-010 n'est pas corrigé ici.** Le chemin du constat du 31/10 (`zone_support.dart:508`) n'est
  plus celui de `/salle` : les flèches de page sont calculées dans
  `lib/features/salle_seance/telephone_plein_ecran.dart`, fonction `pageSalle`, fichier du lot 11
  SALLE-UX (UX-033). Arbitrage du garde-cap : transmis au lot 11 avec le correctif proposé (réduire
  la boîte de la page à `ecran.width - 2 × (48 + 8)` tant qu'elle reste à sa largeur naturelle).
- **Le parcours 3 de la pile est rouge sur main 7b3a3f05** (`parcours_3.mjs` cherche « Créer un
  compte », l'entrée ouvre sur le questionnaire depuis ENTREE-ORDRE). Hors lot, confié par le
  garde-cap à l'intégration du pilote. La famille de la preuve a donc été créée en SQL local
  (tuteur `e2e-a11y-tuteur@example.com`, enfant « Yanis ») ; preuve acceptée par le garde-cap.
- Le constat du 31/10 disait des touches du clavier « aucun nœud » : sur le build web d'aujourd'hui
  elles avaient un nœud, mais leur nom était doublé (« 2\n2 »). C'est ce qui est corrigé.

## Corrigé

| Point | Fichier | Correctif | Preuve |
| :--- | :--- | :--- | :--- |
| UX-021 | `lib/features/appareils/appairage_page.dart` | la zone annoncée (`liveRegion`) devient un conteneur à nœuds enfants explicites : titre, phrase et « Générer un nouveau code » ne fondent plus en un seul bouton | `test/features/appareils/emetteur_qr_test.dart` (rouge avant, vert après) ; robot : 1 nœud bouton nommé exactement, FR et AR, captures 01-02, 09-10 |
| UX-027 (nom) | `lib/core/widgets/pin_pad.dart` (accordé par le garde-cap) | le chiffre dessiné est exclu de la sémantique : la touche se lit une fois | `test/core/widgets/pin_pad_test.dart` (rouge avant, vert après) ; robot : 10 touches sur 10 nommées « 0 » à « 9 », FR et AR |
| UX-027 (consigne parlée) | `lib/core/widgets/audio_label.dart` (accordé par le garde-cap) | le texte dessiné est exclu de la sémantique : « Entre ton code » se lit une fois | `test/core/widgets/audio_label_test.dart` (rouge avant, vert après) ; robot : 1 nœud au nom exact, FR et AR |
| UX-027 (grille) | `lib/features/eleve_connexion/eleve_connexion_page.dart` | la phrase « Quatre chiffres, rien que pour toi… » reste sur « Entre-le encore une fois » : la grille ne change plus de place | `test/features/appareils/appareil_partage_test.dart` (rouge avant, vert après) ; robot : touche 2 à 414 puis 414 (FR), 396 puis 396 (AR), captures 05-08, 13-16 |

Aucun texte nouveau, aucune migration. Réutilisé : `EcranResultat`, `PinPad`, `Pressable` tels
quels ; le robot reprend `tool/e2e/commun.mjs`.

## Rejouer

```
tool/e2e/pile.sh ; tool/e2e/amorcer.sh
E2E_A11Y_TUTEUR=<courriel du tuteur> E2E_A11Y_ENFANT=<prénom> node tool/e2e/a11y_1.mjs
```

Sans ces variables, le script prend la famille du parcours 3 (`comptes_parcours3.json`).
