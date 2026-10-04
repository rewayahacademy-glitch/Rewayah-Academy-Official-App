// COM-F : les routes, coquilles et cloches des Communications, sur le VRAI
// routeur (K-07) : chaque nouvelle route resout vers son ecran, chaque
// entree de coquille est TAPEE depuis la coquille reelle.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';
import 'package:rewayah_academy/features/com_annonces/administration_communications_page.dart';
import 'package:rewayah_academy/features/com_annonces/publier_annonce_classe_page.dart';
import 'package:rewayah_academy/features/com_communaute/communaute_page.dart';
import 'package:rewayah_academy/features/com_messages/messages_page.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
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

Finder _dans(Key cle, Finder cible) =>
    find.descendant(of: find.byKey(cle), matching: cible);

void main() {
  group('Chaque route Communications resout vers son ecran', () {
    // (chemin, role, ecran, destination active de la barre ou null)
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
            0,
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
            tester.widget<NavShell>(find.byType(NavShell)).indexActif,
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
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 0);
    });

    testWidgets('l eleve n a toujours aucune cloche', (
      WidgetTester tester,
    ) async {
      await _monter(tester, Routes.eleve, AppRole.student);
      expect(find.byType(ClocheNotifications), findsNothing);
    });

    test(
      'notificationsPour : une page par role a cloche, sous son prefixe',
      () {
        for (final AppRole role in AppRole.values) {
          final String? chemin = Routes.notificationsPour(role);
          if (role == AppRole.student || role == AppRole.accountant) {
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
      expect(
        tester
            .widget<AdministrationCommunicationsPage>(
              find.byType(AdministrationCommunicationsPage),
            )
            .onglet,
        OngletCommunications.messages,
      );
      expect(tester.takeException(), isNull);
    });

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

  group('Emplacements d entree poses dans les pages hotes', () {
    // Les emplacements sont vides (SizedBox.shrink) tant que leurs voies ne
    // les remplissent pas : on verifie qu'ils sont poses, les tests propres
    // des pages hotes verifient que leur rendu n'a pas change.
    final Map<String, List<String>> hotes = <String, List<String>>{
      'lib/features/classe_tuteur/classe_tuteur_page.dart': <String>[
        'AnnoncesDeClasse(',
        'EntreeMessagesContexte(',
      ],
      'lib/features/fiche_groupe/fiche_groupe_page.dart': <String>[
        'AnnoncesDeClasse(',
        'EntreeMessagesContexte(',
      ],
      'lib/features/enseignant_classes/mes_classes_page.dart': <String>[
        'EntreeMessagesContexte(',
      ],
      'lib/features/ma_classe_adulte/ma_classe_adulte_page.dart': <String>[
        'AnnoncesDeClasse(',
        'EntreeMessagesContexte(',
      ],
    };
    for (final MapEntry<String, List<String>> h in hotes.entries) {
      test(h.key, () {
        final String source = File(h.key).readAsStringSync();
        for (final String attendu in h.value) {
          expect(source, contains(attendu), reason: '${h.key} : $attendu');
        }
      });
    }
  });
}
