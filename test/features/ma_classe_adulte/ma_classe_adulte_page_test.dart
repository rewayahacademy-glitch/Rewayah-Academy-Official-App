// EA-3 : Ma classe de l'eleve adulte, atteinte depuis la VRAIE coquille
// adulte en tapant la VRAIE destination « Ma classe » (K-07), puis ses etats.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_de_classe.dart';
import 'package:rewayah_academy/features/com_messages/entree_messages_contexte.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart'
    show EcranPreparationEleveDemo, routesDemoClasse;
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';
import 'package:rewayah_academy/features/ma_classe_adulte/ma_classe_adulte_page.dart';
import 'package:rewayah_academy/features/tc_catalogue/routes_tc_b.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/emplacements_groupe.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart'
    show IdentiteGroupe;

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

  Future<void> monterCoquille(
    WidgetTester tester,
    String depart, {
    List<RouteBase> autres = const <RouteBase>[],
  }) async {
    final GoRouter routeur = GoRouter(
      initialLocation: depart,
      routes: <RouteBase>[...routesDemoAdulte('dev'), ...autres],
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
  }

  void taille(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  final Finder participants = find.byKey(
    const ValueKey<String>('ma-classe-participants'),
  );

  testWidgets('la destination Ma classe de la coquille ouvre la vraie page, '
      'en sections', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.accueil));
    expect(find.byType(MaClasseAdultePage), findsNothing);

    await tester.tap(find.text(t.adulte.nav.maClasse).first);
    await tester.pumpAndSettle();

    expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 1);
    expect(find.byType(MaClasseAdultePage), findsOneWidget);
    // Des sections, pas d'onglets (R3, E13).
    expect(find.byType(TabBar), findsNothing);
    // L'identite et la carte de seance CL-4, sans fork.
    expect(find.byType(IdentiteGroupe), findsOneWidget);
    expect(find.text(DonneesClasseDemo.classe), findsWidgets);
    expect(find.byType(CarteSession), findsOneWidget);
    expect(find.text(DonneesAdulteDemo.aProposClasse), findsOneWidget);

    // Les participants : une photo (initiales en repli) et un prenom chacun,
    // la personne qui regarde en tete.
    await tester.scrollUntilVisible(
      participants,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final List<ParticipantClasseAdulte> attendus = DonneesAdulteDemo.maClasse(
      GenreTitulaireDemo.homme,
      VueDemoAdulte.titulaire,
    )!.participants;
    expect(
      find.descendant(of: participants, matching: find.byType(PhotoEleve)),
      findsNWidgets(attendus.length),
    );
    expect(
      find.descendant(
        of: participants,
        matching: find.text(t.adulte.maClasse.vous(prenom: 'Mamadou')),
      ),
      findsOneWidget,
    );
    for (final ParticipantClasseAdulte p in attendus.skip(1)) {
      expect(
        find.descendant(of: participants, matching: find.text(p.prenom)),
        findsOneWidget,
      );
    }

    // Ressources (3 au plus) et progression en une ligne, sans pourcentage.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('ma-classe-progression')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(BlocBibliotheque), findsOneWidget);
    expect(find.text(t.adulte.accueil.ressources), findsOneWidget);
    expect(find.text(DonneesAdulteDemo.ligneProgressionClasse), findsOneWidget);
    expect(find.byType(BlocProgression), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('%'), findsNothing);

    // Rien du foyer ici (F8).
    expect(find.text(t.adulte.famille.maFamille), findsNothing);
    expect(find.text(t.adulte.famille.forfaitFamille), findsNothing);
    expect(find.text('Oumar'), findsNothing);
  });

  testWidgets('390 a 200 % : tout tient, sans debordement', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.maClasse));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('ma-classe-progression')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(PhotoEleve), findsWidgets);
  });

  testWidgets('bureau : participants et ressources cote a cote', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 1000));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.maClasse));
    final Offset gauche = tester.getTopLeft(participants);
    final Offset droite = tester.getTopLeft(find.byType(BlocBibliotheque));
    expect(droite.dx, greaterThan(gauche.dx));
  });

  testWidgets('vue du second adulte : jamais dans la Classe du titulaire, '
      'indisponible faute de sa propre Classe', (WidgetTester tester) async {
    // Le foyer fige (00_MAQUETTES section 3) : le second adulte est eleve
    // d'une AUTRE Classe, que la demonstration n'a pas.
    expect(
      DonneesAdulteDemo.maClasse(
        GenreTitulaireDemo.homme,
        VueDemoAdulte.secondAdulte,
      ),
      isNull,
    );
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.maClasse,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    expect(find.byType(MaClasseAdultePage), findsOneWidget);
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.byType(IdentiteGroupe), findsNothing);
    expect(participants, findsNothing);
    expect(find.textContaining('Mariama'), findsNothing);
  });

  test('cote titulaire, une seule liste, sans le second adulte', () {
    List<ParticipantClasseAdulte> liste(GenreTitulaireDemo g) =>
        DonneesAdulteDemo.maClasse(g, VueDemoAdulte.titulaire)!.participants;
    final List<ParticipantClasseAdulte> homme = liste(GenreTitulaireDemo.homme);
    expect(homme.first.estMoi, isTrue);
    expect(homme.first.prenom, 'Mamadou');
    expect(homme.first.id, DonneesAdulteDemo.mamadouId);
    // Le second adulte n'est jamais parmi les camarades du titulaire.
    expect(
      homme.map((ParticipantClasseAdulte p) => p.prenom),
      isNot(contains('Mariama')),
    );
    expect(
      liste(GenreTitulaireDemo.femme)
          .map((ParticipantClasseAdulte p) => p.prenom),
      isNot(contains('Mamadou')),
    );
    // La ligne de progression lit la page de reprise du titulaire.
    expect(
      DonneesAdulteDemo.ligneProgressionClasse,
      endsWith(DonneesAdulteDemo.pageRepriseTitulaire),
    );
  });

  testWidgets('« Voir tout » des ressources ouvre la Bibliotheque de la '
      'Classe', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(EcranDemoAdulte.maClasse),
      autres: <RouteBase>[
        GoRoute(
          path: RoutesTcB.bibliotheque,
          builder: (BuildContext _, GoRouterState etat) => Text(
            'bibliotheque:'
            '${etat.uri.queryParameters[RoutesTcB.parametreGroupe]}',
          ),
        ),
      ],
    );
    final Finder voirTout = find.descendant(
      of: find.byType(BlocBibliotheque),
      matching: find.byType(ActionPrincipale),
    );
    await tester.scrollUntilVisible(
      voirTout,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(voirTout);
    await tester.pumpAndSettle();
    expect(
      find.text('bibliotheque:${DonneesClasseDemo.groupeId}'),
      findsOneWidget,
    );
  });

  testWidgets('porte ouverte : le bouton de l\'emplacement mene a la '
      'preparation', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.maClasse,
        seance: EtatDemoClasse.fenetreOuverte,
      ),
      autres: routesDemoClasse('dev'),
    );
    final Finder bouton = find.descendant(
      of: find.byType(EmplacementEntreeVue),
      matching: find.byType(ActionPrincipale),
    );
    expect(bouton, findsOneWidget);
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.byType(EcranPreparationEleveDemo), findsOneWidget);
    expect(find.byType(MaClasseAdultePage), findsNothing);
  });

  testWidgets('hors ligne : la ligne d\'etat de l\'emplacement, pas de '
      'bouton', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.maClasse,
        seance: EtatDemoClasse.horsLigne,
      ),
    );
    expect(find.text(t.classe.entree.horsLigne), findsOneWidget);
    expect(find.text(t.classe.entree.rejoindre), findsNothing);
  });

  bool estHorsLigne(Widget w) =>
      w is EtatSysteme && w.nature == NatureEtat.horsLigne;

  testWidgets('reseau coupe (revue EA-R M5) : la destination Ma classe de la '
      'vraie route dit « hors ligne »', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(EcranDemoAdulte.accueil, reseauCoupe: true),
    );
    await tester.tap(find.text(t.adulte.nav.maClasse).first);
    await tester.pumpAndSettle();

    expect(find.byType(MaClasseAdultePage), findsOneWidget);
    expect(find.byWidgetPredicate(estHorsLigne), findsOneWidget);
    expect(find.text(t.commun.etats.horsLigne.titre), findsOneWidget);
    expect(find.text(t.commun.etats.echecServeur.titre), findsNothing);
    expect(find.byType(CarteSession), findsNothing);
    expect(participants, findsNothing);
    // Le titre de la page reste.
    expect(find.text(t.adulte.nav.maClasse), findsWidgets);
  });

  testWidgets('sans « reseau=coupe » : Ma classe est inchangee, aucun etat '
      'hors ligne', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.maClasse));
    expect(find.byWidgetPredicate(estHorsLigne), findsNothing);
    expect(find.byType(CarteSession), findsOneWidget);
    expect(participants, findsOneWidget);
  });

  testWidgets('hors ligne et capacite absente : reste indisponible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
        ],
        child: const MaClasseAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.byWidgetPredicate(estHorsLigne), findsNothing);
  });

  testWidgets('chargement : le squelette de la carte de seance', (
    WidgetTester tester,
  ) async {
    final Completer<MaClasseAdulteVM> jamais = Completer<MaClasseAdulteVM>();
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          maClasseAdulteProvider.overrideWith((Ref _) => jamais.future),
        ],
        child: const MaClasseAdultePage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(SqueletteCarteSession), findsOneWidget);
    expect(find.text(t.adulte.nav.maClasse), findsOneWidget);
    expect(find.byType(CarteSession), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('erreur : « Reessayer », et rien d\'invente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          maClasseAdulteProvider.overrideWith(
            (Ref _) => Future<MaClasseAdulteVM>.error(StateError('reseau')),
          ),
        ],
        child: const MaClasseAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.commun.reessayer), findsWidgets);
    expect(find.byType(CarteSession), findsNothing);
    expect(participants, findsNothing);
  });

  testWidgets('sans source serveur : indisponible, sans « Reessayer »', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(child: const MaClasseAdultePage()));
    await tester.pumpAndSettle();
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.text(t.commun.reessayer), findsNothing);
    expect(find.byType(CarteSession), findsNothing);
  });

  testWidgets('vide : aucune classe, un etat subi sans bouton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          maClasseAdulteProvider.overrideWith(
            (Ref _) async => const MaClasseAdulteVM(),
          ),
        ],
        child: const MaClasseAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.adulte.accueil.aucuneClasse), findsOneWidget);
    expect(find.text(t.adulte.maClasse.aucuneClasseDetail), findsOneWidget);
    expect(find.byType(ActionPrincipale), findsNothing);
    expect(find.byType(CarteSession), findsNothing);
    expect(participants, findsNothing);
  });

  testWidgets('COM-F : annonces et Messages de la Classe rendus apres les '
      'ressources, sur la Classe affichee', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.maClasse));
    expect(find.byType(MaClasseAdultePage), findsOneWidget);
    final AnnoncesDeClasse annonces = tester.widget<AnnoncesDeClasse>(
      find.byType(AnnoncesDeClasse, skipOffstage: false),
    );
    expect(annonces.classeId, DonneesClasseDemo.groupeId);
    expect(annonces.ecartAvant, isNotNull);
    expect(annonces.ecartApres, isNull);
    final EntreeMessagesContexte messages = tester
        .widget<EntreeMessagesContexte>(
          find.byType(EntreeMessagesContexte, skipOffstage: false),
        );
    expect(messages.type, TypeObjetLie.classe);
    expect(messages.objetId, DonneesClasseDemo.groupeId);
    expect(messages.ecartAvant, isNotNull);
  });
}
