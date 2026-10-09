<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
## Verdict : SUPERPOS-1 (reprise) acceptée avec réserves

J'ai relu la branche `corrections/c2-superpos` au commit `134a2eb4`, dans un worktree détaché jetable, retiré depuis. Je n'ai rien poussé. J'ai lu les 8 commits de reprise, par rapport au commit `2b42d97d` qui avait été refusé.

Les 6 points du refus précédent sont corrigés. Chaque correction a son test, et ce test échoue bien quand on annule la correction, sauf un (réserve 1). La suite complète passe. Il ne reste **aucun défaut majeur prouvé**, seulement 5 réserves mineures.

### 1. Contrôles

**Commandes du dépôt**
- `dart analyze --fatal-infos` : aucun problème.
- `dart run tool/verifier_revue.dart` : 1546 violations, comme annoncé (1548 avant la reprise).
- `dart run tool/verifier_jetons.dart` : 37 violations, donc sous la borne de 39. La commande sort en code 1 à cause de ces 37 anciennes violations. Le code ajouté par la reprise ne contient aucun littéral de couleur, de marge ou de taille.

**Suite de tests** (`--concurrency=2`, sur `test/core`, `test/features`, `test/widgets`, `test/accessibilite`, `test/router`, `test/foyer`)
- +4588 réussis, ~2148 ignorés, **0 échec** (« All tests passed! »).
- Les 7 fichiers de tests nouveaux ou étendus passent : +64.

### 2. Mutations : on annule chaque correction et on relance ses tests

| # | Correction annulée | Résultat |
|---|---|---|
| M1 | `EnteteCompact.actif` renvoie toujours faux | 5 échecs (`entete_compact_test`, `echanges_compact_superpos_test`, en LTR et RTL) |
| M2 | `placeReservee` ignoré (commandes du Coran) | 3 échecs sur 4. Le 4e vérifie que MA-CMD-1 reste au toucher : c'est voulu |
| M3 | Hauteur minimale de la liste fixée à 96 | **le test passe encore** (réserve 1) |
| M4 | `_montrerSaisie` retiré | 2 échecs |
| M5 | `nomsComposesEntiers` ignoré | 1 échec (« Al- / Badr ») |
| M6 | Ancien contexte du fil remis (qui répétait la classe et la date) | 2 échecs |
| M7 | Ancienne feuille de demande des réglages, sans défilement | 2 échecs (standard et guidée) |
| M8 | Anciennes bornes d'aide (invitation, profil élève) | 6 échecs (fr et ar) |
| M9 | Ancienne aide du champ vide de `ZoneSaisie` | 3 échecs (LTR, RTL, clavier) |
| M10 | Ancienne page de saisie du code | 0 échec : cohérent avec la fiche, qui dit cette aide déjà entière |

### 3. Captures ouvertes

- **En-tête « Dossiers à valider » à 320 ×2** :
  - avant : titre sur trois lignes à côté du disque retour, sous-titre étroit, l'en-tête occupait plus de la moitié de l'écran ;
  - après : le titre se lit « Dossiers à / valider », le sous-titre prend toute la largeur, l'en-tête fait environ 240 px.
  - Le menu qui répète le titre juste en dessous relève de la voie FILTRES-1, exclue de ce lot.
- **Fil à l'arrivée à 320 ×2, en clair et en Interface guidée** :
  - avant, en guidée : le titre « Classe Al- / Badr » était coupé au trait d'union, « aut / omatiquement » était coupé dans le mot, la saisie était hors de l'écran ;
  - après : on voit le dernier message (au moins 200 px), le champ entier avec son aide sans mot coupé, et la raison écrite sous le champ ;
  - pas de bouton grisé : le bouton d'envoi est absent tant que le champ est vide, et sa place est gardée.
- **Lecteur du Coran en Mode Accessibilité avec lecteur d'écran, 390 ×2** :
  - avant : les commandes couvraient la ligne 1:2 du Mushaf ;
  - après : elles sont sous le cadre, dans le flux, et ne recouvrent plus rien ;
  - le rendu des versets n'est pas modifié, seul le cadre raccourcit.
- **Invitation du conjoint à 320 ×2** :
  - l'erreur du courriel est entière, « e‑mail » ne se coupe plus (le trait d'union insécable U+2011 s'affiche bien) ;
  - l'étiquette flottante sur le filet du champ d'une ligne vient du thème : elle est relayée, car ce lot n'a pas le droit de toucher au thème.
- **Feuille de demande des réglages de l'enfant, en guidée à 320 ×2** : elle défile et le bouton d'envoi s'atteint. Le « ? » reste orphelin sur sa ligne (réserve 3).

### 4. Relecture du code et effets sur les autres usages

**`EntetePage` et `EnteteCompact`**
- L'échelle du titre ne descend jamais sous 1 ni sous la taille du thème.
- En hauteur seule, on trouve 24 ≤ 22+2 : le titre n'est donc pas réduit sur un écran bas en texte normal.
- Le clavier ne compte pas, car le calcul utilise `MediaQuery.sizeOf` et pas les marges du clavier.
- Hors mode compact, la forme d'origine est gardée.
- Tous les autres écrans qui utilisent ces composants passent dans la suite complète.

**`TexteSansCoupure.nomsComposesEntiers`**
- C'est limité au titre en mode compact.
- Le lecteur d'écran lit le texte d'origine (`semanticsLabel`).
- La mesure du mot le plus long découpe sur les espaces seulement. « Al-Badr » est donc mesuré en entier et l'échelle reste cohérente.

**`ZoneSaisie`, aide du champ vide**
- Le widget `hint` reprend `inputDecorationTheme.hintStyle` du thème (`inkFaint` sur `bodyLarge`).
- L'aide garde donc l'aspect d'une invite et ne se lit pas comme une valeur déjà saisie.

**`CommandesMasquables`**
- Une `GlobalKey` conserve l'état du contenu quand les commandes basculent de la superposition au flux.
- Le comportement au toucher (MA-CMD-1) est inchangé, et un test le vérifie.

**Interdits**
- Rien n'est touché dans `main`, `supabase/`, `.github/`, `pubspec.yaml`, le thème, `page_shell.dart`, la rangée de filtres, ni le rendu du Coran.
- Les seuls libellés modifiés sont déclarés dans `tool/libelles_sources.json`.

### 5. Relais aux voies exclues

La fiche consigne chaque défaut constaté et l'écran concerné :
- **Messages (voie COM)** : rangée de saisie de `FilDiscussion` avec le bouton à côté du champ, non centré, grisé quand le champ est vide, et débordement à 320 ×2 clavier ouvert.
- **Comptable** : étiquette flottante en ellipse, `nouvelle_obligation_page.dart:462-490`.
- **Finance** : aucun élément flottant ni champ multiligne, conforme.
- **Salle** : vignette de soi posée sur la dernière tuile, nom en ellipse, `salle_seance` sans `placeReservee`.
- **Coquille** : barre du bas qui coupe les mots en Interface guidée.
- **Thème** : étiquette flottante des champs d'une ligne.
- **`PageShell`** : titre simple qui ne passe pas par le mode compact.

Les arbitrages portent la mention « décidé par délégation le 05/10 ». Le statut est écrit honnêtement : présent dans le code et testé localement, ni testé sur staging, ni déployé.

### 6. Réserves, toutes mineures et sans effet sur la fusion

1. Aucun test ne protège la hauteur minimale de la liste du fil (mutation M3 qui passe).
2. Le « point d'attention unique » n'a pas de test dédié.
3. Le « ? » est orphelin dans le titre du motif de la feuille des réglages en guidée à 320 ×2 : il manque une espace insécable.
4. Les mots coupés de la barre du bas en guidée existaient déjà ; ils sont relayés à la voie COUPE-MOTS.
5. À l'arrivée dans le fil à 320 ×2, le titre est passé au-dessus de l'écran. C'est une limite assumée et écrite dans la fiche.

**Décision : ACCEPTEE_AVEC_RESERVES.** Ce lot peut être fusionné quand la CI et les contrôles du dépôt le permettront. Toute fusion dans `main` est une mise en production.
