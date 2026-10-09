<!-- verdict : ACCEPTEE -->
<!-- verdict : ACCEPTEE -->
# Relecture adverse : CARTES-PERSO-1c (branche `corrections/c2-cartes-perso-c` @ 4600d4ca)

**Verdict : ACCEPTÉE.** Les trois points demandés sont traités. Les deux corrections de code sont prouvées par mutation, et la suite `test/features` + `test/router` passe sans échec. Je n'ai trouvé aucun défaut majeur.

Statut de preuve : testé localement dans un worktree jetable détaché sur `origin/corrections/c2-cartes-perso-c`, retiré à la fin. Pas testé sur staging, rien de déployé. Je n'ai rien poussé.

## Périmètre et forme
- **Base** : la branche part de `5a52ff30`, la tête de `corrections/revue-directeur-2026-10`. Elle compte 3 commits : `a3654c09`, `5f5aee24` et `4600d4ca`.
- **Fichiers touchés** :
  - code : `bloc_cartes_classe.dart`, `feuille_carte_classe.dart`, `mode_demonstration.dart` ;
  - tests : `cartes_classe_test.dart` et `demo_admin_cartes_test.dart` (nouveau) ;
  - script de capture `test/capture/cartes_perso1c_capture_test.dart` ;
  - fiche `DASH_STRATEGIE.md` §3.9 ;
  - 11 PNG et 2 scripts archivés, identiques aux originaux (vérifié avec `diff`).
- **Rien de touché** sous `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`, ni dans le thème, le Coran, ZoneSaisie ou les fichiers i18n.
- **Commits** : en français, terminés par les deux lignes exactes, sans autre identifiant de modèle.
- **Positions des surcharges** : la nouvelle surcharge vient après `demandesProvider`. Les tests qui remplacent `demo[1]` et `demo[2]` (`portRevueDossiersProvider` et `portPolitiqueRevueKycProvider`) ne sont donc pas décalés.

## Vérifications générales
- `dart analyze --fatal-infos` : aucun problème.
- `tool/verifier_jetons.dart` : 37 violations, plafond 37. Aucune dans les fichiers touchés.
- `tool/verifier_revue.dart` : 1532 violations. Sur `5a52ff30`, j'en mesure 1533 : il y en a une de moins, et aucune dans les fichiers touchés.
- Tests ciblés, avec `--concurrency=2` :
  - dossiers : `tc_espace_groupe`, `demo`, `classe_tuteur`, `ma_classe_adulte`, `admin_configuration`, `admin_dossiers`, `alertes` et `test/accessibilite` ;
  - fichiers : `admin_coque_test`, `dossiers_admin_demo_test` ;
  - résultat : **+817, 0 échec de test**. Le seul échec signalé vient d'un chemin que j'avais mal saisi (`test/features/fiche_groupe` est un fichier, pas un dossier). Ce fichier est repris dans la suite complète ci-dessous.
- Suite `test/features` + `test/router` : **+3342, 2173 sautés, 0 échec, « All tests passed! »**. Elle couvre tous les autres appelants de `BlocCartesClasse` (EspaceGroupePage, FicheGroupePage, MaClasseAdultePage, ClasseTuteurPage) et tous ceux de `surchargesDemoAdmin`, soit une vingtaine de tests. Les tests sautés sont pour la plupart des captures, sautées faute de `CAPTURE_DIR`.

## Point 1 : sens de lecture des lignes d'échéance
- **Correction** : `isolerSens(...)` entoure :
  - la ligne « Échéance : {date} » du bloc (`VueCarteClasse`) ;
  - la ligne de la feuille, qui affiche « Échéance : {date} » ou « Aucune échéance ».
- **Nouveau groupe de tests** « echeance, rtl » (3 tests). Chacun vérifie :
  - que le texte affiché est exactement `isolerSens(libellé)` ;
  - qu'en RTL, une fois le libellé terminé par un point, la boîte du point se trouve à droite de la première lettre, sur une seule ligne.
- **Mutation A** : `bloc_cartes_classe.dart` remis à `5a52ff30` → 2 échecs (bloc).
- **Mutation B** : `feuille_carte_classe.dart` remis → 4 échecs : les 2 du groupe RTL et 2 assertions de feuille existantes.
- **Contre-épreuve** : ancien code et égalité neutralisée (`if (false)`) → les 3 tests échouent sur la position du point (« le point de « Échéance : Lundi 12 octobre. » doit rester a la fin »). La mesure géométrique est donc probante par elle-même.
- **Captures ouvertes** :
  - `bloc_famille_echeances_320x2_ar_rtl_clair` (vue en entier, en deux morceaux) ;
  - `feuille_aucune_echeance_320x2_ar_rtl_sombre` (2 morceaux sur 4) ;
  - `feuille_devoir_echeance_320x2_ar_rtl_clair` (2 morceaux sur 4).

  Elles font 640 px de large, soit 320 px avec le texte x2. Les lignes d'échéance sont alignées à droite en RTL. Aucun mot n'est coupé.

## Point 2 : démonstration de la direction
- **Correction** : `surchargesDemoAdmin` surcharge `portCartesClasseProvider` avec `PortCartesClasseDemo(peutModifier: false, cartes: cartesClasseDemo(DateTime.now()))`. C'est la même forme que pour le tuteur. La lecture est seule, il n'y a aucune écriture simulée, et CARTES-BR-02 reste du côté serveur.
- **Le test 1 monte la vraie démo direction**, comme `lib/main.dart` (l. 102-117) :
  - `ProviderScope` avec `surchargesDemoAdmin(etat: etatRevueDemoPour(...), avecAlertes: true, arriveeAlerte: ...)`, puis `RewayahApp` et `RepereDemonstration` ;
  - il vérifie que le port est un `PortCartesClasseDemo`, que les titres et leur ordre sont ceux de la démonstration, que `peutModifier` est faux, et qu'un retrait lève une `StateError`.
- **Le test 2** rend `BlocCartesClasse` sous les surcharges réelles de la direction. Il vérifie qu'il y a 3 cartes, que `onModifier` est nul, qu'il n'y a pas de bouton Ajouter et qu'aucune feuille ne s'ouvre au toucher.
- **Mutation C** : surcharge supprimée → les 2 tests échouent.
- **Mutation D** : `peutModifier: true` → les 2 tests échouent.
- **Capture ouverte** : `demo_direction_bloc_390_ar_rtl_clair`. On y voit les 3 cartes avec leurs pictogrammes et « Copier le lien de « Récitation modèle » ».
- **Fiche** : la mention « décidé par délégation le 09/10 (règle DIR-REP-1) » est présente.

## Point 3 : le lien se copie
`pubspec.yaml` n'est pas touché. Le paragraphe « Reste » de CLS-CARTES consigne que le lien se copie et renvoie l'ajout de `url_launcher` à un arbitrage. La reprise 1c le rappelle aussi.

## Réserves mineures, sans effet sur le verdict
1. En locale `ar`, les libellés des cartes s'affichent en français (repli de traduction). C'est antérieur à cette étape et déjà visible en 1b. Le sens RTL est correct.
2. Aucun écran de la direction n'affiche encore le bloc des cartes. Le rédacteur l'a consigné. La surcharge prépare cet écran et est prouvée par les deux tests.

## Compte rendu du rédacteur
Les affirmations vérifiées sont exactes : contre-épreuves, 37 jetons, 1532 contre 1533, 11 captures, scripts archivés. La suite complète qu'il n'avait pas pu finir est désormais faite pour `test/features` + `test/router` : 0 échec.
