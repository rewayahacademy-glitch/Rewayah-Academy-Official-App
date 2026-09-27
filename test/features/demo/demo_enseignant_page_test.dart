// EN-1b : /demo/enseignant n'existe pas en production, et monte la VRAIE
// coquille enseignant sur les donnees de demonstration.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/creneaux/creneaux_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/enseignant_classes/mes_classes_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';

void main() {
  test('/demo/enseignant absente en production, presente ailleurs', () {
    expect(routesDemoEnseignant('production'), isEmpty);
    expect(routesDemoEnseignant(' Production '), isEmpty);
    expect(routesDemoEnseignant(''), isEmpty);
    expect(routesDemoEnseignant('development'), hasLength(1));
  });

  test('la porte ne laisse passer /demo/enseignant que hors production', () {
    String? decider(String environnement) => deciderRedirection(
      session: const SessionState.deconnecte(),
      cheminDemande: Routes.demoEnseignant,
      maintenant: DateTime.utc(2026, 9, 26),
      environnement: environnement,
    );
    expect(decider('production'), isNotNull);
    expect(decider('development'), isNull);
  });

  test('les donnees de demonstration suivent 00_MAQUETTES section 3', () {
    final List<String> noms = <String>[
      for (final ClasseEnseignantDemo c in DonneesEnseignantDemo.classes) c.nom,
    ];
    expect(noms, <String>['An-Nour', 'Al-Fatiha', 'Al-Badr', 'Al-Ikhlas']);
    expect(DonneesEnseignantDemo.classes.first.eleves, hasLength(4));
    expect(DonneesEnseignantDemo.classes[1].remplacement, isFalse);
    expect(DonneesEnseignantDemo.classes.last.prochaineSeance, isNull);
    for (final SeanceEnseignant s in DonneesEnseignantDemo.seances(
      EtatDemoEnseignant.nominal,
    )) {
      expect(s.debut.year, 2026);
      expect(s.debut.month, anyOf(9, 10));
    }
  });

  Future<GoRouter> monter(WidgetTester tester, String depart) async {
    final GoRouter routeur = GoRouter(
      initialLocation: depart,
      routes: routesDemoEnseignant('dev'),
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

  testWidgets('la liste propose chaque ecran x situation', (
    WidgetTester tester,
  ) async {
    await monter(tester, Routes.demoEnseignant);
    for (final EcranDemoEnseignant ecran in EcranDemoEnseignant.values) {
      for (final EtatDemoEnseignant etat in EtatDemoEnseignant.values) {
        expect(
          find.byKey(ValueKey<String>('lien-${ecran.name}-${etat.name}')),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets('chaque ecran monte la vraie page dans la vraie coquille', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monter(
      tester,
      adresseDemoEnseignant(EcranDemoEnseignant.aujourdhui),
    );
    final Map<EcranDemoEnseignant, Type> pages = <EcranDemoEnseignant, Type>{
      EcranDemoEnseignant.aujourdhui: JourneePage,
      EcranDemoEnseignant.classes: MesClassesPage,
      EcranDemoEnseignant.disponibilites: CreneauxPage,
      EcranDemoEnseignant.profil: ProfilEnseignantPage,
    };
    for (final MapEntry<EcranDemoEnseignant, Type> p in pages.entries) {
      routeur.go(adresseDemoEnseignant(p.key));
      await tester.pumpAndSettle();
      expect(find.byType(p.value), findsOneWidget, reason: p.key.name);
      final NavShell coquille = tester.widget<NavShell>(find.byType(NavShell));
      expect(coquille.destinations, hasLength(4));
      expect(coquille.indexActif, p.key.index);
    }
  });
}
