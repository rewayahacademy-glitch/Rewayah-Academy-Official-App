# TC_AGENT_B_REPORT — Library Core

> Baseline `0071557`, worktree `D:\RA_TC\b`, branche `teaching-core/b-library`.
> Ce rapport est écrit pour être relu par un contrôleur qui relancera les commandes.
> Ce qui n'est pas fait est écrit comme tel, au même endroit que ce qui l'est.

---

## 1. Vert ou rouge, en premier

| Commande, lancée depuis `D:\RA_TC\b` | Résultat |
|---|---|
| `flutter analyze lib test` | **`No issues found!`** |
| `flutter test test/teaching_core/b` | **`All tests passed!`** — 95 tests, 8 fichiers |
| `git status --porcelain` | **4 entrées, toutes dans mon ownership** |

**Un défaut préexistant croisé, non corrigé, hors mission.**
`dart run tool/verifier_jetons.dart` rend **10 violations**, toutes antérieures à ce lot
et **toutes hors de mes fichiers** : 6 `m-dash` (`menu_filtre.dart`, `nav_shell.dart`,
`dossiers_page.dart`, `journal_page.dart`), 1 `bouton-material` et 2 `ontap-nu`
(`nav_shell.dart`, `sous_navigation_domaine.dart`). Aucune n'est dans
`tc_bibliotheque/`, `tc_telechargement/` ni `tc_catalogue/`. Je ne les ai pas touchées :
`lib/core/widgets/` est gelé, et corriger un fichier du socle serait le manquement
d'ownership le plus grave que je puisse commettre.

Second défaut connu de la baseline, signalé par l'addendum et confirmé ici sans y
toucher : `test/.../catalogue_galerie_test` est rouge, donc **aucun composant nouveau
ne peut entrer dans `lib/core/widgets/`**. Mes cinq composants vivent dans
`lib/features/tc_catalogue/`, qui m'appartient.

---

## 2. Les 23 fichiers de code créés

Aucun fichier existant n'a été modifié. Aucun.

### `lib/core/tc_bibliotheque/` — le domaine

| Fichier | Lignes | Ce qu'il porte |
|---|---|---|
| `library_resource.dart` | 218 | `LibraryResource` et les quatre enums du manifeste (§6.4), avec `valeurSql` / `depuisSql` et une fabrique `depuisJson` qui fige la forme SQL demandée |
| `resource_version.dart` | 89 | `ResourceVersion`, statuts calqués sur `StatutVersionProgramme` (`0020`) |
| `content_position.dart` | 175 | `ContentPosition`, quatre constructeurs nommés, un seul ancrage à la fois garanti par assertion |
| `content_range.dart` | 104 | `ContentRange`, `contient`, `chevauche`, ordre naturel par type d'ancrage |
| `port_catalogue.dart` | 117 | `PortCatalogue`, `FiltreCatalogue`, `ReprisLecture`, `EchecCatalogue` |
| `port_versions_ressource.dart` | 15 | `PortVersionsRessource`, lecture seule |
| `recherche_catalogue.dart` | 186 | Recherche et filtres, en fonctions **pures** : accents, axes, repères chiffrés |
| `couverture_ressource.dart` | 137 | Le calcul déterministe d'une couverture : teinte, motif, monogramme |
| `vue_catalogue.dart` | 232 | `VueCatalogue.depuis()`, la fonction pure qui décide états et ordre de découverte |
| `catalogue_local.dart` | 196 | `CatalogueLocal`, `VersionsLocales`, `ArtefactsLocaux` — les doubles locaux |
| `donnees_catalogue.dart` | 205 | Le câblage Riverpod du module et les deux lectures agrégées |

### `lib/core/tc_telechargement/` — l'artefact et le hors ligne

| Fichier | Lignes | Ce qu'il porte |
|---|---|---|
| `download_asset.dart` | 107 | `DownloadAsset`, `FormatArtefact` (avec son type MIME et son extension), `OrigineArtefact` |
| `port_telechargement.dart` | 40 | `PortTelechargement`, `LecteurArtefact`, `EchecArtefact` |
| `port_etat_offline.dart` | 238 | `EtatOffline`, `PortEtatOffline`, `DepotOctetsLocal`, `DepotOctetsMemoire`, `EtatOfflineCache` |
| `port_enregistrement_fichier.dart` | 65 | `PortEnregistrementFichier`, son implémentation `file_picker`, et `nomFichierPropose` |

### `lib/features/tc_catalogue/` — les surfaces

| Fichier | Lignes | Ce qu'il porte |
|---|---|---|
| `libelles_tc_b.dart` | 207 | La façade i18n, chaque constante annotée `// TC-I18N: cle=tc.bibliotheque.…` |
| `vignette_ressource.dart` | 192 | La couverture : quatre teintes du thème, quatre motifs peints, un monogramme |
| `carte_ressource.dart` | 154 | La `ResourceCard` : couverture, titre, type, état hors ligne nommé |
| `surface_bibliotheque.dart` | 315 | **La Bibliothèque, la seule.** Recherche, filtres, sections, états vides |
| `bibliotheque_page.dart` | 46 | La coquille hors classe : `PageShell` + la surface |
| `detail_ressource_page.dart` | 311 | La fiche minimale, les deux gestes hors ligne, « Enregistrer une copie » |
| `class_library_picker.dart` | 95 | La surface réutilisable en classe, et son ouverture en feuille |
| `routes_tc_b.dart` | 50 | `routesTcB()` — **une fonction qui retourne des routes**, aucun `GoRouter` |

### Documents

`docs/teaching-core/TC_AGENT_B_REPORT.md`, `TC_CONTRACT_REQUEST_B.md`,
`i18n/tc_i18n_B.json`.

---

## 3. Ce qui marche, et comment on le vérifie

### 3.1 Une seule Bibliothèque — tenu par la structure, pas par la discipline

`BibliothequePage` et `ClassLibraryPicker` montent **le même widget**,
`SurfaceBibliotheque`, qui lit **le même** `VueCatalogue.depuis()`, qui lit **les mêmes**
ports. Il n'y a pas deux chemins à garder synchrones : il n'y en a qu'un.

Seul l'**ordre de découverte** diffère, et il est décidé dans une fonction pure, hors de
tout widget : hors classe `Pour ce groupe > Récents > Tous les supports` précédé de
`Continuer` ; en classe `Récents > Ce groupe > Tous les supports`, puis la recherche,
exactement comme la spec §6.2. Deux tests mesurent l'ordre à l'écran en comparant les
ordonnées des en-têtes de section.

### 3.2 Le picker de classe ne peut pas couper LiveKit

Ce n'est pas une intention, c'est une mesure. `class_library_picker_test.dart` relit les
**onze fichiers** qui composent la surface, commentaires retirés, et échoue si l'un
contient `core/video/`, `livekit_client`, `moteurSalleProvider`, `serviceVideoProvider`,
`preVolProvider` ou `disconnect`. Même méthode que
`test/appairage/code_local_test.dart`, qui prouve qu'un code personnel ne quitte jamais
l'appareil.

Deux tests complètent : choisir un support n'appelle **que** le rappel de l'hôte — pas
de navigation, pas de fermeture, pas de session touchée — et ouvrir la feuille laisse la
page de classe montée, donc le moteur de salle connecté.

### 3.3 Les couvertures sont distinctes, et déterministes partout

Trois axes se combinent : une teinte (4), un motif (4), un monogramme tiré du titre
court. L'index 0 est **réservé au Coran** (`surfaceQuran`, la seule paire du thème qui
ne serve à rien d'autre) ; les autres se répartissent sur trois teintes douces. Douze
combinaisons pour le reste du catalogue, chacune portant deux lettres différentes.

**Un piège évité et mesuré.** La première version employait FNV-1a. Son multiplicateur,
16 777 619, porte le produit à 2^56 avec une valeur courante de 32 bits — au-delà des
2^53 entiers exacts d'un nombre JavaScript. La même ressource aurait donc eu **une
couverture sur le web et une autre sur mobile**, et la production est servie par Vercel.
Le multiplicateur retenu, 33, borne le produit à environ 1,4 × 10^11 : exact partout.
Le test mesure la stabilité, la borne 32 bits, et la répartition réelle sur 60 clés.

### 3.4 Les états hors ligne, et ce qu'ils ne disent pas

Cinq états, et ils se distinguent : `indisponible` (politique, capacité ou version
absente), `aTelecharger`, `enCours`, `enCache` (présent sans demande, donc purgeable),
`telecharge` (demandé, donc conservé). La clé de cache **porte la version** : une version
publiée plus récente ne peut pas être servie depuis les octets de l'ancienne.

Trois règles tenues dans le code, pas dans les commentaires :
- un échec de téléchargement **lève** `EchecTelechargementRessource` et republie l'état
  dans un `finally` : une carte ne reste jamais bloquée sur « en cours » ;
- le flux émet l'état **courant** à l'abonnement, comme `ServiceReseau.horsLigne()` ;
- l'état du réseau vient de `horsLigneProvider`, **jamais** d'un second abonnement
  `Connectivity`. `EtatOfflineCache` ne connaît pas le réseau : il ne sait que ce qui
  est local.

Hors ligne, une ressource non téléchargée **reste listée** et porte sa raison. La
retirer ferait croire à une perte de droit ; la griser laisserait chercher le geste qui
la réactiverait.

### 3.5 « Enregistrer une copie » passe par le système, et rien d'autre

`EnregistrementFichierSysteme` appelle `FilePicker.saveFile()` de `file_picker 12.2.0`,
**déjà présent** : aucune dépendance ajoutée, et la règle §6.5 « jamais un chemin
`/sdcard` bricolé » est tenue sans rien demander. Le résultat est un `Uri` rendu tel
quel — `file`, `content`, `blob` ou `data` selon la plateforme — dont on ne déduit
jamais un chemin.

Le nom proposé garde la langue et les accents du titre ; seuls les caractères qu'un
système de fichiers refuse sont remplacés, et la longueur est bornée à 80 caractères.
Une renonciation rend `null` et **ne produit aucun message** : elle n'est pas une erreur.

Quand la version ne porte pas d'artefact, **le bouton n'est pas rendu** : une phrase
prend sa place (« Aucun fichier à télécharger pour cette version. »). Un bouton qui ne
peut pas aboutir coûte plus cher en confiance qu'un bouton absent.

### 3.6 Trois vides qui ne se disent pas de la même façon

- **catalogue vide** : registre `subi`, aucun bouton — la personne ne peut pas publier
  un support elle-même ;
- **recherche sans résultat** : registre `actionnable`, avec « Tout afficher » ;
- **lecture en échec** : état de panne avec « Réessayer ».

Plus un quatrième, sur la fiche : **ressource invisible pour l'appelant**. `parId` rend
`null`, et l'écran explique sans accuser (« Ce support ne vous est pas ouvert. Il a
peut-être été retiré, ou il est réservé à un autre groupe. »). La barrière est serveur ;
l'écran ne fait que la dire.

### 3.7 La liste tient plusieurs centaines de ressources

`SurfaceBibliotheque` est un `CustomScrollView` à `SliverList.separated` : les cartes se
construisent à la demande. Un test monte **400 ressources** sur une fenêtre de 390 × 844
et vérifie que moins de 40 `CarteRessource` sont construites. Sans cela, 400 couvertures
seraient peintes pour un écran qui en montre six.

---

## 4. Ce qui est mocké, et ce que cela veut dire

**Tout le stockage.** `CatalogueLocal`, `VersionsLocales` et `ArtefactsLocaux` sont des
doubles **en mémoire**, et le provider par défaut rend un catalogue **vide**. Ce n'est
pas un oubli : aucune table `library_resource`, `resource_version` ou `download_asset`
n'existe en base (migrations `0001` à `0029` relues), et aucun bucket Storage n'existe en
dehors de `kyc` et `avatars`.

**Aucune ressource de démonstration n'est livrée.** Un catalogue rempli de faux supports
ferait passer une maquette pour un produit, et le premier écran qu'un opérateur verrait
serait un mensonge. L'écran affiche donc son état vide, qui est la vérité.

Les doubles ne sont pas pour autant des maquettes : ils portent **les vraies règles** de
tri, de recherche, de reprise et de version courante (la publiée de numéro le plus
élevé, comme `versionActiveProgrammeProvider`). Le jour où les tables existent, c'est le
corps des méthodes qui change, pas les contrats ni les écrans.

---

## 5. Limites — honnêtement

1. **Aucun support ne s'affiche.** Aucun moteur PDF n'est dans `pubspec.yaml`, et je
   n'ai pas le droit d'en ajouter un (D-11). La fiche d'un PDF dit « L'aperçu de ce
   format n'est pas encore disponible dans l'application. Vous pouvez en enregistrer une
   copie. » `StructuredTextResource`, `ImageResource` et `LessonResource` sont dans le
   même cas. Seul le Coran a une issue, et elle appartient à Agent C. **Demande §2.1.**

2. **Le hors ligne ne survit pas à un redémarrage.** `DepotOctetsMemoire` tient ses
   octets en mémoire, exactement comme `CacheMediaFichiers` tient ses clés dans un `Set`
   en mémoire. Une ressource « Téléchargée » repasse donc à « À télécharger » au
   lancement suivant. La persistance exige une table Drift, donc une migration 1 vers 2
   qui n'existe pas, et `app_database.dart` porte un commentaire normatif interdisant
   d'en ajouter une sans justification de spec. **Demande §3.1.**

3. **`CacheMedia` n'est pas encore étendu, seulement doublé.** `DepotOctetsLocal` hérite
   de `CacheMedia` et ajoute `deposer` / `obtenir`. Tant que ces deux méthodes ne sont
   pas dans le contrat, le vrai `CacheMediaFichiers` n'est pas utilisable ici, et le
   cache disque du produit n'est donc **pas** celui que la Bibliothèque emploie.
   **Demande §3.**

4. **Aucune URL éphémère.** `ArtefactsLocaux.urlEphemere` lève `EchecArtefact` : sans
   bucket, il n'y a rien à signer, et rendre une URL qui ne mène nulle part serait pire
   que l'échec. **Demande §1.6.**

5. **La palette de couvertures est empruntée au thème.** Quatre teintes, dont deux
   portent déjà un sens ailleurs (`washAccent`, `washSuccess`). C'est assez pour que deux
   supports voisins se distinguent, ce n'est pas la palette administrée que la spec
   appelle. **Demande §4.**

6. **Quatre icônes de type sont des placeholders** annotés `// TC-ICONE:`. Les cinq
   types se distinguent malgré tout, par la teinte, le motif et le monogramme.
   **Demande §5.**

7. **Une seule disposition de carte, en ligne.** La grille de tuiles a été écartée pour
   une raison mesurable : une couverture a un rapport fixe, donc une hauteur qui suit la
   largeur de sa cellule ; posée dans une grille à hauteur bornée, elle déborde dès que
   la colonne s'élargit. La couverture grandit avec le gabarit (64 sur téléphone, 112
   au-delà) sans changer de disposition. C'est une simplification assumée, pas un oubli.

8. **La recherche par sourate et page est une reconnaissance de repère, pas une
   navigation.** `RechercheCatalogue.positionDemandee` rend une `ContentPosition` pour
   « 2:255 » ou « 40 », mais **ne valide aucun numéro** : borner une page à 604 ou un
   verset à sa sourate appartient au moteur d'Agent C. Et la position n'est pas
   transmise à la fiche, faute de renderer capable d'en faire quelque chose — c'est écrit
   en commentaire à l'endroit où elle est abandonnée, plutôt que transporté en silence
   jusqu'à un écran qui l'ignorerait.

9. **Les commentaires Dart sont en français sans accents.** C'est la convention de tout
   le dépôt, vérifiable dans n'importe quel fichier de `lib/`. Les **libellés
   utilisateur**, eux, portent leurs accents, comme dans `fr.i18n.json`. Les documents
   `.md` et le JSON sont entièrement accentués.

10. **Aucun `ContentRange` n'est produit par ce lot.** Le contrat est livré, testé, et
    consommé par personne ici : ce sont les marqueurs d'Agent D et l'état partagé
    d'Agent F qui en fabriqueront. C'est conforme, mais il faut le savoir avant de
    chercher son usage.

---

## 6. Ce qu'Agent Z devra brancher

Par ordre de ce qui bloque le plus.

1. **La redirection.** `redirection.dart` renvoie toute route hors préfixe de rôle vers
   la racine du rôle. Sans ajustement, `/tc/bibliotheque` est **inatteignable**. C'est
   le point le plus important de cette liste, et le plus facile à oublier.
2. **L'entrée de navigation.** `nav_shell.dart` est plafonné à quatre destinations par
   assertion, et l'enseignant en a déjà quatre. Le chemin recommandé est le **slot
   Bibliothèque de l'Espace Groupe d'Agent A** (`SlotBibliotheque`), qui ne coûte aucune
   destination et correspond à ce que décrit la spec. Voir CONTRACT_REQUEST §6.
3. **Les routes.** Appeler `routesTcB()` depuis `app_router.dart` et promouvoir
   `RoutesTcB.bibliotheque` / `.ressource` dans `routes.dart`.
4. **L'i18n.** Fusionner `docs/teaching-core/i18n/tc_i18n_B.json` dans
   `assets/i18n/fr.i18n.json`, régénérer slang, remplacer les constantes de
   `libelles_tc_b.dart` par `t.tc.bibliotheque.…`, puis **supprimer le fichier**. Les
   clés de la façade et du JSON sont identiques, une par une.
5. **Les providers.** Remplacer `portCatalogueProvider`, `portVersionsRessourceProvider`,
   `portTelechargementProvider` et `lecteurArtefactProvider` par les implémentations
   Supabase, une fois les tables créées. `portEtatOfflineProvider` et
   `donneesCatalogueProvider` n'ont **rien à changer** : ils sont écrits contre les
   ports.
6. **Les trois amendements de contrat** de CONTRACT_REQUEST §7, à valider ou à refuser
   avec Agent 0 : la forme de `ContentPosition._()`, la perte de `const` sur trois
   contrats porteurs d'une assertion UTC, et le sort de `EchecCatalogue` et
   `LecteurArtefact`.
7. **Le `DepotOctetsLocal`** disparaît le jour où `CacheMedia` gagne `deposer` et
   `obtenir` : `CacheMediaFichiers` satisfera alors l'interface sans changement, et le
   provider `depotOctetsProvider` pourra rendre le vrai cache disque.

---

## 7. Ce qui a été réutilisé, et ce qui ne l'a pas été

La règle « ne recrée jamais ce qui existe » se vérifie, elle ne se suppose pas.
`lib/core/widgets/` a été listé avant d'écrire le moindre composant.

**Réutilisé tel quel :** `PageShell` (et sa règle `defilante: false` pour un corps qui
gère son propre défilement, documentée par les cinq écrans qu'elle a fait disparaître en
release), `AppCard`, `StatusPill`, `EmptyState` et ses trois registres, `SectionHeader`,
`FilterPill`, `MenuFiltre`, `Skeleton`, `ActionPrincipale`, `LocalFeedback`,
`AppBottomSheet`, `Ecart`, `AppSpacing`, `AppRadius`, `AppPalette`, `AppGabarit`,
`AppIcons`, `horsLigneProvider`.

**Cinq composants créés**, tous dans mon répertoire, aucun ne doublant un existant :
`VignetteRessource` (aucune couverture n'existe dans le dépôt), `CarteRessource`
(`ChildCard` est une carte d'enfant, `BentoTile` une tuile de tableau de bord ; aucune ne
porte une couverture ni un état hors ligne), `SurfaceBibliotheque`, `ClassLibraryPicker`,
et les deux pages.

**Patrons copiés, fichiers non touchés :** les statuts de `service_programme.dart`
(`0020`), la forme interface/implémentation/faux de `service_reseau.dart`, la leçon de
`service_avatar.dart` (on persiste la clé, jamais l'URL signée), la forme de
`selecteur_fichier.dart` pour `port_enregistrement_fichier.dart`, la méthode de
`test/appairage/code_local_test.dart` pour prouver l'absence de dépendance LiveKit.

**Ce que je n'ai **pas** fait, alors que c'était tentant :** étendre `CacheMedia`,
ajouter une table à `AppDatabase`, ajouter `pdfrx` au `pubspec.yaml`, ajouter une teinte
à `app_palette.dart`, ajouter une icône à `app_icons.dart`, toucher `redirection.dart`
pour rendre ma route atteignable. Chacun de ces six gestes aurait débloqué quelque chose
en une ligne, et chacun est une demande de `TC_CONTRACT_REQUEST_B.md`.

---

## 8. Invariants produit, et où ils sont tenus

| Invariant | Où il est tenu |
|---|---|
| Une seule Bibliothèque (D-20) | `SurfaceBibliotheque`, montée par les deux surfaces ; `VueCatalogue.depuis` pour l'ordre |
| La source d'un support est immuable | `ResourceVersion` sans setter, `downloadAssetId` renseigné une seule fois ; aucune écriture de support nulle part dans ce lot |
| Un PDF n'est jamais régénéré | `PortTelechargement.artefactDe` **lit** un artefact ou rend `null` ; aucune fonction de génération n'existe |
| Le Coran reste une source structurée | Aucun renderer Coran ici ; `TypeRessource.quran` délègue, et la fiche le dit |
| Jamais un chemin `/sdcard` | `FilePicker.saveFile()`, et le résultat n'est jamais interprété comme un chemin |
| Capacité jamais codée en dur | Aucun « 5 », aucun plafond : le lot ne touche pas aux groupes |
| Heures en UTC | Assertions `isUtc` sur `ResourceVersion`, `DownloadAsset`, `ReprisLecture` ; aucun offset nulle part |
| Jamais une couleur seule (J7) | `StatusPill` partout pour l'état hors ligne : une pastille **et** un mot |
| Aucune commande vocale | Aucune |
| Aucune PII famille | Le lot ne lit aucun profil, aucun roster, aucune donnée de personne |
| « Interface guidée », jamais « mode enfant » | Aucun des 40 libellés n'emploie le mot |
