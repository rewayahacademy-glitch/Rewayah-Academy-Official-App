# HANDOFF — à lire en premier, avant toute action

> Dernière passation : **11 septembre 2026, cinquième session**. Les lots
> **B0**, **T2** (durcir le langage), **R0** (tunnel d'entrée), **T3** (mode
> sombre), **R4** (le reste de l'existant, section 0 septies) et **A1**
> (accessibilité, RTL et clavier prouvés par des tests, section 0 octies)
> sont tous les six codés et **poussés sur `main`** (`761db39`). Le lot **R**
> est désormais complet. **Ni `flutter test` ni `tool/verifier_jetons.dart`
> n'ont jamais pu tourner sur ce poste**, pour aucun des six lots : c'est la
> **sixième confirmation
> consécutive** du même blocage TLS de `github.com` (hook `package:sqlite3`),
> `CERTIFICATE_VERIFY_FAILED` côté Dart et `SEC_E_UNTRUSTED_ROOT` côté
> `curl.exe`, preuve indépendante que c'est le magasin de certificats du
> poste, pas le réseau ni un incident ponctuel. **T2, R0, T3 et R4 ont tous
> été poussés malgré cette absence de vérification, sur décision explicite de
> l'opérateur** (accord donné une première fois pour T2/R0 « pour voir en
> direct », reconduit pour T3, puis reconduit une nouvelle fois pour R4 quand
> la question a été reposée) : `dart analyze --fatal-infos` est la seule
> preuve automatique obtenue pour les cinq lots poussés, complétée par une
> vérification visuelle manuelle (`flutter build web`) pour R0 (rendu clair de
> `TUT-00`) et pour T3 (rendu clair seulement, le rendu sombre n'a pas pu être
> vérifié visuellement — détail sections 0 quinquies et 0 sexies). R4 n'a reçu
> aucune vérification visuelle de substitution (l'opérateur avait déjà l'app
> ouverte de son côté). **A1 n'ajoute aucun écran** (seulement des tests, et
> trois faux dans `harnais.dart`) : pas de vérification visuelle de
> substitution nécessaire pour ce lot, `dart analyze --fatal-infos` est la
> seule preuve possible sur ce poste. **A1 poussé sur décision explicite de
> l'opérateur**, même raison que les quatre lots précédents.
> **Priorité de la prochaine session, avant tout code neuf** : faire tourner
> `flutter test` et `dart run tool/verifier_jetons.dart` sur ce qui est
> maintenant en production (B0 à A1), pour combler cette dette de
> vérification qui s'accumule lot après lot — soit en réparant le magasin de
> certificats du poste, soit sur un autre poste, soit avec l'accord explicite
> de l'opérateur pour continuer sans. Ne pas boucler sur le même
> contournement TLS déjà refusé deux fois par le classificateur auto-mode
> cette semaine.
> Dernier commit **poussé** de `main` : celui d'A1 (`761db39`).
> `git log --oneline -3` doit correspondre exactement à `origin/main`.
> Détail du lot R4 : section 0 septies. Deux écarts de conception restent
> ouverts et non tranchés, sur `ADM-01`/`ADM-06` (six compteurs contre cinq
> annoncés, ordre signaux/chiffres) — pas des écrans de R4, voir fiche `ADM-01`
> section 6 de `08-catalogue-ecrans.md`. Détail du lot A1 : section 0 octies.

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

### 0 quater. Le lot T2 : durcir le langage, poussé sans vérification par les tests

Cause n3 mesurée du rejet du 11 septembre (ombres à 5 %, bordures décoratives
à 1,20:1 et 1,45:1) et cause n2 (bouton `ActionPrincipale` désactivé qui pesait
moins qu'un secondaire). Les deux sont corrigées dans le code. Ce lot **n'a
jamais pu être vérifié par `flutter test`** sur ce poste, et a été **poussé
sur `main` malgré cela, sur demande explicite de l'opérateur** — voir
l'avertissement en tête de fichier.

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

### 0 quinquies. Le lot R0 : le tunnel d'entrée, poussé sans vérification par les tests

Causes n1 et n2 mesurées du rejet du 11 septembre (`connexion_page.dart`
montait un `Scaffold` nu, seul écran visible sans compte ; le bouton
`ActionPrincipale` désactivé du lot T2 corrige déjà la cause n2 par ailleurs).
Six écrans de la zone Accès reprennent le même défaut, et sont tous corrigés
dans le même lot, commit **`5f96b84`** (« Lot R0 : le tunnel d'entree »),
au-dessus du commit de T2. **Poussé sur `main` malgré l'absence de
confirmation par `flutter test`**, sur demande explicite de l'opérateur —
même raison que T2, voir l'avertissement en tête de fichier. Une vérification
visuelle de substitution a été faite (voir plus bas) : elle confirme le rendu
de `TUT-00`, pas les autres écrans, et ne remplace pas `flutter test`.

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

### 0 sexies. Le lot T3 : mode sombre, poussé sans vérification par les tests

Écart 23 du registre de `decisions.md` (Bible V2 §7.3, ADR-019). Avant ce
lot, `AppPalette.claire()` était la seule palette et `Brightness.light`
était codé en dur dans `_schemaDepuisPalette`.

Résumé factuel :

1. `AppPalette.sombre()` ajoutée (`lib/core/theme/app_palette.dart`), toutes
   valeurs neuves et mesurées independamment du clair. Détail complet dans
   `docs/produit/design-tokens.md` §12. Les quatre paires pleines et `ombre`
   sont réutilisées telles quelles (couleurs de marque, documenté comme un
   choix) ; `surfaceInverse` s'inverse (crème+noir au lieu de noir+crème).
2. `AppElevation` prend désormais l'ombre en paramètre au lieu de tirer
   silencieusement `AppPalette.claire().ombre` (`app_elevation.dart`). Neuf
   fichiers appelants mis à jour.
3. `AppTheme.pour(mode, brightness)` choisit entre les deux palettes ;
   `lib/app.dart` expose `theme`, `darkTheme`, `ThemeMode.system`. Pas de
   bascule manuelle dans un écran : aucune entrée au catalogue
   `08-catalogue-ecrans.md` pour ça, ce lot ferme le mécanisme, pas une
   préférence utilisateur.
4. `test/theme/contraste_sombre_test.dart` créé, même méthode que
   `contraste_test.dart`. Deux constats notables : `inkFaint` n'a aucune
   surface interdite en sombre (le trou du clair, sur `surfaceSunken`, se
   serait déplacé vers `surfaceRaised` ; fermé par le choix de valeur) ; le
   piège du texte blanc de `surfaceAlert` posé sur la page ne se reproduit
   pas en sombre (16,84 contre 1,10 côté clair).
5. La galerie de composants reste clair seulement : le catalogue
   (`07-catalogue-composants.md` §5) ne liste que cinq axes de vérification,
   pas la luminosité.

Non fait : bascule manuelle clair/sombre dans un écran de réglages ;
vérification visuelle du rendu sombre lui-même (voir plus bas).

Vérification tentée, pas obtenue : `flutter test` et
`dart run tool/verifier_jetons.dart` bloquent avec le même
`CERTIFICATE_VERIFY_FAILED` que les sessions précédentes — quatrième
confirmation du même blocage, voir l'en-tête. Vérification visuelle de
substitution : `flutter build web --release` compile, servi en local et
ouvert dans Chrome — `TUT-00` s'affiche en clair comme au lot R0, sans
régression visible du refactor `AppElevation`. Le rendu sombre lui-même n'a
pas été vérifié visuellement : `prefers-color-scheme` ne se force pas depuis
le JS d'une page, et changer le thème du système d'exploitation du poste
pour ce seul test a été jugé disproportionné. Preuve disponible pour le
sombre : `dart analyze` propre, et les mesures de contraste calculées à la
main hors Dart avant d'être écrites dans le code (même formule WCAG que
`Color.computeLuminance`).

**Poussé sur `main` (`1eb0d30`) malgré l'absence de confirmation par
`flutter test`, sur décision explicite de l'opérateur** — même raison que
T2 et R0, voir l'avertissement en tête de fichier. Le rendu sombre en
production reste donc à vérifier visuellement dès que possible.

### 0 septies. Le lot R4 : le reste de l'existant, reprise de coquille

Dernier sous-lot du lot **R** (`08-catalogue-ecrans.md` section 5) : les six
derniers écrans construits mais pas encore repris par le langage T/C, plus
leurs deux sous-écrans. Le lot **R** est désormais complet. Fiches complètes
dans `08-catalogue-ecrans.md` section 6.

**Ce qui a changé, écran par écran :**

1. **`TUT-02`** (`appareils_page.dart`) : `Scaffold` + `OfflineBanner` +
   `RefreshIndicator` + `ListView` → `PageShell`. Dette assumée : le
   tirage-pour-rafraîchir disparaît, cinquième occurrence après `TUT-00b`,
   `TUT-01`, `ENS-02` et `ADM-01`, même raison à chaque fois (`RefreshIndicator`
   a besoin d'un `Expanded` direct, `PageShell` ne le garantit pas à son
   `child`).
2. **`TUT-02/a`** (`ajouter_enfant_page.dart`) : aucun changement de code, il
   passait déjà par `PageParcours`. Seule sa fiche manquait (même cas que
   `TUT-00c` au lot R0).
3. **`TUT-02/b`** (`appairage_page.dart`) : `Scaffold` + `ListView` →
   `PageShell` ; le bouton de retour, collé en bas à la main dans un `Padding`
   hors `Scaffold`, passe par la prise `actions:` de `PageShell` — même
   correction que les feuilles d'accueil du lot R0.
4. **`TUT-04`** (`disponibilites_page.dart`) : `Scaffold` + `ListView` →
   `PageShell`. Pas de tirage-pour-rafraîchir à perdre ici, il n'y en avait
   pas.
5. **`TUT-05`** (`reglages_enfant_page.dart`) : `Scaffold` + `ListView` →
   `PageShell`. `FeuilleDemandeTuteur` (feuille de bas d'écran) garde son
   `Padding` manuel dupliqué — dette déjà connue depuis le lot B0 (section
   0 ter, point 3), pas traitée ici, hors scope.
6. **`ENS-06`** (`creneaux_page.dart`) : **l'écart mesuré au registre est
   corrigé.** L'écran montait un `DefaultTabController` + `Scaffold` propres,
   `TabBar`/`TabBarView` fixes quel que soit le gabarit. Désormais : sur
   mobile, deux onglets restent (`TabBar` dans `PageShell.entete`) mais
   **sans `TabBarView`** — un `TabBarView` s'appuie sur un `PageView`, qui
   exige une hauteur bornée, et `PageShell` ne borne jamais la hauteur de son
   `child` (c'est la page entière qui défile). Le panneau bascule donc
   directement sur l'index du `TabController`, au prix du balayage au doigt
   entre onglets. Sur tablette, les deux panneaux s'empilent sans onglet ;
   sur desktop, ils sont côte à côte dans une `Row`. `CreneauxPage` passe de
   `ConsumerWidget` à `StatelessWidget`. Les deux onglets internes passent de
   `ListView` à `Column`, même transformation que les autres écrans de ce
   lot.
7. **`ADM-02`** (`dossiers_page.dart`) : `Scaffold` + `switch(AsyncValue)` →
   `PageShell` enveloppant le même `switch`. La zone de verdict (checklist
   puis approuver/refuser) reste délibérément dans le corps défilant, **pas**
   dans `PageShell.actions` : la séquence constat→checklist→verdict doit
   rester lisible de haut en bas en une seule colonne (invariant déjà noté
   `08-catalogue-ecrans.md` section 4, « Constat et jugement séparés »),
   contrairement aux écrans à action unique du lot R0.
8. **`ADM-06`** (`demandes_page.dart`) : même transformation et même raison
   qu'`ADM-02` pour garder le verdict dans le corps. `FeuilleRegle` (feuille
   de bas d'écran) garde aussi son `Padding` manuel dupliqué, même dette que
   `TUT-05`.

`tool/verifier_jetons.dart` : les sept entrées R4 de
`_ecransEnAttenteDeCoquille` (règle `page-sans-coquille`) sont retirées, le
set est désormais vide — le lot R est complet, plus aucun écran de
`lib/features/` n'est exempté de cette règle.

`docs/design/07-catalogue-composants.md` section 1 : la ligne `GrilleSemaine`
disait à tort « sélection en `surfacePrimary` » ; corrigée pour décrire les
vrais états du code (case vide `surfaceSunken`, posée `washAccent`,
survol/pression filet `borderStrong`, jamais d'aplat plein).

**Deux écarts restent ouverts, non traités par ce lot** : les six compteurs
contre cinq annoncés et l'ordre signaux/chiffres d'`ADM-01`/`ADM-06`
(`08-catalogue-ecrans.md` section 6, fiche `ADM-01`, lignes ~608-620). Ce
sont des questions de conception sur un écran déjà repris au lot R3, pas des
écrans de R4 : elles restent à trancher, aucune décision n'a été prise ici.

**Vérification tentée, pas obtenue** — cinquième confirmation consécutive du
même blocage : `flutter test` et `dart run tool/verifier_jetons.dart`
échouent toujours avec `CERTIFICATE_VERIFY_FAILED` sur le hook natif de
`package:sqlite3`. Retenté une fois cette session, comme prescrit, pas plus —
la cause est établie. `dart analyze --fatal-infos` est vert sur l'ensemble du
dépôt après ce lot.

**Commit et push** : poussé sur `main` (`76867a7`), sur décision explicite de
l'opérateur — même raison que T2/R0/T3, voir l'avertissement en tête de
fichier. Confirmé par `git fetch origin main` : `origin/main` correspond.

### 0 octies. Le lot A1 : accessibilité, RTL et clavier prouvés par des tests

Dernier lot de la liste ADR-019 avant N0 (specs étape 5). Écart 24 du
registre de `decisions.md`, fermé.

**Constat inexact corrigé, avant de dire ce qui a été fait** :
`decisions.md` écart 24 (écrit au lot B0) affirmait « aucun test de rendu
arabe ». C'est faux : `test/widgets/catalogue_galerie_test.dart` teste déjà le
RTL et le 200 % depuis le lot C (7 septembre), sur les composants isolés de la
galerie. L'écart réel n'était donc pas « rien n'existe », mais une couverture
incomplète : la galerie ne vérifie que l'absence d'exception (pas que le
miroir RTL est *comportementalement* correct), et ne porte que sur les
composants isolés, jamais sur un écran métier réel avec sa propre mise en
page.

**Ce que ce lot ajoute, trois fichiers neufs plus une extension du
harnais :**

1. **`test/icons/app_icons_rtl_test.dart`** : preuve comportementale, pas
   seulement « ne lève pas ». `AppIcons.chevron` porte `matchTextDirection`
   sur ses deux graisses ; `AppIcons.suivant`, même dessin, ne le porte pas
   (c'est la progression du temps, pas une ligne qui mène ailleurs,
   `06-accessibilite.md` section 5) ; les icônes de média (micro, caméra,
   lecture/pause) ne se miroitent jamais. Une régression qui retirerait
   `matchTextDirection` de `chevron` ne lèverait toujours aucune exception :
   sans ce test, elle serait passée inaperçue indéfiniment.
2. **`test/accessibilite/rtl_echelle_texte_ecrans_test.dart`** : les
   **dix-neuf écrans réels** du catalogue (dix-huit fichiers,
   `signature_page.dart` en portant deux : `AccusePage` et `ContratPage`),
   montés avec leurs propres services factices, rejoués en RTL puis à 200 %
   de taille de texte, sans qu'aucune exception ne soit levée. Les cinq
   écrans marqués « à construire » ou « hors MVP-0 » au catalogue n'existent
   pas encore dans le code : rien à monter avant qu'ils soient écrits.
   **Découverte au passage** : `ELV-01` (`EleveConnexionPage`) n'avait
   **aucun test de widget** dans tout le dépôt, ni ici ni ailleurs. Trois faux
   ajoutés à `harnais.dart` pour le rendre montable en test :
   `FauxProfilsLocaux`, `FauxStockageSecurise`, `FauxServiceEnfant`.
3. **`test/accessibilite/clavier_test.dart`** : trois preuves distinctes.
   - **Ordre de focus** : `Tab` fait passer le focus du champ prénom au champ
     nom sur la page identité de `TUT-00c`, dans l'ordre visuel — pas un ordre
     qui daterait de la construction.
   - **Focus visible** : `app_theme.dart` câble bien `focusedBorder` sur
     `borderStrong` à 3px (lot T2), distinct du repos et du désactivé. C'est
     une vérification du câblage du thème, pas du rendu pixel : creuser plus
     loin (l'`InputDecorator` réellement peint) exigerait d'inspecter des
     objets de rendu internes à Flutter, jugé disproportionné pour la preuve
     recherchée ici.
   - **Échap ferme une surface modale** : `lib/core/widgets/app_bottom_sheet.dart`
     documentait déjà ce comportement comme automatique (« rien à câbler »),
     mais rien ne le rejouait. `AppBottomSheet.ouvrir` est le seul point
     d'entrée des surfaces modales du produit : le prouver une fois à ce
     niveau couvre transitivement `ConfirmDestructive`, `FeuilleDemandeTuteur`
     et `FeuilleRegle`, qui n'en sont que des contenus. Un test dédié confirme
     en plus que `ConfirmDestructive.demander` rend bien `false` sur Échap,
     jamais `true`.

**Non fait, et pourquoi** : les cinq écrans « à construire »/« hors MVP-0 »
(`ADM-05`, `CTR-01`, `ELV-03`/`ENS-03`/`CTR-02`, `ELV-04`, `ENS-04`, `TUT-06`,
`ADM-04`, `ENS-05`, `CPT-01`) ne sont pas testés : ils n'existent pas encore
dans le code, rien n'aurait pu être monté. Le rendu pixel du focus (au-delà du
câblage du thème) n'est pas vérifié : inspecter l'`InputDecorator` peint
exigerait de creuser des objets de rendu internes, jugé disproportionné ici.

**Vérification tentée, pas obtenue** — sixième confirmation consécutive du
même blocage : `flutter test` et `dart run tool/verifier_jetons.dart`
échouent toujours avec `CERTIFICATE_VERIFY_FAILED` sur le hook natif de
`package:sqlite3`. Retenté une fois cette session, comme prescrit, pas plus.
`dart analyze --fatal-infos` est vert sur l'ensemble du dépôt après ce lot.
`tool/verifier_jetons.dart` ne scanne que `lib/` (vérifié en lisant son code,
`Directory('${racine.path}/lib')` dans `main()`) : les fichiers de ce lot,
tous sous `test/`, ne peuvent de toute façon déclencher aucune de ses règles.

**Commit et push** : poussé sur `main` (`761db39`), sur décision explicite de
l'opérateur — même raison que T2/R0/T3/R4, voir l'avertissement en tête de
fichier. Confirmé par `git fetch origin main` : `origin/main` correspond.

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
| **R** | Reprise dans cet ordre : `ELV-02`, puis `TUT-01`, puis `ENS-02` et `ADM-01`, puis le reste | quatre d'abord | **fait le 11 septembre 2026** (R1 à R4, y compris R0 hors ordre initial) |

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

## 9. Prompt de reprise — combler la dette de vérification, PUIS le lot N0

À copier tel quel pour démarrer la prochaine session. **B0, T2, R0, T3, R4 et
A1 sont tous les six poussés sur `main`** (`761db39`). Le lot **R** est
complet, et **A1 (accessibilité, RTL et clavier prouvés par des tests) aussi**
— trois fichiers de test neufs, plus trois faux ajoutés à `harnais.dart`,
aucun écran touché, détail section 0 octies. Aucun des six lots n'a été
confirmé par `flutter test` ni `tool/verifier_jetons.dart` sur ce poste —
sixième confirmation consécutive du même blocage TLS, détail en tête de
fichier et section 0 septies.

```
Rewayah Academy -- depot D:\RA _APP\RA -OFFICIAL-APP, branche main.
Chemins en absolu : Glob ne trouve pas ce depot.

Lis docs/HANDOFF.md en entier (l'en-tete et les sections 0 quater a 0 octies),
puis decisions.md ADR-019 et l'ecart 24.

ETAPE 1, OBLIGATOIRE AVANT TOUT CODE NEUF : B0 a A1 sont tous codes et
pousses (confirme l'etat reel avec git log --oneline -5 et git status,
l'en-tete de HANDOFF.md peut etre legerement en retard sur le depot reel).
Aucun n'a ete confirme par flutter test sur ce poste, six sessions de suite :
  1. git log --oneline -5 et git status, pour confirmer l'etat exact contre
     origin/main.
  2. dart analyze --fatal-infos (deja vert a la cloture des six lots).
  3. flutter test -- SIX sessions de suite ne l'ont JAMAIS obtenu (le
     poste bloque github.com en TLS pour le hook package:sqlite3,
     CERTIFICATE_VERIFY_FAILED ; curl.exe echoue aussi sur la meme URL avec
     SEC_E_UNTRUSTED_ROOT, independamment de Dart -- confirmation
     independante que c'est le magasin de certificats du poste). Reessaie
     UNE fois, pas plus : la cause est deja etablie avec certitude, boucler
     dessus une septieme fois n'apporterait aucune preuve nouvelle. Si ca
     bloque encore de la meme facon, continue directement a l'etape 2 -- ce
     n'est plus une question ouverte, c'est un fait du poste. Note :
     `git push` fonctionne malgre ce blocage (chaine de certificats
     differente de celle de Dart/curl.exe, probablement le cacert.pem de Git
     for Windows) : ce n'est PAS une preuve que le blocage general est leve.
  4. dart run tool/verifier_jetons.dart -- meme punition, meme consigne.
  5. Si les deux passent enfin (poste repare, ou lance ailleurs) : ecrase
     l'avertissement en tete de HANDOFF.md par les vrais chiffres, puis
     continue a l'etape 2. Si l'un des deux echoue pour une VRAIE raison (pas
     le blocage reseau) : c'est une regression EN PRODUCTION possible sur
     l'un des six lots, la signaler immediatement a l'operateur avant toute
     chose.

ETAPE 2, seulement apres l'etape 1 : LOT N0 -- specs de l'etape 5 (ADR-020,
Coran structure, machine a etats de presence). Lot documentaire, aucun ecran
ne se code ici. Cette section ne connait PAS le detail de ce que "lot N0"
recouvre au-dela de son nom : NE PAS EN INVENTER LE CONTENU. Avant d'ecrire
quoi que ce soit :
  1. Chercher dans docs/design/08-catalogue-ecrans.md les ecrans marques
     "a construire, etape 5" (ELV-03, ENS-03, CTR-02) et section 0.19-32 du
     resume README.md (Bible V2 non construite, specifiee ici).
  2. Chercher "N0", "ADR-020" et "Coran structure" dans decisions.md
     (registre de fin de fichier) et PROGRESS.md.
  3. Si rien de precis n'en ressort au-dela de fragments epars : DEMANDER A
     L'OPERATEUR de preciser le perimetre du lot N0 avant d'ecrire le moindre
     document -- ne pas improviser une specification a sa place, meme
     partielle.

Fin de lot N0 (une fois son perimetre confirme) : mise a jour de HANDOFF.md
(nouvelle section, en-tete) et de decisions.md si des ecarts y sont tranches,
commit, decision de push a l'operateur si des tests restent bloques par le
poste. Un lot par session. Ignore la branche refactor-ui-lavender.
```
