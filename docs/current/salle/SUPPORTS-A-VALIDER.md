# Supports de démonstration « à valider » (lot SUPPORTS-ETAGERE, 11/11/2026)

Statut de tout ce document : **proposition, à valider par le directeur**. Rien ici n'est un
contenu officiel. Aucun contenu religieux ni pédagogique n'est écrit : seuls des titres tirés du
programme et la place de chaque support dans le parcours. Aucune donnée n'a été écrite en base,
ni en production ni sur staging.

Source unique : compétence `programme-rewayah` (§2 « Niveau 1 Les bases », §4 « Les supports de
Rewayah »). Rappels qui s'imposent à ces supports :

- Rewayah écrit ses propres supports, avec le directeur ; le livre de lecture s'inspire de Nour
  al-Bayân et d'Al-Qâ'ida an-Nûrâniyya **sans les copier** ; on ne cite jamais les pages d'une
  édition d'un autre éditeur (§4).
- Chaque ligne de chaque support est numérotée (support, page, ligne) (§4) : c'est ce qui
  permettra à la salle de dire « la classe s'était arrêtée page 12, ligne 4 ».
- Les illustrations des ablutions et de la prière sont créées par IA puis validées par le
  directeur (§4).

## La liste proposée

| Ordre | Titre proposé (texte de l'app) | À quoi il sert | Pages | Source dans le programme | Statut |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Les lettres (`salle.etagere.demo.lettres`) | Étape 1 des bases : reconnaître et prononcer les lettres. Premier support réel annoncé par le cahier de la salle (§7 : « l'alphabet ») | à définir par le directeur | §2, Niveau 1, étape 1 ; §4 livre de lecture Rewayah | à valider par le directeur |
| 2 | Lire avec les voyelles (`salle.etagere.demo.voyelles`) | Étape 2 des bases, jusqu'à la chadda | à définir | §2, étape 2 ; §2 « 6 à 9 ans : le livre seul jusqu'à la chadda » | à valider par le directeur |
| 3 | Les paroles de la prière (`salle.etagere.demo.priere`) | Matière secondaire (6-9 ans après la chadda) : paroles de la prière et ablutions, montrées en pratique et par illustrations, sans fiqh détaillé | à définir | §2 « 6 à 9 ans » ; §4 illustrations | à valider par le directeur |
| (4) | Lire dans le Coran, fin du livre | Étape 3 des bases (fin du livre de lecture, puis le Mushaf) | à définir | §2, étape 3 | idée seulement, non montrée |
| (5) | Les invocations | Matière secondaire | à définir | §2 | idée seulement, non montrée |

Les sourates courtes (étape 4, d'Al-Masad à Az-Zalzalah) ne sont **pas** un support à part : elles
se lisent dans le Coran, déjà sur l'étagère avec sa couverture.

Ce qui est montré aujourd'hui, et où :

- les trois premiers titres, chacun avec la mention « À valider » sur sa couverture et la phrase
  « Support de démonstration, à valider par la direction. Son contenu n'est pas encore officiel. »
  sur sa fiche ;
- **seulement** dans la galerie de développement (`CouvertureSupport`, derrière `GALERIE`), dans
  les tests (`test/features/salle_enseignant/etagere_supports_test.dart`) et dans les captures
  `docs/current/captures/E2E/supports-etagere/supports_demo_a-valider_*.png`. La salle réelle ne
  montre que le Coran : aucune donnée inventée n'y apparaît.
- Ces trois titres n'ont ni page ni partage : leur fiche le dit (« Ce support ne s'ouvre pas encore
  dans la salle. La direction prépare son contenu. ») et ne propose aucun bouton.

### Le support de démonstration qui se partage (lot PARTAGE-GENERIQUE, 11/11/2026)

Pour prouver que le partage ne dépend plus du Coran, un quatrième objet existe, **factice** :

- titre « Les lettres » (le même texte `salle.etagere.demo.lettres`), 4 pages ;
- chaque page ne porte que : « À valider », le titre, « N / 4 », et « Support de démonstration, à valider
  par la direction. Son contenu n'est pas encore officiel. » **Aucune lettre, aucun exercice, aucun texte
  religieux.** Il sert à essayer le partage, jamais à enseigner ;
- où il existe : sous `PLAYGROUND=true` (que le déploiement force à `false`), dans les tests
  (`test/features/salle_partage_generique_test.dart`) et dans les captures
  `docs/current/captures/E2E/partage-generique/`. **Jamais en production, jamais en base** : il est écrit
  dans le code (`supportDemonstration`, `lib/features/salle_seance/lecteur_support.dart`), pas dans une
  table ;
- ce qu'il fait comme le Coran : « Partager », « Afficher », « Partager page N », tourner la page, suivre
  chez l'élève, pointeur. Sa reprise d'une séance à l'autre attend la migration (brouillon non appliqué).

## Comment un support entre dans les données (relevé du 11/11)

Tables (migration `0032_tc_catalogue.sql`, puis CAP-29) :

- `library_resource` : `title`, `short_title`, `cover_asset`, `resource_type`
  (`quran`, `structured_text`, `pdf`, `image`, `lesson`), `access_policy`
  (`publique`, `inscrits`, `groupe_assigne`, `enseignant_seul`, `admin`), `current_version_id`,
  `archived_at`.
- `resource_version` : `statut` (`brouillon`, `publiee`, `archivee`), publication irréversible.
- `library_resource_groupe` : le support rattaché à une classe (« Cette classe »).
- RLS (`20261011112954_cap29_library_visibility.sql`, lignes 9-46) : un non-administrateur ne voit
  une ressource que si `archived_at is null` **et** `current_version_id is not null` (une version
  publiée) ; l'administration voit tout.

**Conclusion : aucune migration n'est nécessaire** pour poser un support « à valider » visible de
la direction seule. Il suffit d'une ressource dont la seule version est `brouillon`
(`current_version_id` nul) et, par prudence, `access_policy = 'admin'` : la RLS existante la cache
à tout autre rôle. « À valider » = version `brouillon` ; « validé par le directeur » = la
publication de la version (geste de la direction, déjà prévu par CAP-29). Aucun brouillon de
migration n'a donc été écrit, aucun numéro réservé.

Ce qui manque pour aller plus loin (à décider par le directeur, pas dans ce lot) :

1. le contenu lui-même (pages, lignes numérotées), écrit avec le directeur ;
2. une insertion de ces lignes (par l'écran de la direction déjà prévu, ou un script appliqué par
   le pilote sur staging d'abord) : rien n'a été écrit ;
3. le branchement de la Bibliothèque de la salle sur le catalogue (aujourd'hui elle liste le Coran,
   construit dans `salle_page.dart`, et les supports de `supportsDeSalleProvider`, vide en production).
   Le partage en direct, lui, sait transporter un autre support que le Coran depuis le lot
   PARTAGE-GENERIQUE (codé, non fusionné, non prouvé en production : voir
   `docs/current/UX_REVIEW_SUPPORTS-ETAGERE.md` §1).

## Comment un support réel entrera dans la salle (proposition du lot PARTAGE-GENERIQUE, à valider)

Rien de ce qui suit n'est fait. C'est le chemin proposé, écrit pour que le directeur le corrige.

1. **Le format** : une image par page (PNG ou JPEG), toutes aux mêmes dimensions, numérotées de 1 à N.
   C'est ce que le lecteur simple de la salle sait rendre (`PageImageSupport`). L'application n'a aucun
   lecteur de PDF : un PDF se convertit en images au moment du dépôt (par la direction ou par un outil,
   à décider), il ne se partage pas tel quel. Le Coran n'est pas concerné : il garde son lecteur, et
   n'est jamais une image.
2. **Où le déposer** : dans la Bibliothèque existante (`library_resource` de type `image`, une
   `resource_version`, les fichiers dans le stockage privé déjà prévu par CAP-29). Aucune table nouvelle
   n'est nécessaire pour le contenu. Ce qui manque et n'est pas écrit : le nombre de pages et les
   dimensions d'une page dans la version (à lire depuis ses fichiers ou à poser dans ses métadonnées :
   décision technique à prendre avec le premier support), et l'écran de dépôt de la direction.
3. **Qui le valide** : le directeur. « À valider » = la version reste `brouillon` (la RLS la cache à tout
   le monde sauf à la direction). « Validé » = la direction publie la version (geste déjà prévu par
   CAP-29, irréversible). Un support non publié n'apparaît dans aucune salle.
4. **Ce que la salle fera alors** : l'identifiant de la ressource et celui de sa version publiée
   deviennent l'identifiant et la version du message de partage ; la Bibliothèque de la salle lira le
   catalogue au lieu de la liste écrite dans le code (`supportsDeSalleProvider`, aujourd'hui vide en
   production) ; l'élève qui a le droit de lire la ressource verra ses pages ; celui dont l'application
   ne la trouve pas lira « Ce support ne peut pas encore s'afficher ici. »
5. **La reprise** (« La classe s'était arrêtée page N ») : elle demande la migration
   `20261123000000_partage_generique_position_support.sql`, brouillon non appliqué. Tant qu'elle n'est pas
   installée, la page n'est retenue que le temps de la séance, et l'enseignant le lit.
6. **Ligne numérotée** (programme §4 : support, page, ligne) : non traitée. Le partage retient une page,
   pas une ligne.

Questions au directeur : le format « une image par page » convient-il ? Qui convertit un PDF ? Le nom
exact et le nombre de pages du livre des lettres ?
