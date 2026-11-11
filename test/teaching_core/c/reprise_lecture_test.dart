// Lot CORAN-ELEVE (cahier de la salle, §8, directeur) : « "Reprendre la
// lecture" s'affiche en haut (surtout chez l'eleve), ne disparait jamais et
// est laid. Il devrait s'effacer seul apres quelques secondes. »
//
// Le lecteur de l'eleve (`/eleve/coran`, `MushafPage`) : la bande de reprise
// se pose par-dessus le haut de la page (elle ne la pousse plus), s'efface
// seule apres `AppMouvement.ilePassage`, et le signet de l'en-tete la rappelle
// d'un appui.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart'
    show PositionLecture;
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';

import 'faux/faux_corpus_coran.dart';
import 'goldens/corpus_reference.dart';
import 'support/hote_tc_c.dart';

void main() {
  late CorpusReference reference;

  setUpAll(() => reference = CorpusReference.charger());

  Widget ecran() => hoteCoran(
    const MushafPage(),
    surcharges: <Override>[
      portCorpusCoranProvider.overrideWithValue(FauxCorpusCoran(reference)),
      portLayoutMushafProvider.overrideWithValue(
        const LayoutLignesIndisponible(),
      ),
      portNavigationCoranProvider.overrideWithValue(
        FauxNavigationCoran(
          personnelle: const PositionLecture(page: 3, sourate: 2, verset: 6),
        ),
      ),
    ],
  );

  Future<void> poser(WidgetTester tester) async {
    for (int i = 0; i < 6; i++) {
      await tester.pump();
    }
  }

  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1400, 900),
  ]) {
    testWidgets('${taille.width.toInt()} : la reprise passe par-dessus la '
        'page, s efface seule, et revient d un appui', (
      WidgetTester tester,
    ) async {
      await poserFenetre(tester, taille);
      await tester.pumpWidget(ecran());
      await poser(tester);

      final Finder bande = find.byKey(MushafPage.repriseKey);
      final Finder signet = find.byKey(MushafPage.signetRepriseKey);
      expect(bande, findsOneWidget);
      expect(signet, findsNothing);

      // Elle ne pousse pas la page : la zone de lecture commence au meme
      // endroit avec ou sans elle.
      final double hautAvecBande = tester
          .getTopLeft(find.byKey(MushafPage.enteteKey))
          .dy;

      await tester.pump(AppMouvement.ilePassage);
      await tester.pump(AppMouvement.plafond);
      await tester.pump(AppMouvement.plafond);
      expect(bande, findsNothing);
      expect(signet, findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(MushafPage.enteteKey)).dy,
        hautAvecBande,
      );

      await tester.tap(signet);
      await tester.pump();
      await tester.pump(AppMouvement.plafond);
      expect(bande, findsOneWidget);
      expect(signet, findsNothing);

      // Et elle repart seule.
      await tester.pump(AppMouvement.ilePassage);
      await tester.pump(AppMouvement.plafond);
      expect(bande, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
