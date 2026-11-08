// Selection du texte (directeur, 07/11/2026) : la salle de cours est hors de
// la selection (l'appui long y a un role). Meme salle (`SalleSeance`) que
// `/salle`, montee par la demonstration.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/demo_salle_page.dart';
import '../../support/demo/seance_demo.dart';
import '../../support/hote_selection.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final RoleSeance role in <RoleSeance>[
    RoleSeance.enseignant,
    RoleSeance.eleve,
  ]) {
    for (final Size taille in const <Size>[Size(1440, 900), Size(390, 844)]) {
      testWidgets('la salle ${role.name} a ${taille.width.toInt()} : aucun '
          'texte ne se selectionne', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1);
        await tester.pumpWidget(
          hoteSelection(
            DemoSallePage(role: role, etat: EtatDemoSalle.repos),
            brut: true,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final List<String> affiches = <String>[
          for (final Text w in tester.widgetList<Text>(find.byType(Text)))
            if ((w.data ?? '').trim().length > 3) w.data!.trim(),
        ];
        expect(affiches, isNotEmpty);
        final String copie = await toutCopier(tester);
        for (final String texte in affiches) {
          expect(copie, isNot(contains(texte)));
        }
      });
    }
  }
}
