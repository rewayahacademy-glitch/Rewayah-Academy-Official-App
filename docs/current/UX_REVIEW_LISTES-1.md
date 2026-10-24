# LISTES-1 : densité, actions et sélection des listes de gestion (revue UX, DESIGN-GOV §4.2)

Lot LISTES-1 (demande du directeur du 23/10/2026, règle `DECISION-LISTES-2026-10-23.md`). La disposition de la maquette du directeur est une `PROPOSITION` de composition : elle est confrontée ici aux règles écrites, sans reprendre ses couleurs, polices, rayons ni espacements (K-63).

Statut : spécifié, présent dans le code, testé localement. Ni staging, ni déploiement.

## Sources consultées et date

Consultation le 23/10/2026.

| Source | Accès | Usage |
| :--- | :--- | :--- |
| `docs/current/03_DESIGN_SYSTEM_ET_UX.md`, `DESIGN-GOV-2026-09-26.md` (§1, §4.2, §4.3, §4 bis.3, §4 bis.8), `lib/CLAUDE.md` | lus | cibles de 48, autorité, pouvoir des standards UX sur la densité, composants à ne pas dupliquer |
| `docs/archive/2026-09-pre-remise-a-plat/design/00-bible-frontend-v2.md` §38-39 et `05-regles-responsive.md` §4 | lus, archive : **contexte, pas une règle** | tableau dense, actions contextuelles, tri, pagination, état jamais par la couleur seule |
| Flutter 3.47 : `PopupMenuButton`, `Tooltip`, `PopupMenuThemeData`, `TooltipThemeData` (SDK installé) | lus localement | cause de l'infobulle grise : `PopupMenuButton` pose un `Tooltip` par défaut sur son déclencheur |
| Material Design 3 (menus, listes de données), Apple HIG (menus), WCAG 2.2 AA (2.5.8 taille de cible, 1.4.1 couleur, 2.4.7 focus visible, 1.4.10 reflow), Nielsen Norman Group (tableaux de données) | **non relus ce jour** (réseau non utilisé dans ce lot) : rien n'en est cité ; les critères WCAG sont repris des règles déjà écrites dans `03` | aucun |

Une relecture des pages web reste à faire ; aucune conclusion ci-dessous n'en dépend seule.

## Propositions contrôlées

### 1. Lignes de 48 à 56 px, première ligne haute, environ 10 lignes entières

- **Règle utile.** `03` et `DESIGN-GOV` : cibles d'au moins 48 dp, sans exemption pointeur. §4.3 : les standards UX améliorent la densité et la place des actions.
- **Conséquence.** La maquette descend à 36-40 px de commande ; refusé. L'économie vient des espacements (marge de ligne 12+12 retirée, rangées regroupées, panneau « À traiter » réduit à une ligne). Une ligne de texte tient dans 48, une ligne avec case ou menu dans 56 (la cible du mode).
- **Conclusion : conforme.** Mesuré à 1440 x 900 avec la coque : Candidatures, première ligne à y = 288 (684 avant), 10 lignes entières ; Comptes, 10 lignes sur Élèves et Tuteurs.
- **Modification.** `DataCollection` (densité, colonne d'actions hors de la cible de la ligne), `candidatures_page.dart`, `comptes_page.dart`.

### 2. Menu d'actions sans infobulle, surface opaque des jetons

- **Règle utile.** WCAG 2.4.7 (focus visible) et 1.4.1 (pas de couleur seule) repris de `03` ; un seul système de menus (`DESIGN-GOV` §4 bis.3 : ne pas dupliquer).
- **Conséquence.** Avant : infobulle Material par défaut (gris translucide, attente nulle) et menu sans thème (contraste 1,015:1). Après : aucune infobulle sur le déclencheur, libellé gardé pour le lecteur d'écran, surface des dialogues, filet, ombre, largeur de 224 à 320, focus clavier visible, destructif en dernier.
- **Conclusion : conforme.** Le survol à la souris n'est pas simulable sous `flutter test` ; il est prouvé avec une pression forcée.
- **Modification.** `AppTheme.pour` (`tooltipTheme`, `popupMenuTheme`), `MenuActions`, `MenuFiltre`, `menu_commun.dart`.

### 3. Sélection multiple seulement avec une opération groupée réelle

- **Règle utile.** `DESIGN-GOV` §1 : aucune donnée absente du contrat n'est inventée ; K-56 : un seul bouton plein par écran.
- **Conséquence.** Candidatures : le lot serveur existe (`apercu_lot_candidats`, `executer_lot_candidats`, 1 à 200), donc cases et barre compacte. Comptes : aucune RPC de lot, donc **pas de case** (un faux contrôle). La sélection de page n'est pas « tous les résultats ».
- **Conclusion : conforme.** La barre ne rend qu'un `ActionPrincipale` plein ; les autres opérations sont discrètes.
- **Modification.** `CaseACocher`, `BarreSelection.compacte`, `lot_candidatures.dart`.

### 4. Table au bureau (1200 px et plus), cartes ailleurs

- **Règle utile.** `data_collection.dart` et archive 05 § 4 : jamais de tableau rétréci.
- **Conclusion : conforme.** Règle conservée. Entre 1024 et 1199 px, les cartes restent ; à rediscuter si les portables étroits sont fréquents.
- **Modification.** Aucune.

### 5. Retour de la fiche sans perdre le contexte

- **Règle utile.** `03` : les filtres à côté du contenu ; mission : retour sans perdre recherche, filtres, tri, position.
- **Conclusion : conforme.** La liste reste empilée (`push`) ; test d'état gardé au retour.
- **Modification.** `candidatures_page.dart`, adresse de Comptes (`role`, `etat`, `filtre`, `tri`) ; le texte cherché n'y est pas.

## Relecture adverse du 23/10/2026 (lot 6)

Deux relectures (code, captures) ont donné 5 constats à corriger du côté code et 26 du côté visuel. Corrigés : menu (filet franc, ombre en sombre), pastille neutre, barre de sélection flottante et sur une ligne, cartes de téléphone, tri en menu, pied commun, plage arabe, puces de filtre, texte cherché hors de l'adresse, tri Comptes par libellé. Écartés avec preuve ou renvoyés au contrat serveur : voir le compte rendu du lot.

## Ce qui reste ouvert

Taille de page de Candidatures fixée à 50 par le serveur ; tri croissant de la colonne Date ; alertes non servies ; contrat serveur pour élèves et tuteurs (§6 de la décision). 8 cases Material non migrées, bornées par la règle `case-recomposee`.
