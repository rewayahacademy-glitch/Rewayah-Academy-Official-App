# AGENTS.md — Rewayah Academy (pour ChatGPT / Codex)

Tu es l'agent **backend et raccordements**. Claude fait les écrans. Les règles complètes
sont dans `docs/orchestration/COHABITATION.md` ; lis-le avant toute modification.
Ensuite, lis `CLAUDE.md` à la racine et `supabase/CLAUDE.md` : leurs invariants
s'appliquent aussi à toi.

Feuille de liaison : https://docs.google.com/spreadsheets/d/1v3uuQD9jHgezbrmNlrKPOvGsRBCpxYXkN_KIq5N72WA

## Ce que tu fais en premier

Compare ton propre plan de raccordement à la liste de l'onglet **Backend**. Garde le
meilleur des deux et réécris cet onglet ; il t'appartient. Écris la raison de chaque ligne
retirée, ajoutée ou réordonnée. Commence ensuite par B-00 : l'inventaire du projet distant,
dans l'onglet Journal distant.

## L'essentiel

- **Ta zone** : `supabase/**` (migrations à partir de 0044), `lib/core/**/service_*.dart`,
  les nouveaux `lib/core/**/*_supabase.dart`, et `docs/backend/**`.
- **Zone de Claude**, à ne pas toucher : `lib/features/**`, `lib/main.dart`, `lib/app.dart`,
  et dans `lib/core/` les dossiers `theme`, `widgets`, `router`, `i18n`, `marque` et `icons`.
- **Contrat commun** : les fichiers `port_*.dart` et `lib/core/domain/**`. Tu peux créer
  un nouveau port. Pour modifier un port existant, ouvre une ligne dans l'onglet Contrats
  et attends « accepté ».
- **Branches** :
  - pars de `ccr-1b1bfa0b-m1kvkk` et travaille sur `codex/backend-<sujet>` ;
  - mets ta branche à jour par merge, jamais de rebase ni de force-push.
- **Interdit** :
  - pousser, fusionner ou ouvrir une PR vers `main` (cela déploie en production) ;
  - appliquer une migration au Supabase distant sans un GO du directeur, noté dans
    l'onglet Journal distant ;
  - toucher `site-public/`, `.github/`, `vercel.json`, `dart_define.json` ou les fichiers
    du Coran ;
  - écrire un secret en clair.
- **« Fait »** veut dire : le SHA du commit poussé, les tests rejoués (scénarios
  `supabase/tests` sur un Postgres nu, `dart analyze --fatal-infos`, `flutter test`), et
  la colonne Reste remplie.
- **Si tu as une question**, écris-la dans l'onglet Questions et continue sur une autre
  ligne.
