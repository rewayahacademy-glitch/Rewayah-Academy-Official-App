// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : la reponse de la direction a une
// demande de pause, dans la boite de notifications du tuteur ou de l'adulte.
// Une phrase du vocabulaire (fr, ar), jamais un code ; avec un prenom pour un
// enfant (le tuteur est le destinataire), sans prenom pour l'adulte ; l'evenement
// est connu du client et sa destination est deja valide.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  test('l evenement est connu du client ; ses destinations sont deja valides', () {
    expect(evenementsNotificationConnus, contains('pause_repondue'));
    expect(destinationNotificationAutorisee('/tuteur'), isTrue);
    expect(destinationNotificationAutorisee('/eleve'), isTrue);
  });

  group('en francais', () {
    setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    test('acceptee, pour un enfant : son prenom, le mois, la place gardee', () {
      final NotificationContenu c = contenuNotificationPour(
        'pause_repondue',
        <String, dynamic>{
          'decision': 'acceptee',
          'mois': '2027-02',
          'prenom': 'Mariam',
        },
      );
      expect(
        c.titre,
        "La pause d'un mois de Mariam est acceptée pour février 2027. "
        'Sa date limite recule d\'autant. Sa place est gardée.',
      );
    });

    test('acceptee, pour l adulte : a la deuxieme personne', () {
      final NotificationContenu c = contenuNotificationPour(
        'pause_repondue',
        <String, dynamic>{'decision': 'acceptee', 'mois': '2027-02'},
      );
      expect(
        c.titre,
        "Votre pause d'un mois est acceptée pour février 2027. "
        "Votre date limite recule d'autant. Votre place est gardée.",
      );
    });

    test('refusee : le motif est dans l application, jamais dans la notification', () {
      final NotificationContenu enfant = contenuNotificationPour(
        'pause_repondue',
        <String, dynamic>{
          'decision': 'refusee',
          'mois': '2027-03',
          'prenom': 'Mariam',
        },
      );
      expect(enfant.titre, contains('Mariam'));
      expect(enfant.titre, contains('mars 2027'));
      expect(enfant.titre, contains("n'est pas acceptée"));
      expect(enfant.titre, contains("Le motif est dans l'application"));
      final NotificationContenu adulte = contenuNotificationPour(
        'pause_repondue',
        <String, dynamic>{'decision': 'refusee', 'mois': '2027-03'},
      );
      expect(adulte.titre, startsWith('Votre pause'));
    });

    test('un mois illisible : la phrase tient, sans mois invente', () {
      final NotificationContenu c = contenuNotificationPour(
        'pause_repondue',
        <String, dynamic>{'decision': 'acceptee', 'mois': 'bientot'},
      );
      expect(c.titre, isNotEmpty);
      expect(c.titre, isNot(contains('bientot')));
      expect(c.titre, isNot(t.notifications.evenements.inconnu));
    });
  });

  group('en arabe', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));

    test('les quatre phrases existent, avec le mois en toutes lettres', () {
      for (final Map<String, dynamic> p in <Map<String, dynamic>>[
        <String, dynamic>{'decision': 'acceptee', 'mois': '2027-02', 'prenom': 'Mariam'},
        <String, dynamic>{'decision': 'acceptee', 'mois': '2027-02'},
        <String, dynamic>{'decision': 'refusee', 'mois': '2027-03', 'prenom': 'Mariam'},
        <String, dynamic>{'decision': 'refusee', 'mois': '2027-03'},
      ]) {
        final String titre = contenuNotificationPour('pause_repondue', p).titre;
        expect(titre, isNotEmpty);
        expect(titre, isNot(t.notifications.evenements.inconnu));
        expect(titre, isNot(contains('{')));
        expect(titre, matches(RegExp(r'[؀-ۿ]')));
        expect(titre, contains('2027'));
      }
    });
  });
}
