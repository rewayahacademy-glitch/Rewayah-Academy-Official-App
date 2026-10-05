// COM-MSG-2 (K-07) : les entrees reelles des Messages metier de
// l'Administration, TAPEES depuis la vraie coquille admin et la vraie
// application (demonstration admin, aucun serveur) :
//
// - l'onglet Messages de l'Administration des communications
//   (`/admin/operations/communications/messages`), atteint par la ligne
//   « Communications » du tableau de bord puis l'onglet ; on y lit les fils
//   du controleur sur sa mission (paire Controleur / Administration) ;
// - « Ecrire a ... » dans le detail d'un dossier (Personnes, puis la ligne
//   du dossier).
//
// Operations reste le domaine allume : aucun neuvieme domaine (Q4).
//
// Depuis COM-FUS, le routeur monte `MessagesAdminPage` sur la route de
// l'onglet et sur `/:filId` : les tests K-07 parcourent la vraie coquille
// jusqu'au fil. La page est aussi prouvee montee seule, sur les memes
// adresses.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/com_annonces/administration_communications_page.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/entree_messages_contexte.dart';
import 'package:rewayah_academy/features/com_messages/liste_fils.dart';
import 'package:rewayah_academy/features/com_messages/messages_admin.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../../support/harnais.dart';
import 'support_messages.dart';

const Participant _rachid = Participant(
  id: 'p-rachid',
  nomAffiche: 'M. Rachid',
  fonction: 'Contrôleur pédagogique',
);
const Participant _omar = Participant(
  id: 'p-omar',
  nomAffiche: 'Omar Haddad',
  fonction: "Enseignant en cours d'inscription",
);

/// Le dossier d'Omar dans la demonstration admin.
const String _dossierOmar = DonneesDossiersDemo.enseignantNominal;

ObjetLie _mission() => ObjetLie(
  type: TypeObjetLie.mission,
  id: 'mission-12-11',
  libelle: 'Visite de contrôle, Classe An-Nour',
);
ObjetLie _dossier() => ObjetLie(
  type: TypeObjetLie.dossier,
  id: _dossierOmar,
  libelle: "Dossier d'Omar Haddad",
);

FauxMessagesMetier _port() => FauxMessagesMetier(
  fils: <FilMetier>[
    filAvec(
      id: 'fil-mission',
      autre: _rachid,
      objets: <ObjetLie>[_mission()],
      texte: 'La séance a commencé avec huit minutes de retard.',
      attention: const IndicateurAttention(nonLus: 1),
    ),
    filAvec(
      id: 'fil-dossier-omar',
      autre: _omar,
      objets: <ObjetLie>[_dossier()],
      texte: 'Bonjour, voici la pièce demandée.',
    ),
  ],
  conversations: <String, List<ConversationPossible>>{
    cleObjet(TypeObjetLie.dossier, _dossierOmar): <ConversationPossible>[
      ConversationPossible(interlocuteur: _omar, objet: _dossier()),
    ],
  },
  filsParObjet: <String, String>{
    cleObjet(TypeObjetLie.dossier, _dossierOmar): 'fil-dossier-omar',
  },
);

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<GoRouter> _monter(
  WidgetTester tester, {
  Size taille = const Size(1440, 900),
  PortMessagesMetier? port,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        portMessagesMetierProvider.overrideWithValue(port ?? _port()),
        capaciteEcrireOuverteTest,
      ],
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(Routes.admin);
  await _stabiliser(tester);
  return routeur;
}

String _chemin(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

/// Du tableau de bord a l'onglet Messages : la ligne « Communications »,
/// puis l'onglet.
Future<void> _ouvrirOngletMessages(WidgetTester tester) async {
  final Finder ligne = find.byKey(
    const ValueKey<String>('tableau-communications'),
  );
  await tester.scrollUntilVisible(
    ligne,
    200,
    scrollable: find
        .descendant(
          of: find.byType(TableauDeBordPage),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await _stabiliser(tester);
  await tester.tap(ligne);
  await _stabiliser(tester);
  // Sur telephone, la sous-navigation est un menu (ONGLETS-1) : il s'ouvre
  // sur la section courante.
  final Finder onglet = find.text(t.com.socle.navigation.ongletMessages);
  if (onglet.evaluate().isEmpty) {
    await tester.tap(find.text(t.com.socle.navigation.ongletAnnonces).first);
    await _stabiliser(tester);
  }
  await tester.tap(onglet.last);
  await _stabiliser(tester);
}

/// Personnes depuis la coquille (tiroir sur telephone, barre laterale sur
/// bureau), puis la ligne du dossier d'Omar.
Future<void> _ouvrirDossierOmar(WidgetTester tester) async {
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  final bool mobile = barre.evaluate().isEmpty;
  if (mobile) {
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
  }
  await tester.tap(
    find.descendant(
      of: mobile ? find.byKey(AdminShell.tiroirKey) : barre,
      matching: find.text(AdminDomaine.personnes.libelle),
    ),
  );
  await _stabiliser(tester);
  final Finder ligne = find.bySemanticsLabel(
    RegExp("^Ouvrir le dossier d(e |')Omar"),
  );
  await tester.ensureVisible(ligne);
  await _stabiliser(tester);
  await tester.tap(ligne);
  await _stabiliser(tester);
}

void main() {
  group('Onglet Messages de l Administration des communications', () {
    testWidgets('1440 : tableau de bord, Communications, Messages : l adresse '
        'et l onglet du socle, dans la coquille admin', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester);
      await _ouvrirOngletMessages(tester);
      expect(_chemin(routeur), Routes.adminCommunicationsMessages);
      expect(find.byType(SousNavigationDomaine), findsOneWidget);
      expect(find.byType(AdminShell), findsOneWidget);
      // COM-FUS : la page de COM-MSG-2, plus l'ecran provisoire du socle.
      expect(find.byType(MessagesAdminPage), findsOneWidget);
      expect(find.byType(AdministrationCommunicationsPage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '1440 : tableau de bord, Communications, Messages ; le fil '
      'du controleur sur sa mission s ouvre dans la coquille',
      (WidgetTester tester) async {
        final GoRouter routeur = await _monter(tester);
        await _ouvrirOngletMessages(tester);
        expect(_chemin(routeur), Routes.adminCommunicationsMessages);
        expect(find.byType(MessagesAdminPage), findsOneWidget);
        expect(find.byType(SousNavigationDomaine), findsOneWidget);
        expect(find.byType(ListeFils), findsOneWidget);
        expect(find.byKey(ListeFils.cleLigne('fil-mission')), findsOneWidget);
        expect(
          find.byKey(ListeFils.cleLigne('fil-dossier-omar')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(ListeFils.cleLigne('fil-mission')));
        await _stabiliser(tester);
        expect(_chemin(routeur), Routes.adminFilPour('fil-mission'));
        expect(find.byType(FilDiscussion), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(EnteteFilContexte),
            matching: find.text('Visite de contrôle, Classe An-Nour'),
          ),
          findsOneWidget,
        );
        // Toujours la coquille admin, Operations allume.
        expect(find.byType(AdminShell), findsOneWidget);
        final NavigationDrawer tiroir = tester.widget<NavigationDrawer>(
          find.descendant(
            of: find.byKey(AdminShell.barreLateraleKey),
            matching: find.byType(NavigationDrawer),
          ),
        );
        expect(
          tiroir.selectedIndex,
          domainesAdmin(voitDirection: false).indexOf(AdminDomaine.operations),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '390 : une surface a la fois, le retour du fil ramene a la '
      'liste de l onglet',
      (WidgetTester tester) async {
        final GoRouter routeur = await _monter(
          tester,
          taille: const Size(390, 844),
        );
        await _ouvrirOngletMessages(tester);
        expect(find.byType(ListeFils), findsOneWidget);
        await tester.tap(find.byKey(ListeFils.cleLigne('fil-dossier-omar')));
        await _stabiliser(tester);
        expect(_chemin(routeur), Routes.adminFilPour('fil-dossier-omar'));
        expect(find.byType(FilDiscussion), findsOneWidget);
        expect(find.byType(ListeFils), findsNothing);

        await tester.tap(find.byType(DisqueRetour));
        await _stabiliser(tester);
        expect(_chemin(routeur), Routes.adminCommunicationsMessages);
        expect(find.byType(ListeFils), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'production (port neutre) : pas encore disponible, sans '
      '« Reessayer »',
      (WidgetTester tester) async {
        await _monter(tester, port: const MessagesMetierIndisponibles());
        await _ouvrirOngletMessages(tester);
        expect(find.byType(MessagesAdminPage), findsOneWidget);
        expect(
          find.text(t.com.socle.composants.etats.indisponibleTitre),
          findsWidgets,
        );
        expect(find.text(t.com.socle.composants.etats.reessayer), findsNothing);
      },
    );
  });

  group('Detail d un dossier : ecrire a la personne du dossier', () {
    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      testWidgets('${taille.width.toInt()} : Personnes, le dossier, puis '
          '« Ecrire a » ouvre le fil du dossier', (WidgetTester tester) async {
        final GoRouter routeur = await _monter(tester, taille: taille);
        await _ouvrirDossierOmar(tester);
        final Finder ligne = find.descendant(
          of: find.byKey(EntreeMessagesContexte.cleObjet),
          matching: find.text(
            t.com.messages.entree.ecrireA(nom: 'Omar Haddad'),
          ),
        );
        await tester.ensureVisible(ligne);
        await _stabiliser(tester);
        expect(
          find.descendant(
            of: find.byKey(EntreeMessagesContexte.cleObjet),
            matching: find.text(t.com.messages.entree.titreDossier),
          ),
          findsOneWidget,
        );
        await tester.tap(ligne);
        await _stabiliser(tester);
        expect(_chemin(routeur), Routes.adminFilPour('fil-dossier-omar'));
        expect(find.byType(AdminShell), findsOneWidget);
        // L'onglet Messages, sur le fil du dossier (COM-FUS).
        expect(
          tester
              .widget<MessagesAdminPage>(find.byType(MessagesAdminPage))
              .filId,
          'fil-dossier-omar',
        );
        expect(find.byType(FilDiscussion), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('production (port neutre) : le detail du dossier est '
        'inchange', (WidgetTester tester) async {
      await _monter(tester, port: const MessagesMetierIndisponibles());
      await _ouvrirDossierOmar(tester);
      expect(find.byType(EntreeMessagesContexte), findsOneWidget);
      expect(find.byKey(EntreeMessagesContexte.cleObjet), findsNothing);
      expect(find.text(t.com.messages.entree.titreDossier), findsNothing);
    });
  });

  group('MessagesAdminPage montee seule (en attendant COM-FUS)', () {
    testWidgets('1440 : la sous-navigation, la liste ; le fil du controleur '
        'sur sa mission s ouvre a l adresse de l onglet', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterPage(tester);
      expect(find.byType(SousNavigationDomaine), findsOneWidget);
      expect(find.byType(ListeFils), findsOneWidget);
      expect(find.byKey(ListeFils.cleLigne('fil-mission')), findsOneWidget);
      expect(
        find.byKey(ListeFils.cleLigne('fil-dossier-omar')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ListeFils.cleLigne('fil-mission')));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.adminFilPour('fil-mission'));
      expect(find.byType(FilDiscussion), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EnteteFilContexte),
          matching: find.text('Visite de contrôle, Classe An-Nour'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : une surface a la fois, le retour du fil ramene a la '
        'liste de l onglet', (WidgetTester tester) async {
      final GoRouter routeur = await _monterPage(
        tester,
        taille: const Size(390, 844),
      );
      await tester.tap(find.byKey(ListeFils.cleLigne('fil-dossier-omar')));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.adminFilPour('fil-dossier-omar'));
      expect(find.byType(FilDiscussion), findsOneWidget);
      expect(find.byType(ListeFils), findsNothing);
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.adminCommunicationsMessages);
      expect(find.byType(ListeFils), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('production (port neutre) : pas encore disponible, sans '
        '« Reessayer »', (WidgetTester tester) async {
      await _monterPage(tester, port: const MessagesMetierIndisponibles());
      expect(
        find.text(t.com.socle.composants.etats.indisponibleTitre),
        findsWidgets,
      );
      expect(find.text(t.com.socle.composants.etats.reessayer), findsNothing);
    });
  });
}

/// [MessagesAdminPage] montee seule, sur les adresses de l'onglet (liste et
/// fil), hors de la coquille (le routeur la monte depuis COM-FUS).
Future<GoRouter> _monterPage(
  WidgetTester tester, {
  Size taille = const Size(1440, 900),
  PortMessagesMetier? port,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.adminCommunicationsMessages,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.adminCommunicationsMessages,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: MessagesAdminPage()),
        routes: <RouteBase>[
          GoRoute(
            path: ':filId',
            builder: (BuildContext _, GoRouterState etat) => Scaffold(
              body: MessagesAdminPage(filId: etat.pathParameters['filId']),
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        portMessagesMetierProvider.overrideWithValue(port ?? _port()),
        capaciteEcrireOuverteTest,
      ],
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
