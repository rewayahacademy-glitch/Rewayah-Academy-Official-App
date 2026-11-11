// PORTS-COMPTABLE (pilote, 11/11/2026) : les onglets du comptable sans
// serveur (Encaissements, Rapprochement, Contractuels) ne sont pas montres ;
// jamais un « indisponible » derriere un onglet. Contre-epreuve : avec les
// ports de demonstration, ils reviennent.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_beneficiaires_paiement.dart';
import 'package:rewayah_academy/core/capacites/port_encaissements.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_contractuels.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_payables.dart';
import 'package:rewayah_academy/core/capacites/port_rapprochement.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';
import 'package:rewayah_academy/features/comptable/paiements/paiements_page.dart';

import '../../router/support_routeur.dart';
import '../../support/demo/comptable/beneficiaires_demo.dart';
import '../../support/demo/comptable/contractuels_demo.dart';
import '../../support/demo/comptable/encaissements_demo.dart';
import '../../support/demo/comptable/paiements_demo.dart';
import '../../support/harnais.dart';
import 'paiements/support_paiements.dart';

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

    testWidgets('Paiements : ni onglet Contractuels ni onglet Beneficiaires', (
      WidgetTester tester,
    ) async {
      await _comptable(tester, Routes.comptablePaiements);
      final List<String> montres = _onglets(tester);
      expect(montres, contains(o.aEffectuer));
      expect(montres, isNot(contains(o.contractuels)));
      expect(montres, isNot(contains(o.beneficiaires)));
      expect(tester.takeException(), isNull);
    });

    // Point 6 (garde-cap) : « Relancer » n'est pas montre, jamais grise.
    testWidgets('Paiements a effectuer : des lignes a relancer, mais aucun '
        '« Relancer »', (WidgetTester tester) async {
      await _comptable(
        tester,
        // Les lignes a infos manquantes, celles que l'on relance.
        Routes.comptablePaiementsFiltres(filtre: 'infos'),
        surcharges: <Override>[
          portObligationsPayablesProvider.overrideWithValue(
            ObligationsPayablesDemo(EtatDemoPaiements()),
          ),
          ...surchargesCommunes(),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byType(PaiementsAEffectuerPage), findsOneWidget);
      expect(find.text(t.comptable.paiements.actions.relancer), findsNothing);
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

  testWidgets('contre-epreuve : Beneficiaires et « Relancer » reviennent avec '
      'le port des profils de paiement', (WidgetTester tester) async {
    await _comptable(
      tester,
      Routes.comptablePaiementsFiltres(filtre: 'infos'),
      surcharges: <Override>[
        portBeneficiairesPaiementProvider.overrideWithValue(
          const BeneficiairesPaiementDemo(),
        ),
        portObligationsPayablesProvider.overrideWithValue(
          ObligationsPayablesDemo(EtatDemoPaiements()),
        ),
        ...surchargesCommunes(),
      ],
    );
    await tester.pumpAndSettle();
    expect(_onglets(tester), contains(o.beneficiaires));
    expect(find.text(t.comptable.paiements.actions.relancer), findsWidgets);
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
