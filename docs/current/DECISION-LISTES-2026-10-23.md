# Listes de gestion : « List-first, human-first »

**Directeur, 23/10/2026.** Point de départ : la page Candidatures, où 684 px séparaient le haut de l'écran de la première ligne et où 2 lignes seulement étaient visibles à 1440 x 900, alors que l'académie reçoit environ 600 personnes en quelques jours et que le volume grandira. La demande vaut pour toute l'application. Ce document est la **source canonique unique** de la règle ; les autres fichiers y renvoient, sans la recopier.

> **01/11/2026, prévaut sur ce document** : aucune liste ne défile dans un cadre de hauteur fixe ; la liste est la page (`DECISION-DEFILEMENT-2026-11-01.md`).

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
2. Un tuteur qui est aussi élève est une fois dans Familles, une fois dans Élèves, jamais deux fois dans la même vue : qu'il ait deux profils (une ligne de chaque rôle) ou un seul compte tuteur qui apprend pour lui-même (D5, 30/10/2026 : `guardian` avec une fiche d'élève autonome ; `comptes_admin_par_role().est_apprenant`).
3. **La vue ouverte par défaut** est la première, dans cet ordre, qui contient une décision en attente (enseignant en attente ; demande d'admission reçue, `DECISION-ADMISSION-2026-10-27.md`) ; sinon Élèves. Le nombre de chaque vue est compté dans les données lues.
4. Lecture : `comptes_admin_par_role()` (migration `20261101100000`, lecture seule) ; tant qu'elle n'est pas installée, repli sur `comptes_admin()` et bandeau qui dit que l'âge, la classe et le tuteur ne sont pas servis. L'adresse porte `vue`, `etat`, `filtre`, `tri` ; un ancien lien `?role=` ouvre la vue de ce rôle.
5. Toujours **aucune sélection multiple** (§5.6 reste vrai sur ce point).

## 5 ter. La tête défile avec la liste (directeur, 30/10/2026)

**Source : directeur, 30/10 : « tout ce qui n'est pas important ne doit pas apparaître en permanence à l'écran ; l'en-tête ne reste pas fixe au-dessus d'une liste ».** Dit sur les captures de Comptes au téléphone et au bureau (« le header est fixe, donc tout ce qu'on fait défiler passe dessous ; imagine avec 500 ou 1000 élèves »). Revue UX : `UX_REVIEW_LISTES-2.md`.

1. **Rien de fixe au-dessus des lignes, sauf la barre de l'application.** Titre, choix de vue, filtres et recherche défilent avec la liste ; au bureau, seule la rangée d'en-têtes de colonnes reste collée ; le pied de liste vient après la dernière ligne.
2. **Un seul titre** : quand la page a une sous-navigation, sa liste déroulante remplace le grand titre (« Comptes ▾ »), sur la rangée du retour et des actions.
3. **Une seule rangée de commandes** : au téléphone, [vues ▾ | État | loupe] (ONGLETS-1 respecté, sans exception) ; au bureau, les vues en segmenté si elles tiennent, les filtres, la recherche à droite. Au-delà de 130 % de texte, les filtres passent sous la rangée des vues.
4. **Pas de compteur redondant** (le nombre est dans le choix de vue et le pied) ; ce qui attend une décision est une puce « En attente » de la rangée (bureau) ; seule l'exception d'état a sa pastille, jamais « Actif ».
5. **Lignes denses au téléphone** (amende §3 « cartes sous 1200 px » pour les listes qui adoptent le mode) : nom, puis l'essentiel (« matricule · classe · tuteur »), qui passe à la ligne s'il ne tient pas, jamais tronqué (COUPE-MOTS), 64 px au moins, filets fins dans un seul cadre ; l'Interface guidée garde 72 et 80 px.
6. **Adoption liste par liste** (`DESIGN-GOV` §4 bis.8) : mode opt-in des composants partagés, `PageShell(teteAvecLaListe: true)`, `DataCollection(prendTeteDePage: true, tete: ..., densiteTelephone: true)`, `ColonneDonnees(ligneDense: false)`. Comptes l'adopte le 30/10 ; Candidatures sera la suivante. Les autres pages ne changent pas.
7. **Mesures (Comptes, 30/10, vraies polices, `test/capture/listes_comptes_vues_capture_test.dart`)** : 390 x 844, première ligne à y = 192, 9 lignes entières (Élèves), 10 (Familles, Enseignants) ; 1440 x 900, première ligne à y = 204, 14 lignes entières (Élèves, Familles), 12 (Enseignants, menu de 56) ; 1366 x 768, y = 204, 11 lignes (10 en Enseignants).

## 5 quater. Des listes de bureau, la liste est la page (directeur, 01/11/2026)

**Source : directeur, 01/11/2026, mot pour mot.** Sur Opérations › Classes : « maintenant, il faut masquer les classes clôturées. qu'est-ce qui empêcherait d'avoir une liste comme sur l'image ? … le contenu prend toute la page parce que la page est faite pour, le reste c'est du secondaire, on le voit pas partout. en plus sur ordinateur les menus doivent être pour ordinateur et non pour mobile. » Et, plus tôt le même jour : « je t'interdis de bricoler la page morceau par morceau. les specs des listes existent déjà… le contenu change, mais le style doit rester le même ; épuré, et surtout peu d'éléments qui ne sont utiles qu'une seule fois, comme ces filtres et les en-têtes. » Il veut la refonte de **toutes** les listes ; il a été averti que cela sort de la Boucle 1. Va avec `DECISION-DEFILEMENT-2026-11-01.md` (aucun contenu ne défile dans un cadre de hauteur fixe ; une seule barre de défilement par écran).

La référence est une maquette tiers (page « Employees » de bureau), décrite par le garde-cap et **non déposée** (vrais visages). On n'en prend que la **disposition** : couleurs, polices et rayons restent nos jetons (`verifier_jetons`), aucun dégradé, aucune marque tierce.

1. **Au bureau (1200 px et plus), le contenu d'une liste prend toute la largeur** de la zone de contenu, gouttières gardées : `AppPage.largeurMaxContenu` (1200) ne borne plus une liste. Amende la règle implicite de largeur bornée de §3.
2. **La liste vit dans `AdminShell`**, barre latérale visible, **sans flèche de retour**, à toutes les largeurs : la barre latérale (le tiroir au téléphone) est la navigation (pilote, 01/11/2026, relecture de la PR 122 : aucune règle écrite n'impose ce retour ; §5 ter.2 le mentionne sans l'exiger).
3. **Une seule tête, réduite** : le titre (ou la sous-navigation qui en tient lieu, §5 ter.2), une **icône filtre** dans un petit carré et **une seule action** pleine. Aucune phrase d'explication permanente (l'introduction de Classes est retirée).
4. **Filtres repliés derrière l'icône** : au bureau, recherche et filtres se déplient en panneau (toutes les puces visibles, passant à la ligne, sans « Plus » ni défilement horizontal) qui défile avec la liste. Panneau replié, les filtres retenus restent dits en puces retirables (`FiltresActifs`, « Tout effacer ») : rien n'est caché sans le dire. **Amende §3.3** (une rangée de recherche, filtres et « Plus » au bureau ; puces des filtres actifs toujours visibles) et **§5 ter.3** (la rangée de commandes au bureau). Au téléphone, §5 ter.3 reste.
5. **Lignes en cartes** : au bureau, chaque ligne est une carte claire arrondie (rayon `AppRadius.xs`, 8), séparée de la suivante par 8 px, sans filet ni cadre de tableau ; les en-têtes de colonnes sont discrets (petites lettres, encre atténuée, fond de la page), seuls collés, avec le chevron de tri existant (`TriColonne`) quand l'écran trie. Première colonne : cercle de 32 px (`AvatarNom`, `AppAvatar.petit`), le nom sur une ligne (la colonne prend la largeur qu'il faut ; un nom trop long passe à la ligne entre ses mots, jamais tronqué, COUPE-MOTS), l'état dessous dans la même pastille qu'au téléphone ; les autres colonnes en texte simple. La cible de 48 px (§3.4) est gardée : une ligne avec menu et pastille mesure 60 px.
6. **Menus de bureau** : menus contextuels ancrés (`MenuActions`, `MenuFiltre`, menu de `menu_commun.dart`), jamais de feuille du bas ni de boîte au milieu de l'écran. **Une fiche est une page** de la coquille, empilée au-dessus de la liste, qui défile comme une page ; au retour, recherche, filtres, page et position sont gardés (§3.8). L'inspecteur de bureau de Classes (AD-X, 336 px qui défilaient dans leur propre cadre) est retiré (pilote, 01/11/2026, 16:45 UTC).
7. **Téléphone** : le comportement de §5 ter reste (tête et filtres qui défilent avec la liste, lignes denses) ; l'action de création flotte en bas au bord de fin, disque plein de 48 px (`BoutonIcone`, forme `appel`, ton `ouvert` : aucun composant nouveau), et la liste garde la place de ce disque sous son pied.
8. **Mode opt-in des composants partagés**, adopté liste par liste, comme §5 ter.6 : `PageShell(listeBureau: true)` (pleine largeur au bureau, pas de retour à toutes les largeurs), `DataCollection(lignesCartes: true)` (dans le rendu par tranches), `RangeeFiltres(enPanneau: true)` et `RangeeFiltres.bascule(...)`. Aucun composant concurrent. Les autres pages ne changent pas.
9. **Classes l'adopte le 01/11/2026 (lot L1)** : vue par défaut **Ouvertes** (actives et en attente d'enseignant), « Clôturées » et « Toutes les classes » restent des filtres ; rien n'est effacé en base (`classes_admin_page` reçoit `p_etat = 'ouvertes'`, migration `20261103800000_classes_admin_ouvertes.sql`). Pied de liste commun (`PiedDeListe`, « 25 par page » dit, taille imposée par le serveur).
10. **Mesures (Classes, 01/11/2026, vraies polices, coque comprise, `test/capture/listes_classes_capture_test.dart`, démonstration de 630 classes)** :

| Vue | Avant (main du 01/11) | Après (L1) |
| :--- | :--- | :--- |
| 1440 x 900 | première ligne à y = 368, 8 lignes entières | y = 112, **11 lignes entières** (lignes de 60, nom et pastille d'état) |
| 1366 x 768 | y = 368, 6 lignes | y = 112, **9 lignes** |
| 390 x 844 | y = 532, 1 ligne, **deux** défilements verticaux | y = 284, **6 lignes**, un seul défilement |
| 1440 x 900, texte x2 | non mesuré | y = 132, 6 lignes |

Une seule barre de défilement, celle de la page, vérifiée sur chaque capture (nombre de défilements verticaux qui débordent = 1), y compris après défilement : seules la barre de l'application et la rangée d'en-têtes restent en haut.

10 bis. **Comptes l'adopte le 01/11/2026 (lot L2, pilote : « même méthode que Classes »)**. Mêmes modes opt-in, aucun composant nouveau. Au bureau : la tête tient sur une rangée (les vues, et la puce « En attente » quand une décision est attendue : LISTES-2 la veut visible, elle reste donc hors du panneau, à côté des vues) ; recherche, filtre « État » et accès échus passent en panneau derrière l'icône de la tête ; l'exception d'état passe sous le nom (même pastille qu'au téléphone) et la colonne « État » quitte le bureau (le tri par état reste servi par l'adresse, `?tri=etat`, sans en-tête). **Une ligne « En attente » porte l'action qui la débloque** : « Voir la demande » ouvre Personnes › Demandes sur la bonne liste (familles ou élèves adultes), déjà cherchée sur le nom de la personne ; le nom passe en `extra`, jamais dans l'adresse (§5.9). La population est déduite du compte (un titulaire qui apprend, sans enfant, est un élève adulte) ; si la première liste ne trouve personne (un parent qui suit aussi des cours, sans enfant encore inscrit), la page essaie l'autre, une fois. Relecture du pilote (PR 126) : le nom prend la largeur qu'il faut (3 demi-parts au bureau, au lieu de 2) ; la taille de page part de 25, comme Classes (§5.3 fixe le choix 25, 50 ou 100, pas la valeur de départ ; le sélecteur reste, §3.7 interdit une taille imposée sans moyen de la changer) ; le menu de ligne est « … » partout (LISTES-1, `MenuActions.points`), Classes y passe aussi (ligne, fiche et membres) ; la sous-navigation de Personnes (7 sous-pages, donc un menu au bureau, ONGLETS-1) prend la largeur de son contenu et non toute la rangée (option (b) du pilote : `SelecteurSection(menuAuContenu: true)`, mode opt-in, relayé par `SousNavigationDomaine`) ; le regroupement des sous-pages reste une question pour le directeur ; un compte actif n'a aucune action, comme avant ce lot (aucune RPC de suspension ni d'export pour élèves et tuteurs, §6). Correction du socle trouvée par le robot à 390 : dans une ligne dense (§5 ter), le libellé de la pastille remontait dans le menu de la ligne (« En attente Actions : … ») ; le menu y est désormais un nœud à part, comme dans la ligne de table. Aucune migration. Mesures (`test/capture/listes_comptes_vues_capture_test.dart`, démonstration) :

| Vue | Avant (main du 01/11) | Après (L2) |
| :--- | :--- | :--- |
| 1440 x 900, Élèves | première ligne à y = 204, 14 lignes entières | y = 196, **12 lignes** (cartes de 56 et écart de 8, au lieu de lignes de 56 collées) |
| 1366 x 768, Élèves | y = 204, 11 lignes | y = 196, **10 lignes** |
| 390 x 844, Élèves | y = 192, 9 lignes | inchangé (§5 ter reste) |

Les cartes coûtent deux lignes visibles à 1440 et une à 1366 : c'est le prix du rendu commun, dit ici et non caché.

10 ter. **Classes à ouvrir (regroupements) l'adopte le 01/11/2026 (lot L3, pilote : même méthode)**. Mêmes modes opt-in, aucune migration. Au bureau, une ligne-carte par regroupement ; au téléphone, des cartes et non des lignes denses (chaque ligne porte cinq informations et un bouton, qui doivent pouvoir passer à la ligne : « Choisir l'enseignant » et le menu débordaient à 390).
   - **« Créer la classe » est l'action principale de la ligne** (arbitrage du pilote) : un bouton visible, seulement quand le regroupement est prêt et que le serveur dit que la personne peut créer (`peutCreerClasse`) ; une classe déjà créée qui attend son enseignant porte « Choisir l'enseignant ». Le reste va dans le menu « … » : « Voir la classe », pour une classe créée (la ligne de Classes est relue puis passée à la fiche, qui sinon relit `groupes_admin`, sans les classes en attente d'enseignant). Un regroupement sans classe n'a pas d'autre geste (le port n'en a que deux) : pas de menu vide.
   - **Colonnes**, aucune information de la carte d'avant ne disparaît : « Jours et heures » (le créneau ; dessous, la pastille « Prête », « Incomplète » ou « Enseignant à confirmer », la phrase de ce qui manque, et la phrase « non ouverte » quand la personne ne peut pas agir), « Heure de référence » (l'heure commune et son fuseau, ou le fuseau seul), « Ailleurs » (seulement quand une ligne en porte), « Public », « Langue », « Demandes » (« N demandes → M classes possibles »), « Actions ». Retirés : le sous-titre et la phrase de tri (explications permanentes, §5 quater.3), les deux titres de section (la pastille « Enseignant à confirmer » et le tri, inchangé, les remplacent), la phrase « le quota est atteint » sous chaque ligne prête (elle répétait la pastille « Prête » ; la feuille la garde).
   - **Relecture du pilote (PR 129)** : l'action de ligne a un seul style, le même pour toutes les lignes et les deux actions : le contour (le tonal plein sur chaque ligne ferait plusieurs boutons pleins à l'écran, contre K-56, `lib/CLAUDE.md`) ; une ligne incomplète dit ce qui manque en une phrase courte (« Il manque 3 demandes. », sans « quota »), l'explication longue reste dans la feuille ; le titre garde le format du regroupement (« Lundi, mercredi · 17 h ») avant comme après la création, une classe créée y ajoute son numéro R16 quand le serveur le rend, et son genre (« Garçons ») passe dans « Public ».
   - **Corrections trouvées par le robot** : la liste paginée ne se relisait pas après une création (avec le port de pages, celui de la production, la ligne restait « Prête » jusqu'au rechargement ; défaut antérieur, `pageRegroupementsAdminProvider` est maintenant invalidé) ; le bouton se fondait dans la ligne pour le lecteur d'écran (mode opt-in `ColonneDonnees.action`) ; dans une carte, le nœud du menu couvrait toute la carte (le menu y est maintenant un nœud à part, comme dans les autres rendus).
   - **Mesures** (`test/capture/listes_regroupements_capture_test.dart`, démonstration) : avant, première carte à y ≈ 337 et une seule carte visible à 1440 ; après, y = 128, **10 lignes** à 1440, **8** à 1366 ; au téléphone, 2 cartes (194 de haut) ; une seule barre de défilement partout.

10 quater. **L'Espace de traitement l'adopte le 02/11/2026 (lot L4, pilote : même méthode, sans nouvel accord)**. Mêmes modes opt-in, aucune migration, un seul texte nouveau (« Depuis »).
   - **Le maître-détail est retiré**, comme l'inspecteur de Classes (§5 quater.6) : la file de 336 et le détail de 728 défilaient chacun dans son cadre (DECISION-DEFILEMENT-2026-11-01 : une seule barre par écran). Le détail ne portait que des informations et un bouton vers l'écran de décision : les informations passent en colonnes, et **la ligne ouvre directement l'écran de décision** (la file des dossiers, le dossier par `extra` ; la file des demandes). Aucune décision ici, comme avant.
   - **Colonnes** : « Personne concernée » (le nom, sa nature dessous, la pastille de pièce quand le serveur dit « aucune » ou « hors de portée »), « Demandée par », « Pièce d'identité » (« Déposée, à vérifier » ; colonne rendue s'il y a un dossier), « Motif invoqué » (colonne rendue s'il y a une demande), « Depuis » (« Aujourd'hui · 14:05 », « Hier · 09:12 », sinon « 31 oct. · 22:32 » : les groupes de jour d'avant, dits dans la ligne). Retirés : le sous-titre (§5 quater.3), le compteur (le pied le dit), les titres de groupe (dits dans « Depuis »), la phrase « Suivi du traitement » (un texte d'attente : rien n'y est branché).
   - **Mesures** (`test/capture/listes_traitement_capture_test.dart`, démonstration) : avant, file à y ≈ 316, environ 7 lignes à côté du détail à 1440 ; après, y = 108, **11 lignes** à 1440, **9** à 1366, 7 au téléphone ; une seule barre de défilement partout.

11. **Garde automatique** : `dart run tool/verifier_revue.dart --regle=cadre-defilant` refuse une boîte de hauteur fixe (`SizedBox`, `ConstrainedBox`, `Container`, `LimitedBox` avec `height` ou `maxHeight`) autour d'un défilement vertical. Socle daté du 01/11/2026, qui ne peut que baisser : 8 sites dans 6 fichiers (`admin_shell.dart` 1, `fil_discussion.dart` 1, `observations_admin_page.dart` 1, `composer_vocal.dart` 1, `salle_seance.dart` 3, `telephone_plein_ecran.dart` 1). La règle n'est pas encore dans la CI : la ligne de `ci.yml` est donnée au directeur (zone interdite aux agents). **Exception des contenus tiers** (`HtmlElementView`, iframe) : la molette et le doigt posés sur eux ne parviennent pas à Flutter ; la garde ne pousse donc pas vers un cadre à la hauteur du contenu : un contenu tiers plus haut que l'écran devient un élément natif plein écran, dont le défilement est celui de la page (PR 120, constat du garde-cap du 01/11/2026). Le message de la règle le dit.

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
| 1 | Comptes (élèves, familles, enseignants, direction) | refondue, séparée par rôle (30/10) ; listes de bureau (L2, §5 quater.10 bis, 01/11/2026) : pleine largeur, cartes, filtres repliés, « Voir la demande » | contrat serveur paginé et recherché |
| 2 | Progression | corrigée (recherche, menu) | pagination client, tri d'en-tête, mot « cycles » à arbitrer |
| 3 | Paiements (à régulariser) | inchangée | recherche client et compteur ; décision du directeur sur toute action groupée |
| 4 | Dossiers à valider | inchangée | recherche client ; sélection groupée interdite (DEC:24) |
| 5 | Candidatures | refondue | taille de page serveur |
| 6 | Invitations | inchangée | formulaire replié, `MenuActions` pour « Révoquer » |
| 7 | Espace de traitement | listes de bureau (L4, §5 quater.10 quater, 02/11/2026) : la liste est la page, la ligne ouvre l'écran de décision, maître-détail retiré | recherche client |
| 8 | Classes | refondue (L1, §5 quater, 01/11/2026) : pleine largeur, cartes, filtres repliés, vue Ouvertes, fiche-page | 27 autres listes par lots de 4 à 6 |
| 9 | Regroupements | listes de bureau (L3, §5 quater.10 ter, 01/11/2026) : pleine largeur, lignes-cartes, filtres repliés, « Créer la classe » en action de ligne, « Voir la classe » en menu | rien d'urgent |
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
| Listes de bureau (§5 quater, Classes seulement) et garde `cadre-defilant` | oui | oui | oui (tests Flutter, captures et mesures, scénario SQL) | non | non |
| Listes de bureau, Comptes (§5 quater.10 bis) et « Voir la demande » | oui | oui | oui (tests Flutter, captures et mesures, parcours du robot sur la pile locale) | non | non |
| Listes de bureau, Classes à ouvrir (§5 quater.10 ter) | oui | oui | oui (tests Flutter, captures et mesures, parcours du robot sur la pile locale) | non | non |
| Listes de bureau, Espace de traitement (§5 quater.10 quater) | oui | oui | oui (tests Flutter, captures et mesures, parcours du robot sur la pile locale) | non | non |
| Autres listes (menus migrés, recherche de Progression) | oui | oui | oui | non | non |
| Listes non traitées (§7, « inchangée ») | oui | non | non | non | non |

Tests : tout vert sur les dossiers touchés ; la suite complète lancée avant les deux commits de correction de la fusion comptait 13 échecs, dont 8 déjà présents sur la base `1f6e0351` ; elle n'a pas été relancée en entier après. Les appels du lot (`apercu_lot_candidats`, `executer_lot_candidats`) ne sont pas testés contre un vrai serveur. Rien n'est testé sur staging ni déployé.

## 9. Preuve machine

- `dart run tool/verifier_revue.dart --regle=case-recomposee` : interdit un `Checkbox` Material dans `lib/features/` (exceptions datées).
- Tests de densité et de contexte : `test/features/admin_candidatures/candidatures_liste_test.dart` (dix lignes entières, état gardé au retour de la fiche), `test/features/comptes_liste_test.dart`, `test/core/widgets/data_collection_listes_test.dart`, `composants_listes_test.dart`, `menu_commun_test.dart`.
- Captures : harnais `test/capture` (`listes1_*`, `listes2_*`, `listes3_*`, `listes4_*`).
