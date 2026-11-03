// SNT (03/11/2026) : la notification « seance_reportee » dit le report et la
// nouvelle date a venir, avec ou sans heure, en francais et en arabe ; elle
// est lue par l'adaptateur (evenement connu), jamais perdue.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  test('sans heure : la seance est reportee, nouvelle date a venir', () {
    final String titre = contenuNotificationPour(
      'seance_reportee',
      const <String, dynamic>{},
    ).titre;
    expect(titre, t.snt.notifications.seanceReportee);
    expect(titre, contains('reportée'));
    expect(titre, contains('Nouvelle date à venir'));
    expect(titre.toLowerCase(), isNot(contains('rattrap')));
    expect(titre.toLowerCase(), isNot(contains('rembours')));
  });

  test('avec l heure locale : la seance du jour dit est reportee', () {
    final String titre = contenuNotificationPour(
      'seance_reportee',
      const <String, dynamic>{'debut_local': '2030-01-09T18:00:00'},
    ).titre;
    expect(titre, isNot(t.snt.notifications.seanceReportee));
    expect(titre, contains('reportée'));
  });

  test('l adaptateur lit l evenement, jamais le repli', () {
    final List<NotificationTuteur> liste = notificationsDepuis(<dynamic>[
      <String, dynamic>{
        'id': 'n-1',
        'evenement': 'seance_reportee',
        'params': <String, dynamic>{'session_id': 's', 'groupe_id': 'g'},
        'destination': '/tuteur',
        'cree_le': '2030-01-09T18:30:00Z',
        'lu_le': null,
      },
    ], titrePour: contenuNotificationPour);
    expect(liste, hasLength(1));
    expect(liste.single.titre, isNot(t.notifications.evenements.inconnu));
  });

  test('en arabe : le report dit, sans le francais', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    final String titre = contenuNotificationPour(
      'seance_reportee',
      const <String, dynamic>{},
    ).titre;
    expect(titre, contains('أُجّلت'));
  });
}
