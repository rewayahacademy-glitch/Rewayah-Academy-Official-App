# PROGRESS — État d'avancement du projet

> Suivi tenu par l'agent de code, une étape à la fois, jamais en bloc.
> C'est le seul fichier à lire pour savoir quoi faire ensuite.

## DÉMARRER ICI — prochaine session (ne rien chercher d'autre)

**Lire `docs/HANDOFF.md` en premier, avant toute action.** Il dit quel est le
dépôt actif, où le travail s'est arrêté, quel lot reprendre, et avec quelles
commandes. Le reste de ce fichier est le tableau d'avancement, pas la consigne
de reprise.

**Les étapes 3 et 4 sont terminées, la refonte UX/UI aussi.** L0 à L10 sont
faits (étape 4 close le 11 septembre 2026), et B0, T, C, R (R0 à R4), T2, T3,
A1 sont tous codés et poussés sur `main` (ADR-019). N0 (documentaire) a
spécifié l'étape 5 (ADR-020), **N1** a posé sa migration `0007`, puis
**`ADM-05`** (l'attribution manuelle) et **`ADM-04`** (le journal d'audit),
tous deux hors série, ont été construits le 12 septembre pendant que **N2
attend la décision du fournisseur vidéo**.

**L'espace admin n'a plus un seul écran manquant**, et il reste **neuf**
destinations en `EcranAConstruire` : élève (Coran, Suivi), tuteur (Suivi),
enseignant (Profil), contrôleur (Planning), espace comptable, et la salle
(`ELV-03`/`ENS-03`/`CTR-02`). Le compte se lit dans
`lib/core/router/app_router.dart`, jamais en parcourant les écrans.

**Le prochain lot est N2, et il ne peut pas commencer sans l'opérateur** :
fournisseur, compte, clés. S'il est encore bloqué, `docs/HANDOFF.md` §9.5 donne
la liste des lots qui ne dépendent pas de la vidéo, par valeur décroissante —
l'écart `Skeleton` sur les dix-neuf écrans restants est désormais en tête.

**Ce qui a changé de nature le 12 septembre.** Avant `ADM-05`, une affectation
ne pouvait naître que si un enseignant la prenait dans `ENS-06`. Sans
affectation, `materialiser_seances()` n'est jamais appelée ; sans séance,
`ENS-02`, `ELV-02` et `TUT-01` restent vides **quoi qu'ait construit l'étape
4**. L'administration peut désormais attribuer elle-même, et le compteur
« Foyers sans enseignant » d'`ADM-01` mène enfin à son geste.

**Et ce qu'`ADM-04` a rendu vrai le même jour.** `audit_logs` portait
`prev_hash` et `hash` depuis l'étape 1, et `log_sensitive_access()` payait un
`lock table` à chaque écriture du produit pour les tenir cohérents — **sans que
personne ne les relise jamais**. Le journal était donc immuable *par
déclencheur*, mais sa complétude n'avait jamais été constatée. Elle l'est :
`verifier_chaine_audit()` recalcule condensat et maillon, 34 entrées sur 34 se
vérifient sur la base réelle, et deux scénarios SQL falsifient délibérément le
journal pour prouver que la falsification se voit (ADR-022).

1. **Lire, dans cet ordre, et rien de plus** : `docs/HANDOFF.md`, puis, pour le
   lot N2 (étape 5), `docs/architecture/etape-5-salle-coran-presence.md` et
   `decisions.md` (ADR-020, ADR-021). Puis `lib/CLAUDE.md` dans tous les cas.
2. **Ne rien réécrire des étapes 2 et 3.** Les dix composants partagés, le
   thème, le routeur et les services de dossier sont les seuls points d'entrée
   de leur fonction. `dart run tool/verifier_jetons.dart` le dira.
3. **Ne rien réécrire des lots L2 à L8.** Les services de planning, de règles,
   de matching, d'administration, de prières, de réseau, d'appairage et de
   photos existent, avec leurs faux dans `test/support/harnais.dart`. Le tableau
   du handoff dit lequel sert à quoi.
4. **Le démarrage à froid a désormais où se mesurer.** L'application est en
   ligne depuis le 7 septembre : installer la PWA sur un vrai téléphone d'entrée
   de gamme donne enfin une mesure du scénario 14. Elle sera pessimiste, un
   bundle web pesant plus qu'un APK. Les cibles natives, elles, restent fermées
   sur ce poste : `atlstr.h` pour Windows, le magasin de certificats pour
   l'APK — et **pas** la plateforme du SDK, contrairement à ce qui était écrit.
5. **L'application est en service.** Base réelle peuplée, fonctions Edge
   déployées, hook de jeton actif, PWA en ligne, et le compte propriétaire est
   **administrateur**. **Lire `docs/MISE-EN-SERVICE.md`** avant de toucher au
   SQL ou au déploiement : `0005` ne se corrige plus sur place, `0006` attend
   d'être jouée, et l'admin ouvre les données mais pas encore les écrans —
   `ADM-01` est justement le lot L9.

### Commandes du projet

Depuis `D:\RA _APP\RA -OFFICIAL-APP` :

```
flutter pub get
dart run slang                                          # AVANT build_runner
dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos
flutter test
dart run tool/verifier_jetons.dart
flutter run --dart-define-from-file=dart_define.json     # voir l'exemple versionné
flutter build web --dart-define=GALERIE=true             # galerie des composants sur /_galerie
```

Les scénarios SQL se rejouent sur un Postgres **nu**, comme en CI. Un fichier de
scénarios ne se rejoue pas deux fois sur la même base : il insère ses fixtures.
Les commandes exactes, avec le conteneur, sont dans `docs/HANDOFF.md`.

```
psql -f supabase/tests/stub_auth.sql
psql -f supabase/migrations/0001_fondations.sql          # puis 0002 à 0005
psql -f supabase/tests/scenarios_etape3.sql              # 34 contrôles
psql -f supabase/tests/scenarios_etape4.sql              # 39 contrôles
psql -f supabase/tests/scenarios_etape5.sql              # 15 contrôles
psql -f supabase/tests/scenarios_adm05.sql               #  9 contrôles
```

## Étapes de code

| # | Étape | Statut | Où |
| :-- | :--- | :--- | :--- |
| 0 | Socle d'exploitation | partiel | Voir le tableau d'onboarding ci-dessous |
| 1 | Fondations DB, RLS, fonctions, audit | [x] | `supabase/migrations/0001` à `0004` |
| 2 | Core Flutter, thème, cache local, routeur | [x] | `docs/architecture/etape-2-journal.md` |
| 3 | Auth, KYC, appairage, portails d'attente | [x] | `docs/architecture/etape-3-journal.md` |
| 4 | Dashboards Bento Grid, affectation durable, prières | [x] | **Close le 11 septembre 2026 (lot L10)** : L0 à L10 faits, dix-sept scénarios relus (seize verts, le quatorzième non mesurable sur ce poste). `docs/architecture/etape-4-journal.md` |
| 4 bis | **Refonte UX/UI** : jetons, composants, reprise des écrans | [x] | **Close le 11 septembre 2026.** Lots T, C, R (R0 à R4) faits, plus B0, T2, T3 et A1 de la Bible Frontend V2 (ADR-019). **Non en ligne** : la production sert `a9127fd`, onze commits de retard — voir ligne M ci-dessus |
| 5 | Visio LiveKit, preuve de présence, Coran | [ ] | **Spécifiée (lot N0, ADR-020)**, découpage N0→N7 confirmé. **N1 fait** (migration `0007`, 15 contrôles). **N2 fait le 12 septembre 2026** (migration `0010`, 10 contrôles SQL, 13 tests Dart, **ADR-023**) : aiguillage à deux fournisseurs ancré par séance, émission de jeton, webhooks idempotents, et `en_connexion` enfin dérivable — l'état que N1 refusait volontairement de deviner faute de trace en base. Les deux fonctions Edge `create-room-token` et `livekit-webhook` sont **déployées et `ACTIVE`**. ⚠ **La connexion réelle à une salle n'est pas prouvée** : aucun compte LiveKit n'existe encore, la chaîne répond « vidéo non configurée » (`MISE-EN-SERVICE.md` §8). **Reste N3→N7**, dont `N3`, la coquille de salle qui remplacera le plus gros placeholder du routeur. `docs/architecture/etape-5-salle-coran-presence.md` |
| 5 bis | **`ADM-05` attribution manuelle**, hors série | [x] | **Fait le 12 septembre 2026**, pendant le blocage de N2. Migration `0008` (trois fonctions, aucune table), `lib/features/admin_attribution/`, ADR-021, 9 contrôles SQL et 7 tests de widget. Débloque la création d'affectations sans initiative d'un enseignant, donc la matérialisation des séances, donc le contenu d'`ENS-02`/`ELV-02`/`TUT-01`. Fiche `ADM-05` au catalogue |
| 5 ter | **`ADM-04` journal d'audit**, hors série | [x] | **Fait le 12 septembre 2026**, pendant le blocage de N2. Migration `0009` (trois lectures, **aucune table** : `audit_logs` existait et était déjà remplie), `lib/features/admin_journal/`, les composants `DataCollection` (P1 du catalogue, jamais construit jusqu'ici) et `FilterPill`, ADR-022, 9 contrôles SQL et 16 tests Dart. **L'espace admin n'a plus un seul placeholder.** Rend surtout vérifiable la chaîne de hachage que `audit_logs` portait depuis l'étape 1 sans que personne ne la relise. Fiche `ADM-04` au catalogue |
| 6 | Cahier de transmission | [ ] | |

## Protocole d'onboarding (`docs/agent-onboarding.md`)

| # | Étape | Statut | Notes |
| :-- | :--- | :--- | :--- |
| A | Dépôt Git et branche | [x] | `main`, `.gitignore`, remote GitHub connecté |
| B | Projet Supabase | [x] | `gggmtelinlpseweouyav`, `supabase/` initialisé et lié |
| C | Migrations versionnées | [x] | `0001` à `0005`, **appliquées au projet réel le 7 septembre 2026** et inscrites dans `supabase_migrations`. Le risque `pgcrypto` du journal de l'étape 3 était réel, et il est corrigé. **Corollaire : `0005` ne se corrige plus sur place**, tout changement structurel passe par `0006`. Voir `docs/MISE-EN-SERVICE.md` |
| D | Secrets | [x] | **Fermée le 7 septembre 2026.** Projet lié, `dart_define.json` écrit, fonctions Edge `creer-profil-enfant` et `session-enfant` déployées et `ACTIVE`, **hook de jeton actif** (`pg-functions://postgres/public/custom_access_token_hook`, vérifié en lecture sur `/config/auth`) et **`STUDENT_EMAIL_DOMAIN` posé**. Voir `docs/MISE-EN-SERVICE.md` section 3, qui note aussi les quatre réglages Auth que `config push` a écrasés au passage |
| E | CI/CD | [x] | `ci.yml` rejoue les contrôles SQL de `supabase/tests/` à chaque pull request. **116 au 12 septembre 2026** : 34 pour les étapes 1 et 3, 39 pour l'étape 4, 15 pour l'étape 5, 9 pour `ADM-05`, **10 pour `N2`**, 9 pour `ADM-04`. ⚠ **Défaut trouvé et corrigé le 12 septembre** : `scenarios_etape5.sql` existait depuis le lot N1 et n'avait jamais été ajouté au workflow ; ses quinze contrôles n'étaient rejoués que sur le poste. Les migrations, elles, passent par un glob et n'ont jamais eu ce problème. **Un fichier de scénarios ne s'ajoute donc pas tout seul : y penser dans le lot qui le crée.** `scenarios_adm04.sql` vient en dernier, et c'est structurel — son contrôle J4 vérifie l'intégrité de la chaîne de tout ce que les fichiers précédents ont écrit |
| F | Sentry | [ ] | Nécessite le compte Sentry |
| G | Variantes Flutter `dev` / `staging` / `prod` | [ ] | Un seul identifiant aujourd'hui : `com.rewayahacademy.app` |
| H | Stockage média R2 | [ ] | Nécessite le compte Cloudflare. Les seaux `kyc` et `avatars` de Supabase Storage, eux, sont créés par la migration 0004 |
| I | LiveKit | [ ] | **Tout le code est posé et déployé (lot N2, 12 septembre 2026)** ; il ne manque que le compte. Trois secrets à poser, et rien d'autre : `LIVEKIT_CLOUD_WS_URL`, `LIVEKIT_CLOUD_API_KEY`, `LIVEKIT_CLOUD_API_SECRET`, plus la déclaration du webhook côté LiveKit. Recette complète : `MISE-EN-SERVICE.md` §8. **Aucun redéploiement de fonction ni d'application n'est nécessaire** — les secrets sont lus à chaque appel, et le client n'a aucune URL en dur (ADR-023) |
| J | Config applicative `app_config` | [x] | Étendue à l'étape 3 : `kyc_retention_days`, `pairing_code_ttl_minutes` |
| K | Mémoire graphify | [ ] | À faire |
| L | Ressources front et back | [x] | Conformes aux étapes 2 et 3 |
| M | PWA multiappareils | [x] | En ligne sur <https://rewayah-academy.vercel.app>, chargée sans erreur console. Manifeste, `index.html` et `vercel.json` portent le nom, la palette, la balise `viewport` qui manquait et la réécriture SPA. Service worker généré par Flutter. **Rattrapée le 11 septembre 2026** : l'adresse stable sert désormais `ad21990` (`main`, lot L10 compris), confirmé par l'API Vercel (`gitCommitSha` exact). Le retard de onze commits constaté plus tôt dans la même session (la prod servait encore `a9127fd`/R3) est comblé — B0, T2, R0, T3, R4, A1 et N0 sont en ligne. Reste à décider : le plan Vercel Hobby exclut l'usage commercial |

## Décisions en attente de l'opérateur

| Sujet | Question | Où c'est documenté |
| :--- | :--- | :--- |
| ~~`borderDefault`~~ | **Résolue par l'ADR-018** : le jeton unique est remplacé par trois bordures, dont une seule porte du sens et mesure 3,40 sur le crème | `decisions.md`, question 10 |
| Poids des polices | **Déplacée, pas résolue.** Noto Sans et Varela Round sortent (ADR-018), remplacées par Instrument Sans et Bricolage Grotesque. Le poids obtenu est à **mesurer** au lot T, et le sous-ensemblage reste entièrement à faire | `decisions.md`, question 11 |
| Fichiers de police à récupérer | Bricolage Grotesque et Instrument Sans, depuis `fonts.google.com`. ⚠ Pas depuis le dépôt `google/fonts` : ce poste ne fait pas confiance à `github.com` en TLS | `design-tokens.md` §2.4 |
| `child_ui_mode_max_age` | Posé à **8** et employé tel quel par l'étape 3. Modifiable en une ligne d'`app_config`, sans redéploiement. À confirmer ou corriger | `decisions.md`, ADR-016 |
| Lecture du QR par la caméra | Reportée : le paquet réclame une configuration de permissions par plateforme. Le chemin par le code fonctionne partout. À rouvrir si le QR devient nécessaire | `etape-3-auth-kyc.md` section 9 |
| Compression serveur des photos | **Devenue concrète au lot L8** : `TUT-05` dépose désormais vraiment la photo dans le seau `avatars`, avec un refus au-delà de 4 Mo côté client et rien de plus. Aucune compression serveur n'existe, donc le cache local ne peut pas borner sa taille comme l'étape 2 le prévoyait, et c'est l'original du téléphone qui est servi aux appareils du foyer | `decisions.md`, question 17 |
| Litige sur le temps effectif | L'étape 4 pose le minimum payable et sa trace, l'étape 5 mesurera la présence réelle. Les deux doivent se rejoindre avant la première paie | `decisions.md`, question 16 |
| Composant ATL de Visual Studio | Le build Windows échoue sur `atlstr.h` absent, réclamé par `flutter_secure_storage_windows`. Installer « C++ ATL for latest v143 build tools » dans Visual Studio Build Tools | `etape-3-journal.md` |
| Magasin de certificats du poste | **Remplace la ligne « Plateforme Android 37 », qui était fausse** : `sdkmanager "platforms;android-37"` répond `Failed to find package`, ce paquet n'existe pas, Google publie `android-37.0` et il est déjà installé. Le build APK échoue en réalité parce que le hook de `package:sqlite3` ne peut pas joindre `github.com` en TLS — et `Invoke-WebRequest` échoue pareillement, donc c'est le poste, pas Flutter. À réparer côté racines Windows ou antivirus, jamais en désactivant la vérification | `MISE-EN-SERVICE.md` section 4.1 |
| Réglages Auth écrasés par `config push` | Quatre valeurs distantes ont été remplacées par celles de `config.toml` sans qu'on le demande : TOTP `enroll`/`verify` passés à `false`, `enable_confirmations` à `false` (comptes auto-confirmés), `max_frequency` 1 min → 1 s, `otp_length` 8 → 6. À trancher avant l'ouverture au public | `MISE-EN-SERVICE.md` section 3 |
| Migration `0006` non appliquée | Le rattrapage des deux objets que L8 a modifiés dans `0005` après son application (ancre UTC de `instant_creneau`, colonne `access_until` de `profils_du_foyer_v`) est commité mais **pas encore joué sur la base réelle**. Non bloquant : l'application fonctionne sans. Bloc SQL prêt à coller | `MISE-EN-SERVICE.md` section 5 |
| Interfaces d'administration | Le compte propriétaire a été passé en **admin** le 7 septembre, puis **remis en `guardian` le même jour** : `/admin/tableau-de-bord` ne rend qu'`EcranAConstruire`, l'accès admin ouvre les données et pas encore les écrans. C'est exactement `ADM-01`, le lot L9. Le rôle se bascule à volonté par une requête, documentée | `MISE-EN-SERVICE.md` section 3.3 |
| Promotion en production | **Résolue le 11 septembre 2026.** Le retard de onze commits (constaté puis comblé dans la même session, lot L10) est clos : l'adresse stable sert `ad21990` (`main`). Reconstruction faite depuis le worktree `D:\ra-pwa-build` (`git checkout`, `flutter pub get`, `flutter build web --release`, pas besoin de `dart run slang`/`build_runner` : les fichiers générés sont commités dans le dépôt), puis `vercel deploy --prod --yes` — **passé sans refus cette fois**, sur autorisation explicite de l'opérateur | `MISE-EN-SERVICE.md` section 7.1, ligne M ci-dessus |
| Plan d'hébergement | La PWA est sur Vercel Hobby, gratuit, dont les conditions **excluent l'usage commercial**. À trancher avant l'ouverture payante : plan payant, ou un hébergeur statique gratuit qui autorise le commerce | `MISE-EN-SERVICE.md` section 4 |
| Appareil de mesure du démarrage à froid | Le scénario 7 de l'étape 2 demande **moins de 1,5 seconde sur un appareil d'entrée de gamme**. L'écran existe depuis L7 et l'application est en ligne depuis le 7 septembre : la mesure est désormais possible en installant la PWA sur un vrai téléphone d'entrée de gamme. Elle sera pessimiste, un bundle web pesant plus qu'un APK, donc un échec ne condamnerait pas le produit mais une réussite compterait | `etape-4-journal.md`, section L7 |

## Règle de lecture

- Ce fichier est le miroir de l'avancement. Une session qui arrive sur un `[ ]`
  traite l'étape concernée avant tout autre travail, ou dit pourquoi elle ne le
  fait pas.
- Chaque étape a un critère de sortie vérifiable, défini dans
  `docs/agent-onboarding.md` et dans les plans d'étape.
- **Un contrôle qui n'a jamais tourné n'est pas un contrôle vert.** C'est ce qui
  a masqué le défaut de la CI pendant toute l'étape 1.

## Vague 5 — intégration contrôlée du 15 septembre 2026

Worktree d'intégration :
`C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-vague5-integration`.
Les lots R1, shell adaptatif, correctif Material 3, profil enseignant et
surface de correction de présence ont été intégrés un par un depuis les
commits sources `6e85aec`, `da34f9c`, `1fc15c6`, `65c564f` et `d55606c`.
Le profil a nécessité le raccord ciblé `d36fb4b` pour ses chaînes i18n et sa
route ; aucun lot Compte concurrent n'a été repris. Les fichiers OpenCode et
le checkout principal sale sont exclus.

État des preuves sur cette branche : vérificateur de jetons **PASS** (129
fichiers, aucune violation) et `git diff --check` **PASS**. Analyse globale et
tests Flutter globaux **BLOCKED** par le runner silencieux après démarrage ; les
scénarios SQL **BLOCKED** car le daemon Docker est indisponible. La recette
navigateur authentifiée est volontairement reportée et n'est pas prouvée.
