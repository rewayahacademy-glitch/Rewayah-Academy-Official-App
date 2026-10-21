// Captures de recette de FILTRES-1 : chaque ecran a filtres de la branche
// commune, 320 px texte x2, LTR et RTL, vraies polices, theme clair. La
// rangee de filtres est amenee dans la vue avant la capture, sans la faire
// defiler : on la voit comme a l'ouverture.
//
// Les memes cas que `test/features/filtres1_rangee_unique_test.dart`
// (doubles en memoire, aucun service reel). Saute sans CAPTURE_DIR (voir
// `test/capture/LISEZ-MOI.md`). Sortie versionnee dans
// `docs/current/captures/FILTRES-1/avant` (code d'avant, `Wrap`) et
// `.../apres` (`RangeeFiltres`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';

import '../features/filtres1_rangee_unique_test.dart'
    show CasFiltres1, casFiltres1, hoteFiltres1;
import 'outil_capture.dart';

String _nom(String cas) => cas
    .toLowerCase()
    .replaceAll(RegExp(r'\(.*\)'), '')
    .trim()
    .replaceAll(RegExp('[^a-z0-9]+'), '_');

void main() {
  group('FILTRES-1 : captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    final List<CasFiltres1> cas = casFiltres1();
    for (int i = 0; i < cas.length; i++) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${cas[i].nom} ${sens.name}', (WidgetTester tester) async {
          tester.view.physicalSize = const Size(320, 1400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final CasFiltres1 c = casFiltres1()[i];
          await tester.pumpWidget(hoteFiltres1(c.ecran, c.surcharges, sens));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pumpAndSettle();
          // La rangee entiere amenee dans la vue (defilement vertical
          // seulement) : la capture montre la rangee telle qu'a l'ouverture,
          // filtre retenu compris.
          final Finder rangee = find.byType(RangeeFiltres);
          if (rangee.evaluate().isNotEmpty) {
            await tester.ensureVisible(rangee.first);
            await tester.pumpAndSettle();
          }
          await capturerVue(
            tester,
            'filtres1_${_nom(c.nom)}_320_x2_${sens.name}',
          );
        });
      }
    }
  }, skip: sautSansCapture);
}
