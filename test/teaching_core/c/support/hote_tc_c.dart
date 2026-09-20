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
import 'package:rewayah_academy/features/tc_mushaf/routes_tc_c.dart';

/// L'hote minimal d'un ecran du moteur Coran.
///
/// **Ecrit ici et pas dans `test/support/harnais.dart`** : ce fichier de 50 Ko
/// est partage par tous les lots et deja modifie par le chantier enseignant
/// (decision D-06). Agent Z consolidera a l'integration, pas avant.
///
/// Le theme est indispensable : `AppPalette.of` et `AppMetriques.of` lisent des
/// extensions de theme, et un ecran monte sans elles echoue avant d'avoir rendu
/// quoi que ce soit.
Widget hoteCoran(
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

/// Un hote routant, construit avec les routes que `routesTcC()` retourne.
///
/// **C'est ici que le `GoRouter` se construit, et nulle part dans `lib/`** :
/// `tool/verifier_jetons.dart` fait echouer la CI sur tout second `GoRouter`
/// de `lib/`, et `test/` n'est pas concerne (decision D-04).
Widget hoteCoranRoutant({
  String depart = RoutesCoran.mushaf,
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp.router(
      theme: AppTheme.pour(mode, Brightness.light),
      routerConfig: GoRouter(initialLocation: depart, routes: routesTcC()),
    ),
  ),
);

/// Pose la taille de la fenetre de test, et la restaure a la fin.
///
/// Les trois rendus dependent de la largeur : un test qui ne la fixe pas
/// mesure la taille par defaut de `flutter_test` (800 x 600) sans le savoir,
/// et le meme test passerait pour une raison differente de celle qu'il croit.
Future<void> poserFenetre(WidgetTester tester, Size taille) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
