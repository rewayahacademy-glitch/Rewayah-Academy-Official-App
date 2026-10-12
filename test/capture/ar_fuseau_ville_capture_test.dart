// AR-FUSEAU-VILLE : le nom de la ville du fuseau en arabe (« بتوقيت باريس »)
// dans le suivi des demandes (la frise de la famille recevra le meme nom des
// que AR-SUIVI-FAMILLE sera fusionnee : son domaine n'est pas encore traduit
// sur cette base). 390 px, clair et sombre, RTL. Prefixe des PNG : `ar_fuseau_ville_`. Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/port_frise_demande.dart';
import 'package:rewayah_academy/core/offres/port_suivi_demandes.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/suivi_demandes_demo.dart';
import 'package:rewayah_academy/features/suivi_demandes/suivi_demandes_page.dart';
import 'package:rewayah_academy/features/suivi_famille/suivi_famille_page.dart';

import 'outil_capture.dart';

Future<void> _monter(
  WidgetTester tester,
  Brightness clarte,
  String adresse,
) async {
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: <RouteBase>[
      GoRoute(
        path: '/suivi-demandes',
        builder: (BuildContext _, GoRouterState _) => const SuiviDemandesPage(),
      ),
      GoRoute(
        path: '/tuteur/demandes/:demandeId',
        builder: (BuildContext _, GoRouterState etat) =>
            FriseDemandePage(demandeId: etat.pathParameters['demandeId']!),
      ),
      GoRoute(
        path: '/tuteur/demandes',
        builder: (BuildContext _, GoRouterState _) => const SizedBox(),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portSuiviDemandesProvider.overrideWithValue(
          SuiviDemandesDemo.quatreEtapes(),
        ),
        portFriseDemandesProvider.overrideWithValue(
          FriseDemandesDemo(SuiviDemandesDemo.frises()),
        ),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, clarte),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture : AR-FUSEAU-VILLE', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final (String suffixe, Brightness clarte) in <(String, Brightness)>[
      ('clair', Brightness.light),
      ('sombre', Brightness.dark),
    ]) {
      final Map<String, String> ecrans = <String, String>{
        'suivi_demandes': '/suivi-demandes',
      };
      ecrans.forEach((String nom, String adresse) {
        testWidgets('ar_fuseau_ville_${nom}_390_$suffixe', (
          WidgetTester tester,
        ) async {
          LocaleSettings.setLocaleSync(AppLocale.ar);
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, const Size(390, 1500), 1);
          await _monter(tester, clarte, adresse);
          debugPrint(
            'PNG ${await capturer(tester, 'ar_fuseau_ville_${nom}_390_$suffixe')}',
          );
        });
      });
    }
  });
}
