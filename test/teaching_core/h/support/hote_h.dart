import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, alors que `ProviderScope.overrides` en attend une liste.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

/// L'hote de test du lot H.
///
/// **Volontairement separe de `test/support/harnais.dart`.** La decision `D-06`
/// interdit aux neuf agents paralleles d'ecrire dans le harnais partage, deja
/// modifie par le chantier enseignant : chacun pose son propre hote sous
/// `test/teaching_core/<lettre>/support/`. Agent Z consolidera a l'integration,
/// pas avant.
///
/// Il monte exactement ce dont les surfaces du lot H ont besoin : la portee des
/// providers, le fournisseur de traductions -- que les composants partages
/// lisent -- et le theme du produit.
///
/// **Une coquille est posee autour de l'enfant, et c'est voulu.** Les surfaces
/// du lot H ne sont pas des ecrans : elles remplissent des slots que d'autres
/// pages possedent (l'Espace Groupe d'Agent A, la fiche d'Agent E, le cahier du
/// chantier enseignant). Ces pages passent toutes par `PageShell`, qui apporte
/// la surface `Material` et le defilement. Le test doit donc les apporter aussi,
/// sans quoi il mesurerait un montage que personne ne produira jamais.
Widget hoteH(
  Widget enfant, {
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(mode, Brightness.light),
      home: Scaffold(body: SingleChildScrollView(child: enfant)),
    ),
  ),
);

/// Mesure sur un telephone reel, jamais sur la surface par defaut de
/// `flutter_test` (800 x 600, c'est-a-dire une tablette).
///
/// 390 x 844 est le gabarit de reference du produit : une fenetre plus haute
/// cacherait les depassements au lieu de les montrer.
void telephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
