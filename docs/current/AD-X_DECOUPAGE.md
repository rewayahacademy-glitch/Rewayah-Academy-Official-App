# AD-X : découpage du reste de l'espace administration (05/10/2026)

**Étape** : AD-X (tableau board5), décidée par le directeur le 05/10 (« Oui, maintenant »,
`DECISIONS_0510.md`, ligne `ad-x`). **Branche** : `ui/admin-x`, base
`origin/ccr-1b1bfa0b-m1kvkk` (8cb178b9, admin le plus récent, AD-NETTOYAGE-2 compris).
`origin/ui/admin-v1` (a8dfcb34) et `origin/admin-complet` (b19c8d3f) n'ont **aucun commit
absent de la base** (`git log base..branche` vide) : rien de plus récent sur la coque admin.

**Sources** (lues avant ce découpage) : images du directeur
`origin/pilotage/tuteur-v1:11_admin/V/coque/` (ADMIN-SHELL-01 accueil, SHELL-02 espace de
traitement, SHELL-03 collection et inspecteur), `11_admin/V/00_MAQUETTES.md` et
`00_REPRISE.md` ; `DESIGN-GOV-2026-09-26.md` ; `03_DESIGN_SYSTEM_ET_UX.md` ; `lib/CLAUDE.md` ;
`DASH_STRATEGIE.md` (règles D1 à D14, acceptées le 05/10) ; consignes K-09, K-19, K-37, K-61,
K-63.

## 0. Règles qui cadrent tout le lot

- **K-63** : d'une maquette on prend la composition (ordre des zones, proportions, densité,
  panneaux, place des actions), jamais son style. Les pastilles colorées, photos, dégradés
  et fonds des images sont remplacés par les jetons et composants existants. La coque
  affichée est la coque réelle (`AdminShell`).
- **K-37** : aucune couleur, police ni durée nouvelle.
- **Capacité, jamais rôle** : les trois écrans vivent sous `_CoquilleAdmin` ; ils lisent
  des fournisseurs (services, ports), jamais `AppRole`. L'autorisation reste au serveur
  (RLS, RPC `admin`).
- **K-09** : aucune donnée de démonstration hors de `surchargesDemoAdmin` (garde compilée
  `environnementAutoriseDemo`). En production, une source absente dit « pas encore
  branché » (état `indisponible`), jamais un chiffre ou un nom inventé (DESIGN-GOV §1, D10).
- **Cinq états** par écran et par source : chargement (squelette à la forme du contenu,
  180 ms), contenu, vide, erreur (une source en échec n'emporte que ce qu'elle remplit,
  phrase K-59 + action), hors ligne (bandeau de `PageShell`, une seule fois, décision
  « hors-ligne » du 05/10).
- **Mots interdits** : « admin » (on dit la direction), « groupe » (on dit classe) dans un
  texte visible ; « KYC » remplacé (décision « mot-kyc »).

## 1. Le catalogue

Il n'existe **pas** de `docs/design/08-catalogue-ecrans.md` sur la base : le catalogue est
archivé (`docs/archive/2026-09-pre-remise-a-plat/design/08-catalogue-ecrans.md`), et
`DASH_STRATEGIE.md` Annexe A a déjà acté qu'on n'écrit pas dans une archive. **Décidé par
délégation le 05/10** : les fiches des trois écrans sont inscrites ici (§5), au format de la
fiche archivée, **avant le code**, et la ligne du registre est la suivante.

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `ADM-01` | Centre de commande (composition SHELL-01) | Direction | E | 0 | `/admin` | Tuiles puis activité | Tuiles + colonne « Activité récente » | **AD-X écran 1** |
| `ADM-18` | Espace de traitement (SHELL-02) | Direction | E | 1 | `/admin/operations/traitement` | File groupée par jour, détail en feuille | File 336 + détail 728 | **AD-X écran 2, nouveau** |
| `ADM-09` | Classes, collection et inspecteur (SHELL-03) | Direction | E | 1 | `/admin/operations/groupes` | Cartes, détail en feuille | Tableau dense + inspecteur 336 | **AD-X écran 3** |

Validation des fiches : par délégation le 05/10 (aucune page au directeur, prompt de l'étape).

## 2. Les trois écrans, ce qu'on prend de l'image et ce qu'on n'en prend pas

### Écran 1 : Accueil (ADMIN-SHELL-01) → `ADM-01`

L'image montre : en-tête (titre, sous-titre, date du jour et salutation au bord de fin) ;
une rangée de 4 tuiles chiffrées ; à gauche « Éléments à traiter » (puces de catégories,
5 lignes, « Voir tout ») puis « Charge du jour » (4 chiffres) ; à droite « Activité
récente » (5 lignes, « Voir tout ») puis « Calendrier du jour ».

**Décisions par délégation le 05/10** (dernière demande du directeur d'abord, puis règles
acceptées le même jour) :

1. **Les tuiles Bento restent** (BENTO-1, demande répétée « plus de 10 fois », K-61.8 ;
   DASH D3 à D5 acceptées le 05/10). Elles occupent la place de la rangée de tuiles et de
   « Éléments à traiter » : ce sont les mêmes files (dossiers, demandes, élèves sans
   enseignant, cahiers manquants), une tuile par file, avec les 3 plus anciens dossiers
   nommés (D4 a, D6).
2. **« Éléments à traiter » en liste n'est pas repris sur l'Accueil** : DASH Q1, acceptée
   le 05/10, l'a retirée (une liste non bornée sur un tableau de bord, D1). La liste unifiée
   existe désormais **sur sa page**, l'Espace de traitement (écran 2) ; l'Accueil y mène par
   un raccourci.
3. **« Activité récente » est reprise** : colonne de fin à partir du bureau (336, comme la
   file du contrat D), sous les tuiles sinon. Source réelle : `journal_audit()` (les
   3 dernières entrées, D6), « Voir tout » vers le Journal.
4. **« Charge du jour » n'est pas reprise** : elle répète les chiffres des tuiles (D7, une
   information une seule fois).
5. **« Calendrier du jour » n'est pas repris** : le directeur a décidé le 05/10 « Planning
   pour la direction : pas maintenant » (DASH-ADM-PLANNING) ; besoin serveur AD-X-BR-04.
6. **En-tête** : le titre reste « Centre de commande » (l'image dit « Bureau admin » :
   mot interne « admin » interdit). Le sous-titre de l'image est repris : « Vue d'ensemble
   de l'activité et des éléments à traiter. » La date du jour est reprise au bord de fin
   sur bureau (le client connaît la date, aucune donnée inventée). La salutation « Bon
   retour, Admin. » n'est pas reprise (`PageShell` : un titre ne se souhaite pas la
   bienvenue ; mot « Admin »).
7. Les 4 tuiles de l'image (élèves inscrits, enseignants actifs, classes actives, avec
   tendance du mois) n'ont **aucune source serveur** (AD-X-BR-03) : non affichées, rien
   d'inventé.

### Écran 2 : Espace de traitement (ADMIN-SHELL-02) → `ADM-18`, nouveau

L'image montre : barre de filtres (recherche, type, statut, date de dépôt, « Effacer les
filtres ») ; à gauche la file (« 124 éléments en attente », tri « Plus récent », groupes
Aujourd'hui / Hier / Cette semaine, lignes avatar + nom + nature, heure, pastille, chevron) ;
au centre le détail (en-tête nom, nature et date ; onglets Vue d'ensemble, Documents,
Historique, Notes ; « Informations générales » ; « Pièces et éléments soumis » ;
« Vérifications » ; « Refuser » et « Valider le dossier ») ; à droite « Contexte » et
« Activité récente ». « Opérations » est actif dans la barre latérale.

**Décisions par délégation le 05/10** :

1. **Route** `/admin/operations/traitement`, domaine Opérations. La racine `/admin/operations`
   y mène désormais (l'image montre « Opérations » actif sur cet écran). Classes (ADM-09)
   reste à son adresse. Une sous-navigation Opérations (`SelecteurSection`, ONGLETS-1) relie
   les deux : « Espace de traitement », « Classes ». Attribution et Demandes restent des
   fonctions secondaires atteintes depuis l'Accueil et depuis la file.
2. **La file réunit les deux sources réelles** : les dossiers d'identité en attente
   (`dossiers_en_attente()`, enseignants seulement, K-47) et les demandes en attente
   (`demandes_en_attente()`). Groupes Aujourd'hui / Hier / Cette semaine / Plus ancien, avec
   leur nombre. Tri : « Plus récent » par défaut (l'image), « Plus ancien » au choix.
3. **Filtres** : une rangée de `FilterPill` qui passe à la ligne (Tous, Dossiers, Demandes,
   avec leur nombre ; FILTRES-1 : choix dans une liste, saisie minimale), et le tri par
   `MenuFiltre`. Pas de recherche libre ni de filtre de statut ou de date : aucune donnée
   serveur de statut au-delà de « en attente » (AD-X-BR-01).
4. **Détail** : en-tête (nom, nature, « Déposé le … »), puis une carte « Informations
   générales » (`LigneCleValeur`), puis, à 16, **un seul bouton plein** au bord de fin :
   « Ouvrir le dossier » (vers ADM-02, le dossier par `extra`, jamais l'URL) ou « Ouvrir la
   demande » (vers ADM-06). **La décision ne se prend pas ici** : elle a ses écrans, ses
   confirmations et ses contrôles serveur (ADM-02 : vérifications, visionneuse, refus
   motivé ; ADM-06 : motif obligatoire). Les dupliquer ferait deux chemins pour une
   décision juridique (DESIGN-GOV §4.3).
5. **Contexte** (source, campagne, affectation, priorité, assigné à, échéance), **onglets**
   Documents, Historique, Notes et **Activité** du dossier : aucun contrat serveur
   (AD-X-BR-01, AD-X-BR-02). Une seule carte « Suivi du traitement » dit « pas encore
   branché » avec la raison (K-59), au lieu de champs vides. Rien d'inventé.
6. **Mobile et tablette** : la file seule ; toucher une ligne ouvre le même détail en
   feuille (`AppBottomSheet`). Bureau (largeur utile ≥ 336 + 24 + 728, texte < 200 %) :
   file et détail côte à côte, premier élément sélectionné sans déplacer le focus.

### Écran 3 : Collection et inspecteur (ADMIN-SHELL-03) → `ADM-09` Classes

L'image montre, sous « Pédagogie » : onglets de statut avec nombre (Toutes les classes,
En cours, Terminées, Archivées) et « Nouvelle classe » au bord de fin ; recherche et
quatre filtres (Niveau, Enseignant, Statut, Trier par) ; tableau dense (Classe, Enseignant,
Niveau, Élèves, Statut, Début, menu) avec case de sélection ; pagination ; à droite un
inspecteur (nom, sous-titre, statut, Informations générales, Progression, Élèves (3) avec
« Voir tous », Actions).

**Décisions par délégation le 05/10** :

1. **L'écran est la page existante des classes** (`/admin/operations/groupes`, ADM-09) :
   une seconde collection de classes sous Pédagogie dupliquerait la même donnée. La barre
   latérale est gelée (8 domaines) ; l'écran reste sous Opérations, atteint par la
   sous-navigation Opérations et le raccourci de l'Accueil. Écart avec l'image noté.
2. **Titre « Classes »** (décision « classes-groupes » du 05/10, « Classe, jamais
   groupe »). Tous les textes visibles de l'écran et de son inspecteur disent « classe » :
   colonne « Classe », bouton « Nouvelle classe » (l'image), intro, états vides, erreur,
   création, détail, clôture, états « Active » / « Clôturée », feuille d'observation
   (correction du 08/10 après vérification croisée, décidé par délégation le 08/10). Les
   clés et la route gardent `groupes` ; `titre`, `retirerTitre` et `modifierSeuilTitre`
   restent à la main de LIB-DIR-1 (`corrections/lib-dir-1`), pour ne pas croiser ce lot.
3. **Onglets de statut** en `FilterPill` avec nombre : « Toutes les classes », « Actives »,
   « Clôturées » (le serveur ne connaît que `actif` ; « En pause », « Terminées »,
   « Archivées » : AD-X-BR-08). « Nouvelle classe » reste le seul bouton plein, au bord de
   fin de cette rangée sur bureau.
4. **Filtre** « Public » en `MenuFiltre` (Tous les publics, Enfants, Adultes) à la place de
   la rangée de puces. Niveau, Enseignant et tri : pas de donnée Niveau (AD-X-BR-06) ;
   Enseignant et tri non repris (saisie minimale, une classe se retrouve par son nom dans
   le tableau). Pas de case de sélection multiple ni de pagination : aucune action groupée,
   la liste est complète.
5. **Inspecteur** à partir du bureau (texte < 200 %) : la ligne choisie s'ouvre dans un
   panneau de 336 au bord de fin (sélection marquée par fond, contour et `Semantics`,
   jamais la couleur seule) ; ailleurs, la feuille existante. Contenu : nom, public,
   statut ; « Informations générales » (enseignant, public, créneau, membres) ; « Élèves »
   (vraie liste `membres_groupe`, « Retirer » conservé) ; actions : « Ajouter un élève »
   (secondaire) et le menu existant (seuil, observation, clôture). Croix « Fermer
   l'inspecteur » qui rend le focus à la ligne.
6. **Progression**, niveau, date de début, dernière séance, séances de la semaine, état de
   connexion des élèves : aucune source (AD-X-BR-05 à 07) ; non affichés.

## 3. Ordre de travail

1. Ce découpage (commit seul).
2. Écran 1 : ADM-01, test d'écran + contre-épreuve, captures, poussé.
3. Écran 2 : ADM-18 (route, sous-navigation Opérations, page, démo), tests, captures, poussé.
4. Écran 3 : ADM-09 (statuts, filtre public, inspecteur), tests, captures, poussé.
5. `UX_REVIEW_AD-X.md`, suite admin sous verrou, jetons, rapport.

Fichiers interdits respectés : `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`,
valeurs de `lib/core/theme`, Coran, `dart_define.json`. Écrans Finance, Comptable,
Communications non touchés.

## 4. Besoins serveur (aucun n'est codé ici)

| Réf. | Écran | Besoin | Aujourd'hui |
|---|---|---|---|
| AD-X-BR-01 | ADM-18 | File unifiée des éléments à traiter, côté serveur : nature (dossier, demande, signalement, absence, document manquant), statut (à traiter, à vérifier, en revue, résolu), total fiable, tri et pagination par curseur ; assignation (« Assigné à », « Assigner »), échéance, priorité, source et campagne. | Deux lectures séparées (`dossiers_en_attente()`, `demandes_en_attente()`) réunies à l'écran ; carte « Suivi du traitement » « pas encore branché ». |
| AD-X-BR-02 | ADM-18 | Historique et notes internes d'un élément (onglets Historique, Notes), journal par élément. | Absent ; non affiché. |
| AD-X-BR-03 | ADM-01 | Compteurs élèves inscrits, enseignants actifs, classes actives, et leur variation du mois. | Absents ; non affichés. |
| AD-X-BR-04 | ADM-01 | Calendrier du jour de la direction (DASH-ADM-PLANNING, reporté par le directeur le 05/10). | Absent ; non affiché. |
| AD-X-BR-05 | ADM-09 | Progression d'une classe (chapitre courant, pages, pourcentage). | Absente ; non affichée. |
| AD-X-BR-06 | ADM-09 | Niveau d'une classe, date de début, séances de la semaine, dernière séance. | Absents ; non affichés. |
| AD-X-BR-07 | ADM-09 | État de connexion d'un élève (connecté, pas encore connecté, connexion interrompue). | Absent ; non affiché. |
| AD-X-BR-08 | ADM-09 | Statuts de classe au-delà d'actif / clôturé (en pause, terminée, archivée). | Seuls « Actives » et « Clôturées ». |

## 5. Fiches d'écran (format de la fiche archivée)

```
CODE              ADM-01
Nom               Centre de commande (composition ADMIN-SHELL-01)
Rôle              Direction
Route             /admin
Question          Qu'est-ce qui attend une décision, et que s'est-il passé ?
Composition       en-tête (titre, sous-titre, date au bord de fin sur bureau) ;
                  bureau : colonne principale (tuiles Bento, phrase calme,
                  raccourcis) + colonne de fin 336 « Activité récente » ;
                  sinon : tuiles, activité récente, raccourcis, empilés
Priorités         P0  tuiles Bento (inchangées, DASH §3.1)
                  P1  Activité récente : 3 dernières entrées du journal
                  P2  raccourcis : Espace de traitement, Classes, Comptes,
                      Accès des agents IA
Action principale     la tuile Dossiers (aucun bouton plein)
Actions secondaires   tuiles, noms de l'aperçu, « Voir tout » (Journal),
                      raccourcis
États             chargement  tuiles : Skeleton.tuileBento ; activité :
                              squelette de 3 lignes
                  vide        tuiles à 0 + phrase calme ; activité :
                              « Aucune activité récente. »
                  erreur      tuiles : une phrase (inchangé) ; activité :
                              phrase K-59 + « Réessayer », les tuiles restent
                  indispon.   activité en démonstration sans journal :
                              état « indisponible » (jamais en production :
                              journal_audit existe)
                  hors ligne  bandeau de PageShell
                  contenu     tuiles + activité + raccourcis
Invariants        le zéro s'affiche ; 5 indicateurs ; listes bornées à 3 ;
                  une information une seule fois
```

```
CODE              ADM-18
Nom               Espace de traitement (ADMIN-SHELL-02)
Rôle              Direction
Route             /admin/operations/traitement (racine /admin/operations)
Question          Que reste-t-il à traiter, et où le traiter ?
Composition       en-tête (titre, sous-titre, sous-navigation Opérations) ;
                  filtres (puces Tous / Dossiers / Demandes avec nombre, tri) ;
                  bureau : file 336 + détail 728 ; sinon file, détail en feuille
Priorités         P0  la file, groupée Aujourd'hui / Hier / Cette semaine /
                      Plus ancien
                  P1  le détail : Informations générales
                  P2  Suivi du traitement (pas encore branché)
Action principale     « Ouvrir le dossier » / « Ouvrir la demande », à 16 sous
                      la carte, bord de fin, seul bouton plein
Actions secondaires   puces, tri, lignes de la file
États             chargement  squelette de lignes de file
                  vide        « Rien à traiter pour le moment. » (+ filtre :
                              « Aucun élément avec ce filtre. »)
                  erreur      par source : l'autre source reste affichée,
                              phrase K-59 + « Réessayer » ; si l'autre est
                              vide, la phrase d'erreur seule (jamais « Rien
                              à traiter ») ; les deux : état d'erreur de page
                  hors ligne  bandeau de PageShell
                  contenu     file + détail
Invariants        aucune décision prise ici ; enseignants seulement dans les
                  dossiers (K-47) ; identifiant de personne jamais dans l'URL
```

```
CODE              ADM-09
Nom               Classes, collection et inspecteur (ADMIN-SHELL-03)
Rôle              Direction
Route             /admin/operations/groupes
Question          Quelles classes existent, et qu'y a-t-il dans celle-ci ?
Composition       en-tête (titre « Classes », intro, sous-navigation
                  Opérations) ; rangée statuts (Toutes / Actives / Clôturées,
                  avec nombre) + « Nouvelle classe » au bord de fin ; filtre
                  Public ; bureau : tableau dense + inspecteur 336 quand une
                  ligne est choisie ; sinon cartes + feuille
Priorités         P0  la collection
                  P1  l'inspecteur : informations, élèves, actions
Action principale     « Nouvelle classe » (seul bouton plein)
Actions secondaires   statuts, public, lignes, « Ajouter un élève »
                      (secondaire), menu d'actions, « Retirer »
États             chargement  squelette de liste ; membres : squelette
                  vide        « Aucune classe créée » / « Aucune classe avec
                              ce filtre »
                  erreur      liste : état d'erreur + « Réessayer » ;
                              membres : phrase dans l'inspecteur
                  hors ligne  bandeau de PageShell
                  contenu     collection (+ inspecteur)
Invariants        sélection jamais par la couleur seule ; l'inspecteur ne
                  remplace aucune confirmation (clôture, retrait motivés)
```

## 6. Reste connu (hors de ce lot)

- Déplacement des Classes sous Pédagogie comme sur l'image : demande une décision de
  structure (barre latérale gelée, `ongletsPedagogie` à cinq fonctions).
- Les besoins AD-X-BR-01 à 08.
