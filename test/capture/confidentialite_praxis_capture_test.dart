// CONFIDENTIALITE-PRAXIS (17/11/2026) : la politique de confidentialite avec le
// texte de l'assistant Praxis (points 3, 4, 6 et 8), en francais, en anglais et
// en arabe (de droite a gauche), 360 et 1440 px, clair. La page est montee
// haute pour que les quatre points soient dans l'image.
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/juridique/juridique_pages.dart';
import 'package:rewayah_academy/features/juridique/textes_juridiques.dart';

import 'outil_capture.dart';

const List<(String, Size)> _vues = <(String, Size)>[
  ('360', Size(360, 6200)),
  ('1440', Size(1440, 3600)),
];

void main() {
  group('Capture : confidentialite, texte de Praxis', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

    for (final AppLocale langue in <AppLocale>[
      AppLocale.fr,
      AppLocale.en,
      AppLocale.ar,
    ]) {
      for (final (String nom, Size vue) in _vues) {
        testWidgets('${langue.languageCode} $nom', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(tester, vue, 1);
          await tester.pumpWidget(
            hoteCapture(
              const TexteJuridiquePage(texte: TexteJuridique.confidentialite),
              themeMode: ThemeMode.light,
            ),
          );
          await stabiliser(tester);
          expect(find.textContaining('Praxis'), findsWidgets);
          await capturer(
            tester,
            'CONFIDENTIALITE-PRAXIS/confidentialite_${langue.languageCode}_$nom',
          );
        });
      }
    }
  });
}
