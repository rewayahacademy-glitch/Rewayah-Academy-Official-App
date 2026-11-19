// PX-OAUTH 2d : captures R3 de la page de consentement (360 et 1440, francais
// et arabe, clair et sombre ; plus les etats « termine » et « expiree »).
// Sautees sans CAPTURE_DIR :
//   CAPTURE_DIR=docs/current/captures/E2E flutter test \
//     test/features/admin_acces_agents/autoriser_praxis_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/agent/aller_adresse.dart';
import 'package:rewayah_academy/core/agent/service_autorisation_praxis.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_acces_agents/autoriser_praxis_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/faux_service_autorisation_praxis.dart';
import '../../support/harnais.dart';

const String _id = '5a130000-0000-4000-8000-000000000001';

Future<void> _monter(
  WidgetTester tester,
  FauxServiceAutorisationPraxis faux, {
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
          builder: (BuildContext _, GoRouterState _) =>
              const AutoriserPraxisPage(demande: _id),
        ),
      ],
      surcharges: <Override>[
        serviceAutorisationPraxisProvider.overrideWithValue(faux),
        allerAdresseProvider.overrideWithValue((String _) {}),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('captures PX-OAUTH 2d', () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });
    setUp(masquerRubanDebug);
    for (final Size taille in const <Size>[Size(360, 800), Size(1440, 900)]) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        for (final Brightness lum in <Brightness>[
          Brightness.light,
          Brightness.dark,
        ]) {
          final String nom =
              'autoriser-${taille.width.toInt()}-${langue.languageCode}'
              '-${lum == Brightness.dark ? 'sombre' : 'clair'}';
          testWidgets(nom, (WidgetTester tester) async {
            await _monter(
              tester,
              FauxServiceAutorisationPraxis(),
              taille: taille,
              langue: langue,
              lum: lum,
            );
            await capturerVue(tester, 'PX-OAUTH-2D/$nom');
          });
        }
      }
    }

    testWidgets('autoriser-termine-360-fr-clair', (WidgetTester tester) async {
      await _monter(
        tester,
        FauxServiceAutorisationPraxis(),
        taille: const Size(360, 800),
        langue: AppLocale.fr,
        lum: Brightness.light,
      );
      await tester.tap(find.byKey(ClesAutoriserPraxis.autoriser));
      await tester.pumpAndSettle();
      await capturerVue(tester, 'PX-OAUTH-2D/autoriser-termine-360-fr-clair');
    });

    testWidgets('autoriser-expiree-1440-fr-clair', (WidgetTester tester) async {
      await _monter(
        tester,
        FauxServiceAutorisationPraxis(
          demande: const DemandeAutorisationPraxis(
            etat: EtatDemandePraxis.expiree,
            client: 'Claude',
            hote: 'claude.ai',
          ),
        ),
        taille: const Size(1440, 900),
        langue: AppLocale.fr,
        lum: Brightness.light,
      );
      await capturerVue(tester, 'PX-OAUTH-2D/autoriser-expiree-1440-fr-clair');
    });
  }, skip: sautSansCapture);
}
