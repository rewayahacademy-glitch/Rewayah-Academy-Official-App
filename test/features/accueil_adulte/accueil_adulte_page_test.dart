// EA-2 : l'accueil de l'eleve adulte, atteint depuis la VRAIE coquille adulte
// en tapant la VRAIE destination « Accueil » (K-07), puis ses etats.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/core/widgets/timeline_row.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/emplacements_groupe.dart';

void main() {
  Widget app({required Widget child, List<Override> overrides = const []}) =>
      ProviderScope(
        overrides: overrides,
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: child,
          ),
        ),
      );

  Future<void> monterCoquille(WidgetTester tester, String depart) async {
    final GoRouter routeur = GoRouter(
      initialLocation: depart,
      routes: routesDemoAdulte('dev'),
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
  }

  void taille(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('la destination Accueil de la coquille ouvre le vrai accueil', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.monEspace));
    expect(find.byType(AccueilAdultePage), findsNothing);

    await tester.tap(find.text(t.adulte.nav.accueil).first);
    await tester.pumpAndSettle();

    expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 0);
    expect(find.byType(AccueilAdultePage), findsOneWidget);
    expect(
      find.text(t.adulte.accueil.salutation(prenom: 'Mamadou')),
      findsOneWidget,
    );
    expect(find.text(t.adulte.accueil.prochaineSeance), findsOneWidget);
    expect(find.byType(CarteSession), findsOneWidget);
    // Avant le prochain cours : trois actions au plus, celles des donnees.
    expect(find.byType(EmplacementAvantProchainCours), findsOneWidget);
    for (final a in DonneesClasseDemo.actions) {
      expect(find.text(a.libelle), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.byType(BlocBibliotheque),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(DonneesAdulteDemo.ligneParcours), findsOneWidget);
    expect(find.byType(TimelineRow), findsNWidgets(3));
    // Une seule absence porte une pastille ; une presence n'en porte pas.
    expect(
      find.widgetWithText(StatusPill, t.adulte.accueil.absence),
      findsOneWidget,
    );
    expect(find.text(t.adulte.accueil.ressources), findsOneWidget);
  });

  testWidgets('bureau : seance et « Avant » cote a cote', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 1000));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.accueil));
    final Offset carte = tester.getTopLeft(find.byType(CarteSession));
    final Offset avant = tester.getTopLeft(
      find.byType(EmplacementAvantProchainCours),
    );
    expect(avant.dx, greaterThan(carte.dx));
    expect(avant.dy, lessThan(carte.dy));
  });

  testWidgets('vue du second adulte : son prenom', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.accueil,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    expect(
      find.text(t.adulte.accueil.salutation(prenom: 'Mariama')),
      findsOneWidget,
    );
  });

  testWidgets(
    'hors ligne : la ligne d\'etat de l\'emplacement, pas de bouton',
    (WidgetTester tester) async {
      taille(tester, const Size(390, 844));
      await monterCoquille(
        tester,
        adresseDemoAdulte(
          EcranDemoAdulte.accueil,
          seance: EtatDemoClasse.horsLigne,
        ),
      );
      expect(find.text(t.classe.entree.horsLigne), findsOneWidget);
      expect(find.text(t.classe.entree.rejoindre), findsNothing);
    },
  );

  testWidgets('chargement : le squelette de la carte de seance', (
    WidgetTester tester,
  ) async {
    final Completer<AccueilAdulteVM> jamais = Completer<AccueilAdulteVM>();
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          accueilAdulteProvider.overrideWith((Ref _) => jamais.future),
        ],
        child: const AccueilAdultePage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(SqueletteCarteSession), findsOneWidget);
    expect(find.byType(CarteSession), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('erreur : « Reessayer », et rien d\'invente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          accueilAdulteProvider.overrideWith(
            (Ref _) => Future<AccueilAdulteVM>.error(StateError('reseau')),
          ),
        ],
        child: const AccueilAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.commun.reessayer), findsWidgets);
    expect(find.byType(CarteSession), findsNothing);
  });

  testWidgets('sans source serveur : indisponible, sans « Reessayer »', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(child: const AccueilAdultePage()));
    await tester.pumpAndSettle();
    expect(find.text(t.commun.reessayer), findsNothing);
    expect(find.byType(CarteSession), findsNothing);
  });

  testWidgets('vide : aucune classe, un etat subi sans bouton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          accueilAdulteProvider.overrideWith(
            (Ref _) async => const AccueilAdulteVM(prenom: 'Mamadou'),
          ),
        ],
        child: const AccueilAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.adulte.accueil.aucuneClasse), findsOneWidget);
    expect(find.byType(CarteSession), findsNothing);
    expect(find.byType(TimelineRow), findsNothing);
  });
}
