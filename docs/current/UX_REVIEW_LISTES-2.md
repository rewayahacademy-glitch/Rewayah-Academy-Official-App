# Revue UX LISTES-2 : la tête défile avec la liste (Comptes d'abord)

**Date : 30/10/2026.** Preuve exigée par `DESIGN-GOV-2026-09-26.md` §4.2 avant de coder une disposition « proposition ». Source de la demande : le directeur, 30/10/2026, sur les captures de Comptes au téléphone et au bureau : « tout ce qui n'est pas important ne doit pas apparaître en permanence à l'écran » ; « le header est fixe, donc tout ce qu'on fait défiler passe dessous ; imagine avec 500 ou 1000 élèves » ; « le titre Élèves (28) prend une rangée entière, la recherche aussi, les filtres aussi ». Décisions du pilote du 30/10 : ONGLETS-1 respecté sans exception ; mode opt-in des composants partagés, adopté par Comptes seulement ; l'Interface guidée garde 72 et 80 px.

## Constat (avant)

| Vue | Première ligne | Lignes visibles | Ce qui prend la place |
| :--- | :-: | :-: | :--- |
| Production, téléphone 390 x 844 (capture du directeur) | sous le pli de 4 rangées | 5 cartes de 220 px | barre, titre « Comptes », liste déroulante « Comptes », paragraphe d'aide de 4 lignes, rangée Tous, Actif, Rôle |
| Branche du 30/10, 390 x 844 | y ≈ 395 | 2 cartes | titre, « Comptes » déroulant, « Élèves (28) » déroulant, recherche ouverte, « 28 comptes » |
| Branche du 30/10, 1366 x 768 | y ≈ 324 | 8 | titre, « Comptes » déroulant, vues et recherche, « 28 comptes », en-têtes |

« Comptes » est dit trois fois (barre, titre, sous-navigation) ; tout ce qui précède la liste reste fixe.

## Règles confrontées

### 1. Rien de fixe au-dessus de la liste, sauf la barre de l'application

- **Règle.** Material 3, « Top app bar », comportement au défilement (m3.material.io/components/top-app-bar/guidelines, consulté le 30/10/2026) : sur une liste longue, ce qui surmonte le contenu se replie ou défile ; Apple HIG, « Scroll views » et « Navigation bars » (titre large qui se replie au défilement) ; Nielsen, « esthétique et design minimaliste » ; `DECISION-LISTES` §1 et §3.1.
- **Conclusion : à corriger.** Le titre, le choix de vue, la recherche et la synthèse défilent avec les lignes. Au bureau, seule la rangée d'en-têtes de colonnes reste collée (sans elle, une colonne ne se lit plus : `DataCollection`, règle déjà en place). Au téléphone, aucune barre collée en plus ; le pied de liste vient après la dernière ligne.
- **Modification.** `PageShell(teteAvecLaListe: true)` confie sa tête à la liste (mécanisme existant `TetePageConfiee`, celui du fil de discussion) ; `DataCollection(prendTeteDePage: true, tete: ...)` la pose en premier élément de son défilement. Sans liste (chargement, vide, échec), la tête défile avec le corps.

### 2. Un seul titre

- **Règle.** HIER-1 (`lib/CLAUDE.md`, un titre d'écran) ; Nielsen, « reconnaissance plutôt que rappel » : une même information ne se répète pas.
- **Conclusion : à corriger.** Quand la page a une sous-navigation, la liste déroulante de la sous-navigation **devient** le titre (« Comptes ▾ »), sur la rangée du retour et des actions de la coquille. Le titre reste annoncé comme en-tête au lecteur d'écran.
- **Modification.** `PageShell(teteAvecLaListe: true)` avec `entete` : une seule rangée.

### 3. Une seule rangée de commandes

- **Règle.** ONGLETS-1 (`SelecteurSection` : segmenté si tout tient, sinon menu ; jamais une rangée de sections qui défile) ; FILTRES-1 (`RangeeFiltres` pour les filtres) ; Fitts (cibles de 48) ; Baymard, recherche à la demande sur mobile quand la liste a ses propres filtres.
- **Conclusion : à corriger, sans exception à ONGLETS-1.** Téléphone : [« Élèves 28 ▾ » (menu des vues) | État | accès échus s'il y en a | loupe]. La loupe ouvre le champ de recherche sous la rangée ; il reste ouvert tant qu'un texte est cherché. Bureau : vues en segmenté si elles tiennent, État, recherche à droite, sur la même rangée.
- **Modification.** `comptes_page.dart`.

### 4. Pas de compteur redondant

- **Règle.** Nielsen, minimalisme ; `DECISION-LISTES` §3.3 (compteur près de la liste).
- **Conclusion.** « 28 comptes » est retiré : le nombre est dans le choix de vue et le pied dit « 1-28 sur 28 ». La phrase « Une personne attend une décision » reste, car elle appelle un geste, mais seulement quand il y a une attente.

### 5. Lignes denses au téléphone, l'exception seulement

- **Règle.** Material 3, « Lists » (deux lignes de texte, 72 px en deux lignes, m3.material.io/components/lists/specs, consulté le 30/10/2026) ; WCAG 2.2, 2.5.8 (cible 24 au moins, 48 gardé) ; « un état ne se signale jamais par la couleur seule » (texte dans la puce) ; K-55 (une seule grande carte à lignes fines pour des contenus liés).
- **Conclusion : à corriger.** `DataCollection(densiteTelephone: true)` : sous le seuil du tableau, une ligne par compte (nom, puis matricule · classe · tuteur), 64 px au moins (72 en Interface guidée), filets fins dans un seul cadre. Un état « Actif » ne s'affiche plus ; seule l'exception (en attente, suspendu, provisoire, sans décision) a sa puce, au téléphone comme au bureau. **Amende `DECISION-LISTES` §3** (cartes sous 1200 px) pour les listes qui adoptent le mode, par décision du directeur du 30/10.

### 6. Portée

- **Règle.** `DESIGN-GOV` §4 bis.8 : aucune étape faite n'est rouverte sans demande nommée.
- **Conclusion.** Mode opt-in : seules les pages qui passent `teteAvecLaListe` et `prendTeteDePage` changent. Comptes l'adopte ; Candidatures sera la suivante, lot par lot.

## Mesures attendues

| Vue | Première ligne | Lignes visibles |
| :--- | :-: | :-: |
| 390 x 844 | 200 px au plus | 8 au moins |
| 1440 x 900 (Élèves, Familles) | 260 au plus | 12 entières au moins |
| 1440 x 900 (Enseignants, menu de 56) | 260 au plus | environ 10 |
| 1366 x 768 | mesurée et rendue | mesurée et rendue |

## Mesures obtenues (30/10/2026, vraies polices, `test/capture/listes_comptes_vues_capture_test.dart`)

| Vue | Première ligne | Lignes entières visibles | Cible |
| :--- | :-: | :-: | :-: |
| 390 x 844, Élèves, Familles, Enseignants | y = 192 | 10 | y ≤ 200, 8 au moins : atteinte |
| 1440 x 900, Élèves et Familles | y = 204 | 14 | y ≤ 260, 12 au moins : atteinte |
| 1440 x 900, Enseignants (menu de 56) | y = 204 | 12 | environ 10 : atteinte |
| 1366 x 768, Élèves et Familles | y = 204 | 11 | mesurée |
| 1366 x 768, Enseignants | y = 204 | 10 | mesurée |

Captures : `docs/captures/2026-10-31-listes/` (clair, sombre, arabe ; `comptes_apres_defilement_390.png` et `comptes_apres_defilement_1440.png` prouvent qu'il ne reste que la barre de l'application et, au bureau, la rangée d'en-têtes).

## Écarts retenus

- Au bureau, quand la rangée porte aussi des filtres (Familles : « En attente », « État »), les quatre vues ne tiennent plus en segmenté et passent en menu (ONGLETS-1, automatique).
- Au téléphone, la puce « En attente » n'est pas dans la rangée (place) : la ligne en attente porte sa pastille, passe en tête, et le menu « État » propose « En attente ».
- La ligne secondaire dense se termine par des points de suspension quand elle ne tient pas ; le texte entier reste dans la sémantique et au bureau.
