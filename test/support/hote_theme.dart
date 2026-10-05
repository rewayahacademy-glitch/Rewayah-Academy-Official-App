import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import 'harnais.dart';

/// Les trois vues de reference des composants partages du chantier Tuteur V1.
const Size vueMobile = Size(390, 844);

/// Tablette (rail replie, feuille bornee).
const Size vueTablette = Size(800, 1000);

/// Bureau (barre laterale, boite de dialogue).
const Size vueBureau = Size(1440, 900);

/// Fixe la vue logique, a densite 1, pour la duree du test.
void fixerVue(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// L'hote d'un composant, dans le vrai theme clair ou sombre et a une echelle
/// de texte donnee.
///
/// Les deux themes sont ceux de l'application (`AppTheme.pour`) : un
/// composant qui lirait une couleur hors de la palette ne changerait pas d'un
/// theme a l'autre, et les tests le voient. Le reseau est fige en ligne.
Widget hoteTheme(
  Widget enfant, {
  Brightness luminosite = Brightness.light,
  double echelleTexte = 1,
  List<Override> surcharges = const <Override>[],
  bool defilant = true,
}) => ProviderScope(
  overrides: <Override>[
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    ...surcharges,
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
      themeMode: luminosite == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (BuildContext context, Widget? app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(echelleTexte)),
        child: app!,
      ),
      home: Scaffold(
        body: SafeArea(
          child: defilant
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: enfant,
                )
              : enfant,
        ),
      ),
    ),
  ),
);
