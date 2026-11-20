// PX-OAUTH 2e : captures R3 de la liste des connexions a Praxis (360 et 1440,
// francais et arabe, clair et sombre ; plus la feuille de revocation).
// Sautees sans CAPTURE_DIR :
//   CAPTURE_DIR=docs/current/captures/E2E flutter test \
//     test/features/admin_acces_agents/connexions_praxis_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/agent/service_autorisation_praxis.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_acces_agents/connexions_praxis.dart';

import '../../capture/outil_capture.dart';
import '../../support/faux_service_autorisation_praxis.dart';
import '../../support/harnais.dart';

FauxServiceAutorisationPraxis _faux() => FauxServiceAutorisationPraxis(
  connexions: <ConnexionPraxis>[
    connexionPraxisFictive(derniereUtilisation: DateTime(2026, 11, 18, 18)),
    connexionPraxisFictive(
      id: 'cx2',
      client: 'Claude',
      etat: EtatConnexionPraxis.revoquee,
    ),
    connexionPraxisFictive(
      id: 'cx3',
      client: 'Claude',
      etat: EtatConnexionPraxis.expiree,
    ),
  ],
);

Future<void> _monter(
  WidgetTester tester, {
  required Size taille,
  required AppLocale langue,
  required Brightness lum,
}) async {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: '/p',
      themeMode: lum == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      direction: langue == AppLocale.ar ? TextDirection.rtl : null,
      routes: <RouteBase>[
        GoRoute(
          path: '/p',
          builder: (BuildContext _, GoRouterState _) => const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ConnexionsPraxis(),
            ),
          ),
        ),
      ],
      surcharges: <Override>[
        serviceAutorisationPraxisProvider.overrideWithValue(_faux()),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('captures PX-OAUTH 2e', () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });
    setUp(masquerRubanDebug);
    for (final Size taille in const <Size>[Size(360, 900), Size(1440, 700)]) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        for (final Brightness lum in <Brightness>[
          Brightness.light,
          Brightness.dark,
        ]) {
          final String nom =
              'connexions-${taille.width.toInt()}-${langue.languageCode}'
              '-${lum == Brightness.dark ? 'sombre' : 'clair'}';
          testWidgets(nom, (WidgetTester tester) async {
            await _monter(tester, taille: taille, langue: langue, lum: lum);
            await capturerVue(tester, 'PX-OAUTH-2E/$nom');
          });
        }
      }
    }

    testWidgets('connexions-revoquer-360-fr-clair', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(360, 900),
        langue: AppLocale.fr,
        lum: Brightness.light,
      );
      await tester.tap(find.text(t.admin.praxis.revoquer).first);
      await tester.pumpAndSettle();
      await capturerVue(tester, 'PX-OAUTH-2E/connexions-revoquer-360-fr-clair');
    });
  }, skip: sautSansCapture);
}
