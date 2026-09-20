import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, alors que `ProviderScope.overrides` en attend une liste.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

/// L'hote minimal d'un ecran de la Bibliotheque sous test.
///
/// **Ecrit ici et non dans `test/support/harnais.dart`** : ce fichier de
/// 40,5 Ko est partage par tout le depot et deja modifie par le chantier
/// enseignant. Chaque agent Teaching Core ecrit ses propres faux sous
/// `test/teaching_core/<lettre>/` (decision D-06) ; Agent Z consolidera a
/// l'integration, pas avant.
///
/// Le theme est indispensable : `AppPalette.of` et `AppMetriques.of` lisent des
/// extensions de theme, et un ecran monte sans elles echoue avant d'avoir rendu
/// quoi que ce soit. `TranslationProvider` l'est aussi : `PageShell` monte
/// `OfflineBanner`, qui lit une cle slang.
Widget hoteB(
  Widget enfant, {
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(mode, Brightness.light),
      home: enfant,
    ),
  ),
);

/// L'hote d'un ecran qui navigue.
///
/// Le `GoRouter` est construit **ici**, dans `test/`, et non dans `lib/` :
/// `tool/verifier_jetons.dart` fait echouer la CI des qu'un second fichier de
/// `lib/` en construit un (decision D-04).
Widget hoteRoutantB({
  required String depart,
  required List<RouteBase> routes,
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp.router(
      theme: AppTheme.pour(mode, Brightness.light),
      routerConfig: GoRouter(initialLocation: depart, routes: routes),
    ),
  ),
);

/// La fenetre du telephone de reference : 390 x 844.
///
/// Fixee, et non laissee a la taille par defaut de `flutter_test` (800 x 600),
/// parce qu'un catalogue se juge sur la surface ou il sera reellement lu.
void fenetreTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Une fenetre haute, le temps d'un test.
///
/// `tester.tap` ne touche rien hors du viewport : sans elle, une carte posee
/// sous le pli ne serait pas atteignable, et le test mesurerait la hauteur de
/// la fenetre au lieu du comportement de l'ecran.
void fenetreHaute(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
