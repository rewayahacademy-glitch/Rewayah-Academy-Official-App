// COM-F : les routes, coquilles et cloches des Communications, sur le VRAI
// routeur (K-07) : chaque nouvelle route resout vers son ecran, chaque
// entree de coquille est TAPEE depuis la coquille reelle.

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/com_annonces/administration_communications_page.dart';
import 'package:rewayah_academy/features/com_annonces/publier_annonce_classe_page.dart';
import 'package:rewayah_academy/features/com_communaute/communaute_page.dart';
import 'package:rewayah_academy/features/com_messages/messages_admin.dart';
import 'package:rewayah_academy/features/com_messages/messages_page.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/compte/espaces_compte.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart,
  AppRole role, {
  Size taille = const Size(900, 1000),
}) => monterRouteur(
  tester,
  depart,
  source: FausseSourceSession(sessionActive(role)),
  taille: taille,
);

/// La coquille admin reelle, comme `admin_coque_test.dart` : la vraie
/// application en demonstration admin, aucun serveur.
Future<GoRouter> _monterAdmin(
  WidgetTester tester,
  String depart, {
  Size taille = const Size(1440, 900),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesDemoAdmin(environnement: 'staging'),
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

String _chemin(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

/// Un enseignant qui est aussi controleur : deux espaces, donc le raccourci
/// Espaces de CT-9 dans l'en-tete, a cote de la cloche.
class _DeuxEspaces extends EspacesCompteControleur {
  @override
  EspacesCompte build() => const EspacesCompte(
    disponibles: <EspaceTravail>[
      EspaceTravail.enseignement,
      EspaceTravail.controle,
    ],
    actif: EspaceTravail.enseignement,
  );
}

/// Le meme compte a deux espaces, vu depuis l'espace de controle (m4 de
/// COM-F-b-R : le controleur passe aussi par l'en-tete des espaces).
class _DeuxEspacesControle extends EspacesCompteControleur {
  @override
  EspacesCompte build() => const EspacesCompte(
    disponibles: <EspaceTravail>[
      EspaceTravail.enseignement,
      EspaceTravail.controle,
    ],
    actif: EspaceTravail.controle,
  );
}

Finder _dans(Key cle, Finder cible) =>
    find.descendant(of: find.byKey(cle), matching: cible);

void main() {
  group('Chaque route Communications resout vers son ecran', () {
    // (chemin, role, ecran, destination active de la barre ou null).
    // null : pas de coquille. -1 : coquille sans onglet actif, la cloche
    // y est la seule entree active (COM-F-Q5).
    final List<(String, AppRole, Type, int?)> table =
        <(String, AppRole, Type, int?)>[
          (Routes.tuteurMessages, AppRole.guardian, MessagesPage, 0),
          (Routes.tuteurFilPour('f1'), AppRole.guardian, MessagesPage, 0),
          (Routes.enseignantMessages, AppRole.teacher, MessagesPage, 1),
          (Routes.enseignantFilPour('f1'), AppRole.teacher, MessagesPage, 1),
          (Routes.enseignantCommunaute, AppRole.teacher, CommunautePage, 0),
          (
            Routes.enseignantPublicationPour('p1'),
            AppRole.teacher,
            CommunautePage,
            0,
          ),
          (
            Routes.enseignantNotifications,
            AppRole.teacher,
            NotificationsPage,
            -1,
          ),
          (
            Routes.publierAnnoncePour('g1'),
            AppRole.teacher,
            PublierAnnonceClassePage,
            null,
          ),
        ];
    for (final (String chemin, AppRole role, Type ecran, int? actif) in table) {
      testWidgets('$chemin (${role.valeurSql}) rend $ecran', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await _monter(tester, chemin, role);
        expect(lieu(routeur), chemin, reason: 'la garde a devie $chemin');
        expect(find.byType(ecran), findsOneWidget);
        if (actif != null) {
          expect(
            tester.widget<NavShell>(find.byType(NavShell)).indexActif ?? -1,
            actif,
            reason: 'aucune destination ajoutee : la pose garde la sienne',
          );
        } else {
          expect(find.byType(NavShell), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('le fil demande voyage par l adresse', (
      WidgetTester tester,
    ) async {
      await _monter(tester, Routes.enseignantFilPour('fil-7'), AppRole.teacher);
      expect(
        tester.widget<MessagesPage>(find.byType(MessagesPage)).filId,
        'fil-7',
      );
    });

    testWidgets('les ecrans provisoires disent « pas encore disponible »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, Routes.enseignantCommunaute, AppRole.teacher);
      expect(
        find.text(t.com.socle.navigation.provisoire.communauteDetail),
        findsOneWidget,
      );
      expect(
        find.text(t.com.socle.composants.etats.indisponibleTitre),
        findsOneWidget,
      );
    });

    testWidgets('le retour de la Communaute ramene a Aujourd hui', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        Routes.enseignantCommunaute,
        AppRole.teacher,
      );
      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.enseignantJournee);
    });

    testWidgets('le retour de la publication ramene a l Espace Classe', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        Routes.publierAnnoncePour('g1'),
        AppRole.teacher,
      );
      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.groupePour('g1'));
    });
  });

  group('Cloche des coquilles : la NotificationsPage existante', () {
    testWidgets('enseignant : la cloche de la coquille y mene', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        Routes.enseignantCreneaux,
        AppRole.teacher,
      );
      final Finder cloche = find.bySemanticsLabel(
        t.commun.entete.notifications,
      );
      expect(cloche, findsWidgets);
      await tester.tap(cloche.first);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.enseignantNotifications);
      expect(find.byType(NotificationsPage), findsOneWidget);

      // Le retour ramene a Aujourd'hui, pas a l'Accueil du tuteur.
      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.enseignantJournee);
    });

    testWidgets('controleur : la cloche de l Historique y mene', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        Routes.controleurHistorique,
        AppRole.controller,
      );
      final Finder cloche = find.bySemanticsLabel(
        t.commun.entete.notifications,
      );
      expect(cloche, findsWidgets);
      await tester.tap(cloche.first);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.controleurNotifications);
      expect(find.byType(NotificationsPage), findsOneWidget);
      // COM-F-Q5 : la cloche est la seule entree active, aucun onglet.
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, isNull);
    });

    testWidgets(
      'l eleve a sa cloche depuis la fiche du 27/10 (ligne 12), elle ouvre '
      'son centre et le retour ramene a son Accueil',
      (WidgetTester tester) async {
        final GoRouter routeur = await _monter(
          tester,
          Routes.eleve,
          AppRole.student,
        );
        expect(find.byType(ClocheNotifications), findsOneWidget);
        await tester.tap(find.byType(ClocheNotifications));
        await stabiliser(tester);
        expect(lieu(routeur), Routes.eleveNotifications);
        expect(find.byType(NotificationsPage), findsOneWidget);
        expect(
          tester.widget<NavShell>(find.byType(NavShell)).indexActif,
          isNull,
        );
        await tester.tap(find.byType(DisqueRetour));
        await stabiliser(tester);
        expect(lieu(routeur), Routes.eleve);
      },
    );

    test(
      'notificationsPour : une page par role a cloche, sous son prefixe',
      () {
        for (final AppRole role in AppRole.values) {
          final String? chemin = Routes.notificationsPour(role);
          if (role == AppRole.accountant) {
            expect(chemin, isNull, reason: role.valeurSql);
            continue;
          }
          expect(chemin, startsWith(Routes.prefixePour(role)));
        }
      },
    );
  });

  group('AdminShell : cloche, Le Studio, Communications sous Operations', () {
    testWidgets('1440 : la cloche de l en-tete ouvre les notifications', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterAdmin(tester, Routes.admin);
      await tester.tap(
        find.bySemanticsLabel(t.commun.entete.notifications).first,
      );
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.adminNotifications);
      expect(find.byType(NotificationsPage), findsOneWidget);
      // Dans la coquille admin, aucun domaine allume.
      expect(find.byType(AdminShell), findsOneWidget);
      final NavigationDrawer tiroir = tester.widget<NavigationDrawer>(
        _dans(AdminShell.barreLateraleKey, find.byType(NavigationDrawer)),
      );
      expect(tiroir.selectedIndex, isNull);

      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.admin);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 : « Le Studio » ouvre /admin/studio, hors coquille', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterAdmin(tester, Routes.admin);
      await tester.tap(
        find.bySemanticsLabel(t.com.socle.navigation.ouvrirStudio),
      );
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.adminStudio);
      expect(find.byType(StudioPage), findsOneWidget);
      expect(find.byType(AdminShell), findsNothing);

      // La sortie du Studio ramene a l'Accueil admin.
      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.admin);
      expect(tester.takeException(), isNull);
    });

    // COM-F-Q5-R : sous 600, la page est decoupee du padding sous le
    // Scaffold ; le clavier, deja evite par le Scaffold, ne doit pas
    // l'etre une seconde fois par la page.
    testWidgets('390, clavier ouvert : le clavier n est compte qu une fois', (
      WidgetTester tester,
    ) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await _monterAdmin(tester, Routes.admin, taille: const Size(390, 844));
      // Le MediaQuery pose par `removePadding`, juste sous la barre mobile :
      // c'est lui que la page lit, avant tout Scaffold de la page.
      final Finder decoupe = find
          .descendant(
            of: find.descendant(
              of: find.byType(AdminShell),
              matching: find.byType(Expanded),
            ),
            matching: find.byType(MediaQuery),
          )
          .first;
      final MediaQueryData donnees = tester.widget<MediaQuery>(decoupe).data;
      expect(donnees.viewInsets.bottom, 0);
      expect(donnees.padding.top, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : cloche dans l en-tete, Le Studio au pied du tiroir', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterAdmin(
        tester,
        Routes.admin,
        taille: const Size(390, 844),
      );
      expect(
        find.bySemanticsLabel(t.commun.entete.notifications),
        findsWidgets,
      );
      await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
      await stabiliser(tester);
      await tester.tap(
        _dans(AdminShell.tiroirKey, find.text(t.com.socle.navigation.studio)),
      );
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.adminStudio);
      expect(find.byType(StudioPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Communications : sous Operations, trois onglets pairs', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterAdmin(
        tester,
        Routes.adminOperationsCommunications,
      );
      // La racine renvoie au premier onglet.
      expect(_chemin(routeur), Routes.adminCommunicationsAnnonces);
      expect(find.byType(AdministrationCommunicationsPage), findsOneWidget);
      expect(find.byType(SousNavigationDomaine), findsOneWidget);
      // Operations reste le domaine allume : aucun neuvieme domaine.
      final List<AdminDomaine> domaines = domainesAdmin(voitDirection: false);
      expect(domaines.length, lessThanOrEqualTo(AdminShell.maxDomaines));
      final NavigationDrawer tiroir = tester.widget<NavigationDrawer>(
        _dans(AdminShell.barreLateraleKey, find.byType(NavigationDrawer)),
      );
      expect(tiroir.selectedIndex, domaines.indexOf(AdminDomaine.operations));

      await tester.tap(
        find.text(t.com.socle.navigation.ongletModeration).first,
      );
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.adminCommunicationsModeration);

      await tester.tap(find.text(t.com.socle.navigation.ongletMessages).first);
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.adminCommunicationsMessages);
      // COM-FUS : l'onglet Messages monte la page de COM-MSG-2.
      expect(find.byType(MessagesAdminPage), findsOneWidget);
      expect(find.byType(AdministrationCommunicationsPage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // COM-F-b (UX_REV-03) : la seconde entree reelle de COM-W04, avec la
    // recherche. La racine Operations mene a Groupes, jamais ici.
    testWidgets(
      'tableau de bord : la ligne Communications, Operations allume',
      (WidgetTester tester) async {
        final GoRouter routeur = await _monterAdmin(tester, Routes.admin);
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
        await stabiliser(tester);
        expect(
          find.descendant(
            of: ligne,
            matching: find.text(t.com.socle.navigation.communications),
          ),
          findsOneWidget,
        );
        await tester.tap(ligne);
        await stabiliser(tester);
        expect(_chemin(routeur), Routes.adminCommunicationsAnnonces);
        expect(find.byType(AdministrationCommunicationsPage), findsOneWidget);
        final NavigationDrawer tiroir = tester.widget<NavigationDrawer>(
          _dans(AdminShell.barreLateraleKey, find.byType(NavigationDrawer)),
        );
        expect(
          tiroir.selectedIndex,
          domainesAdmin(voitDirection: false).indexOf(AdminDomaine.operations),
        );
        expect(tester.takeException(), isNull);
      },
    );

    // COM-F-b (02_DEC-01) : Le Studio a son icone ; il n'emprunte plus celle
    // des Echanges du controleur.
    for (final Size taille in <Size>[
      const Size(1440, 900),
      const Size(390, 844),
    ]) {
      testWidgets('${taille.width.toInt()} : Le Studio porte AppIcons.studio', (
        WidgetTester tester,
      ) async {
        await _monterAdmin(tester, Routes.admin, taille: taille);
        if (taille.width < 600) {
          await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
          await stabiliser(tester);
        }
        Finder icone(AppIcon i) => find.descendant(
          of: find.byType(AdminShell),
          matching: find.byWidgetPredicate(
            (Widget w) => w is Icon && (w.icon == i.repos || w.icon == i.actif),
          ),
        );
        expect(icone(AppIcons.studio), findsOneWidget);
        expect(icone(AppIcons.discussion), findsNothing);
      });
    }

    testWidgets('la recherche de l en-tete trouve les Communications', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterAdmin(tester, Routes.admin);
      await tester.tap(find.bySemanticsLabel(t.nav.admin.recherche));
      await stabiliser(tester);
      await tester.enterText(
        find.byType(TextField),
        t.com.socle.navigation.communications,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.adminCommunicationsAnnonces);
    });

    test('ongletsCommunications : Annonces, Moderation, Messages', () {
      expect(ongletsCommunications().map((o) => o.chemin).toList(), <String>[
        Routes.adminCommunicationsAnnonces,
        Routes.adminCommunicationsModeration,
        Routes.adminCommunicationsMessages,
      ]);
      for (final o in ongletsCommunications()) {
        expect(o.chemin, startsWith(Routes.adminOperations));
      }
    });

    testWidgets('390 : la cloche de l en-tete de page y mene', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterAdmin(
        tester,
        Routes.admin,
        taille: const Size(390, 844),
      );
      final Finder cloche = find.byType(ClocheNotifications);
      expect(cloche, findsOneWidget);
      // Sous 600 la cloche est dans l'en-tete de page, pas dans la barre.
      expect(
        find.descendant(of: find.byType(EntetePage), matching: cloche),
        findsOneWidget,
      );
      await tester.tap(cloche);
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.adminNotifications);
      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('COM-F-Q5 : la cloche se montre active sur sa propre page', () {
    bool actif(WidgetTester tester) => tester
        .widget<ClocheNotifications>(find.byType(ClocheNotifications))
        .actif;
    int? ongletActif(WidgetTester tester) =>
        tester.widget<NavShell>(find.byType(NavShell)).indexActif;

    for (final (String accueil, String page, AppRole role)
        in <(String, String, AppRole)>[
          (
            Routes.enseignantJournee,
            Routes.enseignantNotifications,
            AppRole.teacher,
          ),
          (
            Routes.controleur,
            Routes.controleurNotifications,
            AppRole.controller,
          ),
          (Routes.tuteurAccueil, Routes.tuteurNotifications, AppRole.guardian),
        ]) {
      testWidgets('${role.valeurSql} : repos ailleurs, active sur $page', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await _monter(tester, accueil, role);
        expect(actif(tester), isFalse);
        expect(ongletActif(tester), isNotNull);
        final SemanticsHandle repos = tester.ensureSemantics();
        expect(
          tester
              .getSemantics(find.byType(ClocheNotifications))
              .flagsCollection
              .isSelected,
          Tristate.none,
          reason: 'au repos, la cloche n annonce aucun etat de selection',
        );
        repos.dispose();
        routeur.go(page);
        await stabiliser(tester);
        expect(find.byType(NotificationsPage), findsOneWidget);
        expect(actif(tester), isTrue);
        // Une seule selection a l'ecran : la cloche, pas l'onglet parent.
        expect(
          ongletActif(tester),
          isNull,
          reason: 'sur sa page, la cloche est la seule entree active',
        );
        final SemanticsHandle semantique = tester.ensureSemantics();
        expect(
          tester
              .getSemantics(find.byType(ClocheNotifications))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
          reason: 'la cloche active s annonce selectionnee',
        );
        semantique.dispose();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('admin : repos sur l Accueil, active sur ses notifications', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterAdmin(tester, Routes.admin);
      expect(actif(tester), isFalse);
      routeur.go(Routes.adminNotifications);
      await stabiliser(tester);
      expect(actif(tester), isTrue);
      expect(
        tester.widget<AdminShell>(find.byType(AdminShell)).domaineActif,
        isNull,
        reason: 'sur ses notifications, aucun domaine n est surligne',
      );
    });
  });

  group('COM-F-Q5 : une seule rangee d actions, Espaces puis cloche', () {
    for (final (
          AppRole role,
          String depart,
          EspacesCompteControleur Function() espaces,
        )
        in <(AppRole, String, EspacesCompteControleur Function())>[
          (AppRole.teacher, Routes.enseignantJournee, _DeuxEspaces.new),
          // COM-FUS (m4 de COM-F-b-R) : le meme cas pour le controleur.
          (AppRole.controller, Routes.controleur, _DeuxEspacesControle.new),
        ]) {
      testWidgets('${role.name}, compte a deux espaces : raccourci puis '
          'cloche, une fois', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        late GoRouter routeur;
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              ...surchargesRouteur(FausseSourceSession(sessionActive(role))),
              espacesCompteProvider.overrideWith(espaces),
            ],
            child: TranslationProvider(
              child: Consumer(
                builder: (BuildContext _, WidgetRef ref, Widget? _) {
                  routeur = ref.read(routeurProvider);
                  return MaterialApp.router(
                    theme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.light,
                    ),
                    routerConfig: routeur,
                  );
                },
              ),
            ),
          ),
        );
        await stabiliser(tester);
        routeur.go(depart);
        await stabiliser(tester);

        final Finder raccourci = find.byType(RaccourciEspaces);
        final Finder cloche = find.byType(ClocheNotifications);
        expect(raccourci, findsOneWidget);
        expect(cloche, findsOneWidget);
        // Meme ligne, Espaces avant la cloche (sens de lecture).
        expect(
          tester.getCenter(raccourci).dy,
          moreOrLessEquals(tester.getCenter(cloche).dy),
        );
        expect(
          tester.getCenter(raccourci).dx,
          lessThan(tester.getCenter(cloche).dx),
        );
      });
    }
  });

  group('COM-F-Q5 : barre mobile admin', () {
    Finder champ() => find.descendant(
      of: find.byType(AdminShell),
      matching: find.byType(TextField),
    );

    testWidgets('390 avec encoche : aucun vide entre la barre et le titre', (
      WidgetTester tester,
    ) async {
      tester.view.padding = const FakeViewPadding(top: 47);
      tester.view.viewPadding = const FakeViewPadding(top: 47);
      addTearDown(tester.view.reset);
      await _monterAdmin(tester, Routes.admin, taille: const Size(390, 844));
      final double basChamp = tester
          .getBottomLeft(find.bySemanticsLabel(t.nav.admin.menu))
          .dy;
      final double hautTitre = tester.getTopLeft(find.byType(EntetePage)).dy;
      // La zone sure du haut n'est posee qu'une fois, par la barre.
      expect(hautTitre - basChamp, lessThan(47));
    });

    // Balayage pixel par pixel sous 600 : partout ou le champ est en ligne,
    // son indication tient sur UNE ligne (revue COM-F-Q5 : une bande de 6 px
    // la passait a la ligne quand la place reservee etait sous-estimee).
    testWidgets('sous 600 : champ en ligne = indication sur une ligne', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      double? uneLigne;
      int champsVus = 0;
      for (double largeur = 599; largeur >= 300; largeur -= 1) {
        tester.view.physicalSize = Size(largeur, 900);
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: MaterialApp(
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                home: AdminShell(
                  domaines: domainesAdmin(voitDirection: true),
                  domaineActif: AdminDomaine.accueil,
                  onAller: (_) {},
                  onCompte: () {},
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        );
        final Finder indication = find.descendant(
          of: find.byType(TextField),
          matching: find.text(t.nav.admin.rechercheIndication),
        );
        if (indication.evaluate().isEmpty) continue;
        champsVus++;
        final double hauteur = tester.getSize(indication).height;
        uneLigne ??= hauteur;
        expect(hauteur, uneLigne, reason: 'indication sur 2 lignes a $largeur');
      }
      expect(champsVus, greaterThan(0), reason: 'le champ doit apparaitre');
    });

    testWidgets(
      '320 : la recherche passe en bouton, la barre garde une ligne',
      (WidgetTester tester) async {
        await _monterAdmin(tester, Routes.admin, taille: const Size(320, 640));
        expect(champ(), findsNothing);
        expect(find.bySemanticsLabel(t.nav.admin.recherche), findsOneWidget);
        expect(find.byType(ClocheNotifications), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    // La bascule se decide sur la largeur MESUREE de l'indication : la
    // police de test (un carre par glyphe) est plus large que la vraie, d'ou
    // 599 ici ; avec les vraies polices le champ tient des 390
    // (`test/capture/cloches_capture_test.dart`).
    testWidgets('599 : le champ de recherche reste en ligne', (
      WidgetTester tester,
    ) async {
      await _monterAdmin(tester, Routes.admin, taille: const Size(599, 900));
      expect(champ(), findsOneWidget);
    });
  });

  group('Garde par prefixe : chaque route reste a son role', () {
    final DateTime maintenant = DateTime.utc(2026, 10, 4, 10);
    final Map<String, AppRole> proprietaires = <String, AppRole>{
      Routes.tuteurMessages: AppRole.guardian,
      Routes.tuteurFilPour('f1'): AppRole.guardian,
      Routes.enseignantMessages: AppRole.teacher,
      Routes.enseignantCommunaute: AppRole.teacher,
      Routes.enseignantNotifications: AppRole.teacher,
      Routes.publierAnnoncePour('g1'): AppRole.teacher,
      Routes.controleurNotifications: AppRole.controller,
      Routes.adminNotifications: AppRole.admin,
      Routes.adminStudio: AppRole.admin,
      Routes.canalStudioPour('c1'): AppRole.admin,
      Routes.adminCommunicationsAnnonces: AppRole.admin,
      Routes.adminCommunicationsModeration: AppRole.admin,
      Routes.adminCommunicationsMessages: AppRole.admin,
      Routes.adminFilPour('f1'): AppRole.admin,
    };
    for (final MapEntry<String, AppRole> e in proprietaires.entries) {
      test('${e.key} : ouvert a ${e.value.valeurSql} seulement', () {
        for (final AppRole role in AppRole.values) {
          final String? redirection = deciderRedirection(
            session: sessionActive(role),
            cheminDemande: e.key,
            maintenant: maintenant,
          );
          if (role == e.value) {
            expect(redirection, isNull, reason: role.valeurSql);
          } else {
            expect(redirection, isNotNull, reason: role.valeurSql);
          }
        }
      });
    }

    test('le controleur et le comptable n entrent pas dans Le Studio', () {
      for (final AppRole role in <AppRole>[
        AppRole.controller,
        AppRole.accountant,
        AppRole.teacher,
      ]) {
        expect(
          deciderRedirection(
            session: sessionActive(role),
            cheminDemande: Routes.adminStudio,
            maintenant: maintenant,
          ),
          isNotNull,
          reason: role.valeurSql,
        );
      }
    });

    test('chaque route Communications est declaree au routeur', () {
      final ProviderContainer conteneur = ProviderContainer(
        overrides: surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
        ),
      );
      addTearDown(conteneur.dispose);
      final List<String> declares = cheminsDeclares(
        conteneur.read(routeurProvider),
      );
      expect(
        declares,
        containsAll(<String>[
          Routes.tuteurMessages,
          '${Routes.tuteurMessages}/:filId',
          Routes.enseignantMessages,
          '${Routes.enseignantMessages}/:filId',
          Routes.enseignantCommunaute,
          '${Routes.enseignantCommunaute}/:publicationId',
          Routes.enseignantNotifications,
          '${Routes.enseignantGroupe}/:groupeId/annonce',
          Routes.controleurNotifications,
          Routes.adminNotifications,
          Routes.adminStudio,
          '${Routes.adminStudioCanaux}/:canalId',
          Routes.adminOperationsCommunications,
          Routes.adminCommunicationsAnnonces,
          Routes.adminCommunicationsModeration,
          Routes.adminCommunicationsMessages,
          '${Routes.adminCommunicationsMessages}/:filId',
        ]),
      );
    });
  });
}
