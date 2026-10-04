// TB-1b : squelette des captures du chantier Supports et tableau.
//
// Sautees sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md). Chaque etape
// TB ajoute ses situations a `_situationsCapturees` et garde les cadrages de
// la definition de « fait » (02_DECOUPAGE) : 390x844, 768x1024, 1440x900,
// clair et sombre, texte x2 aux trois tailles, 320 x1 et x2 (320 x 700 @2,
// le cadrage de salle_200_test).
//
// La page montee est `DemoSallePage`, celle que sert `/demo/salle?role=…&tb=…`.
//
// Commande :
//   CAPTURE_DIR=/tmp/tb flutter test test/features/tb_recette/captures_tb_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

typedef _Cadrage = (
  String nom,
  Size logique,
  double densite,
  EdgeInsets zone,
  double texte,
  ThemeMode mode,
);

const EdgeInsets _zoneTelephone = EdgeInsets.only(top: 47, bottom: 34);

/// Les cadrages de la definition de « fait » (02_DECOUPAGE, point 3).
const List<_Cadrage> _cadragesTb = <_Cadrage>[
  ('390_x1_clair', Size(390, 844), 3, _zoneTelephone, 1, ThemeMode.light),
  ('390_x1_sombre', Size(390, 844), 3, _zoneTelephone, 1, ThemeMode.dark),
  ('390_x2_clair', Size(390, 844), 3, _zoneTelephone, 2, ThemeMode.light),
  ('768_x1_clair', Size(768, 1024), 2, EdgeInsets.zero, 1, ThemeMode.light),
  ('768_x1_sombre', Size(768, 1024), 2, EdgeInsets.zero, 1, ThemeMode.dark),
  ('768_x2_clair', Size(768, 1024), 2, EdgeInsets.zero, 2, ThemeMode.light),
  ('1440_x1_clair', Size(1440, 900), 1, EdgeInsets.zero, 1, ThemeMode.light),
  ('1440_x1_sombre', Size(1440, 900), 1, EdgeInsets.zero, 1, ThemeMode.dark),
  ('1440_x2_clair', Size(1440, 900), 1, EdgeInsets.zero, 2, ThemeMode.light),
  ('320_x1_clair', Size(320, 700), 2, EdgeInsets.zero, 1, ThemeMode.light),
  ('320_x2_clair', Size(320, 700), 2, EdgeInsets.zero, 2, ThemeMode.light),
];

/// Les situations capturees, par role. TB-1b n'a aucune disposition
/// nouvelle : une seule situation, la salle et ses personnes (SAL-00),
/// prouve que le squelette tourne. Chaque etape ajoute les siennes.
const Map<RoleSeance, List<SituationTb>> _situationsCapturees =
    <RoleSeance, List<SituationTb>>{
      RoleSeance.eleve: <SituationTb>[SituationTb.sal00],
      RoleSeance.guidee: <SituationTb>[SituationTb.sal00],
      RoleSeance.enseignant: <SituationTb>[SituationTb.sal00],
    };

void main() {
  test('le delai de masquage est celui de CommandesMasquables (4 s)', () {
    // Une seule valeur (plan V2 §18.1, TB7) : aucune seconde constante.
    expect(CommandesMasquables.delaiParDefaut, const Duration(seconds: 4));
  });

  test('chaque situation capturee a un sens pour son role', () {
    _situationsCapturees.forEach((RoleSeance role, List<SituationTb> l) {
      for (final SituationTb s in l) {
        expect(s.concerne(role), isTrue, reason: '${role.name} ${s.name}');
      }
    });
  });

  group('TB : captures de la salle', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    _situationsCapturees.forEach((RoleSeance role, List<SituationTb> l) {
      for (final SituationTb situation in l) {
        for (final _Cadrage cas in _cadragesTb) {
          final String nom = 'tb_${role.name}_${situation.name}_${cas.$1}';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
            await tester.pumpWidget(
              hoteCapture(
                DemoSallePage(role: role, situation: situation),
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
  });
}
