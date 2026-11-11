# UX_REVIEW SUPPORTS-ETAGERE (11/11/2026)

Lot : l'étagère des supports de la salle, leurs couvertures, « Afficher » et « Partager »
(demande du directeur du 11/11/2026 ; `docs/current/CAHIER-SALLE.md` §7). Statuts : présent dans
le code, testé localement (tests de widget et captures de test). **Pas testé sur staging, pas
déployé, pas prouvé par le directeur.**

## 1. Relevé : ce qui existe pour les supports, et ce qui bloque l'alphabet

Ce qui existe :

- **Données** : catalogue `library_resource` / `resource_version` / `library_resource_groupe`
  (migration `0032_tc_catalogue.sql`, RLS CAP-29), lu par `lib/core/tc_bibliotheque/`
  (`catalogue_supabase.dart`, `vue_catalogue.dart`). En production le 11/11 : 0 support (CONSTAT
  S-7).
- **Bibliothèque générique** (non montrée dans `/salle`) : `SurfaceBibliotheque`
  (`features/tc_catalogue`), `BibliothequeSeance` (aperçu personnel puis « Présenter »,
  `features/salle_seance/bibliotheque_seance.dart`) et `SupportPageFixe` (`vue_seance.dart`) : un
  support générique à pages existe dans la voie « salle de séance », mais pas dans le partage en
  direct de `/salle`. Réutilisé ici : `CouvertureRessource` (teinte stable, réservée au Coran),
  `SupportBibliotheque` (déplacé, élargi), le point d'insertion `PanneauBibliothequeSalle`.
- **Partage en direct dans `/salle`** : un pointeur `ContenuPresente` (page, sourate, verset)
  sur le sujet `contenu-presente` du canal de données LiveKit.

### Relevé revérifié le 11/11/2026 (lot PARTAGE-GENERIQUE) : ce qui est levé, ce qui reste

Statuts : présent dans le code, testé localement (tests de widget, captures de test). **Pas testé sur
staging, pas déployé, pas prouvé par le directeur. La migration est un brouillon non appliqué.**

Le chemin, de « l'enseignant choisit un support » à « l'élève le voit, suit la page, voit le pointeur
et les traits » :

| Étape | Où (fichier, ligne au 11/11) | Supposait le Coran ? | État après PARTAGE-GENERIQUE |
| :-- | :-- | :-- | :-- |
| Le message de présentation | `lib/core/video/video_session_provider.dart:478` (`ContenuPresente`), ``versJson` ligne 628 | Oui : `p`, `s`, `v` seulement, aucun identifiant de support | **Levé** : pour un support qui n'est pas le Coran, le message porte `d` (identifiant), `e` (version), `g` (page) et `n` (nombre de pages). Sans `d`, c'est le Coran : son message ne change pas d'un octet |
| L'envoi et la réception du message | `lib/core/video/livekit_session_provider.dart:688-760` | Non : il transporte le paquet sans le lire | Inchangé |
| Le rejeu à un élève qui arrive | `lib/features/salle/synchro_salle.dart:153-207` | Non : il renvoie le dernier contenu tel quel | Inchangé (le support générique est rejoué comme le Coran) |
| Le seul chemin de présentation | `lib/features/salle_enseignant/presentation_coran.dart:93-163` (`PresentateurCoran`) | Oui | **Levé** : un autre support part par `SallePage._partagerSupport` (`salle_page.dart:2438`) ; `PresentateurCoran` reste le chemin du Coran (il situe sourate et verset) ; `fermer()` range n'importe quel support |
| Le support présenté dans la salle | `lib/features/salle_seance/depuis_salle.dart:221` (`pageCoran`), `salle_page.dart:2884` | Oui : toujours `mushaf-madina-15`, 604 pages | **Levé** : `supportPresenteDe` (`lib/features/salle_seance/lecteur_support.dart`) rend le Coran, un support connu, ou un support inconnu |
| Le rendu de la page | `salle_page.dart:2131-2146` (rappel `page:` de `PorteeMediaSalle`) | Oui : `PageCoranSalle` ou `PageCoranPresentee` | **Levé** : un lecteur par support (`_pageDuSupport`) ; inconnu = « Ce support ne peut pas encore s'afficher ici » |
| La place de la page à l'écran | `lib/features/salle_seance/telephone_plein_ecran.dart:91-123, 200` (boîte au ratio du mushaf), `salle_ordinateur.dart:656` | Oui pour la boîte ; la page s'y composait sur toute la place | **Levé pour la page** : un support aux proportions fixes garde les siennes, centré dans la boîte (`telephone_plein_ecran.dart:329-337`, `SupportPageFixe.ratioFixe`). **Reste** : la boîte elle-même garde le ratio du mushaf (un livre plus large aura des marges ; rien n'est coupé ni étiré) |
| Le nombre de pages | `salle_page.dart` (flèches), `vue_presentation.dart:135`, `panneau_enseignant.dart:290, 473-476` | Oui : `pagesMushafMedine` (604) | **Levé dans la salle** (flèches : nombre de pages du support, `salle_page.dart:1988-1998`). **Reste** : `vue_presentation.dart` et `panneau_enseignant.dart` (ancien panneau d'avant l'entrée en salle, Coran seul) |
| Tourner la page (flèches, glissement au doigt) | `telephone_plein_ecran.dart:348-396`, `glisser_page.dart` | Non : ils appellent `onPagePrecedente` / `onPageSuivante` | Inchangé ; les rappels sont maintenant génériques (`_tournerPage`, `salle_page.dart:2453`) |
| « La page suit celle de l'enseignant » (élève) | `telephone_plein_ecran.dart:385-395` | Non (la phrase ne nomme pas le Coran) | Inchangé |
| Le pointeur | `lib/features/salle/synchro_salle.dart:365-449`, `surface_page_fixe.dart:482-486` | Non : un point de 0 à 1 sur la page (`ReperePage`) | Inchangé ; prouvé sur le support de démonstration (le point tombe au même endroit de la page, au téléphone) |
| L'écriture (traits) | `surface_page_fixe.dart:467-481` (`_CalqueNotes`), `synchro_salle.dart:462-473` | Non : coordonnées de la page, calque attaché à l'identifiant et à la version du support | Inchangé ; **non prouvé par un test sur le support de démonstration** (seul le pointeur l'est) |
| « Reprendre page N » | `lib/features/salle/memoire_page_classe.dart:39` (1 à 604), `position_reprise_supabase.dart:57`, `salle_page.dart:2826-2852` | Oui, et pire : toute page présentée était écrite comme page du Coran | **Levé** : la page d'un autre support n'entre plus jamais dans la mémoire du Coran ; elle a la sienne, par Classe et par support (`lib/features/salle/reprise_support.dart`) |
| La position au serveur | `supabase/migrations/20261110100000_cahier_c1_position_reprise.sql:49-50` (`support = 'mushaf'`, `page BETWEEN 1 AND 604`, une ligne par Classe) | Oui | **Brouillon non appliqué** : `supabase/migrations/20261123700000_partage_generique_position_support.sql` (table neuve, une ligne par Classe et par support ; la contrainte du Coran n'est pas touchée). Sans elle, la salle marche et dit « La page de ce support n'est pas encore retenue d'une séance à l'autre. » |
| Le chrono | `lib/features/salle_seance/chrono_salle.dart` | Non : il ne lit aucun support | Inchangé |
| Le cahier de transmission | `lib/features/cahier/cahier_page.dart:377, 570-594` | Oui : il lit la page du Coran retenue au serveur (`pageRepriseSeanceProvider`) | **Reste** : il ne propose que la page du Coran. Il ne peut plus recevoir par erreur la page d'un autre support |
| Le titre du support sur ordinateur | `lib/features/salle_seance/salle_ordinateur.dart:454` | Oui : « Coran · Page N » pour tout support | **Reste** (fichier d'un autre agent) : le texte générique `salle.support.titrePage` est prêt, non branché |
| « Ouvrir le Coran » sur la scène vide | `salle_page.dart:2112`, `zone_support.dart:569-591`, `telephone_enseignant.dart:171` | Oui | **Reste** : le raccourci de la scène n'ouvre que le Coran ; un autre support s'ouvre par la Bibliothèque |
| La feuille « Bibliothèque » du raccourci B | `salle_page.dart:2471-2497` (`_choisirSupport`) | Oui : une seule ligne, le Coran | **Reste** : la feuille ne liste que le Coran ; l'étagère (panneau, tiroir) liste tous les supports |
| La présentation lue par le tuteur et le contrôleur | `salle_page.dart` (`presentationObserveeProvider`), `depuis_salle.dart:245` | Autre source que le message ; non branchée au Coran non plus | **Reste**, hors de ce lot |
| La Bibliothèque de la salle | `salle_page.dart:2017-2024` | Oui : le Coran seul, construit en dur | **Levé** : le Coran, puis les supports de `supportsDeSalleProvider` (aucun en production ; le support de démonstration sous `PLAYGROUND` et dans les tests). **Reste** : la lecture du catalogue (`library_resource`), voir `docs/current/salle/SUPPORTS-A-VALIDER.md` |

Compatibilité entre versions de l'application (testée, `test/features/salle_partage_generique_test.dart`) :

- application nouvelle, message ancien (sans identifiant) : lu comme le Coran, même page ;
- application ancienne, message du Coran envoyé par une application nouvelle : le message est le même
  qu'avant, à l'octet près ; elle ouvre la même page ;
- application ancienne, message nouveau d'un autre support : elle lit « rien n'est présenté » (la clé `p`
  vaut 0) et garde la vidéo de l'enseignant en grand. Elle n'ouvre **pas** la page du Coran de même numéro
  et ne plante pas. L'élève ne voit donc pas le support tant que son application n'est pas à jour ; il
  entend le cours ;
- application nouvelle, support qu'elle ne connaît pas (identifiant ou version) : « Ce support ne peut pas
  encore s'afficher ici. », avec la raison et quoi faire.

Règles confrontées par PARTAGE-GENERIQUE (ce qui est visible et nouveau) :

| Règle | Source | Conclusion | Modification |
| :-- | :-- | :-- | :-- |
| Tout message de données incomplètes dit ce qui manque, la cause probable et quoi faire | `lib/CLAUDE.md` K-59 | « Ce support ne peut pas encore s'afficher ici. » : l'enseignant partage un support que cette version ne connaît pas ; le cours continue à la voix ; fermer puis rouvrir l'application la met à jour | `SupportIllisibleIci` |
| Un seul bouton plein | K-56 | « Réessayer » d'une page d'image en échec est en contour : « Partager » reste le seul plein | `PageImageSupport` |
| Rien ne réduit ni ne pousse la page du Coran | Directeur, 11/11/2026 | La page du Coran n'est pas touchée (mêmes boîtes, même lecteur, même message). Une page d'image garde ses proportions dans la même boîte | `SupportPageFixe.ratioFixe` |
| Une information, jamais une erreur, quand le serveur ne retient pas encore la page | Consigne du lot | La phrase se lit sur la fiche du support, à côté de sa reprise, en encre discrète ; aucune annonce, aucune boîte | `SupportBibliotheque.note` |
| Jamais présenté comme officiel | CAHIER-SALLE §7 | « À valider » sur la couverture, sur la fiche et sur chaque page du support de démonstration | `PageDemonstration` |

Non vérifié : `SupportIllisibleIci` et `PageDemonstration` à 320 points en texte ×2 (ils se réduisent d'un
bloc, lu dans le code, pas mesuré par un test) ; lecteur d'écran réel.

Petit et sûr, corrigé par SUPPORTS-ETAGERE : la Bibliothèque elle-même ne connaît plus aucun support (le fichier
`etagere_supports.dart` n'a ni « Coran » ni 604) ; chaque support arrive avec ce qu'il sait faire
(`LecteurSupport` pour « Afficher », `onPresenter` pour « Partager »). Le filtre « Récents »
faisait exactement la même chose que « Cette classe » (même condition, `pageReprise != null`) : il
est retiré.

## 2. Règles confrontées

| Règle | Source | Conclusion | Modification |
| :-- | :-- | :-- | :-- |
| Le support est générique ; tiroir, étagère, couvertures soignées, « Afficher » et « Partager » | CAHIER-SALLE §7 (directeur, 10-11/11/2026) | Appliqué dans le panneau existant | `EtagereSupports`, `CouvertureSupport`, `LecteurSupport` |
| Rien ne s'ouvre au milieu de la salle (ordinateur) | Composition du 26/10/2026, `lib/CLAUDE.md` | La fiche et la lecture seule se posent dans le panneau de droite, à sa place fixe | Trois vues dans le même panneau |
| Rien ne recouvre ni ne réduit la page du Coran | Pilote, règles du 11/11/2026 | « Afficher » lit la page dans le panneau ; la page partagée au centre ne bouge pas (capture `supports_1440_afficher_*`) | — |
| Un seul bouton plein (K-56) | `lib/CLAUDE.md` K-56 | « Partager » est plein : partager est le geste le plus courant en cours (l'enseignant ouvre un support pour la classe) ; « Afficher » est en contour. Page partagée en erreur : « Partager » passe en contour (règle existante) | Vérifié par `verifierUnSeulBoutonPlein` |
| Tout choix s'explique (K-58) | `lib/CLAUDE.md` K-58 | Chaque action a sa conséquence au-dessus d'elle : « La classe le voit maintenant. » / « Vous le regardez seul. La classe ne voit rien. » | Textes `salle.etagere.*` |
| Un bouton qui ne peut pas aboutir n'est pas rendu | `lib/CLAUDE.md` | Sans droit de présenter ou sans partage possible : pas de « Partager », une phrase le dit ; sans lecture : pas d'« Afficher » | `onPresenter` et `lecteur` facultatifs |
| Un widget lit une capacité, jamais un rôle | Invariant | Le droit de présenter reste vérifié au point d'insertion (`actions.onBibliotheque`, jeton `can_publish_data`) ; rien n'est élargi | Aucun changement de droit |
| LISTES-1 : le contenu d'abord | `DECISION-LISTES-2026-10-23.md` | Les couvertures d'abord ; filtres sur une rangée discrète ; recherche derrière une loupe, ouverte d'office au-delà de 8 supports | `seuilRecherche` |
| Couleurs : jetons seulement, aucune image inventée | `lib/CLAUDE.md`, marque | **Remplacé le 11/11 (reprise, §2 bis)** : la collection de l'académie dans les violets de la marque, le Coran en bleu nuit et or ; aucune image de mushaf | `AppCouleursCouverture` |
| Ornement de la marque | `assets/brand/logo/README.md`, `BRAND-ORN-1`, M-14, M-28 | Ornement par `OrnementMarque` seul, blanc sur le violet ; jamais le logo (README : jamais dans une liste) ; **aucune marque sur la couverture du Coran** | — |
| Lisible à 320, texte ×2, arabe, sombre ; jamais un mot coupé | `garde_interface`, `aucun_mot_coupe` | Le titre de couverture passe à la ligne et ne se réduit que si la hauteur manque, jamais en coupant un mot ; le dos du livre passe à droite en arabe | Tests 320 ×2 clair et sombre ; `salle_telephone_test` (390 et 834, ×1 et ×2) |
| États chargement, vide, erreur, hors ligne | Invariant | `EtatEtagere` : planches en `Skeleton`, `EmptyState` vide, erreur avec « Réessayer », hors ligne | Testés ; **non branchés** : la salle passe une liste synchrone (le Coran), ces états ne servent qu'au jour où la Bibliothèque lira le catalogue |

## 2 bis. Reprise du 11/11/2026 : couvertures aux couleurs de l'académie, Coran standard

Demande du directeur, mot pour mot : « n'oublie pas de brander les couvertures aux styles et couleurs
de l'académie ; le Coran, lui, doit avoir une couverture standard : si le complexe Roi Fahd n'en
fournit pas, tu en choisis une qui est en arabe, compréhensible et familière à tous les musulmans du
monde. »

### Les livres de l'académie : ce qui vient de la marque, source par source

| Élément | Décidé par | Ce qui est pris |
| :-- | :-- | :-- |
| Couleurs | Registre M-16 (les jetons font foi, violet du logo `#8652E6`) et M-32 (famille des violets de l'application : `#4E2983`, `#6538E4`, `#8652E6`) | Trois nuances de cette famille, encre blanche (10,6:1 ; 6,5:1 ; 4,8:1), regroupées dans `AppCouleursCouverture.academie` (`app_palette.dart`). Aucune valeur nouvelle : elles existent déjà dans la palette. Les teintes d'identité (lilas, pêche, orange) ne servent plus aux couvertures (M-23 : hors charte de marque). |
| Ornement | M-14, M-28, `BRAND-ORN-1`, README du logo (blanc sur fond violet) | `OrnementMarque` blanc, petit, sous le titre |
| Logo | README du logo, « Placement » : jamais dans une carte ni une liste | **Non posé** : l'étagère est une liste de supports |
| Typographie | M-15 (DM Sans pour les titres) | Le titre suit `titleMedium` du thème (DM Sans en français, la police arabe d'interface en arabe) |
| Ce qui distingue deux livres | **Mon choix** | Le titre, un repère (« Étape 1 », « Étape 2 » : étapes du programme, `programme-rewayah` §2) et la nuance de violet ; une seule maquette pour tous (dos, filet blanc, ornement) |

Point à valider : M-14 dit « jamais sur un écran de travail » pour l'ornement signature. Sur une
couverture, l'ornement est le décor d'un objet (M-28 l'admet pour les supports), pas la signature de
l'écran. C'est mon interprétation.

### La couverture du Coran

- **Couverture officielle du Complexe du Roi Fahd : aucune trouvée.** Le dépôt ne cite que les polices
  KFGQPC (`assets/fonts/LICENSE-UthmanicHafs.txt`, `LICENSE-UthmanTahaNaskh.txt`) et le texte
  Tanzil / quran.ws ; aucune licence d'image. Le site `qurancomplex.gov.sa`, lu le 11/11/2026, ne
  propose aucune image de couverture à télécharger ni aucune licence de réutilisation (« جميع الحقوق
  محفوظة », publications « قريباً »). Aucune image n'est copiée.
- **Dessin retenu (mon choix)** : bleu nuit, double filet doré, médaillon ovale à filet doré,
  « القرآن الكريم » en grand au centre, « مصحف المدينة » dessous. Ces deux textes sont déjà ceux de
  l'application (`ar.i18n.json`, `salle.coran.titrePage` = « القرآن الكريم، مصحف المدينة ») ; ils restent
  en arabe dans les deux langues (clés `salle.etagere.coranCouverture.*`, identiques en français et en
  arabe, exception déclarée dans `test/i18n/ar_domaines_test.dart`). Le lecteur d'écran lit le titre
  dans la langue de l'interface. Aucun verset, aucune image de mushaf réel, aucune marque de
  l'académie.
- **Police du titre** : KFGQPC Uthman Taha Naskh (`AppFontFamily.arabeDocument`, chargée après la
  première image quelle que soit la langue). Licence du Complexe : usage, copie et distribution
  gratuits, sans vendre ni modifier la police (`assets/fonts/LICENSE-UthmanTahaNaskh.txt`). Composer un
  titre avec elle est un usage. UthmanicHafs reste réservée au texte du Coran.
- **Couleurs nouvelles, à valider par le directeur** : `AppCouleursCouverture.coran` (fond `#0E2240`,
  titre `#E6C77A`, 9,7:1) et `filetCoran` (`#C9A44E`, 6,7:1), identiques en clair et en sombre. Bleu
  nuit plutôt que vert : la marque interdit « vert et or » comme identité périmée de l'académie
  (`marque-rewayah`, interdit 3) ; ce n'est pas l'identité de l'académie ici, mais le bleu nuit évite
  toute confusion. Pas de fond parchemin. Contrastes vérifiés par
  `test/widgets/couverture_support_test.dart`.

## 3. Le tiroir et la languette : franchement

- **Ordinateur** : un tiroir à languette posé en plus serait une **seconde poignée** pour la même
  chose. Le panneau de droite est déjà le tiroir : il s'ouvre et se ferme par la tuile
  « Bibliothèque » de la barre et la touche B, et se referme par sa croix. Ajouter une languette
  toujours visible au bord de l'écran contredit « un seul endroit par chose » (pilote, 11/11) et
  toucherait la barre (zone d'un autre agent). Ce qui est fait : le titre du panneau devient une
  **languette aux couleurs de la marque** (pilule violette de marque, ornement blanc, mot
  « Bibliothèque »), à côté de la croix. Rien ne recouvre la page.
- **Téléphone** : le tiroir des Commandes existe déjà (onglets Bibliothèque, Outils), l'étagère y
  vit dans l'onglet Bibliothèque, sans languette de plus (pas de place, et le téléphone réduit du
  10/11 garde le moins de commandes possible).
- **À trancher par le directeur** : s'il veut quand même une languette au bord de l'écran sur
  ordinateur, elle doit **remplacer** la tuile « Bibliothèque » de la barre, pas s'y ajouter
  (décision qui touche la barre du bas).

## 4. Réutilisable dans « Ma classe »

`EtagereSupports` (étagère, fiche, lecture seule) ne dépend ni de la séance ni du moteur de visio :
il prend une liste de `SupportBibliotheque`. `CouvertureSupport` est un composant du core, avec sa
fiche de galerie. Pour « Ma classe », il suffira de passer des supports sans `onPresenter`
(« Afficher » seul).

## 5. Limites connues

- Les captures sont des **captures de test** (vraie `SallePage`, moteur de visio simulé, page 42
  seule chargée) : pas la vraie application.
- « Afficher » lit la page dans le panneau de droite (environ 300 points de large) : lisible, plus
  petit que la page partagée.
- Sur le téléphone, la fiche ouverte demande de faire défiler le tiroir pour voir « Afficher ».
