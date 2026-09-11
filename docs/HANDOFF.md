# HANDOFF — à lire en premier, avant toute action

> Dernière passation : **11 septembre 2026, deuxième session**. Le **lot B0**
> est fait, vérifié et poussé sur `main`. Les lots **T2** (durcir le langage)
> et **R0** (tunnel d'entrée) sont codés et commités **localement**, mais
> **non poussés** : ni `flutter test` ni `tool/verifier_jetons.dart` n'ont pu
> tourner sur ce poste pour les vérifier, dans les deux sessions du 11
> septembre (détail section 0 quater et 0 quinquies) — le blocage TLS de
> `github.com` sur ce poste est confirmé **persistant d'une session à
> l'autre**, pas ponctuel (`curl.exe` échoue aussi, `SEC_E_UNTRUSTED_ROOT` :
> c'est le magasin de certificats du poste, pas le réseau). `main` se déploie
> automatiquement en production à chaque push : la décision de pousser un lot
> non vérifié par les tests revient à l'opérateur, pas à l'agent.
> **Avant tout code neuf** : relancer `flutter test` et
> `dart run tool/verifier_jetons.dart`. S'ils passent sur les deux commits
> locaux (`git log --oneline -3` les montre, ni l'un ni l'autre n'est sur le
> serveur), les pousser et continuer au lot **T3**. S'ils échouent encore
> avec `CERTIFICATE_VERIFY_FAILED` ou `SEC_E_UNTRUSTED_ROOT`, c'est le poste,
> pas le lot : ne pas boucler dessus, le signaler et décider avec
> l'opérateur — un correctif possible (mise à jour du magasin de certificats
> racine Windows, ou proxy TLS d'entreprise à investiguer) dépasse ce qu'un
> agent doit changer seul sur la configuration système du poste.
> Dernier commit **poussé** de `main` : celui de B0. `git log --oneline -3`
> peut nommer deux commits locaux, T2 puis R0, en avance sur `origin/main`.

## 0. Ce qui a changé le 7 septembre au soir : la refonte UX/UI

L'opérateur a jugé le premier rendu visuel daté, et a demandé qu'on **arrête
d'ajouter des écrans pour poser d'abord un langage**. C'est fait, en
documentation : **`docs/design/`**, neuf fichiers, plus l'**ADR-018** dans
`decisions.md` et une réécriture de `docs/produit/design-tokens.md`.

Trois conséquences immédiates pour vous :

1. **`docs/design/README.md` se lit avant d'ouvrir un fichier d'écran.** C'est la
   constitution : hiérarchie des sources de vérité, les huit documents, les
   interdits, et surtout la liste de ce que la note de refonte demandait **et qui
   existe déjà** — plusieurs points y sont tranchés dans l'autre sens, ne les
   « corrigez » pas.
2. **Aucun écran ne s'implémente s'il n'est pas dans
   `docs/design/08-catalogue-ecrans.md`.**
3. **Le tableau de jetons d'`etape-2-core-flutter.md` §1 est périmé.** La source
   unique des valeurs est `docs/produit/design-tokens.md`.

### 0 bis. Le lot T est fait : le code porte les nouveaux jetons

Le thème a été remplacé le 7 septembre. Compte rendu complet dans
`docs/architecture/etape-2-journal.md`, section « Refonte UX/UI, lot T ».

Ce que ça change pour vous, en quatre points :

1. **Le vocabulaire des jetons a changé, et l'ancien est refusé par l'outil.**
   `surfaceBase`, `borderDefault`, `textOnLightAccent`, `textOnLightAlert`,
   `NotoSans` et `VarelaRound` font échouer `verifier_jetons.dart`. La
   correspondance est dans `design-tokens.md` §1.8.
2. **Trois nouveaux fichiers de thème** : `app_radius.dart`,
   `app_elevation.dart`, `app_mouvement.dart`. Un rayon, une ombre, une durée
   d'animation ou une courbe posés ailleurs sont refusés.
3. **Le produit a le bon vocabulaire, pas encore la bonne profondeur.** Les
   composants ont été renommés, pas repris : une tuile Bento est toujours posée
   sur `surfaceCanvas` au lieu de `surfaceRaised`, et rien ne porte encore
   d'ombre. C'est le **lot C** qui reprend les usages, et c'est voulu.
4. **Deux chiffres de `design-tokens.md` étaient faux** et ont été corrigés par
   la mesure : blanc sur le fond général vaut 1,10 et non 1,19, et l'axe `opsz`
   de Bricolage Grotesque a pour défaut 96 et non 14. Les valeurs sont
   désormais rejouées par les tests : le document ne peut plus dériver seul.

### 0 ter. Le rendu déployé jugé « plus nul que du générique » : la Bible V2 et le lot B0

Le 11 septembre 2026, l'opérateur a vu le rendu mobile déployé (build de `main`
post-lot R3 poussé sur `rewayah-academy.vercel.app`) et l'a jugé pire que le
générique habituel. Il a remis une **deuxième** Bible frontend, plus stricte et
plus complète que la note du 7 septembre, avec l'instruction explicite qu'elle
ne se redonnera pas une troisième fois.

**Trois causes mesurées dans le code** (pas seulement une impression) :

1. **Le tunnel d'entrée n'a jamais été repris.** `connexion_page.dart` montait
   (avant B0, toujours vrai après B0 : B0 ne touche à aucun écran) un
   `Scaffold` nu — pas de `PageShell`, pas de carte, pas d'ombre, pas de marque.
   C'est le seul écran visible sans compte : tout ce que l'opérateur a vu.
2. **Le bouton `ActionPrincipale` désactivé ressemblait à une panne** : peint
   `surfaceSunken` + `inkMuted`, il pesait moins que les boutons secondaires à
   contour. Toujours vrai après B0.
3. **Le langage visuel était trop timide** : ombres à 5 % d'opacité,
   `borderHairline` à 1,20:1, les trois surfaces dans 4 % de clarté. Toujours
   vrai après B0.

**Ce que B0 a fait, le 11 septembre : rendre la Bible permanente, sans toucher
à un seul pixel d'écran.** Trois couches, pour qu'elle survive au changement de
session ET au changement d'outil (OpenCode, Hermes) :

1. **`docs/design/00-bible-frontend-v2.md`** — le texte intégral, copié sans
   modification, adopté par **ADR-019**. `docs/design/README.md` §4 BIS porte
   la table de correspondance chapitre par chapitre : ce qui est déjà tenu
   (souvent mieux qu'exigé, via `verifier_jetons.dart`), ce qui est tranché
   autrement pour une raison écrite (deux dérogations dans ADR-019), ce qui
   reste un écart et son lot.
2. **Trois chapitres absents du corpus, ajoutés** : la matrice de décision de
   conteneur dans `02-regles-ux.md` §11, le zoning physique en cinq zones dans
   `05-regles-responsive.md` §9, la classification état métier/UI/préférence
   dans `03-architecture-information.md` §8.
3. **Trois règles neuves dans `tool/verifier_jetons.dart`**, chacune prouvée en
   la faisant échouer sur un fichier piège avant d'être acquise (95 fichiers
   vérifiés, méthode déjà utilisée pour les 26 règles précédentes) :
   - `direction-non-geree` — a trouvé et fait corriger **six** occurrences
     réelles de `left`/`right` codés en dur (pas seulement les deux repérées à
     l'audit initial) : `grille_semaine.dart`, `creneaux_page.dart` (deux
     endroits différents), `admin_demandes/demandes_page.dart`,
     `eleve_connexion_page.dart`, `reglages_enfant_page.dart`. Trois d'entre
     elles partagent le même motif de padding de feuille de bas d'écran copié
     trois fois — une dette de duplication notée mais pas traitée ici, hors
     scope Bible ;
   - `page-sans-coquille` — retient une liste **nominative et temporaire** de
     douze écrans encore à l'état brut (cinq pour le lot R0, sept pour R4),
     documentée dans le fichier lui-même. Chaque entrée doit se retirer au lot
     qui reprend vraiment l'écran, jamais avant ;
   - `tag-conformite` — vérifie que tout tag `[XXX]` en début de ligne de
     commentaire appartient au vocabulaire fermé de `lib/CLAUDE.md`
     (`[M3-COLOR]`, `[A11Y]`, `[RESPONSIVE]`, `[QURAN-STAGE]`). Anchré sur la
     ligne entière pour ne pas confondre un tag avec une classe de caractères
     de `RegExp` telle que `'[A-Z2-9]'`, qui l'aurait fait échouer sur du code
     parfaitement sain sans cette précaution.
4. **`docs/AGENT_HANDOFF.md`** créé : le même point d'entrée pour OpenCode et
   Hermes, avec le gabarit de prompt de reprise, pour que la Bible s'applique
   aux trois outils de l'écosystème et pas seulement à Claude Code.

⚠ **Un écart neuf, découvert pendant B0, pas dans l'audit initial** : le lot
`journee_page.dart` (ENS-02, déjà « repris » au lot R3) contenait encore un
`Scaffold` nu pour son état de chargement initial (`monId == null`). Corrigé
dans ce même lot (`PageShell` partout), sans quoi la règle `page-sans-coquille`
aurait dû l'exempter à tort. Un écran marqué « repris » qui régresse plus tard
sur cette règle est une régression au sens de la Bible §51, pas une réouverture
de discussion sur l'exemption.

### 0 quater. Le lot T2 : durcir le langage, commité localement, non poussé

Cause n3 mesurée du rejet du 11 septembre (ombres à 5 %, bordures décoratives
à 1,20:1 et 1,45:1) et cause n2 (bouton `ActionPrincipale` désactivé qui pesait
moins qu'un secondaire). Les deux sont corrigées dans le code, mais ce lot
n'est **pas vérifié par les tests** et **pas poussé** — voir l'avertissement en
tête de fichier.

**Ce qui a changé, et pourquoi ces valeurs précises :**

1. **Ombres** (`app_elevation.dart`) : niveau1 0,05/0,05 → 0,10/0,09, niveau2
   0,05/0,08 → 0,08/0,14, niveau3 0,14 → 0,22. La teinte de l'ombre (`#3A302A`)
   ne change pas.
2. **Bordures décoratives** (`app_palette.dart`) : `borderHairline`
   `#E7DFD8` → `#DCD2C8` (1,20:1 → 1,36:1 sur le crème), `borderResting`
   `#D6CBC3` → `#C9BCB1` (1,45:1 → 1,69:1). **Les trois surfaces neutres ne
   bougent pas** — décision mesurée, pas oubliée : le moindre assombrissement
   de `surfaceSunken` fait chuter `borderStrong` sous 3:1 sur cette surface
   (2,96 dès `#ECE4DA`, un cran à peine plus sombre), qui n'avait déjà que
   3,21 de marge, la plus fine des trois. Chiffré avant d'être écarté.
3. **Focus des champs** (`app_theme.dart`) : passait par `surfacePrimary`
   (violet) à 2px, passe par `borderStrong` à 3px. `borderStrong` est déjà
   documenté dans `app_palette.dart` comme *« la seule bordure porteuse de
   sens : sélection, focus, bord de tableau »* — l'implémentation ne suivait
   pas encore sa propre documentation. `focusedErrorBorder` passe aussi à 3px,
   par cohérence. `disabledBorder` ajouté (`borderHairline`), absent avant :
   un champ désactivé et un champ au repos étaient indiscernables.
4. **`ActionPrincipale` désactivée** (`action_principale.dart`) : peignait
   `surfaceSunken` + `inkMuted` + `borderResting` (2px), donc un fond presque
   invisible sur le fond général (1,06:1 d'écart) et le filet le plus faible
   de la rampe — plus léger qu'un bouton secondaire au repos. Peint
   maintenant `surfaceRaised` (blanc) + `inkMuted` + `borderStrong` (3px,
   plus épais que le contour 2px d'un secondaire) : la forme reste visible et
   pèse plus, seule l'encre dit que l'action attend une condition. Ce
   traitement s'applique aux quatre niveaux d'action quand ils sont
   désactivés, pas seulement au principal — c'était déjà le cas avant ce lot.
5. **Tests mis à jour en conséquence**, dans `test/theme/contraste_test.dart`
   (nouvelles valeurs de bordures, le test de focus vérifie `borderStrong` et
   non plus `surfacePrimary`, un groupe neuf vérifie `inkMuted` sur
   `surfaceRaised` et que le filet du désactivé dépasse celui du repos) et
   `test/theme/elevation_test.dart` (plafond d'opacité remonté de 0,2 à 0,3
   pour laisser passer le niveau3 à 0,22). **Ces fichiers n'ont pas pu tourner
   pour confirmer qu'ils passent réellement** — voir l'avertissement en tête.
6. `docs/produit/design-tokens.md` sections 1.3 et 9 mises à jour avec les
   nouvelles valeurs et leur justification.

**Non fait dans ce lot**, contrairement à l'intention initiale, et pour la
raison ci-dessus : élargir l'écart de clarté entre les trois surfaces. La
route `/_galerie` était déjà correctement gardée par `Env.galerieActive`
(faux par défaut), rien à faire de ce côté.

### 0 quinquies. Le lot R0 : le tunnel d'entrée, commité localement, non poussé

Causes n1 et n2 mesurées du rejet du 11 septembre (`connexion_page.dart`
montait un `Scaffold` nu, seul écran visible sans compte ; le bouton
`ActionPrincipale` désactivé du lot T2 corrige déjà la cause n2 par ailleurs).
Six écrans de la zone Accès reprennent le même défaut, et sont tous corrigés
dans le même lot, commit local **`Lot R0 : le tunnel d'entree`**, au-dessus du
commit local de T2, jamais poussé — même raison que T2, voir l'avertissement
en tête de fichier.

**Ce qui a changé :**

1. **Nouveau composant partagé `MarquePage`**
   (`lib/core/widgets/marque_page.dart`) : le nom du produit seul, en
   `inkAccent`, sur le fond général. **Aucun asset de logo n'existe dans le
   dépôt** (`assets/` vérifié) : la marque est un texte, via la clé slang
   `commun.marque`, en attendant qu'un logo existe. Précède la carte sur les
   six écrans repris.
2. **Six écrans passent de `Scaffold` nu à `PageShell`, contenu posé sur
   `AppCard`** : `connexion_page.dart` (`TUT-00`), `eleve_connexion_page.dart`
   (`ELV-01`), `attente_page.dart` (`TUT-00b`), `signature_page.dart`
   (`AccusePage` = `TUT-00c/a`, `ContratPage` = `TUT-00c/b`),
   `depot_piece_page.dart` (`TUT-00c/c`). Les trois derniers avaient une zone
   d'action réimplémentée à la main (`Padding` + `Column` + message d'erreur
   sous un `ListView`) : elle passe par la prise `actions:` de `PageShell`,
   exactement son rôle.
3. **`tool/verifier_jetons.dart`** : les cinq entrées R0 de
   `_ecransEnAttenteDeCoquille` retirées (règle `page-sans-coquille`), les
   sept entrées R4 restent.
4. **Sept fiches manquantes écrites** dans `docs/design/08-catalogue-ecrans.md`
   section 6 : `TUT-00`, `ELV-01`, `TUT-00c`, `TUT-00b`, `TUT-00c/a`,
   `TUT-00c/b`, `TUT-00c/c`, à partir du code existant. `TUT-00c`
   (`inscription_page.dart`) n'a pas changé de code : il passait déjà par
   `PageParcours`, seule sa fiche manquait.
5. **`assets/i18n/fr.i18n.json`** : clé `commun.marque` ajoutée. **Ajoutée à
   la main aussi dans `lib/core/i18n/strings.g.dart` et
   `strings_fr.g.dart`** (getter et entrée de la flat map) : `dart run slang`
   est bloqué par le même TLS que `flutter test` (tout `dart run` résout les
   hooks natifs de tout le graphe de dépendances, `sqlite3` y compris, même
   pour un script qui n'y touche pas). `dart analyze --fatal-infos` reste
   propre après l'édition manuelle ; non rejoué par `dart run slang` faute de
   pouvoir le lancer.

**Dette assumée, quatrième occurrence** : le tirage-pour-rafraîchir de
`attente_page.dart` (`RefreshIndicator` sur `etatDossierProvider`) disparaît,
même sort et même raison que sur `TUT-01`, `ENS-02` et `ADM-01` (fiches
`08-catalogue-ecrans.md`) — un `RefreshIndicator` autour d'un `ListView` a
besoin d'être l'enfant direct d'un `Expanded` pour ne pas planter en hauteur
non bornée, et `PageShell` ne donne pas cette garantie à son `child`. Le
bouton « réessayer » de l'état d'erreur reste le seul moyen de relire le
dossier avant le prochain démarrage.

**Vérification tentée, pas obtenue** : `flutter test` et
`dart run tool/verifier_jetons.dart` bloquent avec le même
`CERTIFICATE_VERIFY_FAILED` que la session précédente. `curl.exe`, sans
rapport avec Dart, échoue aussi sur la même URL GitHub avec
`SEC_E_UNTRUSTED_ROOT` : confirmation indépendante que c'est le magasin de
certificats racine du poste, pas un blocage propre à l'outillage Flutter ni
un incident réseau ponctuel. **Vérification visuelle de substitution** :
`flutter build web --release` compile (le hook natif `sqlite3` ne s'exécute
pas pour la cible web), servi en local et ouvert dans Chrome avec une
configuration `dart_define.json` de test jetable (jamais commitée, `git
status` le confirme) — `TUT-00` s'affiche exactement comme conçu : marque
violette, carte blanche à filet et ombre visibles, boutons contournés. Capture
prise à la résolution native de l'outil de capture de cette session (l'outil
n'a pas honoré les demandes de redimensionnement à 390×844), pas une preuve
au format demandé mais une preuve réelle d'exécution, au-delà de
`dart analyze`.

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
| **L10** | **Vérifications de fin d'étape, documentation, `PROGRESS.md`** | **toujours à faire** |

⚠ **L10 n'est pas le point de reprise, contrairement à ce que disait cette
page.** L'opérateur a demandé le lot T de la refonte avant lui, et le lot T est
fait. L10 reste ouvert, et il a perdu une partie de son contenu au passage : ses
cinq contrôles ont été rejoués le 7 septembre en clôture du lot T, et leurs
chiffres sont en section 5. Ce qui lui reste, c'est `PROGRESS.md` et la relecture
des dix-sept scénarios, décrits en section 4. Il peut se faire à tout moment,
avant ou après le lot C.

Le démarrage à froid, scénario 14, **n'est pas mesurable sur ce poste** : aucune
cible ne se construit ni ne se lance. Ce n'est pas du travail en retard, c'est
une question d'équipement, détaillée dans le journal et dans `PROGRESS.md`.

## 3. Quoi lire, dans cet ordre, et rien d'autre

Si vous reprenez **L10** (vérifications de fin d'étape 4) :

1. `docs/architecture/etape-4-journal.md` — où en est le code, ce que valent les
   mesures, et les pièges déjà payés. **Le plus important des trois.**
2. `docs/architecture/etape-4-dashboards.md` — la spécification : ADR-017, les
   neuf défauts corrigés, les douze invariants, les écrans, les 17 scénarios.
3. `lib/CLAUDE.md` — les règles du code, qui font échouer la CI quand on les
   ignore.

Si vous attaquez la **refonte** (lots C puis R) :

1. `docs/design/README.md` — la constitution, sa section 7, qui dit ce qui est
   déjà tranché, et sa section 9, qui dit ce que le lot T a laissé au lot C.
2. `docs/produit/design-tokens.md` — toutes les valeurs, toutes mesurées, toutes
   rejouées par les tests.
3. `docs/architecture/etape-2-journal.md`, section « Refonte UX/UI, lot T » — ce
   que le thème contient maintenant, et les pièges déjà payés.
4. `docs/design/01-systeme-visuel.md` puis `07-catalogue-composants.md` puis
   `08-catalogue-ecrans.md`.
5. `lib/CLAUDE.md`.

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

## 4 bis. Puis la refonte, avant l'étape 5

L'ordre est décidé (ADR-018) : l'étape 5 attend, trois lots passent avant. Un lot
par commit, comme toujours.

| Lot | Contenu | Écrans touchés | État |
| :-- | :--- | :--- | :-: |
| **T** | Jetons, thème, typographie, mouvement. Palette crème et rampes, trois bordures, rayons, ombres, crénage, durées et courbes, échelle d'espacement étendue, et les nouvelles règles de `verifier_jetons.dart` | aucun repris, 29 renommés | **fait** |
| **C** | Les douze composants P0 de `07-catalogue-composants.md`, plus la reprise des onze existants, plus la galerie qui montre tous leurs états. Audit de fin de lot en six tranches, 8 constats corrigés. Compte rendu : `etape-2-journal.md`, « Refonte UX/UI, lot C » | aucun | **fait** |
| **R** | Reprise dans cet ordre : `ELV-02`, puis `TUT-01`, puis `ENS-02` et `ADM-01`, puis le reste | quatre d'abord | **à faire, commencer ici** |

**Le lot T se faisait en premier et entièrement**, puis le lot C : reprendre un
écran avant les jetons puis avant les composants aurait obligé à le reprendre
trois fois.

Les deux polices sont désormais **dans le dépôt**, avec leur licence OFL :
`assets/fonts/BricolageGrotesque-Variable.ttf` et `InstrumentSans-Variable.ttf`.
Il n'y a plus rien à récupérer. Si un jour il faut y revenir, l'adresse qui
marche est `fonts.google.com/download/list?family=...` : les deux autres pistes
évidentes sont des impasses, détaillées dans `etape-2-journal.md`.

Ce que le sous-lot R4 trouvera en arrivant :

- les quatre premiers écrans et la coquille de navigation portent le langage
  des lots T/C : `PageShell`, `TimelineRow`, `StatTile`, `SignalRow`,
  `ChildCard`, `StatusPill`, et les `BentoTile` posés sur `surfaceRaised` ;
- le routeur tient quatre `StatefulShellRoute` (élève, tuteur, enseignant,
  admin) et une fonction pure `destinationsPour(role, mode)` testée — le mode
  enfant ne propose aucune barre (ADR-009), le contrôleur et le comptable non
  plus ;
- deux écarts à trancher sont consignés dans les fiches `ENS-02` / `ADM-01`
  (six compteurs contre cinq annoncés, ordre « chiffres d'abord »), et deux
  imprécisions de `07-catalogue-composants.md` sont documentées (`GrilleSemaine`
  §1, famille « composant d'état » §4) — les trier avec la reprise de R4 ;
- les écrans restants portent encore l'ancien rendu (`Scaffold` + bandeau, ou
  liste sans coquille) : c'est exactement ce que la rangée R4 reprend.

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

Relevées le 7 septembre 2026, après le lot T de la refonte :

| Contrôle | Valeur | Après L9, pour mémoire |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème | aucun problème |
| `flutter test` | **362 tests**, tous verts | 277 tests |
| `dart run tool/verifier_jetons.dart` | **80 fichiers**, aucune violation | 77 fichiers |
| `scenarios_etape3.sql` | **34 contrôles** verts | 34 |
| `scenarios_etape4.sql` | **39 contrôles** verts | 39 |

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

## 9. Prompt de reprise — vérifier T2 et R0, PUIS le lot T3

À copier tel quel pour démarrer la prochaine session. Cette session a deux
objectifs distincts, dans l'ordre : d'abord lever le doute sur T2 **et** R0
(tous deux déjà codés, commités localement, pas poussés), ensuite seulement
attaquer T3.

```
Rewayah Academy -- depot D:\RA _APP\RA -OFFICIAL-APP, branche main.
Chemins en absolu : Glob ne trouve pas ce depot.

Lis docs/HANDOFF.md en entier (l'en-tete et les sections 0 ter, 0 quater et
0 quinquies), puis decisions.md ADR-019.

ETAPE 1, OBLIGATOIRE AVANT TOUT CODE NEUF : verifier les lots T2 et R0, deja
codes et commites localement (git log --oneline -3 le montre : deux commits
en avance sur origin/main, aucun pousse).
  1. git log --oneline -3, pour confirmer l'etat exact.
  2. dart analyze --fatal-infos (deja vert a la cloture des deux lots).
  3. flutter test -- deux sessions de suite ne l'ont JAMAIS obtenu (le poste
     bloque github.com en TLS pour le hook package:sqlite3 : neuf tentatives
     cumulees, et curl.exe echoue aussi sur la meme URL avec
     SEC_E_UNTRUSTED_ROOT, independamment de Dart). Reessaie une fois. Si ca
     bloque encore de la meme facon, c'est le poste, pas le code : ne boucle
     pas dessus une troisieme session de suite. Signale-le a l'operateur avec
     ces deux preuves (CERTIFICATE_VERIFY_FAILED ET SEC_E_UNTRUSTED_ROOT) et
     demande explicitement s'il veut reparer le magasin de certificats du
     poste, sinon continue avec dart analyze seul comme preuve.
  4. dart run tool/verifier_jetons.dart -- meme punition, meme consigne.
  5. Si les deux passent : ecrase l'avertissement en tete de HANDOFF.md par les
     vrais chiffres, git push origin main (les deux commits), puis seulement
     continue a l'etape 2. Si flutter test echoue pour une VRAIE raison (pas
     le blocage reseau) : ne pousse rien, corrige, ecris ce que tu as trouve.

ETAPE 2, seulement apres l'etape 1 : LOT T3 -- le mode sombre (Bible V2 §7.3,
ADR-019, ecart 23 du registre de decisions.md). Aujourd'hui, AppPalette.claire()
est la seule palette et Brightness.light est code en dur.

Avant de coder : lire ADR-019 (derogation §7.3 : "planifie et ferme au lot T3,
pas laisse ouvert") et l'ecart 23 de decisions.md ("Toutes les mesures de
contraste seront refaites a cette occasion, aucune ne se transpose depuis le
clair") -- aucune valeur de palette sombre n'existe encore nulle part dans le
depot, ce lot les invente ET les mesure, il ne les recopie pas d'un document
existant.

Fin de lot T3 : dart analyze --fatal-infos, flutter test, dart run
tool/verifier_jetons.dart, mise a jour de HANDOFF.md (nouvelle section,
en-tete) et de decisions.md (ecart 23 ferme), commit. Ne pousse que si les
tests tournent et passent reellement -- un lot visuel non verifie ne se
pousse pas sur une branche qui deploie en production a chaque push, decision
qui revient a l'operateur si les tests restent bloques par le poste. Un lot
par session. Ignore la branche refactor-ui-lavender. Termine par le prompt de
reprise du lot R4.
```
