// CHIFFRES-ACADEMIE (directeur, 21/11/2026) : au telephone en portrait, le
// panneau de la direction ne s'affiche pas ; les pages d'Operations doivent
// s'atteindre par le selecteur de pages de l'Espace de traitement et des
// Classes, pas seulement en paysage.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../support/demo/mode_demonstration.dart';
import '../support/selecteur_section.dart';

late GoRouter _routeur;

Future<void> _laisser(WidgetTester tester) async {
  for (int i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _monter(WidgetTester tester, String adresse) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesDemoAdmin(environnement: 'staging'),
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            _routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: _routeur,
            );
          },
        ),
      ),
    ),
  );
  await _laisser(tester);
  _routeur.go(adresse);
  await _laisser(tester);
}

String get _chemin => _routeur.routerDelegate.currentConfiguration.uri.path;

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('le selecteur porte toutes les pages du panneau d\'Operations', () {
    final List<String> chemins = <String>[
      for (final SousLien o in pagesOperations()) o.chemin,
    ];
    expect(chemins, contains(Routes.adminOperationsChiffres));
    expect(chemins, contains(Routes.adminOperationsTraitement));
    expect(chemins, contains(Routes.adminOperationsGroupes));
    expect(chemins.length, greaterThan(ongletsOperations().length));
  });

  for (final String depart in <String>[
    Routes.adminOperationsTraitement,
    Routes.adminOperationsGroupes,
  ]) {
    testWidgets('390 portrait, depuis $depart : « Les chiffres de '
        'l\'academie » s\'ouvre par le selecteur de pages', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart);
      expect(_chemin, depart);
      await choisirSection(tester, t.admin.chiffres.lien);
      await _laisser(tester);
      expect(_chemin, Routes.adminOperationsChiffres);
      expect(tester.takeException(), isNull);
    });
  }
}
