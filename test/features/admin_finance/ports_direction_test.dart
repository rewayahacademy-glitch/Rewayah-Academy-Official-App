// PORTS-DIRECTION (pilote, 11/11/2026) : plus aucun « indisponible » visible
// pour le directeur. Sans serveur (ports de production), Le Studio,
// l'onglet Moderation, la Vue globale, l'onglet Reserve et delegation,
// « Payer » et l'export ne sont pas montres ; la racine de la Finance tombe
// sur un onglet qui repond. Contre-epreuve : quand le serveur existe (port
// de demonstration), l'entree revient.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_payables.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/comptable/graphiques/action_export.dart';
import 'package:rewayah_academy/features/comptable/paiements/paiements_page.dart';

import '../../router/support_routeur.dart';
import '../../support/demo/comptable/paiements_demo.dart';
import '../../support/harnais.dart';
import '../com_studio/support_studio.dart';
import '../comptable/paiements/support_paiements.dart';

String _chemin(GoRouter r) => r.routerDelegate.currentConfiguration.uri.path;

Future<GoRouter> _direction(
  WidgetTester tester,
  String depart, {
  List<Override> surcharges = const <Override>[],
}) => monterRouteur(
  tester,
  depart,
  source: FausseSourceSession(sessionActive(AppRole.admin)),
  taille: const Size(1440, 900),
  surcharges: surcharges,
);

List<String> _ongletsMontres(WidgetTester tester) => <String>[
  for (final ({String libelle, String chemin}) o
      in tester
          .widget<SousNavigationDomaine>(find.byType(SousNavigationDomaine))
          .onglets)
    o.libelle,
];

/// Aucun etat « indisponible » rendu par la page.
void _aucunIndisponible() {
  for (final Element e in find.byType(EtatSysteme).evaluate()) {
    expect((e.widget as EtatSysteme).nature, isNot(NatureEtat.indisponible));
  }
}

void main() {
  test('ongletsOuverts : retire les onglets fermes, garde l onglet ouvert', () {
    final List<({String libelle, String chemin})> tous =
        <({String libelle, String chemin})>[
          (libelle: 'A', chemin: '/a'),
          (libelle: 'B', chemin: '/b'),
          (libelle: 'C', chemin: '/c'),
        ];
    final r = ongletsOuverts(tous, indexActif: 2, fermes: <int>{0});
    expect(r.onglets.map((o) => o.libelle), <String>['B', 'C']);
    expect(r.indexActif, 1);
    // Une adresse tapee sur un onglet ferme : il reste montre, actif.
    final r2 = ongletsOuverts(tous, indexActif: 0, fermes: <int>{0, 1});
    expect(r2.onglets.map((o) => o.libelle), <String>['A', 'C']);
    expect(r2.indexActif, 0);
  });

  group('sans serveur (ports de production)', () {
    testWidgets('Accueil admin : aucun « Le Studio » ; /admin/studio revient '
        'a l Accueil', (WidgetTester tester) async {
      final GoRouter routeur = await _direction(tester, Routes.admin);
      expect(find.byTooltip(t.com.socle.navigation.studio), findsNothing);
      expect(
        find.bySemanticsLabel(t.com.socle.navigation.ouvrirStudio),
        findsNothing,
      );
      routeur.go(Routes.adminStudio);
      await tester.pumpAndSettle();
      expect(_chemin(routeur), Routes.admin);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Finance : la racine tombe sur Politiques commerciales, sans '
        'Vue globale ni Reserve et delegation', (WidgetTester tester) async {
      final GoRouter routeur = await _direction(tester, Routes.adminFinance);
      expect(_chemin(routeur), Routes.adminFinancePolitiques);
      expect(find.byType(FinancePage), findsOneWidget);
      final List<String> montres = _ongletsMontres(tester);
      expect(montres, isNot(contains(t.admin.finance.vueGlobale)));
      expect(montres, isNot(contains(t.admin.finance.reserveDelegation)));
      expect(montres, contains(t.admin.finance.paieEnseignants));
      routeur.go(Routes.adminFinanceReserveDelegation);
      await tester.pumpAndSettle();
      expect(_chemin(routeur), Routes.adminFinancePolitiques);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Communications : aucun onglet Moderation ; son adresse '
        'revient aux Annonces', (WidgetTester tester) async {
      final GoRouter routeur = await _direction(
        tester,
        Routes.adminCommunicationsModeration,
      );
      expect(_chemin(routeur), Routes.adminCommunicationsAnnonces);
      expect(
        _ongletsMontres(tester),
        isNot(contains(t.com.socle.navigation.ongletModeration)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Paie des enseignants : des paiements a faire, mais aucune '
        'case, aucun « Payer », aucun export', (WidgetTester tester) async {
      await _direction(
        tester,
        Routes.adminFinancePaie,
        surcharges: <Override>[
          // Les paiements a faire de la demonstration ; le paiement et
          // l'export restent les ports de production (« indisponibles »).
          portObligationsPayablesProvider.overrideWithValue(
            ObligationsPayablesDemo(EtatDemoPaiements()),
          ),
          ...surchargesCommunes(),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byType(PaiementsAEffectuerPage), findsOneWidget);
      expect(find.text('Sayyid Youssouf Diallo'), findsWidgets);
      expect(find.byType(Checkbox), findsNothing);
      expect(
        find.byKey(PaiementsAEffectuerPage.cleSelectionnerPrets),
        findsNothing,
      );
      expect(
        find.text(t.comptable.paiements.actions.payerSelection),
        findsNothing,
      );
      expect(find.text(t.comptable.paiements.actions.payer), findsNothing);
      expect(find.byType(ActionExport), findsNothing);
      _aucunIndisponible();
      expect(tester.takeException(), isNull);
    });
  });

  group('contre-epreuve : quand le serveur existe', () {
    testWidgets('le paiement de demonstration rend les cases et « Payer »', (
      WidgetTester tester,
    ) async {
      await _direction(
        tester,
        Routes.adminFinancePaie,
        surcharges: surchargesDemo(EtatDemoPaiements()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('un Studio branche rend « Le Studio » dans l en-tete', (
      WidgetTester tester,
    ) async {
      await _direction(
        tester,
        Routes.admin,
        surcharges: <Override>[
          portStudioProvider.overrideWithValue(portDemo()),
        ],
      );
      expect(find.byTooltip(t.com.socle.navigation.studio), findsWidgets);
    });
  });
}
