## Verdict : REFUSÉE

Le lot améliore nettement la barre : « Q/u/i/t/t/e/r » et « Agrand/ir » ont disparu à 320 px pour 200 % de texte, et la maquette M4 est tenue à 390 px. Il reste pourtant deux défauts majeurs. Des mots sont encore coupés à 100 % de texte sur 340, 360 et 375 px, dont « Son interr/ompu » à 375 px, cité dans la fiche. Et l'état « Réduire » coupe des mots dès 320 px. Le test de 16 cas ne couvre aucune de ces situations.

## Périmètre et commandes

- **Périmètre :** origin/corrections/c2-tuile-tuteur..origin/corrections/c2-obs-coupe, 2 commits (70860c64, 752ede43).
  - lib/features/tc_observation_ui/barre_commandes_observation.dart (+82/−13) ;
  - test/teaching_core/g/barre_observation_coupe_test.dart (nouveau, 16 cas) ;
  - 21 captures sous docs/current/captures/OBS-COUPE-1.
- **Analyse et format :** dart analyze --fatal-infos ne trouve rien ; dart format ne change rien.
- **Vérificateurs, tête puis base :**
  - verifier_revue : 1627 et 1627 ;
  - verifier_jetons : 39 et 39.
  - Aucune hausse. Aucune valeur en dur ajoutée : seuls des jetons AppSpacing sont utilisés.
- **Tests ciblés (--concurrency=2) :** 108 sur 108 passent.
- **Contre-épreuve 1** (ancien fichier lib remis) : 14 cas sur 16 échouent, donc le test porte bien sur le défaut.
- **Contre-épreuve 2** (règle de largeur neutralisée) : les 4 cas à 320 px x1 échouent.
- **Test complémentaire jetable** (largeurs 320, 340, 360, 375, 414 ; échelles 1 ; 1,3 ; 1,5 ; 2 ; 3 ; LTR et RTL ; son reçu et interrompu ; agrandi vrai puis faux) : 16 échecs sur 200.
- **Règles respectées :** aucun libellé nouveau, aucun branchement serveur, aucun rôle lu, Coran non touché.

## Défauts

1. **MAJEUR**, barre_commandes_observation.dart:73-88. La fonction `_troisTropEtroits` suppose trois tiers égaux. Or Quitter garde sa largeur propre en mode une rangée, la marge d'arrondi de 2 px de TexteSansCoupure n'est pas comptée, ni l'encombrement du Pressable. La barre reste donc sur une rangée alors que le mot ne tient pas, même au plancher de 0,85. Mots coupés relevés (même harnais que le test du lot, gouttière de 16 px identique au padding réel du panneau) :
   - « Agrandir » à 340 px x1 et 360 px x1 ;
   - « Son interrompu » à 375 px x1 ;
   - « Agrandir » à 375 px x1,3.
   360 et 375 px sont des largeurs de téléphone très courantes.
2. **MAJEUR**, l'état agrandi (« Réduire ») n'est pas testé, le test fixe agrandi=false à la ligne 44. Mots coupés relevés :
   - ['Son reçu : reçu', 'Réduire : Réduire'] à 320 px x1 ;
   - « Réduire » à 340 px x1 et 360 px x1,3 ;
   - « Son interrompu » à 375 px x1.
3. **Mineur**, la matrice de test se limite à {320, 390} x {1, 2}. Elle ne voit ni 360 ni 375, ni le seuil 1,3.
4. **Mineur**, il manque des captures :
   - à 320 px et 100 % de texte (le cas « Agrand/ir » de la fiche) ;
   - à 360 et 375 px ;
   - de l'état « Réduire » sur téléphone étroit.
5. **Mineur, hors diff et déjà présent sur la base**, à 200 % de texte :
   - la barre est rognée en bas ;
   - la carte du support est tronquée à mi-texte à 320 px ;
   - les vignettes sont rognées à 390 px.

## Captures vues

- 320 px à 200 % de texte (avec la capture de base pour comparer) : barre sans mot coupé, mais support et bas de barre rognés.
- 390 px clair : M4 conforme.
- 390 px à 200 % de texte : deux rangées propres.
- 1440 px sombre : barre D1 correcte.
- 390 px sombre, confirmation de sortie : correcte.

## Pour accepter

- Calculer la place réelle d'un libellé selon la disposition effective : en une rangée, (largeur − 2·sm − 2·xs − largeur de Quitter mesurée) / 2 − médaillon − sm, en tenant compte de la marge d'arrondi de TexteSansCoupure. Ou mesurer directement les libellés dans leur case réelle.
- Étendre le test aux largeurs 320, 340, 360, 375, 390 et 414, aux échelles 1 ; 1,3 ; 2, et à agrandi vrai et faux. Il doit échouer sur la tête actuelle.
- Ajouter les captures à 320 px et 100 % de texte, à 360 px, et de l'état « Réduire » sur téléphone étroit.

## Contre-revue adverse

Verdict confirmé : oui. Verdict final retenu : **REFUSEE**.

Le refus tient : je confirme le verdict REFUSEE. J'ai travaillé dans un worktree détaché sur origin/corrections/c2-obs-coupe (752ede43). J'y ai écrit un test jetable dérivé directement de test/teaching_core/g/barre_observation_coupe_test.dart : même harnais (gouttière de 16 px, verifierAucunMotCoupe), avec en plus les largeurs 320, 340, 360 et 375 px, les échelles 1 et 1,3, les deux sens LTR et RTL, son reçu et son interrompu, et agrandi à false puis à true. Lancé avec --concurrency=2 : 48 cas passent et 16 échouent.

Les deux défauts majeurs se reproduisent exactement comme le premier relecteur les décrit.

1) Avec agrandi=false, le mot est coupé dans les cas suivants :
- 340 px à x1 : « Agrandir : Agrandir » ;
- 360 px à x1 : « Agrandir : Agrandir » ;
- 375 px à x1, son interrompu : « Son interrompu : interrompu » ;
- 375 px à x1,3 : « Agrandir : Agrandir ».
Chaque cas échoue en LTR comme en RTL. La fiche dit avoir corrigé « Son interr/ompu », ce n'est donc pas le cas à 375 px.

2) Avec agrandi=true (libellé « Réduire »), l'état n'est jamais testé par le lot :
- 320 px à x1, son reçu : ['Son reçu : reçu', 'Réduire : Réduire'] ;
- 340 px à x1 : 'Réduire : Réduire' ;
- 360 px à x1,3 : 'Réduire : Réduire' ;
- 375 px à x1, son interrompu : 'Son interrompu : interrompu'.
Cet état est atteignable en production : onAgrandir bascule _agrandi dans panneau_observation_tuteur.dart:120.

Le harnais est fidèle à l'écran réel. Sur téléphone, la salle du tuteur est rendue dans PageShell(defilante: false) (entree_observation_page.dart:428), dont la gouttière mobile vaut 16 px (page_shell.dart:23 et 394). Une seule réserve : le relecteur cite comme gouttière le padding AppSpacing.lg de panneau_observation_tuteur.dart:156. Or cette ligne appartient à la branche tablette. La valeur de 16 px est juste, seule la référence est fausse, et cela ne change rien aux résultats.

La cause tient à la géométrie de _troisTropEtroits. La règle découpe la barre en trois tiers égaux, alors qu'en rangée unique Quitter garde sa largeur propre et laisse donc moins d'un tiers à chacune des deux autres commandes.

Les défauts mineurs sont eux aussi exacts :
- le test du lot ne couvre que {320, 390} x {1, 2} avec agrandi=false ;
- les 21 PNG ne contiennent aucune capture à 320 px et 100 % de texte, aucune à 360 ou 375 px, et aucune de l'état « Réduire » sur téléphone.

Je n'ai trouvé aucun défaut supplémentaire prouvé. Le test jetable a été supprimé et le worktree retiré.

