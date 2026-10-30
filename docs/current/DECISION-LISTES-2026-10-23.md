# Listes de gestion : « List-first, human-first »

**Directeur, 23/10/2026.** Point de départ : la page Candidatures, où 684 px séparaient le haut de l'écran de la première ligne et où 2 lignes seulement étaient visibles à 1440 x 900, alors que l'académie reçoit environ 600 personnes en quelques jours et que le volume grandira. La demande vaut pour toute l'application. Ce document est la **source canonique unique** de la règle ; les autres fichiers y renvoient, sans la recopier.

## 1. La règle (texte du directeur, mot pour mot)

> Dans toute vue de gestion fondée sur une liste, le contenu métier occupe la priorité visuelle et spatiale. Les commandes doivent être regroupées, les détails secondaires accessibles à la demande et les actions courantes réalisables efficacement. Les listes longues doivent être conçues pour les volumes réels et futurs, pas uniquement pour quelques données de démonstration.

## 2. Rang de cette décision

- C'est une **demande explicite et datée du directeur**, donc de rang 1 dans l'autorité de `DESIGN-GOV-2026-09-26.md` §1. Elle s'applique sans modifier ce fichier.
- Elle applique `DESIGN-GOV` §4.3 (les standards UX améliorent disposition, densité, lisibilité, focus, place des actions) et ne l'amende pas. Elle n'élargit aucune permission, ne change aucune règle métier et ne touche aucun jeton gelé.
- `DESIGN-GOV-2026-09-26.md` et le bloc gelé de `03_DESIGN_SYSTEM_ET_UX.md` ne sont pas modifiés. La preuve UX de la disposition est `UX_REVIEW_LISTES-1.md` (§4.2 de `DESIGN-GOV`).
- La maquette fournie par le directeur sert de **disposition seulement**. Ni ses couleurs, ni ses polices, ni ses rayons, ni ses espacements ne sont repris : ce sont ceux de Rewayah (K-63, `AD-X_DECOUPAGE.md`).
- Portée : les écrans nommés par le directeur (Candidatures, élèves et tuteurs) sont traités ; les autres listes sont **recensées** (§7) et ne se reprennent qu'au besoin, une à la fois (`DESIGN-GOV` §4 bis.8 : aucune étape `fait` n'est rouverte sans demande).

## 3. Mesures vérifiables

| # | Exigence | Mesure |
| :-: | :--- | :--- |
| 1 | Contenu métier visible d'abord | Environ 10 lignes entières visibles à 1440 x 900 avec la coque, sans défiler. Candidatures : première ligne à y = 288 (684 avant), 10 lignes entières. |
| 2 | Lignes denses | 48 px pour une ligne de texte, 56 px avec une case ou un menu (cible du mode d'interface). Seule une ligne portant une alerte peut monter, sans déformer le tableau. 72 et 80 px en Interface guidée. |
| 3 | Commandes regroupées | Au bureau, recherche, filtres fréquents et « Plus » sur **une seule rangée** (`RangeeFiltres`). Filtres actifs en puces retirables, avec « Tout effacer ». Compteur de résultats près de la liste. |
| 4 | Cibles gardées | 48 px au moins, y compris au bureau : la densité vient des espacements, pas des cibles (`03`, `DESIGN-GOV`). |
| 5 | Menu d'actions | **Aucune infobulle** sur son déclencheur (le libellé reste dit au lecteur d'écran), surface opaque des jetons (celle des dialogues), filet franc (encre atténuée, environ 3:1) et ombre des surfaces qui recouvrent, **y compris en sombre**, largeur de 224 à 320 px, jamais tronqué, fermeture au clic extérieur et à Échap, focus clavier visible, entrées destructives en dernier et séparées. Un seul menu ouvert à la fois. |
| 6 | Sélection multiple | Seulement s'il existe une **opération groupée réelle** côté serveur. Sinon pas de case. La sélection de page n'est jamais « tous les résultats filtrés » ; elle ne change pas en silence. **Un filtre ou une recherche qui change la retire, avec un message ; un changement de tri ou de page la garde** (le compteur dit « dont N sur cette page »). Le directeur a laissé ce choix au meilleur pour les utilisateurs (23/10) : il est retenu, comme dans une messagerie, pour cocher sur plusieurs pages sans tout perdre. Un geste réussi depuis une ligne retenue la retire de la sélection. La barre de sélection et les messages **flottent** au-dessus du pied de liste : rien ne pousse le tableau. |
| 7 | Aucun faux contrôle | Pas de case sans opération, pas d'indicateur d'une donnée non servie, pas de tri qui ne trie pas, pas de taille de page imposée sans moyen de la changer. Une limite serveur s'écrit à l'écran. |
| 8 | Contexte gardé | Retour d'une fiche : recherche, filtres, tri, page et position sont conservés (la liste reste empilée). |
| 9 | Volumes | Pagination (« 1-50 sur 614 »), en-tête de tableau collé, tri par colonne quand l'écran le fournit. États loading, content, empty, error, offline. |
| 10 | Les quatre combinaisons | Clair et sombre, 390 et 1440 px, texte x1 et x2, LTR et RTL (arabe). |

Table au bureau (fenêtre de 1200 px ou plus), cartes en dessous : règle de `DataCollection` conservée.

## 4. Règle vers composants

Un seul système par fonction : on corrige le composant partagé, on n'en recrée pas un (`lib/CLAUDE.md`, LISTES-1).

| Fonction | Composant (`lib/core/widgets`, sauf mention) |
| :--- | :--- |
| Table au bureau, cartes ailleurs, colonne de cases, colonne d'actions, tri d'en-tête, en-tête collé | `DataCollection` (API additive) ; `Skeleton.tableDense` pour le chargement |
| Case à cocher, page à trois états | `CaseACocher` (jamais un `Checkbox` Material recomposé) |
| Barre de sélection sur une ligne | `BarreSelection.compacte` |
| Menu d'actions de ligne | `MenuActions` (paramètre `objet`), forme commune `menu_commun.dart` ; thème `popupMenuTheme` et `tooltipTheme` d'`AppTheme.pour` |
| Menu de filtre | `MenuFiltre` (même forme que `MenuActions`) |
| Rangée de filtres | `RangeeFiltres` (`visiblesMax`, 3 par défaut) |
| Filtres actifs | `PuceFiltreActif`, `FiltresActifs` |
| Pied de liste | `PiedDeListe` |
| Pays avec drapeau | `PaysEnseignant.parCode` (image embarquée, jamais d'emoji ; pays sans image : nom seul) |
| Précédent et suivant | `BarrePrecedentSuivant` |

## 5. Décisions frontend prises

Prises par délégation, réversibles, sans contradiction avec les règles gelées.

1. **Cibles de 48 px conservées** ; lignes de 48 à 56 px.
2. **Un seul système de menus**, corrigé à sa source. Cause du « petit panneau sombre transparent » : l'infobulle Material par défaut (gris translucide, attente nulle) posée sur tout déclencheur de `PopupMenuButton`, aggravée par un menu sans thème (surface sur canevas, contraste 1,015:1, rayon 4, ombre noire).
3. **Taille de page de Candidatures : 50**, imposée par `lister_candidatures` ; pas de faux sélecteur. Comptes : tout est déjà en mémoire, donc pagination client 25, 50 ou 100.
4. **Un geste lancé depuis une ligne relit d'abord le dossier**, puis ouvre la **même** feuille que la fiche, avec le même calcul des gestes permis (`gestes_proposes.dart`) : la ligne ne porte pas de `version`.
5. **Traitement groupé de Candidatures** : branche le lot existant (`apercu_lot_candidats`, `executer_lot_candidats` : mettre en pause, lever la pause, refuser ; 1 à 200 ; aperçu avec exclus motivés ; nombre à confirmer ; clé d'idempotence ; rapport par ligne). Les autres gestes restent individuels, la barre le dit.
6. **Élèves et tuteurs (Comptes)** : aucune opération groupée fiable n'existe, donc **pas de sélection multiple** ; la limite est écrite dans le code. Recherche, rôles visibles avec leur compte, tri client, pagination client, avertissement dès que la base rend 1000 comptes.
7. **Synthèse « À traiter » compacte** : une ligne, sans indicateur d'une donnée non servie (les alertes « bloquées » et « entretiens en retard » ne sont pas servies, donc non affichées).
8. **La fiche d'une candidature garde son ordre de gestes** : le menu d'une ligne range lui-même les gestes destructifs en dernier (`gestesDuMenuLigne`).
9. **Le texte cherché n'est jamais dans une adresse** (Comptes : nom ou identifiant d'une personne). Le rôle, l'état, les accès échus et le tri y restent.
10. **Pastille neutre** (`StatusPill`) : un filet posé par-dessus la détache d'une ligne de tableau en sombre, sans changer sa taille. **Pastille de tableau** : à la largeur de son texte, jamais étirée sur la colonne.
11. **Cartes** (téléphone) : la case et le menu sont dans la carte, en tête ; un état garde sa pastille ; un nombre seul dit de quoi il est le nombre. Le tri des cartes de Candidatures est un menu au bout de la rangée des filtres. Le pied de liste étroit ne garde que la navigation.
12. **Filtres actifs** : la rangée de puces ne montre que ce que la barre ne montre pas déjà (axes rangés sous « Plus »). Le compteur d'une salle dit « n en cours ».
13. **Pied commun** : la taille de page imposée par la source est dite (`PiedDeListe.mention`) au même endroit que le sélecteur d'une taille réelle ; Classes passe au pied collé.

## 5 bis. Comptes séparé par rôle (directeur, 30/10/2026)

Capture de l'écran Comptes au téléphone, mot du directeur : « Sur ce profil, il y a des tuteurs, des enseignants, des élèves, mais l'application ne fait pas de différence. C'est compliqué. Normalement, les élèves doivent être à part, parce qu'on ne peut pas ajouter les tuteurs directement dans une classe. » **Cette décision prévaut sur §5.6 pour la page Comptes** (une seule liste filtrée par rôle).

1. **Quatre vues**, choisies en haut de l'écran par `SelecteurSection` (ONGLETS-1 : en ligne au bureau, menu au téléphone quand quatre libellés ne tiennent pas), chacune avec sa liste, ses colonnes, sa recherche, son tri et sa page : **Élèves** (matricule, âge, classe, tuteur), **Familles** (tuteurs, élèves rattachés), **Enseignants** (pays, pièce d'identité, contrats), **Direction** (administration, comptabilité, contrôle ; proposée seulement si elle a des comptes).
2. Une vue range les **profils** par rôle : un tuteur qui est aussi élève (deux profils) est une fois dans Familles, une fois dans Élèves, jamais deux fois dans la même vue.
3. **La vue ouverte par défaut** est la première, dans cet ordre, qui contient une décision en attente (enseignant en attente ; demande d'admission reçue, `DECISION-ADMISSION-2026-10-27.md`) ; sinon Élèves. Le nombre de chaque vue est compté dans les données lues.
4. Lecture : `comptes_admin_par_role()` (migration `20261101100000`, lecture seule) ; tant qu'elle n'est pas installée, repli sur `comptes_admin()` et bandeau qui dit que l'âge, la classe et le tuteur ne sont pas servis. L'adresse porte `vue`, `etat`, `filtre`, `tri` ; un ancien lien `?role=` ouvre la vue de ce rôle.
5. Toujours **aucune sélection multiple** (§5.6 reste vrai sur ce point).

## 5 ter. La tête défile avec la liste (directeur, 30/10/2026)

**Source : directeur, 30/10 : « tout ce qui n'est pas important ne doit pas apparaître en permanence à l'écran ; l'en-tête ne reste pas fixe au-dessus d'une liste ».** Dit sur les captures de Comptes au téléphone et au bureau (« le header est fixe, donc tout ce qu'on fait défiler passe dessous ; imagine avec 500 ou 1000 élèves »). Revue UX : `UX_REVIEW_LISTES-2.md`.

1. **Rien de fixe au-dessus des lignes, sauf la barre de l'application.** Titre, choix de vue, filtres et recherche défilent avec la liste ; au bureau, seule la rangée d'en-têtes de colonnes reste collée ; le pied de liste vient après la dernière ligne.
2. **Un seul titre** : quand la page a une sous-navigation, sa liste déroulante remplace le grand titre (« Comptes ▾ »), sur la rangée du retour et des actions.
3. **Une seule rangée de commandes** : au téléphone, [vues ▾ | État | loupe] (ONGLETS-1 respecté, sans exception) ; au bureau, les vues en segmenté si elles tiennent, les filtres, la recherche à droite. Au-delà de 130 % de texte, les filtres passent sous la rangée des vues.
4. **Pas de compteur redondant** (le nombre est dans le choix de vue et le pied) ; ce qui attend une décision est une puce « En attente » de la rangée (bureau) ; seule l'exception d'état a sa pastille, jamais « Actif ».
5. **Lignes denses au téléphone** (amende §3 « cartes sous 1200 px » pour les listes qui adoptent le mode) : nom, puis l'essentiel sur une ligne (« matricule · classe · tuteur »), 64 px au moins, filets fins dans un seul cadre ; l'Interface guidée garde 72 et 80 px.
6. **Adoption liste par liste** (`DESIGN-GOV` §4 bis.8) : mode opt-in des composants partagés, `PageShell(teteAvecLaListe: true)`, `DataCollection(prendTeteDePage: true, tete: ..., densiteTelephone: true)`, `ColonneDonnees(ligneDense: false)`. Comptes l'adopte le 30/10 ; Candidatures sera la suivante. Les autres pages ne changent pas.
7. **Mesures (Comptes, 30/10, vraies polices, `test/capture/listes_comptes_vues_capture_test.dart`)** : 390 x 844, première ligne à y = 192, 10 lignes entières ; 1440 x 900, première ligne à y = 204, 14 lignes entières (Élèves, Familles), 12 (Enseignants, menu de 56) ; 1366 x 768, y = 204, 11 lignes (10 en Enseignants).

## 6. Limites serveur (frontend seulement : non corrigées)

- `lister_candidatures` : page de 50 en dur ; pas de `version` dans la ligne ; 2 alertes sur 4 non servies et aucune clé de filtre « alerte » ; audit à chaque lecture. Colonne Date non triable en croissant.
- `comptes_admin()` : ni recherche, ni tri, ni total, ni pagination ; plafond `max_rows` (1000 en local, valeur distante inconnue) ; ni courriel, ni matricule, ni pays, ni dernière activité pour tous les rôles. Les comptes candidats ne sont pas écartés (pas de marqueur serveur). Depuis le 30/10, `comptes_admin_par_role()` ajoute la tranche d'âge (jamais l'âge exact : aucune date de naissance au profil), la classe active, le tuteur d'un élève, le pays d'un enseignant et la demande d'admission à traiter ; ni page, ni recherche, ni total non plus.
- Aucune RPC de lot, de suspension ou d'export pour élèves et tuteurs : **demande de contrat serveur à ouvrir**.
- `journal_audit` : ni total ni recherche. Catalogue de la bibliothèque : curseur, pas de total.
- **Les alertes de la synthèse ne filtrent pas** : la mission voulait que chaque indicateur applique son filtre. `lister_candidatures` n'a aucune clé de filtre « alerte », et aucun filtre existant n'est équivalent (« Informations manquantes » compte aussi le complément demandé en Salle de vérification). Les nombres sont ceux du serveur, calculés sur toute la portée ; la ligne dit le fait, sans faux contrôle. Contrat serveur à ouvrir : une clé de filtre par alerte.
- Depuis une ligne de candidature, on ne peut pas confirmer un moyen de paiement sous restriction ni « Choisir le responsable » (dossier requis).
- 65 drapeaux embarqués (`LICENCE.txt` à jour) ; un pays sans image s'affiche en nom seul.

## 7. Inventaire des 30 listes

Détail et défauts : l'inventaire du lot 4 (`5-inventaire-traitement.md`, copié dans la revue). Statuts : **refondue** (lots 2 et 3), **corrigée** (code changé), **bénéficie du socle** (menu opaque, densité, focus), **inchangée**.

| # | Liste | Statut | Prochaine étape |
| :-: | :--- | :--- | :--- |
| 1 | Comptes (élèves, familles, enseignants, direction) | refondue, séparée par rôle (30/10) | contrat serveur paginé et recherché |
| 2 | Progression | corrigée (recherche, menu) | pagination client, tri d'en-tête, mot « cycles » à arbitrer |
| 3 | Paiements (à régulariser) | inchangée | recherche client et compteur ; décision du directeur sur toute action groupée |
| 4 | Dossiers à valider | inchangée | recherche client ; sélection groupée interdite (DEC:24) |
| 5 | Candidatures | refondue | taille de page serveur |
| 6 | Invitations | inchangée | formulaire replié, `MenuActions` pour « Révoquer » |
| 7 | Espace de traitement | inchangée | recherche client, compteur |
| 8 | Classes | corrigée (menu) | `PiedDeListe`, `FiltresActifs` |
| 9 | Regroupements | inchangée | table au bureau (la carte porte « Créer la classe ») |
| 10 | Pilotage | bénéficie du socle | en-tête compact |
| 11 | Journal d'audit | bénéficie du socle | recherche serveur à demander |
| 12 | Planning de la direction | inchangée | recherche et filtre client |
| 13 | Avis | inchangée | table dense (lecture avant publication, `DECISION-AVIS`) |
| 14 | À valider (finance) | inchangée | table (décision du directeur : finance) |
| 15 | Évaluations | corrigée (menu) | recherche client et compteur |
| 16 | Catalogue de la bibliothèque | bénéficie du socle | rien d'urgent |
| 17 | Observations (historique) | bénéficie du socle | rien ; modèle de filtre actif |
| 18 | Tirages (historique) | inchangée | table dense, règles repliées |
| 19 | Reprises de foyer | inchangée | table et menu ; confirmation inchangée |
| 20 | Suppressions de compte | inchangée | table dense |
| 21 | Importer (aperçu) | inchangée | `PiedDeListe` client |
| 22 | Offres vitrine | inchangée | table et menu (seule l'administration publie) |
| 23 | Accès des agents IA | bénéficie du socle | formulaire replié |
| 24 | Incidents (24 h) | inchangée | rien |
| 25 | Programmes (niveaux) | corrigée (menu) | rien |
| 26 | Qualité (anomalies) | corrigée (menu) | recherche client, tri |
| 27 | Diagnostics, Demandes | inchangée | ne pas toucher (file séquentielle voulue) |
| 28 | Attribution d'un support | inchangée | `CaseACocher` et `BarreSelection.compacte` |
| 29 | Sélecteur de personne | inchangée | à suivre avec Comptes |
| 30 | Tableau de bord (Accueil) | inchangée | hors périmètre (tuiles) |

Non migrés vers `CaseACocher` : 8 `Checkbox` ou `CheckboxListTile` dans `lib/features/` (liste datée du 23/10/2026 dans `tool/verifier_revue.dart`, règle `case-recomposee`), et 7 sites du patron « colonne vide + `rendreMemeSiTexteVide` + `flex: 0` ».

## 8. Statuts de preuve (au 23/10/2026)

| Élément | Spécifié | Présent dans le code | Testé localement | Testé sur staging | Déployé |
| :--- | :-: | :-: | :-: | :-: | :-: |
| Menu d'actions, thème, `MenuFiltre` | oui | oui | oui | non | non |
| `DataCollection`, `CaseACocher`, `PiedDeListe`, `PuceFiltreActif`, `BarreSelection.compacte`, `PaysEnseignant.parCode` | oui | oui | oui | non | non |
| Candidatures (liste, menu de ligne, lot) | oui | oui | oui | non | non |
| Comptes (élèves, tuteurs) | oui | oui | oui | non | non |
| Comptes séparé par rôle (30/10) et `comptes_admin_par_role()` | oui | oui | oui (tests Flutter, scénario SQL sur Postgres 16 neuf) | non | non |
| Tête qui défile avec la liste, lignes denses (§5 ter, Comptes seulement) | oui | oui | oui (tests Flutter, captures et mesures) | non | non |
| Autres listes (menus migrés, recherche de Progression) | oui | oui | oui | non | non |
| Listes non traitées (§7, « inchangée ») | oui | non | non | non | non |

Tests : tout vert sur les dossiers touchés ; la suite complète lancée avant les deux commits de correction de la fusion comptait 13 échecs, dont 8 déjà présents sur la base `1f6e0351` ; elle n'a pas été relancée en entier après. Les appels du lot (`apercu_lot_candidats`, `executer_lot_candidats`) ne sont pas testés contre un vrai serveur. Rien n'est testé sur staging ni déployé.

## 9. Preuve machine

- `dart run tool/verifier_revue.dart --regle=case-recomposee` : interdit un `Checkbox` Material dans `lib/features/` (exceptions datées).
- Tests de densité et de contexte : `test/features/admin_candidatures/candidatures_liste_test.dart` (dix lignes entières, état gardé au retour de la fiche), `test/features/comptes_liste_test.dart`, `test/core/widgets/data_collection_listes_test.dart`, `composants_listes_test.dart`, `menu_commun_test.dart`.
- Captures : harnais `test/capture` (`listes1_*`, `listes2_*`, `listes3_*`, `listes4_*`).
