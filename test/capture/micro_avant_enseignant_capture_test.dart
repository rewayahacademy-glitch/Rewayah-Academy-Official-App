// Captures de recette MICRO-AVANT-ENSEIGNANT (directeur, 11/11/2026, defaut
// SEC-1) : la salle de l'eleve qui attend son enseignant (la phrase a la place
// du bouton du micro), puis la meme salle une fois le droit rendu (le bouton,
// micro ferme). Telephone 390 et ordinateur 1440, clair et sombre, Interface
// guidee, arabe.
// Saute sans CAPTURE_DIR. Nommage : microattente_<role>_<etat>_<largeur>_<mode>.

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
  (Size(390, 844), 3, '390'),
  (Size(1440, 900), 1, '1440'),
];

Widget _salle(RoleSeance role, {required bool attente}) => SalleSeance(
  vue: DonneesSeanceDemo.vue(
    role,
    EtatDemoSalle.repos,
  ).copyWith(microEnAttente: attente, tutoiement: role == RoleSeance.guidee),
  local: const EtatLocalSeance(microOuvert: false, cameraAllumee: false),
  // Comme dans `/salle` : sans droit de publier, aucun geste de micro.
  actions: ActionsSeance(
    onRetour: () {},
    onQuitter: () {},
    onMicro: attente ? null : () {},
  ),
);

Future<void> _prendre(
  WidgetTester tester,
  String nom,
  RoleSeance role, {
  required bool attente,
  required Size cadre,
  required double densite,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, cadre, densite);
  await tester.pumpWidget(
    hoteCapture(
      _salle(role, attente: attente),
      themeMode: mode,
      interfaceMode: role == RoleSeance.guidee
          ? InterfaceMode.enfant
          : InterfaceMode.standard,
    ),
  );
  await stabiliser(tester);
  expect(tester.takeException(), isNull);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : MICRO-AVANT-ENSEIGNANT', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (Size cadre, double densite, String largeur) in _cadres) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final bool attente in <bool>[true, false]) {
          final String nom =
              'microattente_eleve_${attente ? 'attente' : 'rendu'}_'
              '${largeur}_${mode.name}';
          testWidgets(nom, (WidgetTester tester) async {
            await _prendre(
              tester,
              nom,
              RoleSeance.eleve,
              attente: attente,
              cadre: cadre,
              densite: densite,
              mode: mode,
            );
          });
        }
      }
    }

    testWidgets('microattente_guidee_attente_390_light', (
      WidgetTester tester,
    ) async {
      await _prendre(
        tester,
        'microattente_guidee_attente_390_light',
        RoleSeance.guidee,
        attente: true,
        cadre: const Size(390, 844),
        densite: 3,
      );
    });

    testWidgets('microattente_eleve_attente_390_light_ar', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _prendre(
        tester,
        'microattente_eleve_attente_390_light_ar',
        RoleSeance.eleve,
        attente: true,
        cadre: const Size(390, 844),
        densite: 3,
      );
    });

    testWidgets('microattente_eleve_attente_320_light_x2', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(320, 700), 2);
      await tester.pumpWidget(
        hoteCapture(_salle(RoleSeance.eleve, attente: true), echelleTexte: 2),
      );
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
      debugPrint(
        'PNG ${await capturer(tester, 'microattente_eleve_attente_320_light_x2')}',
      );
    });
  });
}
