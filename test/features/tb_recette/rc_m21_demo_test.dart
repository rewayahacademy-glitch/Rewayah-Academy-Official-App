// TB-RC m21 (verification non auteur du 11/10) : la salle de la demonstration
// SANS situation (`DemoSallePage(role:, etat:)`) lit aussi des outils neufs.
// Le test m21 de `rc_ecarts_test.dart` monte une situation, dont le
// `ProviderScope` portait deja ces overrides ; ce chemin-ci (la branche
// `situation == null` de `demo_salle_page.dart`) n'etait garde par aucun test.
// Contre-epreuve : remplacer `PorteeOutilsSalle(child: salle)` par `salle`
// fait echouer ce test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);

  testWidgets('demo sans situation : la salle a ses outils, la racine ne '
      'voit rien', (WidgetTester tester) async {
    fixerVueCapture(tester, const Size(1440, 900), 1);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteCapture(
        const DemoSallePage(
          role: RoleSeance.enseignant,
          etat: EtatDemoSalle.repos,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final ProviderContainer salle = ProviderScope.containerOf(
      tester.element(find.byType(SalleSeance)),
    );
    final ProviderContainer racine = ProviderScope.containerOf(
      tester.element(find.byType(DemoSallePage)),
    );
    expect(identical(salle, racine), isFalse);
    salle.read(etatOutilsProvider.notifier).choisirOutil(OutilDock.stylet);
    expect(salle.read(etatOutilsProvider).outilActif, OutilDock.stylet);
    expect(racine.read(etatOutilsProvider).outilActif, isNull);
  });
}
