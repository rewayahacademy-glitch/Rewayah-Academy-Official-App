# Journal d'exécution - Étape 3

> Ce fichier dit **où en est le code** de l'étape 3, ce que valent les mesures,
> et quels pièges ont déjà coûté du temps.
> `docs/architecture/etape-3-auth-kyc.md` reste la spécification ; ce journal est
> son compte rendu. Mis à jour à la fin de chaque lot, jamais en bloc.

## État : étape 3 terminée

Vérifications au 6 septembre 2026 :

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | 156 tests, tous verts |
| `dart run tool/verifier_jetons.dart` | 57 fichiers, aucune violation |
| `supabase/tests/scenarios_etape3.sql` sur Postgres 17 | 36 contrôles, tous verts |
| Régénération slang puis `build_runner` | aucun diff |
| `flutter build web` | réussi, 3,28 Mo, galerie totalement élaguée |
| `flutter build windows` | **échoue sur ce poste**, voir les pièges |
| `flutter build apk` | **échoue sur ce poste**, voir les pièges |

| Lot | Contenu | Fait |
| :-- | :--- | :-: |
| L0 | Spécification `etape-3-auth-kyc.md` et ce journal | x |
| L1 | Migration 0004 : les cinq défauts, les tables et fonctions de l'étape | x |
| L2 | Porte `inscription` dans la session et le routeur | x |
| L3 | Connexion `TUT-00` et service d'authentification abstrait | x |
| L4 | Onboarding en cartes `TUT-00c` | x |
| L5 | KYC, contrat, accusé ADR-011, portail d'attente `TUT-00b` | x |
| L6 | Appairage `TUT-02` et connexion enfant `ELV-01` | x |
| L7 | Fonctions Edge : profil enfant, session enfant | x |
| L8 | Validation des dossiers `ADM-02` | x |
| L9 | Vérifications, CI, documentation | x |

## Les douze scénarios d'acceptation

Voir la section 8 de la spécification. Aucun n'est coché tant qu'il n'est pas
mesuré : c'est la règle qui a coûté la découverte du défaut de CI à l'étape 1.

| # | Scénario | État | Où c'est vérifié |
| :-- | :--- | :--- | :--- |
| 1 | Compte sans profil : inscription et rien d'autre | vert | `test/router/redirection_test.dart`, 8 routes croisées plus les deux contrôles négatifs |
| 2 | Échec de lecture : portail d'attente, jamais l'inscription | vert | Même fichier, groupe « scénario 2 » |
| 3 | Inscription publique bornée à deux rôles et à `pending_kyc` | vert | `supabase/tests/scenarios_etape3.sql`, S3a à S3d |
| 4 | L'enseignant dépose sa pièce | vert | S4, S4b, S4c, sous RLS réelle |
| 5 | Genre du lecteur KYC inconnu : refus explicite | vert | S5a à S5d |
| 6 | Tablette partagée entre deux enfants | vert | S6 |
| 7 | Troisième appareil refusé par la base | vert | S7a, plus S7b sur la réactivation |
| 8 | Code d'appairage expiré ou consommé : refusé | vert | S8a, S8b, S8c |
| 9 | Le code personnel de l'enfant ne part jamais au réseau | vert | `test/appairage/code_local_test.dart` : aucune ligne d'appel réseau de `lib/` ne mentionne le vocabulaire du code, et aucun service ne déclare de paramètre pour le recevoir |
| 10 | Portail d'attente, quatre états | vert | `test/features/attente_test.dart` |
| 11 | Bouton d'ajout absent à la limite, jamais en échec | vert | `test/features/appareils_test.dart` |
| 12 | Toujours une issue « Autre » | vert | `test/features/inscription_test.dart`, la carte « Autre » du rôle mène quelque part sans rien fabriquer |

Les scénarios SQL tournent sur un Postgres 17 nu, avec le stub `auth` versionné
dans `supabase/tests/stub_auth.sql`, et la CI les rejoue à chaque pull request.
Trente-six contrôles, tous verts au 6 septembre 2026.

**Les douze scénarios sont verts.** C'est la différence avec l'étape 2, dont le
septième restait non mesuré : ici, aucun scénario ne dépend d'un écran qui
n'existe pas encore.

## Ce que l'étape 3 ne fait pas, et pourquoi

| Point | État | Raison |
| :--- | :--- | :--- |
| Démarrage à froid sous 1,5 s | toujours non mesuré | Ni l'étape 2 ni l'étape 3 n'ont d'écran métier à charger. Un portail d'attente ne dit rien du produit. Premier candidat honnête : `ELV-02`, étape 4 |
| Lecture du QR par la caméra | non fait | Le bloc n'est pas rendu plutôt que rendu inerte. Le chemin par le code fonctionne partout (ADR-016) |
| Fonctions Edge déployées | non | L'étape D est ouverte : elles sont versionnées, elles n'ont jamais tourné, et le dire vaut mieux que de les compter vertes |
| Import des comptes migrés | non | `provisional_active` n'existe que par un import déclenché par l'administration, à partir d'un fichier que l'opérateur n'a pas fourni |
| Photo réelle sur les tuiles d'enfant | repli sur initiales | L'URL signée arrive avec `TUT-05`, à l'étape 4. Le repli est déjà celui de l'ADR-012, jamais une icône d'erreur |

## Pièges rencontrés, à ne pas repayer

Les pièges de poste hérités de l'étape 2 restent valables : voir
`etape-2-journal.md`, notamment le magasin de racines qui ne fait pas confiance à
`github.com` et qui fait échouer tout `dart run`.

### Le journal d'audit fuyait par sa partition

`audit_logs` est partitionnée. `alter table ... enable row level security` de
l'étape 1 ne protège **que le parent** : une partition porte sa propre RLS, et
`audit_logs_default` n'en avait aucune, alors que les droits par défaut de
Supabase l'accordent à `authenticated`.

Mesuré sur Postgres 17, pas déduit : un tuteur lit **0 ligne** par
`public.audit_logs` et **24** par `public.audit_logs_default`, dont chaque
consultation de dossier KYC avec le nom du lecteur. L'insertion de fausses
lignes était possible par le même chemin, les déclencheurs d'immuabilité ne
couvrant que la modification et la suppression.

Corrigé en activant la RLS sur la partition **sans y poser de policy** : une
requête sur le parent applique les policies du parent et ignore celles des
partitions, donc les lectures légitimes passent toujours et l'accès direct se
heurte au refus par défaut. `attacher_partition_audit()` est ajoutée pour que la
tâche mensuelle ne puisse pas réintroduire l'oubli.

**Leçon générale : activer la RLS sur une table partitionnée ne protège pas ses
partitions.** Le contrôle « aucune table sans RLS » doit compter les `relkind`
`r` **et** `p`, sinon il rate exactement ce cas.

### PL/pgSQL confond une colonne et un paramètre de sortie

`consommer_code_appairage` renvoie une colonne `profile_id`, qui est aussi une
colonne de `devices`. La clause `on conflict (profile_id, ...)` est une clause
d'inférence, donc une expression : PL/pgSQL y substitue ses variables et échoue
sur `column reference "profile_id" is ambiguous`. Le conflit se désigne par le
**nom de la contrainte**, pas par ses colonnes.

### Le refus doit précéder la journalisation, pas la suivre

Première écriture de `read_kyc_documents()` : journaliser, puis refuser si le
genre du lecteur est inconnu. Une exception annule la transaction, donc la trace
de la lecture était écrite puis effacée. On refuse d'abord, on journalise ce qui
va réellement sortir.

### Un message d'erreur qui n'existait pas à l'écran

`surfaceAlert` est une **paire** dont la couleur de texte est le blanc, prévue
pour un fond rouge. Écrit sur la page avec `surfaceAlert.applyTo(...)`, un
message d'erreur sortait donc en blanc sur `#F1E3E4`, mesuré à **1,19:1**.
`PinPad` le faisait depuis l'étape 2 : le « Ce code ne correspond pas » d'un
enfant de six ans était présent dans l'arbre de widgets et absent de l'écran.

La palette gagne l'encre `textOnLightAlert`, et deux tests figent le piège
plutôt que sa seule correction : l'un vérifie que l'encre passe 4,5:1, l'autre
que la couleur de texte de `surfaceAlert` échoue bien sur le fond général, ce
qui documente pourquoi le jeton existe.

**Leçon : une paire dit sur quoi elle s'écrit.** L'employer à l'envers passe la
compilation, passe la relecture, et ne se voit qu'à l'écran.

### Le genre d'un dossier ne peut pas venir du client

Première version : l'écran de dépôt envoyait le genre avec la pièce. Or ce
champ décide **quel membre du personnel pourra l'ouvrir** (audit 1.3) : le
laisser venir du client revient à confier au déposant le choix de qui le
regarde. Un déclencheur de la base l'écrase désormais par celui du profil
concerné, et refuse le dépôt quand ce genre est inconnu plutôt que de créer un
dossier que personne ne saura classer. Le paramètre a disparu de l'interface
Dart : ce qui ne peut pas être envoyé ne peut pas être forgé.

`0004` a été corrigée sur place plutôt que complétée par une `0005`. C'est
volontaire et borné : cette migration n'a **jamais été appliquée nulle part**,
l'étape D restant ouverte et le projet n'ayant jamais été lié. La règle
« migrations en avant, jamais de reprise » s'applique à ce qui a tourné.

### Ce que le code personnel de l'enfant protège, et ce qu'il ne protège pas

À dire précisément, sinon la mesure passe pour plus forte qu'elle n'est. Le code
à quatre chiffres empêche **un frère ou une sœur d'ouvrir le profil d'un autre
enfant sur la tablette du salon**, ce qui est le risque réel du produit. Il
n'empêche rien contre quelqu'un qui obtient le contenu du coffre du système :
dix mille combinaisons s'essaient instantanément, quelle que soit la fonction
d'empreinte. La vraie barrière est le jeton d'appareil, émis par le serveur,
révocable par le tuteur, et la RLS derrière lui.

Le code est **créé sur l'appareil** juste après l'appairage, en présence du
tuteur qui vient de montrer le code à six caractères. Il n'est donc pas
réinitialisable à distance : le tuteur révoque l'appareil et le réappaire. C'est
la conséquence directe de « le code ne quitte jamais l'appareil », et elle vaut
mieux qu'un canal de réinitialisation qui ferait exactement ce que l'ADR-005
interdit.

### Le jeton survit-il à la révocation

Première écriture de `revoquer_appareil()` : poser `revoked_at` et s'arrêter là.
Un appareil révoqué dont le jeton reste en base resterait utilisable jusqu'à ce
que quelqu'un pense à le relire. La fonction efface donc `token_hash` dans le
même mouvement, et le scénario de test le vérifie explicitement.

### Filtrer un `AsyncValue` par son type d'exécution est faux sous Riverpod 3

Un écran affichait son état d'erreur une fois sur deux. Mesuré plutôt que
deviné, avec un test jetable qui imprime l'état réel :

```
type=AsyncLoading<int>  hasError=true  err=MonException  match=autre
```

**Riverpod 3 relance automatiquement un provider en échec.** L'état repasse donc
par `AsyncLoading` en conservant `hasError`, et un `switch` sur
`AsyncError<T>()` ne matche plus. Le rendu dépendait de l'instant où la frame
tombait, ce qui donne un écran correct en développement et faux en production,
ou l'inverse.

**Règle : lire `hasValue`, `hasError` et `isLoading`, jamais le type
d'exécution.** Les deux écrans concernés, `AttentePage` et `DossiersPage`, sont
corrigés.

### Un bouton dont l'état dépend d'un champ qu'il n'écoute pas

Le bouton de refus de `ADM-02` restait inerte alors que le motif était saisi :
son état se calcule depuis un `TextEditingController`, mais rien ne
reconstruisait le widget à la frappe. Un `onChanged` manquant ne casse rien de
visible, il rend juste une action impossible. C'est le genre de défaut qu'un
test de bout en bout attrape et qu'une relecture laisse passer.

### Le build Windows échoue sur un composant absent de Visual Studio

```
flutter_secure_storage_windows_plugin.cpp(6,10): error C1083:
Impossible d'ouvrir le fichier include: 'atlstr.h'
```

Ce n'est pas un défaut du code, et ce n'est pas nouveau : `flutter_secure_storage`
est une dépendance de l'étape 2, et le build Windows n'avait jamais été lancé sur
ce poste. Visual Studio Build Tools 2022 est bien installé, mais **sans le
composant « C++ ATL for latest v143 build tools »**. Les runners `windows-latest`
de la CI l'ont, eux.

Bonne nouvelle en passant : le mode développeur Windows, que le journal de
l'étape 2 signalait comme désactivé, ne bloque plus. Les liens symboliques des
greffons se créent, la compilation va jusqu'au code natif.

`flutter doctor` confirme aussi, de son côté, le défaut de confiance TLS déjà
consigné à l'étape 2 :

```
[!] Network resources
    X A cryptographic error occurred while checking "https://github.com/"
```

### Le build Android échoue sur un nom de dossier du SDK

```
Could not determine the dependencies of task
  ':flutter_secure_storage:compileDebugJavaWithJavac'.
> Failed to find target with hash string 'android-37' in:
  C:\Users\dell\AppData\Local\Android\Sdk
```

Le SDK a installé la plateforme dans `platforms\android-37.0`, alors que Gradle
la cherche sous `android-37`. C'est une lacune d'environnement, pas de code, et
elle ne vient pas des dépendances ajoutées à l'étape 3 : la tâche qui échoue est
celle de `flutter_secure_storage`, une dépendance de l'étape 2, et le message
dit que **la cible entière** est introuvable, donc n'importe quel greffon aurait
échoué de la même façon. `file_picker`, ajouté à l'étape 3, s'était résolu sans
incident jusque-là.

Marche à suivre côté poste, à faire par l'opérateur plutôt qu'en aveugle depuis
une session d'agent, puisque cela touche l'installation du SDK :
`sdkmanager "platforms;android-37"`, ou épingler `compileSdk` à 36. **Ne pas
épingler `compileSdk` uniquement pour contourner ce poste** : ce serait modifier
la cible de compilation de tout le monde pour un dossier mal nommé sur une seule
machine. La CI compile sur un SDK propre et tranchera.

### Risque à vérifier quand l'étape D sera posée

`0001` fait `create extension if not exists pgcrypto` sans schéma, et appelle
`public.digest`. Sur un projet Supabase où pgcrypto est déjà installée dans le
schéma `extensions`, le `if not exists` ne fait rien et `public.digest` n'existe
pas : `0001` échouerait à la première application réelle. `0004` suit la même
convention, volontairement, pour qu'il n'y ait qu'un seul problème à corriger et
qu'une seule correction à faire. **À vérifier au premier `supabase db push`.**
