// EA-4 : Mon espace de l'eleve adulte, atteint depuis la VRAIE coquille
// adulte en tapant la VRAIE destination « Mon espace » (K-07), puis ses
// variantes (adulte seul, titulaire, second adulte) et ses etats.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/compte/carte_rubriques.dart';
import 'package:rewayah_academy/features/compte/compte_tuteur_page.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';

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

  Future<GoRouter> monterCoquille(WidgetTester tester, String depart) async {
    final GoRouter routeur = GoRouter(
      initialLocation: depart,
      routes: routesDemoAdulte('dev'),
    );
    addTearDown(routeur.dispose);
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

  void taille(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  final Finder ligneFamille = find.byKey(MonEspaceAdultePage.ligneFamilleKey);
  Finder dansFamille(String texte) =>
      find.descendant(of: ligneFamille, matching: find.text(texte));

  Future<void> voir(WidgetTester tester, Finder cible) =>
      tester.scrollUntilVisible(
        cible,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  testWidgets('la destination Mon espace de la coquille ouvre la vraie page : '
      'identite avec photo, rubriques groupees, une ligne famille', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.accueil));
    expect(find.byType(MonEspaceAdultePage), findsNothing);

    await tester.tap(find.text(t.adulte.nav.monEspace).last);
    await tester.pumpAndSettle();

    expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);
    expect(find.byType(MonEspaceAdultePage), findsOneWidget);
    // L'identite du Compte, reprise telle quelle, avec la photo (K-44).
    expect(find.byType(CarteIdentiteCompte), findsOneWidget);
    expect(find.text('Mamadou Diallo'), findsOneWidget);
    expect(find.text(t.adulte.monEspace.role), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CarteIdentiteCompte),
        matching: find.byType(PhotoEleve),
      ),
      findsOneWidget,
    );
    // « Mon compte » : les six rubriques, dont Mes accords et Paiements.
    for (final RubriqueMonEspace r in <RubriqueMonEspace>[
      RubriqueMonEspace.informations,
      RubriqueMonEspace.coursAcces,
      RubriqueMonEspace.paiements,
      RubriqueMonEspace.accords,
      RubriqueMonEspace.securite,
      RubriqueMonEspace.preferences,
    ]) {
      await voir(tester, find.text(_libelle(r)));
      expect(find.text(_libelle(r)), findsOneWidget, reason: r.name);
    }
    // Ni engrenage doublon, ni « Abonnements », ni pastille « Nouveau ».
    expect(find.byType(BoutonEntete), findsNothing);
    expect(find.textContaining('Abonnement'), findsNothing);
    expect(find.text('Nouveau'), findsNothing);
    // Le titulaire : « Ma famille », une seule ligne.
    await voir(tester, ligneFamille);
    expect(dansFamille(t.adulte.famille.maFamille), findsOneWidget);
    expect(find.text(t.adulte.famille.ajouter), findsNothing);
    expect(find.text(t.adulte.famille.forfaitFamille), findsNothing);
    // La deconnexion, a part, en bas.
    await voir(tester, find.byType(CarteDeconnexion));
    expect(find.byType(CarteDeconnexion), findsOneWidget);
    // Aucun prix ni pourcentage (F12).
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('€'), findsNothing);
  });

  testWidgets('« Ma famille » ouvre le vrai Foyer', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.monEspace));
    await voir(tester, ligneFamille);
    await tester.tap(dansFamille(t.adulte.famille.maFamille));
    await tester.pumpAndSettle();
    expect(find.byType(FoyerPage), findsOneWidget);
    expect(find.byType(MonEspaceAdultePage), findsNothing);
  });

  testWidgets('adulte seul : « Ajouter ma famille » et sa phrase', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.monEspace,
        etat: EtatDemoAdulte.adulteSeul,
      ),
    );
    await voir(tester, ligneFamille);
    expect(dansFamille(t.adulte.famille.ajouter), findsOneWidget);
    expect(dansFamille(t.adulte.famille.ajouterLegende), findsOneWidget);
    expect(find.text(t.adulte.famille.maFamille), findsNothing);
    expect(find.text(t.adulte.famille.forfaitFamille), findsNothing);
  });

  testWidgets('second adulte : « Forfait famille », son nom, jamais « Ma '
      'famille »', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.monEspace,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    expect(find.text('Mariama Diallo'), findsOneWidget);
    await voir(tester, ligneFamille);
    expect(dansFamille(t.adulte.famille.forfaitFamille), findsOneWidget);
    expect(find.text(t.adulte.famille.maFamille), findsNothing);
    expect(find.text(t.adulte.famille.ajouter), findsNothing);
    // Ni quitter ni reprise sur Mon espace lui-meme (ligne 5 c).
    expect(find.textContaining('Quitter'), findsNothing);
    expect(find.textContaining('reprise'), findsNothing);
    await tester.tap(dansFamille(t.adulte.famille.forfaitFamille));
    await tester.pumpAndSettle();
    expect(find.text(t.adulte.provisoire.forfaitFamille), findsOneWidget);
    expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);
  });

  testWidgets('« Paiements » ouvre la vraie page des paiements, sans rien '
      'inventer, et on revient a Mon espace', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.monEspace));
    await voir(tester, find.text(t.adulte.monEspace.paiements));
    await tester.tap(find.text(t.adulte.monEspace.paiements));
    await tester.pumpAndSettle();
    expect(find.byType(MonEspaceAdultePage), findsNothing);
    expect(find.byType(PaiementsComptePage), findsOneWidget);
    expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);
    expect(
      find.text(t.compte.tuteur.pagePaiements.indisponibleTitre),
      findsOneWidget,
    );
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.byType(MonEspaceAdultePage), findsOneWidget);
  });

  testWidgets('390 a 200 % : tout tient, sans debordement', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.monEspace,
        etat: EtatDemoAdulte.adulteSeul,
      ),
    );
    await voir(tester, find.byType(CarteDeconnexion));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bureau : Mon compte a gauche, famille et aide a droite', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 1000));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.monEspace));
    final Offset compte = tester.getTopLeft(
      find.text(t.adulte.monEspace.monCompte),
    );
    final Offset famille = tester.getTopLeft(ligneFamille);
    expect(famille.dx, greaterThan(compte.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chargement : le squelette de l\'identite, rubriques en place', (
    WidgetTester tester,
  ) async {
    final Completer<MonEspaceAdulteVM> jamais = Completer<MonEspaceAdulteVM>();
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          monEspaceAdulteProvider.overrideWith((Ref _) => jamais.future),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.byType(CarteIdentiteCompte), findsNothing);
    expect(find.text(t.adulte.monEspace.monCompte), findsOneWidget);
    expect(ligneFamille, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('erreur : « Reessayer », aucune ligne famille inventee', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          monEspaceAdulteProvider.overrideWith(
            (Ref _) => Future<MonEspaceAdulteVM>.error(StateError('reseau')),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.commun.reessayer), findsWidgets);
    expect(find.byType(CarteIdentiteCompte), findsNothing);
    expect(ligneFamille, findsNothing);
    expect(find.text(t.adulte.monEspace.monCompte), findsOneWidget);
  });

  testWidgets('sans source serveur : indisponible, sans « Reessayer »', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(child: const MonEspaceAdultePage()));
    await tester.pumpAndSettle();
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.text(t.commun.reessayer), findsNothing);
    expect(ligneFamille, findsNothing);
  });

  testWidgets('sans ligne famille rendue : aucune ligne', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          monEspaceAdulteProvider.overrideWith(
            (Ref _) async => const MonEspaceAdulteVM(
              identite: IdentiteTitulaire(
                prenom: 'Awa',
                nom: 'Ba',
                methodeConnexion: MethodeConnexion.inconnue,
              ),
            ),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Awa Ba'), findsOneWidget);
    expect(ligneFamille, findsNothing);
  });

  test('la ligne famille suit la situation et la vue, jamais deux', () {
    expect(
      DonneesAdulteDemo.monEspace(
        EtatDemoAdulte.adulteSeul,
        GenreTitulaireDemo.homme,
        VueDemoAdulte.titulaire,
      ).ligneFamille,
      LigneFamilleAdulte.ajouterMaFamille,
    );
    expect(
      DonneesAdulteDemo.monEspace(
        EtatDemoAdulte.conjointActif,
        GenreTitulaireDemo.femme,
        VueDemoAdulte.secondAdulte,
      ).ligneFamille,
      LigneFamilleAdulte.forfaitFamille,
    );
    // Le second adulte d'une titulaire est Mamadou.
    expect(
      DonneesAdulteDemo.monEspace(
        EtatDemoAdulte.conjointActif,
        GenreTitulaireDemo.femme,
        VueDemoAdulte.secondAdulte,
      ).identite.prenom,
      'Mamadou',
    );
  });
}

String _libelle(RubriqueMonEspace r) => switch (r) {
  RubriqueMonEspace.informations => t.adulte.monEspace.informations,
  RubriqueMonEspace.coursAcces => t.adulte.monEspace.coursAcces,
  RubriqueMonEspace.paiements => t.adulte.monEspace.paiements,
  RubriqueMonEspace.accords => t.adulte.monEspace.accords,
  RubriqueMonEspace.securite => t.compte.tuteur.securite.titre,
  RubriqueMonEspace.preferences => t.compte.tuteur.preferences,
  RubriqueMonEspace.aide => t.compte.tuteur.aide.ligne,
  RubriqueMonEspace.informationsLegales => t.compte.tuteur.aide.legal,
};
