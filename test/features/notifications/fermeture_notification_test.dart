// CALENDRIER-ET-PAUSES (13/11/2026) : les notifications de fermeture de
// l'academie (« fermeture_annoncee », « fermeture_levee »). Le contenu en
// francais et en arabe, jamais une date limite ni une duree, l'heure de La
// Mecque toujours dite ; l'adaptateur lit l'evenement ; la ligne s'affiche dans
// le centre de notifications et MENE A LA CLASSE, par le vrai routeur.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

import '../../router/support_routeur.dart';
import '../historique/support_historique.dart';

const String _classe = '7e2b0a84-1d4c-4f1e-9a53-2f6a9a0d1c11';

Map<String, dynamic> _annoncee({
  int nombre = 1,
  String portee = 'foyer',
  bool locale = true,
}) => <String, dynamic>{
  'groupe_id': _classe,
  'portee': portee,
  'du': '2027-05-16',
  'au': '2027-05-25',
  'nombre': nombre,
  'premiere_jour': '2027-05-18',
  'premiere_heure': '11:00',
  if (locale) 'debut_local': '2027-05-18T04:00:00',
};

class _Port implements PortNotifications {
  _Port(this.rendues);

  final List<NotificationTuteur> rendues;

  @override
  Future<List<NotificationTuteur>> liste() async => rendues;

  @override
  Future<NotificationTuteur?> detail(String id) async =>
      rendues.where((NotificationTuteur n) => n.id == id).firstOrNull;
}

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  test('les evenements sont connus du client ; la destination vers la classe '
      'est valide', () {
    expect(evenementsNotificationConnus, contains('fermeture_annoncee'));
    expect(evenementsNotificationConnus, contains('fermeture_levee'));
    expect(
      destinationNotificationAutorisee('/tuteur/classes/$_classe/planning'),
      isTrue,
    );
    expect(destinationNotificationAutorisee('/enseignant/classes'), isTrue);
    expect(destinationNotificationAutorisee('/eleve'), isTrue);
  });

  group('en francais', () {
    setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    test('annoncee, une seance : la periode, la seance a l heure de la '
        'personne ET a l heure de La Mecque', () {
      final String titre = contenuNotificationPour(
        'fermeture_annoncee',
        _annoncee(),
      ).titre;
      expect(titre, startsWith("L'académie est fermée du 16 mai 2027 au "));
      expect(titre, contains('25 mai 2027'));
      expect(titre, contains("n'aura pas lieu"));
      expect(titre, contains('11:00, heure de La Mecque'));
      // Rien pour un enfant : ni date limite, ni duree.
      expect(titre.toLowerCase(), isNot(contains('limite')));
      expect(titre.toLowerCase(), isNot(contains('durée')));
    });

    test('annoncee, sans heure locale : l heure de La Mecque seule', () {
      final String titre = contenuNotificationPour(
        'fermeture_annoncee',
        _annoncee(locale: false),
      ).titre;
      expect(titre, contains('18 mai 2027 à 11:00, heure de La Mecque'));
    });

    test('annoncee, plusieurs seances : le nombre et la premiere', () {
      final String titre = contenuNotificationPour(
        'fermeture_annoncee',
        _annoncee(nombre: 3),
      ).titre;
      expect(titre, contains('3'));
      expect(titre, contains('dont celle du'));
    });

    test('levee : la seance est retablie', () {
      final String titre = contenuNotificationPour(
        'fermeture_levee',
        <String, dynamic>{..._annoncee(), 'retablies': 1, 'abandonnees': 0},
      ).titre;
      expect(titre, startsWith("La fermeture de l'académie est retirée."));
      expect(titre, contains('est rétablie'));
    });

    test('levee avec abandon : la seance n aura pas lieu', () {
      final String titre = contenuNotificationPour(
        'fermeture_levee',
        <String, dynamic>{..._annoncee(), 'retablies': 0, 'abandonnees': 1},
      ).titre;
      expect(titre, contains("n'aura pas lieu"));
      expect(titre, isNot(contains('rétablie')));
    });

    test('levee mixte : les deux nombres', () {
      final String titre = contenuNotificationPour(
        'fermeture_levee',
        <String, dynamic>{..._annoncee(), 'retablies': 2, 'abandonnees': 1},
      ).titre;
      expect(titre, contains('2'));
      expect(titre, contains('1'));
      expect(titre, contains('Ouvrez la classe'));
    });

    test('des parametres illisibles : la phrase tient, sans rien inventer', () {
      final String titre = contenuNotificationPour(
        'fermeture_annoncee',
        <String, dynamic>{'du': 'demain'},
      ).titre;
      expect(titre, isNotEmpty);
      expect(titre, isNot(t.notifications.evenements.inconnu));
    });
  });

  test('en arabe : la fermeture dit sa periode et l heure de La Mecque, '
      'sans le francais', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    final String titre = contenuNotificationPour(
      'fermeture_annoncee',
      _annoncee(),
    ).titre;
    expect(titre, contains('الأكاديمية مغلقة'));
    expect(titre, contains('مكة المكرمة'));
    expect(RegExp('[A-Za-z]{4,}').hasMatch(titre), isFalse);
    final String levee = contenuNotificationPour(
      'fermeture_levee',
      <String, dynamic>{..._annoncee(), 'retablies': 1, 'abandonnees': 0},
    ).titre;
    expect(levee, contains('سُحب إغلاق الأكاديمية'));
  });

  test('l adaptateur lit l evenement et garde la destination vers la '
      'classe', () {
    final List<NotificationTuteur> liste = notificationsDepuis(<dynamic>[
      <String, dynamic>{
        'id': 'n-f1',
        'evenement': 'fermeture_annoncee',
        'params': _annoncee(),
        'destination': '/tuteur/classes/$_classe/planning',
        'cree_le': '2027-05-10T08:00:00Z',
        'lu_le': null,
      },
    ], titrePour: contenuNotificationPour);
    expect(liste, hasLength(1));
    expect(liste.single.titre, isNot(t.notifications.evenements.inconnu));
    expect(liste.single.destination, '/tuteur/classes/$_classe/planning');
  });

  testWidgets('le centre de notifications : la ligne s affiche et mene a la '
      'classe (vrai routeur)', (WidgetTester tester) async {
    final List<NotificationTuteur> rendues = notificationsDepuis(<dynamic>[
      <String, dynamic>{
        'id': 'n-f1',
        'evenement': 'fermeture_annoncee',
        'params': _annoncee(),
        'destination': '/tuteur/classes/$_classe/planning',
        'cree_le': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toUtc()
            .toIso8601String(),
        'lu_le': null,
      },
    ], titrePour: contenuNotificationPour);
    final GoRouter routeur = await monterHistorique(
      tester,
      taille: const Size(390, 844),
      autres: <Override>[
        portNotificationsProvider.overrideWithValue(_Port(rendues)),
      ],
    );
    await stabiliser(tester);
    routeur.go(Routes.tuteurNotifications);
    await stabiliser(tester);
    expect(lieu(routeur), Routes.tuteurNotifications);
    final Finder ligne = find.byKey(
      const ValueKey<String>('notification-n-f1'),
    );
    expect(ligne, findsOneWidget);
    expect(find.textContaining("L'académie est fermée du"), findsOneWidget);
    await tester.tap(ligne);
    await stabiliser(tester);
    expect(lieu(routeur), Routes.classeSousPage(_classe, 'planning'));
  });
}
