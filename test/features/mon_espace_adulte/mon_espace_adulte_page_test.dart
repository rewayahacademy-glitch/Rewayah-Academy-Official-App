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
import 'package:rewayah_academy/features/compte/aide_page.dart';
import 'package:rewayah_academy/features/compte/apparence_page.dart';
import 'package:rewayah_academy/features/compte/carte_rubriques.dart';
import 'package:rewayah_academy/features/compte/compte_tuteur_page.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart';
import 'package:rewayah_academy/features/compte/informations_legales_page.dart';
import 'package:rewayah_academy/features/compte/informations_page.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/compte/preferences_page.dart';
import 'package:rewayah_academy/features/compte/securite_page.dart';
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
    // Aucune pastille pour l'etat normal (E12) : ni « Compte valide » ni
    // « Actif ».
    expect(find.text(t.compte.tuteur.identite.statutValide), findsNothing);
    expect(find.text('Actif'), findsNothing);
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

  testWidgets('chaque rubrique ouvre sa page depuis la coquille, retour a '
      'Mon espace : Mes accords indisponible, Preferences puis Apparence', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.monEspace));

    Future<void> ouvrir(String libelle) async {
      await voir(tester, find.text(libelle));
      await tester.tap(find.text(libelle));
      await tester.pumpAndSettle();
      expect(find.byType(MonEspaceAdultePage), findsNothing, reason: libelle);
      expect(
        tester.widget<NavShell>(find.byType(NavShell)).indexActif,
        3,
        reason: libelle,
      );
    }

    Future<void> revenir() async {
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
    }

    // « Mes accords » : aucune source, une page qui le dit (EA-BR-08).
    await ouvrir(t.adulte.monEspace.accords);
    expect(find.byType(RubriqueIndisponibleAdultePage), findsOneWidget);
    expect(
      find.text(t.adulte.monEspace.pageAccords.indisponibleTitre),
      findsOneWidget,
    );
    await revenir();
    expect(find.byType(MonEspaceAdultePage), findsOneWidget);

    // « Preferences » : la vraie page du Compte, puis son Apparence.
    await ouvrir(t.compte.tuteur.preferences);
    expect(find.byType(PreferencesComptePage), findsOneWidget);
    await tester.tap(find.text(t.compte.tuteur.pagePreferences.apparence));
    await tester.pumpAndSettle();
    expect(find.byType(ApparenceComptePage), findsOneWidget);
    await revenir();
    expect(find.byType(PreferencesComptePage), findsOneWidget);
    await revenir();
    expect(find.byType(MonEspaceAdultePage), findsOneWidget);

    // Les autres rubriques : chacune sa page, chacune revient.
    for (final (String libelle, Type page) in <(String, Type)>[
      (t.adulte.monEspace.informations, InformationsComptePage),
      (t.adulte.monEspace.coursAcces, RubriqueIndisponibleAdultePage),
      (t.compte.tuteur.securite.titre, SecuriteComptePage),
      (t.compte.tuteur.aide.ligne, AideComptePage),
      (t.compte.tuteur.aide.legal, InformationsLegalesComptePage),
    ]) {
      await ouvrir(libelle);
      expect(find.byType(page), findsOneWidget, reason: libelle);
      await revenir();
      expect(find.byType(MonEspaceAdultePage), findsOneWidget, reason: libelle);
    }
    // Mes informations lit la meme identite que la carte, rien d'invente.
    await ouvrir(t.adulte.monEspace.informations);
    expect(find.text('Mamadou'), findsOneWidget);
    expect(find.text('Diallo'), findsOneWidget);
  });

  testWidgets('chargement : le squelette de l\'identite, rubriques en place', (
    WidgetTester tester,
  ) async {
    final Completer<IdentiteTitulaire> jamais = Completer<IdentiteTitulaire>();
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          identiteTitulaireProvider.overrideWith((Ref _) => jamais.future),
          monEspaceAdulteProvider.overrideWith(
            (Ref _) async => const MonEspaceAdulteVM(
              ligneFamille: LigneFamilleAdulte.ajouterMaFamille,
            ),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.byType(CarteIdentiteCompte), findsNothing);
    expect(find.text(t.adulte.monEspace.monCompte), findsOneWidget);
    // La ligne famille ne depend pas de l'identite.
    expect(ligneFamille, findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('identite en erreur : « Reessayer », la ligne famille reste', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          identiteTitulaireProvider.overrideWith(
            (Ref _) => Future<IdentiteTitulaire>.error(StateError('reseau')),
          ),
          monEspaceAdulteProvider.overrideWith(
            (Ref _) async => const MonEspaceAdulteVM(
              ligneFamille: LigneFamilleAdulte.ajouterMaFamille,
            ),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.commun.reessayer), findsWidgets);
    expect(find.byType(CarteIdentiteCompte), findsNothing);
    expect(dansFamille(t.adulte.famille.ajouter), findsOneWidget);
    expect(find.text(t.adulte.monEspace.monCompte), findsOneWidget);
  });

  testWidgets('ligne famille en erreur : l\'identite reste, aucune ligne '
      'famille inventee', (WidgetTester tester) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          identiteTitulaireProvider.overrideWith(
            (Ref _) async => DonneesAdulteDemo.identite(
              GenreTitulaireDemo.homme,
              VueDemoAdulte.titulaire,
            ),
          ),
          monEspaceAdulteProvider.overrideWith(
            (Ref _) => Future<MonEspaceAdulteVM>.error(StateError('reseau')),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mamadou Diallo'), findsOneWidget);
    expect(ligneFamille, findsNothing);
  });

  testWidgets('sans source serveur : le port d\'identite dit indisponible, '
      'sans « Reessayer »', (WidgetTester tester) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          // Le port de production, sans la session : `IdentiteTitulaireIndisponible`.
          identiteTitulaireProvider.overrideWith(
            (Ref ref) => ref.watch(portIdentiteTitulaireProvider).lire(),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
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
          identiteTitulaireProvider.overrideWith(
            (Ref _) async => const IdentiteTitulaire(
              prenom: 'Awa',
              nom: 'Ba',
              methodeConnexion: MethodeConnexion.inconnue,
            ),
          ),
          monEspaceAdulteProvider.overrideWith(
            (Ref _) async => const MonEspaceAdulteVM(),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Awa Ba'), findsOneWidget);
    expect(ligneFamille, findsNothing);
  });

  testWidgets('pastille : seulement pour une exception (E12)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          identiteTitulaireProvider.overrideWith(
            (Ref _) async => const IdentiteTitulaire(
              prenom: 'Awa',
              nom: 'Ba',
              methodeConnexion: MethodeConnexion.lienCourriel,
              statut: AccountStatus.provisionalActive,
            ),
          ),
          monEspaceAdulteProvider.overrideWith(
            (Ref _) async => const MonEspaceAdulteVM(),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(t.compte.tuteur.identite.statutProvisoire),
      findsOneWidget,
    );
    expect(find.text(t.compte.tuteur.identite.statutValide), findsNothing);
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
      DonneesAdulteDemo.identite(
        GenreTitulaireDemo.femme,
        VueDemoAdulte.secondAdulte,
      ).prenom,
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
