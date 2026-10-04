# Revue croisée C1-MA-R : Mode Accessibilité, décisions A3, A4, A5, A7, A8

- **Objet revu** : `corrections/c1-ma` @ `d7202977` (base `af20f6c2`), 4 commits, 120 fichiers (+1986 −203), dont 78 captures.
  - `7fba9cf7` MA-CORAN-TETE-1, `b8e302b0` MA-APRES-1, `d00c583b` MA-DEC-1, `d7202977` MA-TUTOIEMENT-1.
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit ce lot (auteur : `268bd1ef`).
- **Date** : 4 octobre 2026.
- **Références** : `verifications/2026-10-03/VERIF-MA-1/RAPPORT.md` (pilotage, l. 62-67 et 123-139 : décisions A3, A4, A5, A7, A8 de la feuille du 27/09 et les trois étapes) ; `18_supports_tableau/00_REPRISE.md` (MA-CMD-1) ; Bible V2 ; `lib/CLAUDE.md`.
- **Méthode** :
  - lecture du diff complet ;
  - contrôles relancés dans le worktree détaché `/home/user/rv-c1-ma` (aucun commit, aucun push) ;
  - six mutations ciblées et une sonde, toutes remises en place (`git status` vide à la fin) ;
  - neuf captures ouvertes ;
  - fusion à blanc avec la branche commune.

## Verdict

**Refusée** (confirmé par la contre-vérification, voir la dernière section). Le majeur M1 est confirmé et il est plus large que décrit : en production, l'écran de fin dit **toujours** « Ta prochaine séance n'est pas encore programmée. ». Un second majeur est ajouté (N2, lecteur du Coran à texte x2).

Après « Quitter » pendant une séance **en direct**, l'écran de fin unique dit « Ta prochaine séance n'est pas encore programmée. » quand l'élève n'a pas de travail. C'est faux pour une Classe qui a des séances chaque semaine. C'est le cas le plus courant, car la vraie salle ne connaît qu'une seule sortie : « Quitter » (`salle_page.dart:318`).

Tout le reste est tenu :

- le rendu du Coran n'a pas bougé (golden `q08` vert) ;
- A3, A4, A5, A7 et A8 sont appliquées ;
- MA-CMD-1 tient ;
- l'en-tête du lecteur reste sur une ligne à texte x2 ;
- les tests sont discriminants.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK (code 0) |
| `dart analyze --fatal-infos` | **0 problème** |
| `dart run tool/verifier_jetons.dart \| grep -c "\["` | **39**, le chiffre attendu |
| `test/core/accessibilite`, `test/features/salle_seance`, `classe_live_page_test`, `ma11_technique_test` | **611 réussis**, 361 sautés (captures), 0 échec |
| Écrans voisins : `ma_classe_adulte`, `classe_eleve`, `salle_test`, `salle_200_test`, `accessibilite_recette`, `demo`, `teaching_core/e` | **314 réussis**, 131 sautés, 0 échec |
| Rendu du Coran : `teaching_core/c`, golden `q08_coran_page`, `test/coran`, `test/i18n`, `test/tool` | **172 réussis**, 0 échec |
| Mutation 1 : le lecteur MA repasse au tutoiement pour l'adulte (`coran_accessibilite.dart`) | `coran_tutoiement_ma_test` échoue (« idriss, indisponible : vouvoiement », x2 et grand texte) |
| Mutation 2 : la vraie salle ne monte plus l'écran MA (`salle_page.dart:489`) | `ma_apres1_test` échoue (4 cas au moins, dont « vide, aucune séance programmée ») |
| Mutation 3 : en-tête remis à `maxLines: 2` sans réduction | `coran_ma7_test` : **2 échecs** (« commandes de page : 390 px, texte x2.0 ») |
| Mutation 4 : pastille des places toujours affichée (A5) | `ma_classe_ma4_test` échoue (« texte x2.0 : … une seule ligne d'état ») |
| Mutation 5 : `DepuisClasseLive` ne passe plus l'âge | `classe_live_page_test` échoue (« guidée, âge inconnu, port neutre : vouvoyée ») |
| Mutation 6 : `DepuisSalle` ne passe plus l'âge | **Aucun échec** : voir r3, le paramètre n'est lu par aucun appelant élève |
| Sonde (fichier temporaire, supprimé) : vraie salle MA, Classe `EtatDemoClasse.enDirect`, aucun travail, « Quitter » | `apres.vide` affiché **1 fois**, « Prochaine séance » **0 fois**. Avec travail : « Prochaine séance » 0 fois |
| `git diff --stat` sur `tc_coran`, `coran` | vide. `tc_mushaf` : 3 fichiers (voir point 1) |
| Fichiers interdits (`supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`) | Aucun |
| Fusion à blanc avec `origin/corrections/revue-directeur-2026-10` | **2 conflits** : `lib/core/i18n/strings_fr.g.dart` (généré : relancer `dart run slang`) et `tool/libelles_sources.json` (ajouts en fin de fichier des deux côtés : garder les deux). Aucun conflit sur le code ni sur `tc_mushaf` |
| Suite complète | Non lancée (consigne : une seule fois, par la session principale) |

## Points de la fiche, un par un

| Point demandé | Constat |
| :--- | :--- |
| **Rendu du Coran intouché (tc_mushaf : seulement un paramètre de texte)** | ✅ sur le fond, avec la réserve r1. `textes_lecteur_coran.dart` (nouveau) est un `InheritedWidget` qui ne porte que deux phrases. `vue_page_mushaf.dart:342,351-352,361` et `vue_verset_agrandi.dart:70,78,85-86` lisent `enrobage?.x ?? t.eleve.coran.x` : sans enrobage, le texte d'origine reste. Golden `q08` vert. Mais le diff de `vue_page_mushaf.dart` contient aussi 8 reflows `dart format` sans effet (`_feuilletDe`, `_nombreFeuillets`, `allerA`, `math.max`, `CadrePageMushaf`, `LigneComposee`, `juz`, `NoticeComposition`) |
| **A3 = c** « Assalamou alaykoum, {prénom}. » | ✅ `fr.i18n.json:651`. Posé dans `TexteSansCoupure` (`accueil_accessibilite.dart:97`). Capture `accueil_mariam_320x2_light` : « Assalamou / alaykoum, / Mariam. », aucun mot coupé. Test `ma_dec1_salutation_test` |
| **A4 = a** vouvoyer l'adulte (lecteur du Coran et salle réelle) | ✅ Lecteur : `LecteurCoranAccessibilite(tutoiement:)` (`coran_accessibilite.dart:182-185`) pose `TextesLecteurCoran` (`:502-515`) ; clés `indisponibleDetailVous` et `absentDetailVous`. Salle : port neutre `PortAgeEleve` (`lib/core/accessibilite/age_eleve.dart`, K-09, aucun appel), lu par `SallePage:496` et `ClasseLivePage:682`. Mutations 1 et 5 prises. Réserve r2 sur l'âge inconnu |
| **A5 = a** progression montrée, nombre de places masqué | ✅ `espace_groupe_page.dart:229` `afficherCapacite: !(enPile && role == eleve)`, et l'écart disparaît avec la pastille (`:661`, `:684`). Capture `ma_classe_mariam_390x2_light` : plus de « 3 élèves sur 6 places ». Mutation 4 prise. Réserve r4 |
| **A7 = a** un seul écran de fin | ❌ partiel, **majeur M1**. La vraie salle monte bien `ApresSeanceSalle` en Mode Accessibilité (`salle_page.dart:487-509`) : plus de « Retour à l'accueil » ni de coche, titre « Tu as quitté la séance. », un seul bouton plein, les cinq états. Mais la prochaine séance n'apparaît jamais après « Quitter » pendant une séance en direct, et l'état vide dit alors une chose fausse (sonde ci-dessus) |
| **A8 = a** libellés existants réutilisés | ✅ « Reprendre ta lecture » et « Tu en étais page {page} » (`eleve.coran.*`), « Lire le Coran » (`accessibilite.accueil.lireCoran`), « Chargement », « Retour » (`commun`). Clés `ouvrir`, `reprendre`, `reprendreDetail`, `repriseRecherche*`, `lectureGrande`, `retour` retirées. Pendant la recherche, plus de bouton grisé (K-54) : seule la ligne « Chargement » reste. Capture `coran_idriss_390x2_light` : « Vous en étiez page 6 », « Reprendre votre lecture ». Réserve r5 sur `repriseErreur*` |
| **MA-CMD-1** | ✅ L'en-tête reste sur une ligne, retour en icône seule avec nom lu « Retour ». Les commandes restent dans `CommandesMasquables`. Le cas `coran_ma7_test` « MA-CMD-1 : 390, texte x2, grand texte = true, commandes compactes et masquables » est vert |
| **Texte x2** | ✅ En-tête du lecteur : un `FittedBox(scaleDown)` sur une ligne, sans points de suspension (même principe que MA-TITRE-1). Mutation 3 prise. Captures `coran_tete1_320x2_light` : « Al-Faatiha . Page 1 sur 604 » entier sur une ligne. `apres1_contenu_320_x2_dark` : « Tu as / quitté la / séance. », aucun mot coupé |
| Prochaine séance avec l'heure (mineur MA-6) | ✅ dans le composant : `libelleProchaine` (`apres_seance_accessibilite.dart:127-133`, `heureDeLAppareil`). Capture `contenu_1440_x1_dark` : « Lundi 28 septembre à 19:00 ». ❌ dans la vraie salle après une séance en direct (M1) |
| Cinq états (écran de fin) | ✅ `EtatApresSeance` (chargement, contenu, vide, erreur, hors ligne). Résultat, « Retour à la Classe », support et aide restent toujours. « Réessayer » est en niveau secondaire : un seul bouton plein (capture `erreur_390_x1_light`). Tests dédiés aux quatre états non nominaux |

## Règles du projet

- **Un seul bouton plein, jamais de bouton dans un bouton** : ✅ (écran de fin, entrée du Coran).
- **RTL** : ✅ `AlignmentDirectional` partout dans le nouveau code. Voir r6 pour un défaut ancien du rendu.
- **Aucune valeur inventée** : ✅ (jetons : 39).
- **Aucun texte en dur** : ✅ 14 clés nouvelles ou réécrites, toutes listées dans `tool/libelles_sources.json` avec leur source.
- **Capacité, pas rôle** : la condition A5 lit `espace.role` dans `LectureGroupe` (r4).
- **Port neutre en production** : ✅ `AgeEleveInconnu` par défaut ; la démonstration et les tests surchargent.

## Captures ouvertes (9)

- `MA-CORAN-TETE-1/ma_coran_tete1_320x2_light.png` : l'en-tête tient sur une ligne, titre réduit, entier.
- `MA-APRES-1/ma_apres1_contenu_320_x2_dark.png` : sombre bien sombre ; titre et phrase sans mot coupé ; bouton pleine largeur.
- `MA-APRES-1/ma_apres1_contenu_1440_x1_dark.png` : le travail (3 lignes), le support, puis « Prochaine séance : Lundi 28 septembre à 19:00 ». Attention : le banc est une Classe « à venir », donc cette « prochaine séance » est la séance que l'élève vient de quitter (M1).
- `MA-APRES-1/ma_apres1_erreur_390_x1_light.png` : phrase d'erreur complète, « Réessayer » en contour, un seul bouton plein.
- `MA-DEC-1/ma_dec1_accueil_mariam_320x2_light.png` : la salutation A3 passe à la ligne entre les mots.
- `MA-DEC-1/ma_dec1_ma_classe_mariam_390x2_light.png` : plus de pastille des places.
- `MA-DEC-1/ma_dec1_coran_idriss_390x2_light.png` : libellés A8 au vouvoiement.
- `MA-TUTOIEMENT-1/ma_tutoiement1_coran_adulte_indisponible_390_x1_light.png` : « Dès que le réseau revient, / .votre page se rouvre ici ». Le point est à gauche (r6).
- `MA-TUTOIEMENT-1/ma_tutoiement1_coran_adulte_absent_390_x2_light.png` et `..._320_x2_dark.png` : à x2, la phrase vouvoyée « Signalez-le : ce n'est pas vous. » n'est pas visible : elle est sous les commandes et sous la barre (r6).

## Défauts retenus

### M1 (MAJEUR) : l'écran de fin ment sur la prochaine séance après une séance en direct

- **Où** : `apres_seance_accessibilite.dart:428-442` (`ApresSeanceSalle`).
- **Cause** : la prochaine séance n'est retenue que si `horloge.debutUtc` est après `calculeeAUtc`. Or, quand l'élève quitte une séance en direct, l'horloge de la Classe porte **la séance en cours**. Donc `prochaine == null`. Sans travail, l'état devient `vide`.
- **Ce que l'élève lit** : « Ta prochaine séance n'est pas encore programmée. Elle s'affichera ici et dans ta Classe. » Pour une Classe hebdomadaire, c'est faux. Avec du travail, la section « Prochaine séance » n'apparaît jamais.
- **Preuve** : la sonde ci-dessus (vide = 1, prochaine = 0). Les tests et les captures ne couvrent que deux cas : une Classe « à venir », où la « prochaine séance » montrée est celle qu'on vient de quitter, et un groupe introuvable.
- **Étape proposée (MA-APRES-1b)** :
  - ne dire « pas encore programmée » que si l'on sait qu'aucune occurrence n'est prévue ;
  - sinon, une phrase neutre déjà validée ou à valider, par exemple « Ta prochaine séance s'affichera dans ta Classe. » ;
  - ou bien tirer l'occurrence suivante d'une source existante, si elle existe ;
  - ajouter un test et une capture depuis la vraie salle avec `EtatDemoClasse.enDirect`, avec et sans travail.

### Réserves (mineures ou cosmétiques)

- **r1 (cosmétique) : reflows `dart format` dans `vue_page_mushaf.dart`.** Le fichier est protégé (K-19), et la fiche demande seulement un paramètre de texte. Les huit hunks n'ont aucun effet (golden vert), mais ils grossissent le diff et exposent à des conflits. Remède : les retirer, ne garder que les 3 lignes du paramètre.
- **r2 (mineur, question au directeur) : un âge inconnu vouvoie, enfants compris, jusqu'à BR-1.** En production, le port neutre rend `inconnu`. Un enfant en Mode Accessibilité lit donc « Votre parent observe la séance. » et « Vous avez quitté la séance. ». Avant ce lot, il était tutoyé. Ce choix n'est écrit nulle part dans le pilotage. La phrase d'observation n'existe d'ailleurs que pour un élève mineur suivi par son tuteur. À faire trancher, ou à déduire de l'observation.
- **r3 (mineur) : le paramètre `age` de `DepuisSalle.vue` n'a aucun appelant élève.** `DepuisSalle.vue` ne sert qu'au récapitulatif de fin de l'enseignant (`salle_page.dart:283-293`). La mutation 6 ne fait rien échouer. Le message du commit (« DepuisSalle passe tutoiement à VueSeance ») promet plus que le code. Retirer le paramètre, ou le dire.
- **r4 (mineur) : A5 ne vaut que là où `enPile` est passé**, c'est-à-dire seulement dans la démonstration (`demo_classe_page.dart:460`). La vraie route (`routes_tc_a.dart:44`) ne le passe pas, donc l'élève voit encore « N élèves sur M places » dans l'Espace Groupe réel. C'est le même périmètre que MA-4, qui sera branché par MA-BR, mais il faut l'ajouter à la ligne MA-BR. La condition lit aussi `espace.role` au lieu d'une capacité.
- **r5 (mineur) : `repriseErreur` et `repriseErreurVous` sont gardées, et la question au directeur n'existe que dans le message du commit.** VERIF-MA-1 demandait de faire valider leur ajout « au lieu de les garder sans le dire ». Il faut une ligne dans `QUESTIONS` ou une entrée « à valider » dans `libelles_sources.json`.
- **r6 (défaut ancien, hors périmètre, étape proposée avec l'accord du directeur) : textes français des états vides du lecteur posés en RTL.** L'`EmptyState` est rendu sous la `Directionality(rtl)` du feuilleteur (`vue_page_mushaf.dart:132-136`). Le point final passe donc à gauche : « .votre page se rouvre ici », « .importé ». De plus, à x2, la phrase de détail est cachée sous les commandes et sous la barre. Ce défaut existait déjà à la base, et la vue est protégée (K-19). Mais il touche justement la phrase vouvoyée de ce lot. Étape proposée : `Directionality(ltr)` autour de l'`EmptyState` dans les deux vues, rendu du texte arabe inchangé, avec l'accord du directeur.

## Pour accepter

1. Corriger M1 (étape MA-APRES-1b ci-dessus), avec un test depuis la vraie salle en direct, avec et sans travail, qui échoue sur `d7202977`, et une capture 390 x1 et 320 x2.
2. Conseillé dans le même passage : retirer les reflows de `vue_page_mushaf.dart` (r1), et inscrire les questions r2 et r5.
3. À la fusion : relancer `dart run slang` pour `strings_fr.g.dart`, et garder les deux blocs ajoutés en fin de `tool/libelles_sources.json`.

## Contre-vérification (second relecteur, session 01KyPAZg, 4 octobre 2026)

Méthode : relecture de `ApresSeanceSalle`, des ports réels (horloge, groupes, travail) et des tests ; une sonde et une mutation dans `/home/user/rv-c1-ma`, toutes deux retirées (`git status` vide) ; 5 captures ouvertes ; fusion à blanc relancée. Le verdict reste **Refusée**.

### M1 : confirmé, et plus grave en production

J'ai essayé de le réfuter. Je n'y arrive pas.

- Le code le dit lui-même : « celle que l'élève vient de quitter, encore ouverte, ne l'est pas » (`apres_seance_accessibilite.dart:430-436`). Pendant une séance en direct, `prochaine` vaut donc `null`.
- **En production, c'est pire.** `HorlogeSeanceSupabase.suivre` rend un flux vide sans `sessionId` (`horloge_supabase.dart:116-119`). Or `ApresSeanceSalle` lit `horlogeGroupeProvider(id)`, qui n'en passe jamais. `GroupesSupabase` ne porte aucune horloge (`groupes_supabase.dart:20-23`). Donc `prochaine` vaut **toujours** `null` en production, que la séance soit en direct ou non.
- `portTravailAVenirProvider` vaut `null` en production (`port_travail_a_venir.dart:159-160`). `ApresSeanceSalle` écrase ce `null` en liste vide (`.value ?? const <SlotAction>[]`, `:420-424`). Le contrat écrit dit pourtant : « l'écran dit que le travail n'est pas encore relié, jamais rien à préparer » (`:165-167`).
- Bilan : en production, tout élève en Mode Accessibilité qui quitte une séance lit « Ta prochaine séance n'est pas encore programmée. Elle s'affichera ici et dans ta Classe. ». C'est faux pour toute Classe active. Juste au-dessus, l'écran dit « Tu pourras revenir tant qu'elle reste ouverte. » (capture `ma_apres1_vide_390_x1_light`).
- Sonde (fichier temporaire supprimé) dans la vraie salle, avec le groupe lu par `groupeDepuisLigne` (la forme de production, sans horloge) et aucun travail : `apres.vide` **1 fois**, « Prochaine séance » **0 fois**. Classe de démonstration `enDirect` avec travail : vide 0, « Prochaine séance » **0**. Les chiffres du premier relecteur sont reproduits.
- Le même `.value ?? []` fait aussi passer l'écran par l'état vide pendant que le travail se charge. Il n'y a pas d'état « chargement » à ce moment-là.
- **Test non discriminant (nouveau).** Mutation : la garde `horloge.debutUtc.isAfter(horloge.calculeeAUtc)` est retirée (la séance quittée redevient « la prochaine »). `ma_apres1_test`, `ma_tutoiement1_test` et `test/core/accessibilite` : **+91, All tests passed**. Aucun test ne mesure la règle qui fonde M1. Remis en place.
- **Étape MA-APRES-1b, précisée.** (a) Distinguer « travail non relié » (`null`) de « aucun travail » (liste vide), comme le reste du dépôt. (b) Ne dire « pas encore programmée » que si une source dit qu'aucune occurrence n'est prévue. Sinon, une phrase neutre, à faire valider (libelles_sources). (c) Tests depuis la vraie salle : groupe de forme production (sans horloge), port de travail `null`, et Classe `enDirect` avec et sans travail. Chaque test doit échouer sur `d7202977`.

### N2 (MAJEUR, nouveau) : à texte x2, les états sans texte du lecteur sont illisibles, et la mesure a été réduite au silence

- Captures du lot ouvertes :
  - `ma_tutoiement1_coran_adulte_indisponible_320_x2_dark` : le titre s'arrête à « Le texte n'a pas », la suite est sous les trois commandes et sous la barre. La phrase vouvoyée et « Réessayer » ne se voient pas du tout.
  - `ma_tutoiement1_coran_enfant_absent_320_x2_light` : « Cette page est vide » est coupé par les commandes ; le détail n'apparaît pas.
  - `ma_tutoiement1_coran_adulte_indisponible_verset_agrandi_390_x2_light` : la phrase vouvoyée est visible, mais **« Réessayer », seule action de l'état, est sous les commandes**.
- Cause : `_ContenuDePage` pose l'`EmptyState` dans un `Center` sans défilement (`vue_page_mushaf.dart:342-363`). Le cadre de page coupe ce qui dépasse. Les commandes de `CommandesMasquables` sont posées par-dessus.
- L'auteur le savait. `test/capture/ma_tutoiement1_capture_test.dart:30-62` exclut « Réessayer » de la mesure des mots coupés à 320 x2, et le commentaire dit « Défaut signalé dans le rapport de l'étape ». Ce signalement n'existe pas : ni dans les messages des 4 commits, ni dans `docs/` (le diff `docs` ne contient que des PNG), ni dans le pilotage (`git grep` vide).
- Les tests du lot (`coran_tutoiement_ma_test.dart:100-166`) tournent à 390 x1 seulement et vérifient `find.text`, qui trouve aussi un texte caché. Ils ne peuvent pas voir ce défaut.
- Le défaut est antérieur au lot et la vue est intouchable (fiche, `15_accessibilite/00_REPRISE.md:26`). Le lot ne peut pas le corriger seul. Mais il livre A4 sur une phrase qu'un adulte en grand texte ne peut pas lire, et il cache la preuve. C'est un défaut visible sur la surface du lot.
- **Étape proposée (MA-CORAN-X2-1)** : (a) tout de suite, écrire le défaut dans `QUESTIONS` et dans le rapport, et retirer « signalé dans le rapport » tant que ce n'est pas vrai ; (b) avec l'accord écrit du directeur, rendre l'état défilable et le poser en LTR (voir r6), ou bien placer ces états dans l'enrobage MA, hors du cadre de page ; (c) ajouter un test à 320 x2 qui vérifie que le détail et « Réessayer » sont dans la zone visible, au-dessus des commandes.

### Réserves du premier relecteur

- **r1 : confirmé, mais la règle citée est fausse.** 11 hunks dans `vue_page_mushaf.dart`. K-19 désigne `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`, les secrets (`17_finance/00_REPRISE.md:211`), pas `tc_mushaf`. La source est « Rendu intouchable » (`15_accessibilite/00_REPRISE.md:26`) et la fiche. Le remède ne change pas.
- **r2 et r5 : confirmés.** Aucune trace de « âge inconnu » ni de `repriseErreur` dans `origin/pilotage/tuteur-v1` (`git grep`).
- **r6 : remonté en majeur**, il est fondu dans N2 (en plus du point mal placé en RTL).
- r3 et r4 : non contestés.

### Contrôles relancés

| Contrôle | Résultat |
| :--- | :--- |
| Sonde M1 (vraie salle, groupe forme production, sans travail) | vide **1**, prochaine **0** |
| Sonde M1 (démonstration `enDirect`, avec travail) | vide 0, prochaine **0** |
| Mutation : garde `isAfter` retirée | **0 échec** (+91) : test non discriminant |
| Fusion à blanc avec `origin/corrections/revue-directeur-2026-10` | 2 conflits, identiques : `strings_fr.g.dart`, `tool/libelles_sources.json` |
| `git status` du worktree à la fin | vide |

### Pour accepter (mis à jour)

1. MA-APRES-1b, comme précisé ci-dessus, avec des tests en forme production qui échouent sur `d7202977`.
2. N2 : au minimum, le signalement écrit et la question au directeur ; la correction dans `tc_mushaf` attend son accord.
3. Ensuite, les réserves r1 à r5 comme indiqué par le premier relecteur.

## Suite complète (session principale 01KyPAZg)

Suite dossier par dossier (`flutter test` par dossier de `test/`, captures ignorées) : c1-ma : 5388 réussis, 0 échec.
