# Cohabitation Claude ↔ ChatGPT (Codex)

Décision du directeur, 09/10/2026 : **ChatGPT (Codex) fait le backend et les raccordements,
Claude fait les écrans.** Quand le frontend est fini, Claude relit le backend et, pour chaque
ligne, le confirme, le corrige ou le renvoie avec ses écarts. Ce fichier fixe les frontières
pour que les deux travaux se complètent sans jamais se contredire. Il fait foi sur la feuille
de liaison en cas d'écart.

Feuille de liaison (Google Sheets) : « Rewayah · Liaison Claude ChatGPT »,
https://docs.google.com/spreadsheets/d/1v3uuQD9jHgezbrmNlrKPOvGsRBCpxYXkN_KIq5N72WA

| Onglet | Tenu par | Rôle |
| :--- | :--- | :--- |
| Règles | Claude | Version courte de ce fichier |
| Backend | ChatGPT | Sa liste de travail : statut, branche, preuve, reste ; colonne « Revue Claude » |
| Contrats | les deux | Toute demande de changement sur un fichier de l'autre ou sur un port existant |
| Questions | les deux | Questions entre agents ; on n'attend pas la réponse pour avancer ailleurs |
| Journal distant | ChatGPT | Tout ce qui est appliqué ou réglé sur le projet Supabase distant |

## 1. Premier travail de ChatGPT : fusionner les plans

L'onglet Backend contient une proposition de Claude, tirée du code de cette branche (52 ports
recensés, une vingtaine sans adaptateur réel). ChatGPT a déjà écrit son propre plan de
raccordement à partir du tableau de suivi et de l'état réel du code sur GitHub.

Il compare les deux plans, garde le meilleur de chacun et réécrit l'onglet Backend, dont il
est propriétaire. Pour chaque ligne retirée, ajoutée ou réordonnée, il écrit la raison dans
la colonne Reste. Claude ne rétablit pas son ancienne liste.

## 2. Zones

| Zone | Propriétaire | Fichiers |
| :--- | :--- | :--- |
| Backend | ChatGPT | `supabase/**` (migrations **à partir de 0044**, fonctions Edge, tests, seed, `config.toml`), `lib/core/**/service_*.dart`, nouveaux adaptateurs `lib/core/**/*_supabase.dart`, `docs/backend/**` |
| Frontend | Claude | `lib/features/**`, `lib/app.dart`, `lib/main.dart`, `lib/core/{theme,widgets,router,i18n,marque,icons}`, adaptateurs de démonstration, tests des écrans |
| Contrat commun | les deux, par l'onglet Contrats | `lib/core/**/port_*.dart`, `lib/core/domain/**` |

- **Créer** un nouveau port est libre pour ChatGPT. **Modifier** un port existant passe
  par une ligne Contrats, et seulement après « accepté » de l'autre côté.
- Contrat C-01, déjà accepté : ChatGPT peut sortir les classes `Port*` déclarées dans
  `lib/features/foyer/` et `lib/features/controleur/` vers `lib/core/foyer/` et
  `lib/core/controle/`, en laissant un `export` dans le fichier d'origine. Il ne touche
  rien d'autre dans ces fichiers.
- **Branchement final** : ChatGPT ne décide pas quel adaptateur l'app utilise (démo ou
  réel). Claude fait ce branchement dans `lib/main.dart` et les écrans, après la relecture.
- Les agents de Claude ne créent ni ne modifient aucune migration et ne touchent pas à
  `supabase/` (consigne K-19 du tableau). La numérotation des migrations est donc tenue
  par ChatGPT seul, ce qui supprime le risque de collision de numéros.

## 3. Branches

- ChatGPT part de la branche d'intégration `ccr-1b1bfa0b-m1kvkk`, pas de `main`, parce
  que les ports écrits pour les écrans n'existent que sur celle-ci. Ses branches
  s'appellent `codex/backend-<sujet>`.
- Il met sa branche à jour en fusionnant `ccr-1b1bfa0b-m1kvkk` dedans : jamais de
  rebase, jamais de force-push.
- Claude fusionne les branches `codex/backend-*` dans l'intégration. Les zones ne se
  recouvrent pas, donc ces fusions ne devraient pas créer de conflit. Si un conflit
  apparaît, il signale une sortie de zone et va dans Questions.

## 4. Production et projet distant

- **Jamais de push ni de fusion vers `main`** : pousser sur `main` déploie en production
  (`flutter-deploy.yml`). Pas de PR vers `main` sans GO du directeur.
- Écrire une migration dans le dépôt est libre. **L'appliquer au projet Supabase distant
  demande un GO du directeur**, noté dans l'onglet Journal distant.
- Tout ce qui a déjà été appliqué ou réglé à la main sur le projet distant est inscrit
  dans le Journal distant, avec le fichier du dépôt correspondant. C'est la ligne B-00
  (inventaire). Une différence entre la base distante et `supabase/migrations` est un écart
  à corriger par une migration additive, jamais par la modification d'une migration
  déjà appliquée.
- Avant toute écriture par MCP, vérifier `get_project_url` (le MCP a déjà visé un autre
  projet, `supabase/CLAUDE.md`).

## 5. Interdits pour les deux

`site-public/`, les écrans publics avant connexion, `lib/features/parcours_offres`,
`codex/site-public-preview-main`, `.github/`, `vercel.json`, `flutter-deploy.yml`,
`dart_define.json`, les fichiers du Coran, les valeurs des jetons de `lib/core/theme`, et
tout secret en clair. Une dépendance ajoutée à `pubspec.yaml` passe par une ligne
Contrats ; le directeur tranche.

## 6. Règles de sécurité du backend

Celles de `supabase/CLAUDE.md`, sans exception :
- RLS sur toutes les tables ;
- toute fonction `SECURITY DEFINER` fixe `search_path = ''` ;
- les gardes s'écrivent en exigence positive ;
- `revoke` de `public` **et** de `anon` ;
- le rôle et le foyer se lisent depuis le JWT ;
- l'argent est un entier en unité mineure, calculé côté serveur ;
- `audit_logs` est append-only ;
- les migrations sont additives.

Côté Flutter : aucun secret, aucun calcul financier de référence.

## 7. Preuve et statuts

Une ligne Backend passe à `fait` seulement avec :
- le SHA du commit poussé ;
- les vérifications rejouées :
  - `supabase/tests/stub_auth.sql`, puis les migrations, puis
    `supabase/tests/scenarios_*.sql` sur un Postgres nu ;
  - `dart analyze --fatal-infos` ;
  - `flutter test` sur les fichiers touchés ;
- ce qui reste, écrit dans la colonne Reste.

Statuts : `a_faire`, `en_cours`, `fait`, `bloque`. Revue Claude : `à revoir`, `confirmé`,
`corrigé`, `renvoyé`.

## 8. Relecture finale par Claude

Quand le frontend est fini, l'étape **REVUE-BACKEND-CODEX** du tableau de suivi relit chaque
ligne `fait` :
1. contre-épreuve des tests ;
2. lecture des policies et des RPC contre `02_ARCHITECTURE_ET_SECURITE.md` ;
3. vérification que l'adaptateur respecte le port.

Ensuite, Claude branche les adaptateurs réels dans l'app. Un écart mineur est corrigé
directement. Un écart de conception est renvoyé à ChatGPT avec sa raison, dans Questions.
