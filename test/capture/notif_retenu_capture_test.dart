// NOTIF-RETENU (08/11/2026) : la notification « retenu pour un entretien » dans
// le centre de notifications, a 390 x 844 et 1440 x 900, en francais et en
// arabe. Le vrai ecran `NotificationsPage`, une source simulee qui rend une
// notification `retenu_entretien` non lue (titre lu par `contenuNotificationPour`,
// jamais ecrit a la main). Donnees de test seulement.
//
// Saute sans CAPTURE_DIR. Usage :
//   CAPTURE_DIR=docs/current/captures/E2E/notif-retenu flutter test --no-pub \
//     test/capture/notif_retenu_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

import 'outil_capture.dart';

class _Source implements PortNotifications {
  @override
  Future<List<NotificationTuteur>> liste() async => <NotificationTuteur>[
    NotificationTuteur(
      id: 'n-retenu',
      titre: contenuNotificationPour(
        'retenu_entretien',
        const <String, dynamic>{},
      ).titre,
      date: DateTime(2030, 1, 9, 18, 30),
      lue: false,
      niveau: NiveauAttention.aLire,
      evenement: 'retenu_entretien',
    ),
  ];

  @override
  Future<NotificationTuteur?> detail(String id) async => null;
}

void main() {
  group(
    'Capture NOTIF-RETENU : le centre de notifications',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      int rang = 0;
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        for (final (Size taille, double densite) in <(Size, double)>[
          (const Size(390, 844), 2),
          (const Size(1440, 900), 1),
        ]) {
          final String code = langue.languageCode;
          final int largeur = taille.width.toInt();
          testWidgets('$code $largeur : la notification retenu', (
            WidgetTester tester,
          ) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(tester, taille, densite);
            await tester.pumpWidget(
              hoteCapture(
                const NotificationsPage(),
                surcharges: <Override>[
                  portNotificationsProvider.overrideWithValue(_Source()),
                  horsLigneProvider.overrideWith(
                    (Ref ref) => Stream<bool>.value(false),
                  ),
                ],
              ),
            );
            await stabiliser(tester);
            expect(
              find.text(t.notifications.evenements.retenuEntretien),
              findsOneWidget,
            );
            rang++;
            debugPrint(
              'PNG ${await capturer(tester, '0${rang}_${code}_${largeur}_notification_retenu')}',
            );
          });
        }
      }
    },
  );
}
