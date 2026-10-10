// COM-RC, lot C (revue COM-R, R-07) : la Communaute emploie la recherche
// partagee du core (`ChampRecherche`, `SurfaceRecherche`), avec « Effacer
// la recherche » comme les Messages et Le Studio. Avant le lot C, son champ
// n'avait pas d'« Effacer » et sa surface du telephone etait recomposee.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/champ_recherche.dart';
import 'package:rewayah_academy/core/widgets/surface_recherche.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';

import 'banc_communaute.dart';

int _cartes() => find
    .byWidgetPredicate(
      (Widget w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('communaute-carte-'),
    )
    .evaluate()
    .length;

void main() {
  testWidgets('1440 : le champ partage, « Effacer la recherche » rend le '
      'flux entier', (WidgetTester tester) async {
    await monterCommunaute(tester, taille: const Size(1440, 900));
    final int toutes = _cartes();
    expect(find.byType(ChampRecherche), findsOneWidget);
    await tester.enterText(find.byKey(ClesRechercheCommunaute.champ), 'cartes');
    await tester.pumpAndSettle();
    expect(_cartes(), 1);
    expect(find.byKey(ClesRechercheCommunaute.effacer), findsOneWidget);
    expect(find.bySemanticsLabel(t.commun.recherche.effacer), findsOneWidget);
    await tester.tap(find.byKey(ClesRechercheCommunaute.effacer));
    await tester.pumpAndSettle();
    expect(_cartes(), toutes);
    expect(find.byKey(ClesRechercheCommunaute.effacer), findsNothing);
  });

  for (final double echelle in <double>[1, 2]) {
    testWidgets('telephone (texte x$echelle) : la surface partagee, Effacer '
        'puis Fermer rendent le flux', (WidgetTester tester) async {
      await monterCommunaute(
        tester,
        taille: echelle == 1 ? const Size(390, 844) : const Size(320, 844),
        echelleTexte: echelle,
      );
      final int toutes = _cartes();
      await taper(tester, find.byKey(EntreeRechercheCommunaute.cle));
      expect(find.byType(SurfaceRecherche), findsOneWidget);
      expect(find.byKey(ClesRechercheCommunaute.surface), findsOneWidget);
      await tester.enterText(
        find.byKey(ClesRechercheCommunaute.champ),
        'fiche',
      );
      await tester.pumpAndSettle();
      expect(_cartes(), lessThan(toutes));
      await taper(tester, find.byKey(ClesRechercheCommunaute.effacer));
      expect(find.byKey(ClesRechercheCommunaute.effacer), findsNothing);
      await taper(tester, find.byKey(ClesRechercheCommunaute.fermer));
      expect(find.byType(SurfaceRecherche), findsNothing);
      expect(_cartes(), toutes);
      expect(tester.takeException(), isNull);
    });
  }
}
