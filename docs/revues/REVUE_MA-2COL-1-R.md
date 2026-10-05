# Revue adverse MA-2COL-1 : deux colonnes sur l'Accueil du Mode Accessibilité

**Verdict : ACCEPTEE_AVEC_RESERVES.** La demande est remplie, chaque garde est prouvée par une mutation, et je n'ai trouvé aucune régression. Il reste trois défauts mineurs : un dans le lot, deux antérieurs.

Branche relue : `origin/corrections/c2-ma-2col`, commit `a12cd96a`, dans un worktree jetable détaché. Le worktree est retiré, je n'ai rien poussé.

Les commandes ont été lancées sur ce commit : tests locaux, analyse et vérificateurs. Rien n'est testé sur staging ni déployé.

## 1. La spec
- `docs/current/DASH_STRATEGIE.md:374`, fiche ELV-02-MA : « une colonne ; deux à partir de 840 / facteur de texte ; pas de Bento ».
- Les revues DASH-MA-PROD-R (§1 et §4) et DASH-MA-PROD-b-R (§3) avaient laissé en réserve le retrait des deux colonnes.
- La décision déléguée fait prévaloir la spec, donc le rétablissement est fondé.

## 2. Le code, comparé à MA-3 (`91a6e6d9`)
- On retrouve la même constante `seuilDeuxColonnesAccueil = 840` et la même condition `contraintes.maxWidth / facteur >= 840`, avec `facteur = MediaQuery.textScalerOf(context).scale(1)`.
- On retrouve aussi la même clé `ma3-deux-colonnes` et la même rangée : `Expanded(tâches)`, puis `AppSpacing.xxl`, puis `Expanded(Coran et aide)`.
- La salutation et la séance gardent toute la largeur.
- Une `Row` suit la direction du texte : l'ordre de lecture et de focus reste « tâches, Coran, aide », en LTR comme en RTL.
- Seuls des jetons sont utilisés : AppSpacing, Ecart, Skeleton.

Les corrections de DASH-MA-PROD-b sont conservées. Hors ligne, `onReessayer: () => ref.invalidate(horsLigneProvider)` est toujours là, et aucun bouton n'est grisé.

## 3. Le nouveau paramètre `BlocAsynchrone.piedEchec`
- Il est optionnel et vaut `null` par défaut.
- À `null`, la méthode `build` renvoie `enfant` exactement comme avant : les autres appelants ne changent pas de comportement.
- Il ne s'affiche que dans les états `echec` et `indisponible`, ce qui couvre aussi la tentative perdue.

## 4. Mutations (j'ai annulé chaque correction une à une, puis relancé les tests)

| Mutation | Tests en échec |
|---|---|
| M1 : `deuxColonnes = false` | 9 sur 9 du nouveau fichier |
| M2 : seuil sans le facteur de texte | « seuil divisé par le facteur » |
| M3 : `piedEchec: null` sur l'Accueil | « vide/erreur/indisponible » et « tentative perdue » |
| M4 : `>` au lieu de `>=` | « 839 / 840 au pixel près » |
| M5 : `Réessayer` hors ligne mis à null | le cas hors ligne du nouveau fichier et celui d'accueil_ma_prod (DASH-MA-PROD-b) |
| M6 : `piedEchec` limité à l'échec, sans l'indisponible | composants_etats (piedEchec) et le cas indisponible |
| M7 : le pied retiré de l'état vide | « vide/erreur/indisponible » |

Toutes les gardes sont donc réellement testées.

## 5. Captures
J'ai ouvert neuf des onze captures de `docs/current/captures/MA-2COL-1/`. Les deux que je n'ai pas ouvertes sont `ma_2col_contenu_390_ltr_clair.png` et `ma_2col_erreur_1440_rtl_clair.png` ; le cas 390 est couvert par le test « 390 : une colonne ».

| Capture | Ce que j'ai vu |
|---|---|
| 1440 LTR, clair et sombre | Deux colonnes : tâches à gauche, Coran puis aide à droite |
| 1440 RTL clair | Rangée miroir correcte |
| 1440 x2 | Une colonne |
| 320 x2, LTR clair et RTL sombre | Une colonne, aucun mot coupé ; « 3 h / 28 » sur deux lignes (antérieur) |
| Chargement 1440 | Squelette en deux colonnes, le Coran et l'aide déjà réels |
| Erreur 1440 | Une colonne, le Coran et l'aide sous l'état |
| Vide 1440 | Une colonne, le Coran et l'aide sous l'état |
| Hors ligne 1440 | Deux colonnes, bandeau, « Réessayer » actif |

L'Interface guidée est couverte : les tests montent `InterfaceMode.enfant` sur le vrai routeur `/eleve`.

## 6. Contrôles
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_jetons` : 39, identique au commit parent.
- `verifier_revue` : 1606, identique au commit parent.
- Tests ciblés (nouveau fichier, accueil_ma3, accueil_ma_prod, composants_etats, ma11) : 124 passés.
- `flutter test --concurrency=2 test/widgets test/core test/router test/features` : 3994 passés, 2068 sautés, 0 échec.

## 7. Réserves (mineures)
1. **Dans le lot.** Quand la largeur franchit le seuil, le `BlocAsynchrone` change de parent : en deux colonnes il est rendu seul, en une colonne il est dans une `Column`. Son State est alors recréé, ce qui remet à zéro le compteur de réessais et les minuteries. Les données ne sont pas relues et rien n'est visible à l'écran. Correctif possible : garder la même structure dans les deux cas, ou poser une GlobalKey sur le bloc.
2. **Antérieure.** « Cours dans 3 h / 28 » passe sur deux lignes à 320 x2, entre deux mots. Cela vient de tc_horloge et relève d'un lot dédié, comme déjà noté en réserve.
3. **Antérieure.** Le RTL est testé avec un texte français, pas avec la locale arabe, donc la ponctuation et les unités sont déplacées par le bidi. C'est la même méthode que dans les lots déjà acceptés.

Le compte rendu du rédacteur est exact sur tous les points que j'ai vérifiés. Aucun besoin serveur.
