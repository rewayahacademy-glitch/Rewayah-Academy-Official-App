# HANDOFF — à lire en premier, avant toute action

> Dernière passation : **6 septembre 2026**, fin du lot **L7** de l'étape 4.
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
| **L8** | **`TUT-01`, `TUT-05`, demandes des parties** | **à faire, commencer ici** |
| L9 | `ADM-01`, `ADM-06` | |
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

## 4. Reprendre : le lot L8

Deux écrans du tuteur, plus le chemin des demandes. D'après la spécification
section 5 et les fiches de `parcours-utilisateurs.md` :

- **`TUT-01`, accueil famille.** Bloc dominant : l'état en direct de chaque
  enfant, **une ligne par enfant**, selon les cinq états de la fiche. Le bouton
  « Assister » n'est rendu que pendant une séance en cours et mène à la salle en
  observateur, donc au placeholder de `Routes.salle` avec son billet. Blocs
  secondaires : ajouter un appareil, réglages du foyer, et la date de fin
  d'accès de chaque enfant.
- **`TUT-05`, réglages par enfant.** Un enfant par carte, trois réglages :
  photo, caméra, mode d'interface. Le texte dit la conséquence en clair **avec
  le prénom de l'enfant**, jamais un libellé abstrait. Ils s'appliquent à la
  séance suivante, jamais pendant un cours. Il remplace le placeholder de
  `Routes.tuteurReglages`.
- **Les demandes des parties.** `ServiceMatching.demander` existe déjà et n'a
  encore aucun appelant : c'est ici que le tuteur demande une réaffectation ou
  un changement de règle.

Cela ferme le parcours 3 du tableau de la section 1 de la spécification.

Tout est en place côté données sauf une écriture, **ne rien réécrire** :

| Ce dont L8 a besoin | Où c'est déjà fait |
| :--- | :--- |
| Les enfants du foyer, avec leur mode, leur caméra et leur photo | `elevesDuFoyerProvider`, `lib/core/appairage/service_appairage.dart` |
| Qui suit qui, y compris avant la première séance | `affectationsProvider`, `lib/core/planning/service_planning.dart` |
| Le cours qui vient, en cours ou à venir | `prochainCours`, `lib/core/planning/journee.dart` |
| La séance annulée qu'on attendait aujourd'hui | `seanceAnnuleeDuJour`, même fichier, posée par L7 pour `ELV-02` **et** pour `TUT-01` |
| Les interruptions d'une séance donnée | `interruptionsDe`, même fichier |
| L'état du réseau | `horsLigneProvider`, `lib/core/reseau/service_reseau.dart`, avec son faux au harnais |
| Déposer une demande | `ServiceMatching.demander`, `lib/core/matching/service_matching.dart` |
| La valeur d'une règle pour un profil | `valeurRegleProvider` — **par `regle_effective()`, jamais par `regles_profil_v`**, voir le journal L6 |
| Le libellé parlé d'un texte | `CleAudio`, `lib/core/i18n/cle_audio.dart`, et le composant `AudioLabel`, qui accepte une paire depuis L7 |

**Ce qui manque, et qu'il faudra écrire** : aucune méthode n'écrit les trois
réglages de `student_profiles`. La base est prête et les mesure déjà, contrainte
aux trois colonnes (`scenarios_etape4.sql`, S6a et S6b) ; c'est le service Dart
qui n'a que la lecture.

`ELV-02` est le modèle le plus proche pour l'état en direct :
`lib/features/accueil_eleve/accueil_eleve_page.dart` et son test. Les deux
écrans lisent la même séance et doivent en dire la même chose, le tuteur avec
ses mots d'adulte. **L'horloge s'injecte** : un état qui se compte en minutes ne
se teste pas contre l'horloge de la machine, voir le journal L7.

Les libellés vont dans `assets/i18n/fr.i18n.json`, puis `dart run slang`.
Aucune chaîne en dur. Les fichiers son de `assets/audio/fr/` restent à
enregistrer : la clé audio se pose, le son viendra.

## 5. Mesures de référence, à ne pas faire régresser

Relevées le 6 septembre 2026, après L7 :

| Contrôle | Valeur |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | **227 tests**, tous verts |
| `dart run tool/verifier_jetons.dart` | **72 fichiers**, aucune violation |
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
  `atlstr.h`. Revérifié le 6 septembre, en `--profile` : l'échec vient du
  plugin `flutter_secure_storage_windows`, après 222 secondes de compilation.
- Plateforme Android mal nommée (`android-37.0` au lieu d'`android-37`) : le
  build APK échoue. Et **aucun appareil ni AVD** n'est disponible : `flutter
  devices` ne propose que Windows, Chrome et Edge. C'est ce qui empêche de
  mesurer le démarrage à froid, scénario 14.
- PowerShell 5.1 : `2>&1` sur un exécutable natif fabrique un `NativeCommandError`
  même quand la commande a réussi. Lire la sortie, pas le code de retour.

## 8. Ce qui reste ouvert, et ne dépend pas du code

- **Étape D, les secrets.** Toujours ouverte, et bloquante pour l'usage : sans
  elle les deux fonctions Edge de l'étape 3 ne sont pas déployées, donc **aucun
  enfant ne peut ouvrir de session**. Voir `docs/PROGRESS.md`.
- Les questions en attente de l'opérateur sont listées dans `PROGRESS.md`, et
  les questions de conception dans `decisions.md`, registre en fin de fichier.
