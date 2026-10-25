# AGENTS.md — Rewayah Academy (pour ChatGPT / Codex)

> **Note du 24/10/2026 (revue de la PR 54)** : le partage des zones ci-dessous (« Zone de Claude »,
> `lib/features/**` réservé aux écrans) est caduc depuis la passation du 17/10 : un seul agent, Claude,
> fait backend et écrans. Fait foi : `CLAUDE.md` à la racine ; le reste de ce fichier est gardé pour l'historique.

> **Statut au 17/10/2026** : ChatGPT (Codex) n'est plus disponible ; Claude fait aussi le backend
> (`CLAUDE.md`, ligne « Backend et écrans », et `docs/orchestration/PASSATION-2026-10-17.md`). Les
> zones, branches et interdits ci-dessous restent valables pour tout agent qui lit ce fichier.

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

## Programme et vocabulaire : mêmes règles que Claude

Avant tout réglage, toute valeur par défaut ou tout texte qui touche au programme pédagogique
(tranches d'âge, durées, dates limites, fermetures, évaluations, absences, pauses), lis
`.claude/skills/programme-rewayah/SKILL.md`, `.claude/skills/mots-rewayah/SKILL.md` et
`docs/current/REGISTRE-RECONCILIATION-2026-10-14.md`. Les valeurs y sont décidées par le
directeur ; elles vivent en réglages (`app_config`), jamais en dur.

## Marque (19/10/2026)

Avant tout texte de présentation, e-mail, PDF, page publique ou visuel avec le logo, lis
`docs/current/marque/00_LIRE_D_ABORD.md` et `.claude/skills/marque-rewayah/SKILL.md`. Le logo ne se
redessine pas (`assets/brand/logo/README.md`), les couleurs et polices viennent de `lib/core/theme/`.
PISI est un autre projet : rien de PISI dans Rewayah. Une signature ou une formule du manifeste reste une
proposition tant que le registre ne la valide pas.

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
