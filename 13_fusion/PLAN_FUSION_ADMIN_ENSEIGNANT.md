# Plan de fusion Admin + Enseignant (ui/admin-v1 2fac423 + ui/enseignant-v1 0b01297)

À exécuter par le poste A, après BR-1 et avec l'accord du directeur. Arbre d'essai : f3d72c2 (BASE 3b41b12a).

## 1. Résumé

- **Conflits textuels :** 7 fichiers. Ce sont `action_principale.dart`, `etat_systeme.dart`, `groupe_reglages.dart`, `lien_fleche.dart`, `pressable.dart`, `repere_demonstration.dart` et `strings.g.dart`.
- **Erreurs cachées dans la fusion automatique :** 2, et chacune bloque la compilation. L'icône `reduire` est définie deux fois dans `app_icons.dart`. Dans `groupe_reglages.dart`, `Pressable.selon` reçoit deux fois les mêmes arguments nommés.
- **Risque global :** moyen. Chaque conflit se règle par l'union des deux versions, et aucun appelant n'est à réécrire, sauf une icône à renommer côté admin.
- **Décisions humaines :** oui, sur le rendu visuel. Les points sont le rendu d'ActionPrincipale sur les écrans admin, `actionsContratB` pour l'admin, `pastille` et `marque`, les lignes sans tête, la typographie du ruban Démonstration et le glyphe partagé. Aucune ne bloque la fusion : chaque point a un choix provisoire, consigné au tableau.

## 2. Ordre d'exécution recommandé

1. **Branche d'intégration dédiée, jamais `main`.** Par exemple, `git switch -c integration/admin-enseignant 2fac423`, puis `git merge --no-ff 0b01297`. Vérifier qu'on retrouve les 7 fichiers en conflit de f3d72c2.
2. **Résoudre fichier par fichier, dans cet ordre.** Chaque fichier dépend du précédent.
   1. `lib/core/widgets/pressable.dart`, dont dépendent les trois suivants.
   2. `lib/core/widgets/action_principale.dart`.
   3. `lib/core/widgets/lien_fleche.dart`.
   4. `lib/core/widgets/groupe_reglages.dart`. Corriger aussi le doublon hors marqueurs dans `_Ligne.build`.
   5. `lib/core/widgets/etat_systeme.dart`.
   6. `lib/features/demo/repere_demonstration.dart`.
   7. `lib/core/icons/app_icons.dart`, qui n'a pas de marqueur (voir §4), et `lib/features/admin_dossiers/visionneuse_piece.dart:358`.
3. **i18n.**
   - Vérifier que `assets/i18n/fr.i18n.json` et `ar.i18n.json` n'ont aucun marqueur et aucune clé en double. C'est déjà le cas dans f3d72c2 : c'est l'union exacte des deux côtés.
   - Pour `strings.g.dart`, prendre n'importe quel côté de l'en-tête.
   - Régénérer ensuite slang avec `flutter-verrou.ps1` (`dart run slang`). La commande réécrit `strings.g.dart`, `strings_fr.g.dart` et `strings_ar.g.dart`. Ne jamais corriger ces fichiers générés à la main. Le compte attendu est d'environ 1695 chaînes par locale ; le chiffre exact est celui que slang produit.
4. **Contrôles avant analyze.**
   - `git grep -n '<<<<<<<\|>>>>>>>'` ne doit rien renvoyer.
   - `git grep -c 'this.focusNode' -- lib/core/widgets/pressable.dart` doit renvoyer 2.
   - `git grep -n 'focusNode:' -- lib/core/widgets/groupe_reglages.dart` ne doit renvoyer qu'une seule occurrence dans `Pressable.selon`.
5. **Analyse statique.** Lancer `flutter analyze` jusqu'à zéro erreur, puis `dart run tool/verifier_jetons.dart`.
6. **Suite de tests complète.** Lancer `flutter test` sur toute la suite, pas seulement les listes du §3.
7. **Captures des deux rôles.**
   - Admin : `test/capture/ad5` à `ad11`, `coque_admin`, `hl_a5_planche`.
   - Enseignant, Classe et salle : captures EN-4 à EN-11, `captures_en_test`, `captures_cl47_test`, `salle_seance_capture_test`, préparation élève et enseignant à 200 %.
   - Comparer avec les captures validées et relever les écarts visuels attendus (§5).
8. **Commit de fusion sur la branche d'intégration.** Pas de fusion dans `main` avant l'accord du directeur.

## 3. Résolution par fichier

### lib/core/widgets/pressable.dart (3 blocs, lignes 110-117, 135-142 et 173-188 de l'arbre)

**Intentions.**
- Admin (AD-5 et AD-6) ajoute `selectionne` (Semantics.selected), `coche` (Semantics.checked), `focusNode` (K-10) et `lien` (Semantics.link au lieu de button) sur les deux constructeurs.
- Enseignant (CL-R) n'ajoute que `focusNode`, pour rendre le focus au bouton qui a ouvert un panneau.

**Résolution.**
- La version admin contient déjà tout l'ajout enseignant : prendre les trois blocs admin tels quels.
- Constructeurs : `this.autofocus = false, this.selectionne, this.coche, this.focusNode, this.lien = false,`. Il ne faut **qu'un seul** `this.focusNode` par constructeur. Un second venant de l'enseignant donne un paramètre en double, donc une erreur de compilation.
- Champs : garder les docs de `selectionne`, `coche` et `lien`, puis **une seule** doc au-dessus de l'unique `final FocusNode? focusNode;`. Doc proposée : « Le noeud de focus de la zone, pour qu'un ecran puisse y poser le focus ou le lui rendre (le bouton qui a ouvert un panneau, a sa fermeture). »
- `build()` est déjà fusionné : `button: _pressable && !widget.lien`, `link`, `selected`, `checked`, `FocusableActionDetector(focusNode: widget.focusNode)`.
- Avec les valeurs par défaut, la sémantique reste celle de BASE pour tous les autres appelants.

**Appelants.** Aucun à modifier.
- `groupe_reglages.dart`, `lien_fleche.dart`, `action_principale.dart`, `dock_seance.dart:196` et `salle_seance.dart:1216` dépendent de cette API.
- Les `selectionne:` de `controle_segmente`, `selecteur_profils` et `BoutonAppel` visent d'autres widgets.

**Tests.**
- `test/widgets/composants_test.dart`.
- `test/features/salle_seance/revue_cl_r_test.dart`.
- Les tests `admin_dossiers` (selected, checked, K-10).
- Les tests de la galerie.
- `flutter analyze`.

### lib/core/widgets/action_principale.dart (2 blocs, lignes 61-66 et 140-157)

**Intentions.**
- Admin (AD-7) ajoute `FocusNode? focusNode`, transmis à Pressable, pour rendre le focus au bouton d'ouverture d'une modale.
- Enseignant ajoute trois choses :
  - `compacte`, une pastille d'environ 34 px pour « Ouvrir » (T6) ;
  - `autofocus`, pour poser le focus sur « Retour à la Classe » (CL-7) ;
  - `_styleLibelle` et `encreClaire` (CLV-10), avec une graisse de 700 pour la principale et de 600 ou 500 sinon, et le filet du niveau secondaire qui passe de 2 à 1.

**Résolution.**
- **Bloc 1 :** faire l'union des paramètres, `…, this.pilule = false, this.focusNode, this.compacte = false, this.autofocus = false`. Le champ `final FocusNode? focusNode;` (admin, après `pilule`) et les champs `compacte` et `autofocus` sont déjà dans l'arbre : rien à ajouter.
- **Bloc 2 :** garder le constructeur en bloc de l'enseignant (`reduit`, `respecterCibleTactile: reduit`, `reduit ? Center(child: corps) : corps`) et lui passer **à la fois** `focusNode: focusNode,` et `autofocus: autofocus,`. Écarter la forme courte `=> _corps(...)` de l'admin, qui perdrait le centrage de la pastille compacte.
- Garder tel quel le reste de la version enseignant : `_styleLibelle`, `encreClaire`, l'import `app_typography.dart`, le filet secondaire à 1.
- Aucune couleur ni aucun jeton n'est touché (K-37).

**Appelants.** Aucun à modifier.
- Admin, avec `focusNode:` : `revue_dossier.dart:383`, `:390` et `:535` ; `surfaces_decision.dart:156`, `510`, `543`, `558` et `572` ; `visionneuse_piece.dart:386`.
- Enseignant :
  - `compacte: true` dans `panneau_supports.dart:317` et `:379` ;
  - `autofocus` dans `ecran_resultat.dart:172` et `fiche_eleve_enseignant.dart:246` ;
  - `encreClaire` dans `composants_test.dart:281-283`.
- Effet visuel sur l'admin : le filet des boutons secondaires passe à 1. La graisse passe à 700 sur les boutons principaux et à 600 ou 500 sur les autres.

**Tests.**
- `composants_test`, `composants_partages_test` et `catalogue_galerie_test`.
- `panneau_supports_test` et `salle_test`.
- `preparation_eleve_test`, `preparation_enseignant_test`, `recette_entree_classe_test`, `revue_groupe_test` et `demo_salle_page_test`.
- Tests admin :
  - `revue_dossier_test`, `decisions_coque_test`, `visionneuse_piece_test` et `visionneuse_production_test` ;
  - `ad11_criteres_test`, `dossiers_admin_test` et `dossiers_sans_piece_test`.
- `composants_partages_test` (« GroupeReglages controle mesure ») et `visionneuse_piece_test:297` mesurent des largeurs, et le libellé tertiaire s'élargit de quelques pixels. Un échec est improbable, mais il faut les regarder.

### lib/core/widgets/lien_fleche.dart (1 bloc, lignes 27-42)

**Intentions.**
- Admin ajoute `annonceLien` (AD-6, lien annoncé comme lien) et `alignerEnFin` (HL-A-3).
- Enseignant ajoute `legende` (T6) : `labelSmall` et une flèche de fin en `AppSpacing.md`, avec une cible toujours de 48×48.

**Résolution.**
- Faire l'union dans le constructeur : `this.fleche = true, this.icone, this.annonceLien = false, this.alignerEnFin = false, this.legende = false`.
- Ajouter les champs `alignerEnFin` et `legende`, chacun avec sa doc. `annonceLien` est déjà plus bas dans l'arbre.
- Le reste de l'arbre est déjà fusionné correctement : `lien: annonceLien`, padding conditionnel, `textAlign`, `tailleIcone`.
- Les trois options sont indépendantes les unes des autres.

**Point à ne pas corriger.** `alignerEnFin` n'a plus d'appelant, et c'est voulu : c61d66d (HL-A-5) l'a retiré de `revue_dossier.dart`, et `revue_dossier_test` (1440 px, `lien.right == carte.right - 4`) fige ce choix. Garder le paramètre sans l'ajouter à l'appelant.

**Appelants.** Aucun à modifier.
- `revue_dossier.dart:665` passe `annonceLien: true` et dépend du `lien` de Pressable.
- `journee_page.dart:756` et `panneau_supports.dart:204` passent `legende: true`.

**Tests.**
- `composants_partages_test` (groupe LienFleche), `revue_dossier_test`, `classe_tuteur_test` et `catalogue_galerie_test`.
- Tests du panneau Supports (« Voir tout » en 390×844) et de `journee_page` (clé `journee-a-terminer-voir-tout`).

### lib/core/widgets/groupe_reglages.dart (3 blocs, lignes 26-50, 77-110 et 267-306, plus un doublon hors marqueurs)

**Intentions.**
- Admin (AD-5, AD-6, HL-A-3) ajoute à `LigneRubrique` :
  - `pastille` et `pastilleSousLibelle` ;
  - `selectionnee` et `cochee` ;
  - `libelleSemantique`, `autofocus` et `focusNode`.
- Admin retire aussi l'assert « icône ou meneur » (tête facultative) et place `controle` par mesure (`_RangeeMesuree`).
- Enseignant (EN-3, EN-12, EN-RC) ajoute `marque`, une marque d'état en fin de ligne qui passe sous la légende au-delà de 1,3 ou sous 320 px. Il ajoute aussi `focusNode` et `libelleSemantique`, et factorise le corps de ligne dans `_rangee(...)`.

**Résolution.**
- **Bloc 1 :** constructeur `const LigneRubrique({required this.libelle, this.icone, this.meneur, this.legende, this.valeur, this.onPress, this.controle, this.marque, this.pastille, this.pastilleSousLibelle, this.selectionnee, this.libelleSemantique, this.autofocus = false, this.cochee, this.focusNode})`.
  - `focusNode` et `libelleSemantique` ne sont déclarés qu'une fois.
  - Supprimer l'assert « icône ou meneur ». Le test admin « une rubrique sans icone ni meneur reste lisible », `file_dossiers.dart:302` et `politique_revue_kyc_page.dart:133` en ont besoin.
  - Garder les imports `dart:math` et `flutter/rendering.dart`.
- **Bloc 2 :** faire l'union des champs sans doublon.
  - Pour `focusNode`, une seule doc qui couvre EN-12 et AD-6.
  - Pour `libelleSemantique`, garder la doc de l'enseignant.
- **Hors marqueurs, obligatoire.** Dans `_Ligne.build` (lignes 196-208 de l'arbre), `Pressable.selon` reçoit deux fois `focusNode:` et deux fois `libelleSemantique:`, ce qui ne compile pas. Remplacer l'appel par :

  ```
  return Pressable.selon(
    onPress: ligne.onPress,
    respecterCibleTactile: false,
    arrondiFocus: AppRadius.arrondiSm,
    libelleSemantique: ligne.libelleSemantique,
    selectionne: ligne.selectionnee,
    coche: ligne.cochee,
    focusNode: ligne.focusNode,
    autofocus: ligne.autofocus,
    constructeur: _contenu,
  );
  ```

- Garder aussi, tels que la fusion automatique les produit, `_contenu` (admin : tête nullable, barre de sélection) et `_textes` (admin : w600, pastille).
- **Bloc 3 :** corps de ligne.

  ```
  child: ligne.controle != null
      ? _RangeeMesuree(sens: Directionality.of(context), children: <Widget>[_textes(palette, textes), ligne.controle!])
      : ligne.marque == null
          ? _rangee(palette, textes, double.infinity, context)
          : LayoutBuilder(builder: (BuildContext _, BoxConstraints c) => _rangee(palette, textes, c.maxWidth, context)),
  ```

  - Garder `_rangee` et `_largeurMarqueEnFin = 320`.
  - La condition du chevron devient `ligne.onPress != null && ligne.controle == null && ligne.cochee == null`.
  - Garder `_RangeeMesuree`, `_DonneesRangee` et `_RenduRangeeMesuree`.
  - Ajouter `assert(controle == null || marque == null)`, compatible avec tous les appelants.
  - Facultatif : mettre à jour les docstrings des lignes 13-14 et 17, qui décrivent encore l'assert supprimé.

**Appelants.** Aucun à modifier.
- Admin : `file_dossiers.dart` et `revue_dossier.dart`, plus les lignes à `controle` (`politique_revue_kyc_page`, `preferences_page`, `apparence_page`, `reglages_enfant_page`, appareils).
- Enseignant, avec `marque` : `mes_classes_page:260`, `cahier_page:597`, `creneaux_page:443`, `profil_enseignant_page:307` et `fiche_eleve_enseignant:543`. Avec `focusNode` : `fiche_groupe_page`.
- Écart de rendu (voir §5). `salle/preparation_eleve.dart:483` et `salle/preparation_enseignant.dart:551`, qui n'existent que côté enseignant, ont un `controle: KeyedSubtree(IconeEtatPreparation)`. Ces lignes passent désormais par `_RangeeMesuree` : à 200 % et en largeur étroite, l'icône peut passer sous le libellé.

**Tests.**
- Widgets : `composants_partages_test`, `catalogue_galerie_test`, `composants_test` et `composants_etats_test`.
- Admin : `file_dossiers_test`, `revue_dossier_test`, `decisions_coque_test`, `parcours_ad10_test` et `ad11_criteres_test`.
- Communs :
  - `compte_galerie_test`, `consentements_test`, `appareils_test` et `classe_tuteur_test` ;
  - `mes_classes_test`, `fiche_groupe_test` et `espace_classe_enseignant_test` ;
  - `preparation_enseignant_test` et `preparation_eleve_test`, avec un contrôle visuel à 200 %.
- Enseignant :
  - `cahier_test` et `captures_en7_test` ;
  - `creneaux_test` et `captures_en5_test` ;
  - `profil_enseignant_test` et `captures_en6_test` ;
  - `revue_groupe_test` et `captures_en11_test` ;
  - `captures_en_test` et `captures_en4_test`.

### lib/core/widgets/etat_systeme.dart (2 blocs, lignes 367-372 et 382-429)

**Intentions.**
- Les deux côtés arrêtent d'afficher une phrase vide, avec le même code, et ne diffèrent que par le commentaire.
- Enseignant (T-S3) ajoute `actionsContratB = false`. Avec `true`, les actions suivent les contrats A et B : 16 sous l'objet, groupe au bord de fin, sortie puis poursuite, clés `etat-systeme-secondaire` et `etat-systeme-action`.

**Résolution.**
- Prendre la version enseignant.
- **Bloc 1 :** un seul commentaire (« Phrase vide non rendue : l'écran n'a qu'un texte à dire (le titre) ; une phrase par défaut serait du texte inventé (AD-5, T-S3). ») et un seul `if (phrase.isNotEmpty)`.
- **Bloc 2 :** garder `if (actionsContratB && (avecAction || avecSecondaire)) ...[…] else if (avecAction || avecSecondaire) ...[` et la branche historique inchangée. La ligne admin `if (avecAction || avecSecondaire) ...[` disparaît : elle correspond exactement au `else if`.
- Retirer toutes les lignes de marqueurs, soit 3 par bloc.
- API : `EtatSysteme({…, String? phrase, …, this.actionsContratB = false})`. `phrase` est facultatif : `null` donne la phrase par défaut de la nature, `''` affiche le titre seul.

**Appelants.** Aucun à modifier.
- Admin, en disposition historique : `detail_dossier.dart`, `file_dossiers.dart`, `visionneuse_piece.dart:404`, `revue_dossier.dart` et `politique_revue_kyc_page.dart`.
- Enseignant : `salle_seance.dart:1444-1455`, avec `actionsContratB: true`.

**Tests.**
- `composants_etats_test`.
- Salle :
  - `salle_secours_test` (clés, lignes 107 et 110) et `salle_secours_t_s5_test` ;
  - `salle_secours_bandeau_test` et `vue_seance_secours_test` ;
  - `salle_seance_capture_test` et `demo_salle_page_test`.
- Admin : `file_dossiers_test`, `revue_dossier_test`, `visionneuse_piece_test`, `decisions_coque_test`, `parcours_ad10_test` et `ad6_revue_capture_test`.
- `etats_transverses_test` et `catalogue_galerie_test`.

### lib/features/demo/repere_demonstration.dart (1 bloc, `textStyle:` du Banner)

**Intentions.**
- Admin (AD-S, HL-A-3) passe le libellé en clés i18n (`t.commun.demonstration.repere` et `repereLu`, K-41). Il applique aussi `labelSmall` en taille 9, w600, `height` 1, `letterSpacing` 0, pour que le mot tienne dans les 80 px du Banner.
- Enseignant (EN-RC, K-42) applique `labelSmall` en taille 10, w700.

**Résolution.**
- Le getter i18n et `repereLu` sont déjà fusionnés.
- Garder le bloc admin, qui contient déjà la base de l'enseignant, avec un seul commentaire qui cite AD-S et K-42 :

  ```
  // La famille vient du theme (revue AD-S, K-42 captures lisibles) : un
  // `TextStyle` nu laisse le bandeau (peint, hors `DefaultTextStyle`) sans
  // police, donc peint en blocs. Couleurs inchangees.
  textStyle: (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
      .copyWith(
        color: Theme.of(context).colorScheme.onTertiary,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        height: 1,
        // Le bandeau de `Banner` ne fait que 80 de long : sans
        // interlettrage et en 9, le mot y tient en entier.
        letterSpacing: 0,
      ),
  ```

- Le constructeur reste `const`. `libelleRepereDemonstration` devient un getter, et aucune expression `const` ne le lit.
- Cela exige la régénération slang du §2.

**Appelants.** Aucun à modifier : `demo_enseignant_page.dart:381` et `:390` (const), `demo_classe_page.dart`, `racine_demonstrable.dart:80` et `main.dart`.

**Tests.**
- `repere_demonstration_test`, `entree_demonstration_test`, `demo_enseignant_page_test`, `demo_classe_page_test` et `demo_salle_page_test`.
- `recette_entree_classe_test`.
- Captures : `captures_en_test`, `captures_cl47_test`, `captures_en7_test`, `captures_en5_test`, et `test/capture/` côté admin.
- `admin_ad11_test`, `admin_coque_test` et `test/features/admin_dossiers/`.
- Facultatif : dans `repere_demonstration_test.dart:35` et `admin_coque_test.dart:186`, comparer à `t.commun.demonstration.repereLu` plutôt qu'à une chaîne écrite en dur.

### lib/core/i18n/strings.g.dart (1 bloc, en-tête ligne 7)

**Intentions.**
- Admin ajoute les textes admin et dossiers, et retire `dossiers.motif`, `motifRequis`, `journalisation`, `genreManquant` et `erreur`.
- Enseignant ajoute les textes enseignant, classe, salle et tc, avec 52 clés arabes, et retire 19 clés `enseignant.*` orphelines.
- Dans ce fichier, seul l'en-tête `/// Strings:` diffère.

**Résolution.**
- Prendre n'importe quel côté, puis régénérer par slang (§2). La régénération réécrit aussi `strings_fr.g.dart` et `strings_ar.g.dart`, qu'il ne faut pas laisser tels que git les a assemblés.
- Les JSON fusionnés sont l'union exacte : 3319 clés feuilles en français, 72 en arabe, aucune collision, aucun conflit de préfixe.
- Aucune clé supprimée n'est encore utilisée dans l'arbre. `dossiers_page.dart` et `dossiers_admin_test.dart` prennent la version admin, et les clés `enseignant.*` retirées ne servent plus hors fichiers générés.
- Seul changement d'API : `t.attente.refuseDetail` devient une méthode `({required Object element})`. Tous ses appelants dans l'arbre viennent de l'admin et sont déjà adaptés.

**Tests.**
- Après slang, `git diff lib/core/i18n/*.g.dart` ne doit montrer que l'en-tête et l'union des getters.
- `flutter analyze`.
- `test/i18n/cle_audio_test.dart`, `admin_ad11_test` et `tuteur_k_echelle_texte_test`.
- `attente_test`, `dossiers_admin_test` et `profil_enseignant_test`.
- Captures `ad5`, `ad6`, `ad10` et `ad11`, puis la suite complète.

## 4. Conflits sémantiques des fusions automatiques

1. **Bloquant : `lib/core/icons/app_icons.dart`.**
   - L'icône `reduire` est définie deux fois : ligne 251 côté enseignant (0xe1ce, `corners-in`, utilisée par `barre_support.dart:193` et `dock_seance.dart:298`) et ligne 373 côté admin (0xe32a, le signe moins du zoom).
   - Correction : garder `reduire` pour l'enseignant, renommer l'entrée admin en `moins` (0xe32a) et mettre à jour `lib/features/admin_dossiers/visionneuse_piece.dart:358`.
   - Aucune couleur n'est touchée.
2. **Bloquant : `lib/core/widgets/groupe_reglages.dart:196-208`.** `Pressable.selon` reçoit deux fois `focusNode:` et `libelleSemantique:` en dehors des marqueurs. La correction est donnée au §3.
3. **Faible : `test/router/redirection_test.dart:47-49` (version admin).** La liste des routes enseignant protégées ne contient pas `Routes.enseignantClasses`. L'ajouter après `Routes.enseignantJournee`.
4. **Faible : doublon de texte.** `commun.demonstration.repere` (admin) et `classe.entree.demo.mention` (enseignant) valent tous deux « Démonstration ». Facultatif : faire lire la clé commune au code enseignant.
5. **Sans conflit, vérifiés :**
   - `routes.dart` : aucun nom en double.
   - `redirection.dart` : `/demo/*` hors production et la règle K-47 ne se croisent pas.
   - `app_router.dart` : blocs disjoints.
   - `navigation_test.dart` : les deux changements sont compatibles.
   - JSON i18n : union exacte.

## 5. Points qui demandent une décision humaine

Pour chaque point, le choix provisoire est appliqué par la fusion et consigné au tableau.

1. **Rendu d'ActionPrincipale sur les écrans admin (AD-7, AD-8, revue).**
   - Le changement CLV-10 de l'enseignant est global : filet secondaire de 2 à 1, graisse de 700 pour la principale et de 600 ou 500 sinon.
   - Choix provisoire : accepter cette harmonisation. Les captures et les preuves `UX_REVIEW` admin deviennent alors partiellement obsolètes.
   - L'autre option serait de garder l'ancien rendu admin jusqu'à HU-1. Elle exigerait une variante qui n'existe dans aucune des deux branches.
2. **`actionsContratB` pour les écrans admin AD-5 (`file_dossiers`, `detail_dossier`, `visionneuse_piece`).**
   - Il faut choisir entre passer tout de suite aux contrats A et B, ou garder la disposition historique jusqu'à HU-1.
   - Choix provisoire : `false`, rien ne change. Passer à `true` modifierait les captures `ad6` et les tests admin.
3. **`pastille` (admin) et `marque` (enseignant) sur LigneRubrique.**
   - Ce sont deux notions voisines pour la même StatusPill, avec deux règles de placement : la mesure HL-A-3 d'un côté, les seuils fixes 1,3 et 320 de l'autre.
   - Il faut décider si l'on garde les deux ou si l'on migre vers une seule, et si la mesure doit s'étendre à `marque`.
   - Choix provisoire : garder les deux, chacune sur son propre cas, et trancher à HU-1.
4. **Ligne de rubrique sans icône ni meneur.**
   - La suppression de l'assert l'autorise dans tout le système visuel commun.
   - Choix provisoire : l'accepter, car les tests admin l'exigent.
5. **Lignes de préparation élève et enseignant à contrôle (`KeyedSubtree`).**
   - Elles passent désormais par la mesure HL-A-3 : à 200 % et en largeur étroite, l'icône d'état peut passer sous le libellé.
   - Il faut valider ce rendu sur capture.
6. **Typographie du ruban « Démonstration ».**
   - Admin : taille 9, w600, le mot tient en entier. Enseignant : taille 10, w700, rendu des captures K-42 déjà montrées.
   - Choix provisoire : la version admin. Les captures enseignant et Classe changent légèrement.
7. **`LienFleche` en registre `legende` avec une icône de début.**
   - Seule la flèche de fin est réduite.
   - Aucun appelant ne combine les deux aujourd'hui. Choix provisoire : garder le comportement de l'enseignant.
8. **Glyphe 0xe1ce partagé.**
   - `ajusterEcran` (admin) et `reduire` (enseignant) ont le même dessin.
   - C'est acceptable, mais à signaler au directeur.