# Mesures sur HEAD ff01c087

Date des mesures : 15 octobre 2026.
Dépôt : /home/user/Rewayah-Academy-Official-App. Lecture seule : aucune modification du dépôt, aucun push, aucune base distante, aucun workflow déclenché. Les travaux ont été faits dans une copie (archive de HEAD) placée dans le scratchpad de la session.

## Précision sur le SHA

La mission annonçait le SHA 4a7aa2b. HEAD est ff01c087 (« docs(audit): six registres de conformité de l'audit d'harmonisation »), et 4a7aa2be en est le parent. Le diff hors `docs/` entre 4a7aa2be et HEAD est vide : le code mesuré est identique pour les deux SHA. Toutes les mesures portent sur l'archive de ff01c087. Le commit ff01c087 ne contient que six fichiers `docs/audit-harmonisation/*.md` (2767 insertions).

Copie de travail : /tmp/claude-0/-home-user-Rewayah-Academy-Official-App/3f325e52-cb58-51c1-b88e-226e6d67e5dc/scratchpad/copie. Un dépôt git jetable y a été ajouté pour reproduire le contrôle de divergence du code généré (`git status --porcelain`). Les journaux bruts sont dans le dossier `sql-logs` du même scratchpad.

## 1 Outillage disponible

| Outil | État constaté | Version | Remarque |
|---|---|---|---|
| flutter | absent du poste | 3.47.7 stable, installé dans le scratchpad | Archive officielle téléchargée depuis storage.googleapis.com |
| dart | fourni par le SDK | 3.13.5 | Révision du framework abaf9c52 |
| docker | binaire présent, démon KO (`docker info` échoue) | inconnue | Non utilisé |
| psql (client) | présent | 16.15 | Installé par le paquet Ubuntu |
| PostgreSQL serveur | absent au départ, installé via apt | 16.15 (Ubuntu) | Cluster 16/main démarré en local |
| PostgreSQL 17 | absent d'apt, dépôt PGDG injoignable (HTTP 000) | non disponible | Le CI utilise postgres:17-alpine |
| git | présent | 2.43.0 | |
| Proxy de l'agent | actif, aucun échec relayé au moment des mesures | | TLS non désactivé, HTTPS_PROXY non modifié |

Version de Flutter utilisée par le CI : `.github/workflows/ci.yml`, job `flutter`, emploie `subosito/flutter-action@v2` avec `channel: stable`, sans version épinglée. Le CI ne fixe donc pas de version, contrairement à ce que dit la mission. La version mesurée (3.47.7) est celle que le canal stable fournit à la date du 15 octobre 2026. Un run CI à une autre date peut utiliser une autre version.

## 2 Mesures exécutées

### 2.1 Vérifications Flutter (dans la copie, Linux)

| # | Commande | Résultat brut | Limite |
|---|---|---|---|
| F1 | `flutter pub get` | rc 0, « Got dependencies! ». 75 paquets ont des versions plus récentes incompatibles avec les contraintes (information seulement) | |
| F2 | `dart run slang` | rc 0, « Translations generated successfully » | |
| F3 | `dart run build_runner build --delete-conflicting-outputs` | rc 0, 1048 sorties en 80 s | |
| F3b | `git status --porcelain` après F2 et F3 | 0 fichier modifié : le code généré versionné correspond aux sources | Contrôle équivalent à celui du CI, sur la copie |
| F4 | `dart analyze --fatal-infos` | rc 0, « No issues found! » | |
| F5 | `flutter test --reporter expanded` | rc 0, « All tests passed! », dernière ligne `+1762`, durée d'environ 3 min, 0 échec | Linux seulement. Le CI exécute aussi la matrice web, apk et windows, non mesurée |
| F6 | `dart run tool/verifier_jetons.dart` | rc 0, « Jetons verifies : 342 fichiers, aucune violation » | Voir l'écart E3 : le vérificateur exclut `features/_dev/` |
| F6b | même vérificateur, copie modifiée pour ne plus exclure `features/_dev/` (fichier `tool/verifier_sans_exclusion_dev.dart` créé dans la copie seulement) | rc 1, 20 violations : 16 dans `lib/features/_dev/galerie/catalogue_galerie.dart` (règle `pression-forcee-hors-galerie`), 2 dans `galerie_page.dart` et 1 dans `compte_galerie.dart` (règle `page-sans-coquille`), 1 dans `lib/features/_dev/playground/playground_racine.dart` ligne 105 (règle `page-sans-coquille`) | Mesure hors du dépôt. Je ne sais pas à quelle date l'exclusion a été introduite |

Chiffres annoncés dans le dépôt, comparés aux mesures :
- `flutter test` : 729 tests (HANDOFF, session ancienne), et 684/691 avec 7 échecs (`docs/HANDOFF.md` ligne 42). Mesuré : 1762 tests, 0 échec. Ces chiffres annoncés sont périmés, ou ne concernent pas le même périmètre.
- `verifier_jetons` : 11 violations (HANDOFF ligne 47), 10 (ligne 291), 6 (lignes 2490 et 3073). Mesuré : 0 violation avec l'exclusion en vigueur, 20 sans elle.

### 2.2 Base de données (PostgreSQL 16.15 local, base neuve à chaque run)

Le stub d'authentification `supabase/tests/stub_auth.sql` est exécuté tel quel. Les migrations sont lues par ordre de glob (ordre lexicographique), comme le CI.

| # | Protocole | Résultat | Limite |
|---|---|---|---|
| B1 | Rejeu fidèle au CI : `ON_ERROR_STOP=1`, arrêt au premier échec, comme le step bash du job `migrate-check` | `stub_auth.sql` rc 0. Migrations 0001 à 0029 rc 0 (29 fichiers). **0030_tc_socle.sql rc 3** : `relation "storage.buckets" does not exist`. Le CI s'arrête là : le job `migrate-check` échoue à HEAD | Le schéma `storage` vient de Supabase et n'existe pas dans le stub commun. Le même échec est attendu sous Postgres 17, mais je ne l'ai pas vérifié sous 17 |
| B2 | Rejeu complet sans arrêt, stub CI tel quel | Échecs en cascade après 0030 : 0032_tc_catalogue (`schema "storage" does not exist`), puis plusieurs scénarios. Ce run n'est pas représentatif, car des migrations ont été appliquées après un échec | Utilisé seulement pour constater la cascade |
| B3 | Expérience : stub CI, plus un stub `storage` minimal (tables `buckets` et `objects`, fonction `foldername`, RLS, grants), fichier `stub_exp_combined.sql` hors dépôt. Sans arrêt au premier échec, base neuve | Stub rc 0. **42 migrations rc 0**, y compris 0035, 0036 et 0037. **8 scénarios sur 12 rc 0** : etape5, adm05, n2, n4, n5, hook_jeton, r2, adm04. **4 scénarios en échec** (voir B4) | Le stub `storage` est une fabrication locale, pas celui de Supabase : les résultats de 0030 et 0032 ne valent que sous cette hypothèse |
| B4 | Isolement de chaque scénario en échec : base neuve, stub, migrations, puis ce seul fichier | Voir le tableau ci-dessous | Même stub expérimental que B3 |

Détail des scénarios en échec (B3 et B4) :

| Scénario | Erreur | Isolé (B4) | Lecture |
|---|---|---|---|
| `scenarios_etape3.sql` | `ADM-02 ECHEC : 4 dossiers en attente au lieu de 2` | Échec identique | Les contrôles S3a à S5d passent. Le fichier s'arrête à ADM-02, donc la suite n'est pas mesurée. L'assertion compte les dossiers en attente de toute la base, et 2 fixtures supplémentaires sont présentes. Je n'ai pas identifié lesquelles |
| `scenarios_etape4.sql` | `ADM-01 ECHEC : 4 dossiers annonces, 3 reels` | Passe (rc 0) | Échec dû à l'état laissé par etape3 interrompu : dépendance à l'ordre |
| `scenarios_ctr01.sql` | `C2 : un troisieme eleve a ete accepte dans un cours 1-to-1` | Échec identique, y compris sans les migrations 0035 à 0037 | Cause non identifiée. Un contrôle de non-régression du plafond 1-to-1 échoue |
| `scenarios_agt01.sql` | `permission denied for function est_du_foyer` (dans une requête sur `public.presence_seance_v`) | Échec identique, y compris sans 0035 à 0037 | Test d'accès agent (AGT-01), donc test de sécurité SQL en échec : P0 selon la consigne. L'erreur est un refus du moteur, pas une fuite observée. Cause non identifiée : privilège manquant ou test qui suppose un privilège |

Les scénarios ont été rejoués dans l'ordre du CI pour ce qui suit ctr01 et agt01, mais leurs échecs ont été vérifiés en isolation, ce qui exclut l'ordre comme cause pour ces deux-là.

### 2.3 Logs

Journaux bruts : `sql-logs/ci_head_1` (B1), `sql-logs/ci_exp_storage` (B3), `sql-logs/iso_*` (B4), `sql-logs/flutter_test.log`, `sql-logs/dart_analyze.log`, `sql-logs/verifier_jetons.log`, `sql-logs/verifier_sans_exclusion.log`, tous dans le scratchpad de la session.

## 3 Mesures statiques (sur HEAD ff01c087, dans la copie)

| # | Mesure | Commande ou méthode | Résultat | Limite |
|---|---|---|---|---|
| S1 | Fichiers `.dart` sous `lib/` | glob `lib/**/*.dart` | 346 | |
| S2 | Fichiers `.dart` sous `test/` | glob `test/**/*.dart` | 183, dont 143 `*_test.dart` | |
| S3 | Migrations SQL | `git ls-files supabase/migrations/*.sql` | 42 fichiers. Trous de numérotation : 0039 à 0042 absents. Numéros en double : 0030, 0032 et 0033 (une variante `_durcissement` chacun) | |
| S4 | Tables créées sans RLS | regex `create table` puis `alter table ... enable row level security`, sur toutes les migrations | 72 tables créées, 72 avec RLS activée. Aucune table sans RLS | Faux positif écarté : le gabarit `create table public.%I partition of` (0004, ligne 966) crée des partitions d'`audit_logs`, dont la RLS est activée dynamiquement (0004, ligne 970) |
| S5 | Fonctions SECURITY DEFINER | heuristique sur l'en-tête de chaque `create [or replace] function` (avant `as $` ou `begin`) | 188 définitions, dont 0 sans `search_path` dans l'en-tête | Compte des occurrences, y compris les redéfinitions successives d'une même fonction. Heuristique : une fonction dont l'en-tête est mal découpé pourrait échapper |
| S6 | Tirets cadratins (U+2014) | `grep` sur `lib`, `web`, `assets/i18n` | `lib` : 0 dans les `.dart`, 5 dans `lib/CLAUDE.md` (document de consigne, pas un écran). `assets/i18n/ar.i18n.json` et `fr.i18n.json` : 0. `web/` : 0 | Non examiné dans `test/` (5 fichiers en contiennent) |
| S7 | Symbole de section (U+00A7) | idem | `lib` : 25 occurrences dans 19 fichiers, toutes dans des commentaires (filtre sur `///`, `//`, `*`). `assets/i18n` : 0. `web/` : 0 | Non examiné dans `test/` (5 fichiers en contiennent) |
| S8 | Poids des assets | `du` et tri par taille sur `assets/` | 2,55 Mo au total. Plus gros : `NotoSansArabic-Variable.ttf` (825 Ko), `Phosphor-Regular.ttf` (477 Ko), `Phosphor-Fill.ttf` (439 Ko), `BricolageGrotesque-Variable.ttf` (398 Ko), `InstrumentSans-Variable.ttf` (189 Ko) | |
| S9 | Secrets, motifs `sk_live`, `sk_test`, `sk-` (20 caractères ou plus), `AKIA`, `BEGIN PRIVATE KEY`, secret LiveKit, valeur R2 hexadécimale | `git grep -nI` sur HEAD, hors `docs/` et hors `*.md` | 0 occurrence pour chaque motif | Ne voit que les formes connues |
| S10 | Préfixe `eyJ` (JWT) | idem | 3 occurrences, toutes dans `test/` : `test/agent/acces_agent_test.dart` ligne 191, `test/config/supabase_key_validation_test.dart` lignes 25 et 26. Décodées : en-tête seul, ou signature de 5 caractères, ou sans signature. Ce sont des fixtures, pas des clés | |
| S11 | Motif `service_role` suivi d'une valeur | idem | 0. La mention `service_role` apparaît 123 fois hors docs, comme nom de rôle et non comme valeur | |
| S12 | Fichiers `.env`, clés, trousseaux versionnés | `git ls-files` avec motifs | 0 | |

Limite générale : seules la branche HEAD et sa copie ont été lues. L'historique git n'a pas été fouillé pour des secrets retirés.

## 4 Ce qui n'a pas pu être mesuré, et pourquoi

- PostgreSQL 17, version du CI : le dépôt PGDG est injoignable (HTTP 000) et le paquet n'existe pas dans apt Ubuntu 24.04. Toutes les mesures SQL sont faites en 16.15.
- Job `migrate-check` avec Postgres 17 : non mesuré, pour la même raison.
- Scénarios SQL avec le vrai schéma `storage` de Supabase : impossible, pas de Supabase local (démon Docker indisponible). Le stub `storage` utilisé en B3 et B4 est une fabrication locale et ses résultats sont conditionnels.
- Tests Deno du stockage R2 (`deno test supabase/functions/_shared/r2/`) et type-check Deno du job `edge-r2` : non mesurés. Deno n'est pas installé et ce n'était pas dans le périmètre demandé.
- `flutter build web`, `flutter build apk`, `flutter build windows` (job `flutter` du CI) : non tentés, hors périmètre demandé.
- Matrice Windows du CI pour `flutter test` : non mesurée, Linux seulement.
- Chiffres de session des documents (HANDOFF, PROGRESS) : cités comme annoncés, non revérifiés au-delà des mesures ci-dessus.

## 5 Écarts et points à traiter

- E1, P1, CI rouge à HEAD. Le job `migrate-check` échoue à 0030_tc_socle.sql (`storage.buckets` absent du stub commun). 0004 protège sa création de bucket par `to_regclass('storage.buckets')` (ligne 992), mais 0030 (lignes 207 et 211) et 0032 (policies sur `storage.objects`, lignes 632 à 661) ne le font pas. Confirmer sous Postgres 17.
- E2, P0 à qualifier. `scenarios_agt01.sql` échoue (`permission denied for function est_du_foyer`), en isolation et sans 0035 à 0037. C'est un test de sécurité SQL en échec au sens de la consigne. Aucune fuite n'est observée. Il faut dire si le privilège manque ou si le test est mal écrit.
- E3, écart. `tool/verifier_jetons.dart` exclut `features/_dev/` (lignes 366 et 403). Le vérificateur est vert à HEAD parce que 20 violations sont exclues. Le fait est mesuré, l'appréciation de la règle revient à l'équipe.
- E4, écart. `scenarios_ctr01.sql` (C2, plafond 1-to-1) échoue en isolation, sans 0035 à 0037. Cause non identifiée.
- E5, écart. `scenarios_etape3.sql` s'arrête à ADM-02 (4 dossiers en attente au lieu de 2). Cette assertion compte toute la base, et etape4 échoue dans la séquence à cause de cet état. Dépendance à l'ordre.
- E6, écart. Chiffres annoncés périmés : `flutter test` mesuré à 1762 tests et 0 échec, contre 729 et 684/691 annoncés ; verifier_jetons mesuré à 0 violation (avec exclusion), contre 6, 10 ou 11 annoncés.
- E7, écart. Le CI ne fixe pas la version de Flutter (`channel: stable`). La mission la croyait fixée.
- E8, écart. Les migrations 0035, 0036 et 0037 sont présentes dans le dépôt et exécutées par le CI, alors que leur fichier `LISEZ-MOI-0035-0037-non-appliquees.md` indique qu'elles ne sont pas appliquées en production. Numérotation : trous 0039 à 0042, doublons 0030, 0032 et 0033.
- E9, fait. Aucun secret trouvé, aucune table sans RLS, aucune fonction SECURITY DEFINER sans `search_path` dans les migrations.

Pour une lecture humaine : le code Flutter (analyse, génération, tests, jetons) est sain sur ce qui est mesuré, au prix de l'exclusion `_dev`. La base est le point faible : le job SQL échoue dès 0030, et au-delà de ce point, quatre scénarios sur douze échouent, dont un test d'accès agent.
