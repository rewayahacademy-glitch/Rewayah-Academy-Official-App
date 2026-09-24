# Brief commun - chantier frontend Tuteur V1 (Rewayah)

Date : 24/09/2026. Coordinateur : session Claude Code principale.

## Chemins
- Dépôt Flutter : `D:\RA _APP\RA -OFFICIAL-APP` (checkout actuel : branche `c0/configuration-baseline-2026-09-23`, PR #2 brouillon, NE PAS changer de branche dans ce checkout, NE RIEN y committer).
- Mandat du directeur (source de vérité du lot) : `D:\RA _APP\docs de lancement\REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` (deux parties : prompt principal + « Prompt étape observation tuteur » qui corrige et complète).
- Maquettes : `D:\RA _APP\docs de lancement\tutuor image\` (+ sous-dossier `mobile\`).
- Docs de lancement (copie directeur des specs) : `D:\RA _APP\docs de lancement\0x_*.md` ; specs canoniques du dépôt : `D:\RA _APP\RA -OFFICIAL-APP\docs\current\`.
- Règles du dépôt à lire AVANT toute analyse : `D:\RA _APP\RA -OFFICIAL-APP\CLAUDE.md`, `D:\RA _APP\RA -OFFICIAL-APP\lib\CLAUDE.md`, `docs/current/00_LIRE_D_ABORD.md`, `docs/current/08_...` §5 bis.
- Dossier de pilotage (sorties des agents) : `D:\RA _APP\pilotage-tuteur-v1\`.

## Faits déjà établis par le coordinateur
- Machine : 4 cœurs, 7,9 Go RAM, ~1 Go libre. Ne lancez JAMAIS plusieurs commandes Flutter lourdes en parallèle ; préférez `dart analyze <chemins>` ciblé et `flutter test <fichier>` ciblé.
- Flutter : `C:\flutter\bin\flutter.bat`. Réseau disponible.
- Polices actuelles : `InstrumentSans` (corps) et `BricolageGrotesque` (titres) + arabe (`NotoSansArabic`, `UthmanTahaNaskh`) + Phosphor. **Aucune trace de « Jakarta » ni de « DM Sans »** dans le dépôt ni sur aucune branche locale, contrairement à ce qu'affirme le mandat (« Jakarta est déjà déclarée »). Contradiction à consigner.
- i18n : slang, un seul fichier `assets/i18n/fr.i18n.json` (113 Ko), `flat_map`, interpolation `{x}`, pas de namespaces.
- Un seul routeur `lib/core/router/app_router.dart` (820 lignes), `routes.dart`, `redirection.dart`, `ecran_a_construire.dart`.
- Branches notables non fusionnées : `observation/lot-2026-09-21` (11 commits hors `main`, dont migrations 0039-0042 appliquées en production et UI d'observation), `v0/verite-produit` (commit `33503fe`, groupes réels au lieu du double de démo), `codex/r1-adaptive-design-system`, `codex/r2-adaptive-shell`, `core24/fable-frontend` (CORE24 déclaré NON CONFORME : ne jamais intégrer), `teaching-core/*`.
- `main` = `origin/main` ; la branche C0 a 9 commits d'avance sur `main` (docs + CI), 0 de retard.
- Pousser sur `main` = mise en production. Interdits absolus : push, merge main, déploiement, migration, modification backend (supabase/), suppression de branche/worktree.

## Rôle Tuteur - navigation cible
Accueil · Foyer · Historique · Compte (même ordre partout). Maquette mobile high-fi montre 3 onglets (Accueil, Foyer, Compte) ; maquette desktop montre 4 (Accueil, Foyer, Historique, Compte).

## Règles de preuve
Distinguer : « UI réalisée », « branchée au service existant », « testée en simulation », « vérifiée réellement », « dépendance backend ». Ne jamais inventer un PASS. Citer fichier:ligne.
