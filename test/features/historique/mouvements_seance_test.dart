// Detail d'une seance passee -> « Voir les mouvements associes » (LT-12),
// sur le VRAI routeur et la coquille du tuteur : le lien TOUCHE ouvre la
// liste des mouvements, le retour ramene a la seance ; en production
// (DB-FIN-02 indisponible) le lien n'existe pas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/compte/mouvements_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/suivi_foyer/detail_seance_page.dart';

import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart';
import 'support_historique.dart';

final String _seance = Uri(
  path: Routes.seancePour('s-presente'),
  queryParameters: <String, String>{'eleve': FoyersFictifs.a1.id},
).toString();

void main() {
  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('${taille.width.toInt()} demonstration : seance -> mouvements '
        'associes -> retour a la seance', (WidgetTester tester) async {
      final GoRouter routeur = await monterHistorique(
        tester,
        depart: _seance,
        taille: taille,
        autres: <Override>[
          portFinanceFoyerProvider.overrideWithValue(const FinanceFoyerDemo()),
        ],
      );
      expect(find.byType(DetailSeancePage), findsOneWidget);
      final Finder lien = find.byKey(DetailSeancePage.voirMouvementsKey);
      expect(find.text(t.historique.seance.voirMouvements), findsOneWidget);

      await tester.ensureVisible(lien);
      await stabiliser(tester);
      await tester.tap(lien);
      await stabiliser(tester);
      expect(Uri.parse(lieu(routeur)).path, Routes.tuteurCompteMouvements);
      expect(find.byType(MouvementsComptePage), findsOneWidget);

      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), _seance);
      expect(find.byType(DetailSeancePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('production : DB-FIN-02 indisponible, aucun lien', (
    WidgetTester tester,
  ) async {
    await monterHistorique(tester, depart: _seance);
    expect(find.byType(DetailSeancePage), findsOneWidget);
    expect(find.text(t.historique.seance.blocSeance), findsOneWidget);
    expect(find.byKey(DetailSeancePage.voirMouvementsKey), findsNothing);
    expect(find.text(t.historique.seance.voirMouvements), findsNothing);
  });
}
