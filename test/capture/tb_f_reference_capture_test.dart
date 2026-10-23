// TB-F (voie Supports et tableau) : captures de reference « avant » de la
// salle de demonstration (/demo/salle), avant TB-1b. Sautees sans
// CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).
//
// Trois roles (eleve, guidee, enseignant), etat `repos` :
// - 390x844 @3, texte x1 et x2 (vrai `textScaler` 2), clair et sombre ;
// - 1440x900 @1, texte x1, clair.
//
// La page est `DemoSallePage`, celle que sert la route : la guidee y lit le
// theme `InterfaceMode.enfant` comme en demonstration.
//
// Commande :
//   CAPTURE_DIR=docs/current/captures/TB-F \
//     flutter test test/capture/tb_f_reference_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import 'outil_capture.dart';

const Map<RoleSeance, String> _noms = <RoleSeance, String>{
  RoleSeance.eleve: 'eleve',
  RoleSeance.guidee: 'guidee',
  RoleSeance.enseignant: 'enseignant',
};

typedef _Cas = (
  String nom,
  Size logique,
  double densite,
  EdgeInsets zone,
  double texte,
  ThemeMode mode,
);

const EdgeInsets _zoneTelephone = EdgeInsets.only(top: 47, bottom: 34);

const List<_Cas> _cas = <_Cas>[
  ('390_x1_clair', Size(390, 844), 3, _zoneTelephone, 1, ThemeMode.light),
  ('390_x1_sombre', Size(390, 844), 3, _zoneTelephone, 1, ThemeMode.dark),
  ('390_x2_clair', Size(390, 844), 3, _zoneTelephone, 2, ThemeMode.light),
  ('390_x2_sombre', Size(390, 844), 3, _zoneTelephone, 2, ThemeMode.dark),
  ('1440_x1_clair', Size(1440, 900), 1, EdgeInsets.zero, 1, ThemeMode.light),
];

void main() {
  group('TB-F : captures de reference de la salle', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    test('garde-fou des polices : aucune capture en carres', () {
      final double inconnue = largeurSonde('FamilleInexistante');
      for (final String famille in <String>['PlusJakartaSans', 'DMSans']) {
        expect(
          largeurSonde(famille),
          lessThan(inconnue * 0.6),
          reason: famille,
        );
      }
    });

    for (final RoleSeance role in RoleSeance.values) {
      for (final _Cas cas in _cas) {
        final String nom = 'tbf_${_noms[role]}_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
          await tester.pumpWidget(
            hoteCapture(
              DemoSallePage(role: role, etat: EtatDemoSalle.repos),
              themeMode: cas.$6,
              echelleTexte: cas.$5,
            ),
          );
          await stabiliser(tester);
          // Un cycle du point clignotant : capture a pleine opacite.
          await tester.pump(const Duration(milliseconds: 1400));
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });
}
