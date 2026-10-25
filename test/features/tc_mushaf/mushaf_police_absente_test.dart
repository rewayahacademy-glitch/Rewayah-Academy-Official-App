// D9 (24/10/2026, decision du pilote) : dans le lecteur `/eleve/coran`, en
// mode page, la police du mushaf absente ne retombe plus sur le flux Tanzil
// simple ; un etat visible dit ce qui manque et quoi faire (K-59). Avec la
// police, la page de quinze lignes reste rendue.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/tc_mushaf/page_madina_15.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';

import '../../support/mushaf_15l.dart';

const Size _telephone = Size(390, 844);

void main() {
  testWidgets('police absente : un etat visible, ni page ni texte continu', (
    WidgetTester tester,
  ) async {
    await monterPageMadina15(
      tester,
      page: 293,
      taille: _telephone,
      tanzilSimple: true,
      policeMushaf: false,
    );
    expect(find.byKey(TexteDePage.cleCoranIndisponible), findsOneWidget);
    expect(find.text(t.salle.coran.indisponible), findsOneWidget);
    expect(find.byType(PageMadina15), findsNothing);
    expect(find.byType(ParagrapheVersets), findsNothing);
  });

  testWidgets('police presente : la page de quinze lignes', (
    WidgetTester tester,
  ) async {
    await monterPageMadina15(tester, page: 293, taille: _telephone);
    expect(find.byType(PageMadina15), findsOneWidget);
    expect(find.byKey(TexteDePage.cleCoranIndisponible), findsNothing);
  });
}
