// TB-RC (ecarts declares) : les captures de controle du telephone couche
// (844 x 390), que le harnais ne cadrait pas, et les deux ecarts visibles
// n.7 (phrase du tableau libre) et n.17 (menu de rangement).
//
// Sautees sans CAPTURE_DIR (test/capture/LISEZ-MOI.md) :
//   CAPTURE_DIR=docs/current/captures/TB-RC-ECARTS flutter test \
//     test/features/tb_recette/rc_ecarts_captures_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart' hide stabiliser;
import '../../capture/outil_capture.dart' as capture show stabiliser;

/// Le telephone couche : 844 x 390, zone sure laterale non simulee.
const Size _couche = Size(844, 390);

void main() {
  group('Telephone couche (844 x 390)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (RoleSeance role, SituationTb situation, String etat)
        in <(RoleSeance, SituationTb, String)>[
          (RoleSeance.enseignant, SituationTb.ped03, 'ferme'),
          (RoleSeance.enseignant, SituationTb.cmd01, 'commandes'),
          (RoleSeance.eleve, SituationTb.cmd01, 'commandes'),
          (RoleSeance.guidee, SituationTb.cmd01, 'commandes'),
        ]) {
      for (final double texte in <double>[1, 2]) {
        final String nom =
            'rc_couche_${role.name}_${etat}_844x390_x${texte.toInt()}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, _couche, 2);
          await tester.pumpWidget(
            hoteCapture(
              DemoSallePage(role: role, situation: situation),
              echelleTexte: texte,
            ),
          );
          await capture.stabiliser(tester);
          await tester.pump(const Duration(milliseconds: 1400));
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });
}
