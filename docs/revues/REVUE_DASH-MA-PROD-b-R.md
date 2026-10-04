J'accepte le lot avec réserves. Le défaut majeur des rapports est corrigé : hors ligne, l'Accueil MA n'a plus de bouton « Réessayer » grisé. Restent trois mineurs, qui demandent tous une décision du directeur ou un lot séparé.

# Relecture adverse DASH-MA-PROD-b (corrections/c2-ma-prod-b, 295a3332)

## Contexte

- **Lot relu** : `origin/corrections/c2-ma-prod-b` à 295a3332, 2 commits au-dessus de `origin/corrections/c2-ma-prod` (ef272b74).
- **Défauts à lever** : ceux de `docs/revues/REVUE_DASH-MA-PROD-R.md` (branche `origin/revues/2026-10-04-b061fd81`), soit 1 majeur et 4 mineurs.
- **Méthode** : tout s'est fait dans un worktree jetable détaché, `rv-MA-PROD`, plus `rv-MA-BASE` pour la base. Les deux sont retirés. Rien n'a été poussé et aucune branche n'a été modifiée.

## Ce que je n'ai pas vérifié

- **Démarche « Ce qui change »** : je ne l'ai pas refaite telle quelle. La relecture d'origine l'avait établie avec une sonde dans le test et la capture `ma_prod_horsligne_390_clair.png`. Je l'ai remplacée par des mutations : je remets l'ancien comportement et je constate que les nouveaux tests échouent (voir « Contre-épreuves »).
- **Mots coupés à 390 px** : ils ne sont contrôlés que sur les captures livrées, pas par la matrice de tests.
- **Captures non ouvertes** : les deux à 390 px en sombre (hors ligne et vide), et la capture vide à 1440. Je n'ai pas non plus ouvert la capture contenu 320 x2 de ef272b74, ni aucune capture où la séance est affichée : le point « 3 h / 28 » repose donc sur la relecture d'origine.

## Ce qui change (diff ef272b74..295a3332)

- **`accueil_accessibilite.dart`**
  - Sur la route lue, `_Haut` transmet maintenant `onReessayer: () => ref.invalidate(horsLigneProvider)` à `CarteSession`.
  - C'est le même fonctionnement que `fiche_groupe_page.dart:505` et `espace_groupe_page.dart:318`.
  - La branche de démonstration passe `onReessayer: null` avec `horsLigne: false`. Dans ce cas, aucun « Réessayer » ne s'affiche.
  - Le commentaire U+2011 est corrigé : il parle maintenant de U+2060, ce qui correspond au code.
- **`carte_session.dart` (`_LigneEtat`)** : `Text` devient `TexteSansCoupure`. Le style tabulaire est conservé. C'est un composant partagé.
- **`fr.i18n.json`** : dans `videPhrase`, le « ; » devient un point. Seul le fichier fr porte cette clé. Le nouveau texte est déclaré dans `libelles_sources.json`.
- **Tests** : `test/features/accueil_ma_prod_test.dart` reçoit trois ajouts.
  - Un test hors ligne : aucune ActionPrincipale sans onPress, « Réessayer » relit le réseau, puis « Voir ma classe » revient.
  - Un test sur la ponctuation orpheline : état vide, 320 x2, LTR et RTL.
  - L'état « hors ligne » entre dans la matrice « aucun mot coupé ».

## Commandes et résultats (worktree à 295a3332)

| Commande | Résultat |
| --- | --- |
| `flutter pub get --offline` | OK |
| `dart run slang` | OK, sans changement non suivi |
| `dart analyze --fatal-infos` | aucun problème |
| `dart run tool/verifier_jetons.dart` | 39 violations, même liste que sur ef272b74 (seul un numéro de ligne de `carte_session.dart` passe de 399 à 400) |
| `dart run tool/verifier_revue.dart` | 1627 violations, sortie identique à ef272b74 |
| `dart format` sur les fichiers touchés | 0 fichier modifié |
| `flutter test --concurrency=2 test/features/accueil_ma_prod_test.dart` | 49 tests passent |
| `flutter test --concurrency=2 test/features test/accessibilite test/widgets test/teaching_core test/router` | +4288, ~2117 sautés, **0 échec** (EXIT=0, environ 21 min) |

Je n'ai pas relancé les autres dossiers de `test/`. Ils ne sont pas touchés par le diff ; `CarteSession` et `TexteSansCoupure` sont couverts par les dossiers ci-dessus.

## Contre-épreuves (une mutation à la fois, puis retour à HEAD)

| Mutation | Résultat |
| --- | --- |
| M1 : `_Haut` ne transmet plus `onReessayer` (on remet le défaut majeur d'origine) | Le test hors ligne échoue (1 échec) |
| M2 : `onReessayer: () {}` (le bouton n'est plus grisé mais ne fait rien) | Le test hors ligne échoue aussi (1 échec) : il vérifie bien que le réseau est relu, pas seulement que onPress existe |
| M3 : on remet l'ancien `videPhrase` avec « ; » (json et g.dart) | 2 échecs : « « ; » jamais seul », vide 320 x2, LTR et RTL |
| M4 : `_LigneEtat` revient à `Text` | 2 échecs : « Aucun mot coupé », hors ligne 320 x2, LTR et RTL |

Les quatre nouveaux tests distinguent bien l'ancien code du nouveau.

## Défaut majeur de la relecture : levé

L'ancien défaut était : « Réessayer » grisé hors ligne, et « Voir ma classe » masqué.

- **Mutations** : M1 reproduit l'état ef272b74 (`onReessayer` non transmis, donc onPress nul) et fait échouer le nouveau test. Sur HEAD, le test passe.
- **Capture `ma_prod_b_horsligne_390_clair.png`** (ouverte) : le bandeau « Pas de réseau » est en haut. On lit « Tu es hors ligne. La séance nécessite une connexion. ». Le bouton « Réessayer » est un bouton secondaire à contour, avec un libellé en encre pleine, non grisé.
- **Captures 320 x2 clair et sombre** : « connexion. » reste entier, « Réessayer » est actif, et le Coran et l'aide restent visibles.
- **Capture 1440 clair** : navigation latérale, « Réessayer » en fin de ligne.
- **Retour en ligne** : relire `horsLigneProvider` relance le flux de connectivité (`service_reseau.dart:52`). C'est le fonctionnement déjà utilisé sur deux autres écrans. Le test prouve qu'au retour en ligne, le bandeau et « Réessayer » disparaissent et que « Voir ma classe » revient.
- **D9** : il demande que « Rejoindre » reste présent et inerte hors ligne. Hors ligne, `CarteSession` affiche « Réessayer » à sa place. Ce composant partagé est antérieur au lot et fait de même sur la fiche groupe : ce n'est pas une régression.

## Défauts mineurs de la relecture

1. **« ; » orphelin : levé.** Le « ; » devient un point. Le test le mesure par `getBoxesForSelection`, et M3 montre qu'il distingue l'ancien texte du nouveau. La capture `ma_prod_b_vide_320x2_sombre.png` (ouverte) montre « l'académie. » puis « En attendant, … », sans ponctuation orpheline ni mot coupé. Le libellé change, et cette modification reste à faire valider par le directeur.
2. **Commentaire U+2011 : levé.** Il annonce maintenant U+2060 (gluon de mots), ce qui correspond à `replaceAll('-', '-⁠')`.
3. **Deux colonnes supprimées : non levé.** C'est un arbitrage du directeur entre DASH-1 Q3 et la fiche ELV-02-MA. Le rédacteur le renvoie correctement au directeur. Je le garde en réserve.
4. **« 3 h / 28 » : non levé.** Il vient du formateur partagé `tc_horloge`, antérieur au lot. La ligne se coupe entre deux mots, pas au milieu d'un mot. À traiter dans un lot dédié. Je le garde en réserve.

## Défaut supplémentaire corrigé par le rédacteur

« une conn / exion » apparaissait à 320 x2 hors ligne : le lot l'avait fait apparaître en transmettant `horsLigne`. Il est corrigé par le passage à `TexteSansCoupure`, et M4 montre que le test le détecte.

## Régressions

- **`CarteSession`** : elle est partagée par l'espace de groupe, la fiche groupe et la salle. Son changement est couvert par les 4288 tests des dossiers features, accessibilité, widgets, teaching_core et router, tous au vert.
- **Mots coupés** : aucun nouveau mot coupé, ni dans la matrice (320 x2 et 1440, LTR et RTL, contenu, hors ligne, vide, erreur, indisponible, aide) ni sur les captures ouvertes : hors ligne en 320 x2 clair et sombre, 390 clair et 1440 clair ; vide en 320 x2 sombre.
- **Règles du lot** : aucun jeton, rôle, secret ou fichier interdit n'est touché. `pubspec`, `.github`, `supabase` et le thème sont inchangés.

## Côté serveur

Rien de nouveau. La source réelle de l'Accueil MA (MA-BR, BR-1) n'existe toujours pas. En production, le port renvoie toujours `CapaciteIndisponible`.

## Verdict

**ACCEPTEE_AVEC_RESERVES.** Le seul défaut majeur est levé, avec une preuve qui tient (test qui distingue l'ancien code du nouveau, captures), et je n'ai trouvé aucune régression. Les réserves sont trois points mineurs :
- le choix une ou deux colonnes, à trancher par le directeur ;
- « 3 h / 28 », qui vient du formateur partagé et relève d'un lot dédié ;
- le nouveau libellé `videPhrase`, à faire valider par le directeur.