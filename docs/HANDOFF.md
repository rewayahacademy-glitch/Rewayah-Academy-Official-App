# HANDOFF — à lire en premier, avant toute action

> Dernière passation : **7 septembre 2026**, fin du lot **L9** de l'étape 4.
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
| L9 | `ADM-01`, `ADM-06` | fait |
| **L10** | **Vérifications de fin d'étape, documentation, `PROGRESS.md`** | **à faire, commencer ici** |

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

## 4. Reprendre : le lot L10

Le dernier lot de l'étape 4. Il n'ajoute aucun écran : il **vérifie et
consigne**. Trois choses, dans cet ordre.

1. **Rejouer les cinq contrôles de la section 5**, sur un conteneur neuf, et
   inscrire les chiffres obtenus dans `etape-4-journal.md`. Les mesures de L9
   sont dans ce fichier : elles servent de référence, pas de dispense.
2. **Mettre `docs/PROGRESS.md` à jour.** Il ment sur trois points, et
   `MISE-EN-SERVICE.md` dit lesquels dans son propre en-tête : les lignes C, D
   et M du tableau d'onboarding, et la ligne « Plateforme Android 37 » des
   décisions en attente, qui est à **retirer** (ce paquet n'existe pas sous ce
   nom, l'échec venait du magasin de certificats). À reporter aussi : l'étape 4
   est close côté écrans, et le scénario 14 reste non mesurable faute
   d'équipement, pas faute de code.
3. **Relire les dix-sept scénarios** du journal. Seize sont verts ; le
   quatorzième, le démarrage à froid, ne l'est pas et ne peut pas l'être sur ce
   poste. Ne pas le cocher. La PWA étant en ligne, il se ferme désormais en
   installant l'application sur un vrai téléphone d'entrée de gamme, ce qui est
   à la main de l'opérateur.

Ce que L10 **ne doit pas** faire : ouvrir l'étape 5. La salle, le pre-flight et
`ELV-03` / `ENS-03` sont une autre étape, avec sa propre spécification à écrire.

Deux dettes restent ouvertes et n'appartiennent à aucun lot :

- **`0006` n'est toujours pas jouée sur la base réelle.** Elle est écrite,
  commitée, et le harnais la rejoue à la suite de `0005` sans rien casser. Elle
  porte le correctif de la semaine UTC et la colonne de `profils_du_foyer_v`.
  Tant qu'elle n'est pas passée, `ENS-06` reste faux deux heures par semaine en
  production, et `TUT-01` lit une vue sans sa colonne. Le SQL à coller est dans
  `MISE-EN-SERVICE.md` section 5.
- **La production sert la build de `c5a511f`**, c'est-à-dire L8. Les deux écrans
  d'administration de L9 n'y sont pas. La ligne de promotion est à l'opérateur,
  `MISE-EN-SERVICE.md` section 7.1.

## 5. Mesures de référence, à ne pas faire régresser

Relevées le 7 septembre 2026, après L9 :

| Contrôle | Valeur |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | **277 tests**, tous verts |
| `dart run tool/verifier_jetons.dart` | **77 fichiers**, aucune violation |
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
# 0004_inscription_kyc_appairage, 0005_dashboards_affectation_regles,
# 0006_rattrapage_semaine_utc_et_foyer
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -q -f /sql/migrations/0001_fondations.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_etape3.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_etape4.sql
```

Un fichier de scénarios **ne se rejoue pas deux fois sur la même base** : il
insère ses fixtures. Repartir d'un conteneur neuf à chaque mesure.

Le compte de contrôles se lit en comptant les `NOTICE`. Un `docker rm -f` dont la
ligne contient aussi le chemin du volume peut être refusé par la protection de
chemins : le passer sur sa propre ligne.

⚠ **La convention « `0005` se corrige sur place » est morte.** Elle valait tant
que la migration n'était appliquée nulle part ; depuis le 7 septembre, `0001` à
`0005` sont inscrites dans `supabase_migrations` du projet réel, qui ne les
rejouera jamais. Toute correction posée dans `0005` y resterait donc invisible.
Tout changement structurel passe désormais par `0006` et suivantes, et `0006`
existe déjà : le harnais la rejoue à la suite de `0005`, sans effet sur une base
neuve puisqu'elle n'est faite que de `create or replace`.

## 7. Ce qui casse sur ce poste, et n'est pas de votre fait

- Le magasin de racines ne fait pas confiance à `github.com` : le hook de
  `package:sqlite3` échoue, donc `dart run` et `flutter test` peuvent échouer
  au premier appel. Voir `etape-2-journal.md`.
- Composant **ATL absent** de Visual Studio : `flutter build windows` échoue sur
  `atlstr.h`. Revérifié le 6 septembre, en `--profile` : l'échec vient du
  plugin `flutter_secure_storage_windows`, après 222 secondes de compilation.
- Build APK : **ce n'est pas la plateforme du SDK**, contrairement à ce qui
  était écrit ici. `sdkmanager "platforms;android-37"` répond `Failed to find
  package` — ce paquet n'existe pas, Google publie `android-37.0`, déjà
  installé. L'échec réel vient du magasin de certificats : le hook de
  `package:sqlite3` ne peut pas télécharger sa bibliothèque depuis `github.com`
  (`CERTIFICATE_VERIFY_FAILED`), et `Invoke-WebRequest` échoue pareillement sur
  la même adresse. **C'est le poste entier qui ne fait pas confiance à
  `github.com`**, pas l'outillage Flutter. Détail dans `MISE-EN-SERVICE.md`,
  section 4.1.
- **Aucun appareil ni AVD** Android : `flutter devices` ne propose que Windows,
  Chrome et Edge. Mais la cible web, elle, se construit et **tourne en ligne**
  depuis le 7 septembre : le démarrage à froid du scénario 14 peut désormais se
  mesurer en installant la PWA sur un vrai téléphone d'entrée de gamme. La
  mesure sera pessimiste — un bundle web pèse plus qu'un APK — donc un échec ne
  condamnerait pas le produit, mais une réussite compterait.
- PowerShell 5.1 : `2>&1` sur un exécutable natif fabrique un `NativeCommandError`
  même quand la commande a réussi. Lire la sortie, pas le code de retour.

## 7 bis. Le produit est en service, et ça change trois choses

Le 7 septembre 2026, en parallèle du lot L8, l'application a été **mise en
service pour de vrai**. Tout est consigné dans **`docs/MISE-EN-SERVICE.md`**, à
lire avant de toucher au SQL ou au déploiement.

Le travail PWA non commité que cette section signalait était la moitié de cette
mise en service : il est désormais vérifié par un `flutter build web`, déployé
et commité.

Ce qui change pour vous :

1. **Les migrations `0001` à `0005` sont appliquées au projet réel**
   `gggmtelinlpseweouyav`, et inscrites dans `supabase_migrations`. La
   convention « `0005` se corrige sur place » est morte : tout changement
   structurel passe désormais par une migration `0006` et suivantes. Les deux
   objets que L8 a modifiés dans `0005` **ne sont toujours pas sur la base
   réelle** : ils vivent dans `supabase/migrations/0006_rattrapage_semaine_utc_et_foyer.sql`,
   qui reste à jouer. Le même bloc SQL est dans `MISE-EN-SERVICE.md`, section 5.
2. **L'application tourne sur <https://rewayah-academy.vercel.app>**, construite
   depuis un commit vert, jamais depuis l'arbre de travail.
3. **Deux commandes restent à la main de l'opérateur** (hook de jeton et
   `STUDENT_EMAIL_DOMAIN`) : sans la première, toutes les RLS refusent et
   l'application n'affiche que des écrans vides, sans la moindre erreur.

Et la leçon de méthode qui valait déjà : **vérifier `git status` en arrivant**.
La correction `pgcrypto` de `0001` et `0004` attendait dans l'arbre, et a été
commitée à part au début du lot L8.

## 8. Ce qui reste ouvert, et ne dépend pas du code

- **Étape D, les secrets.** Aux trois quarts fermée le 7 septembre : le projet
  est lié, `dart_define.json` est écrit, et les deux fonctions Edge sont
  déployées et `ACTIVE`. Il reste **deux commandes**, listées dans
  `docs/MISE-EN-SERVICE.md` section 3 : le hook de jeton et
  `STUDENT_EMAIL_DOMAIN`. Sans la seconde, aucun enfant ne peut être créé.
- **Compression serveur des photos.** Devenue concrète au lot L8 : `TUT-05`
  dépose désormais vraiment une photo dans le seau `avatars`, avec un refus
  au-delà de 4 Mo côté client et rien de plus. C'est l'original du téléphone qui
  est servi aux appareils du foyer.
- Les questions en attente de l'opérateur sont listées dans `PROGRESS.md`, et
  les questions de conception dans `decisions.md`, registre en fin de fichier.
