# TC_CONTRACT_REQUEST_B — Agent B, Library Core

> Ce que la Bibliothèque ne peut pas obtenir sans qu'un fichier hors de mon périmètre
> change. Chaque demande dit la signature exacte attendue, **ce qui a été essayé avec
> l'existant avant de la formuler**, et ce que j'ai livré en attendant.
>
> Rien de ce qui suit n'a été contourné : aucune migration écrite, aucune dépendance
> ajoutée, aucun fichier du socle modifié.

---

## 1. DEMANDE SQL

### 1.1 `library_resource` — le manifeste (BLOQUANT)

**Ce qui a été cherché avant de demander.** `0001` à `0029` relues : aucune table de
ressource générique. Le contenu du produit est aujourd'hui entièrement codé autour du
Coran (`mushaf`, `sourate`, `juz`, `page_mushaf`, `verset`, `0007` et `0013`). Le seul
catalogue versionné existant est `programme_versions` / `programme_niveaux` (`0020`) :
c'est un curriculum, pas un catalogue de supports, et `0022` (lignes 5-12) interdit
explicitement de l'étendre avec des clés d'un autre domaine.

```sql
create table public.library_resource (
  id                 uuid primary key default gen_random_uuid(),
  title              text not null,
  short_title        text not null,
  cover_asset        text,            -- CLE de stockage, jamais une URL signee
  resource_type      public.library_resource_type not null,
  edition            text,
  language           text not null default 'fr',
  category           text not null default '',
  level_scope        text[] not null default '{}',   -- codes de programme_niveaux
  access_policy      public.library_access_policy not null,
  offline_policy     public.library_offline_policy not null,
  current_version_id uuid references public.resource_version(id),
  capabilities       text[] not null default '{}',
  created_at         timestamptz not null default now(),
  archived_at        timestamptz
);

create type public.library_resource_type as enum
  ('quran','structured_text','pdf','image','lesson');
create type public.library_access_policy as enum
  ('publique','inscrits','groupe_assigne','enseignant_seul','admin');
create type public.library_offline_policy as enum
  ('jamais','sur_demande','automatique');
```

**RLS attendue.** Lecture ouverte selon `access_policy`, résolue **en base** :
`publique` pour tous, `inscrits` pour tout `auth.uid()` ayant un profil,
`groupe_assigne` via `library_resource_groupe` (§1.4), `enseignant_seul` pour
l'enseignant assigné au groupe, `admin` pour `app_role() = 'admin'`. **Aucune écriture
par policy** : seules des RPC écrivent, comme `groupes` (`0017`, durcie `0019`).

**Deux règles de sécurité à répéter dans la migration**, telles que D-12 les impose :
1. **jamais `grant execute` à `agent_ro`** sur une RPC volatile ou d'écriture de ce lot ;
   `get_advisors` ne le détecte pas ([[feedback_agent_ro_jamais_sur_rpc_ecriture]]) ;
2. toute vue d'exposition **répète le filtre d'appelant et le masquage
   `agent_identite_masquee()` colonne par colonne** — le motif est dupliqué à la main
   dans le dépôt, et une surface oubliée est une fuite avec une bannière devant.

**Miroir Dart déjà écrit et prêt à consommer cette forme :**
`lib/core/tc_bibliotheque/library_resource.dart`, fabrique `LibraryResource.depuisJson`.
Les noms de colonnes ci-dessus sont ceux qu'elle lit.

### 1.2 `resource_version` — la version immuable (BLOQUANT)

**Le patron existe déjà et est testé** : `programme_versions` (`0020`) impose la
publication irréversible en base, pas côté client, et `creer_version_programme()` clone
une version. **Calquer, ne pas inventer un second vocabulaire de statuts.**

```sql
create table public.resource_version (
  id                uuid primary key default gen_random_uuid(),
  resource_id       uuid not null references public.library_resource(id) on delete cascade,
  numero_version    int  not null,
  statut            public.statut_version_ressource not null default 'brouillon',
  publiee_le        timestamptz,
  publiee_par       uuid references public.profiles(id),
  download_asset_id uuid references public.download_asset(id),
  empreinte         text,                       -- sha256 du contenu
  unique (resource_id, numero_version)
);

create type public.statut_version_ressource as enum
  ('brouillon','publiee','archivee');
```

**Contrainte non négociable, en base :** un `update` sur une ligne dont `statut`
vaut `publiee` ou `archivee` est refusé, sauf la transition `publiee -> archivee`.
C'est exactement ce que fait `0020` ; le client ne doit pas être le gardien.

### 1.3 `download_asset` — l'artefact dérivé

```sql
create table public.download_asset (
  id                  uuid primary key default gen_random_uuid(),
  resource_version_id uuid not null references public.resource_version(id) on delete cascade,
  format              public.format_artefact not null,
  cle_stockage        text not null,      -- CLE, jamais une URL signee
  taille_octets       bigint not null,
  empreinte           text,
  origine             public.origine_artefact not null,
  cree_le             timestamptz not null default now(),
  unique (resource_version_id, format)
);

create type public.format_artefact  as enum ('pdf','epub','audio','image');
create type public.origine_artefact as enum ('genere_a_la_publication','importe_tel_quel');
```

**L'unicité `(resource_version_id, format)` est ce qui tient la règle produit** « ne
jamais générer un PDF à chaque clic » : il ne peut pas y avoir deux PDF pour une même
version, donc rien à régénérer.

### 1.4 `library_resource_groupe` — « Pour ce groupe »

```sql
create table public.library_resource_groupe (
  resource_id uuid not null references public.library_resource(id) on delete cascade,
  groupe_id   uuid not null references public.groupes(id) on delete cascade,
  epinglee    boolean not null default false,
  ajoutee_le  timestamptz not null default now(),
  ajoutee_par uuid references public.profiles(id),
  primary key (resource_id, groupe_id)
);
```

RPC de lecture attendue, **bornée par rôle** et non par le client :

```sql
-- Les ressources visibles par l'appelant pour ce groupe.
-- Refuse si l'appelant n'est ni membre, ni tuteur d'un membre, ni l'enseignant
-- assigne, ni admin.
create function public.ressources_du_groupe(p_groupe_id uuid)
returns setof public.library_resource
language sql stable security definer;
```

### 1.5 `library_reading_position` — « Continuer »

**Ne pas étendre `student_reading_position`.** Elle existe (`0007`) mais elle est liée
au mushaf (`page_mushaf`, `sourate`, `verset`, `zoom_level`), et son **invariant J2**,
inscrit en commentaire dans la migration, dit qu'elle ne porte aucune référence à une
séance et qu'une page tournée par l'enseignant pour toute la classe ne doit jamais
l'écrire. Une position générique multi-ressources est autre chose.

```sql
create table public.library_reading_position (
  profile_id          uuid not null references public.profiles(id) on delete cascade,
  resource_id         uuid not null references public.library_resource(id) on delete cascade,
  resource_version_id uuid references public.resource_version(id),
  type_ancrage        public.type_ancrage_contenu not null,
  page                int,
  sourate             int,
  ayah                int,
  section_id          text,
  fraction            double precision,
  vue_le              timestamptz not null default now(),
  primary key (profile_id, resource_id),
  constraint un_seul_ancrage check ( /* exactement un groupe de colonnes renseigne */ )
);

create type public.type_ancrage_contenu as enum ('page','ayah','section','fraction');
```

**La contrainte `un_seul_ancrage` doit exister en base**, et pas seulement dans
l'assertion Dart de `ContentPosition` : un client ne garde pas un invariant de données.

### 1.6 Bucket Storage `supports`

Aucun bucket n'existe en dehors de `kyc` et `avatars` (`0004`, lignes 992-1060).
Il en faut un pour les artefacts **et** les couvertures, avec la même règle que les
avatars : **on persiste la clé, l'URL signée se redemande** (`service_avatar.dart`
ligne 148, `dureeUrlSecondes`). Policies de lecture alignées sur `access_policy`.

---

## 2. DÉPENDANCE DEMANDÉE

### 2.1 Un moteur de rendu PDF

**Ce qui a été essayé avec l'existant.** `pubspec.yaml` relu en entier : aucun moteur
PDF, aucun rendu Markdown, et `flutter_cache_manager` ne rend que des octets. Aucune
composition à partir de l'existant ne peut afficher une page de PDF. J'ai donc livré
l'état explicite plutôt qu'un faux aperçu : la fiche d'une ressource PDF affiche
« L'aperçu de ce format n'est pas encore disponible dans l'application. Vous pouvez en
enregistrer une copie. », et « Enregistrer une copie » fonctionne.

| Paquet | Argument | Réserve |
|---|---|---|
| **`pdfrx` (^1.x)** — recommandé | Un seul paquet pour Android, iOS, web, Windows, macOS et Linux. Le web est **obligatoire** ici : la production est servie par Vercel. Rendu par PDFium, donc fidèle. | Embarque PDFium : c'est le poste de poids à mesurer contre les 20 Mo de `docs/produit/bibliotheque-contenu.md`. Licence à vérifier par Agent Z avant adoption. |
| `pdfx` | Plus léger sur mobile. | Web par PDF.js, donc une seconde chaîne de rendu à valider. |
| `syncfusion_flutter_pdfviewer` | Le plus complet. | Licence Syncfusion, contrainte commerciale. **À écarter sauf décision opérateur.** |

**Ce qu'il faut mesurer avant d'ajouter, et que je ne peux pas mesurer sans l'ajouter :**
la taille du bundle web après ajout. `pubspec.yaml` porte déjà un commentaire normatif
sur `sentry_flutter` bloqué en 8.x pour ne pas rétrograder `path_provider_android`,
« qui porte le répertoire du cache Drift, donc le mode hors ligne, qui est un invariant
produit » : une dépendance ajoutée à la légère casse le hors ligne sans que personne le
voie.

**`flutter_markdown` n'est pas demandé.** `StructuredTextResource` peut se rendre avec
`RichText` et le `TextTheme` existant si le contenu arrive structuré depuis la base,
ce qui est de toute façon le choix de `docs/produit/bibliotheque-contenu.md`
(« zéro PDF comme outil principal de texte »). Le rendu appartiendra au lot qui
définira la forme des blocs.

**Aucune autre dépendance n'est demandée.** En particulier ni `share_plus` ni
`path_provider` : `file_picker 12.2.0` expose `saveFile()`, et la règle « passer par le
sélecteur système, jamais `/sdcard` » est tenue avec lui seul (décision D-11).

---

## 3. EXTENSION DE `CacheMedia` (fichier PROTECTED)

`lib/core/cache/media/cache_media.dart` sait **retirer** un fichier et **lister** ses
clés. Il ne sait ni en déposer un, ni en relire un. Le PROMPT B interdit de l'éditer et
impose de l'étendre par un port : c'est fait, mais l'extension doit finir dans le
contrat existant.

```dart
// Deux methodes a ajouter a `abstract interface class CacheMedia` :

/// Depose des octets sous une cle.
Future<void> deposer(String cle, List<int> octets);

/// Relit les octets d'une cle. `null` quand rien n'est conserve.
Future<List<int>?> obtenir(String cle);
```

**Ce que j'ai livré en attendant.** `DepotOctetsLocal` dans
`lib/core/tc_telechargement/port_etat_offline.dart` : une interface qui **hérite** de
`CacheMedia` et ajoute ces deux méthodes exactes. Le jour où elles rejoignent le
contrat, `CacheMediaFichiers` satisfait `DepotOctetsLocal` sans une ligne de changement
de mon côté, et le port disparaît.

### 3.1 Persistance des clés — le vrai manque du hors ligne

`CacheMediaFichiers` tient ses clés dans un `Set` **en mémoire** : rien ne survit à un
redémarrage. Mon `DepotOctetsMemoire` hérite de la même limite, et je l'ai écrite dans
le code plutôt que de la laisser découvrir. **Conséquence produit : une ressource
« Téléchargée » repasse à « À télécharger » au lancement suivant.**

La correction demande une table locale Drift, donc une **migration Drift 1 vers 2 qui
n'existe pas**, et `app_database.dart` porte un commentaire normatif : « exactement
quatre tables, ni plus ni moins ; toute table supplémentaire doit d'abord être
justifiée dans la spécification ». La justification est ici — un invariant produit,
le hors ligne — mais la décision et la migration appartiennent à Agent Z.

```dart
/// Index local des ressources conservees hors ligne.
class RessourcesHorsLigne extends Table {
  TextColumn get resourceId => text()();
  TextColumn get versionId  => text()();
  TextColumn get cleCache   => text()();
  BoolColumn get epinglee   => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deposeeA => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{resourceId};
}
```

⚠ La table `PagesMushafConsultees` existe déjà, est générée, et est **morte** : aucun
code de `lib/` ne l'écrit ni ne la lit. Son modèle page-image est incompatible avec un
corpus structuré. **Ne pas construire dessus sans la redéfinir, et ne pas en créer une
cinquième à côté.**

---

## 4. JETON DE DESIGN DEMANDÉ — la palette de couvertures

La spec veut des couvertures « visuellement reconnaissables », « persistantes et
distinctes », et reproche nommément à l'existant une grille d'icônes génériques
identiques.

**Ce que j'ai livré.** Un repli déterministe à trois axes : une teinte parmi quatre
paires **existantes** du thème, un motif parmi quatre, et un monogramme tiré du titre
court. Douze combinaisons pour les ressources non coraniques, chacune portant deux
lettres différentes. L'empreinte est stable sur toutes les plateformes, web compris.

**Ce qui manque, et pourquoi je ne l'ai pas pris.** `lib/core/theme/app_palette.dart`
est le seul fichier du dépôt autorisé à poser une couleur littérale, et il est
READ-ONLY. Quatre teintes sont peu pour une bibliothèque qui grandira, et deux d'entre
elles (`washAccent`, `washSuccess`) portent déjà un sens ailleurs dans le produit.

**Demande :** une palette de couvertures administrée, sur le modèle exact de celle des
groupes (décision D-18, cible 32 à 40 teintes accessibles), exposée comme
`AppPalette.teinteCouverture(int index)` ou une liste de `AppColorPair`. Le code
n'aurait alors qu'à changer `CouvertureRessource.nombreTeintes` et la fonction
`VignetteRessource.teinte`.

---

## 5. ICÔNES DEMANDÉES

`lib/core/icons/app_icons.dart` est le seul fichier autorisé à construire un `IconData`,
et la CI refuse tout `Icons.` ailleurs. Quatre icônes manquent pour distinguer les types
de ressource. Des placeholders annotés `// TC-ICONE:` sont en place dans
`lib/features/tc_catalogue/vignette_ressource.dart`.

| Souhaitée | Usage | Placeholder actuel |
|---|---|---|
| `fichierPdf` | Type `pdf` | `AppIcons.dossiers` |
| `texteStructure` (article) | Type `structured_text` | `AppIcons.cahier` |
| `image` | Type `image` | `AppIcons.qr` |
| `lecon` | Type `lesson` | `AppIcons.pedagogie` |

`AppIcons.coran` existe et convient exactement au type `quran` : rien à demander.

---

## 6. ROUTES ET NAVIGATION

`lib/features/tc_catalogue/routes_tc_b.dart` expose
`List<RouteBase> routesTcB({String? groupeId})`, sous le préfixe réservé :

- `/tc/bibliotheque` → `BibliothequePage`
- `/tc/bibliotheque/:resourceId` → `DetailRessourcePage`

**Deux points qu'Agent Z doit trancher, et qu'aucune ligne de mon périmètre ne peut
régler :**

1. **`redirection.dart` renvoie toute route hors du préfixe de rôle vers la racine du
   rôle.** Sans ajustement, ces deux routes sont **inatteignables**, quelle que soit la
   qualité du reste. C'est le piège nommé de la décision D-04.
2. **Une route sans entrée de navigation n'existe pas**
   ([[feedback_brancher_l_entree_pas_la_route]]). Or `nav_shell.dart` est PROTECTED et
   **plafonné à quatre destinations par assertion**, et l'enseignant en a déjà quatre.
   Ouvrir la Bibliothèque depuis la barre est donc un **arbitrage produit**, pas un
   patch. Deux chemins possibles, et je ne choisis pas :
   - la Bibliothèque vit **dans l'Espace Groupe d'Agent A**, par le slot prévu
     (`SlotBibliotheque`) — c'est ce que la spec décrit, et cela ne coûte aucune
     destination ;
   - ou une destination remplace une existante, ce qui demande une décision opérateur.

---

## 7. AMENDEMENTS PROPOSÉS AU CONTRAT CANONIQUE

Trois écarts, tous déclarés plutôt que silencieux.

### 7.1 `ContentPosition._()` n'est pas implémentable tel qu'écrit

`TEACHING_CORE_CONTRACTS.md` §7 écrit :

```dart
const ContentPosition._();
```

Des champs `final` ne peuvent pas être initialisés par un constructeur sans paramètre.
La forme livrée garde **la surface publique exacte** — les quatre constructeurs nommés
`.page`, `.ayah`, `.section`, `.fraction` — et donne au constructeur privé les
paramètres qu'il lui faut, plus les assertions qui tiennent l'invariant « un seul
ancrage à la fois ». **Aucun consommateur n'est affecté** : personne n'appelle un
constructeur privé.

### 7.2 Trois contrats ne peuvent pas être `const`

`ResourceVersion`, `DownloadAsset` et `ReprisLecture` portent une assertion
`isUtc`. Un getter d'instance ne s'évalue pas à la compilation, donc leur constructeur
ne peut pas être `const`. Le choix retenu : **garder l'assertion d'UTC**, qui est une
règle de contrat (CONTRACTS §0), et abandonner `const`, qui n'en est pas une
(« constructeur `const` **quand c'est possible** »). À confirmer par Agent 0.

### 7.3 Deux types ajoutés, à promouvoir ou à refuser

- **`EchecCatalogue`** (`lib/core/tc_bibliotheque/port_catalogue.dart`) : exception de
  domaine, dans l'esprit de CONTRACTS §0 (« un port rend un résultat typé ou lève une
  exception de son domaine `EchecXxx` »). Elle permet à l'écran de distinguer un refus
  serveur d'une absence — deux états qui ne se disent pas de la même façon.
- **`LecteurArtefact`** (`lib/core/tc_telechargement/port_telechargement.dart`) : port
  local. Il manque parce que « Enregistrer une copie » a besoin d'**octets**, que
  `PortTelechargement.urlEphemere` rend une **URL**, et qu'aucun client HTTP n'est
  exposé dans `lib/`. Soit `PortTelechargement` gagne une méthode `octets(DownloadAsset)`,
  soit ce port est promu au contrat partagé. **Je n'ai pas tranché seul :** la signature
  est isolée dans un fichier que je possède, et rien d'autre ne la consomme.

Aucune méthode n'a été ajoutée à un port **produit par un autre agent**, et aucun stub
de port externe n'a été écrit : Agent B ne consomme aucun port (OWNERSHIP §2).
