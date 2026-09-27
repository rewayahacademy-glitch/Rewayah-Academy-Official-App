// MA-1b : /demo/accessibilite n'existe pas en production, et ouvre, depuis la
// vraie route, le VRAI Espace Classe eleve en Mode Accessibilite.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';

void main() {
  test('/demo/accessibilite absente en production, presente ailleurs', () {
    expect(routesDemoAccessibilite('production'), isEmpty);
    expect(routesDemoAccessibilite(' Production '), isEmpty);
    expect(routesDemoAccessibilite(''), isEmpty);
    expect(routesDemoAccessibilite('development'), hasLength(1));
  });

  test('la porte ne laisse passer /demo/accessibilite que hors production', () {
    String? decider(String environnement) => deciderRedirection(
      session: const SessionState.deconnecte(),
      cheminDemande: Routes.demoAccessibilite,
      maintenant: DateTime.utc(2026, 9, 27),
      environnement: environnement,
    );
    expect(decider('production'), isNotNull);
    expect(decider('development'), isNull);
  });

  test('les donnees suivent 00_MAQUETTES section 4', () {
    expect(DonneesAccessibiliteDemo.mariamId, 'demo-eleve-mariam');
    expect(
      DonneesAccessibiliteDemo.mineur(EleveDemoAccessibilite.mariam),
      isTrue,
    );
    expect(
      DonneesAccessibiliteDemo.mineur(EleveDemoAccessibilite.idriss),
      isFalse,
    );
    expect(DonneesAccessibiliteDemo.classe, 'Classe An-Nour');
    expect(DonneesAccessibiliteDemo.presentation, InterfaceMode.enfant);
    expect(DonneesAccessibiliteDemo.nombreTravaux, lessThanOrEqualTo(3));
    for (final DateTime d in DonneesAccessibiliteDemo.seances) {
      expect(d.year, 2026);
      expect(d.month, anyOf(9, 10));
    }
    // L'observation n'est jamais montree pour l'adulte.
    for (final MomentDemoAccessibilite m in MomentDemoAccessibilite.values) {
      expect(
        DonneesAccessibiliteDemo.observationActive(
          EleveDemoAccessibilite.idriss,
          m,
        ),
        isFalse,
      );
    }
  });

  Future<GoRouter> monter(WidgetTester tester, String depart) async {
    final GoRouter routeur = GoRouter(
      initialLocation: depart,
      routes: routesDemoAccessibilite('dev'),
    );
    await tester.pumpWidget(
      ProviderScope(
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
    return routeur;
  }

  testWidgets('la liste propose chaque eleve x moment', (
    WidgetTester tester,
  ) async {
    await monter(tester, Routes.demoAccessibilite);
    expect(find.text(t.accessibilite.demo.titre), findsWidgets);
    for (final EleveDemoAccessibilite e in EleveDemoAccessibilite.values) {
      for (final MomentDemoAccessibilite m in MomentDemoAccessibilite.values) {
        expect(
          find.byKey(ValueKey<String>('lien-${e.name}-${m.name}')),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets('un lien ouvre la vraie page, Mode Accessibilite actif', (
    WidgetTester tester,
  ) async {
    await monter(tester, Routes.demoAccessibilite);
    final Finder lien = find.byKey(const ValueKey<String>('lien-mariam-avant'));
    await tester.ensureVisible(lien);
    await tester.tap(lien);
    await tester.pumpAndSettle();
    expect(find.byType(EspaceGroupePage), findsOneWidget);
    final ProviderContainer c = ProviderScope.containerOf(
      tester.element(find.byType(EspaceGroupePage)),
    );
    expect(c.read(modeAccessibiliteActifProvider), isTrue);
  });
}
