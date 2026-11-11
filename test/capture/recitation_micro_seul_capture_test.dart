// Captures de recette RECITATION-MICRO-SEUL (directeur, 11/11/2026, D-022) :
// la salle d'un camarade pendant qu'un autre eleve recite. Pas de bouton de
// micro, la phrase qui dit pourquoi, et le bouton de la camera, garde.
//
// Captures de TEST (la salle de seance montee seule, avec les donnees de
// demonstration du depot) : ce n'est pas la vraie application dans un
// navigateur. Saute sans CAPTURE_DIR.
// Nommage : recitation_<cas>_<largeur>_<mode>[_ar].

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/demo/seance_demo.dart';
import 'outil_capture.dart';

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 2, '390'),
  (Size(1440, 900), 1, '1440'),
];

VueSeance _vue({required bool camera, RoleSeance role = RoleSeance.eleve}) =>
    DonneesSeanceDemo.vue(role, EtatDemoSalle.repos).copyWith(
      microEnAttente: true,
      recitantPrenom: 'Yasmine',
      cameraAutorisee: camera,
      tutoiement: false,
    );

Future<void> _monter(
  WidgetTester tester,
  VueSeance vue, {
  required bool camera,
  required Size cadre,
  required double densite,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, cadre, densite);
  await tester.pumpWidget(
    hoteCapture(
      SalleSeance(
        vue: vue,
        local: const EtatLocalSeance(microOuvert: false),
        // Comme `/salle` : pas de geste de micro pendant la recitation, la
        // camera seulement si le serveur la laisse.
        actions: ActionsSeance(
          onRetour: () {},
          onQuitter: () {},
          onCamera: camera ? () {} : null,
        ),
      ),
      themeMode: mode,
      interfaceMode: vue.role == RoleSeance.guidee
          ? InterfaceMode.enfant
          : InterfaceMode.standard,
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture : RECITATION-MICRO-SEUL', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (Size cadre, double densite, String largeur) in _cadres) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nom = 'recitation_camarade_camera_${largeur}_${mode.name}';
        testWidgets(nom, (WidgetTester tester) async {
          await _monter(
            tester,
            _vue(camera: true),
            camera: true,
            cadre: cadre,
            densite: densite,
            mode: mode,
          );
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }

    testWidgets('recitation_camarade_sans_camera_390_light', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _vue(camera: false),
        camera: false,
        cadre: const Size(390, 844),
        densite: 2,
      );
      expect(tester.takeException(), isNull);
      debugPrint(
        'PNG ${await capturer(tester, 'recitation_camarade_sans_camera_390_light')}',
      );
    });

    testWidgets('recitation_camarade_camera_390_light_ar', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(
        tester,
        _vue(camera: true),
        camera: true,
        cadre: const Size(390, 844),
        densite: 2,
      );
      expect(tester.takeException(), isNull);
      debugPrint(
        'PNG ${await capturer(tester, 'recitation_camarade_camera_390_light_ar')}',
      );
    });
  });
}
