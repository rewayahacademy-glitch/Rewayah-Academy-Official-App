// Fiche « Fraicheur et notifications » (27/10/2026), lignes 12 et 14 : la
// cloche et son point de non-lus sur l'accueil du tuteur et de l'enseignante,
// sur le VRAI routeur ; le point vient d'un seul provider alimente par le
// port de notifications ; ouvrir la page marque tout lu et le point
// disparait. L'eleve mineur n'a pas de cloche (reponse Q5 du directeur du
// 04/10, maintenue le 27/10 : le foyer est prevenu) ; le test des coquilles
// (`routes_communications_test`) le tient.
//
// Le port est un faux en memoire ; aucun Supabase.

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// Des notifications en memoire qui savent tout marquer lu.
class _FauxNotifications
    implements PortNotifications, PortLectureGroupeeNotifications {
  _FauxNotifications(this.rendues);

  List<NotificationTuteur> rendues;
  int lectures = 0;
  int marquagesGroupes = 0;

  @override
  Future<List<NotificationTuteur>> liste() async {
    lectures++;
    return rendues;
  }

  @override
  Future<NotificationTuteur?> detail(String id) async =>
      rendues.where((NotificationTuteur n) => n.id == id).firstOrNull;

  @override
  Future<void> marquerToutesLues() async {
    marquagesGroupes++;
    rendues = <NotificationTuteur>[
      for (final NotificationTuteur n in rendues) n.marqueeLue(),
    ];
  }
}

NotificationTuteur _notification(String id, {bool lue = false}) =>
    NotificationTuteur(
      id: id,
      titre: 'Une classe vient d\'être créée.',
      date: DateTime(2026, 10, 27, 9),
      lue: lue,
      niveau: lue ? NiveauAttention.information : NiveauAttention.aLire,
    );

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart,
  AppRole role, {
  required PortNotifications port,
}) => monterRouteur(
  tester,
  depart,
  source: FausseSourceSession(sessionActive(role)),
  surcharges: <Override>[portNotificationsProvider.overrideWithValue(port)],
);

Finder _clocheAvecPoint() =>
    find.bySemanticsLabel(t.commun.entete.notificationsUneNonLue);

Finder _clocheSansPoint() =>
    find.bySemanticsLabel(t.commun.entete.notifications);

void main() {
  // (depart, role, ecran attendu)
  final List<(String, AppRole, Type)> accueils = <(String, AppRole, Type)>[
    (Routes.tuteurAccueil, AppRole.guardian, AccueilFamillePage),
    (Routes.enseignantJournee, AppRole.teacher, JourneePage),
  ];

  group('ligne 12 : la cloche et son point sur les accueils', () {
    for (final (String depart, AppRole role, Type ecran) in accueils) {
      testWidgets('$depart : une non-lue, un point (${role.valeurSql})', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          depart,
          role,
          port: _FauxNotifications(<NotificationTuteur>[
            _notification('n1'),
            _notification('n2', lue: true),
          ]),
        );
        expect(find.byType(ecran), findsOneWidget);
        expect(find.byType(ClocheNotifications), findsOneWidget);
        expect(_clocheAvecPoint(), findsOneWidget);
      });

      testWidgets('$depart : tout lu, pas de point (${role.valeurSql})', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          depart,
          role,
          port: _FauxNotifications(<NotificationTuteur>[
            _notification('n1', lue: true),
          ]),
        );
        expect(find.byType(ClocheNotifications), findsOneWidget);
        expect(_clocheAvecPoint(), findsNothing);
        expect(_clocheSansPoint(), findsOneWidget);
      });
    }

    testWidgets('production : aucune source, la cloche reste, sans point', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        Routes.enseignantJournee,
        AppRole.teacher,
        port: const NotificationsIndisponibles(),
      );
      expect(find.byType(ClocheNotifications), findsOneWidget);
      expect(_clocheAvecPoint(), findsNothing);
      expect(find.bySemanticsLabel(RegExp('non lue')), findsNothing);
    });

    testWidgets('l eleve mineur n a pas de cloche, meme avec des non-lues', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        Routes.eleve,
        AppRole.student,
        port: _FauxNotifications(<NotificationTuteur>[_notification('n1')]),
      );
      expect(find.byType(ClocheNotifications), findsNothing);
    });
  });

  group('ligne 14 : ouvrir la page marque tout lu', () {
    for (final (String depart, AppRole role, _) in accueils) {
      testWidgets(
        '$depart : la cloche ouvre le centre du role, tout est marque lu, '
        'le point disparait (${role.valeurSql})',
        (WidgetTester tester) async {
          final _FauxNotifications port = _FauxNotifications(
            <NotificationTuteur>[_notification('n1'), _notification('n2')],
          );
          final GoRouter routeur = await _monter(
            tester,
            depart,
            role,
            port: port,
          );
          expect(_clocheAvecPoint(), findsNothing);
          final Finder deuxNonLues = find.bySemanticsLabel(
            t.commun.entete.notificationsNonLues(nombre: 2),
          );
          expect(deuxNonLues, findsAtLeastNWidgets(1));

          await tester.tap(deuxNonLues.first);
          await stabiliser(tester);

          expect(lieu(routeur), Routes.notificationsPour(role));
          expect(find.byType(NotificationsPage), findsOneWidget);
          // Le port a marque tout lu une fois, la liste a ete relue.
          expect(port.marquagesGroupes, 1);
          expect(port.lectures, greaterThanOrEqualTo(2));
          // Plus de point : la cloche, active sur sa page, ne dit plus de
          // non-lus (le titre de la page dit aussi « Notifications » : on
          // lit la cloche elle-meme).
          expect(find.bySemanticsLabel(RegExp('non lue')), findsNothing);
          final ClocheNotifications cloche = tester.widget<ClocheNotifications>(
            find.byType(ClocheNotifications),
          );
          expect(cloche.nonLues, 0);
          expect(cloche.actif, isTrue);
          expect(port.rendues.every((NotificationTuteur n) => n.lue), isTrue);
        },
      );
    }
  });
}
