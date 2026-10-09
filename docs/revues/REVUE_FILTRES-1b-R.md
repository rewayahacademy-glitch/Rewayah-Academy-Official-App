<!-- verdict : REFUSEE -->
<!-- verdict : REFUSEE -->
## FILTRES-1b : relecture adverse de corrections/c2-filtres-b (c2763700)

**Verdict : REFUSÉE.** Le lot répond bien à presque toute la demande, mais il introduit une régression majeure, et le compte rendu affirme le contraire. Dans Observations (admin), à partir de 700 px, la personne qu'on vient de retenir (tuteur ou élève) sort de la vue, au bout de l'unique rangée. Avant le lot, elle était entièrement visible. Le correctif est court (voir plus bas).

Statut : présent dans le code et testé localement. Ni staging, ni déploiement. Je n'ai rien poussé. Les worktrees `rv-FILTRES-1b-11`, `-base` (5a52ff30) et `-mut` sont retirés.

### Ce qui a été vérifié

**Périmètre et forme**
- Le diff 5a52ff30..c2763700 ne touche aucun fichier interdit : `supabase/`, `.github/`, `pubspec.yaml`, thème, Coran, `page_shell.dart`, `admin_shell.dart`, i18n et dart_define sont intacts.
- Les 4 commits sont en français et finissent exactement par les deux lignes demandées. Aucun identifiant de modèle n'apparaît ailleurs.

**Outils**
- `dart analyze --fatal-infos` : 0 problème.
- `verifier_revue` : 1533, égal à la base mesurée sur 5a52ff30, règle par règle.
- `verifier_jetons` : 37, égal à la base.
- `--regle=wrap-filtres` : 0 sur la branche.
  - Qualité remise en `Wrap` : 1 violation (total 1534).
  - Les 7 marques « Choix de formulaire » retirées : 7 violations. Ce sont bien des choix de formulaire : accès agents, création de classe, planification et résultat d'évaluation, niveau.

**Tests (toujours avec --concurrency=2)**
- Suite complète, hors capture, fixtures et support : **6704 succès, 0 échec**. C'est le total annoncé.
- Ancien code (5a52ff30) : les 4 nouveaux fichiers de test y échouent tous sur de vraies assertions, et non sur des erreurs de compilation.
  - rangee_filtres : -9.
  - qualite_liste : -8, avec « Vertical viewport was given unbounded height » et « RenderFlex children have non-zero flex… ».
  - observations_filtres_lignes : -6.
  - hauteur_reelle : -26.

**Mutations (correction annulée)**

| Mutation | Résultat |
| :--- | :--- |
| M1 curseur en couleur d'accent | échoue (attendu) |
| M2 piste invisible | échoue |
| M3b ancien centrage | échoue |
| M5 Qualité `defileSeule: true` | échoue |
| M6 Qualité en `Column` | échoue |
| M7 ligne Observations toujours côte à côte | échoue |
| M8 trait d'union insécable retiré | échoue |
| M9 personnes hors de la rangée | échoue |
| M11 Comptes en `Column` | échoue |
| **M3** alignement « début de puce » retiré | **survit** |
| **M4** « nouvellement retenu » neutralisé | **survit** |
| **M10** `minimumEtire` retiré (Comptes) | **survit** |

**Régressions sur les autres appelants**
- J'ai fait un balayage ponctuel de **792 cas** : les 11 écrans à filtres, aux largeurs 320, 390, 600, 700, 1024 et 1440, en texte x1 et x2, en LTR et en RTL, en clair, en sombre et en Interface guidée. Résultat : **0 exception**.
- Sur la base, le même balayage donnait 122 échecs : Qualité, Programmes, Comptes, Classes, Évaluations et Progression débordaient à 320x568.
- `DataCollection.defileSeule` vaut vrai par défaut, donc le comportement ne change pas pour les autres appelants.

**Les 8 points de la demande**
1. **Qualité** : fait. Plus de plantage avec des anomalies ouvertes, à 320 et 1440, en x1 et x2, en LTR et RTL. La correction est étendue à 5 autres écrans.
2. **Barre de défilement** : faite. Elle est neutre, faite de jetons, avec sa piste. Le choix est consigné « décidé par délégation le 09/10 ». Réserve mineure : le curseur reste un trait sombre de 4 px et, à 320 x2, il tombe sous la puce retenue.
3. **Ouverture** : faite. La rangée s'ouvre au début d'une puce et le filtre retenu se voit entier. Je l'ai vérifié sur les captures en LTR et en RTL.
4. **Observations dès 600 px** : une seule rangée, c'est fait, **mais au prix d'une régression** (voir plus bas).
5. **« Fatoumata » et « 23/09/2026 »** : faits. Plus de coupure à 320 x2, en LTR et en RTL.
6. **Fiche UX** : `UX_REVIEW_FILTRES-1.md` est présente et complète. Les sources web sont bien inaccessibles : je l'ai vérifié, curl renvoie 000 pour les trois.
7. **Contrôle `wrap-filtres`** : en place et efficace, total inchangé.
8. **Captures** : 68 captures, que j'ai ouvertes : 320 x2 LTR et RTL, 390, 1440, sombre, Interface guidée. Réserve : les captures à 320 sont faites à 900 px de haut, et il n'y en a aucune à 320 x2 en Interface guidée.

### Défaut majeur (bloquant)

**Les personnes retenues sont cachées après le choix**
- Le mécanisme ne reconnaît pas les personnes : `RangeeFiltres._retenu` (rangee_filtres.dart:151) ne reconnaît que `FilterPill` et `MenuFiltre`. Observations lui passe des `_PastillePersonne`, c'est-à-dire un `FilterPill` dans un `Semantics`. Elles ne sont donc jamais « retenues » aux yeux de la rangée, qui ne les amène pas dans la vue, ni au choix ni à l'ouverture.
- Mesures, part visible de la puce de chaque personne :

| Largeur et texte | Branche (tuteur / élève) | Base 5a52ff30 |
| :--- | :--- | :--- |
| 700 x1 | 34 % / 0 % | 100 % / 100 % |
| 1024 x2 | 32 % / 0 % | 100 % / 100 % |
| 1440 x2, LTR et RTL | 58 % / 0 % | 100 % / 100 % |

- La capture livrée `filtres1b_observations_personnes_1440_x2.png` montre bien « Tuteur : Fatour » coupé et aucune puce Élève.
- Or la puce est le seul moyen de retirer ce filtre.
- **Correctif à faire :**
  - que `_retenu` reconnaisse la pastille de personne (marqueur ou paramètre) ;
  - ajouter un test « la personne retenue se voit entière » à 600, 1024 et 1440, en x1 et x2, en LTR et RTL ;
  - ajouter un test qui échoue quand `didUpdateWidget` est neutralisé.
- J'ai essayé ce correctif : Mariam devient visible à 100 % à toutes les largeurs.

### Réserves mineures
- Trois mutations survivent : M3, M4 et M10. Il faut ajouter :
  - une assertion « puce retenue hors du fondu » ;
  - une assertion sur la hauteur minimale lisible de la liste.
- Le curseur reste un trait sombre sous la puce retenue à 320 x2. Il est acceptable avec sa piste ; on pourrait l'éclaircir.
- Les captures à 320 x2 sont faites à 900 px de haut. Il faudrait en ajouter à 320x568, et une à 320 x2 en Interface guidée.

### À relayer (hors lot, antérieur)
- **À 1440 x2, en vue tableau (DataCollection), des mots sont coupés :**
  - Observations : « 23/09/20 / 26 » et « 18:12: / 00 », et l'en-tête « Entr… » est tronqué. On le voit sur la capture du lot, sans que le compte rendu le signale.
  - Comptes : « Enseignant », « Administration », « Pièce d'identité » et « Inscrit depuis ».
  - Progression : « Perfectionnement » et « Approfondissement ».
- **Interface guidée à 320x568 x2 :**
  - le sélecteur de sous-navigation affiche « Programme / s » ;
  - le texte d'aide de la recherche d'Observations finit en ellipse ;
  - dans Bibliothèque, le texte d'aide (« Titre, niveau, sourate ou page ») et « Leçon · Tajwid » sont tronqués.
- **En RTL forcé**, les heures s'affichent dans un ordre inversé (« 18:14 - 18:12 », « min 2 »), comme le rédacteur l'a signalé.
- **Groupes** : la page s'intitule toujours « Groupes » et non « Classes ».
