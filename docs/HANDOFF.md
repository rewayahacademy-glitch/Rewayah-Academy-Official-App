# HANDOFF — à lire en premier, avant toute action

> Dernière passation : **6 septembre 2026**, fin du lot **L5** de l'étape 4.
> Commit `2bc7818` sur `main`, poussé.

## 1. Le projet actif est celui-ci

**Dépôt de travail : `D:\RA _APP\RA -OFFICIAL-APP`** — Rewayah Academy,
application Flutter de cours de Coran en visio, Supabase en dos.

**Ne pas travailler sur PISI.** Les projets PISI (`PISI CERVEAU`, console de
production vidéo, Next.js) sont **en pause** : ils occupent la plus grosse part
de l'historique et de la mémoire, et une session qui suit ses pointeurs par
habitude se branche dessus par erreur. C'est arrivé au début de la session du
6 septembre. Si le répertoire de travail ouvert n'est pas celui ci-dessus,
changer de répertoire avant toute chose.

`Glob` ne trouve pas ce dépôt : le répertoire de session pointe ailleurs. Passer
les chemins en absolu, et préfixer les commandes par
`cd "D:\RA _APP\RA -OFFICIAL-APP"`.

## 2. Où en est le travail

Étape 4, **dashboards Bento Grid, affectation durable, disponibilités et
prières**. Découpage en onze lots, un lot par commit.

| Lot | Contenu | État |
| :-- | :--- | :-: |
| L0 | Spécification, ADR-017, journal | fait |
| L1 | Migration `0005` et `scenarios_etape4.sql` | fait |
| L2 | Services Dart : règles, planning, matching, admin | fait |
| L3 | Grille de semaine partagée, `TUT-04` | fait |
| L4 | `ENS-06`, prise atomique, plafond | fait |
| L5 | Prières : réglages, calcul, ajustements, journée | fait |
| **L6** | **`ENS-02` la journée en une colonne** | **à faire, commencer ici** |
| L7 | `ELV-02` et ses six états, puis le démarrage à froid | |
| L8 | `TUT-01`, `TUT-05`, demandes des parties | |
| L9 | `ADM-01`, `ADM-06` | |
| L10 | Vérifications de fin d'étape, documentation, `PROGRESS.md` | |

## 3. Quoi lire, dans cet ordre, et rien d'autre

1. `docs/architecture/etape-4-journal.md` — où en est le code, ce que valent les
   mesures, et les pièges déjà payés. **Le plus important des trois.**
2. `docs/architecture/etape-4-dashboards.md` — la spécification : ADR-017, les
   neuf défauts corrigés, les douze invariants, les écrans, les 17 scénarios.
3. `lib/CLAUDE.md` — les règles du code, qui font échouer la CI quand on les
   ignore.

Ne pas rouvrir l'historique des étapes 1 à 3 : leurs journaux ne servent qu'en
cas de doute sur un point précis.

## 4. Reprendre : le lot L6

`ENS-02` remplace le placeholder de `Routes.enseignantJournee`. Ce qu'il rend,
d'après la spécification section 5 :

- **Bloc dominant** : le prochain cours, prénom et identifiant immuable de
  l'élève, minuteur. Le bouton de lancement **n'est pas rendu** : le pre-flight
  est l'étape 5, et un bouton qui échoue après le geste coûte plus cher qu'un
  bouton absent.
- **Une seule colonne de haut en bas** : cours, pauses et prières comme des
  entrées de même nature. Un bloc « prières » séparé est explicitement interdit.
- **Bloc secondaire** : le nombre d'élèves en attente compatibles, et l'accès à
  `ENS-06`.

Tout est déjà en place côté données, **ne rien réécrire** :

| Ce dont L6 a besoin | Où c'est déjà fait |
| :--- | :--- |
| La colonne triée cours + pauses + prières | `construireJournee` dans `lib/core/planning/journee.dart` |
| Les séances des trois rôles | `seancesProvider`, `lib/core/planning/service_planning.dart` |
| Les réglages de prière de l'enseignant | `reglagesPriereProvider`, `lib/core/priere/service_priere.dart` |
| Le nom d'une prière | `libellePriere`, `lib/core/priere/libelle_priere.dart` |
| La durée maximale d'une pause | `ServiceRegles.valeur(profil, CleRegle.pauseEntreCours)` — **jamais une constante** |
| Le feed des élèves en attente | `elevesEnAttenteProvider`, `lib/core/matching/service_matching.dart` |

Les libellés vont dans `assets/i18n/fr.i18n.json`, section nouvelle, puis
`dart run slang`. Aucune chaîne en dur.

## 5. Mesures de référence, à ne pas faire régresser

Relevées le 6 septembre 2026, après L5 :

| Contrôle | Valeur |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | **196 tests**, tous verts |
| `dart run tool/verifier_jetons.dart` | **69 fichiers**, aucune violation |
| `scenarios_etape3.sql` | **34 contrôles** verts |
| `scenarios_etape4.sql` | **37 contrôles** verts |

Un lot se termine par ces cinq contrôles, la mise à jour de
`etape-4-journal.md`, un commit et un push. Jamais l'inverse.

## 6. Commandes vérifiées sur ce poste

```
cd "D:\RA _APP\RA -OFFICIAL-APP"
flutter pub get
dart run slang                                          # AVANT build_runner
dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos
flutter test
dart run tool/verifier_jetons.dart
```

Le harnais SQL, tel qu'il a servi pour L5. Les noms de migration sont ceux du
dépôt, pas ceux qu'on devine :

```powershell
docker rm -f ra_e5 | Out-Null
docker run -d --name ra_e5 -e POSTGRES_HOST_AUTH_METHOD=trust `
  -v "D:\RA _APP\RA -OFFICIAL-APP\supabase:/sql" postgres:17-alpine
# attendre pg_isready, puis :
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -q -f /sql/tests/stub_auth.sql
# 0001_fondations, 0002_statut_attente_kyc, 0003_profil_defaut_attente,
# 0004_inscription_kyc_appairage, 0005_dashboards_affectation_regles
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -q -f /sql/migrations/0001_fondations.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_etape3.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_etape4.sql
```

Un fichier de scénarios **ne se rejoue pas deux fois sur la même base** : il
insère ses fixtures. Repartir d'un conteneur neuf à chaque mesure.

`0005` n'est appliquée nulle part en réel, l'étape D restant ouverte : elle se
**corrige sur place**, comme elle l'a déjà été trois fois. Le journal dit
pourquoi à chaque fois.

## 7. Ce qui casse sur ce poste, et n'est pas de votre fait

- Le magasin de racines ne fait pas confiance à `github.com` : le hook de
  `package:sqlite3` échoue, donc `dart run` et `flutter test` peuvent échouer
  au premier appel. Voir `etape-2-journal.md`.
- Composant **ATL absent** de Visual Studio : `flutter build windows` échoue sur
  `atlstr.h`.
- Plateforme Android mal nommée (`android-37.0` au lieu d'`android-37`) : le
  build APK échoue.
- PowerShell 5.1 : `2>&1` sur un exécutable natif fabrique un `NativeCommandError`
  même quand la commande a réussi. Lire la sortie, pas le code de retour.

## 8. Ce qui reste ouvert, et ne dépend pas du code

- **Étape D, les secrets.** Toujours ouverte, et bloquante pour l'usage : sans
  elle les deux fonctions Edge de l'étape 3 ne sont pas déployées, donc **aucun
  enfant ne peut ouvrir de session**. Voir `docs/PROGRESS.md`.
- Les questions en attente de l'opérateur sont listées dans `PROGRESS.md`, et
  les questions de conception dans `decisions.md`, registre en fin de fichier.
