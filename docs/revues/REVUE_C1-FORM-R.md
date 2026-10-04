# Revue croisée C1-FORM-R : formulaires FORM-L2, FORM-L4-11-12, FORM-L5, FORM-L6

- **Objet revu** :
  - `corrections/c1-form-a` @ `2e1e4355` (base `af20f6c2`), 6 commits, 64 fichiers (+2267 −170), dont 45 captures. Étapes FORM-L2 et FORM-L4-11-12 (lots L4, L10, L11, L12).
  - `corrections/c1-form-b` @ `00b699da` (base `af20f6c2`), 2 commits, 55 fichiers (+1440 −135), dont 40 captures. Étapes FORM-L5 et FORM-L6.
- **Relecteur** : session `01KyPAZg`, non auteur (auteur : `268bd1ef`).
- **Date** : 4 octobre 2026.
- **Références** : recensement `05_recette/FORM-AUTO-1/RECENSEMENT.md` (lots L2, L4, L5, L6, L10, L11, L12) ; K-41, K-56 à K-59, K-61 (pilotage `origin/pilotage/tuteur-v1`) ; `lib/CLAUDE.md`.
- **Méthode** :
  - lecture des deux diffs ;
  - contrôles relancés dans chaque worktree (`/home/user/rv-c1-form-a`, `/home/user/rv-c1-form-b`) ;
  - tests ciblés seulement (pas de suite complète) ;
  - cinq mutations, toutes remises en place (`git status` propre dans les deux worktrees) ;
  - fusions à blanc ;
  - huit captures ouvertes.

## Verdict

**REFUSÉE** pour la branche `c1-form-a`, à cause de trois défauts majeurs :

1. Un test existant échoue : la galerie n'a pas d'entrée pour les deux nouveaux widgets partagés.
2. `ChampDate` contient un `onTap` nu : `verifier_jetons` passe de 39 à 40 violations.
3. À 320 px avec le texte ×2, le calendrier affiche « 2 » et « 3 » au lieu de « 20 » et « 30 ». La capture du dépôt de pièce coupe « Passepor / t ».

La branche `c1-form-b` serait acceptable seule, avec réserves. Elle n'a aucun défaut majeur.

> **Mise à jour après contre-vérification (second relecteur, voir la dernière section)** : verdict **REFUSÉE** maintenu. M1, M2 et M3 sont confirmés. M4 est confirmé comme défaut visible, mais il est antérieur au lot (`ChoiceCardGroup`, hors diff) : il sort des majeurs du lot et part au chantier COUPE-MOTS. Un majeur nouveau touche la branche `c1-form-b` : l'étiquette « Nom du nouveau cy… » est tronquée à 320 ×2 (N1). La branche b n'est donc plus acceptable seule en l'état.

## Contrôles relancés (chiffres mesurés)

| Contrôle | c1-form-a | c1-form-b |
|---|---|---|
| `dart run slang` | 0 | 0 |
| `build_runner` | 0 | 0 |
| `dart analyze --fatal-infos` | No issues found | No issues found |
| `verifier_jetons` (nombre de `[`, attendu 39) | **40** : nouvelle violation `lib/core/widgets/champ_date.dart:91 [ontap-nu]` | 39 |
| Tests propres à l'étape | `form_l2_selecteur_personne_test` + `form_l4_11_12_test` : **+22, 0 échec** | `feuille_niveau_test` + `formulaire_profil_eleve_test` + `inviter_conjoint_nom_test` : **+32, 0 échec** |
| Tests des écrans et composants voisins | 11 fichiers (connexion, dossier, navigation, observation de groupe, RTL et échelle, cartes collées, galerie, page d'étape, connexion élève) : **+172, 1 échec** : `catalogue_galerie_test.dart` « chaque fichier de lib/core/widgets a son entrée » (`'champ_date'` à la place de `'child_card'`) | `admin_pedagogie_programmes/`, `foyer/`, galerie, RTL, échelle tuteur, cartes collées : **+383 ~37, 0 échec** |
| `verifier_revue` sur les fichiers touchés | aucune nouvelle violation `bouton-grise` ni `libelle-sans-source`. `plein-multiple` reste au compte du socle (groupes 5, évaluations 3) | **une nouvelle violation `bouton-grise`** : `formulaire_profil_eleve.dart:626` (puces d'âge coupées pendant l'envoi). `plein-multiple` programmes : 4, égal au socle |
| Fichiers interdits (`supabase/`, `.github/`, `pubspec.yaml`, `vercel.json`) | 0 | 0 |
| Lecture serveur ajoutée (`rpc`, `from`, nouveau `FutureProvider`) | 0 | 0 |

**Mutations (toutes remises en place)** :

- A1. Filtre de rôle retiré dans `personnes_proposables.dart` : 4 échecs dans `form_l2`.
- A2. Bouton « Créer » de nouveau grisé tant que l'enseignant manque : 1 échec (« presser sans choix dit ce qui manque »).
- A3. Courriel non transmis à la récupération (`extra: null`) : 1 échec dans le lot L10.
- B1. Ordre déduit sans « +1 » : 2 échecs dans `feuille_niveau_test`.
- B2. Nom du titulaire non prérempli : 1 échec dans `formulaire_profil_eleve_test`.

Les tests mordent.

**Fusions à blanc** :

| Fusion | Résultat |
|---|---|
| tronc `corrections/revue-directeur-2026-10` (`08a27c2e`) + c1-form-a | conflit sur `lib/core/i18n/strings_fr.g.dart` et `tool/libelles_sources.json` |
| tronc + c1-form-b | conflit sur `lib/core/i18n/strings_fr.g.dart` et `tool/libelles_sources.json` |
| c1-form-a + c1-form-b | conflit sur `lib/core/i18n/strings.g.dart` et `tool/libelles_sources.json` |

Ces conflits sont mécaniques :

- les fichiers `.g.dart` se régénèrent avec `dart run slang` ;
- dans `libelles_sources.json`, chaque branche ajoute ses lignes en fin d'objet : il faut garder l'union, avec une virgule.

`fr.i18n.json` et tous les fichiers Dart se fusionnent sans conflit.

## Points de la fiche, un par un

1. **K-57 (proposer avant de faire saisir)** : ✅.
   - L2 : `SelecteurPersonne` remplace les identifiants tapés. Il sert dans trois feuilles : création de classe (enseignant), ajout d'élève, planification d'évaluation. La liste vient de `comptesProvider`, filtrée par rôle et par état actif ou provisoire, triée sans accent.
   - L4 : la date se choisit dans un calendrier, de aujourd'hui à +1 an.
   - L5 : le cycle se choisit en puces. L'ordre est déduit, avec un pas de ±1. Le code est généré depuis le nom.
   - L6 : le nom du titulaire est prérempli. L'âge se choisit en puces, de 3 à 18.
   - L10 : le courriel passe par `extra` et n'apparaît jamais dans l'URL.
   - L11 : la carte « Autre » à champ libre est remplacée par `TypePiece.autre`.
   - L12 : le libellé est prérempli et n'est jamais écrasé une fois écrit.
2. **Listes issues de lectures existantes, aucun serveur nouveau** : ✅.
   - `personnes_proposables.dart` est une projection de `comptesProvider` (`comptes_admin()`, déjà présent à la base).
   - L5 lit `niveauxProgrammeProvider`, et L6 lit `identiteTitulaireProvider`. Les deux existent à `af20f6c2`.
   - Aucun `rpc` ni `from` n'est ajouté.
   - Réserve : L5 lit `ref.read(...).value ?? []`. Si les niveaux ne sont pas encore chargés à l'ouverture de la feuille, aucune puce de cycle ne s'affiche et l'ordre vaut 1. Le cas est rare (la liste est affichée derrière), mais il n'est pas testé.
3. **K-56 (jamais grisé)** : ✅ sur les boutons visés. `groupes_page`, `evaluations_page`, `acces_agents_page` et `programmes_page` appellent toujours l'action, qui dit ce qui manque. Les trois lignes `bouton-grise` sont retirées de `tool/revue_socle.txt`. Un seul bouton plein par feuille ; « Modifier le code technique » est tertiaire. Deux réserves :
   - les puces d'âge de L6 passent à `onPress: null` pendant l'envoi. Le sens est acceptable (anti double envoi), mais `verifier_revue` le compte comme un nouveau `bouton-grise` ;
   - le bouton « Créer le profil » du foyer reste grisé hors ligne. C'est hors périmètre, cela existait avant.
4. **K-58 (phrase de contexte)** : ✅. Le sélecteur dit pourquoi seuls les comptes actifs figurent dans la liste. L'ordre est expliqué (« L'ordre proposé suit le dernier niveau du cycle choisi »). Le nom prérempli est expliqué (`nomAidePrerempli`).
5. **K-59 (échec : cause, suite, ce qui reste fiable)** : ✅.
   - L'erreur du sélecteur dit « Cause probable … (non confirmé). Réessayez » et propose une action Réessayer.
   - La liste vide dit quoi faire (Personnes > Comptes).
   - Une recherche sans résultat propose « Effacer la recherche ».
   - L5 : `ajouterNiveauErreur` cite le code en double comme cause possible.
6. **K-41 (langues)** : ⚠ conforme sur l'essentiel, avec deux réserves mineures. Toutes les chaînes passent par slang, sans `Text('…')` littéral. `ar.i18n.json` n'est pas complété, mais il ne compte que 98 clés pour 3906 en français : c'est l'état connu, avec repli sur `fr`. Les deux réserves :
   - `programmes_page.dart` assemble les manques avec `manques.join(', ')` : c'est une phrase par concaténation, et le séparateur est figé ;
   - `ChampDate.ecrire` impose le format `JJ/MM/AAAA`, qui est réutilisé dans `libelleAuto`.
7. **K-61 (320 ×2, captures)** : ❌ pour la branche a.
   - Chaque étape a bien ses captures 390, 1440 et 320 ×2, en clair et en sombre.
   - `form_l4_11_12_calendrier_320x1400@2_x2_dark.png` : les jours 20 et 30 s'affichent « 2 » et « 3 » (le second chiffre est coupé). L'en-tête « dim. 4 … » et le mois « octobre … » sont tronqués. Le plafond du texte à 150 % ne suffit donc pas. L'aide du champ, « Entre aujourd'hui et … », est coupée.
   - `form_l4_11_12_depot_320x1400@2_x2_dark.png` : « Passepor / t » est coupé au milieu du mot. Le composant existait avant, mais c'est l'écran de l'étape et la capture a été livrée comme preuve.
   - `form_l2_creation_320x1400@2_x2_light.png` : l'étiquette « Heure (… » est tronquée (champ de L3, existant).
8. **Libellés « à valider » dans `tool/libelles_sources.json`** : ✅. Tous les nouveaux libellés sont déclarés et `verifier_revue` ne signale aucun `libelle-sans-source` sur les nouvelles clés.
   - Branche a : 32 entrées, dont 7 marquées « à valider par le directeur » : `commun.selecteurPersonne.contexteEleve`, `contexteEnseignant`, `videEleveDetail`, `videEnseignantDetail`, `commun.champDate.aide`, `kyc.autrePiece`, `admin.agents.libelleAuto`.
   - Branche b : 17 entrées, toutes « à valider » : les 13 clés `admin.programmes.*` (dont `ajouterNiveauErreur` modifiée), `foyer.ajout.identite.nomAidePrerempli`, `foyer.ajout.identite.age`, `foyer.ajout.erreurs.ageRequis` et `adulte.invitation.nomAidePrerempli`.
9. **Contre-épreuves** : ✅. Les commits annoncent des tests rouges sur l'ancien code. Mes cinq mutations ont toutes fait échouer au moins un test.

**Captures ouvertes** :

- FORM-L2, création 320 ×2 clair : les cartes enseignant sont lisibles, l'identifiant est en description. L'étiquette « Heure (… » est tronquée.
- FORM-L2, évaluation 390 sombre : cartes élèves correctes. Cette capture montre encore « Date prévue (JJ/MM/AAAA) » : elle a été prise avant L4 et est donc périmée sur ce point, puisque L4 a ses propres captures.
- FORM-L4, calendrier 320 ×2 sombre : chiffres et en-tête coupés (voir plus haut).
- FORM-L4, jeton 390 clair : le libellé prérempli « Observation de Maryam, le 04/10/20… » déborde du champ sur une ligne. L'aide est tronquée à « qu… ».
- FORM-L4, jeton 320 ×2 clair : « ELV- / MS-010 » est coupé au tiret. Le champ ne montre que « Observation c ».
- FORM-L4, dépôt 320 ×2 sombre : « Passepor / t » est coupé. La carte « Autre pièce officielle » est correcte.
- FORM-L5, ajout 320 ×2 clair : puces de cycle, pas ±1 et phrase d'ordre corrects. Le code est coupé proprement au tiret.
- FORM-L6, âge 320 ×2 sombre : 16 puces sur 4 lignes, nom « Diallo » prérempli avec sa phrase, un seul bouton plein. Le « : » se retrouve en début de ligne (espace normale avant les deux-points).

**Composants partagés** :

- Branche a : deux nouveaux composants, `SelecteurPersonne` et `ChampDate`, sous `lib/core/widgets`. Ils ne sont utilisés que dans les écrans de l'étape. Aucun composant existant n'est modifié (`ChoiceCardGroup` est seulement réutilisé). Le changement de `app_router.dart` ne touche que la route de récupération ; `bienvenue_connexion_navigation_test` est vert.
- Branche b : aucun composant partagé modifié.

## Défauts retenus

| # | Gravité | Défaut | Preuve | Correction proposée |
|---|---|---|---|---|
| M1 | MAJEUR | La galerie n'a pas d'entrée pour `champ_date` ni `selecteur_personne` : le test existant échoue, et la CI (`flutter test`) sera rouge. | `test/widgets/catalogue_galerie_test.dart`, « chaque fichier de lib/core/widgets a son entrée » | Ajouter les deux entrées à la galerie (`lib/features/_dev/…` ou l'emplacement du catalogue). |
| M2 | MAJEUR | `onTap` nu dans `ChampDate` (`InkWell`), contre la règle « tout passe par Pressable ». `verifier_jetons` passe de 39 à 40. | `lib/core/widgets/champ_date.dart:91` | Envelopper le champ dans `Pressable` (focus, survol et état pressé du socle). |
| M3 | MAJEUR | Calendrier à 320 px, texte ×2 : les jours 20 et 30 sont rendus « 2 » et « 3 », et l'en-tête et le mois sont tronqués. | `form_l4_11_12_calendrier_320x1400@2_x2_dark.png` | Plafonner plus bas le texte de la grille des jours (par exemple 1,3), ou forcer `DatePickerEntryMode.input` quand le texte dépasse 1,5. Refaire la capture et l'ouvrir. |
| M4 | MAJEUR | Dépôt de pièce à 320 px, texte ×2 : « Passepor / t » est coupé au milieu du mot, sur la capture livrée comme preuve. | `form_l4_11_12_depot_320x1400@2_x2_dark.png` | Ne plus couper les mots dans le titre des cartes de `ChoiceCardGroup` à ×2 (même traitement que COUPE-MOTS-2), ou réduire l'écart avec la pastille radio. Refaire la capture. |
| m1 | mineur | Les puces d'âge à `onPress: null` pendant l'envoi créent un nouveau `bouton-grise` dans `verifier_revue`. | `formulaire_profil_eleve.dart:626` | Laisser les puces actives et ignorer le choix pendant `_envoi`, ou passer par `enCours`. |
| m2 | mineur | Phrase assemblée par `join(', ')`, et « Complétez-le » au singulier même quand plusieurs éléments manquent. | `programmes_page.dart` (`_envoyer`) ; `admin.programmes.manque` | Un message par manque, ou une clé au pluriel. |
| m3 | mineur | Vocabulaire mélangé : « Il manque le nom de la classe » à côté de « Nom du groupe » et « Créer le groupe ». | `fr.i18n.json` `admin.groupes.manqueNom` | Aligner sur le lot « groupe » → « classe » ou garder « groupe » ici. |
| m4 | mineur | Le libellé prérempli du jeton (environ 45 caractères) déborde d'un champ d'une ligne, même à 390 px. | `form_l4_11_12_jeton_390x844@3_light.png` | `maxLines: null` ou 2 sur ce champ. |
| m5 | mineur | Plafond du texte du calendrier à 150 %. Il y a des précédents (`nav_shell`), mais il n'est pas décidé pour ce composant. | `champ_date.dart:74` | À inscrire comme exception, ou à lever avec M3. |
| m6 | mineur | La capture FORM-L2 « évaluation » montre encore le champ `JJ/MM/AAAA`, aujourd'hui retiré. | `FORM-L2/form_l2_evaluation_*` | Régénérer après L4, ou l'indiquer dans la planche. |
| m7 | mineur | L5 : si les niveaux ne sont pas encore chargés, aucune puce de cycle ne s'affiche et l'ordre vaut 1. Le pas −1 descend aussi sous 1. | `programmes_page.dart` (`existants: ref.read(...)`, `_pas`) | Utiliser `ref.watch` dans la feuille et borner le pas à 1 au minimum. |
| m8 | mineur | Le séparateur « : » se retrouve en début de ligne dans `nomAidePrerempli`. | capture FORM-L6 âge 320 ×2 | Espace insécable avant « : ». |

## Pour accepter

1. Corriger M1 à M4 sur `corrections/c1-form-a`. Relancer `verifier_jetons` (39 attendu) et `catalogue_galerie_test` (vert). Refaire et ouvrir les captures calendrier et dépôt à 320 ×2, en clair et en sombre.
2. Traiter m1 sur la branche b, pour ne pas ajouter de ligne au socle `bouton-grise`.
3. À la fusion, résoudre `libelles_sources.json` par union et régénérer les fichiers `.g.dart` avec `dart run slang`.
4. Faire valider par le directeur les 24 libellés marqués « à valider » (7 sur la branche a, 17 sur la branche b).

## Contre-vérification

- **Relecteur** : second relecteur indépendant, session `01KyPAZg`, non auteur.
- **Date** : 4 octobre 2026.
- **Méthode** : chaque majeur est reproduit ou contesté. Une recherche de ce qui a été raté. Deux mutations à moi. Un test jetable en arabe (RTL), 320 px, texte ×2, en clair et en sombre, supprimé ensuite. Six captures ouvertes. `git status` est propre dans les deux worktrees.

### Les majeurs, un par un

| # | Constat | Preuve |
|---|---|---|
| M1 | ✅ **confirmé** | `flutter test test/widgets/catalogue_galerie_test.dart` : +15 −1. Le test « chaque fichier de lib/core/widgets a son entree » échoue. `champ_date.dart` et `selecteur_personne.dart` sont dans `lib/core/widgets`, mais n'ont pas d'entrée dans la galerie. |
| M2 | ✅ **confirmé** | `dart run tool/verifier_jetons.dart \| grep -c "\["` = **40** (39 attendu). La ligne ajoutée : `lib/core/widgets/champ_date.dart:91 [ontap-nu]`. C'est un `InkWell` nu sous `Semantics(button: true)`, sans `Pressable`, donc sans l'anneau de focus du socle. |
| M3 | ✅ **confirmé** | J'ai ouvert `form_l4_11_12_calendrier_320x1400@2_x2_dark.png`. Le 20 et le 30 s'affichent « 2 » et « 3 », décalés vers le haut : le « 0 » passe à la ligne et il est rogné. On voit aussi « dim. 4 … », « octobre … » et « Entre aujourd'hui et … ». Le défaut vient du lot (`showDatePicker` est ajouté par L4). Le plafond à 150 % (`champ_date.dart:74`) ne suffit pas. Aucun test ne peut le voir : mon test jetable à 320 ×2 ouvre le calendrier sans lever d'exception, car la cellule rogne sans signaler de débordement. Seule la capture le montre. |
| M4 | ❌ **rejeté comme majeur du lot**, gardé hors lot | Le défaut est réel : j'ai ouvert `form_l4_11_12_depot_320x1400@2_x2_dark.png`, et on y lit « Passepor / t ». Mais il est antérieur au lot. La carte « Passeport » existait déjà à `af20f6c2`. Le diff de `depot_piece_page.dart` ajoute seulement la carte « Autre pièce officielle » et retire la saisie libre. `choice_card_group.dart` n'est pas modifié. La règle suivie jusqu'ici (BENTO-2-R, BENTO-2b-R, BENTO-1c-R) envoie ces coupures du socle au chantier COUPE-MOTS, sans les compter contre le lot. Attention : aucune branche `c1-coupe`, `c2-coupe2` ni `c2-obs-coupe` ne touche `choice_card_group.dart`. Il faut donc ouvrir une ligne COUPE-MOTS pour `ChoiceCardGroup` (titre de carte à ×2), sinon le défaut ne sera suivi par personne. |

### Ce que la première revue a raté

- **N1 (MAJEUR, branche `c1-form-b`, FORM-L5)**. J'ai ouvert `forml5_erreur_320_x2_dark.png`. L'étiquette du champ ajouté par L5, `admin.programmes.champNouveauCycle`, se lit « Nom du nouveau cy… ». Elle est tronquée au milieu du mot, sur la capture livrée comme preuve de K-61. Le libellé et le champ sont nouveaux (diff `programmes_page.dart`, `labelText: t.admin.programmes.champNouveauCycle`). C'est le même défaut que l'auteur a lui-même corrigé dans `SelecteurPersonne` (« Chercher un … », passé en `hintText` avec `hintMaxLines: 6`). La première revue avait jugé cette capture correcte. Sur la même feuille, « Description (o… » est tronquée aussi, sur un champ que le lot a retouché. **Correction** : mettre le nom du champ en texte au-dessus du champ, ou dans une indication sur plusieurs lignes comme L2. Refaire la capture 320 ×2 et l'ouvrir.
- **n1 (mineur, branche a)**. Il n'y a aucune capture RTL pour les quatre étapes. Les deux nouveaux widgets n'ont aucune couverture RTL : ils manquent à la galerie (M1), et c'est la galerie qui porte le contrôle « en arabe, tout se rend en miroir ». Mon test jetable (`SelecteurPersonne` et `ChampDate` en `ar`, 320 ×2, clair et sombre) passe sans exception : +2, 0 échec. Le risque reste donc faible. Corriger M1 rétablit cette couverture.
- **n2 (mineur, branche a, existant)**. Sur `form_l4_11_12_jeton_320x1400@2_x2_dark.png`, l'étiquette « À quoi sert ce jet… », l'aide « Obligatoire. Un j… » et la recherche « Chercher … » sont tronquées. Ces trois champs n'ont pas été ajoutés par le lot, mais l'écran est celui de L12. Ils sont à porter à COUPE-MOTS, comme « Heure (… ».
- **Fusion à blanc des deux branches** : refaite. Le résultat est le même que dans la première revue : conflits sur `lib/core/i18n/strings.g.dart` et `tool/libelles_sources.json`. Ajout : `strings_fr.g.dart` se fusionne « tout seul », mais c'est un fichier généré. Il faut le régénérer avec `dart run slang` après la fusion, sans faire confiance à la fusion automatique.
- **Listes issues de lectures existantes** : ✅ confirmé. `SelecteurPersonne` reçoit un `AsyncValue` de l'appelant et ne lit rien lui-même.
- **Textes et couleurs** : aucun `Text('…')` en dur. La couleur d'erreur du jeton vient de `colorScheme.error`, et aucune couleur n'est inventée.
- **Bouton dans un bouton** : rien trouvé.

### Mutations du second relecteur (remises en place)

- C1. Borne du calendrier passée de +1 an à +2 ans (`champ_date.dart`, `dernierJour`) : 1 échec (« borne d'aujourd'hui a +1 an »).
- C2. Garde `_libelleSaisi` retirée de `_preremplir` (`acces_agents_page.dart`) : 1 échec (« un libelle ecrit a la main n'est jamais ecrase »).

Les tests du cœur du changement mordent. Aucun test ne voit M3 : seule la capture le montre.

### Verdict corrigé

**REFUSÉE**.

- **Branche a** : M1, M2 et M3 sont à corriger. M4 sort des majeurs du lot et part au chantier COUPE-MOTS (`ChoiceCardGroup`).
- **Branche b** : N1 est à corriger. C'est une petite correction, avec une capture 320 ×2 à refaire.
- Les mineurs m1 à m8 restent valables.

## Suite complète (session principale 01KyPAZg)

Suite dossier par dossier (`flutter test` par dossier de `test/`, captures ignorées) : c1-form-a : 5112 réussis et 1 ÉCHEC (test/widgets/catalogue_galerie_test.dart, « chaque fichier de lib/core/widgets a son entree ») ; c1-form-b : 5374 réussis, 0 échec.
