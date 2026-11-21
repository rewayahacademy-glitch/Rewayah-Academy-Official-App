// OPERATIONS-PORTRAIT (directeur, 21/11/2026) : captures R3 du lot.
// L'Espace de traitement au telephone en portrait, son selecteur de pages
// ouvert (toutes les pages d'Operations, dont « Les chiffres de
// l'academie ») ; l'Accueil et son lien vers les chiffres ; en francais et en
// arabe. Sautees sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';

import '../support/demo/mode_demonstration.dart';
import 'outil_capture.dart';

Future<GoRouter> _monter(WidgetTester tester, String adresse) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesDemoAdmin(environnement: 'staging'),
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(adresse);
  await stabiliser(tester);
  await stabiliser(tester);
  return routeur;
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('OPERATIONS-PORTRAIT', skip: sautSansCapture, () {
    for (final (String langue, AppLocale locale) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      testWidgets('traitement 390 $langue', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 844), 1);
        await _monter(tester, Routes.adminOperationsTraitement);
        debugPrint(
          'PNG ${await capturerVue(tester, 'traitement_390_$langue')}',
        );
        final Finder selecteur = find.byType(SelecteurSection<int>);
        await tester.tap(
          find.descendant(of: selecteur, matching: find.byType(InkWell)).first,
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, 'traitement_pages_390_$langue')}',
        );
      });

      testWidgets('accueil 390 $langue', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 844), 1);
        await _monter(tester, Routes.admin);
        await tester.ensureVisible(find.byKey(TableauDeBordPage.cleChiffres));
        await stabiliser(tester);
        debugPrint('PNG ${await capturerVue(tester, 'accueil_390_$langue')}');
      });
    }

    testWidgets('traitement 1440 fr', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await _monter(tester, Routes.adminOperationsTraitement);
      debugPrint('PNG ${await capturerVue(tester, 'traitement_1440_fr')}');
    });
  });
}
