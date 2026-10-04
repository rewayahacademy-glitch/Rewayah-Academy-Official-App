## Revue adverse : DASH-EA-PROD-b (corrections/c2-ea-prod-b, f464da60)

### Verdict
**ACCEPTEE_AVEC_RESERVES.**
- Le seul défaut majeur, celui de la contre-revue, est levé. Je l'ai prouvé par la même mutation que la contre-revue.
- Les mineurs corrigés le sont, et chaque correction a un test discriminant.
- Restent des mineurs : deux besoins hors périmètre déjà consignés, un test faible et un écart de chiffre dans le compte rendu.
- Je n'ai trouvé aucune régression et aucun nouveau mot coupé.

Statuts :
- **présent dans le code** : oui ;
- **testé localement** : oui ;
- **testé sur staging** : non ;
- **déployé** : non ;
- **serveur** : aucun branchement.

### Contexte
- Lot : origin/corrections/c2-ea-prod..origin/corrections/c2-ea-prod-b, deux commits (8cd51243, f464da60).
- Rapport de référence : docs/revues/REVUE_DASH-EA-PROD-R.md (origin/revues/2026-10-04-b061fd81).
- Fichiers touchés :
  - accueil_adulte_page.dart (capacité, nouveau widget `EnteteVoirTout`, hauteurs du squelette) ;
  - historique_seances_adulte_page.dart (commentaire) ;
  - DASH_STRATEGIE.md (registre §5 bis, DASH-BIB-TITRE) ;
  - un nouveau test, accueil_adulte_revue_test.dart ;
  - le renommage du test D9 ;
  - les captures.
- Rien n'est touché dans supabase/, .github/, pubspec, le thème ou le Coran.
- J'ai travaillé dans un worktree détaché rv-EA-PROD, retiré à la fin, sans rien pousser.

### Commandes et résultats
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_jetons` : 39 sur la base comme sur la tête.
- `verifier_revue` : 1608 sur la base comme sur la tête, liste identique. Le rédacteur annonçait « 1610 vers 1608 » ; je n'ai pas reproduit ce 1610 de base. Il n'y a pas de régression.
- `flutter test --concurrency=2 test/features/accueil_adulte/` : +62, tous verts (58 d'avant et 4 nouveaux).
- `flutter test --concurrency=2` sur test/router, adulte_recette, foyer, demo et ma_classe_adulte : +895, 688 sautés, 0 échec.

### Défaut majeur de la contre-revue : réveil du routeur
J'ai refait la mutation d'origine : suppression des trois lignes `ref.listen<bool>(capaciteAccueilAdulteProvider, ...)` dans app_router.dart:149-151.
- Résultat : +61 -1, avec « Expected: '/eleve/adulte' Actual: '/eleve' » sur le nouveau test.
- Ce test passe par le vrai routeur. La lecture est tenue par un Completer, puis complétée sans nouvelle navigation.
- Sur la tête, le test est vert. **Le défaut est levé.**

### Mineurs corrigés, avec leurs contre-épreuves
| Défaut | Mutation | Résultat |
|---|---|---|
| Mineur 1, partie locale : capacité vraie après une relecture en échec | retour à `hasValue` seul | échec, « Expected: false Actual: true » |
| « Voir tout » placés différemment sur mobile | retour à `SectionHeader` | échec, « Expected 1236 ±1 Actual 1298 » |
| Mineur 2 : hauteurs du squelette en dur | hauteur + 20 | échec |
| Mineur 3 : test D9 | renommé « non-régression », avec un commentaire | conforme |
| Registre EA-BR absent | §5 bis ajouté (DASH-BR-01, DASH-BR-02, à reporter dans EA-BR.md) | consigné, sans numéro EA-BR inventé |

Le nouveau widget `EnteteVoirTout` reprend exactement la logique de `BlocBibliotheque` :
- même seuil `AppGabarit.seuilTexteColonne` ;
- en ligne, le titre en flex 2 et le lien en flex 1 ;
- empilé au-dessus du seuil, le lien sous le titre au bord de début ;
- pas de lien sans destination (D9).

Il n'utilise que des jetons et ne grise aucun bouton. Le titre n'est pas réduit par FittedBox : il passe par `TexteSansCoupure`.

### Captures
Captures livrées que j'ai ouvertes : contenu_390_clair, contenu_320x2_clair, contenu_1440_clair, contenu_390_rtl et chargement_320x2_clair.
- Les deux « Voir tout » sont alignés : sur la ligne du titre à 390 et 1440, sous le titre à 320 x2.
- Le squelette Bento est sans donnée.

J'ai fait mes propres captures sur la tête, avec le vrai routeur. Aucune exception n'a été levée.
- **320 x1** : chaque « Voir tout » passe sur deux lignes (« Voir / tout »), entre les mots, sans coupure. Les deux liens restent cohérents entre eux, comme dans `BlocBibliotheque` existant.
- **320 x1,3** : même rendu, aucun mot coupé.
- **320 x1,45 sombre RTL** : miroir correct, aucun mot coupé.
- **320 x2 sombre RTL** : empilé, lien au bord de début (à droite), aucun mot coupé.
- **600 x2** : empilé, cohérent.
- **1440 sombre RTL** : deux colonnes, chaque lien sur la ligne de son titre au bord de fin.

En RTL forcé sur la locale française, l'ordre des nombres est inversé (par exemple « à 18:45 18:00 »). Ces textes viennent de composants hors du lot.

### Défauts restants (mineurs)
1. La capacité doit être rendue par le serveur avec la session. C'est un besoin serveur interdit ici, consigné comme DASH-BR-02.
2. Le titre de `BlocBibliotheque` est réduit par FittedBox à 320 x2. Le défaut est hors périmètre, existait dans la base, et il est consigné comme DASH-BIB-TITRE.
3. Le test du squelette recalcule la formule du code : sa valeur de garde est faible.
4. Compte rendu : le « 1610 » de base pour `verifier_revue` n'est pas reproduit (1608 de part et d'autre).

### Pour lever les réserves
- Brancher DASH-BR-01 et DASH-BR-02 après BR-1.
- Traiter DASH-BIB-TITRE dans une étape dédiée.
- Si l'on veut une garde plus forte sur le squelette, comparer sa hauteur rendue à celle d'une tuile réelle, plutôt que de recopier la formule.