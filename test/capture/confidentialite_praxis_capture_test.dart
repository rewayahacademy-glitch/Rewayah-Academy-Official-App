// CONFIDENTIALITE-PRAXIS (20/11/2026) : la politique de confidentialite avec
// la mention de l'assistant Praxis (points 3, 4, 6 et 8), en francais,
// anglais et arabe, et la ligne de version 2026-11-v2. Vue haute de 390 pour
// montrer la page entiere (une capture n'est que la fenetre, LISEZ-MOI).
//
//   CAPTURE_DIR=docs/current/captures/E2E/confidentialite-praxis \
//     flutter test test/capture/confidentialite_praxis_capture_test.dart
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/juridique/juridique_pages.dart';
import 'package:rewayah_academy/features/juridique/textes_juridiques.dart';

import 'outil_capture.dart';

void main() {
  for (final AppLocale langue in <AppLocale>[
    AppLocale.fr,
    AppLocale.en,
    AppLocale.ar,
  ]) {
    // La langue se change hors du `FakeAsync` de `testWidgets` (sinon le test
    // pend) : un groupe par langue, reglee dans `setUpAll`.
    group(
      'Capture : confidentialite et assistant Praxis, ${langue.languageCode}',
      skip: sautSansCapture,
      () {
        setUpAll(() async {
          await chargerPolicesDuDepot();
          await LocaleSettings.setLocale(langue);
        });
        tearDownAll(() => LocaleSettings.setLocale(AppLocale.fr));

        testWidgets('la page entiere', (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(390, 7600), 1);
          await tester.pumpWidget(
            hoteCapture(
              const TexteJuridiquePage(texte: TexteJuridique.confidentialite),
            ),
          );
          await stabiliser(tester);
          final j = t.juridique.confidentialite;
          for (final String bloc in <String>[
            j.s3.blocs.last,
            j.s4.blocs.last,
            j.s6.blocs.last,
            j.s8.blocs[3],
          ]) {
            expect(find.textContaining(bloc.substring(2, 40)), findsOneWidget);
          }
          expect(find.textContaining('2026-11-v2'), findsOneWidget);
          await capturer(
            tester,
            'confidentialite_praxis_${langue.languageCode}_390',
          );
        });
      },
    );
  }
}
