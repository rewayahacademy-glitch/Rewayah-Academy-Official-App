// CPT-FUS : chaque ecran de la demonstration Comptable (les pages livrees
// par les six voies, dans la vraie coquille du role ou la coquille admin du
// delta Direction) a 320 px, texte x2, en VRAIES polices : aucune exception
// de mise en page, aucun mot coupe ni tronque sur l'ecran entier.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';

import '../../../capture/outil_capture.dart';
import '../../../support/aucun_mot_coupe.dart';
import '../../admin_finance/reserve_delegation/support_direction.dart';

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
  });

  testWidgets('garde-fou : les vraies polices sont actives', (
    WidgetTester tester,
  ) async {
    expect(
      largeurSonde('PlusJakartaSans'),
      lessThan(largeurSonde('FamilleInexistante') * 0.6),
    );
  });

  for (final EcranDemoComptable ecran in EcranDemoComptable.values) {
    testWidgets('320 px, texte x2, ${ecran.name} : aucun mot coupe', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(320, 2400), 2);
      await tester.pumpWidget(
        hoteCapture(
          CoquilleComptableDemo(ecran: ecran),
          surcharges: surchargesCoquilleComptableDemo(montantsAffiches: false),
          echelleTexte: 2,
        ),
      );
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
      final List<String> fautes = motsCoupes(
        tester,
        find.byKey(cadreCapture),
        traitDUnionPermis: true,
      );
      for (final String f in fautes) {
        debugPrint('FAUTE ${ecran.name} | $f');
      }
      expect(fautes, isEmpty, reason: '${ecran.name} : $fautes');
    });
  }

  testWidgets('320 px, texte x2, /demo/finance?ecran=reserveDelegation : '
      'FinancePage (onglets, titre) sans mot coupe', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(320, 2400), 2);
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
            builder: (BuildContext contexte, Widget? app) => MediaQuery(
              data: MediaQuery.of(contexte)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: app!,
            ),
            routerConfig: routeur,
          ),
        ),
      ),
    );
    await stabiliser(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(FinancePage), findsOneWidget);
    final List<String> fautes = motsCoupes(
      tester,
      find.byType(MaterialApp),
      traitDUnionPermis: true,
    );
    for (final String f in fautes) {
      debugPrint('FAUTE finance | $f');
    }
    expect(fautes, isEmpty, reason: 'finance : $fautes');
  });
}
