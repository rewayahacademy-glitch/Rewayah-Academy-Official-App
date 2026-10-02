// CT-7 : CTR-05 Historique et CTR-06 Detail, depuis la VRAIE route de
// demonstration. Historique -> ouvrir un rapport -> lien vers le fil de la
// mission ; « A terminer » -> compte rendu ; « Ajouter un complement » ouvre
// la page provisoire (CT-8) ; le port par defaut n'invente aucun rapport.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur_page.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  Size taille = const Size(1000, 1000),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: routesDemoControleur('dev'),
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

Future<void> _attendre(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> _versHistorique(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(NavShell.railKey),
      matching: find.text(t.nav.controleur.historique),
    ),
  );
  await _attendre(tester);
}

void main() {
  testWidgets('Historique -> rapport -> detail -> fil de la mission', (
    WidgetTester tester,
  ) async {
    final h = t.controleur.historique;
    final GoRouter routeur = await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.controle),
    );
    await _versHistorique(tester);
    expect(routeur.state.uri.queryParameters['ecran'], 'historique');
    expect(find.text('Cet écran est en préparation.'), findsNothing);

    // Trois rapports, statut ecrit, plus recent d'abord.
    expect(find.text(h.envoye), findsOneWidget);
    expect(find.text(h.complementAjoute), findsOneWidget);
    expect(find.text(h.aTerminer), findsOneWidget);
    final double yIkhlas = tester
        .getTopLeft(
          find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0926')),
        )
        .dy;
    final double yBadr = tester
        .getTopLeft(
          find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0924')),
        )
        .dy;
    final double yNour = tester
        .getTopLeft(
          find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0921')),
        )
        .dy;
    expect(yIkhlas < yBadr && yBadr < yNour, isTrue);

    // Detail en lecture : sections, observation, complement, presents.
    await tester.tap(
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0924')),
    );
    await tester.pumpAndSettle();
    expect(find.text(h.sectionMission), findsOneWidget);
    expect(find.text(t.controleur.compteRendu.faits), findsOneWidget);
    expect(find.text(h.sectionObservation), findsOneWidget);
    expect(find.text(h.sectionComplements), findsOneWidget);
    expect(find.text(h.sectionEchanges), findsOneWidget);
    expect(find.textContaining('huit minutes de retard'), findsOneWidget);
    expect(find.textContaining('coupure de connexion'), findsOneWidget);
    expect(find.textContaining('Bilal K.'), findsOneWidget);
    // Aucune edition : aucun champ de saisie.
    expect(find.byType(TextField), findsNothing);

    // « Ajouter un complement » : page provisoire (CT-8), puis retour.
    await tester.ensureVisible(
      find.byKey(HistoriqueControleurPage.complementKey),
    );
    await tester.tap(find.byKey(HistoriqueControleurPage.complementKey));
    await tester.pumpAndSettle();
    expect(find.text(h.provisoire), findsOneWidget);
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.text(h.sectionMission), findsOneWidget);

    // Le lien vers le fil d'echanges de la mission.
    await tester.ensureVisible(
      find.byKey(HistoriqueControleurPage.ecrireAdminKey),
    );
    await tester.tap(find.byKey(HistoriqueControleurPage.ecrireAdminKey));
    await _attendre(tester);
    expect(routeur.state.uri.queryParameters['ecran'], 'echanges');
    expect(
      routeur.state.uri.queryParameters['fil'],
      'demo-mission-al-badr-0924',
    );
    expect(find.byType(EchangesControleurPage), findsOneWidget);
    expect(find.textContaining('huit minutes de retard'), findsOneWidget);
  });

  testWidgets('un rapport sans fil ouvre un fil neuf de sa mission', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.historique),
      taille: const Size(390, 844),
    );
    await _attendre(tester);
    await tester.tap(
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0921')),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.controleur.compteRendu.rienASignaler), findsOneWidget);
    expect(find.text(t.controleur.historique.sansComplement), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(HistoriqueControleurPage.ecrireAdminKey),
    );
    await tester.tap(find.byKey(HistoriqueControleurPage.ecrireAdminKey));
    await _attendre(tester);
    expect(
      routeur.state.uri.queryParameters['fil'],
      'demo-mission-an-nour-0921',
    );
    expect(find.text(t.controleur.echanges.contexte), findsOneWidget);
  });

  testWidgets('« A terminer » reprend le compte rendu', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.historique),
    );
    await _attendre(tester);
    await tester.tap(
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0926')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CompteRenduControlePage), findsOneWidget);
    // La transmission de demonstration repond en 400 ms.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('le filtre Etat ne garde que les rapports choisis', (
    WidgetTester tester,
  ) async {
    final h = t.controleur.historique;
    await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.historique),
    );
    await _attendre(tester);
    await tester.tap(find.text(h.filtreEtat));
    await tester.pumpAndSettle();
    await tester.tap(find.text(h.envoye).last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0921')),
      findsOneWidget,
    );
    expect(
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0924')),
      findsNothing,
    );
    expect(find.text(h.resultats(n: 1)), findsOneWidget);
  });

  testWidgets('le port par defaut n\'invente aucun rapport', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const HistoriqueControleurPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.controleur.historique.vide), findsNothing);
    expect(find.text(t.controleur.historique.envoye), findsNothing);
  });
}
