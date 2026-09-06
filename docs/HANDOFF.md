# HANDOFF — à lire en premier, avant toute action

> Dernière passation : **7 septembre 2026**, fin du lot **L8** de l'étape 4.
> Dernier commit de `main`, poussé. `git log -1 --oneline` le nomme.

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
| L6 | `ENS-02` la journée en une colonne | fait |
| L7 | `ELV-02` et ses six états | fait |
| L8 | `TUT-01`, `TUT-05`, demandes du tuteur | fait |
| **L9** | **`ADM-01`, `ADM-06`** | **à faire, commencer ici** |
| L10 | Vérifications de fin d'étape, documentation, `PROGRESS.md` | |

Le démarrage à froid, scénario 14, **n'est pas mesurable sur ce poste** : aucune
cible ne se construit ni ne se lance. Ce n'est pas du travail en retard, c'est
une question d'équipement, détaillée dans le journal et dans `PROGRESS.md`.

## 3. Quoi lire, dans cet ordre, et rien d'autre

1. `docs/architecture/etape-4-journal.md` — où en est le code, ce que valent les
   mesures, et les pièges déjà payés. **Le plus important des trois.**
2. `docs/architecture/etape-4-dashboards.md` — la spécification : ADR-017, les
   neuf défauts corrigés, les douze invariants, les écrans, les 17 scénarios.
3. `lib/CLAUDE.md` — les règles du code, qui font échouer la CI quand on les
   ignore.

Ne pas rouvrir l'historique des étapes 1 à 3 : leurs journaux ne servent qu'en
cas de doute sur un point précis.

## 4. Reprendre : le lot L9

Les deux écrans de l'administration. D'après la spécification section 5 :

- **`ADM-01`, centre de commande.** Cinq compteurs, plus un sixième arrivé par
  l'ADR-017, les demandes en attente de décision. **Le zéro s'affiche comme les
  autres valeurs**, il ne fait pas disparaître son compteur : c'est l'invariant
  I9 et le scénario 11, qui se mesure par un test de widget. Sous les compteurs,
  la liste « à traiter en premier », ordonnée par ancienneté, chaque ligne menant
  d'un tap à l'écran d'action. Il remplace le placeholder de
  `Routes.adminTableauDeBord`.
- **`ADM-06`, demandes et règles.** **Seul écran vraiment nouveau de l'étape**,
  et sa route reste à déclarer. Deux usages, un seul écran, dans le registre de
  `ADM-02` : une file de demandes prise une par une, deux verdicts, motif
  obligatoire pour un refus ; et la feuille de règles d'un élève, où chaque
  valeur affiche **côte à côte** le défaut de la plateforme et la valeur
  effective, pour que l'écart se voie sans calcul mental. L'administration change
  une règle à la volée depuis cette feuille, sans qu'une demande existe : c'est la
  consigne, une demande n'est qu'un des deux chemins. L'historique des surcharges
  closes reste affiché sous la valeur courante.

Cela ferme le parcours 6 du tableau de la section 1 de la spécification, et rend
enfin visibles les demandes que `ENS-06` et `TUT-05` déposent déjà.

Tout est en place côté données, **ne rien réécrire** :

| Ce dont L9 a besoin | Où c'est déjà fait |
| :--- | :--- |
| Les six compteurs en une lecture | `indicateurs_admin()`, `lib/core/admin/service_admin.dart` |
| La file des demandes en attente | `ServiceAdmin.demandesEnAttente`, même fichier, et le modèle `Demande` de `lib/core/matching/service_matching.dart` |
| Trancher une demande | `ServiceAdmin.decider`, écrit en L2 et **sans aucun écran qui l'appelle** : c'est l'écran que L9 apporte, pas le service |
| Poser et clore une règle | `ServiceRegles.poser` et `.clore`, `lib/core/regles/service_regles.dart`, sans appelant à ce jour non plus |
| Valeur effective et valeur de plateforme, côte à côte | `RegleProfil`, déjà porteur des deux, et `reglesProfilProvider` |
| La valeur d'une règle pour un profil | `valeurRegleProvider` — **par `regle_effective()`, jamais par `regles_profil_v`**, voir le journal L6 |
| Les dossiers à valider, pour la ligne « à traiter » | `ServiceValidation`, écrit à l'étape 3, et l'écran `ADM-02` qui existe |

Les modèles les plus proches : `dossiers_page.dart` pour une file avec verdict et
motif obligatoire, et la feuille `_FeuilleDemande` de `creneaux_page.dart` puis
`FeuilleDemandeTuteur` de `reglages_enfant_page.dart` pour le formulaire de
demande. Les trois se ressemblent volontairement.

**`ServiceAdmin` n'a pas encore de faux** dans `test/support/harnais.dart`,
contrairement aux six autres services : personne n'en avait eu besoin. C'est la
première chose à écrire, sans quoi `ADM-01` n'est pas mesurable, et le scénario
11 demande précisément un test de widget.

Les libellés vont dans `assets/i18n/fr.i18n.json`, puis `dart run slang`.
Aucune chaîne en dur.

## 5. Mesures de référence, à ne pas faire régresser

Relevées le 7 septembre 2026, après L8 :

| Contrôle | Valeur |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | **253 tests**, tous verts |
| `dart run tool/verifier_jetons.dart` | **75 fichiers**, aucune violation |
| `scenarios_etape3.sql` | **34 contrôles** verts |
| `scenarios_etape4.sql` | **39 contrôles** verts |

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

Le harnais SQL. Les noms de migration sont ceux du dépôt, pas ceux qu'on devine.
**Attendre `pg_isready` dans une boucle** : sept secondes ne suffisent pas
toujours, et `psql` répond alors « No such file or directory » sur la socket,
ce qui ressemble à une panne et n'en est pas une.

```powershell
docker rm -f ra_e5
docker run -d --name ra_e5 -e POSTGRES_HOST_AUTH_METHOD=trust `
  -v "D:\RA _APP\RA -OFFICIAL-APP\supabase:/sql" postgres:17-alpine
# boucler sur pg_isready, puis :
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -q -f /sql/tests/stub_auth.sql
# 0001_fondations, 0002_statut_attente_kyc, 0003_profil_defaut_attente,
# 0004_inscription_kyc_appairage, 0005_dashboards_affectation_regles
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -q -f /sql/migrations/0001_fondations.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_etape3.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_etape4.sql
```

Un fichier de scénarios **ne se rejoue pas deux fois sur la même base** : il
insère ses fixtures. Repartir d'un conteneur neuf à chaque mesure.

Le compte de contrôles se lit en comptant les `NOTICE`. Un `docker rm -f` dont la
ligne contient aussi le chemin du volume peut être refusé par la protection de
chemins : le passer sur sa propre ligne.

`0005` n'est appliquée nulle part en réel, l'étape D restant ouverte : elle se
**corrige sur place**, comme elle l'a déjà été quatre fois. Le journal dit
pourquoi à chaque fois.

## 7. Ce qui casse sur ce poste, et n'est pas de votre fait

- Le magasin de racines ne fait pas confiance à `github.com` : le hook de
  `package:sqlite3` échoue, donc `dart run` et `flutter test` peuvent échouer
  au premier appel. Voir `etape-2-journal.md`.
- Composant **ATL absent** de Visual Studio : `flutter build windows` échoue sur
  `atlstr.h`. Revérifié le 6 septembre, en `--profile` : l'échec vient du
  plugin `flutter_secure_storage_windows`, après 222 secondes de compilation.
- Plateforme Android mal nommée (`android-37.0` au lieu d'`android-37`) : le
  build APK échoue. Et **aucun appareil ni AVD** n'est disponible : `flutter
  devices` ne propose que Windows, Chrome et Edge. C'est ce qui empêche de
  mesurer le démarrage à froid, scénario 14.
- PowerShell 5.1 : `2>&1` sur un exécutable natif fabrique un `NativeCommandError`
  même quand la commande a réussi. Lire la sortie, pas le code de retour.

## 7 bis. Du travail non commité traîne dans l'arbre

`web/index.html` et `web/manifest.json` sont modifiés et **non commités** : un
début de mise en forme PWA, daté d'avant le lot L8, qui remplace les valeurs par
défaut de Flutter par le nom, la description et les couleurs du produit. C'est
l'étape M du tableau d'onboarding, toujours `[ ]`.

Le lot L8 ne les a pas repris : ce n'est pas son périmètre, et personne ne sait
si le service worker et l'URL déployée qui vont avec sont commencés. **Ne pas les
committer sans les avoir vérifiés** par un `flutter build web`, et sans savoir ce
que l'opérateur voulait en faire.

La même situation s'est produite pour `0001` et `0004` : la correction `pgcrypto`
attendait dans l'arbre depuis une session antérieure, et a été commitée à part
au début du lot L8. Vérifier `git status` en arrivant vaut mieux que le
découvrir au moment de committer.

## 8. Ce qui reste ouvert, et ne dépend pas du code

- **Étape D, les secrets.** Toujours ouverte, et bloquante pour l'usage : sans
  elle les deux fonctions Edge de l'étape 3 ne sont pas déployées, donc **aucun
  enfant ne peut ouvrir de session**. Voir `docs/PROGRESS.md`.
- **Compression serveur des photos.** Devenue concrète au lot L8 : `TUT-05`
  dépose désormais vraiment une photo dans le seau `avatars`, avec un refus
  au-delà de 4 Mo côté client et rien de plus. C'est l'original du téléphone qui
  est servi aux appareils du foyer.
- Les questions en attente de l'opérateur sont listées dans `PROGRESS.md`, et
  les questions de conception dans `decisions.md`, registre en fin de fichier.
