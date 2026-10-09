// COUPE-MOTS-4 : l'hote commun des tests d'ecran de l'etape. Vraies
// polices du depot, vraie locale (l'arabe donne le sens RTL), 320 px de
// large et texte x2 par defaut, Interface standard ou guidee.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../../capture/outil_capture.dart';

/// Les deux langues mesurees : francais (LTR) et arabe (RTL).
const List<AppLocale> languesCoupeMots4 = <AppLocale>[
  AppLocale.fr,
  AppLocale.ar,
];

/// Les deux presentations mesurees.
const List<InterfaceMode> interfacesCoupeMots4 = <InterfaceMode>[
  InterfaceMode.standard,
  InterfaceMode.enfant,
];

/// Le nom court d'une presentation, pour le nom d'un test.
String nomInterface(InterfaceMode i) =>
    i == InterfaceMode.enfant ? 'guidee' : 'standard';

/// A appeler dans `main` : charge les polices du depot et la locale arabe
/// (differee) une fois, hors du `FakeAsync` des tests.
void preparerCoupeMots4() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
}

/// Monte [construire] (appele APRES le changement de locale, pour que ses
/// libelles soient ceux de [langue]) a [largeur] px, texte [echelle].
Future<void> monterCoupeMots4(
  WidgetTester tester,
  Widget Function() construire, {
  required AppLocale langue,
  List<Override> surcharges = const <Override>[],
  InterfaceMode interface = InterfaceMode.standard,
  double largeur = 320,
  double hauteur = 4000,
  double echelle = 2,
}) async {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  fixerVueCapture(tester, Size(largeur, hauteur), 1);
  await tester.pumpWidget(
    hoteCapture(
      construire(),
      surcharges: surcharges,
      echelleTexte: echelle,
      interfaceMode: interface,
    ),
  );
  await stabiliser(tester);
}
