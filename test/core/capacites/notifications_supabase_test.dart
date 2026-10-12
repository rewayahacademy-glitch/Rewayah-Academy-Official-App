import 'package:flutter_test/flutter_test.dart';

import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';

void main() {
  group('notificationDepuis', () {
    test('maps the event and unread receipt without exposing internal IDs', () {
      Map<String, dynamic>? resolvedParams;
      final NotificationTuteur notification = notificationDepuis(
        _row(
          evenement: 'classe_validee',
          params: <String, dynamic>{
            'groupe_id': 'private-group-id',
            'etat': 'classe_validee',
            'debut_local': '2026-10-12T18:00:00',
            'motif': '  Votre classe est validée.  ',
          },
        ),
        titrePour: (String evenement, Map<String, dynamic> params) {
          resolvedParams = params;
          return NotificationContenu(
            titre: 'Classe validée',
            texte: params['motif'] as String?,
          );
        },
      );

      expect(notification.type, TypeNotification.changementPlanning);
      expect(notification.lue, isFalse);
      expect(notification.niveau, NiveauAttention.aLire);
      expect(notification.texte, 'Votre classe est validée.');
      expect(notification.destination, '/tuteur/demandes');
      expect(resolvedParams, <String, dynamic>{
        'etat': 'classe_validee',
        'debut_local': '2026-10-12T18:00:00',
        'motif': 'Votre classe est validée.',
      });
      expect(resolvedParams!.containsKey('groupe_id'), isFalse);
    });

    test(
      'maps read replacement notices to information without losing type',
      () {
        final NotificationTuteur notification = notificationDepuis(
          _row(
            evenement: 'remplacement_propose',
            destination: '/enseignant/journee/remplacements',
            luLe: '2026-10-10T12:00:00Z',
          ),
          titrePour: (String _, Map<String, dynamic> _) =>
              const NotificationContenu(titre: 'Remplacement proposé'),
        );

        expect(notification.type, TypeNotification.remplacement);
        expect(notification.lue, isTrue);
        expect(notification.niveau, NiveauAttention.information);
        expect(notification.destination, '/enseignant/journee/remplacements');
      },
    );

    test('maps presentation requests and skips unknown events per row', () {
      final List<NotificationTuteur> notifications = notificationsDepuis(
        <dynamic>[
          _row(evenement: 'evenement_futur'),
          _row(
            evenement: 'demande_presentation',
            params: <String, dynamic>{'demande_id': 'private-request-id'},
          ),
        ],
        titrePour: (String evenement, Map<String, dynamic> _) =>
            NotificationContenu(
              titre: evenement == 'demande_presentation'
                  ? 'Demande de présentation'
                  : 'Inattendu',
            ),
      );

      expect(notifications, hasLength(1));
      expect(notifications.single.titre, 'Demande de présentation');
      expect(notifications.single.destination, '/tuteur/demandes');
    });

    test('rejects malformed read timestamps instead of marking them read', () {
      expect(
        () => notificationDepuis(
          _row(luLe: 'pas-une-date'),
          titrePour: (String _, Map<String, dynamic> _) =>
              const NotificationContenu(titre: 'Demande reçue'),
        ),
        throwsFormatException,
      );
    });

    test('drops destinations outside the table allowlist', () {
      final NotificationTuteur notification = notificationDepuis(
        _row(destination: 'https://example.invalid'),
        titrePour: (String _, Map<String, dynamic> _) =>
            const NotificationContenu(titre: 'Demande reçue'),
      );

      expect(notification.destination, isNull);
    });
  });
}

Map<String, dynamic> _row({
  String evenement = 'demande_recue',
  Map<String, dynamic> params = const <String, dynamic>{},
  String? destination = '/tuteur/demandes',
  String? luLe,
}) => <String, dynamic>{
  'id': 'b0900000-0000-0000-0000-000000000001',
  'evenement': evenement,
  'params': params,
  'destination': destination,
  'cree_le': '2026-10-10T12:00:00+03:00',
  'lu_le': luLe,
};
