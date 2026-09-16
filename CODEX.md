# Rewayah Academy — Codex

Agent d'assistance au perfectionnement de l'app. Tu assistes Claude Code :
tu explores, proposes, vérifies — tu ne remplaces pas.

## Prescription de lecture (docs specs)

1. `docs/HANDOFF.md` — à lire **en premier**, avant toute action. Où la
   session s'est arrêtée, quel lot reprendre.
2. `docs/PROGRESS.md` — où en est le projet (section « DÉMARRER ICI »).
3. `docs/architecture/decisions.md` — le registre ADR (questions tranchées).
4. La table complète de routage des docs est dans `CLAUDE.md` — applique-la.

## Non négociables

- Toute config une fois faite est codée dans le dépôt. Tu ne reconfigures rien
  au fil de l'eau.
- **Aucun écran ne s'implémente s'il n'est pas inscrit dans
  `docs/design/08-catalogue-ecrans.md`.**
- Aucune couleur, police, rayon, ombre ou valeur d'espacement inventée : tout
  vient de `docs/produit/design-tokens.md`
  (`tool/verifier_jetons.dart` et l'ADR-019 le vérifient).
- Un widget lit une **capacité**, jamais un rôle.
- Un écran n'est fini qu'avec ses états loading / content / empty / error /
  offline.
- Français dans la doc, code et messages en français aussi.

## Vérification avant de dire que c'est fait

```
dart run slang
dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos
flutter test
dart run tool/verifier_jetons.dart
```

Côté base, sur un Postgres nu (voir `docs/HANDOFF.md` pour le conteneur) :
rejouer `supabase/tests/stub_auth.sql`, les migrations `0001`→`0005+`, puis
`scenarios_etape3.sql` / `scenarios_etape4.sql`. Un contrôle qui n'a jamais
tourné n'est pas un contrôle vert.

## Travail partagé avec Claude Code

Claude Code est actif sur ce même dépôt. Règles :

- `git status` et `git diff` avant TOUT commit ; ne committe que ce qui est à
  toi, avec `git hash-object -w` + `git update-index --cacheinfo` si le fichier
  est partagé.
- Ne modifie pas `CLAUDE.md`, `docs/HANDOFF.md`, `docs/PROGRESS.md` en cours de
  session sans accord explicite.
- Ne touche pas `~/.claude/`. Un `flutter build web --release` ne se lance
  JAMAIS nu : uniquement `--dart-define-from-file=dart_define.json` depuis
  `D:\ra-pwa-build`.
- Avant toute écriture SQL en prod : `get_project_url` (le MCP a déjà visé le
  mauvais projet).