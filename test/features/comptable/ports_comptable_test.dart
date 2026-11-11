// PORTS-COMPTABLE (pilote, 11/11/2026) : les onglets du comptable sans
// serveur (Encaissements, Rapprochement, Contractuels) ne sont pas montres ;
// jamais un « indisponible » derriere un onglet. Contre-epreuve : avec les
// ports de demonstration, ils reviennent.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_encaissements.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_contractuels.dart';
import 'package:rewayah_academy/core/capacites/port_rapprochement.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';

import '../../router/support_routeur.dart';
import '../../support/demo/comptable/contractuels_demo.dart';
import '../../support/demo/comptable/encaissements_demo.dart';
import '../../support/harnais.dart';

Future<void> _comptable(
  WidgetTester tester,
  String depart, {
  List<Override> surcharges = const <Override>[],
}) async {
  await monterRouteur(
    tester,
    depart,
    source: FausseSourceSession(sessionActive(AppRole.accountant)),
    taille: const Size(1440, 900),
    surcharges: surcharges,
  );
}

List<String> _onglets(WidgetTester tester) => <String>[
  for (final ({String libelle, String chemin}) o
      in tester
          .widget<SousNavigationDomaine>(find.byType(SousNavigationDomaine))
          .onglets)
    o.libelle,
];

void main() {
  final o = t.comptable.onglets;

  group('sans serveur (ports de production)', () {
    testWidgets('Tresorerie : ni Encaissements ni Rapprochement', (
      WidgetTester tester,
    ) async {
      await _comptable(tester, Routes.comptableTresorerie);
      final List<String> montres = _onglets(tester);
      expect(montres, contains(o.coffres));
      expect(montres, contains(o.rapports));
      expect(montres, isNot(contains(o.encaissements)));
      expect(montres, isNot(contains(o.rapprochement)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Paiements : pas d onglet Contractuels', (
      WidgetTester tester,
    ) async {
      await _comptable(tester, Routes.comptablePaiements);
      final List<String> montres = _onglets(tester);
      expect(montres, contains(o.aEffectuer));
      expect(montres, isNot(contains(o.contractuels)));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('contre-epreuve : avec les ports de demonstration, les trois '
      'onglets reviennent', (WidgetTester tester) async {
    final List<Override> demo = <Override>[
      portEncaissementsProvider.overrideWithValue(EncaissementsDemo()),
      portRapprochementProvider.overrideWithValue(RapprochementDemo()),
      portObligationsContractuelsProvider.overrideWithValue(
        ObligationsContractuelsDemo(),
      ),
    ];
    await _comptable(tester, Routes.comptableTresorerie, surcharges: demo);
    expect(_onglets(tester), contains(o.encaissements));
    expect(_onglets(tester), contains(o.rapprochement));
  });

  testWidgets('contre-epreuve : Contractuels revient avec son port', (
    WidgetTester tester,
  ) async {
    await _comptable(
      tester,
      Routes.comptablePaiements,
      surcharges: <Override>[
        portObligationsContractuelsProvider.overrideWithValue(
          ObligationsContractuelsDemo(),
        ),
      ],
    );
    expect(_onglets(tester), contains(o.contractuels));
  });
}
