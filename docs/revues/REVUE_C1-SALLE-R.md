# Revue croisée C1-SALLE-R : salle du contrôleur, pré-vol, commandes à 320

- **Objet revu** : `corrections/c1-salle` @ `ecccd0cc` (base `af20f6c2`, branche commune), 5 commits, 70 fichiers (+949 −271), dont 56 captures.
- **Étapes couvertes** : CTRL-SON-1 (`d208e53e`), CTRL-AGRANDIR-1 (`259d296a`), CTRL-PREVOL-1 (`15422a44`), SALLE-CORR-3 (`e65acd13`), SALLE-200-2 (`ecccd0cc`).
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit ce lot (auteur : `268bd1ef`).
- **Date** : 4 octobre 2026.
- **Références** : messages de commit (fiches), `VERIF-CT-1/RAPPORT.md` et `VERIF-CORR-2/LISEZMOI.md` lus sur `origin/pilotage/tuteur-v1`, `14_controleur/CT-BR.md`, `LEXIQUE_CONTROLEUR.md`.
- **Méthode** :
  - lecture du diff ;
  - contrôles relancés dans le worktree `/home/user/rv-c1-salle` (aucune suite complète) ;
  - cinq mutations ciblées, remises en place (`git status` propre à la fin) ;
  - neuf captures ouvertes ;
  - fusion à blanc sur `origin/corrections/revue-directeur-2026-10` @ `08a27c2e`.

## Verdict

**Acceptée avec réserves.** Les cinq étapes font ce que leurs fiches annoncent, et chaque changement est tenu par un test qui échoue sans lui.

- « Son reçu » et « Agrandir le support » ne sont plus rendus chez le contrôleur, pas même grisés (K-56).
- Le contrôleur, le tuteur témoin et l'administration en observation entrent sans micro. Le pré-vol n'est pas lancé pour eux (0 vérification mesurée).
- L'administration visible dont le jeton permet la voix reste bloquée sans micro. C'est la recommandation « garder » de la question CTRL-PREVOL-1.
- La rangée de l'enseignant tient à 320 px texte ×1 (cas réactivé, plus de saut).
- Mot et icône des commandes prennent l'encre du registre salle, pour tous les rôles.
- Le rappel du contrôleur et du tuteur garde son titre à ×2.
- La carte du cours annulé nomme sa Classe et y mène par un lien.

Aucune couleur nouvelle. Le seul défaut grave vu reste **antérieur** au lot et hors de ses fiches (réserve R1) : il doit recevoir une étape avant TB-F.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
|---|---|
| `dart run slang` | régénéré, aucun écart avec le commit (`git status` propre) |
| `dart run build_runner build --delete-conflicting-outputs` | 2050 sorties, aucun écart |
| `dart analyze --fatal-infos` | No issues found |
| `dart run tool/verifier_jetons.dart \| grep -c "\["` | **39** (attendu 39) |
| `flutter test test/features/salle_test.dart test/features/salle_200_test.dart test/features/controleur/ test/features/journee_test.dart` | **+307 ~32**, All tests passed (les 32 sautés sont les groupes de captures, `sautSansCapture`) |
| Écrans voisins : `test/features/salle_seance test/features/salle_enseignant_test.dart test/features/demo/demo_salle_page_test.dart test/video` | **+559 ~367**, All tests passed |
| Fusion à blanc sur `08a27c2e` | **1 conflit**, `lib/core/i18n/strings_fr.g.dart` seul (fichier généré : se règle par `dart run slang`). `fr.i18n.json`, `journee_page.dart`, `journee_test.dart`, `libelles_sources.json` fusionnent seuls |

### Mutations (toutes remises en place)

| Mutation | Test qui échoue |
|---|---|
| `observateur` forcé à faux (`salle_page.dart:235`) | `salle_test` : « un controleur sans micro entre… » et « tuteur temoin et administration… » (2 échecs) |
| Second pré-vol de l'admin visible désactivé (`salle_page.dart:266`) | `salle_test` : « enseignant, eleve et administration qui parle restent bloques » |
| `serree: false` dans `_Commandes` | `salle_200_test` : « teacher, 320 px, texte x1 » |
| `encreLibelle: null` dans `_Commande` | `salle_200_test` : les 4 cas « mot et icone a l encre du fond » (enseignant, élève, clair, sombre) |
| Nom de la Classe vidé dans `_CarteCoursAnnule` | `journee_test` : « ANNUL-VIS-1 : le cours annule du jour nomme la Classe… » |

Les tests sont discriminants.

## Points de la fiche, un par un

1. **CTRL-SON-1 (C5 = a)** ✅. `_CommandesControle` est supprimée (`salle_page.dart`, ancien bloc 996-1076). `salle_controleur_test.dart:80-89` exige l'absence des quatre libellés, en texte et en sens. La ligne BR-CT-20 existe dans `CT-BR.md:31`, le lexique marque P12 et P13 « retiré ».
2. **CTRL-AGRANDIR-1** ✅. `_agrandi`, `_SupportAgrandi` et le raccourci Échap sont retirés. Le test exige l'absence d'« Agrandir » et de « Réduire » (texte, sens, infobulle) et la présence de la colonne « Présence ». Capture 320 sombre : aucune commande en bas, la colonne de présence n'est pas remplacée.
3. **CTRL-PREVOL-1** ✅. Le micro n'est mesuré que pour élève, enseignant ou compte illisible (repli fermé). Le jeton tranche ensuite : `peutPublier` vrai relance le pré-vol et bloque sans micro. La salle attend la session résolue (`_roleDuCompte`). **Question** : l'admin visible avec voix reste bloqué sans micro ; c'est la recommandation « garder », appliquée et testée.
4. **SALLE-CORR-3** ✅ pour ce que dit le commit :
   - rangée serrée puis compacte : mesure par `LayoutBuilder` et `_largeurMot` au style `labelMedium`, le même que le mot du disque (`commande_salle.dart:258`) ;
   - encre du registre pour tous les rôles ;
   - titre du rappel à ×2 : `bandeauControleTitre`, `observationMuetteTitre`, sources dans `libelles_sources.json` (« à valider par le directeur ») ;
   - bandeau permanent dans la gouttière (`EdgeInsetsDirectional`, RTL tenu), test « bandeau permanent dans la gouttiere » ;
   - carte annulée : nom, puis `LienFleche` « Voir la Classe » (pas de second bouton plein).
5. **SALLE-200-2** ✅. Le `skip: reste` est supprimé. Le cas enseignant 320 ×1 passe : aucune exception, support ≥ 422 px, Quitter à l'écran.
6. **K-61 (320 ×1 et ×2, 4 bords)** ✅ avec réserve mineure. Les 4 rôles × 320/390 × ×1/×2 passent sans exception de mise en page. Le test vérifie Quitter sur 3 bords (gauche, droite, bas), pas le haut, et pas les autres disques un par un. Le débordement serait de toute façon levé par `takeException`.
7. **K-56 (jamais grisé)** ✅. Les commandes retirées ne sont pas rendues du tout. Le commentaire « un contrôle que le jeton refuse n'est pas rendu » est conservé dans `_rangee`.
8. **Aucune couleur nouvelle** ✅. Seules les paires existantes (`surfaceInverse.onBackground`) et les jetons `AppSpacing.xs/sm/md/lg`. Vérificateur : 39.
9. **R1 à R21 / règles du projet** ✅. 5 états de la salle inchangés. Aucun texte en dur (2 clés ajoutées avec leur source). Pas de bouton dans un bouton. RTL : `EdgeInsetsDirectional` pour le bandeau. Le rôle lu dans l'état de la page suit le précédent déjà présent (`salle_page.dart:182, 442, 481`) et le remède nommé par VERIF-CT-1 (mineur m2).
10. **Composant partagé `CommandeSalle`** ✅. Le changement ne joue que si `encreLibelle` est fourni. Seul `salle_page.dart:2066` le fournit. `dock_seance.dart`, `barre_support.dart` et la galerie ne bougent pas. Leurs tests ciblés passent (+559).

## Captures ouvertes

- `SALLE-CORR-3/salle_corr3_enseignant_320_x1_clair.png` : la rangée tient (Micro coupé, Caméra éteinte, Quitter), mots clairs lisibles. Bandeau « Cours enregistré » à 16 px. **Mais** « Présenté : page 42 sur 604 · 2:255 », le titre « Cette page n'a pas pu être lue » et « 42 / 604 » restent sombres sur fond sombre (R1).
- `SALLE-CORR-3/salle_corr3_enseignant_320_x2_sombre.png` : commandes compactes en icônes, bandeau sur deux lignes dans la gouttière. Le titre d'erreur, « Présenté… » et la position sont **invisibles** (clair sur clair) (R1).
- `SALLE-CORR-3/salle_corr3_enseignant_390_sombre.png` : même constat. Commandes lisibles.
- `SALLE-200-2/salle_corr3_enseignant_320_x1_sombre.png` : rangée entière à l'écran, même défaut du support.
- `SALLE-CORR-3/salle_corr3_controleur_320_x2_clair.png` : rappel « Visite de contrôle. » en toutes lettres, Quitter en icône, rien ne déborde.
- `SALLE-CORR-3/salle_corr3_eleve_320_x1_sombre.png` : Micro coupé et Quitter lisibles sur fond clair.
- `SALLE-CORR-3/salle_corr3_journee_annule_320_x2_clair.png` : « Annulée », « An-Nour », horaire barré, « Voir la Classe → » ; aucun mot coupé.
- `CTRL-AGRANDIR-1/ctrl_agrandir1_salle_320_sombre.png` : aucune commande en bas, Quitter en haut. Le ruban « Démonstration » chevauche le coin du bouton Quitter (m5).
- `CTRL-PREVOL-1/ctrl_prevol1_salle_390_clair.png` : contrôleur entré sans micro, rappel entier, Quitter.
- `CTRL-SON-1/ctrl_son1_salle_1440_sombre.png` : état intermédiaire où seul « Agrandir » reste, icône invisible dans son disque. Cet état est retiré par le commit suivant (m6).

## Défauts retenus

### Réserve importante (antérieure au lot, hors de ses fiches)

- **R1. Support de l'enseignant illisible dans la salle.** Ce défaut n'est pas introduit par ce lot. Il est nommé dans le relevé VERIF-CORR-2 (`salle_ens_320_x1_sansvideo`) avec les mots des commandes, mais seul ce dernier point a été corrigé. Il reste visible dans les propres captures de preuve du lot :
  - en clair : sombre sur sombre ;
  - en sombre : invisible ;
  - textes concernés : « Présenté : page N sur 604 », le titre d'erreur, la position « 42 / 604 ».

  Aucune étape ne le porte sur `pilotage/tuteur-v1` (recherche faite). **Étape proposée : SALLE-CORR-4**, avant TB-F : poser les textes du panneau de support de `/salle` sur l'encre du registre `salle`, avec un test d'encre comme celui des commandes et des captures 320 ×1/×2 clair et sombre.

### Mineurs

- m1. Clés devenues orphelines dans le code : `salle.visiteControle.sonRecu/sonCoupe/couperSon/retablirSon/agrandir/reduire`. Elles ne restent lues que par les tests d'absence. On peut les garder pour BR-1, mais il faut l'écrire dans le lexique pour `agrandir/reduire`.
- m2. `_roleDuCompte` lit un `AppRole` dans l'état de la page. Le précédent existe et VERIF-CT-1 l'a demandé, mais la règle « capacité, pas rôle » mériterait une capacité « observe sans parler » quand le port le permettra.
- m3. `_roleDuCompte` attend sans délai une session résolue. Le routeur ne mène pas à `/salle` avant, donc c'est sans effet visible aujourd'hui. Non mesuré.
- m4. Le test K-61 de `salle_200_test.dart:163-170` ne vérifie pas le bord haut, ni les disques autres que Quitter.
- m5. Ruban « Démonstration » posé sur le coin de Quitter en démo (antérieur).
- m6. Les captures CTRL-SON-1 montrent l'état intermédiaire (Agrandir à icône invisible). C'est exact pour l'historique mais trompeur seul : à signaler dans un LISEZMOI.
- m7. La carte annulée n'a pas de capture 320 ×1 (×2, 390, 1440 seulement).
- m8. Les titres `bandeauControleTitre` et `observationMuetteTitre` sont à valider par le directeur, comme l'indiquent leurs sources.

## Pour accepter

1. Fusionner `corrections/c1-salle` dans la branche commune. Régler le conflit de `strings_fr.g.dart` par `dart run slang`, puis relancer les tests ciblés de la salle.
2. Ouvrir l'étape **SALLE-CORR-4** pour R1 avant TB-F.
3. Mineurs m1 à m8 : à reprendre au fil de l'eau, aucun ne bloque.

## Contre-vérification

- **Relecteur** : second relecteur indépendant, session `01KyPAZg`, non auteur. Même worktree `/home/user/rv-c1-salle` @ `ecccd0cc`, aucune suite complète, `git status` propre à la fin.

### Majeurs du premier relecteur

Il n'en a retenu aucun. Rien à réfuter. Je n'en ajoute aucun : je n'ai trouvé aucun défaut visible introduit par le lot, ni aucune règle cassée par lui.

### Contrôles relancés

- `dart analyze --fatal-infos` : No issues found. `verifier_jetons` : **39**. `slang` et `build_runner` : aucun écart.
- Je n'ai relevé aucune couleur nouvelle. `CommandeSalle` ne prend que `encreLibelle.onBackground`, une paire qui existait déjà (`surfaceInverse`). Les écarts viennent de `AppSpacing`.
- K-56 : les commandes retirées ne sont pas rendues du tout (aucun `actif: false` ajouté).
- Question CTRL-PREVOL-1 : la recommandation « garder » est bien appliquée. `_sansMicro` ne sert qu'à l'élève (`salle_page.dart:497`). L'admin visible n'a donc pas de « continuer sans micro » et reste bloqué. C'est cohérent avec la recommandation.

### Mutations supplémentaires (remises en place)

| Mutation | Résultat |
|---|---|
| `_roleDuCompte` rend le rôle sans attendre une session résolue | `salle_test` échoue (2 tests : contrôleur sans micro, tuteur et admin en observation). L'attente est donc tenue, contrairement à ce que laissait croire m3. |
| `compte != null &&` retiré : un compte illisible devient observateur et entre sans micro | **Aucun test n'échoue** (`salle_test` + `controleur/`, +220). Le « repli fermé » annoncé par le commentaire de `salle_page.dart:229` n'est tenu par aucun test. |

### Captures ouvertes par moi

- `SALLE-CORR-3/salle_corr3_eleve_320_x2_clair.png` : compactes en icônes, Micro coupé et Quitter lisibles, rien ne déborde. **Mais** le bandeau permanent « Cours enregistré, visite de contrôle possible. » est gris sur le fond sombre de la salle, avec un contraste faible. La couleur est antérieure au lot (`_SurLaSalle` n'agit qu'en Mode Accessibilité). Le lot l'a seulement déplacé dans la gouttière. C'est la même famille de défaut que R1.
- `SALLE-CORR-3/salle_corr3_controleur_320_x2_sombre.png` : « Visite de contrôle. » en toutes lettres, Quitter en icône en haut, aucune commande en bas, aucun mot coupé.
- `SALLE-CORR-3/salle_corr3_journee_annule_320_x2_sombre.png` : « Annulée », « An-Nour », horaire barré, « Motif non communiqué », lien « Voir la Classe → ». Aucun mot coupé, un seul appel (un lien, pas un bouton plein).
- RTL : le lot ne contient aucune capture RTL. Le code utilise `EdgeInsetsDirectional` pour le bandeau, et `_largeurMot` utilise `Directionality.of`. Je n'ai rien mesuré en RTL.

### Ce que le premier relecteur a raté (mineurs, aucun ne bloque)

- m9. Le repli fermé du compte illisible n'est pas testé : la mutation survit. Il faut ajouter un cas `SessionState(resolue: true, role: null)` sans micro, qui doit rester bloqué.
- m10. Le bandeau permanent de la salle (élève et enseignant hors Mode Accessibilité) est gris sur fond sombre en clair (capture élève 320 ×2 clair). Il est antérieur au lot. Il faut l'ajouter au périmètre de SALLE-CORR-4 avec R1.
- m11. Le contour des bascules à contour seul (`borderStrong`, `borderResting`) reste celui du thème, alors que l'icône prend désormais l'encre du registre. Le contour est visible dans les captures, mais aucun test ne vérifie son contraste sur le fond de la salle.
- m12. Pour l'admin visible, le pré-vol a lieu après l'émission du jeton (avant la connexion). Si l'émission du jeton est inscrite au journal, un admin bloqué y apparaît sans être entré. Non mesuré. À vérifier avec INTEG-RC-1.
- Correction de m3 : l'attente de la session est bien tenue par un test (voir la mutation). Seule l'absence de délai maximal reste à relever.

### Verdict après contre-vérification

**Inchangé : acceptée avec réserves.** Aucun majeur. R1 reste la réserve importante, avec m10 dans la même étape SALLE-CORR-4. Il faut ajouter m9 à m12 aux mineurs.

## Suite complète (session principale 01KyPAZg)

Suite dossier par dossier (`flutter test` par dossier de `test/`, captures ignorées) : c1-salle : 5372 réussis, 0 échec.
