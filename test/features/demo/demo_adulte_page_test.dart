// EA-1b : /demo/adulte n'existe pas en production, monte la VRAIE coquille
// (NavShell) a quatre destinations, et « Ma famille » ouvre le VRAI Foyer
// dans la coquille du tuteur.

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
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

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

  testWidgets('la coquille a quatre destinations, chacune tapee', (
    WidgetTester tester,
  ) async {
    await monter(tester, adresseDemoAdulte(EcranDemoAdulte.accueil));
    NavShell coquille() => tester.widget<NavShell>(find.byType(NavShell));
    expect(coquille().destinations, hasLength(4));
    expect(coquille().indexActif, 0);
    for (final (int i, String libelle) in <(int, String)>[
      (1, t.adulte.nav.maClasse),
      (2, t.adulte.nav.coran),
      (3, t.adulte.nav.monEspace),
      (0, t.adulte.nav.accueil),
    ]) {
      await tester.tap(find.text(libelle).first);
      await tester.pumpAndSettle();
      expect(coquille().destinations, hasLength(4), reason: libelle);
      expect(coquille().indexActif, i, reason: libelle);
    }
  });

  testWidgets('Ma famille ouvre le vrai Foyer, et on revient a Mon espace', (
    WidgetTester tester,
  ) async {
    await monter(tester, adresseDemoAdulte(EcranDemoAdulte.monEspace));
    expect(find.text(t.adulte.famille.maFamille), findsOneWidget);
    expect(find.text(t.adulte.famille.ajouter), findsNothing);
    expect(find.text(t.adulte.famille.forfaitFamille), findsNothing);
    // Mon espace est la vraie page (EA-4) : la ligne est sous les rubriques.
    await tester.ensureVisible(find.text(t.adulte.famille.maFamille));
    await tester.tap(find.text(t.adulte.famille.maFamille));
    await tester.pumpAndSettle();
    expect(find.byType(FoyerPage), findsOneWidget);
    expect(find.text('Aïcha'), findsWidgets);
    expect(find.text('Oumar'), findsWidgets);
    // La coquille du tuteur existante, jamais une cinquieme destination.
    expect(
      tester.widget<NavShell>(find.byType(NavShell)).destinations,
      hasLength(4),
    );
    await tester.tap(find.byKey(const ValueKey<String>('retour-mon-espace')));
    await tester.pumpAndSettle();
    expect(find.byType(FoyerPage), findsNothing);
    expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);
  });

  testWidgets('adulte seul : Ajouter ma famille ; second adulte : Forfait '
      'famille', (WidgetTester tester) async {
    final GoRouter routeur = await monter(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.monEspace,
        etat: EtatDemoAdulte.adulteSeul,
      ),
    );
    expect(find.text(t.adulte.famille.ajouter), findsOneWidget);
    expect(find.text(t.adulte.famille.maFamille), findsNothing);
    routeur.go(
      adresseDemoAdulte(
        EcranDemoAdulte.monEspace,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.adulte.famille.forfaitFamille), findsOneWidget);
    await tester.ensureVisible(find.text(t.adulte.famille.forfaitFamille));
    await tester.tap(find.text(t.adulte.famille.forfaitFamille));
    await tester.pumpAndSettle();
    expect(find.byType(ForfaitFamillePage), findsOneWidget);
    expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);
  });
}
