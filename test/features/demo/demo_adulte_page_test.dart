// EA-1b : /demo/adulte n'existe pas en production, monte la VRAIE coquille
// (NavShell) a trois destinations, et « Ma famille » ouvre le VRAI Foyer
// dans la coquille du tuteur.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../support/demo/adulte_demo.dart';
import '../../support/demo/demo_adulte_page.dart';

void main() {
  test('/demo/adulte absente en production, presente ailleurs', () {
    expect(routesDemoAdulte('production'), isEmpty);
    expect(routesDemoAdulte(' Production '), isEmpty);
    expect(routesDemoAdulte(''), isEmpty);
    expect(routesDemoAdulte('development'), hasLength(1));
  });

  test('la porte ne laisse passer /demo/adulte que hors production', () {
    String? decider(String environnement) => deciderRedirection(
      session: const SessionState.deconnecte(),
      cheminDemande: Routes.demoAdulte,
      maintenant: DateTime.utc(2026, 9, 27),
      environnement: environnement,
    );
    expect(decider('production'), isNotNull);
    expect(decider('development'), isNull);
  });

  test('le foyer Diallo suit 00_MAQUETTES section 3 et le doc section 18', () {
    expect(EtatDemoAdulte.values, hasLength(25));
    expect(
      DonneesAdulteDemo.prenomTitulaire(GenreTitulaireDemo.homme),
      'Mamadou',
    );
    expect(
      DonneesAdulteDemo.prenomSecondAdulte(GenreTitulaireDemo.homme),
      'Mariama',
    );
    expect(
      DonneesAdulteDemo.prenomTitulaire(GenreTitulaireDemo.femme),
      'Mariama',
    );
    expect(DonneesAdulteDemo.enfants.map((e) => e.prenom), <String>[
      'Aïcha',
      'Oumar',
    ]);
    // Une seule ligne famille, selon la situation et la vue.
    expect(
      DonneesAdulteDemo.ligneFamille(
        EtatDemoAdulte.adulteSeul,
        VueDemoAdulte.titulaire,
      ),
      LigneFamilleDemo.ajouterMaFamille,
    );
    expect(
      DonneesAdulteDemo.ligneFamille(
        EtatDemoAdulte.conjointActif,
        VueDemoAdulte.titulaire,
      ),
      LigneFamilleDemo.maFamille,
    );
    expect(
      DonneesAdulteDemo.ligneFamille(
        EtatDemoAdulte.conjointActif,
        VueDemoAdulte.secondAdulte,
      ),
      LigneFamilleDemo.forfaitFamille,
    );
    // La fin de delai est une donnee, jamais un calcul (F17).
    expect(
      DonneesAdulteDemo.finDelaiPour(EtatDemoAdulte.delai60),
      DateTime.utc(2026, 12, 18),
    );
    expect(
      DonneesAdulteDemo.finDelaiPour(EtatDemoAdulte.conjointActif),
      isNull,
    );
    // Chaque situation a son libelle.
    for (final EtatDemoAdulte e in EtatDemoAdulte.values) {
      expect(libelleEtatDemoAdulte(e), isNotEmpty, reason: e.name);
    }
  });

  Future<GoRouter> monter(WidgetTester tester, String depart) async {
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
    return routeur;
  }

  testWidgets('la liste propose chaque ecran, variante et situation', (
    WidgetTester tester,
  ) async {
    await monter(tester, Routes.demoAdulte);
    expect(find.text(t.adulte.demo.titre), findsWidgets);
    expect(find.byKey(const ValueKey<String>('lien-ecran-accueil')), findsOne);
    expect(
      find.byKey(const ValueKey<String>('lien-etat-emancipation')),
      findsOne,
    );
  });

  testWidgets('la coquille a trois destinations, chacune tapee', (
    WidgetTester tester,
  ) async {
    await monter(tester, adresseDemoAdulte(EcranDemoAdulte.accueil));
    NavShell coquille() => tester.widget<NavShell>(find.byType(NavShell));
    // Trois destinations : Mon espace est supprime (MON-ESPACE-ADULTE-SUPPR,
    // 11/11/2026).
    expect(coquille().destinations, hasLength(3));
    expect(coquille().indexActif, 0);
    for (final (int i, String libelle) in <(int, String)>[
      (1, t.adulte.nav.maClasse),
      (2, t.adulte.nav.coran),
      (0, t.adulte.nav.accueil),
    ]) {
      await tester.tap(find.text(libelle).first);
      await tester.pumpAndSettle();
      expect(coquille().destinations, hasLength(3), reason: libelle);
      expect(coquille().indexActif, i, reason: libelle);
    }
  });

  testWidgets('Ma famille ouvre le vrai Foyer, et on revient a l\'Accueil', (
    WidgetTester tester,
  ) async {
    // Ma famille par son adresse : Mon espace, qui l'ouvrait, est supprime
    // (MON-ESPACE-ADULTE-SUPPR, 11/11/2026).
    await monter(tester, adresseDemoAdulte(EcranDemoAdulte.maFamille));
    expect(find.byType(FoyerPage), findsOneWidget);
    expect(find.text('Aïcha'), findsWidgets);
    expect(find.text('Oumar'), findsWidgets);
    // La coquille du tuteur existante, jamais une cinquieme destination.
    expect(
      tester.widget<NavShell>(find.byType(NavShell)).destinations,
      hasLength(4),
    );
    await tester.tap(find.byKey(const ValueKey<String>('retour-accueil')));
    await tester.pumpAndSettle();
    expect(find.byType(FoyerPage), findsNothing);
    expect(find.byType(AccueilAdultePage), findsOneWidget);
    expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 0);
  });

  testWidgets('second adulte : Forfait famille', (WidgetTester tester) async {
    // Forfait famille par son adresse : Mon espace, dont la ligne famille
    // l'ouvrait, est supprime (MON-ESPACE-ADULTE-SUPPR, 11/11/2026).
    await monter(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.forfaitFamille,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    expect(find.byType(ForfaitFamillePage), findsOneWidget);
    // Hors des trois destinations, l'Accueil reste allume.
    expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 0);
  });

  // Revue EA-R (relecture EA-RC) : chaque barriere prouvee a part.
  Future<GoRouter> monterAvecEspion(
    WidgetTester tester,
    _ServiceAuthEspion espion,
    String depart,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final GoRouter routeur = GoRouter(
      initialLocation: depart,
      routes: <RouteBase>[
        ...routesDemoAdulte('dev'),
        // La vraie connexion de l'application : jamais atteinte depuis la
        // demonstration (K-28, F24).
        GoRoute(
          path: Routes.connexion,
          builder: (BuildContext _, GoRouterState _) =>
              const Text('connexion-reelle'),
        ),
      ],
    );
    addTearDown(routeur.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[serviceAuthProvider.overrideWithValue(espion)],
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

  testWidgets('barriere 1 (coquille adulte) : fermerDemo rend vrai, la '
      'carte ne descend jamais au service', (WidgetTester tester) async {
    final _ServiceAuthEspion espion = _ServiceAuthEspion();
    await monterAvecEspion(
      tester,
      espion,
      adresseDemoAdulte(EcranDemoAdulte.accueil),
    );
    final ProviderContainer conteneur = ProviderScope.containerOf(
      tester.element(find.byType(AccueilAdultePage)),
    );

    // Barriere 2, presente aussi : le service vu par la coquille n'est pas
    // celui de l'application.
    expect(conteneur.read(serviceAuthProvider), isNot(same(espion)));
    // Barriere 1 : la session de demonstration se ferme localement.
    expect(conteneur.read(sessionProvider.notifier).fermerDemo(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(NavShell), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('lien-ecran-accueil')),
      findsOneWidget,
    );
    expect(espion.appels, 0);
  });

  testWidgets('barriere 2 (coquille du tuteur, Ma famille) : le service de '
      'demonstration est atteint, aucun appel reel', (
    WidgetTester tester,
  ) async {
    final _ServiceAuthEspion espion = _ServiceAuthEspion();
    await monterAvecEspion(
      tester,
      espion,
      adresseDemoAdulte(EcranDemoAdulte.maFamille),
    );
    expect(find.byType(FoyerPage), findsOneWidget);
    final ServiceAuth service = ProviderScope.containerOf(
      tester.element(find.byType(FoyerPage)),
    ).read(serviceAuthProvider);
    expect(service, isNot(same(espion)));
    await service.envoyerLienCourriel('demo@example.com');
    await service.connexionGoogle();
    await service.connexionMotDePasse('demo@example.com', 'x');
    await service.deconnexion();
    await tester.pumpAndSettle();
    expect(espion.appels, 0);
    expect(find.byType(FoyerPage), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('lien-ecran-accueil')),
      findsOneWidget,
    );
  });

  testWidgets('invitation sans compte : « Continuer » revient a la liste, '
      'jamais la vraie connexion (K-28, F24)', (WidgetTester tester) async {
    final _ServiceAuthEspion espion = _ServiceAuthEspion();
    final GoRouter routeur = await monterAvecEspion(
      tester,
      espion,
      adresseDemoAdulte(EcranDemoAdulte.invitationSansCompte),
    );
    final Finder continuer = find.byKey(InvitationSansComptePage.continuerKey);
    await tester.ensureVisible(continuer);
    await tester.tap(continuer);
    await tester.pumpAndSettle();
    expect(find.text('connexion-reelle'), findsNothing);
    expect(
      routeur.routerDelegate.currentConfiguration.uri.path,
      Routes.demoAdulte,
    );
    expect(
      find.byKey(const ValueKey<String>('lien-ecran-accueil')),
      findsOneWidget,
    );
    expect(espion.appels, 0);
  });
}

/// Le service d'authentification de l'application, espionne : chaque appel
/// compte, aucun ne part.
class _ServiceAuthEspion implements ServiceAuth {
  int appels = 0;

  @override
  Future<void> envoyerLienCourriel(
    String courriel, {
    String? jetonControle,
  }) async => appels++;

  @override
  Future<void> connexionMotDePasse(
    String courriel,
    String motDePasse, {
    String? jetonControle,
  }) async => appels++;

  @override
  Future<void> verifierCodeCourriel(String courriel, String code) async =>
      appels++;

  @override
  Future<void> connexionGoogle() async => appels++;

  @override
  Future<void> deconnexion() async => appels++;
}
