# Passation Codex 2 (12/10/2026, après-midi)

Ce document s'adresse au **nouveau Codex 2**, qui remplace une session arrêtée. Lis-le en entier
avant de toucher au code. Il remplace `CODEX2_FILE_ATTENTE.md`, qui date du matin et est périmé.

## 1. Ton rôle

- **Qui tu es :** l'un des deux agents ChatGPT (Codex) du backend de Rewayah Academy : Supabase,
  migrations, fonctions Edge, adaptateurs `*_supabase.dart`. Les écrans sont faits par Claude.
- **Codex 1 :** l'autre agent. C'est lui qui intègre les lots confirmés dans
  `codex/backend-canon-fixes`. Tu ne fusionnes jamais dans cette branche.
- **Les vérificateurs :** des sessions Claude, qui rejouent chacun de tes lots sur PostgreSQL 17
  nu et rendent un verdict CONFIRMÉ ou CHANGES.
- **L'orchestrateur :** une autre session Claude, qui écrit tes consignes.

## 2. Où lire et où écrire

| Quoi | Où |
| :--- | :--- |
| Tes consignes et les verdicts | Feuille de liaison `1v3uuQD9jHgezbrmNlrKPOvGsRBCpxYXkN_KIq5N72WA`, onglet **Codex2**. Lignes `SUITE-ORCH` (orchestrateur) et `REJEU` (verdicts) |
| Ta réponse à chaque lot | Une ligne dans l'onglet Codex2 : titre, date, `Codex 2`, branche @ SHA complet, contenu, autocontrôle, réserves |
| Si la feuille est illisible | Une section « Réponse Codex 2 » en bas d'un fichier `docs/orchestration/CODEX2_REPONSE.md`, sur une branche `codex2/reponse-<date>`, poussée sans force |
| Les décisions du directeur | `docs/current/` sur `ccr-1b1bfa0b-m1kvkk`, à commencer par `00_LIRE_D_ABORD.md` et `docs/orchestration/COHABITATION.md` |

**Règle d'écriture dans la feuille :** juste avant d'écrire, relis la colonne A et écris sur la
première ligne vide **après la dernière ligne pleine**. N'écris jamais par-dessus une ligne
existante, ni dans un trou entre deux lignes pleines. Des lignes ont été écrasées le 12/10.

## 3. Règles (ne se discutent pas)

1. **Interdits :** pas de push sur `main`, pas de push forcé, pas de STAGING ni de PROD, pas de
   clé `service_role`. Ne modifie jamais `.github/` ni `lib/main.dart`.
2. **Branches :** une branche par lot, `codex2/<lot>`, partant de la **dernière**
   `codex/backend-canon-fixes`. Push normal, puis `git ls-remote` pour confirmer le SHA.
3. **Migrations :** horodatage unique à la seconde, **secondes impaires** pour toi (Codex 1 a les
   paires). Aucune nouvelle numérotation `00xx`. Ne modifie jamais une migration déjà intégrée :
   corrige par une nouvelle migration.
4. **Heures :** le serveur stocke en UTC avec le fuseau IANA du foyer. L'adaptateur convertit en
   heure murale. Les ports Dart de `lib/core/capacites` restent en heure murale et font foi.
5. **Sécurité (F86) :** toute nouvelle fonction est `SECURITY INVOKER` par défaut. Une fonction
   `DEFINER` a un `search_path` vide et son `md5(pg_get_functiondef)` est relevé dans ta ligne.
   `anon` et `service_role` n'ont jamais EXECUTE. Chaque garde a un scénario de refus, et retirer la
   garde doit faire échouer ce scénario (mutant).
6. **Rejeu :** la référence est PostgreSQL 17 nu, dans cet ordre : `supabase/tests/stub_auth.sql`,
   puis toutes les migrations dans l'ordre glob, puis chaque `scenarios_*.sql` dans une base neuve.
   Si ton PostgreSQL local bloque (mot de passe, rôles), ne t'arrête pas : dis-le en une phrase dans
   ta ligne et pousse quand même. Le vérificateur rejoue en PG17.
7. **Données réelles :** aucune donnée personnelle réelle dans Git, dans la feuille ou dans un
   test. Tous les tests utilisent des personnes inventées.
8. **Ne t'arrête jamais de toi-même :** après chaque lot poussé et inscrit, relis les nouvelles
   lignes de l'onglet Codex2. Un CHANGES sur un de tes lots passe avant tout. Sinon, avance dans la
   file. Si la file est vide, attends 10 minutes (`sleep 600`), relis, et recommence.

## 4. Avant de commencer : l'état laissé par l'ancienne session

L'ancienne session a peut-être laissé du travail non poussé sur le disque `D:`, dans
`D:/RA _APP/rewayah-rech-back-*` ou d'autres dossiers `rewayah-*`. Dans chaque dossier, lance
`git status --short` et `git log --branches --not --remotes --oneline`.

- **S'il y a des changements :** ne les efface pas. Lis-les. S'ils correspondent au point 1 de la
  file (RECH-BACK-2), reprends-les. Sinon, mets-les de côté avec `git stash push -m
  "ancienne-session-codex2"`, et signale-le dans ta première ligne.
- **N'utilise jamais** `git reset --hard`, `git clean -fdx` ni un push forcé.

### Ce qui est fait (sur le serveur Git, `origin`)

| Lot | Branche @ SHA | État |
| :--- | :--- | :--- |
| RECH-BACK-1 | `codex2/rech-back-1` @ `175eda7c` | CONFIRMÉ. Le hook de jeton a un nouveau md5 (`fc825b4f…`). |
| RECH-BACK-4 | `codex2/rech-back-4` @ `94e7df11` | CONFIRMÉ |
| RECH-BACK-5 | `codex2/rech-back-5` @ `cf698ae3` | CONFIRMÉ |
| X2-17 | `codex2/x2-17` @ `6873b372` | CONFIRMÉ, en attente d'intégration par Codex 1 |
| X2-15, X2-16 | `codex2/x2-15` @ `7156440b`, `codex2/x2-16` @ `ba480361` | CONFIRMÉS, en attente d'intégration par Codex 1 |
| X2-20, cahier admin, X2-22 | — | CONFIRMÉS et intégrés dans canon-fixes |
| RECH-BACK-2 | `codex2/rech-back-2` @ `1724ad43` | **CHANGES** (Codex2 A196), point 1 ci-dessous |
| RECH-BACK-6 (cumul) | `codex2/rech-back-6` @ `27cdd4c8` | **CHANGES**, seulement à cause de RECH-BACK-2 |

N'y touche plus, sauf RECH-BACK-2 et RECH-BACK-6.

## 5. Ta file, dans l'ordre

### 1. RECH-BACK-2 : recherche de classes et supports (Codex2 A196, consigne A199)

- **Droits :** avec les droits Supabase par défaut, `library_resource`, `resource_version` et
  `library_resource_groupe` gardent un droit de table pour `authenticated`. L'assertion
  « projection privileges » ne doit pas dépendre de l'environnement : teste plutôt qu'un appelant ne
  lit aucune colonne privée à travers la fonction.
- **Performance :** le p95 est de 246 à 311 ms sur 10 000 lignes, en Seq Scan sous RLS. Le même
  SELECT en superutilisateur prend 0,47 ms avec l'index trigramme. Fais d'abord filtrer par l'index
  (sous-requête ou CTE sur les seules colonnes indexées, avec LIMIT), puis applique la visibilité
  aux candidats. Autre solution : une fonction `DEFINER` à `search_path` vide, avec un filtre de
  visibilité explicite et son md5 relevé. **Cible : p95 inférieur à 50 ms sur 10 000 lignes**, mesure
  écrite dans ta ligne.
- **Quota de curseurs :** ajoute un test du quota (le mutant qui le retire survit aujourd'hui).
- Repousse `codex2/rech-back-2`, puis refusionne-le dans `codex2/rech-back-6` et repousse.

### 2. IMM-BACK-1 : matricule `RA-26-4817`

- **La décision fait foi :** lis en entier `docs/current/DECISION-IMMATRICULATION-2026-10-12.md` sur
  `ccr-1b1bfa0b-m1kvkk`. Elle remplace le **format** du complément du 07/10
  (`docs/orchestration/handoff/2026-10-09/REWAYAH_COMPLEMENT_IMMATRICULATION_IDENTITES_V0_1.md`),
  dont le reste s'applique (registre, atomicité, critères IMM-01 à IMM-14).
- **Branche :** `codex2/imm-back-1`.
- **Le matricule :** registre `person_registrations`. Le matricule `RA-AA-NNNN` se compose de `RA`, de
  l'année sur 2 chiffres et d'un nombre **tiré au hasard** de 4 chiffres (5 au-delà de 4 500
  matricules dans l'année). Nouveau tirage sur conflit d'unicité seulement. Il est attribué dans la
  même transaction, dans **tous** les parcours de création (inscription, enfant, personnel, import).
  Le rôle n'est pas dans le code. Le code est immuable et jamais réattribué.
- **L'ancien générateur :** retire le générateur par initiales `next_immutable_id`. La colonne
  `profiles.immutable_id` reçoit le matricule. Les anciens codes ne sont pas repris.
- **Lecture :** lecture et recherche exacte sous autorisation, avec une saisie tolérante (casse,
  tirets, espaces) ramenée à la forme canonique.
- **Scénarios :** IMM-01 à 05, 09, 11, 12 et 14, avec leurs mutants : collision forcée, deux
  attributions concurrentes, renommage et changement de rôle sans changement de code, A ne lit pas
  le code de B.
- **Contrat :** écris le contrat du port pour Claude dans l'onglet **Contrats**.

### 3. RECH-BACK-3 : recherche des familles et élèves par matricule exact (D2)

Elle s'appuie sur le registre d'IMM-BACK-1 et doit être non énumérable, avec des quotas. La spec de
recherche est sur `docs/specs-entrantes-2026-10-10@db050205`, fichier
`docs/entrants/2026-10-10/rech/REWAYAH_RECH_03_SPEC_CANONIQUE_FRONT_BACK_SECURITE_PERFORMANCE_V3.md`,
§7.2 et §15.

### 4. IMM-ACCUEIL-BACK : import automatique des inscrits actuels (décision §5, Codex2 A201)

- **L'import :** une RPC réservée à un administrateur actif, sans `service_role`. Elle reçoit le CSV
  **brut** des formulaires Google et fait tout côté serveur. Les en-têtes exacts sont dans Codex2
  A201. Repère les colonnes par leur nom, jamais par leur position.
- **Le traitement :** regroupement par e-mail du tuteur ou de l'adulte, dates au format
  JJ/MM/AAAA, rejets rapportés avec leur motif.
- **Essai et confirmation :** un essai à blanc sans écriture, puis une confirmation idempotente
  (clé stable par personne), avec audit.
- **Les mots d'accueil :** les mots de bienvenue et de patience sont remplis avec les prénoms, et
  chaque foyer a un drapeau « a patienté ».
- **Le rattachement :** il se fait seulement **après la preuve de l'e-mail**. Rien n'est révélé
  avant.
- **Tests :** uniquement sur des CSV inventés, avec les mêmes en-têtes.

### 5. IMM-BACK-2 : codes d'évaluation `EV-NNNN`

Le format est au §4 de la décision : des chiffres au hasard, uniques dans l'évaluation. La
politique de publication est au §5 du complément du 07/10. Critères IMM-06 à 08 et IMM-13.

## 6. Ta première ligne dans l'onglet Codex2

Écris d'abord une ligne `PRISE DE RELAIS Codex 2`. Elle donne l'état du disque trouvé (§4), confirme
que tu as lu ce document et les lignes A199 et A201, et annonce que tu commences par RECH-BACK-2.
