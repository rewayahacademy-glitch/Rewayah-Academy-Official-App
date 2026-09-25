# REVUE2 — Lot A (revue adversariale + suite complète)

Session : B-2026-09-25-coord — 2026-09-25 08:02–08:xx

## Périmètre revu

Diff `origin/ui/tuteur-v1..HEAD` dans `C:\RA\lot-a` (branche `ui/tuteur-v1-a`, HEAD `4437614`),
avec attention particulière aux deux commits COORD les plus récents :

- `cba5263` fix(coord): demandes A-1, A-3(1), A-4, A-5.1, A-5.3 du lot A
- `4437614` feat(widgets): ChoiceCardGroup côte à côte, étape genre selon la maquette (A-5.2)

## Constats

1. **`PageEtape.onRetour` / `RangeeEtape.onRetour`** : passe de paramètre nommé requis à
   nommé optionnel (nullable). Tous les appelants existants (lot A, B, C, D, E) utilisent
   `onRetour:` nommé explicite → aucun site d'appel cassé. Vérifié par grep sur
   `lot-b`, `lot-c`, `lot-d`, `lot-e` : aucun appel positionnel, aucune régression.
2. **`OptionChoix.cle` et `ChoiceCardGroup.coteACote`** : deux paramètres additifs, tous
   deux facultatifs avec valeur par défaut (`cle` nul, `coteACote` faux). Le rendu par
   défaut (liste, sans côte à côte) est inchangé. Vérifié par grep des usages de
   `ChoiceCardGroup(` / `OptionChoix(` dans `lot-b/c/d/e` (dont des usages `const`) :
   aucun ne casse, `cle` étant un champ `Key?` additionnel accepté par un constructeur
   `const` existant.
3. **`redirection.dart`** : la racine `/` sans session mène maintenant à `/bienvenue`
   (demande A-1) au lieu de rester bloquée sur la connexion sans destination. Comportement
   isolé au routeur du lot A / COORD, testé dans `test/router/redirection_test.dart`
   (renforcé dans le même commit). Pas d'usage de cette fonction hors COORD trouvé dans
   les autres lots à l'exception des tests propres au lot A.
4. **Fichiers interdits** : aucun fichier de `supabase/`, `.github/`, `vercel.json`,
   `pubspec.yaml`, `assets/fonts`, `lib/core/theme`, `lib/core/coran`, `lib/core/tc_coran`,
   `lib/features/tc_mushaf`, `dart_define.json` touché sur tout le diff
   `origin/ui/tuteur-v1..HEAD` (vérifié par grep sur la liste complète des fichiers
   modifiés).
5. **Tests qui tapent le bouton** : les tests de capture et de geste ajoutés dans les
   commits récents (`test/widgets/page_etape_choix_test.dart`,
   `test/accessibilite/clavier_test.dart`, `test/router/redirection_test.dart`) tapent
   effectivement les boutons/cases concernés (ex. tape « Femme » sur la carte côte à
   côte, tape « Continuer » sous `hoteRoutant`) plutôt que de piloter l'état directement.
6. **LA-3 (consentements)** : aucun bouton n'existe dans le code du lot A menant à
   `Routes.tuteurCompteConsentements` — seule la page de consentements elle-même
   s'y référence (son propre `GoRouter.of(context).go(...)`). L'entrée depuis le Compte
   dépend de l'intégration du lot E (page Compte), hors périmètre du lot A. Conforme au
   motif déjà posé sur la ligne LA-3 du tableau.

Aucune régression trouvée. Aucune correction nécessaire au-delà de ce qui est déjà
commité par le lot A.

## Suite complète `flutter test`

Sous verrou (`flutter-verrou.ps1 -Dossier C:\RA\lot-a -Commande "flutter test"`) :

```
All tests passed!  (+2295 ~321, code 0)
```

Aucun échec, aucune régression détectée sur PageEtape / ChoiceCardGroup / OptionChoix
dans le reste de la suite (widgets, accessibilité, router, features, capture).

## Verdict

- LA-2 : déjà « fait » au tableau (session précédente), confirmé conforme par cette revue.
- LA-3 : reste « en_cours », motif inchangé (entrée Compte à l'intégration E ; texte
  signé à valider par le directeur, P2).
- LA-F : « fait ». Preuve : commit `4437614` (HEAD `ui/tuteur-v1-a`), suite `flutter test`
  intégrale verte (2295 passed, 0 failed), aucun fichier interdit touché, aucune
  régression PageEtape/ChoiceCardGroup/OptionChoix dans les autres lots.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
