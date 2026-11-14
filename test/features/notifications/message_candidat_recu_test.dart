// MESSAGERIE-PUSH (14/11/2026) : la notification « message_candidat_recu » de
// la direction est lue par l'adaptateur (evenement connu, type message), dite
// sans nom ni texte, et ouvre le fil du candidat ; une destination hors forme
// est ecartee.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

const String _fil = '7c600000-0000-4000-8000-0000000000f9';

Map<String, dynamic> _ligne(String destination) => <String, dynamic>{
  'id': 'n-1',
  'evenement': 'message_candidat_recu',
  'params': <String, dynamic>{
    'portee': 'direction',
    'fil_id': _fil,
    'source_id': _fil,
  },
  'destination': destination,
  'cree_le': '2026-11-14T12:00:00Z',
  'lu_le': null,
};

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  test('evenement connu, phrase propre, jamais celle de repli', () async {
    expect(evenementsNotificationConnus, contains('message_candidat_recu'));
    for (final AppLocale langue in AppLocale.values) {
      await LocaleSettings.setLocale(langue);
      expect(
        contenuNotificationPour(
          'message_candidat_recu',
          const <String, dynamic>{'portee': 'direction'},
        ).titre,
        t.push1.evenements.messageCandidat,
      );
    }
  });

  test('ouvre le fil du candidat chez la direction', () {
    final List<NotificationTuteur> liste = notificationsDepuis(<dynamic>[
      _ligne('/admin/operations/communications/messages/$_fil'),
    ], titrePour: contenuNotificationPour);
    expect(
      liste.single.destination,
      '/admin/operations/communications/messages/$_fil',
    );
    expect(liste.single.titre, t.push1.evenements.messageCandidat);
  });

  test('une destination hors forme est ecartee', () {
    for (final String d in <String>[
      '/admin/operations/communications/messages/pas-un-fil',
      '/admin/operations/communications/messages/$_fil/autre',
      'https://exemple.invalid/admin/operations/communications/messages',
    ]) {
      expect(destinationNotificationAutorisee(d), isFalse, reason: d);
    }
    expect(
      destinationNotificationAutorisee(
        '/admin/operations/communications/messages',
      ),
      isTrue,
    );
  });
}
