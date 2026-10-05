// CPT-DIR-1 : l'onglet « Reserve et delegation » : les deux panneaux lus sur
// leurs ports, les cinq etats, l'enregistrement de bout en bout, et la
// demonstration `/demo/finance?ecran=reserveDelegation` dans la vraie
// coquille admin.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_delegation_finance.dart';
import 'package:rewayah_academy/core/capacites/port_politique_reserve.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/bascule_montants.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';
import 'package:rewayah_academy/core/widgets/section_header.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/admin_finance/reserve_delegation/finance_delegation_policy_panel.dart';
import 'package:rewayah_academy/features/admin_finance/reserve_delegation/strategic_reserve_policy_panel.dart';
import 'package:rewayah_academy/features/admin_finance/reserve_delegation_page.dart';
import 'package:rewayah_academy/features/demo/comptable/direction_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/socle_comptable_demo.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';

import 'support_direction.dart';

final c = t.comptable.direction;

List<Override> _demo({
  PolitiqueReserveDemo? reserve,
  DelegationFinanceDemo? delegation,
}) => <Override>[
  portPolitiqueReserveProvider.overrideWithValue(
    reserve ?? PolitiqueReserveDemo(),
  ),
  portDelegationFinanceProvider.overrideWithValue(
    delegation ?? DelegationFinanceDemo(),
  ),
];

/// Un port de reserve qui echoue, ou ne repond jamais.
class _ReserveEnPanne implements PortPolitiqueReserve {
  _ReserveEnPanne(this.erreur, {this.attente});

  final Object erreur;
  final Completer<PolitiqueReserve>? attente;
  int lectures = 0;

  @override
  Future<PolitiqueReserve> politique() {
    lectures++;
    return attente?.future ?? Future<PolitiqueReserve>.error(erreur);
  }

  @override
  Future<IndicateursReserve> indicateurs() =>
      Future<IndicateursReserve>.error(erreur);

  @override
  Future<PolitiqueReserve> enregistrer({
    required BrouillonPolitiqueReserve brouillon,
    required String cleIdempotence,
  }) => Future<PolitiqueReserve>.error(erreur);

  @override
  Future<List<EntreeJournal>> journal() =>
      Future<List<EntreeJournal>>.error(erreur);
}

/// Le titre de section [texte] (l'historique de la demonstration reprend le
/// meme objet, d'ou la recherche sous `SectionHeader`).
Finder _titre(String texte) =>
    find.descendant(of: find.byType(SectionHeader), matching: find.text(texte));

int _etats(NatureEtat nature) => find
    .byWidgetPredicate((Widget w) => w is EtatSysteme && w.nature == nature)
    .evaluate()
    .length;

void main() {
  testWidgets('contenu : la Reserve (etat actuel, politique, historique) '
      'puis la delegation, montants masques', (WidgetTester tester) async {
    taille(tester, const Size(1440, 6000));
    await tester.pumpWidget(
      hoteDirection(const ReserveDelegationPage(), surcharges: _demo()),
    );
    await tester.pumpAndSettle();

    expect(_titre(c.reserve), findsOneWidget);
    expect(_titre(c.delegation), findsOneWidget);
    expect(find.text(c.sousTitre), findsOneWidget);
    expect(find.byType(StrategicReservePolicyPanel), findsOneWidget);
    expect(find.byType(FinanceDelegationPolicyPanel), findsOneWidget);
    expect(find.text(c.etatActuel), findsOneWidget);
    expect(find.text(t.comptable.commun.reserveStrategique), findsOneWidget);
    // Deux historiques : deux « Version 1/2 » enregistrees par la direction.
    expect(find.text(c.historique), findsNWidgets(2));
    expect(find.byType(EtatSysteme), findsNothing);

    // Masques par defaut : le masque de la devise, jamais le chiffre.
    final String masque = MontantSensible.masquePour('USD');
    expect(find.text(masque), findsWidgets);
    final String actuel = formaterMontant(SocleComptableDemo.usd(7400));
    expect(find.text(actuel), findsNothing);
    await tester.tap(find.byKey(BasculeMontants.cleBouton));
    await tester.pumpAndSettle();
    expect(find.text(actuel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production : sans port, « Pas encore disponible » deux fois, '
      'aucun chiffre, aucun bouton d enregistrement', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 3000));
    await tester.pumpWidget(hoteDirection(const ReserveDelegationPage()));
    await tester.pumpAndSettle();
    expect(_etats(NatureEtat.indisponible), 2);
    expect(find.text(c.enregistrer), findsNothing);
    expect(find.byType(StrategicReservePolicyPanel), findsNothing);
  });

  testWidgets('chargement : le squelette, aucun champ', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 3000));
    final _ReserveEnPanne port = _ReserveEnPanne(
      Exception('x'),
      attente: Completer<PolitiqueReserve>(),
    );
    await tester.pumpWidget(
      hoteDirection(
        const StrategicReservePolicyPanelBloc(),
        surcharges: <Override>[
          portPolitiqueReserveProvider.overrideWithValue(port),
        ],
      ),
    );
    await tester.pump();
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('erreur : l etat dit quoi faire et « Reessayer » relit', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 3000));
    final _ReserveEnPanne port = _ReserveEnPanne(Exception('x'));
    await tester.pumpWidget(
      hoteDirection(
        const StrategicReservePolicyPanelBloc(),
        surcharges: <Override>[
          portPolitiqueReserveProvider.overrideWithValue(port),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(_etats(NatureEtat.echecServeur), 1);
    expect(port.lectures, 1);
    await tester.tap(
      find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
    );
    await tester.pumpAndSettle();
    expect(port.lectures, 2);
  });

  testWidgets('hors ligne : un echec sans reseau se dit hors ligne', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 3000));
    final _ReserveEnPanne port = _ReserveEnPanne(Exception('x'));
    await tester.pumpWidget(
      hoteDirection(
        const StrategicReservePolicyPanelBloc(),
        surcharges: <Override>[
          portPolitiqueReserveProvider.overrideWithValue(port),
        ],
        horsLigne: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(_etats(NatureEtat.horsLigne), 1);
    expect(_etats(NatureEtat.echecServeur), 0);
  });

  testWidgets('capacite absente meme hors ligne : indisponible, pas '
      'hors ligne', (WidgetTester tester) async {
    taille(tester, const Size(1440, 3000));
    final _ReserveEnPanne port = _ReserveEnPanne(
      const CapaciteIndisponible('CPT-BR-12'),
    );
    await tester.pumpWidget(
      hoteDirection(
        const StrategicReservePolicyPanelBloc(),
        surcharges: <Override>[
          portPolitiqueReserveProvider.overrideWithValue(port),
        ],
        horsLigne: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(_etats(NatureEtat.indisponible), 1);
  });

  testWidgets('enregistrer de bout en bout : la version suit, l historique '
      'grandit, le retour dit « enregistree »', (WidgetTester tester) async {
    taille(tester, const Size(900, 6000));
    final PolitiqueReserveDemo reserve = PolitiqueReserveDemo();
    await tester.pumpWidget(
      hoteDirection(
        const StrategicReservePolicyPanelBloc(),
        surcharges: _demo(reserve: reserve),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(c.versionDepuis(version: '2', date: '15 septembre 2026')),
      findsOneWidget,
    );

    final Finder cible = find.descendant(
      of: find.byWidgetPredicate(
        (Widget w) =>
            w is Semantics &&
            w.properties.label == c.reservePanneau.montantCible,
      ),
      matching: find.byType(TextField),
    );
    await tester.enterText(cible, '12000');
    await tester.pump();
    final Finder bouton = find.descendant(
      of: find.byKey(StrategicReservePolicyPanel.enregistrerKey),
      matching: find.text(c.enregistrer),
    );
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();

    final PolitiqueReserve apres = await reserve.politique();
    expect(apres.version, '3');
    expect(apres.montantCible!.mineur, 1200000);
    expect(find.text(c.enregistree), findsOneWidget);
    expect(find.text(c.versionSansDate(version: '3')), findsNothing);
    expect(
      find.text(c.versionDepuis(version: '3', date: '4 octobre 2026')),
      findsOneWidget,
    );
    expect((await reserve.journal()).length, 2);
    // Plus rien a enregistrer : la version vient d'etre prise.
    expect(find.text(c.enregistree), findsOneWidget);
  });

  testWidgets('delegation de bout en bout : la version 2 est lue', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(900, 6000));
    final DelegationFinanceDemo delegation = DelegationFinanceDemo();
    await tester.pumpWidget(
      hoteDirection(
        const FinanceDelegationPolicyPanelBloc(),
        surcharges: _demo(delegation: delegation),
      ),
    );
    await tester.pumpAndSettle();
    final Finder interrupteur = find.byType(Switch).first;
    await tester.ensureVisible(interrupteur);
    await tester.tap(interrupteur);
    await tester.pump();
    final Finder bouton = find.descendant(
      of: find.byKey(FinanceDelegationPolicyPanel.enregistrerKey),
      matching: find.text(c.enregistrer),
    );
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    final PolitiqueDelegationFinance apres = await delegation.politique();
    expect(apres.version, '2');
    expect(apres.paiementsStandardsAutorises, isFalse);
    expect(apres.autoPayoutInterdit, isTrue);
    expect(find.text(c.enregistree), findsOneWidget);
  });

  for (final (String, double, Size, TextDirection) cas
      in <(String, double, Size, TextDirection)>[
        ('320 px, texte x2', 2, const Size(320, 900), TextDirection.ltr),
        ('390 px, RTL', 1, const Size(390, 900), TextDirection.rtl),
        ('1440 px', 1, const Size(1440, 900), TextDirection.ltr),
      ]) {
    testWidgets('mise en page : ${cas.$1}', (WidgetTester tester) async {
      taille(tester, cas.$3);
      await tester.pumpWidget(
        hoteDirection(
          const ReserveDelegationPage(),
          surcharges: _demo(),
          echelle: cas.$2,
          sens: cas.$4,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_titre(c.reserve), findsOneWidget);
    });
  }

  testWidgets('/demo/finance?ecran=reserveDelegation : dans la vraie '
      'coquille admin, un seul PageShell', (WidgetTester tester) async {
    taille(tester, const Size(1440, 900));
    final GoRouter routeur = GoRouter(
      initialLocation: adresseDemoFinance(OngletFinance.reserveDelegation),
      routes: routesDemoFinance('staging'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: sessionDirection(),
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: routeur,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(FinancePage), findsOneWidget);
    expect(find.byType(ReserveDelegationPage), findsOneWidget);
    expect(find.byType(StrategicReservePolicyPanel), findsOneWidget);
    expect(find.byType(FinanceDelegationPolicyPanel), findsOneWidget);
    expect(find.byType(EtatSysteme), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
