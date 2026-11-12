// NOTIF-DEFAUT (08/11/2026) : Preferences > Notifications ouvre les Reglages
// (avant : une ligne morte), et la fenetre « Recevoir les notifications ? »
// de la premiere connexion (navigateur qui exige un geste). 390 x 844, FR et AR.
//
// Saute sans CAPTURE_DIR. Usage : CAPTURE_DIR=docs/current/captures/E2E/notif-defaut \
//   flutter test --no-pub test/capture/notif_defaut_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/push/bandeau_invitation_push.dart';
import 'package:rewayah_academy/core/push/invitation_push.dart';
import 'package:rewayah_academy/core/push/port_push.dart';
import 'package:rewayah_academy/core/push/reglages_push.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';

import 'outil_capture.dart';

class _Navigateur implements NavigateurPush {
  _Navigateur(this._etat, {this.geste = false});

  final bool geste;

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
  Future<bool> besoinGeste() async => geste;

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

void main() {
  group('Capture NOTIF-DEFAUT', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    int rang = 0;
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      final String code = langue.languageCode;
      testWidgets('$code : la fenetre de premiere connexion', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        fixerVueCapture(tester, const Size(390, 844), 2);
        await tester.pumpWidget(
          hoteCapture(
            const Column(
              children: <Widget>[
                BandeauInvitationPush(),
                Expanded(child: SizedBox.shrink()),
              ],
            ),
            surcharges: <Override>[
              navigateurPushProvider.overrideWithValue(
                _Navigateur(EtatAppareilPush.inactif, geste: true),
              ),
              portPushProvider.overrideWithValue(_Serveur(inscrit: false)),
              horsLigneProvider.overrideWith(
                (Ref ref) => Stream<bool>.value(false),
              ),
            ],
          ),
        );
        final ProviderContainer c = ProviderScope.containerOf(
          tester.element(find.byType(BandeauInvitationPush)),
        );
        await tester.runAsync(c.read(invitationPushProvider.notifier).verifier);
        await stabiliser(tester);
        expect(find.byKey(BandeauInvitationPush.cleActiver), findsOneWidget);
        rang++;
        debugPrint(
          'PNG ${await capturer(tester, '0${rang}_${code}_390_fenetre_premiere_connexion')}',
        );
      });
    }
  });
}
