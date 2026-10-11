// TB-RC (ecarts declares) : les captures de controle du telephone couche
// (844 x 390), que le harnais ne cadrait pas, et les deux ecarts visibles
// n.7 (phrase du tableau libre) et n.17 (menu de rangement).
//
// Sautees sans CAPTURE_DIR (test/capture/LISEZ-MOI.md) :
//   CAPTURE_DIR=docs/current/captures/TB-RC-ECARTS flutter test \
//     test/features/tb_recette/rc_ecarts_captures_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
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

  group('n.7 et n.17', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // n.7 : la phrase du tableau libre sur sa carte, a x2.
    for (final (String nom, Size taille, double texte, ThemeMode mode)
        in <(String, Size, double, ThemeMode)>[
          ('390_x2_clair', const Size(390, 844), 2, ThemeMode.light),
          ('390_x2_sombre', const Size(390, 844), 2, ThemeMode.dark),
          ('320_x2_clair', const Size(320, 700), 2, ThemeMode.light),
        ]) {
      final String fichier = 'rc_n7_libre_enseignant_$nom';
      testWidgets(fichier, (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 2);
        await tester.pumpWidget(
          hoteCapture(
            const DemoSallePage(
              role: RoleSeance.enseignant,
              situation: SituationTb.ped01,
            ),
            echelleTexte: texte,
            themeMode: mode,
          ),
        );
        await capture.stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, fichier)}');
      });
    }

    // n.17 : 40 ms apres le choix de « Ranger », le menu n'est plus la.
    testWidgets('rc_n17_rangement_en_cours_390_x1_clair', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      await tester.pumpWidget(
        hoteCapture(
          const DemoSallePage(
            role: RoleSeance.enseignant,
            situation: SituationTb.ped03,
          ),
        ),
      );
      await capture.stabiliser(tester);
      await tester.tap(find.byKey(DeclencheurCommandes.cle));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CommandesPedagogiques.cleMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.salle.seance.rangement.ranger));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      debugPrint(
        'PNG ${await capturer(tester, 'rc_n17_rangement_en_cours_390_x1_clair')}',
      );
    });
  });
}
