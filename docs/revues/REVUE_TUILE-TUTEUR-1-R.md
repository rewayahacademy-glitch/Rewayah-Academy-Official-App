## Verdict
**REFUSEE.** Il reste deux défauts majeurs : la preuve à 320 px × 2 est nulle, et des mots sont coupés dans une capture livrée. Le code du lot lui-même est sain.

## Ce qui est bon
- **Code :** `panneau_observation_tuteur.dart` passe bien à `TuileSansImage`, appelée comme dans `scene_classe` et `salle_page`. Le style vient de `surfaceSunken` + `labelMedium`. L'étiquette du bas disparaît sans image (`etiquette = image != null || p == null`). Les ondes vont dans le coin via `_OndesParole` (jetons `pointsStatut.succes`, `AppSpacing.lg`).
- **Règles :** aucun libellé nouveau (`cameraFermee` existait déjà), aucun rôle lu, aucun branchement serveur, rendu du Coran non touché.

## Périmètre et commandes
af20f6c2..1910b943 : 2 commits, 3 fichiers Dart et 21 PNG.

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `verifier_revue` | 1627 sur la tête = 1627 sur la base |
| `verifier_jetons` | 39 sur la tête = 39 sur la base |
| Tests ciblés (`--concurrency=2`) | 21 + 80, tout passe |
| Captures régénérées | identiques octet pour octet aux PNG commités |

Contre-épreuves, refaites par moi :

| Changement appliqué | Résultat |
| :--- | :--- |
| Fichier lib remis à la base | 3 échecs, détecté |
| Étiquette du bas forcée (`etiquette = true`) | échec, détecté |
| `libelleSansImage` retiré | échec, détecté |
| `coin: null` | tout passe, **non détecté** |

## Défauts
1. **Majeur — la capture `o2_sans_image_texte200_320x844@2_light.png` ne montre aucune vignette.**
   - Elle est identique octet pour octet à celle que produit le code de base.
   - À 320 px et 200 %, les vignettes sont à y 763–866 dans un Scrollable, donc hors champ.
   - Le test de widget vérifie seulement que la tuile tient dans son cadre, pas qu'elle est visible à l'écran.
   - Correction : `ensureVisible` sur les vignettes avant de capturer.
2. **Majeur (déjà présent sur la base, hors diff) — mots coupés à 320 px et 200 %.**
   - Barre de commandes : « Agrand / ir », « Quitter » à une lettre par ligne.
   - En-tête : « Mariam · Sayyid E… » rogné.
   - À corriger, ou à ouvrir comme étape distincte et datée.
3. **Mineur — le nom est dit deux fois au lecteur d'écran.**
   - Tête : un nœud « Mariam », puis un nœud enfant « Mariam, Caméra fermée ».
   - Base : un seul nœud « Mariam\nCaméra fermée ».
   - Correction : `excludeSemantics` sur le cadre quand la tuile est montrée.
4. **Mineur — ondes de parole non testées.** Avec `coin: null`, les 168 tests de `test/teaching_core/g/` passent quand même.
5. **Mineur — le sens droite-à-gauche n'est ni testé ni capturé.**

## Captures vues
- **390 clair et sombre :** conformes.
- **1440 :** conforme.
- **320 × 2 :** voir les défauts 1 et 2.

## Pour accepter
- Refaire la capture 320 × 2 après défilement jusqu'aux vignettes, et ajouter dans le test un contrôle de visibilité à l'écran.
- Corriger les mots coupés de la barre de commandes à 320 px et 200 %, ou les consigner dans une étape dédiée et datée validée par le directeur.
- De préférence, corriger aussi la sémantique en double, ajouter un test des ondes en mode sans image, et ajouter un cas RTL.

## Contre-revue adverse

Verdict confirmé : oui. Verdict final retenu : **REFUSEE**.

Le refus tient : j'ai reproduit les deux défauts majeurs.

Méthode : worktree détaché sur origin/corrections/c2-tuile-tuteur (1910b943), avec flutter pub get et dart run slang, puis tests ciblés en --concurrency=2. Le worktree est retiré.

1. Majeur 1, capture 320 px à 200 % qui ne prouve rien : reproduit.
   - J'ai ouvert docs/current/captures/TUILE-TUTEUR-1/o2_sans_image_texte200_320x844@2_light.png. On y voit le compteur, l'en-tête et la barre de commandes, mais aucune vignette ni aucune tuile sans image.
   - Refaite sur la tête avec CAPTURE_DIR, la capture est identique octet pour octet au PNG commité (cmp).
   - Refaite avec lib remis à af20f6c2, elle est identique octet pour octet à celle de la tête (cmp). Elle ne montre donc rien du lot (K-61, contre-épreuve).
   - Une sonde de test à 320 px et 200 % trouve le nœud sémantique de vignette-enfant marqué isHidden (hors champ). Le test se contente de bord.contains(cercle.topLeft) et ne vérifie pas que la vignette est visible.

2. Majeur 2, mots coupés à 320 px et 200 % : reproduit sur la même capture.
   - « Agrand / ir » est coupé sur deux lignes.
   - « Quitter » s'affiche à une lettre par ligne.
   - La ligne « Sayyid E… » de l'en-tête est rognée à mi-hauteur.
   - Le défaut existait déjà sur la base, mais le lot livre cette capture comme preuve à 320 px × 2, ce qui viole la règle « aucun mot coupé ». Le classer majeur se justifie.

3. Mineur sémantique : confirmé par la sonde. Le cadre porte le label « Mariam » et son enfant le label « Mariam, Caméra fermée », soit un nom annoncé deux fois.

4. Mineurs non rejoués (ondes de parole non couvertes par un test, aucune preuve RTL) :
   - Pour les ondes, le diff montre seulement coin: parle ? const _OndesParole() : null, et aucun test du lot ne cherche _OndesParole. C'est cohérent avec le défaut, mais je n'ai pas rejoué la mutation coin: null.
   - Pour le RTL, le groupe de tests ajouté ne couvre que ltr et aucune capture RTL n'est livrée.

Je ne trouve aucun défaut infondé. Je n'ajoute aucun défaut manqué, faute de preuve supplémentaire.

