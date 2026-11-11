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

Codé en dur pour le Coran, et qui empêcherait l'alphabet de se partager (non corrigé : c'est le
mécanisme de partage, hors de ce lot) :

| Où | Quoi |
| :-- | :-- |
| `lib/core/video/video_session_provider.dart:449-533` | `ContenuPresente` ne porte que `page`, `sourate`, `verset` ; le paquet `versJson` (`p`, `s`, `v`) n'a **aucun identifiant de support**. Un autre support ne peut pas voyager. |
| `lib/features/salle_enseignant/presentation_coran.dart:93-160` | `PresentateurCoran` : seul chemin de présentation, situe une sourate dans le mushaf. |
| `lib/features/salle_enseignant/vue_presentation.dart:135` | bornes de page = `pagesMushafMedine` (604). |
| `lib/features/salle_enseignant/panneau_enseignant.dart:290, 473-476` | position « page N / 604 » en dur. |
| `lib/features/salle_seance/depuis_salle.dart:163-172` | le support présenté est toujours `pageCoran` (`mushaf-madina-15`, 604 pages). |
| `lib/features/salle/salle_page.dart:1793-1830` | la Bibliothèque de la salle ne contient que le Coran, construit en dur ; `_choisirSupport` (feuille) idem. |
| `supabase/migrations/20261110100000_*.sql:49-50` | `classe_position_reprise.support CHECK (support = 'mushaf')`, `page BETWEEN 1 AND 604`. |

Petit et sûr, corrigé ici : la Bibliothèque elle-même ne connaît plus aucun support (le fichier
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
| Couleurs : jetons seulement, aucune image inventée | `lib/CLAUDE.md`, marque | Teinte `surfaceQuran` (Coran) ou `teintesIdentite` ; étiquette `surfaceRaised` ; aucune image de mushaf | `CouvertureSupport.teinteDe` (repris par `VignetteRessource`) |
| Ornement de la marque | `assets/brand/logo/README.md`, `BRAND-ORN-1` | Ornement décoratif, par `OrnementMarque` seul : violet sur l'étiquette claire, blanc sur l'étiquette sombre et sur la languette violette ; jamais le logo (interdit dans une carte ou une liste) | — |
| Lisible à 320, texte ×2, arabe, sombre ; jamais un mot coupé | `garde_interface`, `aucun_mot_coupe` | Le titre de couverture passe à la ligne et ne se réduit que si la hauteur manque, jamais en coupant un mot ; le dos du livre passe à droite en arabe | Tests 320 ×2 clair et sombre ; `salle_telephone_test` (390 et 834, ×1 et ×2) |
| États chargement, vide, erreur, hors ligne | Invariant | `EtatEtagere` : planches en `Skeleton`, `EmptyState` vide, erreur avec « Réessayer », hors ligne | Testés ; **non branchés** : la salle passe une liste synchrone (le Coran), ces états ne servent qu'au jour où la Bibliothèque lira le catalogue |

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
