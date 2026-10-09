import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

void main() {
  testWidgets('debug', (WidgetTester tester) async {
    fixerVueCapture(tester, const Size(320, 700), 1);
    await tester.pumpWidget(
      hoteCapture(
        const DemoSallePage(
          role: RoleSeance.enseignant,
          situation: SituationTb.ped03,
        ),
        echelleTexte: 2,
      ),
    );
    await stabiliser(tester);
    await tester.tap(find.byKey(DeclencheurCommandes.cle));
    await stabiliser(tester);
    debugPrint('EXC1 ${tester.takeException()}');
    debugPrint(
      'panneau ${tester.getRect(find.byKey(const ValueKey<String>('panneau-seance-feuille')))}',
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(CommandesPedagogiques.cleOnglets),
        matching: find.text(t.salle.seance.commandes.ongletOutils),
      ),
    );
    await stabiliser(tester);
    debugPrint('EXC2 ${tester.takeException()}');
    debugPrint(
      'panneau ${tester.getRect(find.byKey(const ValueKey<String>('panneau-seance-feuille')))}',
    );
    debugPrint('reduire ${tester.getRect(find.byKey(PanneauSeance.cleReduire))}');
  });
}
