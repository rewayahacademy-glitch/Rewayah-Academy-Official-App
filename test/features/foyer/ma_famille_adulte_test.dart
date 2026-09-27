// EA-5 : Ma famille du titulaire adulte, atteinte depuis la VRAIE coquille
// adulte (K-07) : on tape la VRAIE destination « Mon espace », puis la VRAIE
// ligne « Ma famille ». Puis la place adulte dans ses etats (F21), la
// variante titulaire femme (F3), les etats de la page (vide, chargement,
// erreur, hors ligne), les destinations de la coquille du tuteur, et
// l'Accueil de la conjointe sans la Classe du titulaire (EA-BR-13).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/appareils/appareils_page.dart';
import 'package:rewayah_academy/features/compte/compte_tuteur_page.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/formulaire_profil_eleve.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';

void main() {
  void taille(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

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

  Finder place() => find.descendant(
    of: find.byKey(lignePlaceAdulteKey),
    matching: find.byType(Text),
  );

  bool placeDit(WidgetTester tester, String texte) =>
      tester.widgetList<Text>(place()).any((Text w) => w.data == texte);

  testWidgets('Mon espace > Ma famille, tapes : carte du titulaire, place, '
      'enfants, un seul bouton, Paiements du foyer', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.accueil));

    await tester.tap(find.text(t.adulte.nav.monEspace).first);
    await tester.pumpAndSettle();
    final Finder ligne = find.descendant(
      of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
      matching: find.text(t.adulte.famille.maFamille),
    );
    await tester.ensureVisible(ligne);
    await tester.tap(ligne);
    await tester.pumpAndSettle();

    expect(find.byType(FoyerPage), findsOneWidget);
    // En-tete sobre : « Ma famille », pas « Foyer ».
    expect(find.text(t.adulte.famille.maFamille), findsOneWidget);
    expect(find.text(t.foyer.sousTitre), findsNothing);
    // La carte du titulaire : la carte du Compte, son role, sa photo.
    final Finder carte = find.byKey(FoyerPage.titulaireKey);
    expect(
      find.descendant(of: carte, matching: find.byType(CarteIdentiteCompte)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: carte, matching: find.text('Mamadou Diallo')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: carte,
        matching: find.text(t.adulte.famille.titulaire),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: carte, matching: find.byType(PhotoEleve)),
      findsOneWidget,
    );
    // La place : « Ma conjointe · Mariama », ses initiales, rien d'autre.
    expect(
      placeDit(tester, t.adulte.famille.place.maConjointe(prenom: 'Mariama')),
      isTrue,
    );
    expect(
      find.descendant(
        of: find.byKey(lignePlaceAdulteKey),
        matching: find.byType(PhotoEleve),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(lignePlaceAdulteKey),
        matching: find.textContaining(DonneesAdulteDemo.classeTitulaire),
      ),
      findsNothing,
    );
    // Les enfants, avec leur photo (K-44), sans compteur ni age.
    final Finder membres = find.byKey(FoyerPage.membresKey);
    for (final String prenom in <String>['Aïcha', 'Oumar']) {
      expect(
        find.descendant(of: membres, matching: find.text(prenom)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: membres, matching: find.byType(PhotoEleve)),
      findsNWidgets(2),
    );
    // Un seul bouton dominant : « Ajouter un profil eleve ».
    expect(find.byType(ActionPrincipale), findsOneWidget);
    expect(find.text(t.foyer.ajouterProfil), findsOneWidget);
    // Le titulaire adulte est deja eleve : pas de « Creer mon profil ».
    expect(find.byKey(FoyerPage.monProfilKey), findsNothing);

    // « Paiements du foyer » ouvre la page des paiements, retour a Ma famille.
    final Finder paiements = find.descendant(
      of: find.byKey(paiementsFoyerKey),
      matching: find.text(t.adulte.famille.paiementsFoyer),
    );
    await tester.ensureVisible(paiements);
    await tester.tap(paiements);
    await tester.pumpAndSettle();
    expect(find.byType(PaiementsComptePage), findsOneWidget);
    expect(find.byType(FoyerPage), findsNothing);
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.byType(FoyerPage), findsOneWidget);
  });

  testWidgets('la place adulte dit son etat sur sa ligne (F21)', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    final GoRouter routeur = await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.maFamille,
        etat: EtatDemoAdulte.titulaireSansConjoint,
      ),
    );
    final String date = dateEcheance(DonneesAdulteDemo.finDelai);
    for (final (EtatDemoAdulte etat, String attendu, String? legende)
        in <(EtatDemoAdulte, String, String?)>[
          (
            EtatDemoAdulte.titulaireSansConjoint,
            t.adulte.famille.place.ajouterConjointe,
            t.adulte.famille.place.inviterConjointe,
          ),
          (
            EtatDemoAdulte.invitationExpiree,
            t.adulte.famille.place.ajouterConjointe,
            null,
          ),
          (
            EtatDemoAdulte.invitationEnAttente,
            t.adulte.famille.place.invitationEnvoyee,
            null,
          ),
          (
            EtatDemoAdulte.validationEnAttente,
            t.adulte.famille.place.validationEnAttente,
            null,
          ),
          (
            EtatDemoAdulte.validationRefusee,
            t.adulte.famille.place.validationRefusee,
            null,
          ),
          (
            EtatDemoAdulte.delai60,
            t.adulte.famille.place.nouvelleInvitation(date: date),
            null,
          ),
          (
            EtatDemoAdulte.conjointRetire,
            t.adulte.famille.place.nouvelleInvitation(date: date),
            null,
          ),
        ]) {
      routeur.go(adresseDemoAdulte(EcranDemoAdulte.maFamille, etat: etat));
      await tester.pumpAndSettle();
      expect(placeDit(tester, attendu), isTrue, reason: etat.name);
      if (legende != null) {
        expect(placeDit(tester, legende), isTrue, reason: etat.name);
      }
      // Jamais « Ajouter » pendant un delai ou une validation (F17, R4).
      if (etat == EtatDemoAdulte.delai60 ||
          etat == EtatDemoAdulte.validationEnAttente) {
        expect(
          placeDit(tester, t.adulte.famille.place.ajouterConjointe),
          isFalse,
        );
      }
    }
  });

  testWidgets('titulaire femme : « Ajouter un conjoint », « Mon conjoint » '
      '(F3)', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    final GoRouter routeur = await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.maFamille,
        genre: GenreTitulaireDemo.femme,
      ),
    );
    expect(
      placeDit(tester, t.adulte.famille.place.monConjoint(prenom: 'Mamadou')),
      isTrue,
    );
    expect(find.text('Mariama Diallo'), findsOneWidget);
    routeur.go(
      adresseDemoAdulte(
        EcranDemoAdulte.maFamille,
        etat: EtatDemoAdulte.titulaireSansConjoint,
        genre: GenreTitulaireDemo.femme,
      ),
    );
    await tester.pumpAndSettle();
    expect(placeDit(tester, t.adulte.famille.place.ajouterConjoint), isTrue);
    expect(placeDit(tester, t.adulte.famille.place.inviterConjoint), isTrue);
  });

  testWidgets('adulte seul et second adulte : jamais le Foyer du titulaire '
      '(F6, F7), meme par l\'adresse', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    final GoRouter routeur = await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.maFamille,
        etat: EtatDemoAdulte.adulteSeul,
      ),
    );
    // Adulte seul : « Ajouter ma famille », comme sa ligne de Mon espace.
    expect(find.byType(FoyerPage), findsNothing);
    expect(find.text(t.adulte.provisoire.ajouterMaFamille), findsOneWidget);
    expect(find.text(t.adulte.famille.titulaire), findsNothing);
    // Second adulte : « Forfait famille », sans enfants ni place.
    for (final EcranDemoAdulte ecran in <EcranDemoAdulte>[
      EcranDemoAdulte.maFamille,
      EcranDemoAdulte.ficheEleve,
      EcranDemoAdulte.appareils,
    ]) {
      routeur.go(adresseDemoAdulte(ecran, vue: VueDemoAdulte.secondAdulte));
      await tester.pumpAndSettle();
      expect(find.byType(FoyerPage), findsNothing, reason: ecran.name);
      expect(
        find.text(t.adulte.provisoire.forfaitFamille),
        findsOneWidget,
        reason: ecran.name,
      );
      expect(find.text('Aïcha'), findsNothing, reason: ecran.name);
      expect(find.textContaining('Mariama'), findsNothing, reason: ecran.name);
    }
  });

  testWidgets('Ma famille : ajouter un profil (sans « Un proche adulte »), '
      'fiche d\'un enfant, appareils, place adulte : les vraies pages', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.monEspace));
    Future<void> versMaFamille() async {
      final Finder ligne = find.descendant(
        of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
        matching: find.text(t.adulte.famille.maFamille),
      );
      await tester.ensureVisible(ligne);
      await tester.tap(ligne);
      await tester.pumpAndSettle();
      expect(find.byType(FoyerPage), findsOneWidget);
    }

    // « Ajouter un profil eleve » : le formulaire commun, sans proche adulte.
    await versMaFamille();
    await tester.tap(find.byKey(FoyerPage.ajouterKey));
    await tester.pumpAndSettle();
    expect(find.byType(FormulaireProfilEleve), findsOneWidget);
    expect(find.text(t.foyer.ajout.pourQui.enfantTitre), findsOneWidget);
    expect(find.text(t.foyer.ajout.pourQui.procheTitre), findsNothing);
    expect(find.byKey(FormulaireProfilEleve.porteIllisibleKey), findsNothing);
    // Quitter le formulaire ramene a Ma famille.
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.byType(FoyerPage), findsOneWidget);

    // Une ligne enfant : sa fiche, retour a Ma famille.
    final Finder aicha = find.descendant(
      of: find.byKey(FoyerPage.membresKey),
      matching: find.text('Aïcha'),
    );
    await tester.ensureVisible(aicha);
    await tester.tap(aicha);
    await tester.pumpAndSettle();
    expect(find.byType(FicheElevePage), findsOneWidget);
    expect(
      tester.widget<FicheElevePage>(find.byType(FicheElevePage)).eleveId,
      DonneesAdulteDemo.aichaId,
    );
    expect(find.byKey(FicheElevePage.enteteKey), findsOneWidget);
    // Aucune date sentinelle d'acces.
    expect(find.textContaining('2099'), findsNothing);
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.byType(FoyerPage), findsOneWidget);

    // « Appareils du foyer » : la page des appareils, avec les enfants.
    final Finder appareils = find.descendant(
      of: find.byKey(FoyerPage.appareilsKey),
      matching: find.text(t.foyer.appareilsFoyer),
    );
    await tester.ensureVisible(appareils);
    await tester.tap(appareils);
    await tester.pumpAndSettle();
    expect(find.byType(AppareilsPage), findsOneWidget);
    expect(find.text('Oumar'), findsOneWidget);
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.byType(FoyerPage), findsOneWidget);

    // La place adulte : une page provisoire honnete, retour a Ma famille.
    final Finder placeLigne = find.descendant(
      of: find.byKey(lignePlaceAdulteKey),
      matching: find.text(
        t.adulte.famille.place.maConjointe(prenom: 'Mariama'),
      ),
    );
    await tester.ensureVisible(placeLigne);
    await tester.tap(placeLigne);
    await tester.pumpAndSettle();
    expect(find.text(t.adulte.provisoire.placeAdulte), findsOneWidget);
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.byType(FoyerPage), findsOneWidget);
  });

  testWidgets('les destinations de la coquille du tuteur reagissent toutes', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.maFamille));
    Future<void> taper(String libelle) async {
      await tester.tap(
        find.descendant(
          of: find.byKey(NavShell.barreBasseKey),
          matching: find.text(libelle),
        ),
      );
      await tester.pumpAndSettle();
    }

    await taper(t.nav.tuteur.compte);
    expect(find.byType(MonEspaceAdultePage), findsOneWidget);
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.maFamille));
    await taper(t.nav.tuteur.accueil);
    expect(find.byType(AccueilAdultePage), findsOneWidget);
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.maFamille));
    await taper(t.nav.tuteur.historique);
    expect(find.byType(AccueilAdultePage), findsOneWidget);
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.maFamille));
    await taper(t.nav.tuteur.foyer);
    expect(find.byType(FoyerPage), findsOneWidget);
  });

  testWidgets('Accueil de la conjointe : jamais la Classe An-Nour du '
      'titulaire (EA-BR-13)', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.accueil,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    expect(find.byType(AccueilAdultePage), findsOneWidget);
    expect(find.textContaining(DonneesClasseDemo.classe), findsNothing);
    expect(find.text(DonneesAdulteDemo.ligneParcours), findsNothing);
    expect(
      find.byWidgetPredicate(
        (Widget w) => w is EtatSysteme && w.nature == NatureEtat.indisponible,
      ),
      findsOneWidget,
    );
  });

  group('etats de la page', () {
    const FoyerTitulaireVM vue = FoyerTitulaireVM(
      placeFeminine: true,
      place: PlaceDisponible(),
    );

    Future<void> monterPage(
      WidgetTester tester, {
      required Future<List<EleveDuFoyer>> Function() eleves,
      bool horsLigne = false,
    }) async {
      taille(tester, const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            foyerTitulaireProvider.overrideWith((Ref _) async => vue),
            identiteTitulaireProvider.overrideWith(
              (Ref _) async => DonneesAdulteDemo.identite(
                GenreTitulaireDemo.homme,
                VueDemoAdulte.titulaire,
              ),
            ),
            elevesDuFoyerProvider.overrideWith((Ref _) => eleves()),
            horsLigneProvider.overrideWith(
              (Ref _) => Stream<bool>.value(horsLigne),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: const FoyerPage(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('chargement : squelette des profils, carte et place en place', (
      WidgetTester tester,
    ) async {
      final Completer<List<EleveDuFoyer>> jamais =
          Completer<List<EleveDuFoyer>>();
      await monterPage(tester, eleves: () => jamais.future);
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byKey(FoyerPage.titulaireKey), findsOneWidget);
      expect(placeDit(tester, t.adulte.famille.place.ajouterConjointe), isTrue);
    });

    testWidgets('erreur : dite, avec Reessayer ; la place reste lisible', (
      WidgetTester tester,
    ) async {
      await monterPage(
        tester,
        eleves: () => Future<List<EleveDuFoyer>>.error(Exception('panne')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.echecServeur,
        ),
        findsOneWidget,
      );
      expect(placeDit(tester, t.adulte.famille.place.ajouterConjointe), isTrue);
    });

    testWidgets('hors ligne : dit comme tel', (WidgetTester tester) async {
      await monterPage(
        tester,
        eleves: () => Future<List<EleveDuFoyer>>.error(Exception('reseau')),
        horsLigne: true,
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.horsLigne,
        ),
        findsOneWidget,
      );
    });

    testWidgets('titulaire en chargement ou en erreur : jamais le Foyer du '
        'tuteur en silence', (WidgetTester tester) async {
      taille(tester, const Size(390, 844));
      final Completer<FoyerTitulaireVM> jamais = Completer<FoyerTitulaireVM>();
      bool panne = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            foyerTitulaireProvider.overrideWith(
              (Ref _) => panne
                  ? Future<FoyerTitulaireVM>.error(Exception('panne'))
                  : jamais.future,
            ),
            elevesDuFoyerProvider.overrideWith(
              (Ref _) async => const <EleveDuFoyer>[],
            ),
            horsLigneProvider.overrideWith(
              (Ref _) => Stream<bool>.value(false),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              home: const FoyerPage(),
            ),
          ),
        ),
      );
      await tester.pump();
      // Chargement : un squelette, ni « Foyer » ni « Creer mon profil ».
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text(t.foyer.titre), findsNothing);
      expect(find.byKey(FoyerPage.monProfilKey), findsNothing);
      // Erreur : dite, avec « Reessayer ».
      panne = true;
      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(FoyerPage)),
      );
      conteneur.invalidate(foyerTitulaireProvider);
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.echecServeur,
        ),
        findsOneWidget,
      );
      expect(find.text(t.foyer.titre), findsNothing);
      expect(find.byKey(FoyerPage.monProfilKey), findsNothing);
    });

    testWidgets(
      'sans valeur rendue (EA-BR-14) : le Foyer du tuteur, inchange',
      (WidgetTester tester) async {
        taille(tester, const Size(390, 844));
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              elevesDuFoyerProvider.overrideWith(
                (Ref _) async => const <EleveDuFoyer>[],
              ),
              horsLigneProvider.overrideWith(
                (Ref _) => Stream<bool>.value(false),
              ),
            ],
            child: TranslationProvider(
              child: MaterialApp(
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                home: const FoyerPage(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(t.foyer.titre), findsWidgets);
        expect(find.byKey(FoyerPage.titulaireKey), findsNothing);
        expect(find.byKey(lignePlaceAdulteKey), findsNothing);
        expect(find.byKey(paiementsFoyerKey), findsNothing);
        expect(find.byKey(FoyerPage.monProfilKey), findsOneWidget);
      },
    );
  });

  test('libelles de la place : jamais un calcul de date (F17)', () {
    final FoyerTitulaireVM delai = FoyerTitulaireVM(
      placeFeminine: false,
      place: DelaiEnCours(DateTime.utc(2026, 12, 18)),
    );
    expect(libellePlace(delai), contains('18 décembre 2026'));
    expect(placeActionnable(delai.place), isFalse);
    expect(placeActionnable(const PlaceDisponible()), isTrue);
  });
}
