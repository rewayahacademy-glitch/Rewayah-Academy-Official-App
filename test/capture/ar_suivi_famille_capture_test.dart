// AR-SUIVI-FAMILLE : le suivi des demandes de la famille, en arabe (RTL).
// La liste et trois frises de demonstration : Yusuf en liste d'attente, Ines
// integree (intervalles entre etapes), Hana close parce que l'eleve a deja
// une place en classe. Prefixe des PNG : `ar_suivi_famille_`.
// Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/port_frise_demande.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/suivi_demandes_demo.dart';
import 'package:rewayah_academy/features/suivi_famille/suivi_famille_page.dart';

import 'outil_capture.dart';

typedef _Variante = ({
  String nom,
  double largeur,
  double hauteur,
  double echelle,
  Brightness clarte,
});

const List<_Variante> _variantes = <_Variante>[
  (
    nom: '390_x1_clair',
    largeur: 390,
    hauteur: 1100,
    echelle: 1,
    clarte: Brightness.light,
  ),
  (
    nom: '390_x1_sombre',
    largeur: 390,
    hauteur: 1100,
    echelle: 1,
    clarte: Brightness.dark,
  ),
  (
    nom: '320_x2_clair',
    largeur: 320,
    hauteur: 2600,
    echelle: 2,
    clarte: Brightness.light,
  ),
];

Future<void> _monter(WidgetTester tester, _Variante v, String adresse) async {
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: <RouteBase>[
      GoRoute(
        path: '/tuteur/demandes',
        builder: (BuildContext _, GoRouterState _) =>
            const SuiviDemandesEntree(),
      ),
      GoRoute(
        path: '/tuteur/demandes/:demandeId',
        builder: (BuildContext _, GoRouterState etat) =>
            FriseDemandePage(demandeId: etat.pathParameters['demandeId']!),
      ),
      GoRoute(
        path: '/tuteur/classes/catalogue',
        builder: (BuildContext _, GoRouterState _) => const SizedBox(),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
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
              theme: AppTheme.pour(InterfaceMode.standard, v.clarte),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (BuildContext c, Widget? app) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: TextScaler.linear(v.echelle)),
                child: app!,
              ),
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
  group('Capture : AR-SUIVI-FAMILLE', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final _Variante v in _variantes) {
      final Map<String, String> ecrans = <String, String>{
        'liste': '/tuteur/demandes',
        'attente': '/tuteur/demandes/demo-demande-yusuf',
        'integree': '/tuteur/demandes/demo-demande-ines',
        'deja_en_classe': '/tuteur/demandes/demo-demande-hana',
      };
      ecrans.forEach((String nom, String adresse) {
        testWidgets('ar_suivi_famille_${nom}_${v.nom}', (
          WidgetTester tester,
        ) async {
          LocaleSettings.setLocaleSync(AppLocale.ar);
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, Size(v.largeur, v.hauteur), 1);
          await _monter(tester, v, adresse);
          debugPrint(
            'PNG ${await capturer(tester, 'ar_suivi_famille_${nom}_${v.nom}')}',
          );
        });
      });
    }
  });
}
