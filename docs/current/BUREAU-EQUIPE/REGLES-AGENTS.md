# Règles imposées à chaque agent du Bureau de l'équipe

Un agent qui enfreint une règle voit sa PR refusée. En cas de doute : s'arrêter et écrire
au coordinateur (la session qui t'a lancé) par `send_message`, en trois lignes.

## A. Ce que tu lis, dans cet ordre, et rien d'autre

1. `CLAUDE.md` : seulement « Vérité d'abord », « Invariants » et « Vérifier avant de dire que c'est fait ».
2. `docs/current/DECISION-QUATRE-AGENTS-2026-11-02.md`, §3 en entier : ces règles s'appliquent toutes (Z, B, T, L, G).
3. Ton cahier `docs/current/BUREAU-EQUIPE/CAHIER-<lot>.md`.
4. Les fichiers nommés dans ton cahier. Pas les archives, pas les autres cahiers.
5. Avant tout texte visible : la compétence `mots-rewayah`. Avant toute liste : `DECISION-LISTES`
   et `DECISION-DEFILEMENT`. Avant tout geste : `DECISION-FLUIDITE`.

## B. Ta zone

- B1. Tu n'écris que dans les dossiers de ton cahier. Un fichier hors zone : tu t'arrêtes et tu demandes.
- B2. Tu ne touches jamais : `lib/core/widgets/fil_discussion.dart`, `lib/features/com_messages`,
  `lib/features/com_studio` (un autre agent refait la messagerie), `.github/`, `pubspec.yaml`,
  `.claude/`.
- B3. `app_router.dart`, `assets/i18n/*.json`, `lib/main.dart` : par ajout seulement, clés sous
  le préfixe de ton lot.
- B4. Une branche, une PR brouillon vers `main`. Tu ne fusionnes pas, tu n'installes aucune
  migration, tu n'écris rien en production. Lire la production est permis.

## C. Comment tu travailles

- C1. **Chercher avant d'écrire.** Ton bilan nomme ce que tu as réutilisé. Aucun composant
  neuf si un composant de `lib/core/widgets` fait la chose.
- C2. **Rien de plus que le cahier.** Pas de refonte voisine, pas de renommage, pas de
  `dart format` hors des fichiers touchés. Une idée hors cahier s'écrit dans le bilan, elle
  ne se code pas.
- C3. **Rien de moins.** Chaque ligne « À faire » du cahier est faite, ou nommée « non faite »
  avec sa raison, en tête du bilan.
- C4. **Aucun bouton qui fait semblant.** Un geste sans serveur ne s'affiche pas.
- C5. **Les cinq états** de tout écran touché : chargement, contenu, vide, erreur, hors connexion.
- C6. **Téléphone d'abord** (largeur 360), puis ordinateur (1366), puis arabe (droite à gauche).
  Captures des trois dans `docs/current/captures/E2E/<lot>/`.
- C7. **Tests** : un test par ligne « À faire », plus les cas de refus. Suite complète avant la PR
  (`flutter test --no-pub`), `dart analyze --fatal-infos`, `verifier_jetons`, `verifier_branchement`.
- C8. **SQL** : additif ; fonction existante retouchée par ancre ; aucun `DROP`, `DELETE`,
  `TRUNCATE` ; numéros de migration dans la plage du cahier ; scénario joué en `authenticated`.
- C9. **Vérité d'abord** : la description de PR et le bilan commencent par ce qui est faux,
  bloqué ou non prouvé. « Testé localement » n'est pas « fait ».
- C10. **À la fin** : mettre à jour ta ligne dans `SUIVI.md` (statut `PR ouverte`, numéro),
  puis rendre compte au coordinateur : ce qui est faux ou non fait, le numéro de PR, les
  migrations à installer, ce que tu as réutilisé.
