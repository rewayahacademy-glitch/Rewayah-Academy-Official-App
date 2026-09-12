# HANDOFF — à lire en premier, avant toute action

> 🟢 **12 septembre 2026, deuxième session — `ADM-05`, l'attribution manuelle,
> est construite.** L'opérateur a demandé de **laisser le fournisseur vidéo de
> côté** et d'avancer ailleurs en attendant : le lot N2 reste donc non
> commencé, et `ADM-05` a été fait hors série. Ce n'est pas un écran de plus :
> **c'était le chaînon manquant du produit.** Sans lui, une affectation ne
> pouvait naître que si un enseignant la demandait dans `ENS-06` ; sans
> affectation, `materialiser_seances()` n'est jamais appelée ; sans séance,
> `ENS-02`, `ELV-02` et `TUT-01` restent vides quoi qu'ait construit l'étape 4.
> Le compteur « Foyers sans enseignant » d'`ADM-01`, qui ne menait nulle part,
> mène maintenant à son geste.
> Livré : migration `0008` (trois fonctions, aucune table, aucune policy
> d'écriture ouverte), `lib/core/matching/service_attribution.dart`,
> `lib/features/admin_attribution/`, **ADR-021**, fiche `ADM-05` au catalogue.
> Mesuré, pas supposé : **`flutter test` 542/542**, `dart analyze` propre,
> jetons **98 fichiers** sans violation, et **97 contrôles SQL** verts
> (34 + 39 + 15 + 9) rejoués ensemble sur `0001`→`0008`.
> ⚠ **Une décision a été prise sans l'opérateur, et elle est réversible** :
> l'administration peut attribuer hors des disponibilités déclarées d'un
> enseignant, **avec motif obligatoire vérifié en base** et journalisation.
> Raison, et la recette pour la défaire en une heure : **ADR-021**, plus les
> questions 25 et 26 du registre.
> ⚠ **`0008` doit être collée à la base réelle, sinon `/admin/attribution`
> affichera une erreur de lecture** au lieu de ses deux listes. Contrairement à
> `0006` et `0007`, celle-ci se voit tout de suite. `MISE-EN-SERVICE.md` §5.3.
>
> 🔴 **12 septembre 2026, première session — le verdict de l'opérateur est
> vérifié, chiffré, et il avait raison.** « L'app est loin d'être fonctionnelle » : mesuré en
> ouvrant la production en session admin, pas déduit. **Onze destinations du
> routeur sur trente rendent `EcranAConstruire`** — dont `ELV-03 / ENS-03`,
> c'est-à-dire la salle de cours elle-même, le produit. Côté admin, deux des
> quatre entrées de navigation (Attribution, Journal) affichent « Cet écran
> arrive à l'étape 3 », et les deux autres sont vides. **Ce n'est pas une
> régression : c'est que l'étape 5 n'était pas commencée.** Le détail écran par
> écran est en section 9.
> ✅ **Le lot N1 est fait le même jour** (`a736a43`) : migration `0007`, le
> Coran structuré, la position de lecture personnelle, la présence dérivée à
> quatorze états. Quinze contrôles verts, non-régression des étapes 3 (34) et
> 4 (39) vérifiée. **Le découpage N0→N7 est confirmé** par l'opérateur.
> ⚠ **Deux actions restent à sa main, et rien n'avance sans elles** : coller
> `0006` **et** `0007` dans l'éditeur SQL du projet `gggmtelinlpseweouyav`
> (`MISE-EN-SERVICE.md` §5, §5.1, §5.2), et promouvoir la build prête en
> production (section 9). `0006` est toujours absente de la base réelle,
> mesuré ce jour par PostgREST.
> ⚠ **Le serveur MCP `supabase` de ce poste pointe sur la base PISI**
> (`riaqzfhdynmtshvbgdvt`), pas sur Rewayah. Ne jamais l'utiliser pour
> appliquer une migration de ce projet.

> Dernière passation : **11 septembre 2026, huitième session — la dette de
> vérification est soldée.** Le lot **L10** (clôture de l'étape 4) est fait :
> section 0 decies. **L'ordre de travail de l'ADR-019 est entièrement épuisé** —
> B0, T2, R0, T3, R4, A1 (les six lots de code) et N0 (documentaire) sont
> poussés.
> ✅ **`flutter test` a enfin tourné, pour la première fois en neuf sessions.**
> Le blocage TLS de `github.com` (hook `package:sqlite3`,
> `CERTIFICATE_VERIFY_FAILED`) **est toujours là et n'a pas été réparé** : il a
> été **contourné** par le `user_define` `source: system` que le paquet
> documente lui-même, posé uniquement dans le worktree détaché
> `D:\ra-pwa-build`, jamais commité, retiré après la mesure. Méthode et
> précautions : **section 0 undecies**.
> **Ce que la mesure a trouvé : aucune régression de production.** 515 verts,
> 19 rouges au départ ; sept tests périmés, neuf mesurés sur une fenêtre
> 800 × 600 (gabarit tablette, plus court que tout téléphone) et trois vrais
> défauts, dont `Échap` qui ne fermait aucune modale. Tout est corrigé :
> **534 verts, 1 rouge**, `dart analyze --fatal-infos` propre,
> `verifier_jetons.dart` 96 fichiers sans violation. Le rouge restant est une
> bombe à retardement horaire sans rapport avec la refonte, décrite en fin de
> section 0 undecies.
> **Découverte de cette session, sans rapport avec L10 lui-même, et déjà
> résolue** : la production servait `a9127fd` (lot R3, déployé le
> 8 septembre), onze commits de retard sur `main` — pas `c5a511f`/L8 comme
> l'affirmait à tort cette page depuis plusieurs sessions. **Comblé dans la
> même session, sur autorisation explicite de l'opérateur** : la production
> sert désormais `ad21990`, confirmé par l'API Vercel. Détail section
> 0 decies et `PROGRESS.md` ligne M.
> Dernier commit **poussé** de `main` avant cette session : `39aec71`.
> `git log --oneline -5` doit correspondre exactement à `origin/main`.
> Détail du lot R4 : section 0 septies. Deux écarts de conception restent
> ouverts et non tranchés, sur `ADM-01`/`ADM-06` (six compteurs contre cinq
> annoncés, ordre signaux/chiffres) — pas des écrans de R4, voir fiche `ADM-01`
> section 6 de `08-catalogue-ecrans.md`. Détail du lot A1 : section 0 octies.
> Détail du lot N0 : section 0 novies. Détail du lot L10 : section 0 decies.

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

### 0 novies. Le lot N0 : spécification de l'étape 5, ADR-020

Dernier lot de la liste ADR-019 avant **L10** (dette indépendante de
l'étape 4). Lot documentaire : aucun écran, aucune migration, aucun test.

**Étape 1 de ce prompt de reprise, avant N0** : `git log --oneline -5` et
`git status` confirmés contre `origin/main` (`1748c06`, aucune divergence,
seuls des fichiers Windows générés — `generated_plugin_registrant.*` —
modifiés, sans rapport). `dart analyze --fatal-infos` vert. `flutter test`
puis `dart run tool/verifier_jetons.dart` retentés une fois chacun, comme
prescrit : même échec identique, `CERTIFICATE_VERIFY_FAILED` sur le hook natif
de `package:sqlite3`, **septième confirmation consécutive**. Pas de nouvelle
tentative au-delà de celle prescrite.

**Ce que N0 a produit**, après recherche du périmètre dans
`docs/design/08-catalogue-ecrans.md` (écrans `ELV-03`, `ENS-03`, `CTR-02`,
`ELV-04`, tous « à construire, étape 5 », plus leurs invariants déjà notés) et
`docs/design/README.md` §4 BIS (qui pointait vers les §19-32 de la Bible V2,
déjà adoptée en entier par l'ADR-019 et lue en entier pour ce lot) :

1. **`docs/architecture/etape-5-salle-coran-presence.md`**, nouveau, sur le
   modèle de `etape-4-dashboards.md` : ce que l'étape 5 doit rendre possible,
   ce qui est déjà tranché par dix ADR d'architecture antérieurs (001, 002,
   004-006, 008-012) et n'est pas rouvert, le Coran comme contenu structuré
   (`mushaf`/`sourate`/`page_mushaf`/`verset`, état personnel de lecture
   distinct de l'état partagé de séance), la salle en cinq sous-systèmes à
   dégradation indépendante, la machine à états de présence par participant
   (14 états de la Bible §29.1, aucun ajouté ni retiré, dérivée de
   `session_events`/`StatutSeance` déjà existants, pas une nouvelle table
   d'événements bruts), les quatre écrans en prose, huit invariants, ce que
   l'étape 5 ne fait pas, six questions explicitement laissées ouvertes
   (§10 : source technique des données Coran, seuils de retard/reconnexion,
   vocabulaire de `session_events.source`, écran pour marquer un participant
   excusé, canal de diffusion de l'état partagé, granularité mot-à-mot), un
   découpage en huit lots proposé (N0 à N7, à confirmer au premier lot de
   code) et une proposition de migration non écrite.
2. **`decisions.md`** : **ADR-020** ajouté, qui pointe vers ce document.
   **Question 3 du registre fermée** : Hafs ʿan ʿĀṣim, édition Mushaf
   Al-Madinah An-Nabawiyyah du Complexe du Roi Fahd — décision explicite de
   l'opérateur (« c'est hafs, le package du roi fahd avec tout ce qui va
   avec »), qui confirme un défaut déjà présent en base depuis l'étape 1
   (`student_profiles.riwaya = 'hafs'`, jamais écrit autrement). La source
   technique des données (jeu de données ou API, police, licence) reste
   ouverte, ce n'est pas une décision de riwaya. **Question 19 mise à jour** :
   posée pour le seul domaine présence par les 14 états ci-dessus, reste
   ouverte pour les autres domaines (matching, séance, contenu).
3. **`docs/design/README.md`** §4 BIS (ligne « §19-32 salle, Coran structuré,
   présence ») et §9 (liste `[à faire] Lot N0` → `[fait]`) mis à jour.
4. **`docs/PROGRESS.md`** ligne 5 (étape 5) mise à jour : spécifiée, code non
   touché, attend son premier lot de code (N1).

**Deux points ont été posés à l'opérateur avant d'écrire quoi que ce soit**,
conformément à la consigne « ne pas inventer » du prompt de reprise : le
format du livrable (spec complète façon L0, retenu) et la riwaya (Hafs/Roi
Fahd, retenu, voir ci-dessus). Sans ces deux réponses, ce lot n'aurait pas pu
avancer sans deviner à la place de l'opérateur.

**Ce qui n'a pas été fait, volontairement** : aucun code, aucune fiche
d'écran remplie dans `08-catalogue-ecrans.md` (les fiches complètes se
remplissent au lot qui construit vraiment l'écran, comme le dit déjà §3 de ce
fichier — pas avant), aucune migration écrite (la proposition §13 du nouveau
document n'est pas `0006` ni une nouvelle migration, elle sera affinée au lot
N1).

**Commit et push** : à faire sur ce lot, docs uniquement, aucun code touché
— cohérent avec la règle déjà appliquée depuis plusieurs lots (build vert →
commit et push sans redemander), et sans le risque des lots précédents
puisque rien en `lib/` ni `test/` n'a changé.

### 0 decies. Le lot L10 : clôture de l'étape 4

Dernier lot du découpage en onze de l'étape 4 (section 2), dette indépendante
de la refonte, redevenue la priorité après que N0 a épuisé l'ordre de travail
de l'ADR-019. N'ajoute aucun écran : vérifie et consigne, comme prescrit.

**Étape 1 de ce prompt de reprise, avant L10** : `git log --oneline -5` et
`git status` confirmés contre `origin/main` (`39aec71`, aucune divergence,
seuls les fichiers Windows générés modifiés, sans rapport). `dart analyze
--fatal-infos` vert. `flutter test` puis `dart run tool/verifier_jetons.dart`
retentés une fois chacun, comme prescrit : même échec identique,
`CERTIFICATE_VERIFY_FAILED` sur le hook natif de `package:sqlite3`,
**huitième confirmation consécutive**. Pas de nouvelle tentative au-delà de
celle prescrite.

**Ce que L10 a fait, dans l'ordre de la section 4 :**

1. **Les cinq contrôles rejoués sur un conteneur Docker neuf.** Trois obtenus,
   deux non (même blocage TLS que l'étape 1, ce sont les mêmes commandes) :
   `dart analyze --fatal-infos` vert, `scenarios_etape3.sql` 34 contrôles
   verts, `scenarios_etape4.sql` 39 contrôles verts — identiques aux comptes
   de L9, aucune régression. Chiffres et détail consignés dans
   `etape-4-journal.md`, nouvelle section « Mesures du lot L10 ».
2. **`docs/PROGRESS.md` mis à jour** : étapes 4 et 4 bis passées à `[x]`, ligne
   M de l'onboarding corrigée, ligne « Promotion en production » corrigée,
   section « DÉMARRER ICI » réécrite pour pointer vers N1 plutôt que L10. La
   ligne « Plateforme Android 37 » avait déjà été retirée lors d'une session
   antérieure (remplacée par « Magasin de certificats du poste ») : rien à
   faire de ce côté, contrairement à ce que disait le prompt de reprise.
3. **Les dix-sept scénarios relus** (`etape-4-journal.md` section « Les
   dix-sept scénarios d'acceptation ») : déjà exacts, seize verts, le
   quatorzième (démarrage à froid) toujours marqué non mesurable sur ce
   poste, ni coché ni refait. Rien à corriger.

⚠ **Découverte non prévue par le prompt de reprise, en vérifiant la ligne M** :
`docs/HANDOFF.md` affirmait depuis plusieurs sessions que la production
servait `c5a511f` (L8). C'était faux. Vérifié par l'API Vercel
(`get_deployment` sur `rewayah-academy.vercel.app`, en lecture seule, aucun
déploiement déclenché) : la production sert en réalité **`a9127fd`**, le
commit qui a suivi la clôture du lot R3 (déployé le 8 septembre au soir, déjà
noté dans `PROGRESS.md` mais avec le mauvais SHA, `09527ec`). Conséquence :
**onze commits séparent la production de `main`** — B0, T2, R0, T3, R4, A1 et
N0 sont codés et poussés mais **aucun n'est en ligne**. Corrigé dans les deux
fichiers (`HANDOFF.md` section 4 bis, `PROGRESS.md` lignes M et « Promotion en
production »). La ligne de promotion reste à l'opérateur, comme toujours —
ce lot n'a rien déployé, seulement lu l'état réel.

**Ce que L10 n'a pas fait, volontairement** : ouvrir l'étape 5 (N1 reste un
autre lot, un autre jour) ; toucher au SQL de la base réelle.

**Mise à jour, plus tard dans la même session** : sur autorisation explicite
de l'opérateur, le retard de production a été comblé. Reconstruction dans le
worktree `D:\ra-pwa-build` depuis `ad21990` (`flutter pub get`, `flutter
build web --release` — pas besoin de `dart run slang`/`build_runner`, les
fichiers générés sont commités dans le dépôt, donc déjà corrects après le
`git checkout`), puis `vercel deploy --prod --yes` depuis `build/web`. **Passé
sans refus cette fois.** Confirmé par l'API Vercel : l'alias
`rewayah-academy.vercel.app` porte `gitCommitSha: ad21990...`. La production
est maintenant à jour avec `main`.

**Commit et push** : à faire sur ce lot, `docs/` et `PROGRESS.md` seulement,
cohérent avec la règle déjà appliquée (build vert → commit et push sans
redemander) et sans le risque des lots de code précédents, puisque rien en
`lib/` ni `test/` n'a changé.

### 0 undecies. Le lot de remise au vert : le blocage TLS contourné, et ce que la mesure a trouvé

**Neuf sessions durant, `flutter test` n'a jamais tourné sur ce poste.** Le hook
de build de `package:sqlite3` télécharge une DLL depuis `github.com`, que le
magasin de racines du poste refuse. Six lots de code ont donc été poussés, puis
déployés, sans qu'aucune suite ne les ait jamais confirmés.

**Le contournement était documenté depuis le début, dans le paquet lui-même.**
`sqlite3/doc/hook.md` décrit un `user_define` qui lie le SQLite **du système**
au lieu d'en télécharger un :

```yaml
hooks:
  user_defines:
    sqlite3:
      source: system
      name_windows: winsqlite3
      name: sqlite3
```

⚠ **Il n'est ni commité ni laissé en place.** Il change le SQLite d'un build de
production. Il a été posé dans le worktree détaché `D:\ra-pwa-build`, le temps
de la mesure, puis retiré par `git checkout -- pubspec.yaml`. La méthode :
éditer dans le dépôt de travail, copier les fichiers touchés vers le worktree,
mesurer là-bas. Le dépôt de travail n'est jamais modifié par la mesure.

**Première mesure réelle : 515 verts, 19 rouges.** Aucune régression de
production : les dix-neuf se rangent en trois familles, et aucune n'était un
écran cassé.

| Famille | Nb | Ce que c'était vraiment |
| :--- | :-: | :--- |
| Tests périmés | 7 | `composants_test.dart` comparait `d.boxShadow` à `AppElevation.niveau2`, c'est-à-dire à un **tear-off de fonction** : le lot T3 a fait des trois niveaux des fonctions de `AppShadowColor`, les tests ne l'ont pas suivi. Plus une assertion restée sur la paire d'avant T2 |
| Surface de mesure fausse | 9 | `flutter_test` monte tout sur **800 × 600**, c'est-à-dire au gabarit **tablette**, plus court que n'importe quel téléphone. `ENS-06` n'a d'onglets qu'en mobile depuis R4 : six tests cherchaient un onglet inexistant à cette largeur. `TUT-00c/c` : trois `tap` tombaient sous la ligne de flottaison de cette fenêtre-là. **Le produit tenait, la fenêtre mentait** — les neuf passent en 390 × 844 sans toucher un écran |
| Vrais défauts | 3 | `Échap` ne fermait aucune modale (2), `MarquePage` absente du catalogue (1) |

**Le défaut d'`AppBottomSheet` mérite d'être lu, il ne se devine pas.** La
méthode `ouvrir` fournissait son propre `transitionAnimationController`. Or
`ModalBottomSheetRoute` pose alors `willDisposeAnimationController = false` :
le contrôleur appartient à l'appelant. Et l'appelant le détruisait par
`.whenComplete(animation.dispose)` — c'est-à-dire **au pop, pas au retrait**.
Le contrôleur mourait au milieu de l'animation de sortie, la route
n'atteignait jamais l'état qui la retire de l'overlay, et **la feuille restait
affichée sur une route déjà dépopée**. `Échap` faisait exactement ce qu'il
fallait ; rien ne bougeait. Le commentaire du fichier affirmait au contraire
qu'« il n'y a rien à câbler ».

Le remède **supprime** du code : `AnimationStyle` porte les durées autant que
les courbes, donc `showModalBottomSheet` construit le contrôleur lui-même — et
le détruit lui-même, au bon moment. **Ne jamais repasser de
`transitionAnimationController` ici.**

Diagnostic obtenu par élimination, et la méthode vaut d'être notée : une
feuille Material **nue** se ferme sur `Échap` ; on lui rajoute un ingrédient à
la fois (contrôleur, style, `isScrollControlled`) jusqu'à ce qu'elle cesse. Le
premier suffit.

**Un vrai défaut de rendu trouvé au passage, corrigé.** Le lot R4 a rendu
`ENS-06` responsive et a laissé les deux libellés d'onglet dans le seul
`TabBar` mobile : au-delà de 600 px, la grille gardait sa question en tête mais
**le feed d'élèves n'avait plus aucun titre**. Les deux panneaux portent
désormais un `SectionHeader` avec le libellé de leur onglet, et un test le tient
à 768 comme à 1440.

**Deux lignes du tableau de correspondance de `docs/design/README.md` étaient
fausses**, et disaient « Fait » sans que rien ne l'ait vérifié :

- **§13.4 clavier** — le lot A1 avait écrit le test d'`Échap` et l'avait laissé
  rouge, faute de pouvoir le lancer. Fermé pour de bon ici.
- **§18 chargement** — `Skeleton` est né au lot C et **aucun écran ne
  l'emploie** : zéro usage dans `lib/features/` hors `_dev/`. Les écrans qui
  disent quelque chose affichent un `Text` « Chargement… », parfois un
  `EmptyState` détourné en attente (`creneaux_page.dart`). La ligne dit
  maintenant « Écart ». **C'est le premier chantier de rendu qui reste.**

**Résultat : 534 verts, 1 rouge, `dart analyze --fatal-infos` propre,
`verifier_jetons.dart` 96 fichiers sans violation** (il en comptait une avant :
un tiret cadratin dans `appareils_page.dart`).

⚠ **Le rouge restant n'a rien à voir avec ce lot : c'est une bombe à
retardement.** `test/features/journee_test.dart`, « `ENS-02` : le bloc
dominant », place son cours à `DateTime.now() + 25 min 30 s` et attend
« Dans 25 min ». Passé **23 h 34**, cet instant tombe le lendemain, et `ENS-02`
affiche la journée d'aujourd'hui : le cours n'y est pas. Le test échoue donc
tous les soirs entre 23 h 34 et minuit, et il a effectivement basculé du vert au
rouge entre deux exécutions de cette session, à 23 h 42. **Le scénario est
inexprimable près de minuit sans horloge injectable** : le vrai remède est de
faire lire l'heure au code de planning via une horloge qu'un test puisse figer
(`package:clock` et `withClock`), ce qui touche la couche planning — une
décision, pas un correctif de test. À trancher avec l'opérateur.

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
| **L10** | **Vérifications de fin d'étape, documentation, `PROGRESS.md`** | **fait le 11 septembre 2026** |

**L'étape 4 est désormais close.** Détail du lot L10 : section 0 decies.

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

## 4. Le lot L10 est fait

Clôture de l'étape 4, détail complet en section 0 decies. Les cinq contrôles
de la section 5 sont rejoués (chiffres dans `etape-4-journal.md`),
`docs/PROGRESS.md` est à jour, les dix-sept scénarios sont relus (seize
verts, le quatorzième toujours non mesurable sur ce poste, non coché). Ce
n'est plus le point de reprise.

L'étape 5 (salle, pre-flight, `ELV-03`/`ENS-03`) reste une autre étape : elle
est désormais **spécifiée** (lot N0, ADR-020,
`docs/architecture/etape-5-salle-coran-presence.md`), mais son premier lot de
code, **N1**, n'a pas été ouvert par L10 — c'est volontaire, voir section
0 decies.

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
- **La production sert la build de `a9127fd`** (lot R3, déployée le 8 septembre
  au soir), pas `c5a511f`/L8 comme l'affichait cette ligne — corrigé au lot L10
  après vérification par l'API Vercel (`docs/PROGRESS.md` ligne M). Les deux
  écrans d'administration de L9 (`ADM-01`, `ADM-06`) y sont, L9 étant antérieur
  à ce déploiement ; ce qui n'y est pas, c'est tout ce qui a suivi le 8
  septembre : B0, T2, R0, T3, R4, A1, N0, soit onze commits de retard sur
  `main`. La ligne de promotion est à l'opérateur, `MISE-EN-SERVICE.md`
  section 7.1.

## 5. Mesures de référence, à ne pas faire régresser

Relevées le **12 septembre 2026**, au lot `ADM-05`. La colonne du milieu est
celle du 11 septembre, lot de remise au vert — **les premières vraies depuis le
lot T**, les colonnes intermédiaires n'ayant jamais pu être mesurées sur ce
poste (section 0 undecies).

| Contrôle | Valeur (12/09) | Au lot de remise au vert (11/09) |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème | aucun problème |
| `flutter test` | **542 tests, tous verts** | 535 tests, 534 verts |
| `dart run tool/verifier_jetons.dart` | **98 fichiers**, aucune violation | 96 fichiers |
| `scenarios_etape3.sql` | **34 contrôles** verts | 34 |
| `scenarios_etape4.sql` | **39 contrôles** verts | 39 |
| `scenarios_etape5.sql` | **15 contrôles** verts | 15 |
| `scenarios_adm05.sql` | **9 contrôles** verts | — |

⚠ Le 535e test, rouge le 11 septembre, est la **bombe horaire** de
`journee_test.dart` : il ne tombe qu'entre 23 h 34 et minuit. Le voir vert ne
prouve pas qu'il soit réparé, seulement qu'il n'est pas cette heure-là. Détail
en fin de section 0 undecies.

⚠ `flutter test` ne tourne toujours pas tel quel sur ce poste : il faut le
contournement du hook `sqlite3`, dans le worktree de build **et nulle part
ailleurs**. Recette complète en section 0 undecies. `dart run` est logé à la
même enseigne : `verifier_jetons.dart` se lance depuis le worktree lui aussi.

Un lot se termine par ces contrôles, la mise à jour de la documentation d'étape,
un commit et un push. Jamais l'inverse.

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
# puis les HUIT migrations, dans l'ordre : 0001_fondations,
# 0002_statut_attente_kyc, 0003_profil_defaut_attente,
# 0004_inscription_kyc_appairage, 0005_dashboards_affectation_regles,
# 0006_rattrapage_semaine_utc_et_foyer,
# 0007_coran_structure_position_presence, 0008_attribution_manuelle
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -q -f /sql/migrations/0001_fondations.sql
# puis les QUATRE fichiers de scenarios, dans cet ordre : ils tiennent sur la
# meme base et chacun borne ses assertions a ses propres fixtures.
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_etape3.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_etape4.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_etape5.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_adm05.sql
```

⚠ **Un fichier de scénarios ne compte jamais en global.** Les quatre tournent
sur la même base : `select count(*) from eleves_sans_enseignant()` y voit les
élèves des trois autres fichiers. Une assertion se borne à ses propres fixtures
(par `household_id` ou par identifiant), et l'ordre se vérifie en **rang
relatif**, jamais par `limit 1`. Le lot `ADM-05` s'est fait prendre une fois :
vert seul, rouge à la suite.

⚠ **Aucune heure locale ne s'écrit en dur dans un scénario qui croise deux
fuseaux.** Conakry ne change pas d'heure, Paris si : « 16 h Conakry = 17 h
Paris » est vrai d'octobre à mars et faux le reste de l'année. Le fixture
d'`ADM-05` calcule l'heure par
`extract(hour from (instant_creneau(...) at time zone '...'))`. Même piège que
la bombe horaire de `journee_test.dart`, en version saisonnière.

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
  au premier appel. Voir `etape-2-journal.md`. **Contournable sans réparer le
  poste** depuis le 11 septembre : le `user_define` `source: system` documenté
  par le paquet, posé dans le seul worktree `D:\ra-pwa-build` et retiré après
  la mesure — **jamais commité**, il changerait le SQLite d'un build de
  production. Recette en section 0 undecies. La vraie réparation (ajouter la
  racine au magasin du poste) reste à faire et vaudrait mieux.
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

## 9. Prompt de reprise — `ADM-05` est fait, N2 attend toujours la vidéo

À copier tel quel pour démarrer la prochaine session.

### 9.1 Ce qui a été mesuré le 12 septembre, et non supposé

**Première session.** La production a été ouverte en session admin plutôt que
de questionner l'opérateur écran par écran. Le verdict « l'app est loin d'être
fonctionnelle » est **vérifié** : onze destinations du routeur rendaient
`EcranAConstruire`, dont `ELV-03`/`ENS-03`, la salle de cours, c'est-à-dire le
produit. Dix-neuf écrans existaient pour de vrai. Zéro erreur console : rien
n'était cassé, l'étape 5 n'était pas commencée. **Ne pas refaire ce
diagnostic.**

**Deuxième session.** L'opérateur a demandé de laisser le fournisseur vidéo de
côté et d'avancer ailleurs. `ADM-05` a donc été construit : il ne reste plus
que **dix** `EcranAConstruire`, et surtout le produit peut enfin produire une
séance sans qu'un enseignant en prenne l'initiative.

### 9.2 Les deux causes non-code, toujours ouvertes

1. **La migration `0006` n'est pas sur la base réelle.** Mesuré par PostgREST
   (`42703 column ... does not exist` sur `profils_du_foyer_v.access_until`).
   `TUT-01` lit une vue amputée, `ENS-06` reste faux deux heures par semaine.
2. **La production ne sert pas `main`.** L'écart est mince, mais réel.

Trois migrations attendent désormais l'éditeur SQL, dans cet ordre : `0006`
(bloc de `MISE-EN-SERVICE.md` §5), `0007`, `0008`. **`0008` est la première
dont l'absence se voit immédiatement** : `/admin/attribution` afficherait une
erreur de lecture au lieu de ses deux listes.

### 9.3 Ce que la deuxième session a livré

- `supabase/migrations/0008_attribution_manuelle.sql` : `eleves_sans_enseignant()`,
  `enseignants_pour(uuid)`, `attribuer_eleve(...)`. **Aucune table, aucune
  policy d'écriture ouverte** : l'invariant I3 de `0005` tient, le contrôle A9
  le mesure.
- `supabase/tests/scenarios_adm05.sql` : neuf contrôles, rejoués à la suite des
  trois autres fichiers sur `0001`→`0008`. **97 contrôles verts au total.**
- `lib/core/matching/service_attribution.dart`, `lib/features/admin_attribution/`,
  le compteur `ADM-01` câblé, sept tests de widget.
- **ADR-021** et les questions **25** et **26** du registre.
- `ADM-05` est le **premier écran du produit à employer `Skeleton`**. L'écart de
  la Bible §18 n'est plus théorique : il reste ouvert sur les dix-neuf autres
  écrans, mais il a un précédent à copier.

### 9.4 Ce qui ne peut pas se faire depuis le poste

**1. Coller les trois migrations** dans l'éditeur SQL du projet
`gggmtelinlpseweouyav` : `MISE-EN-SERVICE.md` §5 (bloc `0006`), puis §5.2
(`0007`), puis §5.3 (`0008`).
⚠ Le serveur MCP `supabase` de ce poste pointe sur **PISI**
(`riaqzfhdynmtshvbgdvt`), pas sur Rewayah.

**2. Reconstruire et promouvoir.** La build qui attend dans
`D:\ra-pwa-build\build\web` date de `5b8b868` : elle **ne contient pas**
`ADM-05`. Il faut la refaire avant de promouvoir.

```
! cd "D:\ra-pwa-build"; flutter build web --release
! cd "D:\ra-pwa-build\build\web"; vercel deploy --prod --yes
```

### 9.5 Le prompt

```
Rewayah Academy -- depot D:\RA _APP\RA -OFFICIAL-APP, branche main.
Chemins en absolu : Glob ne trouve pas ce depot.

NE RELIS PAS TOUT LE CODE. Lis exactement ceci, dans cet ordre :
  1. docs/HANDOFF.md -- l'en-tete et la section 9.
  2. docs/architecture/etape-5-salle-coran-presence.md -- sections 5, 7 et 12.
  3. docs/MISE-EN-SERVICE.md sections 5.1, 5.2, 5.3 et 7.1.
Le reste ne se lit que si le sujet du jour y touche.

OU ON EN EST, MESURE ET NON SUPPOSE.
Le verdict "l'app est loin d'etre fonctionnelle" est VERIFIE depuis le
12/09 : onze destinations du routeur rendaient EcranAConstruire, dont
ELV-03/ENS-03, la salle de cours. Ne REFAIS PAS ce diagnostic.
Il en reste DIX : eleve (Coran, Suivi), tuteur (Suivi), enseignant
(Profil), controleur (Planning), admin (Journal), espace comptable,
et ELV-03/ENS-03/CTR-02 la salle.

FAIT :
  N0 = spec etape 5 + ADR-020 (39aec71)
  N1 = migration 0007 : Coran structure, student_reading_position,
       presence_state a 14 etats, etat_presence(), presence_seance_v
       (a736a43) -> 15 controles
  ADM-05 = attribution manuelle, HORS SERIE, fait pendant que N2
       attendait la decision video. Migration 0008 (trois fonctions),
       ecran, ADR-021 -> 9 controles SQL + 7 tests de widget.
       C'etait le chainon manquant : sans lui aucune affectation ne
       naissait sans un enseignant, donc aucune seance, donc ENS-02 /
       ELV-02 / TUT-01 restaient vides.

LE PROCHAIN LOT EST N2, ET IL DEMANDE UNE DECISION AVANT DU CODE.
N2 = VideoSessionProvider/LiveKitSessionProvider (ADR-001), pre-flight,
emission de jeton. L'operateur a dit le 12/09 qu'il lui restait des
infos a completer sur l'outil, et a pointe la spec :
  "D:\RA _APP\docs de lancement\architecture live kit..md"
NE PAS LIRE CE FICHIER tant que le lot du jour ne traite pas la video :
il est long et coute cher en contexte. Demander d'abord a l'operateur
si la decision est prise (fournisseur, compte, cles).
C'est aussi N2 qui posera la trace d'emission de jeton rendant l'etat
`en_connexion` derivable. N1 ne le derive volontairement pas, faute de
trace en base. Ne pas l'inventer.

SI N2 EST TOUJOURS BLOQUE, les lots non bloques par la video sont, par
valeur decroissante :
  - ADM-04 journal d'audit (/admin/journal, dernier placeholder de
    l'espace admin, table audit_logs en place depuis l'etape 1) ;
  - N5 / ELV-04 lecteur Coran -- mais il demande d'abord l'import du
    jeu de donnees coranique, et github.com est injoignable en TLS
    depuis ce poste ;
  - l'ecart Skeleton sur les dix-neuf ecrans restants (bible section
    18) : ADM-05 montre le motif a copier.
CTR-01 et CTR-02 restent bloques par la salle, pas par la video seule.

TROIS ACTIONS A LA MAIN DE L'OPERATEUR, a lui rappeler si pas faites :
  a) Coller 0006 (MISE-EN-SERVICE.md section 5) PUIS 0007 PUIS 0008
     dans l'editeur SQL du projet gggmtelinlpseweouyav. 0006 etait
     toujours absente au 12/09, mesure par PostgREST (42703).
     0008 est la premiere dont l'absence SE VOIT : sans elle,
     /admin/attribution affiche une erreur au lieu de ses deux listes.
     ATTENTION : le MCP supabase de ce poste pointe sur la base PISI
     (riaqzfhdynmtshvbgdvt). NE JAMAIS l'utiliser pour ce projet.
  b) Confirmer ou refuser l'ADR-021 : l'administration peut attribuer
     un eleve hors des disponibilites declarees d'un enseignant, avec
     motif obligatoire et journalisation. Decision prise par l'agent
     faute de pouvoir attendre. Reversible en une heure, recette en
     fin d'ADR-021.
  c) Reconstruire PUIS promouvoir. La build de D:\ra-pwa-build\build\web
     date de 5b8b868 et ne contient pas ADM-05 :
     ! cd "D:\ra-pwa-build"; flutter build web --release
     ! cd "D:\ra-pwa-build\build\web"; vercel deploy --prod --yes

POUR MESURER :
  - SQL : docker, conteneur neuf, stub_auth puis migrations 0001 a 0008,
    puis les QUATRE fichiers de scenarios a la suite. Recette section 6.
    Docker Desktop n'est pas forcement demarre : le lancer et boucler
    sur `docker info`.
    Le `docker rm -f` se passe SEUL sur sa ligne (protection de chemins).
    Reference : 34 + 39 + 15 + 9 = 97 controles, zero erreur.
    PIEGE : les quatre fichiers tournent sur la MEME base. Une assertion
    qui compte en global mesure les fixtures des autres. Borner par
    household_id ou par identifiant, et verifier l'ordre en rang
    relatif, jamais par limit 1.
  - Dart : flutter test NE TOURNE PAS tel quel (TLS github.com refuse
    pour le hook package:sqlite3). Contournement en section 0 undecies :
    le user_define `source: system` dans le pubspec du worktree
    D:\ra-pwa-build UNIQUEMENT, jamais commite, retire apres la mesure
    par `git checkout -- pubspec.yaml`. Reference 542/542.
    `dart run tool/verifier_jetons.dart` est loge a la meme enseigne :
    il se lance depuis le worktree. Reference 98 fichiers.
    Methode : editer dans le depot de travail, copier les fichiers
    touches vers le worktree, mesurer la-bas.

PIEGES :
- OpenCode travaille EN PARALLELE sur le meme depot (lib/app.dart,
  lib/core/config/env.dart, lib/main.dart, lib/features/_dev/playground/).
  git status avant tout commit, ne jamais stager ses fichiers.
- verifier_jetons.dart refuse le tiret cadratin dans le code Dart.
  Deux points ou une virgule a la place.
- journee_test.dart / "ENS-02 : le bloc dominant" est rouge entre 23h34
  et minuit seulement. Vert ne prouve pas repare.
- Aucune heure locale en dur dans un scenario qui croise deux fuseaux :
  Conakry ne change pas d'heure, Paris si. Calculer par
  extract(hour from (instant_creneau(...) at time zone '...')).
- Une ligne "Fait" du tableau de docs/design/README.md ne vaut que si un
  test la tient : deux etaient fausses (13.4 et 18).
- Skeleton n'est employe que par ADM-05. Les dix-neuf autres ecrans
  affichent encore un Text "Chargement" nu, et le demarrage a froid de
  la PWA depasse treize secondes.

Un lot par session. Ignore la branche refactor-ui-lavender.
FIN DE SESSION : livrer un prompt de reprise et mettre a jour cette
section 9. Consigne permanente de l'operateur.
```

