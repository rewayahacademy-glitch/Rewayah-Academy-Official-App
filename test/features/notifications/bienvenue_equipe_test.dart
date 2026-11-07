// SALLE-3-ACCUEIL (07/11/2026) : la notification « bienvenue_equipe » dit
// l'accueil dans l'equipe, en francais et en arabe, sans nom de salle ; elle
// est lue par l'adaptateur (evenement connu, destination la Journee), jamais
// remplacee par la phrase de repli.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  test('le titre dit l\'accueil dans l\'equipe, jamais un nom de salle', () {
    final String titre = contenuNotificationPour(
      'bienvenue_equipe',
      const <String, dynamic>{},
    ).titre;
    expect(titre, t.notifications.evenements.bienvenueEquipe);
    expect(titre, contains('Bienvenue dans l\'équipe'));
    expect(titre, isNot(contains('Salle')));
    expect(titre, isNot(t.notifications.evenements.inconnu));
  });

  test('l\'adaptateur lit l\'evenement et sa destination, jamais le repli', () {
    final List<NotificationTuteur> liste = notificationsDepuis(<dynamic>[
      <String, dynamic>{
        'id': 'n-1',
        'evenement': 'bienvenue_equipe',
        'params': <String, dynamic>{},
        'destination': '/enseignant/journee',
        'cree_le': '2030-01-09T18:30:00Z',
        'lu_le': null,
      },
    ], titrePour: contenuNotificationPour);
    expect(liste, hasLength(1));
    expect(liste.single.titre, t.notifications.evenements.bienvenueEquipe);
  });

  test('contre-epreuve : un evenement inconnu garde la phrase de repli', () {
    final String titre = contenuNotificationPour(
      'evenement_qui_n_existe_pas',
      const <String, dynamic>{},
    ).titre;
    expect(titre, t.notifications.evenements.inconnu);
  });

  test('en arabe : l\'accueil dit, sans le francais', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    final String titre = contenuNotificationPour(
      'bienvenue_equipe',
      const <String, dynamic>{},
    ).titre;
    expect(titre, contains('مرحبًا بك في الفريق'));
    expect(titre, isNot(contains('Bienvenue')));
  });
}
