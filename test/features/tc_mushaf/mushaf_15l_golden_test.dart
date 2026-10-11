// MUSHAF-15L : goldens des pages 1, 2, 50, 293 et 604, en 390 et 1440, clair et
// sombre. Rendus avec les polices du depot (UthmanicHafs chargee depuis le
// fichier) ; comparaison a l'identique, sur Linux seulement : le moteur de
// texte d'une autre plateforme ne dessine pas au pixel pres (CI et sessions
// cloud sont sous Linux).
//
// Regenerer : `flutter test --update-goldens test/features/tc_mushaf/
// mushaf_15l_golden_test.dart`, puis relire les images (`git diff --stat`).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../capture/outil_capture.dart';
import '../../support/mushaf_15l.dart';

void main() {
  final Object saut = Platform.isLinux
      ? false
      : 'goldens du Mushaf generes sous Linux seulement';

  group('MUSHAF-15L : goldens', skip: saut, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await chargerPoliceMadina15();
    });
    setUp(masquerRubanDebug);

    for (final int page in <int>[1, 2, 50, 293, 604]) {
      for (final (String nom, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode theme in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String sombre = theme == ThemeMode.dark ? 'sombre' : 'clair';
          testWidgets('page $page $nom $sombre', (WidgetTester tester) async {
            await monterPageMadina15(
              tester,
              page: page,
              taille: taille,
              theme: theme,
            );
            await expectLater(
              find.byKey(cadreCapture),
              matchesGoldenFile(
                'goldens/mushaf_15l/p${page}_${nom}_$sombre.png',
              ),
            );
          });
        }
      }
    }
  });
}
