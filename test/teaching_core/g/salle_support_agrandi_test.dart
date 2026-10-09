// PAGESHELL-200-1d (reserve 3 de la revue PAGESHELL-200-1c-R2) : la mutation
// `minimumEtire: AppTouchTarget.standard` survivait dans la salle du
// telephone. Le minimum de la zone etiree n'y est pas redondant : avec
// « Agrandir », le support est seul dans la zone, sans le defileur qui en
// garantit la hauteur. Un support reel (le Coran, un PDF) ne sait pas se
// mesurer seul : c'est `minimumEtire` qui le garde a sa hauteur lisible
// quand le bandeau et la barre agrandis ne lui laissent presque rien, et la
// page defile pour le reste.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/tc_observation_ui/panneau_observation_tuteur.dart';
import 'package:rewayah_academy/features/tc_observation_ui/vue_observation_tuteur.dart';

import '../../support/harnais.dart';

void main() {
  final v = t.tc.observation.visite;
  const ValueKey<String> cleSupportReel = ValueKey<String>('support-reel');

  for (final (Size, double, TextDirection) cas
      in const <(Size, double, TextDirection)>[
        (Size(320, 568), 2, TextDirection.ltr),
        (Size(320, 568), 2, TextDirection.rtl),
        (Size(360, 640), 2, TextDirection.ltr),
        (Size(667, 375), 1, TextDirection.ltr),
        (Size(667, 375), 2, TextDirection.rtl),
      ]) {
    testWidgets('Agrandir, support reel, ${cas.$1.width.toInt()}x'
        '${cas.$1.height.toInt()}, texte x${cas.$2.toInt()}, ${cas.$3.name} : '
        'le support garde sa hauteur lisible', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = cas.$1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = cas.$2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        hote(
          Directionality(
            textDirection: cas.$3,
            child: PageShell(
              titre: 'Salle',
              defilante: false,
              child: PanneauObservationTuteur(
                vue: VueObservationTuteur.depuis(
                  participants: const [],
                  enfantProfilId: 'enfant-1',
                ),
                onQuitter: () {},
                supportPartage: const ColoredBox(
                  key: cleSupportReel,
                  color: Color(0xFF808080),
                ),
              ),
            ),
          ),
          surcharges: <Override>[
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(v.agrandir));
      await tester.pumpAndSettle();
      await tester.tap(find.text(v.agrandir));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(v.reduire), findsOneWidget);
      expect(
        tester.getSize(find.byKey(cleSupportReel)).height,
        greaterThanOrEqualTo(200 - 0.5),
      );
      // « Reduire » et « Quitter » se rejoignent en defilant la page.
      await tester.ensureVisible(find.text(v.quitter));
      await tester.pumpAndSettle();
      for (final String libelle in <String>[v.reduire, v.quitter]) {
        final Rect r = tester.getRect(find.text(libelle));
        expect(r.top, greaterThanOrEqualTo(-0.5));
        expect(r.bottom, lessThanOrEqualTo(cas.$1.height + 0.5));
      }
    });
  }
}
