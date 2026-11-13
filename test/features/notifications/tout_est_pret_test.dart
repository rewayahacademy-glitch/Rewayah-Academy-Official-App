// SUIVI-ATTENTE (13/11/2026) : la notification « tout_est_pret » est lue par
// l'adaptateur (evenement connu, destination du tuteur ou de l'adulte), dite
// dans le registre de chacun, et nomme l'enfant au tuteur : un tuteur de deux
// enfants dans la meme classe recoit deux avis, chacun avec le prenom de son
// enfant. Jamais un identifiant ; jamais une phrase de repli.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

Map<String, dynamic> _ligne(
  String id, {
  required String portee,
  String? prenom,
  String destination = '/tuteur/demandes',
}) => <String, dynamic>{
  'id': id,
  'evenement': 'tout_est_pret',
  'params': <String, dynamic>{
    'portee': portee,
    'groupe_id': 'g-1',
    'eleve_id': 'e-$id',
    'classe': 'Classe Al-Fatiha',
    'prenom_secret': 'ne pas lire',
    'eleve_prenom': ?prenom,
    'eleves': <String>[?prenom],
  },
  'destination': destination,
  'cree_le': '2030-01-09T18:30:00Z',
  'lu_le': null,
};

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  test('l\'evenement est connu : jamais la phrase de repli', () {
    expect(evenementsNotificationConnus, contains('tout_est_pret'));
    for (final String portee in <String>['soi', 'foyer', '']) {
      expect(
        contenuNotificationPour('tout_est_pret', <String, dynamic>{
          'portee': portee,
        }).titre,
        isNot(t.notifications.evenements.inconnu),
      );
    }
  });

  test('le tuteur lit le prenom de l\'enfant, l\'adulte sa propre phrase', () {
    expect(
      contenuNotificationPour('tout_est_pret', const <String, dynamic>{
        'portee': 'foyer',
        'eleve_prenom': 'Yusuf',
      }).titre,
      t.notifications.evenements.toutEstPretPour(prenom: 'Yusuf'),
    );
    expect(
      contenuNotificationPour('tout_est_pret', const <String, dynamic>{
        'portee': 'soi',
      }).titre,
      t.notifications.evenements.toutEstPretSoi,
    );
    // Sans prenom (ancienne ligne) : la phrase generale, sans nom invente.
    expect(
      contenuNotificationPour('tout_est_pret', const <String, dynamic>{
        'portee': 'foyer',
      }).titre,
      t.notifications.evenements.toutEstPret,
    );
  });

  test('deux enfants, deux avis : chacun nomme son enfant', () {
    final List<NotificationTuteur> liste = notificationsDepuis(<dynamic>[
      _ligne('n-1', portee: 'foyer', prenom: 'Yusuf'),
      _ligne('n-2', portee: 'foyer', prenom: 'Maryam'),
    ], titrePour: contenuNotificationPour);
    expect(liste, hasLength(2));
    final List<String> titres = <String>[for (final n in liste) n.titre];
    expect(titres.where((String x) => x.contains('Yusuf')), hasLength(1));
    expect(titres.where((String x) => x.contains('Maryam')), hasLength(1));
    // L'adaptateur ne garde aucun identifiant ni parametre hors liste.
    for (final String titre in titres) {
      expect(titre, isNot(contains('e-n-')));
      expect(titre, isNot(contains('ne pas lire')));
    }
  });

  test('l\'adulte : destination de son accueil, phrase a lui', () {
    final List<NotificationTuteur> liste = notificationsDepuis(<dynamic>[
      _ligne('n-3', portee: 'soi', destination: '/eleve'),
    ], titrePour: contenuNotificationPour);
    expect(liste, hasLength(1));
    expect(liste.single.titre, t.notifications.evenements.toutEstPretSoi);
    expect(liste.single.destination, '/eleve');
  });

  test('en arabe, le prenom est isole', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    final String titre = contenuNotificationPour(
      'tout_est_pret',
      const <String, dynamic>{'portee': 'foyer', 'eleve_prenom': 'Yusuf'},
    ).titre;
    expect(titre, contains('\u2068Yusuf\u2069'));
  });
}
