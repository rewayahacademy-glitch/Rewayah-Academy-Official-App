# DASH-1 : stratégie des tableaux de bord (02/10/2026)

Statut : **document seul, aucun code**. DASH-1 décide du **contenu** des tableaux de bord.
BENTO-1 (fait, `lib/core/widgets/grille_bento.dart`) décide de leur **forme**.
Branche `corrections/c2-dash1`, partie de `corrections/revue-directeur-2026-10` @ `0796f75`.

## 0. La demande

Demande répétée du directeur (relayée par l'étape DASH-1, 02/10/2026) :

> « Le tableau de bord actuel affiche tous les dossiers. Je veux un simple résumé : quelques
> indicateurs et ce qui demande une action, avec des liens ou boutons vers les pages dédiées
> où se fait le travail (dossiers, groupes, planning…). »

Demande répétée : elle passe devant le reste du lot (`LECONS_DES_ROLES.md` l.214, K-61.8).

Ce qui est vrai aujourd'hui sur le Centre de commande :
- la liste « À traiter en premier » rend **toutes** les lignes, sans plafond
  (`lib/features/admin_tableau/tableau_de_bord_page.dart:200-214`) ;
- les trois plus anciens dossiers sont **déjà** montrés dans la grande tuile (l.154-166),
  puis répétés dans la liste : le même dossier apparaît deux fois ;
- un texte explique pourquoi certains compteurs n'ont pas d'écran (l.229, clé
  `admin.tableau.aTraiterPortee`) : un écran qui doit s'excuser est un écran trop chargé.

---

## 1. Sources consultées (02/10/2026)

| # | Source | Règle utile |
|---|---|---|
| S1 | Stephen Few, *Information Dashboard Design* (O'Reilly 2006 ; Analytics Press 2013), définition citée par [UXmatters, revue du livre](https://uxmatters.com/mt/archives/2007/04/book-review-information-dashboard-design.php) et [Speckyboy](https://speckyboy.com/designing-information-dashboards/) | « Un affichage visuel des informations **les plus importantes** pour atteindre un ou plusieurs objectifs, **rassemblées sur un seul écran** pour être suivies **d'un coup d'œil**. » |
| S2 | Nielsen Norman Group, P. Laubheimer, [*Dashboards: Making Charts and Graphs Easier to Understand*](https://www.nngroup.com/articles/dashboards-preattentive/), 18/06/2017 | Un tableau de bord donne une information d'un coup d'œil **sur laquelle on agit vite** ; il n'est pas fait pour explorer. Distingue le tableau **opérationnel** (décision rapide) de l'**analytique**. La position et la longueur se lisent avant tout le reste. |
| S3 | Nielsen Norman Group, [*Progressive Disclosure*](https://www.nngroup.com/videos/progressive-disclosure/) (J. Nielsen, 1995) | Montrer d'abord le principal, **renvoyer le secondaire vers un écran dédié**. |
| S4 | Nielsen Norman Group, K. Kaplan, [*Designing Empty States in Complex Applications: 3 Guidelines*](https://www.nngroup.com/articles/empty-state-interface-design/), 19/09/2021 | Un état vide dit l'état du système, apprend comment le remplir, et offre un **chemin direct** vers la tâche. |
| S5 | Google Material Design, [*Cards*](https://m1.material.io/components/cards.html) (la page M3 équivalente ne se lit pas sans JavaScript) | La carte est **une porte d'entrée vers une information plus détaillée** ; son action principale est **la carte elle-même** ; au plus **deux actions secondaires**. |
| S6 | Android Developers, [*Canonical layouts*](https://developer.android.com/guide/topics/ui/layout/canonical-layouts) (Material 3) | Trois mises en page types : liste-détail, panneau d'appui, **flux en grille** (feed). Une ou deux zones visibles selon la largeur. |
| S7 | Apple HIG, [*Widgets*](https://developer.apple.com/design/human-interface-guidelines/widgets) | Un widget porte **une seule idée**, peu d'information, à jour et personnelle, lisible d'un coup d'œil. |
| S8 | N. Cowan, [*The magical number 4 in short-term memory*](https://pubmed.ncbi.nlm.nih.gov/11515286/), *Behavioral and Brain Sciences* 24(1), 2001 | La mémoire immédiate tient **3 à 5 éléments** (en moyenne 4). |
| S9 | Instructure Canvas (LMS), [*To Do list et barre latérale du tableau de bord, élève*](https://community.canvaslms.com/docs/DOC-8345) et [*enseignant*](https://community.canvaslms.com/docs/DOC-12905) | Produit éducatif reconnu : le tableau de bord porte une liste **« À faire » bornée** (jusqu'à 7 éléments) et un lien vers la page complète. |
| S10 | W3C, WCAG 2.2, critères [1.4.4 Redimensionnement du texte](https://www.w3.org/WAI/WCAG22/Understanding/resize-text) et [1.4.10 Redistribution](https://www.w3.org/WAI/WCAG22/Understanding/reflow) | Texte à **200 %** sans perte ; contenu lisible à **320 px** sans défilement horizontal. |

Règles internes qui priment sur ces sources (hiérarchie `DESIGN-GOV-2026-09-26.md` §1) :
- K-42, style CL-4 (`ressources-git/memoire/STYLE-REFERENCE-CL4-2026-09-26.md`, points 1 à 7) ;
- DESIGN-GOV, contrats A à E et skeletons (`docs/current/DESIGN-GOV-2026-09-26.md` §4 bis) ;
- K-55, cartes jamais collées, écart 16 (`docs/current/REVUE-DIRECTEUR-2026-10.md:164`) ;
- leçons 9 (cinq états), 11 (aucun bouton inerte), 12 (libellés), 13 (composants partagés)
  de `pilotage-git/LECONS_DES_ROLES.md` ;
- K-37 : thème et couleurs figés. Ce document ne touche à aucune couleur.

---

## 2. Les règles retenues (valables pour tous les rôles)

| N° | Règle | Chiffre | Source |
|---|---|---|---|
| D1 | Un tableau de bord **résume et oriente**. Le travail se fait sur la page dédiée. | — | S1, S2, S3 |
| D2 | **Ce qui demande une action vient en premier**, dans l'ordre de lecture (haut, puis début de ligne). Viennent ensuite l'état calme, puis les raccourcis. | 3 rangées au plus : agir, savoir, aller | S2 (position lue d'abord), K-42 point 6 |
| D3 | **3 à 5 indicateurs** par écran. Au-delà, on regroupe ceux qui sont calmes (valeur nulle) dans une seule tuile. | 3 à 5 tuiles de chiffres | S8, S1, déjà appliqué : `tableau_de_bord_page.dart:351-359` |
| D4 | Une tuile = **une seule idée**, et la tuile entière est le lien vers sa page dédiée. Pas de bouton plein dans une tuile. | 1 idée, 0 bouton plein | S5, S7, DESIGN-GOV Contrat B règle 4 |
| D5 | **Une seule action dominante** par écran. Sur un tableau de bord sans tâche immédiate, l'élément dominant est la **plus grande tuile**, pas un bouton. Quand une tâche est immédiate (entrer en salle), c'est son bouton et lui seul. | 1 | K-42 point 2, DESIGN-GOV Contrat B règle 1 |
| D6 | Toute liste sur un tableau de bord est **bornée à 3 lignes**, les plus anciennes ou les plus proches d'abord, puis un lien **« Voir tout »** vers la page dédiée. | 3 lignes + 1 lien | S9 (liste bornée), convention déjà en place : `journee_page.dart:83`, `port_travail_a_venir.dart:37`, `accueil_adulte_page.dart:137` |
| D7 | Une information n'apparaît **qu'une fois** sur l'écran. | — | K-42 point 3 |
| D8 | **Le zéro s'affiche** comme les autres valeurs. | — | invariant I9, `tableau_de_bord_page.dart:109-111` |
| D9 | Une tuile **sans page dédiée** est un rapport : elle n'a pas d'appui, jamais un bouton grisé. Une page cible qui n'existe pas = une ligne « à faire », jamais un lien inerte. | — | leçon 11, `tableau_de_bord_page.dart:348-350` |
| D10 | Une donnée absente du serveur ne remplit jamais une tuile. | — | DESIGN-GOV §1 (« Une donnée absente du contrat serveur ne doit pas être inventée pour remplir une carte ») |
| D11 | **Cinq états**, chacun atteignable en démonstration : chargement (skeleton fidèle aux tuiles, après 180 ms), vide (phrase + chemin direct quand une action existe), erreur **par tuile** (les autres restent justes), hors ligne (bandeau de `PageShell`, `page_shell.dart:198`), contenu. | 5 états | leçon 9, S4, DESIGN-GOV §4 bis.6 |
| D12 | **320 px et texte à 200 %** : deux colonnes sous 600 px, quatre au-delà ; une seule colonne de hauteur libre dès que le texte dépasse 115 % (déjà dans `GrilleBento`). Aucune troncature. | 320 px, 200 % | S10, `BENTO_RECENSEMENT.md:3-7`, leçon 8 |
| D13 | Une **liste** dans une tuile prend au moins **2 lignes de grille** (2 × 160) : une rangée de 160 ne tient pas un titre et trois lignes de 48. | hauteur ≥ 2 lignes | `GrilleBento.hauteurLigne` (`BENTO_RECENSEMENT.md:6`), anatomie `GroupeReglages` ligne 48 (DESIGN-GOV Contrat C) |
| D14 | Pas de décor pour remplir un vide. Un rôle qui n'a qu'une chose à faire garde **une seule carte**. Bento ne s'impose pas à un écran d'une ou deux tuiles. | — | K-42 point 1, S7 |

**Tailles Bento** (vocabulaire de `grille_bento.dart:15-25`) : carrée 1×1, large 2×1,
haute 1×2, grande 2×2. La notation « A / B » ci-dessous donne l'étendue sur 2 colonnes
(téléphone) puis sur 4 colonnes (tablette et ordinateur, `etendueLarge`).

---

## 3. Tableau de bord par rôle

### 3.1 Direction : Centre de commande (`ADM-01`, `/admin`)

**Aujourd'hui** (`lib/features/admin_tableau/tableau_de_bord_page.dart`)
1. Six compteurs en Bento (l.173-187, détail l.302-379) : Dossiers (grande, aperçu des 3 plus anciens), Demandes (haute), Élèves sans enseignant (carrée), Cahiers manquants (carrée), Incidents et Accès échus (tuile double quand ils valent 0).
2. Liste « À traiter en premier », **toutes les lignes** (l.190-214), puis une phrase d'explication (l.229).
3. Deux raccourcis : Comptes, Accès des agents IA (l.247-265).

**Demain** (ordre de lecture)

| Rang | Tuile | Taille | Page dédiée (route réelle) |
|---|---|---|---|
| 1 | Dossiers à valider : chiffre + 3 plus anciens (nom, ancienneté) | grande 2×2 / grande 2×2 | `/admin/personnes/dossiers` (`routes.dart:402`, `app_router.dart:909`) |
| 2 | Demandes à trancher : chiffre + phrase | haute 1×2 / haute 1×2 | `/admin/operations/demandes` (`routes.dart:396`, `app_router.dart:897`) |
| 3 | Élèves sans enseignant | carrée / carrée | `/admin/operations/attributions` (`routes.dart:392`, `app_router.dart:887`) |
| 4 | Cahiers manquants | carrée / carrée | `/admin/pedagogie/qualite` (`routes.dart:426`, `app_router.dart:974`) |
| 5 | Incidents (24 h) et Accès échus : rapport sans appui, une tuile si les deux valent 0 | large 2×1 / 4×1 | aucune page : **reste un rapport** (D9) |
| 6 | Raccourcis, une carte à lignes (`CarteLignes`) : **Groupes**, Comptes, Accès des agents IA | pleine largeur | `/admin/operations/groupes` (`routes.dart:389`, `app_router.dart:880`), `/admin/personnes/comptes` (`app_router.dart:929`), `/admin/securite-audit/acces-agents` (`app_router.dart:1033`) |

**Sort vers une page dédiée**
- la liste complète « À traiter en premier » (l.190-229) : chaque file a déjà sa page, et la tuile y mène. Le tri par ancienneté reste fait **dans** chaque page.
- la phrase `aTraiterPortee` (l.229) : sans la liste, elle n'a plus d'objet.
- l'état vide « Rien à traiter » (l.193-198) devient une phrase calme sous les tuiles quand dossiers et demandes valent 0 (D11, S4).

**Planning** : aucune route de planning n'existe côté direction (recherche dans `routes.dart:381-463`). Aucun lien n'est posé : ligne « à faire » DASH-ADM-PLANNING (D9).

**Indicateurs** : 4 tuiles de chiffres + 1 tuile calme = 5 (D3). Élément dominant : la tuile Dossiers (D5).

**Écart connu** : le compteur serveur des dossiers compte encore les tuteurs alors que l'aperçu ne montre que les enseignants (K-47, commentaire `tableau_de_bord_page.dart:139-141`, ligne serveur BR-1.c déjà ouverte). Aucun code serveur ici.

### 3.2 Élève, présentation standard : Accueil (`ELV-02`, `/eleve`)

**Aujourd'hui** (`lib/features/accueil_eleve/accueil_eleve_page.dart`) : deux blocs (l.207-229).
Le bloc principal dans un de ses six états (l.263-299) ; le bloc Coran (l.567-578), qui mène à `/eleve/coran`.
Commentaire de l'écran : « Deux blocs, rien d'autre » (l.118).

**Demain**

| Rang | Tuile | Taille | Page dédiée |
|---|---|---|---|
| 1 | Prochain cours (6 états ; « Rejoindre » est la seule action dominante quand le cours est en direct, l.395-399) | grande 2×2 / 4×2 | `/salle` par billet (`routes.dart:495`) |
| 2 | Le Coran | large 2×1 / 4×1 | `/eleve/coran` (`routes.dart:78`) |

Rien n'est ajouté (D14) : deux tuiles suffisent, et la barre porte déjà Ma classe (`app_router.dart:308-311`).

**À faire** : le fichier n'a **aucune branche d'erreur** (aucune occurrence de `hasError`). Une lecture en échec sans valeur tombe sur la liste vide (l.176), donc sur « aucun cours » : erreur et vide sont confondus (leçon 9). Ligne DASH-ELV-ERR.

### 3.3 Élève, Mode Accessibilité : Accueil (`lib/features/accueil_eleve/accueil_accessibilite.dart`)

**Aujourd'hui** (l.161-194) : salutation ; Prochaine séance avec un seul bouton (« Voir ma classe » ou « Rejoindre », l.102-127) ; « Avant le prochain cours » (l.246-266) ; Lire le Coran ; Aide (l.133-158). Deux colonnes à partir de 840 divisé par le facteur de texte (l.30-32, l.164-184).

**Demain** : **pas de Bento**. La composition actuelle suit déjà K-42 points 2, 4 et 6. Une colonne linéaire garde un ordre de lecture unique, ce que le Mode Accessibilité recherche. Voir la question Q3.

**À faire** : l'écran n'est monté que par la démonstration (`lib/features/demo/demo_accessibilite_page.dart:402`), et l'aide n'a « aucune route réelle hors de la démonstration » (même fichier, l.414-416). Ligne DASH-MA-PROD.

### 3.4 Tuteur : Accueil famille (`TUT-01`, `/tuteur`)

**Aujourd'hui** (`lib/features/accueil_famille/accueil_famille_page.dart`) : sélecteur de profils (l.194-202) ; carte classe et prochaine séance (l.244-257) ; bandeau de blocage si aucun appareil prêt (l.259-265) ; « Avant le prochain cours », 3 au plus et « Voir tout » (l.267-277, `liste_preparation.dart:129` et `:151`) ; « Dernière séance » (l.279-291). Téléphone : une colonne (l.293-307). Bureau : 62 / 38 (l.339-349).

C'est déjà un résumé conforme à D1, D6 et D7. Seule la forme change (BENTO).

| Rang | Tuile | Taille | Page dédiée |
|---|---|---|---|
| 0 | Sélecteur de profils (hors grille, au-dessus) | — | `/tuteur/foyer/ajouter` pour « Ajouter » (`routes.dart:110`) |
| 1 | Bandeau de blocage, s'il existe (seule action dominante dans ce cas : « Connecter un appareil ») | large 2×1 / 4×1 | `/tuteur/foyer/appairer/:eleveId` (`routes.dart:150`) |
| 2 | Classe et prochaine séance | grande 2×2 / 2×2 | `/tuteur/classes/:classeId` (`routes.dart:207`) |
| 3 | Avant le prochain cours (3 + « Voir tout ») | grande 2×2 / 2×2 | `/tuteur/classes/:classeId/travail` (`routes.dart:216`, `app_router.dart:474`) |
| 4 | Dernière séance | large 2×1 / 4×1 | `/tuteur/suivi` (`routes.dart:176`) et `/tuteur/seances/:seanceId` (`routes.dart:188`) |

États : déjà portés par `BlocAsynchrone` (l.117-130), vide avec chemin direct (l.121-127), « sans classe » avec chemin vers le catalogue (l.220-231). Le Foyer (`/tuteur/foyer`) est une page dédiée, pas un tableau de bord : hors DASH.

### 3.5 Enseignant : Aujourd'hui (`ENS-02`, `/enseignant/journee`)

**Aujourd'hui** (`lib/features/journee/journee_page.dart`) : Prochaine séance avec un seul emplacement d'action (l.254-264, l.412-496) ; cartes Remplacement confirmées (l.265-268) ; Ma journée (l.269-273) ; À terminer, 3 au plus et « Voir tout » (l.274-280, l.855-933) ; Alertes utiles, 2 absences au plus puis « et N autres » (l.89, l.281-301, l.324-331). Une ou deux colonnes 3 / 2 (l.336-409).

| Rang | Tuile | Taille | Page dédiée |
|---|---|---|---|
| 1 | Prochaine séance (seule action dominante : Préparer, Rejoindre, Remplir le cahier ou Voir la Classe) | grande 2×2 / 2×2 | `/salle` (`routes.dart:495`), `/enseignant/seance/:id/cahier` (`routes.dart:318`), `/enseignant/classes` (`routes.dart:284`) |
| 2 | Remplacement confirmé, s'il existe | large 2×1 / 2×1 | même destinations que la séance |
| 3 | Ma journée (frise du jour) | haute 1×2 / 2×2 | aucune page dédiée : la journée **est** le contenu de cet écran (voir Q4) |
| 4 | À terminer (3 + « Voir tout ») | grande 2×2 / 2×2 | liste complète : voir « à faire » ci-dessous |
| 5 | Alertes utiles, s'il y en a | large 2×1 / 2×1 | `/enseignant/groupe/:id` (`routes.dart:325`) |

Accord avec `BENTO_RECENSEMENT.md:21` (« Prochaine séance large, Ma journée haute »).

**À faire** : « Voir tout » ouvre la liste par `Navigator.push(MaterialPageRoute)` (l.908-912), sans adresse. Le retour fonctionne, mais la page n'a pas de route (un rechargement Web la perd). Ligne DASH-ENS-ROUTE.

### 3.6 Contrôleur : Contrôle (`CTR-01`, `/controleur`)

**Aujourd'hui** (`lib/features/controleur/controle_page.dart`) : une carte de mission (l.206-346) avec un seul bouton « Commencer le contrôle » quand la séance est en direct (l.301-311), puis « Compte rendu à terminer » s'il existe (l.100-110, l.121-176). Colonne bornée à 640 (l.62, l.90-93). Cinq états : contenu, erreur (l.74-78), chargement (l.79-82), vide (l.187-193), indisponible (l.194-200) ; hors ligne par `PageShell`.

**Demain** : **inchangé, pas de Bento** (D14). Le rôle a une seule chose à faire : « Une seule carte de mission, jamais de planning » (`routes.dart:335-336`, CT-2, C3). Historique et Échanges sont dans la barre (`app_router.dart:806-851`).

### 3.7 Élève adulte : Accueil (`lib/features/accueil_adulte/accueil_adulte_page.dart`)

**Aujourd'hui** : salutation et cloche (l.172-205) ; Prochaine séance (l.266-273) ; Avant le prochain cours si non vide (l.276-284) ; Mon parcours en une ligne (l.286-298) ; Dernières séances, 3 (l.261-263, l.307-332) ; Ressources, 3 + « Voir tout » (l.335-340). Deux colonnes par rangées (l.349-356).

| Rang | Tuile | Taille | Page dédiée |
|---|---|---|---|
| 1 | Prochaine séance (seule action dominante) | grande 2×2 / 2×2 | `/salle` (`routes.dart:495`) |
| 2 | Avant le prochain cours, s'il y en a | grande 2×2 / 2×2 | Ma classe adulte : route réelle absente (voir à faire) |
| 3 | Mon parcours : **une ligne**, pas une tuile de chiffres (K-42 point 4) | large 2×1 / 4×1 | — |
| 4 | Dernières séances (3) | grande 2×2 / 2×2 | aucune page d'historique adulte : pas de « Voir tout » tant qu'elle n'existe pas |
| 5 | Ressources (3 + « Voir tout ») | grande 2×2 / 2×2 | `/tc/bibliotheque` (`routes.dart:567`) |

**À faire** : l'écran n'a « aucune source serveur à ce jour » (l.104-112, EA-BR-04) et n'est monté que par la démonstration (`lib/features/demo/demo_adulte_page.dart:590`). Pas de route `/adulte` dans `routes.dart`. Ligne DASH-EA-PROD.

« Mon espace » adulte (`mon_espace_adulte_page.dart:119`) est une page de compte (identité, rubriques), pas un tableau de bord : hors DASH.

### 3.8 Enseignant : Mes classes (`/enseignant/classes`)

Liste de cartes, pas un tableau de bord (`BENTO_RECENSEMENT.md:24`). Hors DASH.

---

## 4. Questions au directeur

Aucune ne bloque. Chaque recommandation est appliquée dans ce document.

- **Q1.** Retirer la liste complète « À traiter en premier » du Centre de commande, puisque chaque tuile ouvre sa file ? **Recommandation : oui** ; les 3 plus anciens dossiers restent dans la grande tuile.
- **Q2.** Il n'existe pas de page « Planning » pour la direction. **Recommandation : pas de lien tant qu'elle n'existe pas** ; « Groupes » est ajouté aux raccourcis.
- **Q3.** Mode Accessibilité : garder une colonne simple plutôt que des tuiles de tailles variées ? **Recommandation : oui**, l'ordre de lecture unique aide l'élève.
- **Q4.** Enseignant : garder la journée entière sur « Aujourd'hui » plutôt que 3 lignes et « Voir tout » ? **Recommandation : oui**, la journée est le sujet même de l'écran.

---

## 5. Lignes « à faire »

| Ligne | Quoi | Où |
|---|---|---|
| DASH-ADM-1 | Coder le Centre de commande selon §3.1 (retrait de la liste, ajout de « Groupes », état vide calme) | `tableau_de_bord_page.dart` |
| DASH-ADM-PLANNING | Page « Planning » de la direction absente ; aucun lien d'ici là | `routes.dart` (domaine Opérations) |
| DASH-ELV-ERR | Accueil élève : distinguer l'erreur de lecture du « aucun cours » | `accueil_eleve_page.dart:172-176` |
| DASH-MA-PROD | Monter l'Accueil du Mode Accessibilité hors démonstration ; donner une route réelle à l'Aide | `accueil_accessibilite.dart`, `demo_accessibilite_page.dart:414-416` |
| DASH-TUT-BENTO | Accueil famille en `GrilleBento` selon §3.4 | `accueil_famille_page.dart:293-353` |
| DASH-ENS-BENTO | Aujourd'hui en `GrilleBento` selon §3.5 | `journee_page.dart:336-409` |
| DASH-ENS-ROUTE | Donner une route à la liste complète « À terminer » | `journee_page.dart:908-912` |
| DASH-EA-PROD | Accueil adulte : route réelle et source serveur (EA-BR-04) ; historique adulte pour « Voir tout » des dernières séances | `accueil_adulte_page.dart:104-112` |
| DASH-LIB | Déclarer les libellés de l'annexe B dans `tool/libelles_sources.json` après accord | annexe B |

Aucun branchement serveur (avant BR-1). Le seul besoin serveur cité (compteur des dossiers qui inclut les tuteurs) est déjà la ligne BR-1.c.

---

## Annexe A : fiches d'écran des tableaux de bord

**Il n'existe pas de catalogue des écrans actif dans `docs/current`.** Le seul catalogue est
archivé (`docs/archive/2026-09-pre-remise-a-plat/design/08-catalogue-ecrans.md`), et
`docs/archive/README.md:16` le dit « remplacé par `docs/current/03` ». On n'écrit pas dans
une archive. Les fiches sont donc ici, **au format de la fiche archivée** (§3 de ce fichier,
l.215-257), réduit aux champs utiles au contenu.

```
CODE              ADM-01
Nom               Centre de commande
Rôle              Direction
Route             /admin
Question          Qu'est-ce qui attend une décision, et depuis quand ?
Priorités         P0  Dossiers à valider (3 plus anciens)       grande
                  P0  Demandes à trancher                         haute
                  P1  Élèves sans enseignant                      carrée
                  P1  Cahiers manquants                           carrée
                  P2  Incidents (24 h) + Accès échus (rapport)    large
                  P2  Raccourcis : Groupes, Comptes, Accès agents IA
Action principale     la tuile Dossiers (aucun bouton plein)
Actions secondaires   les autres tuiles, les raccourcis
États             chargement  skeleton des tuiles
                  vide        chiffres à 0 + phrase calme
                  erreur      par tuile ; la file illisible n'emporte pas les compteurs
                  hors ligne  bandeau de PageShell
Invariants        le zéro s'affiche ; une tuile sans page est un rapport
```

```
CODE              ELV-02
Nom               Accueil élève (présentation standard)
Rôle              Élève
Route             /eleve
Question          Quand est mon prochain cours, et puis-je entrer ?
Priorités         P0  Prochain cours (6 états)    grande
                  P1  Le Coran                     large
Action principale     Rejoindre (seulement en direct)
États             chargement  deux skeletons de tuile (accueil_eleve_page.dart:209-216)
                  vide        aucun cours aujourd'hui, prochain cours annoncé
                  erreur      À FAIRE (DASH-ELV-ERR)
                  hors ligne  état horsLigne du bloc + bandeau
Invariants        deux blocs, rien d'autre
```

```
CODE              ELV-02-MA
Nom               Accueil élève (Mode Accessibilité)
Rôle              Élève
Route             démonstration seulement (/demo/accessibilite) ; DASH-MA-PROD
Priorités         P0  Prochaine séance + un seul bouton
                  P1  Avant le prochain cours
                  P2  Lire le Coran ; Aide
Composition       une colonne ; deux à partir de 840 / facteur de texte ; pas de Bento
```

```
CODE              TUT-01
Nom               Accueil famille
Rôle              Tuteur
Route             /tuteur
Question          Mon enfant est-il prêt pour son prochain cours ?
Priorités         P0  Blocage appareil (si présent)       large
                  P0  Classe et prochaine séance          grande
                  P1  Avant le prochain cours (3)         grande
                  P2  Dernière séance                     large
Action principale     Connecter un appareil si blocage ; sinon la carte de séance
États             BlocAsynchrone : chargement, erreur, vide (ajouter un profil),
                  sans classe (catalogue), contenu ; hors ligne par PageShell
```

```
CODE              ENS-02
Nom               Aujourd'hui
Rôle              Enseignant
Route             /enseignant/journee
Question          Quelle est ma prochaine séance, et que dois-je terminer ?
Priorités         P0  Prochaine séance            grande
                  P0  Remplacement confirmé        large
                  P1  Ma journée                   haute
                  P1  À terminer (3)               grande
                  P2  Alertes utiles               large
Action principale     l'emplacement de la séance (Préparer, Rejoindre,
                      Remplir le cahier, Voir la Classe)
États             skeleton (journee_page.dart:1188-1197), erreur avec
                  Réessayer (l.186-193), échec partiel signalé (l.237-238)
```

```
CODE              CTR-01
Nom               Contrôle
Rôle              Contrôleur
Route             /controleur
Question          Quelle classe dois-je observer maintenant ?
Priorités         P0  Carte de mission
                  P1  Compte rendu à terminer (si présent)
Composition       une colonne bornée à 640 ; pas de Bento
```

```
CODE              EA-ACCUEIL
Nom               Accueil élève adulte
Rôle              Élève adulte
Route             démonstration seulement (/demo/adulte) ; DASH-EA-PROD
Priorités         P0  Prochaine séance            grande
                  P1  Avant le prochain cours      grande
                  P2  Mon parcours (une ligne)     large
                  P2  Dernières séances (3)        grande
                  P2  Ressources (3 + Voir tout)   grande
```

## Annexe B : libellés nouveaux

Statut : **proposé par un agent** (leçon 12, K-53.4). Aucune clé i18n n'est créée.

| Proposition | Où | Remarque |
|---|---|---|
| « Les classes, leurs élèves et leur enseignant. » | légende de la ligne Groupes des raccourcis (ADM-01) | le titre réutilise `admin.groupes.titre` (« Groupes ») ; à revoir avec le renommage « groupe » → « classe » du lot 3 |
| « Rien n'attend de décision aujourd'hui. » | phrase calme sous les tuiles quand dossiers et demandes valent 0 (ADM-01) | remplace `admin.tableau.aTraiterAucun` et `aTraiterAucunDetail` |
| « Vos cours n'ont pas pu être lus. Réessayez dans un instant. » | erreur de l'Accueil élève (DASH-ELV-ERR) | format K-59 : ce qui manque, l'action |

Réutilisés sans changement : `tuteur.accueil.voirTout` (« Voir tout »), `admin.tableau.*` des compteurs.
