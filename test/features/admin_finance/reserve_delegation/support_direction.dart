// Le support des tests des panneaux Direction (CPT-DIR-1).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../../../router/support_routeur.dart';
import '../../../support/harnais.dart';

/// Monte [enfant] dans une page defilante, au texte [echelle], dans le sens
/// [sens] et la luminosite [luminosite].
Widget hoteDirection(
  Widget enfant, {
  List<Override> surcharges = const <Override>[],
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
  Brightness luminosite = Brightness.light,
  bool horsLigne = false,
}) => ProviderScope(
  overrides: <Override>[
    // La bascule des montants lit la session (remise a « masque » a chaque
    // nouvelle session) ; ces surcharges portent aussi le faux reseau.
    ...sessionDirection(),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
    ...surcharges,
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
      themeMode: luminosite == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (BuildContext context, Widget? app) => Directionality(
        textDirection: sens,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(echelle)),
          child: app!,
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: enfant,
          ),
        ),
      ),
    ),
  ),
);

/// Fixe la taille de la fenetre de test.
void taille(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Tous les textes rendus.
List<String> textes(WidgetTester tester) => <String>[
  for (final Element e in find.byType(RichText).evaluate())
    (e.widget as RichText).text.toPlainText(),
];

/// Les surcharges de session d'un administrateur, pour monter la page dans la
/// demonstration (la bascule des montants lit la session).
List<Override> sessionDirection() =>
    surchargesRouteur(FausseSourceSession(sessionActive(AppRole.admin)));
