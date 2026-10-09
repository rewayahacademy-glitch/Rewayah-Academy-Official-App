// PUB-1 : captures de preuve de la presentation publique. Premiere page
// (ligne d'etat a mi-course), page du parcours, derniere page (sorties vers
// la connexion), hors ligne. 320 texte x2 en LTR et RTL, 390, 1440 ; clair et
// sombre. Jamais sans `CAPTURE_DIR`.

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/preferences/presentation_vue.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/features/bienvenue/bienvenue_page.dart';

import 'outil_capture.dart';

List<Override> _surcharges({bool horsLigne = false}) => <Override>[
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  stockagePresentationProvider.overrideWithValue(StockagePreferencesMemoire()),
];

void main() {
  group('Capture : PUB-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (Size, ThemeMode, double, TextDirection) cas
        in <(Size, ThemeMode, double, TextDirection)>[
          (const Size(390, 844), ThemeMode.light, 1, TextDirection.ltr),
          (const Size(390, 844), ThemeMode.light, 1, TextDirection.rtl),
          (const Size(320, 700), ThemeMode.light, 2, TextDirection.ltr),
          (const Size(320, 700), ThemeMode.dark, 2, TextDirection.rtl),
          (const Size(1440, 900), ThemeMode.light, 1, TextDirection.ltr),
          (const Size(1440, 900), ThemeMode.dark, 1, TextDirection.ltr),
        ]) {
      final String suffixe =
          '${cas.$1.width.toInt()}${cas.$3 == 2 ? 'x2' : ''}_'
          '${cas.$2 == ThemeMode.light ? 'clair' : 'sombre'}'
          '${cas.$4 == TextDirection.rtl ? '_rtl' : ''}';
      // Le numero de page (0 a 4) et son nom.
      for (final (int, String) page in <(int, String)>[
        (0, 'p1'),
        (3, 'p4'),
        (4, 'p5'),
      ]) {
        testWidgets('${page.$2} $suffixe', (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$1, 1);
          await tester.pumpWidget(
            hoteCapture(
              Directionality(
                textDirection: cas.$4,
                child: const BienvenuePage(),
              ),
              surcharges: _surcharges(),
              themeMode: cas.$2,
              echelleTexte: cas.$3,
            ),
          );
          await stabiliser(tester);
          if (page.$1 == 0) {
            // La ligne d'etat a mi-course du defilement automatique.
            for (int i = 0; i < 20; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          } else {
            for (int i = 0; i < page.$1; i++) {
              await tester.tap(find.bySemanticsLabel(t.bienvenue.suivante));
              await tester.pumpAndSettle(AppMouvement.navigation);
            }
          }
          debugPrint(
            'PNG ${await capturer(tester, 'pub1_${page.$2}_$suffixe')}',
          );
        });
      }
    }

    // Reprise PUB-1 : la souris posee au milieu de la page, sur ordinateur,
    // ne gele plus le defilement ; apres 3 s, la ligne est a mi-course.
    testWidgets('1440 souris posee', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await tester.pumpWidget(
        hoteCapture(const BienvenuePage(), surcharges: _surcharges()),
      );
      await stabiliser(tester);
      final TestGesture souris = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await souris.addPointer(location: Offset.zero);
      addTearDown(souris.removePointer);
      await souris.moveTo(const Offset(720, 600));
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      debugPrint(
        'PNG ${await capturer(tester, 'pub1_p1_1440_souris_3s_clair')}',
      );
    });

    testWidgets('hors ligne 390', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 1);
      await tester.pumpWidget(
        hoteCapture(
          const BienvenuePage(),
          surcharges: _surcharges(horsLigne: true),
        ),
      );
      await stabiliser(tester);
      debugPrint('PNG ${await capturer(tester, 'pub1_hors_ligne_390')}');
    });
  });
}
