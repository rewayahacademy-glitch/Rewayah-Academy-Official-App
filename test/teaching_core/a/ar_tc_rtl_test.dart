// AR-TC-1 : les ecrans du Teaching Core en arabe, de droite a gauche.
//
// « Mes classes » et l'espace d'une classe (eleve, enseignant) se montent en
// arabe sans debordement ni exception, au telephone (390, et 320 a texte x2)
// comme au bureau ; le sens est RTL et les libelles sont ceux de l'arabe.
// Avec CAPTURE_DIR, les memes ecrans sont captures :
//   CAPTURE_DIR=docs/current/captures/AR-TC-1 flutter test \
//     test/teaching_core/a/ar_tc_rtl_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/mes_groupes_page.dart';

import '../../capture/outil_capture.dart';
import 'support/hote_tc_a.dart';

typedef _Ecran = (String nom, Widget Function() construire);

final List<_Ecran> _ecrans = <_Ecran>[
  ('mes_classes', () => const MesGroupesPage()),
  (
    'espace_eleve',
    () => const EspaceGroupePage(
      groupeId: GroupesDemonstration.alFatiha,
      role: RoleEspaceGroupe.eleve,
    ),
  ),
  (
    'espace_enseignant',
    () => const EspaceGroupePage(
      groupeId: GroupesDemonstration.anNour,
      role: RoleEspaceGroupe.enseignant,
    ),
  ),
];

const List<(String, Size, double, ThemeMode)> _cadrages =
    <(String, Size, double, ThemeMode)>[
      ('390_x1_clair', Size(390, 844), 1, ThemeMode.light),
      ('390_x1_sombre', Size(390, 844), 1, ThemeMode.dark),
      ('320_x2_clair', Size(320, 700), 2, ThemeMode.light),
      ('1440_x1_clair', Size(1440, 900), 1, ThemeMode.light),
    ];

void main() {
  late String titreFr;
  setUpAll(() async {
    titreFr = t.tc.groupe.mesGroupes.titre;
    if (dossierCapture != null) await chargerPolicesDuDepot();
  });
  setUp(() => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final (String nom, Widget Function() construire) in _ecrans) {
    for (final (String cas, Size taille, double texte, ThemeMode mode)
        in _cadrages) {
      testWidgets('ar_tc_${nom}_$cas', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteCapture(
            construire(),
            surcharges: surchargesDemonstration(),
            themeMode: mode,
            echelleTexte: texte,
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byWidget(construire()).first)),
          TextDirection.rtl,
        );
        if (dossierCapture != null) {
          debugPrint('PNG ${await capturer(tester, 'ar_tc_${nom}_$cas')}');
        }
      });
    }
  }

  testWidgets('« Mes classes » en arabe, plus en francais', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(390, 844), 1);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteCapture(
        const MesGroupesPage(),
        surcharges: surchargesDemonstration(),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(t.tc.groupe.mesGroupes.titre), findsWidgets);
    expect(t.tc.groupe.mesGroupes.titre, isNot(titreFr));
    expect(find.text(titreFr), findsNothing);
  });
}
