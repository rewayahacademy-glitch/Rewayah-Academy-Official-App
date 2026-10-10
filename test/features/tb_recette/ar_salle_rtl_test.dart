// AR-SALLE-1 : la salle en arabe, de droite a gauche.
//
// Les situations de la salle (eleve, interface guidee, enseignant) se
// montent en arabe sans debordement ni exception, au telephone (390, et 320
// a texte x2) comme au bureau ; le sens est RTL et les libelles sont ceux de
// l'arabe, plus ceux du francais.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart' hide stabiliser;

const Map<RoleSeance, List<SituationTb>> _situations =
    <RoleSeance, List<SituationTb>>{
      RoleSeance.eleve: <SituationTb>[SituationTb.sal00, SituationTb.ped03],
      RoleSeance.guidee: <SituationTb>[SituationTb.sal00],
      RoleSeance.enseignant: <SituationTb>[
        SituationTb.sal00,
        SituationTb.ped01,
        SituationTb.cmd01,
        SituationTb.lib01,
        SituationTb.ctx01,
      ],
    };

const List<(String, Size, double)> _cadrages = <(String, Size, double)>[
  ('390 x1', Size(390, 844), 1),
  ('320 x2', Size(320, 700), 2),
  ('1440 x1', Size(1440, 900), 1),
];

void main() {
  late String introFr;
  setUpAll(() => introFr = t.salle.seance.bibliotheque.intro);
  setUp(() => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  _situations.forEach((RoleSeance role, List<SituationTb> liste) {
    for (final SituationTb situation in liste) {
      for (final (String nom, Size taille, double texte) in _cadrages) {
        testWidgets('${role.name} ${situation.name} $nom', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, 1);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            hoteCapture(
              DemoSallePage(role: role, situation: situation),
              echelleTexte: texte,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            Directionality.of(tester.element(find.byType(DemoSallePage))),
            TextDirection.rtl,
          );
        });
      }
    }
  });

  testWidgets('les libelles de la salle sont ceux de l\'arabe', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(1440, 900), 1);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteCapture(
        const DemoSallePage(
          role: RoleSeance.enseignant,
          situation: SituationTb.lib01,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.salle.seance.bibliotheque.intro), findsOneWidget);
    expect(t.salle.seance.bibliotheque.intro, isNot(introFr));
    expect(find.text(introFr), findsNothing);
  });
}
