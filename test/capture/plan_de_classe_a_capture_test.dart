// Captures de recette PLAN-DE-CLASSE A (lot 5, 13/11/2026), sur le vrai routeur
// en demonstration admin : la fiche d'une classe (etape et menu), Diagnostics
// (qui n'a pas d'etape), Programmes (un brouillon dans l'impasse), a 390 et
// 1440, clair et sombre, en francais et en arabe.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Donnees :
// fixtures synthetiques de la demonstration uniquement.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_diagnostics.dart';
import 'package:rewayah_academy/core/admin/service_plan_classe.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../features/admin_plan_de_classe/fauxs.dart';
import '../support/demo/mode_demonstration.dart';
import '../support/demo/repere_demonstration.dart';
import 'outil_capture.dart';

typedef _Ecran = ({String code, String route, bool brouillon});

final List<_Ecran> _ecrans = <_Ecran>[
  (
    code: 'fiche_classe',
    route: Routes.adminOperationsGroupePour('demo-classe-1'),
    brouillon: false,
  ),
  (
    code: 'diagnostics',
    route: Routes.adminPedagogieDiagnostics,
    brouillon: false,
  ),
  (code: 'programmes', route: Routes.adminPedagogieProgrammes, brouillon: true),
];

const List<(String, Size, double)> _formats = <(String, Size, double)>[
  ('390', Size(390, 1500), 2),
  ('1440', Size(1440, 1100), 1),
];

Future<void> _monter(WidgetTester tester, ThemeMode mode, _Ecran ecran) async {
  late GoRouter routeur;
  final FauxPlanClasse plan = FauxPlanClasse(
    etat: ecran.brouillon
        ? const EtatPublication(
            raison: RaisonBrouillon.incomplet,
            detail: 'Lecture',
          )
        : const EtatPublication(raison: RaisonBrouillon.publiable),
  );
  final FauxProgrammePublie programme = ecran.brouillon
      ? FauxProgrammePublie(
          versionsListe: <VersionProgramme>[
            FauxProgrammePublie.version(
              'v1',
              StatutVersionProgramme.brouillon,
              1,
              niveaux: 1,
            ),
          ],
        )
      : FauxProgrammePublie();
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(
          environnement: 'staging',
          servicesFournis: <Object>[
            servicePlanClasseProvider,
            serviceProgrammeProvider,
            serviceDiagnosticsProvider,
          ],
        ),
        servicePlanClasseProvider.overrideWithValue(plan),
        serviceProgrammeProvider.overrideWithValue(programme),
        serviceDiagnosticsProvider.overrideWithValue(FauxDiagnostics()),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
                builder: (BuildContext context, Widget? child) =>
                    RepereDemonstration(child: child),
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(ecran.route);
  await stabiliser(tester);
}

void main() {
  group('Capture : PLAN-DE-CLASSE A', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final _Ecran ecran in _ecrans) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          for (final (String, Size, double) f in _formats) {
            final String nom =
                'plan_classe_a_${ecran.code}_${langue.languageCode}_${f.$1}_${mode.name}';
            testWidgets(nom, (WidgetTester tester) async {
              await tester.runAsync(() => LocaleSettings.setLocale(langue));
              addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
              fixerVueCapture(tester, f.$2, f.$3);
              await _monter(tester, mode, ecran);
              debugPrint('PNG ${await capturer(tester, nom)}');
            });
          }
        }
      }
    }
  });
}
