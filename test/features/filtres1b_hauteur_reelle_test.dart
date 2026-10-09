// FILTRES-1b : les ecrans a filtres a une HAUTEUR de telephone reelle.
//
// `filtres1_rangee_unique_test.dart` monte chaque ecran dans une vue de
// 2400 px de haut : la rangee s'y mesure bien, mais un ecran dont la liste
// n'a plus de place sous l'intro et la rangee (320 px texte x2) n'y deborde
// jamais. Ici, la meme liste d'ecrans a 320x568 et 320x640 texte x2, LTR et
// RTL, et 390x844 texte x2 : aucune exception de rendu (debordement, liste
// sans hauteur), et la rangee de filtres s'atteint.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import 'filtres1_rangee_unique_test.dart'
    show CasFiltres1, casFiltres1, hoteFiltres1;

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  final List<CasFiltres1> cas = casFiltres1();
  for (int i = 0; i < cas.length; i++) {
    for (final Size vue in const <Size>[
      Size(320, 568),
      Size(320, 640),
      Size(390, 844),
    ]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${cas[i].nom} ${vue.width.toInt()}x${vue.height.toInt()} '
            'texte x2 ${sens.name}', (WidgetTester tester) async {
          tester.view.physicalSize = vue;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final CasFiltres1 c = casFiltres1()[i];
          await tester.pumpWidget(hoteFiltres1(c.ecran, c.surcharges, sens));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final Finder rangee = find.byType(RangeeFiltres);
          expect(rangee, findsWidgets);
          await tester.ensureVisible(rangee.first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
