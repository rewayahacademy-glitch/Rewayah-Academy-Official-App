# DASH-1 : stratégie des tableaux de bord (02/10/2026)

Statut : **document seul, aucun code**. DASH-1 décide du **contenu** des tableaux de bord.
BENTO-1 (fait, `lib/core/widgets/grille_bento.dart`) décide de leur **forme**.
Branche `corrections/c2-dash1`, partie de `corrections/revue-directeur-2026-10` @ `0796f75`.

## 0. La demande

Demande répétée du directeur, **reformulée ici** d'après l'énoncé de l'étape DASH-1
(02/10/2026). Le texte d'origine n'est pas dans le dépôt (recherche sans résultat) ; ce
n'est donc pas une citation : le tableau de bord actuel affiche tous les dossiers ; le
directeur veut un simple résumé (quelques indicateurs et ce qui demande une action), avec des
liens ou boutons vers les pages dédiées où se fait le travail (dossiers, groupes, planning).
Source exacte à relever par le directeur ou au tableau (voir « Reste »).

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
| S3 | J. Nielsen, Nielsen Norman Group, [*Progressive Disclosure*](https://www.nngroup.com/articles/progressive-disclosure/), article du 03/12/2006 (relu le 02/10/2026) | « Montrer d'abord les quelques options les plus importantes, offrir le reste **à la demande** » : le secondaire part vers un écran dédié. |
| S4 | Nielsen Norman Group, K. Kaplan, [*Designing Empty States in Complex Applications: 3 Guidelines*](https://www.nngroup.com/articles/empty-state-interface-design/), 19/09/2021 | Un état vide dit l'état du système, apprend comment le remplir, et offre un **chemin direct** vers la tâche. |
| S5 | Google Material Design **1**, [*Cards*](https://m1.material.io/components/cards.html). **Règle M1, non revérifiée en M3** : `m3.material.io/components/cards` ne se lit pas sans JavaScript (essai outillé du 02/10/2026), et la documentation M3 Android ([`Card.md`](https://github.com/material-components/material-components-android/blob/master/docs/components/Card.md), relue le 02/10/2026) ne dit rien de l'action principale ni du nombre d'actions | La carte est **une porte d'entrée vers une information plus détaillée** ; son action principale est **la carte elle-même** ; au plus **deux actions secondaires**. Ici, S5 ne sert qu'en appui de S7 et de DESIGN-GOV Contrat B règle 4, qui suffisent seuls. |
| S6 | Android Developers, [*Canonical layouts*](https://developer.android.com/guide/topics/ui/layout/canonical-layouts) (Material 3) | Trois mises en page types : liste-détail, panneau d'appui, **flux en grille** (feed). Une ou deux zones visibles selon la largeur. |
| S7 | Apple HIG, [*Widgets*](https://developer.apple.com/design/human-interface-guidelines/widgets) | Un widget porte **une seule idée**, peu d'information, à jour et personnelle, lisible d'un coup d'œil. |
| S8 | N. Cowan, [*The magical number 4 in short-term memory*](https://pubmed.ncbi.nlm.nih.gov/11515286/), *Behavioral and Brain Sciences* 24(1), 2001 | La mémoire immédiate tient **3 à 5 éléments** (en moyenne 4). |
| S9 | Instructure Canvas (LMS), guide élève *How do I use the To Do list and sidebar in the Dashboard as a student?*. Les liens d'origine (`community.canvaslms.com/docs/DOC-8345`, `DOC-12905`) ne mènent plus à ce guide (essai du 02/10/2026). Copie relue le 02/10/2026 : [base de connaissances de Tacoma Community College, article 38587](https://tacomacc.teamdynamix.com/TDClient/KB/ArticleDet?ID=38587) | Produit éducatif reconnu : la liste « À faire » du tableau de bord est **bornée** (les devoirs dus dans les **7 prochains jours**) et un lien **« Show All »** ouvre la page complète. Le plafond « jusqu'à 7 éléments » cité dans la première version n'est pas confirmé par cette copie ; il est retiré. |
| S10 | W3C, WCAG 2.2, critères [1.4.4 Redimensionnement du texte](https://www.w3.org/WAI/WCAG22/Understanding/resize-text) et [1.4.10 Redistribution](https://www.w3.org/WAI/WCAG22/Understanding/reflow) | Texte à **200 %** sans perte ; contenu lisible à **320 px** sans défilement horizontal. |
| S11 | Flutter, [*General approach to adaptive apps*](https://docs.flutter.dev/ui/adaptive-responsive/general), page mise à jour le 05/05/2026 (Flutter 3.47), relue le 02/10/2026 (DESIGN-GOV §4.1, premier référentiel) | Décider d'après **la place disponible** (`MediaQuery.sizeOf` pour la fenêtre, `LayoutBuilder` pour le parent), **jamais d'après le type d'appareil** ; exemple de seuil Material à **600** px logiques ; ne pas verrouiller l'orientation. |

Règles internes qui priment sur ces sources (hiérarchie `DESIGN-GOV-2026-09-26.md` §1) :
- K-42, style CL-4 (`ressources-git/memoire/STYLE-REFERENCE-CL4-2026-09-26.md`, points 1 à 7) ;
- DESIGN-GOV, contrats A à E et skeletons (`docs/current/DESIGN-GOV-2026-09-26.md` §4 bis) ;
- K-55, cartes jamais collées, écart 16 (`docs/current/REVUE-DIRECTEUR-2026-10.md:164`) ;
- leçons 9 (cinq états), 11 (aucun bouton inerte), 12 (libellés), 13 (composants partagés)
  de `pilotage-git/LECONS_DES_ROLES.md` ;
- K-37 : thème et couleurs figés. Ce document ne touche à aucune couleur.

---

## 2. Les règles retenues (valables pour tous les rôles)

Colonne « Conclusion » au sens de DESIGN-GOV §4.2 : **conforme** (la règle reprend la source
telle quelle), **ajustée** (la source est adaptée, l'écart est dit), **non applicable**.

| N° | Règle | Chiffre (critère vérifiable) | Source | Conclusion |
|---|---|---|---|---|
| D1 | Un tableau de bord **résume et oriente**. Le travail se fait sur la page dédiée. | **0 formulaire, 0 liste non bornée** sur un tableau de bord (hors exceptions nommées de D6) | S1, S2, S3 | conforme |
| D2 | **Ce qui demande une action vient en premier**, dans l'ordre de lecture (haut, puis début de ligne). Viennent ensuite l'état calme, puis les raccourcis. | 3 rangées au plus : agir, savoir, aller | S2 (position lue d'abord), K-42 point 6 | conforme |
| D3 | **3 à 5 indicateurs** par écran, **dans tous les cas de valeurs** (nulles ou non). Deux compteurs de même nature (rapports sans page) partagent une seule tuile qui garde leurs deux chiffres. | 3 à 5 tuiles de chiffres, quelles que soient les valeurs | S8, S1 | ajustée : S8 donne une capacité moyenne de 4, la règle en fait un plafond d'écran |
| D4 | Une tuile = **une seule idée**, et la tuile entière est le lien vers sa page dédiée. Pas de bouton plein dans une tuile. **Exceptions nommées** : (a) une ligne d'aperçu qui **nomme une personne** ouvre **sa** fiche, pas la file (cible ≥ 48, ADM-01 Dossiers, modification UX n°2, `tableau_de_bord_page.dart:81-83`) ; (b) la tuile de la **tâche immédiate** garde son bouton (voir D5). | 1 idée ; 0 bouton plein hors exception (b) | S7, DESIGN-GOV Contrat B règle 4 ; S5 en appui (M1, non revérifiée en M3) | ajustée : exceptions (a) et (b) |
| D5 | **Une seule action dominante** par écran. Sans tâche immédiate, l'élément dominant est la **plus grande tuile**, pas un bouton. Quand une tâche est immédiate (entrer en salle, remplir le cahier, connecter l'appareil qui bloque), c'est son bouton, **au niveau primaire, et lui seul** : tout autre bouton de l'écran passe au niveau secondaire ou devient une tuile-lien. | 1 bouton primaire au plus par écran | K-42 point 2, DESIGN-GOV Contrat B règle 1 | conforme |
| D6 | Toute liste sur un tableau de bord est **bornée à 3 lignes**, les plus anciennes ou les plus proches d'abord, puis un lien **« Voir tout »** vers la page dédiée. **Exceptions nommées** : (a) la frise « Ma journée » d'ENS-02, non bornée (elle est le sujet de l'écran, Q4) ; (b) « Alertes utiles » d'ENS-02, 2 lignes puis « et N autres » sans lien, tant qu'aucune page ne liste ces alertes (D9, ligne DASH-ENS-ALERTES). | 3 lignes + 1 lien, sauf (a) et (b) | S9 (liste bornée et « Show All »), convention déjà en place : `journee_page.dart:83`, `port_travail_a_venir.dart:37`, `accueil_adulte_page.dart:143` | ajustée : S9 borne par une fenêtre de 7 jours, la règle borne par un nombre |
| D7 | Une information n'apparaît **qu'une fois** sur l'écran. | 0 doublon | K-42 point 3 | conforme |
| D8 | **Le zéro s'affiche** comme les autres valeurs. | 0 tuile masquée parce que sa valeur est 0 | invariant I9, `tableau_de_bord_page.dart:109-111` | conforme |
| D9 | Une tuile **sans page dédiée** est un rapport : elle n'a pas d'appui, jamais un bouton grisé. Une page cible qui n'existe pas = une ligne « à faire », jamais un lien inerte. **Exception nommée** : « Rejoindre » de l'Accueil élève reste présent et inerte **hors ligne** (panne passagère, signalée par un changement de paire de couleurs, `accueil_eleve_page.dart:389-399`). | 0 bouton grisé hors exception | leçon 11, `tableau_de_bord_page.dart:348-350` | conforme |
| D10 | Une donnée absente du serveur ne remplit jamais une tuile. | une lecture en échec ou absente donne un état d'erreur ou de chargement, **jamais un 0 ni un texte de remplacement** | DESIGN-GOV §1 (« Une donnée absente du contrat serveur ne doit pas être inventée pour remplir une carte ») | conforme |
| D11 | **Cinq états**, chacun atteignable en démonstration : chargement (skeleton fidèle aux tuiles, après 180 ms), vide (phrase + chemin direct quand une action existe), erreur **par source de données** (une source en échec n'emporte que ce qu'elle remplit ; les autres restent justes), hors ligne (bandeau de `PageShell`, `page_shell.dart:198`), contenu. | 5 états par fiche | leçon 9, S4, DESIGN-GOV §4 bis.6 | conforme |
| D12 | **320 px et texte à 200 %** : deux colonnes sous 600 px **de place disponible** (`LayoutBuilder`, `GrilleBento.colonnesPour`), quatre au-delà. **Texte agrandi seulement** (au-dessus de 100 %) : une colonne de moins, 4 → 3 → 2 → 1, tant que la largeur utile par colonne est sous 112 px × l'échelle du texte (seuil sans source, à faire valider) ; à trois colonnes et plus, une tuile prend son étendue large, si bien que la grande tuile 2×2 reste. À 100 % ou moins, rien ne change, même dans une place étroite. La hauteur de ligne suit l'échelle (`hauteurLignePour`) ; les tuiles à contenu variable prennent la hauteur de leur contenu (`hauteurContenu`, BENTO-2). En une colonne, hauteur libre. Aucune troncature (BENTO-1b, BENTO-1c). Jamais de décision d'après le type d'appareil. | 320 px, 200 % | S10, S11, `BENTO_RECENSEMENT.md:3-20`, leçon 8 | conforme |
| D13 | Une **liste** dans une tuile prend au moins **2 lignes de grille** (2 × 160) : une rangée de 160 ne tient pas un titre et trois lignes de 48. | hauteur ≥ 2 lignes | `GrilleBento.hauteurLigne` (`BENTO_RECENSEMENT.md:6`), anatomie `GroupeReglages` ligne 48 (DESIGN-GOV Contrat C) | conforme |
| D14 | Pas de décor pour remplir un vide. Un rôle qui n'a qu'une chose à faire garde **une seule carte**. | écran de **2 tuiles ou moins → pas de Bento** ; 0 élément sans donnée ni action | K-42 point 1, S7 | conforme |

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
| 1 | Dossiers à valider : chiffre + 3 plus anciens (nom, ancienneté). Le titre et le chiffre mènent à la file ; **chaque nom de l'aperçu ouvre son propre dossier** (`extra: dossier.profilId`, comme aujourd'hui `tableau_de_bord_page.dart:76-84`), exception D4 (a) | grande 2×2 / grande 2×2 (aujourd'hui large / grande, l.306-307) | file : `/admin/personnes/dossiers` (`routes.dart:402`, `app_router.dart:909`) ; nom : même route avec `extra` = profil |
| 2 | Demandes à trancher : chiffre + phrase | haute 1×2 / haute 1×2 | `/admin/operations/demandes` (`routes.dart:396`, `app_router.dart:897`) |
| 3 | Élèves sans enseignant | carrée / carrée | `/admin/operations/attributions` (`routes.dart:392`, `app_router.dart:887`) |
| 4 | Cahiers manquants | carrée / carrée | `/admin/pedagogie/qualite` (`routes.dart:426`, `app_router.dart:974`) |
| 5 | « Incidents et accès » : **une seule tuile dans tous les cas**, qui garde ses deux chiffres, Incidents (24 h) et Accès échus, qu'ils valent 0 ou plus (forme `_TuileDouble`, aujourd'hui réservée au cas 0 / 0, l.351-359 ; le cas non nul l.360-377 éclate en deux tuiles et disparaît). Rapport sans appui | large 2×1 / 4×1 | aucune page cible adaptée, voir ci-dessous : **reste un rapport** (D9) |
| 6 | Raccourcis, une carte à lignes (`CarteLignes`) : **Groupes**, Comptes, Accès des agents IA | pleine largeur | `/admin/operations/groupes` (`routes.dart:389`, `app_router.dart:880`), `/admin/personnes/comptes` (`app_router.dart:929`), `/admin/securite-audit/acces-agents` (`app_router.dart:1033`) |

**Pourquoi Incidents et Accès échus n'ont pas de page cible.** Deux pages existent, aucune ne
s'ouvre sur ce que la tuile compte :
- le Journal (`ADM-04`, `/admin/securite-audit/journal`, `routes.dart:452-454`) a des filtres
  de période et d'événement, mais tenus **dans l'écran** (`admin_journal/journal_page.dart:22`,
  `:97`, `:284`) : aucune adresse ne l'ouvre déjà filtré sur « incidents des 24 dernières
  heures ». Un lien y mènerait au journal entier, qui ne montre pas le chiffre de la tuile ;
- Comptes (`ADM-08`, `/admin/personnes/comptes`, `routes.dart:405`) n'a **aucun filtre**
  d'accès échu (aucune occurrence de « échu » ni « expire » dans `admin_comptes/comptes_page.dart`).
Lignes « à faire » DASH-ADM-INC et DASH-ADM-ECHUS ; la tuile deviendra un lien quand l'une
des deux pages s'ouvrira filtrée.

**Sort vers une page dédiée**
- la liste complète « À traiter en premier » (l.190-229) : chaque file a déjà sa page, et la tuile y mène. Le tri par ancienneté reste fait **dans** chaque page.
- **Ce qui se perd, dit clairement** : le tri **commun** des dossiers et des demandes par
  ancienneté (une seule liste triée, `aTraiter()` l.70-105, tri l.103). Après DASH-ADM-1, le directeur voit les
  3 plus anciens dossiers, et pour les demandes le seul chiffre. L'accès direct au dossier
  d'une personne nommée (modification UX n°2) est **conservé** par l'exception D4 (a).
  Question Q1 complétée en conséquence.
- la phrase `aTraiterPortee` (l.229) : sans la liste, elle n'a plus d'objet.
- l'état vide « Rien à traiter » (l.193-198) devient une phrase calme sous les tuiles, affichée
  **seulement quand les 4 compteurs d'action valent 0** : dossiers, demandes, élèves sans
  enseignant, cahiers manquants (D11, S4). Incidents et accès échus, rapports sans action, ne
  comptent pas dans cette condition.

**États** (D11), par source de données réelle :
- les six compteurs viennent d'**un seul** fournisseur (`indicateursProvider`, l.128-130) :
  une erreur « par tuile » entre compteurs est impossible. Chargement : **skeleton en forme de
  grille Bento** (`Skeleton.tuileBento`, `skeleton.dart:59`, déjà employé
  `journee_page.dart:1195`) à la place de `Skeleton.liste(lignes: 2)` (l.187). Erreur : **une
  phrase à la place de toute la grille** (`admin.tableau.compteursErreur`, l.177-185), jamais
  des tuiles à 0 (D10) ;
- l'aperçu de la tuile Dossiers vient d'une **autre** source, `dossiersEnAttenteProvider`
  (l.132-134), qui passe par `read_kyc_documents()` et **refuse** la lecture quand le genre du
  lecteur est inconnu (l.215-218). C'est le seul échec partiel réel : la tuile garde son
  chiffre et dit « La liste n'a pas pu être lue. » **à la place des noms** (reprend le sens de
  `admin.tableau.listeErreur`, l.222). Jamais un aperçu vide en silence ;
- `demandesProvider` (l.131) ne sert plus au tableau de bord : la tuile Demandes ne montre que
  le chiffre des compteurs ;
- hors ligne : bandeau de `PageShell` ; vide : phrase calme ci-dessus ; contenu.

**Planning** : aucune route de planning n'existe côté direction (recherche dans `routes.dart:381-463`). Aucun lien n'est posé : ligne « à faire » DASH-ADM-PLANNING (D9).

**Indicateurs** : 4 tuiles de chiffres + 1 tuile « Incidents et accès » = **5 dans tous les
cas** (D3), puisque la tuile 5 garde ses deux chiffres même non nuls. Élément dominant : la
tuile Dossiers (D5).

**Alertes (ALERTE-1, 05/10/2026, §3.9)** : une section « Alertes » s'ajoute au Centre de
commande. **Avec une alerte urgente ouverte, elle passe en tête de la page, au-dessus des
tuiles** (rang 0), jusqu'au traitement de l'alerte ; sans alerte urgente, elle suit les tuiles
et la phrase calme (rang 5 bis, avant les raccourcis). La phrase calme n'est plus vraie quand
une alerte urgente ou importante est ouverte. Ce n'est pas une tuile : D3 (3 à 5 indicateurs)
reste tenu.

**Écart connu** : le compteur serveur des dossiers compte encore les tuteurs alors que l'aperçu ne montre que les enseignants (K-47, commentaire `tableau_de_bord_page.dart:139-141`, ligne serveur BR-1.c déjà ouverte). Aucun code serveur ici.

### 3.2 Élève, présentation standard : Accueil (`ELV-02`, `/eleve`)

**Aujourd'hui** (`lib/features/accueil_eleve/accueil_eleve_page.dart`) : deux blocs (l.207-229).
Le bloc principal dans un de ses six états (l.263-299) ; le bloc Coran (l.567-578), qui mène à `/eleve/coran`.
Commentaire de l'écran : « Deux blocs, rien d'autre » (l.118).

**Demain** : **pas de Bento** (D14 : deux blocs, donc 2 tuiles ou moins), comme MA et CTR.
La composition actuelle en deux blocs empilés reste.

| Rang | Bloc | Page dédiée |
|---|---|---|
| 1 | Prochain cours (6 états ; « Rejoindre » est la seule action dominante quand le cours est en direct, l.395-399) | `/salle` par billet (`routes.dart:495`) |
| 2 | Le Coran | `/eleve/coran` (`routes.dart:78`) |

Rien n'est ajouté (D14), et la barre porte déjà Ma classe (`app_router.dart:308-311`).

**Exception assumée (D9)** : dans l'état `horsLigne`, « Rejoindre » reste **présent et
inerte** (`joignable` faux, l.389-399). Le code le justifie : c'est une panne passagère, pas
une limite de droit ; un bouton disparu ferait croire à l'enfant que son cours n'existe plus ;
l'inertie se dit par un changement de **paire** de couleurs, pas par de la transparence.
L'exception est inscrite dans D9.

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
| 1 | Bandeau de blocage, s'il existe : « Connecter un appareil » | large 2×1 / 4×1 | `/tuteur/foyer/appairer/:eleveId` (`routes.dart:150`) |
| 2 | Classe et prochaine séance : **la tuile entière est le lien** vers la classe ; plus de bouton « Voir la classe » | grande 2×2 / 2×2 | `/tuteur/classes/:classeId` (`routes.dart:207`) |

**Bouton dominant, état du code et changement prévu (D4, D5, K-42).** Aujourd'hui, le bouton
plein de l'écran est « Voir la classe », posé **dans** la carte (`ActionPrincipale` sans
niveau, donc primaire, `carte_classe_seance.dart:107-111`) ; « Connecter un appareil » est au
niveau **secondaire** (`bandeau_blocage.dart:74-77`). Demain :
- **avec blocage** : « Connecter un appareil » passe au niveau **primaire** et reste le seul
  bouton plein (tâche immédiate, D5) ; « Voir la classe » cesse d'être un bouton, la carte de
  séance devient la tuile-lien ;
- **sans blocage** : aucun bouton plein ; la carte de séance est la tuile-lien et l'élément
  dominant (plus grande tuile, D5).
Jamais deux boutons primaires sur l'écran (K-42 point 2).
| 3 | Avant le prochain cours (3 + « Voir tout ») | grande 2×2 / 2×2 | `/tuteur/classes/:classeId/travail` (`routes.dart:216`, `app_router.dart:474`) |
| 4 | Dernière séance | large 2×1 / 4×1 | `/tuteur/suivi` (`routes.dart:176`) et `/tuteur/seances/:seanceId` (`routes.dart:188`) |

États : déjà portés par `BlocAsynchrone` (l.117-130), vide avec chemin direct (l.121-127), « sans classe » avec chemin vers le catalogue (l.220-231). Le Foyer (`/tuteur/foyer`) est une page dédiée, pas un tableau de bord : hors DASH.

### 3.5 Enseignant : Aujourd'hui (`ENS-02`, `/enseignant/journee`)

**Aujourd'hui** (`lib/features/journee/journee_page.dart`) : Prochaine séance avec un seul emplacement d'action (l.254-264, l.412-496) ; cartes Remplacement confirmées (l.265-268) ; Ma journée (l.269-273) ; À terminer, 3 au plus et « Voir tout » (l.274-280, l.855-933) ; Alertes utiles, 2 absences au plus puis « et N autres » (l.89, l.281-301, l.324-331). Une ou deux colonnes 3 / 2 (l.336-409).

| Rang | Tuile | Taille | Page dédiée |
|---|---|---|---|
| 1 | Prochaine séance. Tâche immédiate (Rejoindre, Remplir le cahier) : son bouton, primaire et seul (D5, exception D4 (b)). Sinon (Préparer, Voir la Classe) : la tuile entière est le lien, sans bouton plein | grande 2×2 / 2×2 | `/salle` (`routes.dart:495`), `/enseignant/seance/:id/cahier` (`routes.dart:318`), `/enseignant/classes` (`routes.dart:284`) |
| 2 | Remplacement confirmé : **une tuile par remplacement** (`remplacements` est une liste, une `CarteRemplacement` par offre confirmée, `journee_page.dart:265-268`), triées par début, **3 au plus** ; au-delà, ligne DASH-ENS-REMPL (aucune page ne liste les remplacements, D9). La tuile entière est le lien ; le bouton secondaire « Voir la classe » d'aujourd'hui disparaît | large 2×1 / 2×1 | `/enseignant/groupe/:id` par `Routes.groupePour` (`routes.dart:322-325`, `absence_remplacement_vue.dart:202-211`, ouverture par `push`) ; sans `groupeId`, tuile sans appui (rapport, D9), comme aujourd'hui sans action (l.202-203) |
| 3 | Ma journée (frise du jour) | haute 1×2 / 2×2 | aucune page dédiée : la journée **est** le contenu de cet écran (voir Q4) |
| 4 | À terminer (3 + « Voir tout ») | grande 2×2 / 2×2 | liste complète : voir « à faire » ci-dessous |
| 5 | Alertes utiles, s'il y en a | large 2×1 / 2×1 | `/enseignant/groupe/:id` (`routes.dart:325`) |

Accord avec `BENTO_RECENSEMENT.md:28` (« Prochaine séance grande, […] Ma journée haute »).

**À faire** : « Voir tout » ouvre la liste par `Navigator.push(MaterialPageRoute)` (l.908-912), sans adresse. Le retour fonctionne, mais la page n'a pas de route (un rechargement Web la perd). Ligne DASH-ENS-ROUTE.

### 3.6 Contrôleur : Contrôle (`CTR-01`, `/controleur`)

**Aujourd'hui** (`lib/features/controleur/controle_page.dart`) : une carte de mission (l.206-346) avec un seul bouton « Commencer le contrôle » quand la séance est en direct (l.301-311), puis « Compte rendu à terminer » s'il existe (l.100-110, l.121-176). Colonne bornée à 640 (l.62, l.90-93). Cinq états : contenu, erreur (l.74-78), chargement (l.79-82), vide (l.187-193), indisponible (l.194-200) ; hors ligne par `PageShell`.

**Demain** : **inchangé, pas de Bento** (D14). Le rôle a une seule chose à faire : « Une seule carte de mission, jamais de planning » (`routes.dart:335-336`, CT-2, C3). Historique et Échanges sont dans la barre (`app_router.dart:806-851`).

### 3.7 Élève adulte : Accueil (`lib/features/accueil_adulte/accueil_adulte_page.dart`)

**Aujourd'hui** : salutation et cloche (l.172-205) ; Prochaine séance (l.266-273) ; Avant le prochain cours si non vide (l.276-284) ; Mon parcours en une ligne (l.286-298) ; Dernières séances, 3 (l.261-263, l.307-332) ; Ressources, 3 + « Voir tout » (l.335-340). Deux colonnes par rangées (l.349-356).

| Rang | Tuile | Taille | Page dédiée |
|---|---|---|---|
| 1 | Prochaine séance. « Rejoindre » est son bouton, primaire et seul, **quand l'entrée est possible** (tâche immédiate, D5, exception D4 (b)) ; sinon la tuile n'a pas de bouton plein | grande 2×2 / 2×2 | `/salle` (`routes.dart:495`) |
| 2 | Avant le prochain cours, s'il y en a | grande 2×2 / 2×2 | Ma classe adulte : route réelle absente (voir à faire) |
| 3 | Mon parcours : **une ligne**, pas une tuile de chiffres (K-42 point 4) | large 2×1 / 4×1 | — |
| 4 | Dernières séances (3 + « Voir tout ») | grande 2×2 / 2×2 | `/eleve/adulte/seances` (DASH-EA-PROD ; sans source avant BR-1 : « indisponible ») |
| 5 | Ressources (3 + « Voir tout ») | grande 2×2 / 2×2 | `/tc/bibliotheque` (`routes.dart:567`) |

**Fait (BENTO-3)** : `GrilleBento` en hauteur de contenu selon le tableau ci-dessus (l.364-424). Deux grandes tuiles ne partagent leur bande que si chaque moitié offre 360 px × échelle du texte (`largeurMinCarteClasse`, règle BENTO-2b de l'accueil famille, seuil sans source) ; sans « Avant le prochain cours », la Prochaine séance prend toute sa bande (ordre D2) ; avec 2 tuiles ou moins (séance et ressources seules), une colonne sans Bento (D14).

**Fait (DASH-EA-PROD, 04/10/2026)** : route réelle `/eleve/adulte` dans la branche Accueil de la coquille élève (`routes_accueil_adulte.dart`), atteinte depuis `/eleve` quand la capacité `capaciteAccueilAdulteProvider` est servie (lecture `accueil_eleve_adulte` rendue au compte élève), jamais d'après le rôle ; « Voir tout » des dernières séances vers `/eleve/adulte/seances` (`historique_seances_adulte_page.dart`) ; squelette en grille Bento (m6 de BENTO-3-R) ; pas de cloche sans destination (D9). Captures : `docs/current/captures/DASH-EA-PROD/`.

**Fait (DASH-EA-PROD-b, 04/10/2026, revue DASH-EA-PROD-R)** : test du réveil du routeur quand la capacité arrive après la première navigation (vrai parcours de connexion) ; capacité fausse après une relecture en échec, même après une première lecture réussie (`hasValue && !hasError`) ; « Voir tout » des dernières séances placé comme celui des ressources (sur la ligne du titre au bord de fin, sous le titre à grande taille de texte, `EnteteVoirTout`) ; hauteurs du squelette composées des jetons (`AppSpacing`, `AppPage.hauteurReglage`) ; besoins serveur inscrits au registre §5 bis.

**Reste** : sources serveur (avant BR-1, ports neutres « indisponible ») : EA-BR-04 (accueil), DASH-BR-01 (historique complet, prolongement d'EA-BR-06) et DASH-BR-02 (capacité « accueil adulte » rendue avec la session, pour éviter d'afficher un instant l'accueil élève avant la redirection), registre §5 bis. Le titre « Ressources de la classe » de `BlocBibliotheque` se réduit en bloc (`FittedBox`) à 320 px et texte ×2 : composant partagé par quatre écrans, à traiter dans une étape dédiée (revue DASH-EA-PROD-R, défaut 4).

« Mon espace » adulte (`mon_espace_adulte_page.dart:119`) est une page de compte (identité, rubriques), pas un tableau de bord : hors DASH.

### 3.8 Enseignant : Mes classes (`/enseignant/classes`)

Liste de cartes, pas un tableau de bord (`BENTO_RECENSEMENT.md:43`). Hors DASH.

### 3.9 Alertes de la direction (ALERTE-1)

**Demande du directeur** (commentaire sur la page « Essai de fusion », 01/10/2026 à 23:02,
reformulée d'après l'énoncé de l'étape ALERTE-1, le texte d'origine n'est pas dans le dépôt) :
les alertes urgentes doivent être **en haut de l'écran dès leur arrivée**, et **signalées
immédiatement par les notifications**. **Constat** : en démonstration admin, une alerte
urgente apparaissait en bas de l'écran, sous le reste.

**Décision du 05/10/2026, déléguée par le directeur** (« c'est à toi de choisir le meilleur
choix… respecter à la lettre toutes les specs ») ; le directeur peut corriger la liste à tout
moment :

| Gravité | Définition | Exemples |
|---|---|---|
| **Urgente** (`urgent`) | Exige une action humaine **immédiate** pour une séance en cours ou imminente, ou touche la **sécurité d'un élève** | classe sans enseignant, incident de séance, signalement |
| **Importante** (`important`) | À traiter **dans la journée** | paiement échu, remplacement à confirmer |
| **Pour information** (`info`) | Tout le reste | programme d'une classe mis à jour |

Règles (A1 à A6) :

| N° | Règle | Critère vérifiable | Où |
|---|---|---|---|
| A1 | **Tri par gravité, puis par date**, la plus récente d'abord ; à égalité, l'identifiant (ordre stable). Le serveur trie (DASH-BR-03) ; l'écran retrie, car une alerte reçue en temps réel arrive en queue du flux. | urgente > importante > information ; dans une gravité, la plus récente d'abord | `lib/core/alertes/alerte.dart` (`trierAlertes`) |
| A2 | **Une alerte urgente est toujours en tête** du tableau de bord et des listes, au-dessus de tout autre contenu, **jusqu'à son traitement**. Elle n'est jamais cachée derrière « Voir tout » : la liste du tableau de bord montre **toutes** les urgentes, puis les suivantes jusqu'à 3 lignes (D6). | section Alertes au-dessus des tuiles ; 0 urgente masquée | `tableau_de_bord_page.dart`, `section_alertes.dart` (`alertesDuTableau`) |
| A3 | **À son arrivée** : mise à jour en temps réel, **sans recharger** ; **point sur la cloche** ; **bandeau en haut de l'écran ouvert** ; notification push si l'application est fermée. | le flux émet, le bandeau et le point apparaissent sur la page déjà ouverte | `port_alertes.dart` (flux), `bandeau_alerte_urgente.dart`, `AdminShell.cloche` ; push : DASH-BR-05 |
| A4 | Une alerte traitée **sort du flux** : le bandeau et le point disparaissent. Le traitement se fait sur la page de l'alerte (chaque ligne l'ouvre). | | serveur (DASH-BR-03) |
| A5 | **Délai mesuré** entre la création de l'alerte (horodatage **serveur**, `Alerte.creeeLe`) et son affichage. **Objectif proposé : moins de 5 s application ouverte** (à confirmer par le directeur). | p95 < 5 s, mesuré sur staging | DASH-BR-06 |
| A6 | La capacité « alertes » est lue, **jamais un rôle** : sans source (production avant BR-1), ni cloche ni bandeau, et la section dit « indisponible ». Aucune liste vide qui ferait croire que rien n'attend. | `AlertesIndisponibles` rend `CapaciteIndisponible('DASH-BR-03')` | `port_alertes.dart` |

**Couleur** : registre doux (`washAlert` pour une urgente, `washWarning` pour une importante,
neutre pour une information), jamais un aplat ; la gravité est toujours **écrite** (« Urgente »,
« Importante », « Pour information »), jamais dite par la seule couleur. Aucun jeton nouveau.

**Où elles se voient** : section « Alertes » du Centre de commande (`ADM-01`) ; page des alertes
(`ADM-ALERTES`, `/admin/alertes`, sous l'Accueil) ; bandeau en haut de toute autre page de la
direction ; cloche de la coquille admin (avant le compte, sur les trois formes de la coquille).
Le bandeau ne se pose pas sous l'Accueil (Centre de commande, page des alertes), qui montrent
déjà l'alerte en tête (D7). Les autres rôles ne reçoivent pas encore d'alertes : le port est
par profil, il servira à leur tour sans nouveau composant.
### 3.10 Espace de classe : cartes de la classe (CARTES-PERSO-1, fiche CLS-CARTES)

**Demande** (directeur, commentaire sur la page Essai de fusion, 01/10 23:32) : l'enseignant touche une carte pour en changer le contenu et y saisir ce qu'il veut (titre, texte, lien, échéance) ; les cartes sont visibles par le tuteur, l'élève enfant et l'élève adulte de la classe.

**Décision datée du 05/10/2026, déléguée par le directeur** (ordre du 04/10 soir) :
- les cartes sont un **emplacement de l'espace de classe** (`tc_espace_groupe/bloc_cartes_classe.dart`, à côté des emplacements de `emplacements_groupe.dart`), posé sur les quatre écrans qui montrent une Classe : Espace Classe (`EspaceGroupePage`, quatre rôles et Interface guidée), Espace Classe enseignant (`FicheGroupePage`), Ma classe de l'élève adulte (`MaClasseAdultePage`), Classe vue par le tuteur (`ClasseTuteurPage`) ;
- **contenu visible immédiatement** par les membres de la classe et les tuteurs de leurs foyers, sans relecture préalable ; l'enseignant en est responsable ; **masquage a posteriori par la direction**, consigné pour BR-1 (CARTES-BR-02) ;
- **Interface guidée** (élève enfant, ou adulte qui l'a choisie) : titre et texte seuls (le modèle ne se dit pas), lien en bouton pleine largeur de sa carte ;
- modèles préremplis (K-57) : Annonce, Devoir, Lien utile, Rappel. Le modèle est **choisi** (`ChoiceCardGroup`, chaque option dit quand la choisir, K-58) ; il **déduit** le titre proposé et, pour un devoir ou un rappel, l'échéance (date de la prochaine séance, modifiable) ; le titre, le texte et le lien sont **saisis** parce que ce sont les mots de l'enseignant (aucune déduction possible) ;
- bornes appliquées avant l'envoi et à revérifier par le serveur : titre 60 caractères (non vide), texte 280, lien `https` complet de 500 au plus, 6 cartes au plus par Classe, échéance obligatoire pour un devoir (`BornesCarteClasse`, `defautsCarte`).

**Droit de modifier** : une **capacité rendue par la lecture** (`CartesClasseVM.peutModifier`), jamais déduite d'un rôle ; la barrière reste la RLS (écriture réservée à l'enseignant de la Classe).

**Fait (CARTES-PERSO-1, 05/10/2026, partie client avant BR-1)** : port neutre `PortCartesClasse` (`lib/core/tc_groupe/cartes_classe.dart`), indisponible en production (`CapaciteIndisponible('CARTES-BR-01')`, aucune fausse carte) ; démonstration en mémoire (`lib/features/demo/cartes_classe_demo.dart`), capacité vraie pour l'enseignant (`/demo/classe`, vue enseignant), fausse pour l'élève, l'Interface guidée et l'adulte ; feuille de composition (`feuille_carte_classe.dart`) ; texte de l'enseignant isolé dans son sens de lecture (point final gardé en RTL) et traits d'union insécables ; tests `test/features/tc_espace_groupe/cartes_classe_test.dart` (39, contre-épreuves par mutation) ; captures `docs/current/captures/CARTES-PERSO-1/`.

**Reprise après revue adverse (CARTES-PERSO-1, 05/10/2026)** : la feuille de l'enseignant s'ouvre sur le Navigator du routeur, au-dessus du `ProviderScope` imbriqué de la démonstration ; elle reçoit désormais le conteneur de l'emplacement (`UncontrolledProviderScope`), sans quoi elle lisait le port de production et tout envoi finissait « non confirmé ». Testé localement : enregistrement et retrait depuis la vraie page `/demo/classe` (enseignant, 390 et 1440) ; lecture par le tuteur sur la vraie `ClasseTuteurPage` montée par le routeur (`test/features/classe_tuteur/classe_tuteur_cartes_test.dart`, capacité fausse : rien ne se presse, le lien se copie) ; phrases de l'interface (contexte, aucune carte, hors ligne, limite, « Copier le lien de… », contexte et erreurs de la feuille) isolées dans leur sens de lecture en RTL. Captures `page_enseignant_enregistree_*`, `page_tuteur_*` (390, 1440, 320 x2 LTR et RTL). Constat hors périmètre : à 320 px et texte x2, la carte de séance de `ClasseTuteurPage` (`carte_seance_classe.dart`, antérieure à cette étape) coupe « Durée », « 18:10 », « Paris », « septembre » ; à traiter dans une étape dédiée.

**Reprise après deuxième revue adverse (CARTES-PERSO-1b, 05/10/2026)** : (1) la **vraie démonstration tuteur** (« Essayer la démonstration », P2-07, `surchargesDemoTuteur`) surcharge désormais le port des cartes : la page Classe du tuteur lit les mêmes cartes de démonstration que la démonstration enseignant, capacité fausse ; avant, elle disait « pas encore ouvertes ». La démonstration adulte et l'élève (`surchargesEleveDemo`) les lisaient déjà. Testé localement en montant la vraie racine (`test/features/demo/demo_tuteur_cartes_test.dart` : entrée, carte de l'Accueil, Classe ; contre-épreuve faite). (2) Sens de lecture en arabe : aides des champs (« 60 caractères au plus »), erreurs, descriptions des modèles, titre de la feuille (« Modifier la carte « titre » »), question et conséquence du retrait isolés ; les champs titre et texte prennent le sens de leur première lettre (`sensDeLaSaisie`), le lien reste de gauche à droite. (3) Hors ligne : un port qui échoue après une première lecture garde les cartes déjà lues (test dédié). (4) Pictogrammes : le lien utile prend `AppIcons.supports` (`file-text`) ; `livreOuvert` et `lecon` dessinaient le même livre que le devoir ; aucun pictogramme ajouté au jeu gelé. **Visibilité : cartes visibles tout de suite, la direction pourra retirer une carte (choix a), décidé par délégation le 05/10** (règle DIR-REP-1), retrait par la direction consigné CARTES-BR-02. Captures `docs/current/captures/CARTES-PERSO-1b/` (locale `ar`, sens RTL donné par la langue). Constat hors périmètre, sur la page de démonstration de l'enseignant en arabe : « élèves sur 6 places 3 », « .téléphone », « % Chapitre 1 · 60 » (composants antérieurs à cette étape) ; à traiter dans une étape dédiée.

**Reprise des réserves de la revue CARTES-PERSO-1b (CARTES-PERSO-1c, 09/10/2026)** : (1) les lignes « Échéance : {date} » (bloc et feuille) et « Aucune échéance » (feuille) sont isolées dans leur sens de lecture (`isolerSens`) ; tests RTL dans `test/features/tc_espace_groupe/cartes_classe_test.dart` (groupe « echeance, rtl ») avec contre-épreuve : le libellé terminé par un point garde ce point à la fin de sa lecture ; sans isolat, le point passe à gauche (3 échecs constatés sur l'ancien code). (2) La **démonstration de la direction** (`surchargesDemoAdmin`) surcharge le port des cartes avec les cartes de démonstration, **en lecture seule** (capacité fausse) ; le retrait ou le masquage par la direction reste une écriture serveur (CARTES-BR-02), aucune écriture simulée : choix le plus prudent, **décidé par délégation le 09/10** (règle DIR-REP-1). Test `test/features/demo/demo_admin_cartes_test.dart` qui monte la vraie démonstration direction comme `main.dart` (contre-épreuve : sans la surcharge, le port reste indisponible, 2 échecs). Aucun écran de la direction n'affiche encore le bloc des cartes ; la capture le montre sous les surcharges réelles de la démonstration. (3) Le lien se copie toujours au lieu de s'ouvrir : `url_launcher` demanderait `pubspec.yaml`, interdit à cette étape ; reste consigné ci-dessous. Captures `docs/current/captures/CARTES-PERSO-1c/` (ouvertes, aucun mot coupé à 320 px texte x2 en LTR et RTL). Statut : présent dans le code, testé localement ; pas testé sur staging, non déployé.

**Reste** : la source serveur (CARTES-BR-01 à 03, §5 bis) ; le lien se **copie** (presse-papiers, « Lien copié. Collez-le dans votre navigateur ») au lieu de s'ouvrir, faute de paquet d'ouverture de lien dans `pubspec.yaml` (interdit à cette étape) : à arbitrer par le directeur (ajout de `url_launcher`).

---

## 4. Questions au directeur

Aucune ne bloque. Chaque recommandation est appliquée dans ce document.

- **Q1.** Retirer la liste complète « À traiter en premier » du Centre de commande, puisque chaque tuile ouvre sa file ? **Recommandation : oui** ; les 3 plus anciens dossiers restent dans la grande tuile, et chaque nom ouvre toujours son dossier (modification UX n°2 conservée, exception D4 (a)). **Ce qui se perd** : le tri commun des dossiers et des demandes par ancienneté (une seule liste) ; les demandes ne se voient plus que par leur chiffre.
- **Q2.** Il n'existe pas de page « Planning » pour la direction. **Recommandation : pas de lien tant qu'elle n'existe pas** ; « Groupes » est ajouté aux raccourcis.
- **Q3.** Mode Accessibilité : garder une colonne simple plutôt que des tuiles de tailles variées ? **Recommandation : oui**, l'ordre de lecture unique aide l'élève.
- **Q4.** Enseignant : garder la journée entière sur « Aujourd'hui » plutôt que 3 lignes et « Voir tout » ? **Recommandation : oui**, la journée est le sujet même de l'écran.

---

## 5. Lignes « à faire »

| Ligne | Quoi | Où |
|---|---|---|
| DASH-ADM-1 | Coder le Centre de commande selon §3.1 : retrait de la liste ; noms de l'aperçu Dossiers cliquables vers leur dossier (`extra`) ; tuile « Incidents et accès » unique dans tous les cas ; ajout de « Groupes » ; phrase calme quand les 4 compteurs d'action valent 0 ; **skeleton en forme de grille Bento** (`Skeleton.tuileBento`) à la place de `Skeleton.liste(lignes: 2)` (l.187, DESIGN-GOV §4 bis.6 règle 3) ; erreur des compteurs en une phrase, erreur de l'aperçu dans la tuile Dossiers | `tableau_de_bord_page.dart` |
| DASH-ADM-PLANNING | Page « Planning » de la direction absente ; aucun lien d'ici là | `routes.dart` (domaine Opérations) |
| DASH-ADM-INC | Ouvrir le Journal filtré par une adresse (« incidents des 24 dernières heures ») ; la tuile deviendra un lien | `admin_journal/journal_page.dart`, `routes.dart:452-454` |
| DASH-ADM-ECHUS | Filtre « accès échus » dans Comptes, ouvrable par une adresse | `admin_comptes/comptes_page.dart`, `routes.dart:405` |
| DASH-TUT-CTA | Accueil famille : « Connecter un appareil » au niveau primaire quand il y a blocage ; « Voir la classe » remplacé par la carte-lien | `bandeau_blocage.dart:74-77`, `carte_classe_seance.dart:107-111` |
| DASH-ENS-REMPL | Au-delà de 3 remplacements confirmés : page ou liste où lire les autres | `journee_page.dart:265-268` |
| DASH-ENS-ALERTES | Page où lire toutes les « Alertes utiles » ; d'ici là, « et N autres » sans lien (D6 b) | `journee_page.dart:281-301` |
| DASH-ELV-ERR | Accueil élève : distinguer l'erreur de lecture du « aucun cours » | `accueil_eleve_page.dart:172-176` |
| DASH-MA-PROD | Monter l'Accueil du Mode Accessibilité hors démonstration ; donner une route réelle à l'Aide | `accueil_accessibilite.dart`, `demo_accessibilite_page.dart:414-416` |
| DASH-TUT-BENTO | Accueil famille en `GrilleBento` selon §3.4 | `accueil_famille_page.dart:293-353` |
| DASH-ENS-BENTO | Aujourd'hui en `GrilleBento` selon §3.5 | `journee_page.dart:336-409` |
| DASH-ENS-ROUTE | Donner une route à la liste complète « À terminer » | `journee_page.dart:908-912` |
| DASH-EA-PROD | Accueil adulte : route réelle et historique faits (04/10/2026, §3.7) ; **reste** la source serveur (EA-BR-04, DASH-BR-01, DASH-BR-02, §5 bis) | `routes_accueil_adulte.dart`, `historique_seances_adulte_page.dart` |
| DASH-BIB-TITRE | Titre de `BlocBibliotheque` réduit en bloc à 320 px et texte ×2 (« Ressources de la classe ») : passer à la ligne entre les mots (`TexteSansCoupure`) sur les quatre écrans qui l'emploient | `tc_espace_groupe/emplacements_groupe.dart:155-160` |
| DASH-LIB | Déclarer les libellés de l'annexe B dans `tool/libelles_sources.json` après accord | annexe B |
| ALERTE-1 | **Partie client faite (05/10/2026)** : tri gravité puis date, section en tête du Centre de commande, page des alertes, bandeau, point sur la cloche, port neutre et démonstration. **Reste** : DASH-BR-03 à DASH-BR-06 (§5 bis), puis brancher l'adaptateur Supabase du port et confirmer l'objectif de délai (A5) | `lib/core/alertes/`, `lib/features/alertes/` |
| CARTES-PERSO-1 | Cartes de la classe : partie client faite (05/10/2026, §3.10) ; **reste** la source serveur (CARTES-BR-01 à 03, §5 bis) et l'ouverture du lien (paquet à ajouter, décision du directeur) | `core/tc_groupe/cartes_classe.dart`, `tc_espace_groupe/bloc_cartes_classe.dart`, `feuille_carte_classe.dart` |

Aucun branchement serveur (avant BR-1). Le seul besoin serveur cité (compteur des dossiers qui inclut les tuteurs) est déjà la ligne BR-1.c.

### 5 bis. Registre des besoins serveur DASH

Le registre des besoins de l'élève adulte, `16_eleves_adultes/EA-BR.md`, n'existe que sur la branche `pilotage/tuteur-v1`, hors de la lignée de cette branche. Les besoins nés des lots DASH y sont donc inscrits ici, sous une référence propre (pas de numéro EA-BR inventé qui heurterait la suite de ce registre), **à reporter dans `EA-BR.md` à la réunion des branches**. Rien n'est branché avant BR-1 (K-28) ; chaque ligne suit le doc §17 : idempotence, audit, tests d'accès horizontal, revue sécurité séparée.

| Réf. | Étape | Besoin | Aujourd'hui |
|---|---|---|---|
| DASH-BR-01 | DASH-EA-PROD | Historique complet des séances passées de la Classe de l'élève adulte, prolongement d'EA-BR-06 : pour le compte connecté seulement, chaque séance passée (les plus récentes d'abord), sa date déjà rendue, sa plage horaire, l'absence de l'élève seule (aucune donnée de présence d'un autre élève) ; tests d'accès horizontal (un élève ne lit que sa propre Classe). | `historiqueSeancesAdulteProvider` rend `CapaciteIndisponible` (« indisponible ») ; la démonstration le surcharge (`DonneesAdulteDemo.historiqueSeances()`). |
| DASH-BR-03 | ALERTE-1 | **Gravité portée par chaque alerte et lecture triée** : colonne `gravite` (enum `urgent` / `important` / `info`, A1) sur la table des alertes de la direction (ou des notifications), horodatage **serveur** `cree_le` ; lecture des alertes **ouvertes** du profil connecté seulement, triées gravité puis date ; état traité (qui, quand) et sortie de la liste au traitement ; destination interne (chemin de l'application) ; RLS, `search_path = ''`, tests d'accès horizontal (un profil ne lit que ses alertes). | `portAlertesProvider` rend `AlertesIndisponibles` (`CapaciteIndisponible('DASH-BR-03')`) ; la démonstration admin le surcharge (`AlertesDemo`). |
| DASH-BR-04 | ALERTE-1 | **Temps réel** : Supabase Realtime sur cette table, **canal par profil**, filtré par la RLS (aucune alerte d'un autre profil sur le canal) ; l'adaptateur du port émet la liste complète à chaque changement (`PortAlertes.suivre`). | le port est déjà un flux ; aucun adaptateur. |
| DASH-BR-05 | ALERTE-1 | **Notification push** à la création d'une alerte urgente quand l'application est fermée : d'abord **Web Push (PWA)** (clés VAPID en secret serveur, jamais côté Flutter ; table des abonnements **par appareil**, sous RLS ; fonction d'envoi déclenchée à la création), puis **natif**. | rien côté client (aucune demande d'autorisation de notification n'est posée). |
| DASH-BR-06 | ALERTE-1 | **Délai mesuré** création → affichage : horodatage serveur dans l'alerte (DASH-BR-03), heure d'affichage notée par le client, mesure sur staging ; objectif proposé A5 (moins de 5 s application ouverte), à confirmer par le directeur. | `Alerte.creeeLe` porte déjà l'horodatage ; aucune mesure. |
| DASH-BR-02 | DASH-EA-PROD | Capacité « accueil de l'élève adulte » rendue avec la session (ou le profil), pour que `/eleve` s'ouvre directement sur `/eleve/adulte` sans afficher un instant l'accueil de l'élève, et pour qu'elle ne dépende plus du succès de la lecture d'EA-BR-04 ; jamais déduite du rôle côté client. | `capaciteAccueilAdulteProvider` déduite de la lecture d'`accueil_eleve_adulte` (vraie seulement quand elle réussit, fausse après une relecture en échec) ; le routeur se réveille quand elle change. |
| CARTES-BR-01 | CARTES-PERSO-1 | Table `class_cards` (`id`, `group_id`, `position`, `type` parmi annonce, devoir, lien, rappel, `titre`, `texte`, `lien`, `echeance` en date, `modifie_par`, `modifie_le`, `supprime_le`) ; RLS activée : **écriture** réservée à l'enseignant assigné de la Classe, **lecture** aux membres actifs de la Classe et aux tuteurs de leurs foyers (et à la direction) ; RPC de lecture ordonnée (position, puis identifiant ; cartes non retirées seulement) qui rend aussi la capacité `peut_modifier` de l'appelant ; RPC d'écriture (création, modification, retrait doux par `supprime_le`) avec contrôle des longueurs (titre 1 à 60, texte 280, lien `https` 500), de l'échéance d'un devoir et du plafond de 6 cartes ; idempotence ; `search_path = ''` ; tests d'accès horizontal (un tuteur ou un élève d'une autre Classe ne lit rien, un enseignant d'une autre Classe n'écrit rien). | `portCartesClasseProvider` rend `PortCartesClasseIndisponible` (`CapaciteIndisponible('CARTES-BR-01')`, « Les cartes de la classe ne sont pas encore ouvertes ») ; la démonstration le surcharge (`surchargesCartesClasseDemo`). |
| CARTES-BR-02 | CARTES-PERSO-1 | Masquage a posteriori par la direction (décision du 05/10) : une RPC de la direction masque une carte avec un motif, journalisé ; la carte masquée disparaît de la lecture des membres et des tuteurs ; l'enseignant voit qu'elle a été masquée. | Rien côté client : aucune interface de masquage avant BR-1. |
| CARTES-BR-03 | CARTES-PERSO-1 | Journal d'audit de chaque écriture (création, modification, retrait, masquage) : auteur, Classe, carte, date, ancien et nouveau contenu. | Rien côté client. |

---

## Annexe A : fiches d'écran des tableaux de bord

**Il n'existe pas de catalogue des écrans actif dans `docs/current`.** Le seul catalogue est
archivé (`docs/archive/2026-09-pre-remise-a-plat/design/08-catalogue-ecrans.md`), et
`docs/archive/README.md:16` le dit « remplacé par `docs/current/03` ». On n'écrit pas dans
une archive. Les fiches sont donc ici, **au format de la fiche archivée** (§3 de ce fichier,
l.215-257), réduit aux champs utiles au contenu. **Écart de livrable acté** :
`REPRISE-CORRECTIONS-REVUE.md:39` attendait des « fiches catalogue » ; elles vivent ici en
annexe, faute de catalogue actif (la ligne de REPRISE le dit désormais). Chaque fiche porte
ses cinq états (D11), avec fichier:ligne ou « À FAIRE ».

```
CODE              ADM-01
Nom               Centre de commande
Rôle              Direction
Route             /admin
Question          Qu'est-ce qui attend une décision, et depuis quand ?
Priorités         P0  Alertes, en tête QUAND une alerte urgente est ouverte
                      (toutes les urgentes, puis 3 lignes au plus) ; sinon
                      après les tuiles (ALERTE-1, §3.9)
                  P0  Dossiers à valider (3 plus anciens)       grande
                  P0  Demandes à trancher                         haute
                  P1  Élèves sans enseignant                      carrée
                  P1  Cahiers manquants                           carrée
                  P2  Incidents (24 h) + Accès échus (rapport)    large
                  P2  Raccourcis : Groupes, Comptes, Accès agents IA
Action principale     la tuile Dossiers (aucun bouton plein)
Actions secondaires   les autres tuiles, les noms de l'aperçu (vers leur dossier),
                      les raccourcis
États             chargement  skeleton en grille Bento (Skeleton.tuileBento) ;
                              À FAIRE (DASH-ADM-1), aujourd'hui Skeleton.liste l.187
                  vide        chiffres à 0 + phrase calme si les 4 compteurs
                              d'action valent 0
                  erreur      compteurs (une seule source) : une phrase à la place
                              de la grille (l.177-185) ; aperçu Dossiers refusé
                              (read_kyc_documents, l.215-218) : chiffre gardé,
                              « La liste n'a pas pu être lue. » à la place des noms
                  hors ligne  bandeau de PageShell
                  contenu     5 tuiles + raccourcis
                  alertes     leurs cinq états propres, voir ADM-ALERTES
Invariants        le zéro s'affiche ; une tuile sans page est un rapport ;
                  5 indicateurs quelles que soient les valeurs ;
                  une alerte urgente au-dessus de tout autre contenu
```

```
CODE              ADM-ALERTES
Nom               Alertes
Rôle              Direction (capacité « alertes », jamais le rôle)
Route             /admin/alertes (sous l'Accueil, retour vers l'Accueil)
Question          Qu'est-ce qui exige une action, et quoi d'abord ?
Entrées           cloche de la coquille admin ; bandeau d'alerte urgente ;
                  « Voir toutes les alertes » du Centre de commande
Priorités         P0  Alertes urgentes (toujours en tête)
                  P1  Alertes importantes
                  P2  Alertes pour information
Composition       UNE carte à lignes fines (CarteLignes) ; chaque ligne :
                  gravité écrite (StatusPill), titre, date et heure ;
                  chevron quand elle mène à sa page ; sans page, la ligne
                  n'est pas une cible (jamais grisée)
Tri               gravité, puis la plus récente (trierAlertes, A1)
Action principale     aucune (chaque ligne ouvre sa page)
États             chargement  Skeleton.liste (BlocAsynchrone)
                  vide        « Aucune alerte en cours » (EtatSysteme
                              aucunResultat)
                  erreur      « Les alertes n'ont pas pu être lues » +
                              Réessayer (BlocAsynchrone)
                  hors ligne  bandeau de PageShell ; liste déjà lue gardée ;
                              sans liste : « Les alertes n'ont pas pu être
                              lues » + Réessayer, sans redire « hors ligne »
                              (K-42)
                  indisponible  production avant DASH-BR-03 : « Les alertes
                              ne sont pas encore disponibles », sans
                              Réessayer ; ni cloche ni bandeau
                  contenu     la liste triée
Temps réel        une alerte reçue s'ajoute sans recharger (DASH-BR-04)
Invariants        une urgente en tête jusqu'à son traitement ; gravité
                  jamais par la seule couleur
```

```
CODE              ADM-BANDEAU-URGENT
Nom               Bandeau d'alerte urgente (composant de la coquille admin)
Où                en haut de toute page de la direction, sauf sous l'Accueil
                  (Centre de commande et page des alertes, qui montrent déjà
                  l'alerte en tête, D7)
Contenu           SignalRow au ton d'alerte : « Alerte urgente : <titre> » ou
                  « N alertes urgentes. La plus récente : <titre> », date et
                  heure, chevron ; la carte entière ouvre /admin/alertes
Apparition        dès qu'une alerte urgente entre dans le flux, sans
                  recharger ; région vivante (annoncée par le lecteur
                  d'écran) ; disparaît au traitement
États             rien sans alerte urgente, ni quand la source ne rend rien
                  (indisponible, échec) : un signal, pas un état de page
Position          ALERTE-1b, décidé par délégation le 05/10 : figé tout en
                  haut de l'écran (sous la barre mobile, au-dessus de la
                  page sur rail et barre latérale), hors de la zone qui
                  défile ; il pousse la page, ne la recouvre jamais, et
                  reste en vue jusqu'au traitement. Tant qu'il est posé,
                  la tête de la page (titre, onglets) défile avec elle
                  (règle de PageShell gardée : elle évite le débordement
                  d'une tête haute, Interface guidée, sous le bandeau).
                  Hauteur bornée à la moitié de la vue.
Forme courte      vue de moins de 480 de haut à texte normal (hauteur /
                  échelle du texte : 320x640 à texte x2, téléphone couché,
                  400 %) : « Alerte urgente à traiter » / « N alertes
                  urgentes à traiter », sans titre ni heure (lus sur
                  /admin/alertes, à un tap) ; décidé par délégation le 05/10
Cloche            point quand au moins une alerte urgente est ouverte ; lue
                  « Alertes, une urgente » / « Alertes, N urgentes » ;
                  absente sans capacité (Q5). Sous 600, quand la cloche ne
                  laisse plus au champ de recherche la place du mot le plus
                  long de son indication, le champ cède la place au bouton
                  Recherche (ALERTE-1b, leçon 8)
```

```
CODE              ELV-02
Nom               Accueil élève (présentation standard)
Rôle              Élève
Route             /eleve
Question          Quand est mon prochain cours, et puis-je entrer ?
Priorités         P0  Prochain cours (6 états)
                  P1  Le Coran
Composition       deux blocs empilés ; pas de Bento (D14)
Action principale     Rejoindre (seulement en direct)
États             chargement  deux skeletons de bloc (accueil_eleve_page.dart:209-216)
                  vide        aucun cours aujourd'hui, prochain cours annoncé
                  erreur      À FAIRE (DASH-ELV-ERR)
                  hors ligne  état horsLigne du bloc + bandeau ; Rejoindre
                              présent et inerte (exception D9, l.389-399)
                  contenu     les deux blocs
Invariants        deux blocs, rien d'autre
```

```
CODE              ELV-02-MA
Nom               Accueil élève (Mode Accessibilité)
Rôle              Élève
Route             démonstration seulement (/demo/accessibilite) ; DASH-MA-PROD
Question          Quand est ma prochaine séance, et puis-je entrer ?
Priorités         P0  Prochaine séance + un seul bouton
                  P1  Avant le prochain cours
                  P2  Lire le Coran ; Aide
Action principale     « Rejoindre » quand l'entrée est possible, sinon
                      « Voir ma classe » ; jamais les deux
                      (accueil_accessibilite.dart:36-38, l.102-127)
Composition       une colonne ; deux à partir de 840 / facteur de texte ; pas de Bento
États             chargement  À FAIRE (DASH-MA-PROD) : l'écran reçoit ses données
                              par constructeur (l.42-52), sans lecture propre
                  vide        À FAIRE (DASH-MA-PROD) : aucun cas « sans classe »
                  erreur      À FAIRE (DASH-MA-PROD)
                  hors ligne  bandeau de PageShell (l.161)
                  contenu     salutation, séance, avant le cours, Coran, Aide
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
Action principale     avec blocage : « Connecter un appareil », niveau primaire
                      (aujourd'hui secondaire, bandeau_blocage.dart:74-77) ;
                      sans blocage : la carte de séance, tuile-lien.
                      « Voir la classe » (primaire aujourd'hui,
                      carte_classe_seance.dart:107) cesse d'être un bouton.
                      DASH-TUT-CTA
États             BlocAsynchrone : chargement, erreur, vide (ajouter un profil),
                  sans classe (catalogue), contenu ; hors ligne par PageShell
```

```
CODE              ENS-02
Nom               Aujourd'hui
Rôle              Enseignant
Route             /enseignant/journee
Question          Quelle est ma prochaine séance, et que dois-je terminer ?
Priorités         P0  Prochaine séance                    grande
                  P1  Remplacements confirmés (1 tuile
                      chacun, 3 au plus)                  large
                  P1  Ma journée                          haute
                  P1  À terminer (3)                      grande
                  P2  Alertes utiles (2 + « et N autres ») large
Action principale     tâche immédiate (Rejoindre, Remplir le cahier) : son
                      bouton, seul primaire ; sinon (Préparer, Voir la Classe)
                      la tuile Prochaine séance est le lien
États             chargement  skeleton (journee_page.dart:1188-1197)
                  vide        « aucune séance » dans la carte (l.512-524) ;
                              journée vide « rien aujourd'hui » (l.829-830, l.1155)
                  erreur      séances illisibles : Réessayer (l.186-193) ;
                              échec partiel signalé et relancé (l.237-238, l.288-299)
                  hors ligne  bandeau de PageShell (commentaire l.105)
                  contenu     les cinq tuiles présentes selon les données
```

```
CODE              CTR-01
Nom               Contrôle
Rôle              Contrôleur
Route             /controleur
Question          Quelle classe dois-je observer maintenant ?
Priorités         P0  Carte de mission
                  P1  Compte rendu à terminer (si présent)
Action principale     « Commencer le contrôle », seulement quand la séance est
                      en direct (controle_page.dart:301-311)
Composition       une colonne bornée à 640 ; pas de Bento
États             chargement  Skeleton(hauteur: 180) (l.79-82)
                  vide        aucune mission (l.187-193) ; indisponible, message
                              seul (l.194-200)
                  erreur      EtatSysteme échec serveur + action (l.74-78)
                  hors ligne  bandeau de PageShell
                  contenu     carte de mission (l.70-73, l.206-346)
```

```
CODE              EA-ACCUEIL
Nom               Accueil élève adulte
Rôle              Élève adulte
Route             /eleve/adulte (capacité) ; démonstration /demo/adulte
Question          Quand est ma prochaine séance, et que dois-je préparer ?
Priorités         P0  Prochaine séance            grande
                  P1  Avant le prochain cours      grande
                  P2  Mon parcours (une ligne)     large
                  P2  Dernières séances (3)        grande
                  P2  Ressources (3 + Voir tout)   grande
Action principale     « Rejoindre » quand l'entrée est possible (seul primaire) ;
                      sinon la tuile Prochaine séance, sans bouton plein
Composition       GrilleBento en hauteur de contenu (BENTO-3, l.364-424) ;
                  2 tuiles ou moins : une colonne, pas de Bento (D14)
États             chargement  SqueletteGroupe (accueil_adulte_page.dart:180) et
                              salutation en skeleton (l.212-221) ; le
                              squelette garde l'ancienne forme en colonnes
                              (D11 « fidèle aux tuiles » : à faire)
                  vide        « aucune classe », état subi (l.244-249)
                  erreur      BlocAsynchrone avec Réessayer (l.178-181)
                  hors ligne  bandeau de PageShell (l.168)
                  contenu     les tuiles ci-dessus ; source serveur absente
                              (l.110, DASH-EA-PROD)
```

```
CODE              CLS-CARTES
Nom               Cartes de la classe (emplacement de l'espace de classe)
Rôles             Enseignant de la Classe (modifie) ; tuteur, élève enfant
                  (Interface guidée), élève adulte (lisent)
Écrans            EspaceGroupePage (rangée 1, sous « Avant le prochain
                  cours ») ; FicheGroupePage (après la préparation) ;
                  MaClasseAdultePage (après « À propos ») ; ClasseTuteurPage
                  (après les rubriques ; colonne de la carte sur bureau)
Question          Qu'est-ce que l'enseignant veut que la classe sache ?
Priorités         P1  les cartes, dans l'ordre de la Classe (position)
                  P2  « Ajouter une carte » (enseignant, 6 au plus)
Action principale     aucune dans l'emplacement (le bouton plein de l'écran
                      reste celui de la séance) ; dans la feuille :
                      « Enregistrer la carte », seul bouton plein
Actions secondaires   toucher une carte (enseignant) ouvre sa modification ;
                      « Ajouter une carte » (lien à flèche) ; « Retirer cette
                      carte » (tertiaire, confirmation) ; « Copier le lien de
                      « titre » » (lien à flèche, bouton secondaire pleine
                      largeur « Copier le lien » en Interface guidée, le
                      lecteur d'écran lisant le libellé entier)
Champs (K-57)     modèle       choisi  (ChoiceCardGroup, 4 options expliquées)
                  titre        déduit du modèle, puis saisi (mots de
                               l'enseignant)
                  texte        saisi (facultatif, 280)
                  lien         saisi (facultatif, https)
                  échéance     déduite (prochaine séance) pour devoir et
                               rappel, sinon choisie (sélecteur de date)
États             chargement  Skeleton.liste(lignes: 2) dans BlocAsynchrone
                  vide        famille : « Aucune carte pour l'instant », état
                              subi ; enseignant : phrase « Ajoutez-en une »
                              et le lien d'ajout
                  erreur      « Les cartes de la classe n'ont pas pu être
                              lues. Réessayez dans un instant. » + Réessayer
                  indisponible  production avant BR-1 : « Les cartes de la
                              classe ne sont pas encore ouvertes », sans
                              Réessayer
                  hors ligne  bandeau de PageShell ; cartes déjà lues
                              gardées ; sans elles, EtatSansDonnees (« Les
                              cartes de la classe n'ont pas pu être
                              chargées ») ; enseignant : cartes non
                              pressables, ajout non rendu, phrase « Les
                              cartes pourront être modifiées quand la
                              connexion reviendra »
                  contenu     PileCartes (écart 16), une AppCard par carte
Invariants        capacité lue, jamais un rôle ; aucun bouton grisé ; aucun
                  bouton dans une carte pressable ; aucune fausse carte en
                  production ; aucun mot coupé à 320 px, texte ×2, LTR et RTL
```

## Annexe A bis : FILTRES-1, écrans à filtres (05/10/2026)

**Décidé par délégation le 05/10** (DIR-REP-1) : l'écran exact visé par la remarque du
directeur n'est pas identifié, donc **audit de tous les écrans à filtres** de la branche commune
et **même modèle partout**. Fiche au format de l'annexe A, faute de catalogue actif.

```
CODE              FILTRES-1 (composant partagé, tous rôles)
Composant         RangeeFiltres (lib/core/widgets/rangee_filtres.dart), créé :
                  aucun composant de rangée n'existait, chaque écran posait un
                  Wrap de FilterPill / MenuFiltre (2 à 6 lignes à 320 px x2)
Modèle            UNE rangée de puces, qui défile horizontalement si elle ne
                  tient pas ; puces de même hauteur (la plus haute), contenu
                  centré (K-54) ; une puce n'est jamais plus large que la
                  rangée, un libellé plus long passe à la ligne ENTRE ses mots ;
                  aucun mot coupé ni tronqué à 320 px texte x2, LTR et RTL ;
                  barre de défilement visible dès que la rangée déborde, fondu
                  du bord où des puces sont cachées (sens de lecture) ; le
                  filtre retenu se voit à l'ouverture (rangée centrée sur lui,
                  sans faire défiler la page)
Saisie            choisir plutôt que saisir : axe fermé en puces, axe ouvert en
                  MenuFiltre dont les entrées viennent des données de l'écran
                  (classes, rôles, types d'événement, acteurs) ; les compteurs
                  des puces viennent des données chargées. Les champs de
                  recherche existants (Observations, Bibliothèque) restent,
                  hors rangée ; aucun nouveau champ de saisie
Pas un filtre     le sélecteur de section (MenuFiltre selecteurDeSection,
                  ONGLETS-1) reste sur sa propre ligne
États             le composant n'apparaît que dans l'état contenu (et l'état
                  vide filtré, qui garde la rangée pour défaire le filtre) ;
                  chargement, erreur, hors ligne, vide sont ceux de chaque
                  écran, inchangés par FILTRES-1
Libellés          aucun libellé nouveau ni modifié
Serveur           aucun besoin
```

| Écran | Fichier:ligne | Puces | Avant | Après |
| :--- | :--- | :--- | :--- | :--- |
| Comptes (ADM-08) | `admin_comptes/comptes_page.dart:256` | états, Rôle (menu) | Wrap | RangeeFiltres |
| Groupes / Classes | `admin_groupes/groupes_page.dart:130` | public | Wrap | RangeeFiltres |
| Journal (ADM-04) | `admin_journal/journal_page.dart:262` | période, Événement, Acteur | Wrap | RangeeFiltres |
| Observations (admin) | `admin_observations/observations_admin_page.dart:497` | Classe, Période, Statut, personnes | Wrap | RangeeFiltres |
| Progression | `admin_pedagogie_progression/progression_page.dart:131` | cycles | Wrap | RangeeFiltres |
| Évaluations | `admin_pedagogie_evaluations/evaluations_page.dart:132` | statuts, certifications | Wrap | RangeeFiltres |
| Qualité | `admin_pedagogie_qualite/qualite_page.dart:139` | Toutes, Ouvertes, Traitées | Wrap | RangeeFiltres |
| Programmes (versions) | `admin_pedagogie_programmes/programmes_page.dart:169` | versions | Wrap | RangeeFiltres |
| Historique du contrôleur | `controleur/historique_controleur_page.dart:254` | Période, Classe, État | Wrap | RangeeFiltres |
| Historique du foyer (séances, observations) | `suivi_foyer/composants_historique.dart:180` | Classe, Période, Statut | Wrap | RangeeFiltres |
| Bibliothèque | `tc_catalogue/surface_bibliotheque.dart:165` | types, Disponibilité | Wrap | RangeeFiltres |

**Hors modèle, vérifiés** : `admin_acces_agents/acces_agents_page.dart` (durée, identité,
personne) emploie des `FilterPill` comme **choix de formulaire**, pas comme filtres de liste :
inchangé. Notifications, Mes classes, Créneaux, Disponibilités, Suivi élève, Classe tuteur,
Parcours : le mot « filtre » n'y désigne pas de rangée de puces. **Exclus (autres voies)** :
`lib/features/communications/**`, Finance / Comptable (`finance`, `foyer`, `comptable`,
`revenus`), `salle`, `tc_classe_live` ; aucune rangée de filtres n'y figure sur la branche
commune au 05/10, à relayer si leurs voies en ajoutent.

**Preuves** : `test/core/widgets/rangee_filtres_test.dart` (6 cas) et
`test/features/filtres1_rangee_unique_test.dart` (11 écrans x LTR/RTL, 320 px texte x2,
vraies polices) ; contre-épreuve faite (l'ancien `Wrap` échoue sur les 22 cas d'écran ; le
composant sans fondu ni rappel du filtre retenu échoue sur 7 cas). Captures avant / après :
`docs/current/captures/FILTRES-1/` (script `filtres1_capture_test.dart.txt`). Statut :
présent dans le code, testé localement ; ni staging ni déploiement.

**Écarts vus, hors FILTRES-1, à relayer** : Qualité, la liste lève « Vertical viewport was
given unbounded height » à 320 px texte x2 ; Observations (admin), la date des lignes
(« 23/09/2026 ») se coupe à 320 px texte x2 ; Groupes, la page s'intitule encore
« Groupes » (lot 3, « groupe » devient « classe »).

## Annexe B : libellés nouveaux

Statut : **proposé par un agent** (leçon 12, K-53.4). Aucune clé i18n n'est créée.

| Proposition | Où | Remarque |
|---|---|---|
| « Les classes, leurs élèves et leur enseignant. » | légende de la ligne Groupes des raccourcis (ADM-01) | le titre réutilise `admin.groupes.titre` (« Groupes ») ; à revoir avec le renommage « groupe » → « classe » du lot 3 |
| « Rien n'attend de décision aujourd'hui. » | phrase calme sous les tuiles, **seulement quand les 4 compteurs d'action valent 0** : dossiers, demandes, élèves sans enseignant, cahiers manquants (ADM-01) | remplace `admin.tableau.aTraiterAucun` et `aTraiterAucunDetail` ; vraie dans ce seul cas, puisque les 4 sont des files d'action |
| « La liste n'a pas pu être lue. » | tuile Dossiers, à la place des noms quand l'aperçu est refusé (ADM-01) | reprend le sens de `admin.tableau.listeErreur` ; le chiffre reste |
| « Incidents et accès » | titre de la tuile 5 unique (ADM-01) | les deux libellés de chiffre restent `admin.tableau.incidents` et `admin.tableau.comptes` |
| « Vos cours n'ont pas pu être lus. Réessayez dans un instant. » | erreur de l'Accueil élève (DASH-ELV-ERR) | format K-59 : ce qui manque, l'action |

**ALERTE-1 (05/10/2026)**, clés `alertes.*`, rédigées par l'agent, à faire valider par le
directeur (déclarées dans `tool/libelles_sources.json`) : « Alertes » ; gravités « Urgente »,
« Importante », « Pour information » ; « Le {date} à {heure} » ; « Alerte urgente : {titre} » ;
« {nombre} alertes urgentes. La plus récente : {titre} » ; « Voir toutes les alertes » ;
« Aucune alerte en cours. » ; « Une alerte urgente s'affichera ici, en tête, dès son
arrivée. » ; « Les alertes ne sont pas encore disponibles » ; « Les alertes urgentes
s'afficheront ici, en tête, dès que leur source sera ouverte. » ; « Les alertes n'ont pas pu
être lues » ; cloche « Alertes », « Alertes, une urgente », « Alertes, {nombre} urgentes ».

Réutilisés sans changement : `tuteur.accueil.voirTout` (« Voir tout »), `admin.tableau.*` des compteurs.

## Reste

Points de la relecture du 02/10/2026 traités en partie seulement :
- **S5 en M3** : la règle des cartes reste une règle **M1**, non revérifiée en M3 (page
  `m3.material.io/components/cards` illisible sans JavaScript ; `Card.md` M3 muette sur le
  sujet). D4 tient sans elle (S7, DESIGN-GOV Contrat B règle 4). À relire dans un navigateur.
- **S9** : le guide Instructure n'est plus joignable par ses liens d'origine ; une copie tierce
  datée est citée. L'URL actuelle sur `community.instructure.com` n'a pas été retrouvée
  (`.../Student-Guide/.../ta-p/525` mène à un autre article).
- **§0** : la source exacte de la demande du directeur (commentaire d'artefact ou consigne
  datée) n'est pas dans le dépôt ; le texte est présenté comme une reformulation.
- **Q1** : la perte du tri commun dossiers + demandes est dite, mais la décision revient au
  directeur.
- Les autres points (S3, D1 à D14 et colonne « Conclusion », S11 Flutter, D3 à 5 dans tous les
  cas, aperçu Dossiers cliquable, états d'erreur ADM-01, phrase calme, boutons dominants
  TUT/ENS/EA, remplacements, fiches complètes, ELV-02 sans Bento, exceptions D6 et D9,
  Incidents et Accès échus, skeleton Bento) sont corrigés dans le corps du document.
