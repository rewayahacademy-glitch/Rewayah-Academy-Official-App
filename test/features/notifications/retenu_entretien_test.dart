// NOTIF-RETENU (08/11/2026) : la notification « retenu_entretien » dit que la
// personne est retenue pour un entretien, en francais et en arabe, sans nom
// de salle ; elle est lue par l'adaptateur (evenement connu, destination
// /attente/entretien), jamais remplacee par la phrase de repli.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  test('le titre dit « Vous êtes retenu pour un entretien »', () {
    final String titre = contenuNotificationPour(
      'retenu_entretien',
      const <String, dynamic>{},
    ).titre;
    expect(titre, t.notifications.evenements.retenuEntretien);
    expect(titre, contains('retenu pour un entretien'));
    expect(titre, contains('Faisons connaissance'));
    expect(titre, isNot(contains('Salle')));
    expect(titre, isNot(t.notifications.evenements.inconnu));
  });

  test('l\'adaptateur lit l\'evenement et sa destination, jamais le repli', () {
    final List<NotificationTuteur> liste = notificationsDepuis(<dynamic>[
      <String, dynamic>{
        'id': 'n-1',
        'evenement': 'retenu_entretien',
        'params': <String, dynamic>{},
        'destination': '/attente/entretien',
        'cree_le': '2030-01-09T18:30:00Z',
        'lu_le': null,
      },
    ], titrePour: contenuNotificationPour);
    expect(liste, hasLength(1));
    expect(liste.single.titre, t.notifications.evenements.retenuEntretien);
  });

  test('en arabe : la phrase est dite, sans le francais', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    final String titre = contenuNotificationPour(
      'retenu_entretien',
      const <String, dynamic>{},
    ).titre;
    expect(titre, contains('اختير طلبك لمقابلة'));
    expect(titre, isNot(contains('candidature')));
  });
}
