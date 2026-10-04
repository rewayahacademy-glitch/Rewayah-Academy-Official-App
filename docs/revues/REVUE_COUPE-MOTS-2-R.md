# Revue COUPE-MOTS-2 (point 3, m6 de COUPE-MOTS-1-R)

## Verdict
**ACCEPTEE_AVEC_RESERVES** : aucun défaut bloquant ni majeur, quatre défauts mineurs.

Le défaut corrigé : en RTL, la légende française de repli « 3 élèves » s'affichait « élèves 3 ». Le correctif l'isole par ligne entière avec U+2068/U+2069 (FSI/PDI), dans `mes_classes_page.dart:235-255` et `:324`. Le reste du code ne change pas. Il n'y a ni jeton, ni rôle, ni serveur, ni libellé nouveau, et le rendu du Coran n'est pas touché. Isoler la ligne entière plutôt que chaque segment est le bon choix : à 320 px, l'ordre visuel des segments reste correct.

## Périmètre et commandes
Diff af20f6c2..8343eb95, deux commits : un fichier lib, un fichier de test, 6 PNG.
- dart analyze --fatal-infos : 0
- verifier_revue : 1627, aussi bien sur la base que sur la tête
- verifier_jetons : 39, aussi bien sur la base que sur la tête
- Tests ciblés, --concurrency=2 : 42 réussis, 0 échec
- **Contre-épreuve refaite** : avec l'ancien mes_classes_page.dart, le cas RTL échoue (le chiffre est à 438 alors que la limite est 339). Le cas LTR passe. Fichier restauré.

## Défauts
1. **mineur** : il manque une capture en thème sombre et une capture à 1440. Le lot s'arrête à 1280, en clair seulement.
2. **mineur** : `mes_classes_page.dart:246-255`, l'isolat de la ligne « quand » n'a aucun test. Une mutation qui le retire passerait.
3. **mineur** : le même défaut est latent dans `journee_page.dart:1210`, `absence_remplacement_vue.dart:176` et `cahier_page.dart:692`. Ces libellés « {nombre} élèves » n'existent pas dans ar et retombent sur le français. Le helper `_isole` est privé alors que le besoin concerne plusieurs écrans.
4. **mineur** : à 320 px, le chiffre est séparé de « élèves » par le retour à la ligne, sur Al-Badr, en LTR comme en RTL. Une espace insécable dans le libellé réglerait le problème.

## Captures vues
320 x2 RTL, 320 x2 LTR, 390 x2 RTL et 1280 x2 RTL : l'ordre « 3 élèves » est correct partout, aucun mot coupé, aucun chevauchement, aucun texte trop petit.

## Pour accepter sans réserve
- Ajouter une capture sombre et une capture à 1440 de Mes Classes en RTL.
- Tester l'ordre de la ligne « Aucune séance prévue » ou « Prochaine séance » en RTL.
- Ouvrir un lot de suivi qui partage l'isolat bidi pour Journée, Remplacement et Cahier.
- Mettre une espace insécable entre le nombre et « élèves ».

## Contre-revue adverse

Verdict confirmé : oui. Verdict final retenu : **ACCEPTEE_AVEC_RESERVES**.

Contre-relecture dans un worktree détaché à 8343eb95 (origin/corrections/c2-coupe2), retiré à la fin. Je n'ai trouvé aucun défaut bloquant ou majeur que le premier relecteur aurait manqué. Le verdict ACCEPTEE_AVEC_RESERVES tient.

1. Diff relu en entier (af20f6c2..HEAD). Le code change à un seul endroit, mes_classes_page.dart. Chaque ligne de légende passe dans un isolat FSI…PDI via le helper privé _isole. Aucune couleur, aucun espacement, aucun rayon en dur. Aucun rôle, aucun branchement serveur, aucun nouveau libellé. Le seul ajout est une fonction pure en fin de fichier.

2. Régressions possibles hors du lot :
   - _isole n'est utilisé que dans mes_classes_page.dart.
   - Un seul test cherche ces chaînes : mes_classes_test.dart:123. Il utilise find.textContaining(sansProchaine), donc les caractères d'isolat ne le cassent pas.
   - TexteSansCoupure découpe les mots sur \s+. FSI et PDI ne sont pas des espaces : le découpage et la mesure du mot le plus long restent cohérents.
   - Les captures sont reproductibles par le test de capture existant (test/capture/coupe_mots1_capture_test.dart:262, nom mes_classes_{largeur}_x2_{sens}). Elles ne viennent pas d'un script hors dépôt.

3. Les tests prouvent bien le correctif :
   - mes_classes_test.dart passe sur la tête : +23, 0 échec.
   - Contre-épreuve refaite avec mes_classes_page.dart remis à af20f6c2. Le cas rtl ÉCHOUE (Expected < 339.36, Actual 438.34) et le cas ltr passe. Cela confirme ce que le premier relecteur avait mesuré.
   - Fichier restauré, git status propre.

4. Captures que le premier relecteur n'avait pas ouvertes : 390_ltr et 1280_ltr. J'ai aussi rouvert 320_rtl.
   - Aucun mot coupé, aucun chevauchement.
   - « 3 élèves » est dans le bon ordre partout.
   - À 320 px en RTL, la séparation « Français · 3 / élèves » se confirme. Elle est déjà notée en réserve mineure.

5. Bilan sur ses réserves :
   - assets/i18n/ar.i18n.json ne contient ni enseignant.classes ni disponibilites.joursLongs. Toute la page s'affiche donc en français de repli. Cela confirme sa réserve n° 3 (même défaut sur d'autres écrans, hors périmètre).
   - L'isolat sur la ligne « quand » ne change rien au rendu actuel : la ligne commence par une lettre latine. Son absence de test (réserve n° 2) reste donc mineure.
   - Aucune de ses réserves n'est infondée.
   - Je n'ai pas prouvé qu'une capture sombre ou à 1440 est exigée pour ce lot. Je laisse cette réserve en mineur, comme il l'a classée.

