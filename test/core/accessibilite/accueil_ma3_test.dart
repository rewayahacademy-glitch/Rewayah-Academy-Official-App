// MA-3 : l'Accueil de l'eleve en Mode Accessibilite. On ouvre la VRAIE route
// de demonstration /demo/accessibilite, on tape « Accueil » dans la vraie
// coquille, puis l'action principale de l'Accueil (« Voir ma classe ») : on
// arrive sur Ma classe (le vrai Espace Classe). Un seul emplacement d'entree,
// jamais « Rejoindre » a cote d'une ligne d'etat, trois taches au plus, deux
// colonnes seulement sur bureau et jamais a 200 %.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_accessibilite.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';

import '../../router/support_routeur.dart' show stabiliser;

const List<(Size, Key)> _formes = <(Size, Key)>[
  (Size(390, 844), NavShell.barreBasseKey),
  (Size(768, 1024), NavShell.railKey),
  (Size(1440, 900), NavShell.barreLateraleKey),
];

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  EleveDemoAccessibilite eleve = EleveDemoAccessibilite.mariam,
  MomentDemoAccessibilite moment = MomentDemoAccessibilite.avant,
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoAccessibilite(eleve, moment: moment),
    routes: routesDemoAccessibilite('local'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
          ),
          child: MaterialApp.router(
            routerConfig: routeur,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

Finder _dans(Key forme, String libelle) =>
    find.descendant(of: find.byKey(forme), matching: find.text(libelle));

void main() {
  for (final (Size taille, Key forme) in _formes) {
    testWidgets(
      'route de demonstration, ${taille.width.toInt()} : Accueil, puis '
      '« Voir ma classe » mene a Ma classe',
      (WidgetTester tester) async {
        await _monter(tester, taille);
        await tester.tap(_dans(forme, t.nav.eleve.accueil));
        await stabiliser(tester);
        expect(find.byType(AccueilAccessibilite), findsOneWidget);
        expect(
          find.text(t.accessibilite.accueil.salutation(prenom: 'Mariam')),
          findsOneWidget,
        );
        // Avant la seance : une ligne d'etat et un seul bouton, jamais
        // « Rejoindre ».
        expect(find.byType(ActionPrincipale), findsOneWidget);
        expect(find.byKey(AccueilAccessibilite.cleVoirClasse), findsOneWidget);
        // Trois taches au plus, le Coran, l'aide.
        expect(find.text(t.accessibilite.accueil.lireCoran), findsOneWidget);
        expect(find.text(t.accessibilite.accueil.aide), findsOneWidget);
        // Deux colonnes seulement sur bureau.
        expect(
          find.byKey(AccueilAccessibilite.cleDeuxColonnes),
          taille.width >= 1200 ? findsOneWidget : findsNothing,
        );

        await tester.ensureVisible(
          find.byKey(AccueilAccessibilite.cleVoirClasse),
        );
        await tester.tap(find.byKey(AccueilAccessibilite.cleVoirClasse));
        await stabiliser(tester);
        expect(
          tester.widget<NavShell>(find.byType(NavShell)).indexActif,
          EcranAccessibiliteDemo.indexMaClasse,
        );
        expect(find.byType(EspaceGroupePage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Idriss, apres la seance : l Accueil et « Lire le Coran »', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const Size(390, 844),
      eleve: EleveDemoAccessibilite.idriss,
      moment: MomentDemoAccessibilite.apres,
    );
    await tester.tap(
      _dans(NavShell.barreBasseKey, t.nav.eleve.accueil),
    );
    await stabiliser(tester);
    expect(
      find.text(t.accessibilite.accueil.salutation(prenom: 'Idriss')),
      findsOneWidget,
    );
    final Finder coran = find.text(t.accessibilite.accueil.lireCoran);
    await tester.ensureVisible(coran);
    await tester.tap(coran);
    await stabiliser(tester);
    expect(
      tester.widget<NavShell>(find.byType(NavShell)).indexActif,
      EcranAccessibiliteDemo.indexCoran,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('bureau a 200 % : une seule colonne, rien ne deborde', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900), echelle: 2);
    await tester.tap(
      _dans(NavShell.barreLateraleKey, t.nav.eleve.accueil),
    );
    await stabiliser(tester);
    expect(find.byType(AccueilAccessibilite), findsOneWidget);
    expect(find.byKey(AccueilAccessibilite.cleDeuxColonnes), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seance ouverte : « Rejoindre » est le seul bouton', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bool rejoint = false;
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.enfant, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: AccueilAccessibilite(
              prenom: 'Mariam',
              espace: DonneesAccessibiliteDemo.espaceAccueil(
                MomentDemoAccessibilite.pendant,
              ),
              onVoirClasse: () {},
              onRejoindre: () => rejoint = true,
              onCoran: () {},
              onAide: () {},
            ),
          ),
        ),
      ),
    );
    await stabiliser(tester);
    expect(find.byKey(AccueilAccessibilite.cleVoirClasse), findsNothing);
    final Finder rejoindre = find.byType(ActionPrincipale);
    expect(rejoindre, findsOneWidget);
    await tester.tap(rejoindre);
    expect(rejoint, isTrue);
  });
}
