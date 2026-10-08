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
import 'package:rewayah_academy/core/appairage/service_appairage.dart'
    show EleveDuFoyer;
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/appareils/appareils_page.dart';
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
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/formulaire_profil_eleve.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart';
import 'package:rewayah_academy/features/ma_classe_adulte/ma_classe_adulte_page.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';

import '../../support/harnais.dart' show sansPersonneConnectee;

void main() {
  Widget app({
    required Widget child,
    List<Override> overrides = const [],
    bool horsLigne = false,
  }) => ProviderScope(
    overrides: <Override>[
      horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
      // La source de session, comme l'application la pose toujours (R7-04).
      sansPersonneConnectee(),
      ...overrides,
    ],
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
        // La source de session, comme l'application la pose toujours :
        // les lectures d'argent suivent la personne connectee (R7-04).
        overrides: <Override>[sansPersonneConnectee()],
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
    expect(find.byType(ForfaitFamillePage), findsOneWidget);
    expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);
  });

  testWidgets('second adulte rattache : « Paiements du foyer » ouvre la page '
      'des paiements dans SA coquille, jamais le Foyer (E3)', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.monEspace,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    // Une seule entree vers les paiements : pas de « Paiements » personnels
    // a cote des paiements du foyer (revue d'EA-4c).
    expect(find.text(t.adulte.monEspace.paiements), findsNothing);
    await voir(tester, dansFamille(t.adulte.famille.paiementsFoyer));
    await tester.tap(dansFamille(t.adulte.famille.paiementsFoyer));
    await tester.pumpAndSettle();
    expect(find.byType(PaiementsComptePage), findsOneWidget);
    expect(find.byType(FoyerPage), findsNothing);
    // La page d'arrivee porte le nom de la ligne tapee.
    expect(find.text(t.adulte.famille.paiementsFoyer), findsWidgets);
    expect(find.text(t.compte.tuteur.pagePaiements.titre), findsNothing);
    final NavShell coquille = tester.widget<NavShell>(find.byType(NavShell));
    expect(coquille.destinations.map((d) => d.libelle), <String>[
      t.adulte.nav.accueil,
      t.adulte.nav.maClasse,
      t.adulte.nav.coran,
      t.adulte.nav.monEspace,
    ]);
    expect(coquille.indexActif, 3);
    expect(find.text('Aïcha'), findsNothing);
    expect(find.text('Oumar'), findsNothing);
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.byType(MonEspaceAdultePage), findsOneWidget);
  });

  testWidgets('le titulaire ne voit pas « Paiements du foyer » dans Mon '
      'espace : ils sont dans Ma famille', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.monEspace));
    expect(find.text(t.adulte.famille.paiementsFoyer), findsNothing);
  });

  // F6, F7 (revue du 27/09, majeur 1) : pour CHACUN des 25 etats, et pour
  // les deux variantes (titulaire homme, second adulte Mariama ; titulaire
  // femme, second adulte Mamadou), le second adulte, rattache ou non, ne
  // voit jamais les enfants du titulaire, ni par sa ligne famille ni par une
  // adresse de l'espace foyer.
  for (final (GenreTitulaireDemo genre, EtatDemoAdulte etat)
      in <(GenreTitulaireDemo, EtatDemoAdulte)>[
        for (final GenreTitulaireDemo g in GenreTitulaireDemo.values)
          for (final EtatDemoAdulte e in EtatDemoAdulte.values) (g, e),
      ]) {
    testWidgets('confidentialite, titulaire ${genre.name}, ${etat.name} : le '
        'second adulte ne voit jamais les enfants', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(390, 844));
      final GoRouter routeur = await monterCoquille(
        tester,
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          etat: etat,
          genre: genre,
          vue: VueDemoAdulte.secondAdulte,
        ),
      );
      // Les ecrans de l'espace foyer, et les enfants Diallo par leur
      // identifiant (DEMO-D1, DEMO-D2) partout ; par leur prenom hors de
      // l'Accueil et de Ma classe (la Classe An-Nour de la demonstration a
      // aussi une eleve « Aicha »).
      void aucunEnfant(String ou, {bool classe = false}) {
        for (final Type page in <Type>[
          FoyerPage,
          FicheElevePage,
          AppareilsPage,
          FormulaireProfilEleve,
        ]) {
          expect(find.byType(page), findsNothing, reason: '$ou, $page');
        }
        for (final EleveDuFoyer e in DonneesAdulteDemo.enfants) {
          expect(
            find.textContaining(e.identifiantImmuable),
            findsNothing,
            reason: '$ou, ${e.identifiantImmuable}',
          );
          if (!classe) {
            expect(find.text(e.prenom), findsNothing, reason: ou);
          }
        }
        // Ma classe : aucun participant n'est un enfant du foyer, controle
        // par son identifiant, pas par son prenom.
        final Finder classeAdulte = find.byType(MaClasseAdultePage);
        if (classeAdulte.evaluate().isNotEmpty) {
          final AsyncValue<MaClasseAdulteVM> lue = ProviderScope.containerOf(
            tester.element(classeAdulte),
          ).read(maClasseAdulteProvider);
          final Iterable<String> ids = lue.hasValue && !lue.hasError
              ? lue.requireValue.participants.map(
                  (ParticipantClasseAdulte p) => p.id,
                )
              : const <String>[];
          for (final EleveDuFoyer e in DonneesAdulteDemo.enfants) {
            expect(ids, isNot(contains(e.id)), reason: '$ou, ${e.id}');
          }
        }
      }

      aucunEnfant('Mon espace');
      // Jamais « Ma famille » pour lui.
      expect(find.text(t.adulte.famille.maFamille), findsNothing);
      final LigneFamilleAdulte? ligne = DonneesAdulteDemo.ligneFamille(
        etat,
        VueDemoAdulte.secondAdulte,
      );
      if (ligne == null) {
        expect(ligneFamille, findsNothing);
      } else {
        final String libelle = ligne == LigneFamilleAdulte.forfaitFamille
            ? t.adulte.famille.forfaitFamille
            : t.adulte.famille.ajouter;
        await voir(tester, dansFamille(libelle));
        await tester.tap(dansFamille(libelle));
        await tester.pumpAndSettle();
        aucunEnfant('ligne famille');
      }
      // Chaque ecran, l'espace foyer compris, demande par son adresse.
      for (final EcranDemoAdulte ecran in EcranDemoAdulte.values) {
        routeur.go(
          adresseDemoAdulte(
            ecran,
            etat: etat,
            genre: genre,
            vue: VueDemoAdulte.secondAdulte,
            eleve: DonneesAdulteDemo.aichaId,
          ),
        );
        await tester.pumpAndSettle();
        aucunEnfant(
          ecran.name,
          classe:
              ecran == EcranDemoAdulte.accueil ||
              ecran == EcranDemoAdulte.maClasse,
        );
      }
    });
  }

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

  testWidgets('bureau : Mon compte puis la famille au debut, l\'aide a la '
      'fin, les deux titres a la meme hauteur', (WidgetTester tester) async {
    taille(tester, const Size(1440, 1000));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.monEspace));
    final Offset compte = tester.getTopLeft(
      find.text(t.adulte.monEspace.monCompte),
    );
    final Offset aide = tester.getTopLeft(
      find.text(t.compte.tuteur.aide.titre),
    );
    final Offset famille = tester.getTopLeft(ligneFamille);
    // La colonne de fin commence par son titre, a la hauteur de « Mon
    // compte » : plus de surface qui part plus haut que le titre voisin.
    expect(aide.dx, greaterThan(compte.dx));
    expect(aide.dy, moreOrLessEquals(compte.dy, epsilon: 0.5));
    // La ligne famille suit « Mon compte », dans la meme colonne.
    expect(famille.dx, lessThan(aide.dx));
    expect(famille.dy, greaterThan(compte.dy));
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

  final Finder blocFamille = find.byKey(MonEspaceAdultePage.blocFamilleKey);
  Finder dansBloc(Finder f) => find.descendant(of: blocFamille, matching: f);
  final List<Override> identiteMamadou = <Override>[
    identiteTitulaireProvider.overrideWith(
      (Ref _) async => DonneesAdulteDemo.identite(
        GenreTitulaireDemo.homme,
        VueDemoAdulte.titulaire,
      ),
    ),
  ];

  testWidgets('ligne famille en erreur : un message et « Reessayer », '
      'l\'identite reste, aucune ligne inventee', (WidgetTester tester) async {
    int lectures = 0;
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          ...identiteMamadou,
          monEspaceAdulteProvider.overrideWith((Ref _) {
            lectures++;
            return Future<MonEspaceAdulteVM>.error(StateError('reseau'));
          }),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mamadou Diallo'), findsOneWidget);
    expect(ligneFamille, findsNothing);
    expect(blocFamille, findsOneWidget);
    expect(
      dansBloc(find.text(t.commun.etats.echecServeur.titre)),
      findsOneWidget,
    );
    final Finder reessayer = dansBloc(find.text(t.commun.reessayer));
    expect(reessayer, findsOneWidget);
    await tester.ensureVisible(reessayer);
    await tester.tap(reessayer);
    await tester.pumpAndSettle();
    expect(lectures, 2);
  });

  testWidgets('ligne famille en chargement : son squelette, a sa place', (
    WidgetTester tester,
  ) async {
    final Completer<MonEspaceAdulteVM> jamais = Completer<MonEspaceAdulteVM>();
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          ...identiteMamadou,
          monEspaceAdulteProvider.overrideWith((Ref _) => jamais.future),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Mamadou Diallo'), findsOneWidget);
    expect(blocFamille, findsOneWidget);
    expect(dansBloc(find.byType(Skeleton)), findsOneWidget);
    expect(ligneFamille, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  // Revue EA-R, M2 (F7) : la rubrique « Paiements » personnelle n'existe
  // qu'une fois la ligne famille lue, et hors forfait famille ; jamais par
  // defaut puis masquee.
  testWidgets('M2 : ligne famille en chargement puis en erreur, aucune '
      'rubrique « Paiements » personnelle', (WidgetTester tester) async {
    final Completer<MonEspaceAdulteVM> attente = Completer<MonEspaceAdulteVM>();
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          ...identiteMamadou,
          monEspaceAdulteProvider.overrideWith((Ref _) => attente.future),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text(t.adulte.monEspace.monCompte), findsOneWidget);
    expect(find.text(t.adulte.monEspace.paiements), findsNothing);
    expect(find.text(t.adulte.famille.paiementsFoyer), findsNothing);
    attente.completeError(StateError('reseau'));
    await tester.pumpAndSettle();
    expect(dansBloc(find.text(t.commun.reessayer)), findsOneWidget);
    expect(find.text(t.adulte.monEspace.paiements), findsNothing);
    expect(find.text(t.adulte.famille.paiementsFoyer), findsNothing);
  });

  testWidgets('M2 : ligne famille sans source ou hors ligne, aucune rubrique '
      '« Paiements » personnelle', (WidgetTester tester) async {
    for (final (bool horsLigne, Object erreur) in <(bool, Object)>[
      (false, const CapaciteIndisponible('mon_espace_eleve_adulte')),
      (true, StateError('reseau')),
    ]) {
      await tester.pumpWidget(
        app(
          horsLigne: horsLigne,
          overrides: <Override>[
            ...identiteMamadou,
            monEspaceAdulteProvider.overrideWith(
              (Ref _) => Future<MonEspaceAdulteVM>.error(erreur),
            ),
          ],
          child: const MonEspaceAdultePage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(t.adulte.monEspace.paiements),
        findsNothing,
        reason: '$erreur',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('M2 : second adulte rattache, donnee lue : « Paiements du '
      'foyer » present (E3 = b, K-53.8), pas de « Paiements » personnels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          ...identiteMamadou,
          monEspaceAdulteProvider.overrideWith(
            (Ref _) async => const MonEspaceAdulteVM(
              ligneFamille: LigneFamilleAdulte.forfaitFamille,
            ),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    await voir(tester, dansFamille(t.adulte.famille.paiementsFoyer));
    expect(dansFamille(t.adulte.famille.paiementsFoyer), findsOneWidget);
    expect(find.text(t.adulte.monEspace.paiements), findsNothing);
  });

  for (final LigneFamilleAdulte? ligne in <LigneFamilleAdulte?>[
    null,
    LigneFamilleAdulte.ajouterMaFamille,
    LigneFamilleAdulte.maFamille,
  ]) {
    testWidgets('M2 : adulte seul ou titulaire (${ligne?.name}), donnee lue : '
        '« Paiements » personnels, jamais « Paiements du foyer »', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          overrides: <Override>[
            ...identiteMamadou,
            monEspaceAdulteProvider.overrideWith(
              (Ref _) async => MonEspaceAdulteVM(ligneFamille: ligne),
            ),
          ],
          child: const MonEspaceAdultePage(),
        ),
      );
      await tester.pumpAndSettle();
      await voir(tester, find.text(t.adulte.monEspace.paiements));
      expect(find.text(t.adulte.monEspace.paiements), findsOneWidget);
      expect(find.text(t.adulte.famille.paiementsFoyer), findsNothing);
    });
  }

  testWidgets('ligne famille sans source : indisponible, dit comme tel, '
      'sans « Reessayer »', (WidgetTester tester) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          ...identiteMamadou,
          monEspaceAdulteProvider.overrideWith(
            (Ref _) => Future<MonEspaceAdulteVM>.error(
              const CapaciteIndisponible('mon_espace_eleve_adulte'),
            ),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      dansBloc(find.text(t.adulte.famille.indisponibleTitre)),
      findsOneWidget,
    );
    expect(dansBloc(find.text(t.commun.reessayer)), findsNothing);
    expect(ligneFamille, findsNothing);
  });

  testWidgets('hors ligne : un seul etat, un seul « Reessayer » qui relit '
      'les deux lectures (K-42)', (WidgetTester tester) async {
    int identites = 0;
    int familles = 0;
    await tester.pumpWidget(
      app(
        horsLigne: true,
        overrides: <Override>[
          identiteTitulaireProvider.overrideWith((Ref _) {
            identites++;
            return Future<IdentiteTitulaire>.error(StateError('reseau'));
          }),
          monEspaceAdulteProvider.overrideWith((Ref _) {
            familles++;
            return Future<MonEspaceAdulteVM>.error(StateError('reseau'));
          }),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(MonEspaceAdultePage.horsLigneKey), findsOneWidget);
    expect(find.text(t.commun.etats.horsLigne.titre), findsOneWidget);
    expect(find.text(t.commun.etats.echecServeur.titre), findsNothing);
    final Finder reessayer = find.text(t.commun.reessayer);
    expect(reessayer, findsOneWidget);
    // La ligne famille, en echec elle aussi, garde sa forme sans bouton.
    expect(dansBloc(find.byType(Skeleton)), findsOneWidget);
    // Les rubriques restent en place.
    expect(find.text(t.adulte.monEspace.monCompte), findsOneWidget);
    await tester.tap(reessayer);
    await tester.pumpAndSettle();
    expect(identites, 2);
    expect(familles, 2);
  });

  testWidgets('hors ligne, seule la ligne famille en echec : l\'etat unique '
      'est a sa place', (WidgetTester tester) async {
    await tester.pumpWidget(
      app(
        horsLigne: true,
        overrides: <Override>[
          ...identiteMamadou,
          monEspaceAdulteProvider.overrideWith(
            (Ref _) => Future<MonEspaceAdulteVM>.error(StateError('reseau')),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mamadou Diallo'), findsOneWidget);
    expect(
      dansBloc(find.byKey(MonEspaceAdultePage.horsLigneKey)),
      findsOneWidget,
    );
    expect(find.text(t.commun.reessayer), findsOneWidget);
  });

  testWidgets('hors ligne, ligne deja lue : elle reste', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        horsLigne: true,
        overrides: <Override>[
          ...identiteMamadou,
          monEspaceAdulteProvider.overrideWith(
            (Ref _) async => const MonEspaceAdulteVM(
              ligneFamille: LigneFamilleAdulte.maFamille,
            ),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(dansFamille(t.adulte.famille.maFamille), findsOneWidget);
    expect(find.text(t.commun.etats.horsLigne.titre), findsNothing);
  });

  testWidgets('legendes honnetes : les rubriques sans source disent « Non '
      'disponible », sans promettre d\'action', (WidgetTester tester) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          ...identiteMamadou,
          monEspaceAdulteProvider.overrideWith(
            (Ref _) async => const MonEspaceAdulteVM(),
          ),
        ],
        child: const MonEspaceAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    // Cours et acces, Paiements, Mes accords et Aide et contact : leur page
    // d'arrivee dit indisponible (EA-BR-08, 09, DB-CPT-03, 07).
    expect(find.text(t.compte.nonDisponible), findsNWidgets(4));
    expect(find.textContaining('Accepter'), findsNothing);
    // Une seule personne dans les legendes : ni « mes » ni « mon ».
    for (final String legende in <String>[
      t.adulte.monEspace.coursAccesLegende,
      t.adulte.monEspace.paiementsLegende,
      t.adulte.monEspace.accordsLegende,
      t.adulte.monEspace.securiteLegende,
    ]) {
      expect(
        RegExp(r'\b(mes|mon|ma)\b', caseSensitive: false).hasMatch(legende),
        isFalse,
        reason: legende,
      );
    }
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
    // La ligne famille, sans source non plus, le dit aussi (EA-BR-07).
    expect(find.text(t.adulte.famille.indisponibleTitre), findsOneWidget);
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
    // F6, F7 : « Ma famille » (le Foyer et les enfants) n'est rendue qu'au
    // titulaire ; le second adulte detache redevient un adulte autonome.
    for (final EtatDemoAdulte etat in EtatDemoAdulte.values) {
      final LigneFamilleAdulte? ligne = DonneesAdulteDemo.ligneFamille(
        etat,
        VueDemoAdulte.secondAdulte,
      );
      expect(ligne, isNot(LigneFamilleAdulte.maFamille), reason: etat.name);
      expect(
        ligne == LigneFamilleAdulte.forfaitFamille,
        DonneesAdulteDemo.secondAdultePresent(etat),
        reason: etat.name,
      );
    }
    for (final EtatDemoAdulte etat in <EtatDemoAdulte>[
      EtatDemoAdulte.conjointQuitte,
      EtatDemoAdulte.conjointRetire,
      EtatDemoAdulte.delai60,
      EtatDemoAdulte.delai120,
      EtatDemoAdulte.invitationEnAttente,
      EtatDemoAdulte.titulaireSansConjoint,
    ]) {
      expect(
        DonneesAdulteDemo.ligneFamille(etat, VueDemoAdulte.secondAdulte),
        LigneFamilleAdulte.ajouterMaFamille,
        reason: etat.name,
      );
    }
    // Revue d'EA-4c : aucune ligne pour le second adulte qui a deja accepte
    // (validation en attente ou refusee, section 10.4), qui devient titulaire
    // (reprise validee, section 12.6), ou qui est deja ailleurs (section 11) :
    // jamais « Ajouter ma famille », qui pousserait a une double appartenance.
    for (final EtatDemoAdulte etat in <EtatDemoAdulte>[
      EtatDemoAdulte.validationEnAttente,
      EtatDemoAdulte.validationRefusee,
      EtatDemoAdulte.repriseValidee,
      EtatDemoAdulte.dejaDansUnAutreFoyer,
    ]) {
      expect(
        DonneesAdulteDemo.ligneFamille(etat, VueDemoAdulte.secondAdulte),
        isNull,
        reason: etat.name,
      );
    }
    // Le titulaire qui a invite un adulte deja ailleurs garde « Ma famille »
    // et ses enfants ; sa place dit l'invitation envoyee, neutre (F4).
    expect(
      DonneesAdulteDemo.ligneFamille(
        EtatDemoAdulte.dejaDansUnAutreFoyer,
        VueDemoAdulte.titulaire,
      ),
      LigneFamilleAdulte.maFamille,
    );
    expect(
      DonneesAdulteDemo.place(
        EtatDemoAdulte.dejaDansUnAutreFoyer,
        GenreTitulaireDemo.homme,
      ),
      isA<InvitationEnvoyee>(),
    );
    expect(
      ecranPermisDemoAdulte(
        EcranDemoAdulte.maFamille,
        EtatDemoAdulte.dejaDansUnAutreFoyer,
        VueDemoAdulte.titulaire,
      ),
      EcranDemoAdulte.maFamille,
    );
    // Seul l'adulte seul, vu comme titulaire, se voit proposer une famille.
    for (final EtatDemoAdulte etat in EtatDemoAdulte.values) {
      expect(
        DonneesAdulteDemo.ligneFamille(etat, VueDemoAdulte.titulaire) ==
            LigneFamilleAdulte.ajouterMaFamille,
        etat == EtatDemoAdulte.adulteSeul,
        reason: etat.name,
      );
    }
    // Aucun ecran de l'espace foyer pour le second adulte, sauf les
    // paiements du foyer (E3), rendus dans sa propre coquille.
    for (final EtatDemoAdulte etat in EtatDemoAdulte.values) {
      for (final EcranDemoAdulte ecran in EcranDemoAdulte.values) {
        final EcranDemoAdulte vu = ecranPermisDemoAdulte(
          ecran,
          etat,
          VueDemoAdulte.secondAdulte,
        );
        expect(
          <EcranDemoAdulte>{
            EcranDemoAdulte.maFamille,
            EcranDemoAdulte.placeAdulte,
            EcranDemoAdulte.ajouterProfil,
            EcranDemoAdulte.ficheEleve,
            EcranDemoAdulte.appareils,
            EcranDemoAdulte.inviterConjoint,
            EcranDemoAdulte.invitationEnvoyee,
            EcranDemoAdulte.aProposForfait,
            EcranDemoAdulte.creerMonProfil,
            EcranDemoAdulte.profilNonCree,
          }.contains(vu),
          isFalse,
          reason: '${etat.name} ${ecran.name}',
        );
        if (vu == EcranDemoAdulte.paiementsFoyer) {
          expect(DonneesAdulteDemo.secondAdultePresent(etat), isTrue);
        }
      }
    }
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
  RubriqueMonEspace.paiementsFoyer => t.adulte.famille.paiementsFoyer,
};
