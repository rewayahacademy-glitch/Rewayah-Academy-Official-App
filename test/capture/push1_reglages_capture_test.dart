// PUSH-1 (07/11/2026) : la page Notifications et ses Reglages des
// notifications sur l'appareil, a 390 x 844 et 1440 x 900, en francais et en
// arabe. Le vrai ecran `NotificationsPage` (liste vide : le cas du directeur
// le 07/11, aucune notification), le lien « Notifications sur cet appareil »
// touche, la vraie feuille ouverte (`AppBottomSheet.ouvrir`), sur un
// navigateur et un serveur simules : la capture montre ce qu'une personne
// voit avant d'avoir accorde quoi que ce soit.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Usage : CAPTURE_DIR=docs/current/captures/E2E/push-1 flutter test --no-pub \
//   test/capture/push1_reglages_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/push/port_push.dart';
import 'package:rewayah_academy/core/push/reglages_push.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';
import 'package:rewayah_academy/features/notifications/reglages_push.dart';

import 'outil_capture.dart';

class _SourceVide implements PortNotifications {
  @override
  Future<List<NotificationTuteur>> liste() async => <NotificationTuteur>[];

  @override
  Future<NotificationTuteur?> detail(String id) async => null;
}

class _Navigateur implements NavigateurPush {
  _Navigateur(this._etat);

  final EtatAppareilPush _etat;

  @override
  Future<EtatAppareilPush> etat() async => _etat;

  @override
  Future<String?> adresse() async =>
      _etat == EtatAppareilPush.actif ? 'https://push.test/moi' : null;

  @override
  Future<AbonnementNavigateur> activer(String clePublique) async =>
      throw const ActivationRefusee(RefusActivation.echec);

  @override
  Future<String?> desactiver() async => null;

  @override
  Future<bool> besoinGeste() async => false;

  @override
  String get appareil => 'Android';
}

class _Serveur implements PortPush {
  _Serveur({required this.inscrit});

  final bool inscrit;

  @override
  Future<ReglagesPushServeur> reglages({String? adresse}) async =>
      ReglagesPushServeur(
        autorise: true,
        cetAppareil: inscrit,
        appareils: inscrit ? 1 : 0,
        categories: <CategoriePush, bool>{
          for (final CategoriePush c in CategoriePush.values)
            c: c != CategoriePush.paiements || !inscrit,
        },
      );

  @override
  Future<String> clePublique() async => 'CLE';

  @override
  Future<void> inscrire(
    AbonnementNavigateur abonnement, {
    String? appareil,
  }) async {}

  @override
  Future<void> desinscrire(String adresse) async {}

  @override
  Future<void> reglerCategorie(
    CategoriePush categorie, {
    required bool actif,
  }) async {}
}

List<Override> _surcharges(EtatAppareilPush appareil) => <Override>[
  portNotificationsProvider.overrideWithValue(_SourceVide()),
  navigateurPushProvider.overrideWithValue(_Navigateur(appareil)),
  portPushProvider.overrideWithValue(
    _Serveur(inscrit: appareil == EtatAppareilPush.actif),
  ),
  horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(false)),
];

void main() {
  group(
    'Capture PUSH-1 : Reglages des notifications sur l\'appareil',
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
          testWidgets('$code $largeur : la page, puis la feuille', (
            WidgetTester tester,
          ) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(tester, taille, densite);
            await tester.pumpWidget(
              hoteCapture(
                const NotificationsPage(),
                surcharges: _surcharges(EtatAppareilPush.inactif),
              ),
            );
            await stabiliser(tester);
            expect(
              find.byKey(NotificationsPage.cleReglagesPush),
              findsOneWidget,
            );
            rang++;
            debugPrint(
              'PNG ${await capturer(tester, '${rang.toString().padLeft(2, '0')}_${code}_${largeur}_page_notifications')}',
            );
            await tester.tap(find.byKey(NotificationsPage.cleReglagesPush));
            await stabiliser(tester);
            expect(find.byKey(ReglagesPushVue.cleActiver), findsOneWidget);
            rang++;
            debugPrint(
              'PNG ${await capturer(tester, '${rang.toString().padLeft(2, '0')}_${code}_${largeur}_reglages_appareil_inactif')}',
            );
          });
        }
      }

      testWidgets('fr 390 : appareil actif, Paiements coupes', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 844), 2);
        await tester.pumpWidget(
          hoteCapture(
            const NotificationsPage(),
            surcharges: _surcharges(EtatAppareilPush.actif),
          ),
        );
        await stabiliser(tester);
        await tester.tap(find.byKey(NotificationsPage.cleReglagesPush));
        await stabiliser(tester);
        expect(find.byKey(ReglagesPushVue.cleDesactiver), findsOneWidget);
        debugPrint(
          'PNG ${await capturer(tester, '09_fr_390_reglages_appareil_actif')}',
        );
      });
    },
  );
}
