// Captures de recette de CPT-BEN-1 et CPT-BEN-2 (W07 Beneficiaires, profil
// de paiement masque, « Recevoir mes paiements ») : les trois ecrans de la
// voie dans la VRAIE coquille du Comptable en demonstration
// (`CoquilleComptableDemo`, donnees fictives), 390x844 @3 et 1440x900 @1 en
// clair et en sombre, 320x640 @2 texte x2 en clair, plus les etats que la
// demonstration fixe ne montre pas.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Mode
// d'emploi : `test/capture/LISEZ-MOI.md`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_mes_moyens_paiement.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/beneficiaires_page.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/profil_paiement_page.dart';
import 'package:rewayah_academy/features/demo/comptable/beneficiaires_demo.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';
import 'package:rewayah_academy/features/paiements_recus/recevoir_paiements_page.dart';

import 'outil_capture.dart';

Future<void> _monter(
  WidgetTester tester,
  Widget Function() ecran, {
  ThemeMode mode = ThemeMode.light,
  double texte = 1,
}) async {
  final GoRouter routeur = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (BuildContext _, GoRouterState _) => ecran()),
    ],
  );
  tester.platformDispatcher.textScaleFactorTestValue = texte;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    TranslationProvider(
      child: RepaintBoundary(
        key: cadreCapture,
        child: Builder(
          builder: (BuildContext context) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
            themeMode: mode,
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: routeur,
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

Widget _page(
  Widget page, {
  bool affiches = false,
  List<Override> plus = const <Override>[],
}) => ProviderScope(
  overrides: surchargesCoquilleComptableDemo(montantsAffiches: affiches),
  // Un port remplace dans un conteneur enfant : jamais deux surcharges du
  // meme fournisseur dans un seul conteneur.
  child: plus.isEmpty ? page : ProviderScope(overrides: plus, child: page),
);

void main() {
  group(
    'Capture : beneficiaires et paiements recus (CPT-BEN)',
    skip: sautSansCapture,
    () {
      setUpAll(() async {
        final List<String> familles = await chargerPolicesDuDepot();
        debugPrint('FAMILLES chargees : ${familles.join(', ')}');
      });

      final List<(String, EcranDemoComptable)> ecrans =
          <(String, EcranDemoComptable)>[
            ('liste', EcranDemoComptable.beneficiaires),
            ('profil', EcranDemoComptable.profilPaiement),
            ('recevoir', EcranDemoComptable.recevoirPaiements),
          ];

      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final (String nom, EcranDemoComptable e) in ecrans) {
          testWidgets('390x844 @3, $nom, ${mode.name}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(
              tester,
              const Size(390, 844),
              3,
              zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
            );
            await _monter(
              tester,
              () => CoquilleComptableDemo(ecran: e),
              mode: mode,
            );
            debugPrint(
              'PNG ${await capturer(tester, 'ben_${nom}_390x844@3_${mode.name}')}',
            );
          });
          testWidgets('1440x900 @1, $nom, ${mode.name}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, const Size(1440, 900), 1);
            await _monter(
              tester,
              () => CoquilleComptableDemo(ecran: e),
              mode: mode,
            );
            debugPrint(
              'PNG ${await capturer(tester, 'ben_${nom}_1440x900@1_${mode.name}')}',
            );
          });
        }
      }

      for (final (String nom, EcranDemoComptable e) in ecrans) {
        testWidgets('320x640 @2 texte x2, $nom', (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(320, 640), 2);
          await _monter(
            tester,
            () => CoquilleComptableDemo(ecran: e),
            texte: 2,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'ben_${nom}_320x640@2_texte2_light')}',
          );
        });
      }

      // Les etats que la demonstration fixe ne montre pas.
      final List<(String, Widget Function())> variantes =
          <(String, Widget Function())>[
            (
              'liste_infos_manquantes',
              () => _page(const BeneficiairesPage(filtre: 'infos')),
            ),
            (
              'profil_sans_methode',
              () => _page(
                const ProfilPaiementPage(
                  beneficiaireId: ProfilsBeneficiairesDemo.sansMethode,
                ),
              ),
            ),
            (
              'profil_suspendu',
              () => _page(
                const ProfilPaiementPage(
                  beneficiaireId: ProfilsBeneficiairesDemo.suspendu,
                ),
              ),
            ),
            (
              'profil_externe_invite',
              () => _page(
                const ProfilPaiementPage(
                  beneficiaireId: ProfilsBeneficiairesDemo.externe,
                ),
              ),
            ),
            (
              'recevoir_aucun_moyen',
              () => _page(
                const RecevoirPaiementsPage(),
                plus: <Override>[
                  portMesMoyensPaiementProvider.overrideWithValue(
                    MesMoyensPaiementDemo(depart: MesMoyensPaiementDemo.aucun),
                  ),
                ],
              ),
            ),
          ];
      for (final (String nom, Widget Function() w) in variantes) {
        testWidgets('390x844 @3, $nom', (WidgetTester tester) async {
          fixerVueCapture(
            tester,
            const Size(390, 844),
            3,
            zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
          );
          await _monter(tester, w);
          debugPrint(
            'PNG ${await capturer(tester, 'ben_${nom}_390x844@3_light')}',
          );
        });
      }
    },
  );
}
