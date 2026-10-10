// Captures de recette de CPT-COM : le fil « Profil de paiement » OUVERT par
// « Relancer », dans la VRAIE coquille du Comptable en demonstration (route
// `/demo/comptable`, donnees fictives, message modele §27.3 prerempli).
// 390x844 @3 en clair et en sombre, 320x640 @2 texte x2 en clair et en
// sombre.
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
import 'package:rewayah_academy/features/comptable/beneficiaires/fil_profil_paiement_page.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/profil_paiement_page.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';

import 'outil_capture.dart';

Future<void> _ouvrirFil(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  double texte = 1,
}) async {
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoComptable(EcranDemoComptable.profilPaiement),
    routes: routesDemoComptable('staging'),
  );
  tester.platformDispatcher.textScaleFactorTestValue = texte;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  await tester.ensureVisible(find.byKey(ProfilPaiementPage.relancerKey));
  await tester.tap(find.byKey(ProfilPaiementPage.relancerKey));
  await stabiliser(tester);
  expect(find.byType(FilProfilPaiementPage), findsOneWidget);
}

void main() {
  group(
    'Capture : fil « Profil de paiement » ouvert par Relancer (CPT-COM)',
    skip: sautSansCapture,
    () {
      setUpAll(() async {
        final List<String> familles = await chargerPolicesDuDepot();
        debugPrint('FAMILLES chargees : ${familles.join(', ')}');
      });

      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('390x844 @3, fil ouvert, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(
            tester,
            const Size(390, 844),
            3,
            zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
          );
          await _ouvrirFil(tester, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'com_fil_profil_390x844@3_${mode.name}')}',
          );
        });

        testWidgets('320x640 @2 texte x2, fil ouvert, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 640), 2);
          await _ouvrirFil(tester, mode: mode, texte: 2);
          debugPrint(
            'PNG ${await capturer(tester, 'com_fil_profil_320x640@2_x2_${mode.name}')}',
          );
        });
      }
    },
  );
}
