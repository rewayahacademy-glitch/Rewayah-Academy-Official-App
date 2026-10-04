# CORAN-CARTE-1 (finitions sur `_BlocCoran`) : acceptée avec réserves

J'ai relu la branche `origin/corrections/c2-coran-carte` au commit `64643b90`, par rapport à la base `a61666ba`. Les commits relus sont `acd59742` et `64643b90`. J'ai travaillé dans un worktree jetable en HEAD détachée, retiré à la fin. Je n'ai rien poussé et je n'ai rien modifié.

Les quatre points demandés sont faits et prouvés. Il reste deux défauts mineurs, tous deux hors de la carte du Coran et déjà présents avant le lot.

## Ce que touche le lot
6 fichiers :
- `lib/features/accueil_eleve/accueil_eleve_page.dart` : une ligne de code et le commentaire ;
- `test/features/accueil_eleve_test.dart` ;
- 3 PNG et le script `.dart.txt` dans `docs/current/captures/CORAN-CARTE-3`.

Le lot ne touche aucune zone interdite : ni `supabase/`, ni `.github`, ni `pubspec`, ni `vercel.json`, ni le thème, ni le rendu du Coran. Les deux messages de commit finissent bien par les deux lignes d'attribution exigées.

## Point 1 : colonne calée au bord de début (fait)
- **Le code :** `Align(alignment: AlignmentDirectional.topStart)` remplace `Alignment.topCenter`. Il respecte le RTL.
- **Le test :** l'ancien test « 1440 centrée » est remplacé par « 1440, ltr/rtl : colonne bornee, calee au bord de debut ». Il vérifie :
  - que la colonne mesure au plus 400 de large ;
  - que le livre et le titre touchent le bord de début du contenu ;
  - que tout l'air restant (largeur du contenu - 400) est du côté de la fin ;
  - que le chevron finit au même bord que le haut-parleur.
- **Mes contre-épreuves,** chacune annulée ensuite :

| Alignement remis | Résultat |
| :--- | :--- |
| `Alignment.topCenter` | les deux tests 1440 (LTR et RTL) échouent |
| `AlignmentDirectional.topEnd` | les deux échouent |
| `Alignment.topLeft` (non directionnel) | le cas RTL seul échoue, ce qui prouve que le test contrôle bien le sens |

- **Les captures,** ouvertes :
  - `coran_1440_clair` : la colonne est calée à gauche.
  - `coran_1440_rtl` : elle est calée à droite.
  - `rv_1440_sombre_enfant`, que j'ai produite en sombre et en Interface guidée : calée à gauche, rien ne coupe.

## Point 2 : taille fixe des icônes (fait, documenté)
Le code des icônes n'a pas changé. Le commentaire de `_BlocCoran` dit maintenant que leur taille fixe à 320 px et texte x2 est voulue (spec point 6, acté). Elles grossissent avec l'Interface guidée (`metriques.estEnfant`, une métrique d'interface et non un rôle), jamais avec l'échelle du texte.

## Point 3 : captures (fait)
- `coran_320x2_enfant` passe à 320x1400. Le titre, la phrase, le chevron et l'air du bas sont visibles.
- `coran_1440_clair` est régénérée et `coran_1440_rtl` est nouvelle.
- Le script `.dart.txt` est à jour.
- **Les captures se reproduisent à l'octet près :** j'ai relancé le script avec `CAPTURE_DIR`, et les 12 PNG du dossier sont identiques à l'octet.
- J'ai aussi produit et ouvert `rv_320x2_enfant_rtl_sombre`, `rv_1440_sombre_enfant` et `rv_390_enfant_rtl`, ainsi que `coran_320x2_sombre`, `coran_320x2_rtl` et `coran_390_clair`. La carte du Coran ne coupe aucun mot et ne déborde pas.

## Point 4 : Interface guidée dans la boucle « aucun débordement, aucun mot coupé » (fait)
La boucle compte maintenant 8 cas : standard et enfant, à 320 px texte x2 et à 1440, en LTR et en RTL. Chaque cas appelle `verifierAucunMotCoupe(tester, carte())`.

**Ma contre-épreuve :** j'ai ajouté une marge de fin de 180, active seulement en Interface guidée, autour de la ligne titre et phrase.
- Les cas enfant à 320 x2 échouent avec « Un mot coupe ou tronque », levé par `verifierAucunMotCoupe` (`aucun_mot_coupe.dart:65`).
- Les 4 cas standard passent.
- Avec une marge de 215 ou 230, c'est le contrôle de débordement qui attrape l'erreur.

Les deux contrôles mordent bien sur le mode enfant.

## Vérifications

| Vérification | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `dart run tool/verifier_jetons.dart` | 39 violations, le chiffre attendu |
| `dart run tool/verifier_revue.dart` | 1627 sur la tête, 1627 sur la base `a61666ba` mesurée de la même façon : aucune hausse |
| `dart format` sur les deux fichiers modifiés | 0 changement |
| Tests ciblés ELV-02 | 47 sur 47 réussis |

Suite complète par dossiers, en `--concurrency=2` :

| Dossier | Résultat |
| :--- | :--- |
| `test/features` | +2497, ~2062 sautés, 0 échec |
| `test/core` | +654, 0 échec |
| `test/router` | +277, 0 échec |
| `test/widgets` | +270, 0 échec |
| Les 22 autres dossiers (sauf capture, fixtures, support) | +787, 0 échec |

Le compte rendu annonçait 23 dossiers et +1699 / ~55 sautés pour ce dernier groupe. Le décompte diffère, mais il n'y a aucun échec.

## Réserves (aucune ne bloque ce lot)
1. **Mot coupé dans l'état vide, au-dessus de la carte.** Le mot « aujourd'hui » est coupé à 320 px et texte x2 : « aujourd'hu / i » en mode standard, « aujour / d'hui » en Interface guidée. On le voit en LTR et en RTL, en clair et en sombre. C'est contraire à la règle « aucun mot coupé ».
   - Le défaut existait avant le lot : les captures `coran_320x2_*` en mode standard sont inchangées depuis la base.
   - Le rédacteur ne l'a signalé que pour l'Interface guidée.
   - Il faut un lot dédié sur l'état vide de l'accueil élève, et étendre le contrôle `verifierAucunMotCoupe` à cette tuile.
2. **Point final mal placé en RTL forcé.** Avec un texte français, le point final de la phrase de l'état vide s'affiche au début (« .Ton prochain cours… »). Cela ne concerne pas la carte du Coran.

## Statut de preuve
Présent dans le code et testé localement. Pas testé sur staging, pas déployé.
