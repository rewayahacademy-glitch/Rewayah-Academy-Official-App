// Captures de recette SORTIE-SALLE (directeur, 11/11/2026) : la commande
// « Reduire la salle » (barre de l'ordinateur, pilule de l'eleve), la
// question de sortie de celui qui conduit et celle de l'eleve, a 390 et
// 1440, clair et sombre, plus l'arabe. Saute sans CAPTURE_DIR.
// Nommage : sortiesalle_<sujet>_<largeur>_<mode>.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/demo/seance_demo.dart';
import 'outil_capture.dart';

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 3, '390'),
  (Size(1440, 900), 1, '1440'),
];

const List<ThemeMode> _modes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

Widget _dock(RoleSeance role, {required bool nommee}) => Builder(
  builder: (BuildContext context) => ColoredBox(
    color: AppPalette.of(context).surfaceInverse.background,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: DockSeance(
        vue: DonneesSeanceDemo.vue(role, EtatDemoSalle.repos),
        nommee: nommee,
        actions: ActionsSeance(
          onRetour: () {},
          onQuitter: () {},
          onMicro: () {},
          onCamera: () {},
        ),
      ),
    ),
  ),
);

Widget _question({required bool cahier}) => Builder(
  builder: (BuildContext context) => Center(
    child: TextButton(
      key: const ValueKey<String>('ouvrir'),
      onPressed: () => unawaited(
        confirmerQuitterSeance(context, () {}, cahier: cahier, reduire: () {}),
      ),
      child: const Text('ouvrir'),
    ),
  ),
);

Future<void> _photographier(
  WidgetTester tester,
  String nom,
  Widget scene, {
  required Size cadre,
  required double densite,
  required ThemeMode mode,
  bool ouvrir = false,
}) async {
  fixerVueCapture(tester, cadre, densite);
  await tester.pumpWidget(hoteCapture(Scaffold(body: scene), themeMode: mode));
  await stabiliser(tester);
  if (ouvrir) {
    await tester.tap(find.byKey(const ValueKey<String>('ouvrir')));
    await stabiliser(tester);
  }
  expect(tester.takeException(), isNull);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : SORTIE-SALLE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final ThemeMode mode in _modes) {
      testWidgets('sortiesalle_commande_enseignant_1440_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _photographier(
          tester,
          'sortiesalle_commande_enseignant_1440_${mode.name}',
          _dock(RoleSeance.enseignant, nommee: true),
          cadre: const Size(1440, 300),
          densite: 1,
          mode: mode,
        );
      });
      testWidgets('sortiesalle_commande_eleve_1440_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _photographier(
          tester,
          'sortiesalle_commande_eleve_1440_${mode.name}',
          _dock(RoleSeance.eleve, nommee: false),
          cadre: const Size(1440, 300),
          densite: 1,
          mode: mode,
        );
      });
      for (final (Size cadre, double densite, String largeur) in _cadres) {
        for (final (String sujet, bool cahier) in <(String, bool)>[
          ('conduite', true),
          ('eleve', false),
        ]) {
          final String nom =
              'sortiesalle_question_${sujet}_${largeur}_${mode.name}';
          testWidgets(nom, (WidgetTester tester) async {
            await _photographier(
              tester,
              nom,
              _question(cahier: cahier),
              cadre: cadre,
              densite: densite,
              mode: mode,
              ouvrir: true,
            );
          });
        }
      }
    }

    testWidgets('sortiesalle_question_conduite_390_light_ar', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _photographier(
        tester,
        'sortiesalle_question_conduite_390_light_ar',
        _question(cahier: true),
        cadre: const Size(390, 844),
        densite: 3,
        mode: ThemeMode.light,
        ouvrir: true,
      );
    });
  });
}
