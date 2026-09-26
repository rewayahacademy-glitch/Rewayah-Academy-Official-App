// CL-4.2 : /demo/classe n'existe pas en production, et liste role x etat.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';

void main() {
  test('/demo/classe absente en production, presente ailleurs', () {
    expect(routesDemoClasse('production'), isEmpty);
    expect(routesDemoClasse(' Production '), isEmpty);
    expect(routesDemoClasse(''), isEmpty);
    expect(routesDemoClasse('development'), hasLength(1));
  });

  test('en production, la porte ne laisse pas passer /demo/classe', () {
    expect(
      deciderRedirection(
        session: const SessionState.deconnecte(),
        cheminDemande: Routes.demoClasse,
        maintenant: DateTime.utc(2026, 9, 26),
        environnement: 'production',
      ),
      isNotNull,
    );
    expect(
      deciderRedirection(
        session: const SessionState.deconnecte(),
        cheminDemande: Routes.demoClasse,
        maintenant: DateTime.utc(2026, 9, 26),
        environnement: 'development',
      ),
      isNull,
    );
  });

  testWidgets('la liste propose chaque role x etat, un lien ouvre le recap', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = GoRouter(
      initialLocation: Routes.demoClasse,
      routes: routesDemoClasse('dev'),
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
    for (final RoleEntree role in RoleEntree.values) {
      for (final EtatDemoClasse etat in EtatDemoClasse.values) {
        expect(
          find.byKey(ValueKey<String>('lien-${role.name}-${etat.name}')),
          findsOneWidget,
        );
      }
    }
    routeur.go(
      adresseDemoClasse(RoleEntree.enseignant, EtatDemoClasse.fenetreOuverte),
    );
    await tester.pumpAndSettle();
    expect(find.text("Préparer l'entrée"), findsOneWidget);
    expect(find.text('Forme : bouton'), findsOneWidget);
  });
}
