// Captures de recette de la voie CPT-ENC (W05, detail, rapprochement), dans
// la VRAIE coquille du Comptable en demonstration
// (`/demo/comptable?ecran=...`, `CoquilleComptableDemo`) : 390x844 @3 et
// 1440x900 @1, clair et sombre, plus 320 texte x2 ; montants masques (par
// defaut) et une variante montants affiches.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Mode
// d'emploi : `test/capture/LISEZ-MOI.md`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/comptable/encaissements/encaissements_page.dart';
import 'package:rewayah_academy/features/comptable/encaissements/rapprochement/espace_rapprochement.dart';
import 'package:rewayah_academy/features/demo/comptable/encaissements_demo.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';

import '../../../capture/outil_capture.dart';

Future<void> _monter(
  WidgetTester tester,
  EcranDemoComptable ecran, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  bool montantsAffiches = false,
}) async {
  final GoRouter routeur = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext _, GoRouterState _) => CoquilleComptableDemo(
          ecran: ecran,
          montantsAffiches: montantsAffiches,
        ),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
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
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
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

void _telephone(WidgetTester tester) => fixerVueCapture(
  tester,
  const Size(390, 844),
  3,
  zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
);

void _bureau(WidgetTester tester) =>
    fixerVueCapture(tester, const Size(1440, 900), 1);

void _etroit(WidgetTester tester) => fixerVueCapture(
  tester,
  const Size(320, 900),
  2,
  zoneSure: const EdgeInsets.only(top: 20, bottom: 20),
);

Future<void> _png(WidgetTester tester, String nom) async {
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : voie CPT-ENC', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final String m = mode.name;

      testWidgets('ENC-1 encaissements 390 $m', (WidgetTester tester) async {
        _telephone(tester);
        await _monter(tester, EcranDemoComptable.encaissements, mode: mode);
        await _png(tester, 'enc1_encaissements_390x844@3_$m');
      });

      testWidgets('ENC-1 encaissements 1440 $m', (WidgetTester tester) async {
        _bureau(tester);
        await _monter(tester, EcranDemoComptable.encaissements, mode: mode);
        await _png(tester, 'enc1_encaissements_1440x900@1_$m');
        await tester.tap(
          find.byKey(
            EncaissementsPage.ligneKey(DonneesEncaissementsDemo.encConfirme),
          ),
        );
        await stabiliser(tester);
        await _png(tester, 'enc1_encaissements_panneau_1440x900@1_$m');
      });

      testWidgets('ENC-1 detail 390 $m', (WidgetTester tester) async {
        _telephone(tester);
        await _monter(
          tester,
          EcranDemoComptable.detailEncaissement,
          mode: mode,
        );
        await _png(tester, 'enc1_detail_390x844@3_$m');
      });

      testWidgets('ENC-1 detail 1440 $m', (WidgetTester tester) async {
        _bureau(tester);
        await _monter(
          tester,
          EcranDemoComptable.detailEncaissement,
          mode: mode,
        );
        await _png(tester, 'enc1_detail_1440x900@1_$m');
      });

      testWidgets('ENC-2 rapprochement 390 $m', (WidgetTester tester) async {
        _telephone(tester);
        await _monter(tester, EcranDemoComptable.rapprochement, mode: mode);
        await _png(tester, 'enc2_rapprochement_390x844@3_$m');
        await tester.tap(
          find.byKey(
            ReconciliationWorkspace.ligneKey(
              DonneesEncaissementsDemo.trxDoublon,
            ),
          ),
        );
        await stabiliser(tester);
        await _png(tester, 'enc2_rapprochement_feuille_doublon_390x844@3_$m');
      });

      testWidgets('ENC-2 rapprochement 1440 $m', (WidgetTester tester) async {
        _bureau(tester);
        await _monter(tester, EcranDemoComptable.rapprochement, mode: mode);
        await tester.tap(
          find.byKey(
            ReconciliationWorkspace.ligneKey(
              DonneesEncaissementsDemo.trxAVerifier,
            ),
          ),
        );
        await stabiliser(tester);
        await _png(tester, 'enc2_rapprochement_panneau_1440x900@1_$m');
        await tester.tap(
          find.byKey(
            ReconciliationWorkspace.vueKey(VueRapprochement.remboursements),
          ),
        );
        await stabiliser(tester);
        await _png(tester, 'enc2_remboursements_1440x900@1_$m');
      });
    }

    testWidgets('ENC-1 encaissements 1440 montants affiches', (
      WidgetTester tester,
    ) async {
      _bureau(tester);
      await _monter(
        tester,
        EcranDemoComptable.encaissements,
        montantsAffiches: true,
      );
      await tester.tap(
        find.byKey(
          EncaissementsPage.ligneKey(DonneesEncaissementsDemo.encConfirme),
        ),
      );
      await stabiliser(tester);
      await _png(
        tester,
        'enc1_encaissements_panneau_affiches_1440x900@1_light',
      );
    });

    testWidgets('ENC-2 rapprochement 390 remboursements affiches', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      await _monter(
        tester,
        EcranDemoComptable.rapprochement,
        montantsAffiches: true,
      );
      await tester.tap(
        find.byKey(
          ReconciliationWorkspace.vueKey(VueRapprochement.remboursements),
        ),
      );
      await stabiliser(tester);
      await _png(tester, 'enc2_remboursements_affiches_390x844@3_light');
    });

    for (final (String nom, EcranDemoComptable ecran) cas
        in <(String, EcranDemoComptable)>[
          ('enc1_encaissements', EcranDemoComptable.encaissements),
          ('enc1_detail', EcranDemoComptable.detailEncaissement),
          ('enc2_rapprochement', EcranDemoComptable.rapprochement),
        ]) {
      testWidgets('320 texte x2 ${cas.$1}', (WidgetTester tester) async {
        _etroit(tester);
        await _monter(tester, cas.$2, echelle: 2, montantsAffiches: true);
        await _png(tester, '${cas.$1}_320x900@2_texte200');
      });
    }
  });
}
