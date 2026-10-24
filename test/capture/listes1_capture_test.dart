// Captures de la refonte des listes administratives (LISTES-1, 23/10/2026),
// sur la VRAIE application et le vrai routeur en demonstration
// d'administration : la coque (barre laterale, en-tete) est donc dans chaque
// PNG. Candidatures (quatorze lignes fictives) et Comptes (eleves, tuteurs,
// responsables), 1440x900, clair et sombre.
//
// Le meme fichier sert aux captures « avant » (code de depart) et « apres » :
// seul `CAPTURE_DIR` change. Saute sans CAPTURE_DIR (voir
// `test/capture/LISEZ-MOI.md`). Donnees fictives uniquement.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/comptes_capture.dart';
import '../support/lignes_candidatures_capture.dart';
import 'outil_capture.dart';

const Size _bureau = Size(1440, 900);

Future<void> _monter(
  WidgetTester tester,
  String route, {
  required ThemeMode mode,
  PortCandidaturesDirection? port,
  ServiceComptes? comptes,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        if (port != null)
          portCandidaturesDirectionProvider.overrideWithValue(port),
        if (comptes != null)
          comptesProvider.overrideWith((Ref ref) => comptes.comptes()),
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
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(route);
  await stabiliser(tester);
  await stabiliser(tester);
}

Future<void> _enHaut(WidgetTester tester) async {
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    if (etat.position.axis == Axis.vertical) {
      etat.position.jumpTo(etat.position.minScrollExtent);
    }
  }
  await tester.pump();
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('LISTES-1 : captures des listes', skip: sautSansCapture, () {
    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('candidatures 1440 ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, _bureau, 1);
        await _monter(
          tester,
          Routes.adminPersonnesCandidatures,
          mode: mode,
          port: FauxCandidaturesDirection(
            lignes: lignesCandidaturesCapture(),
            capacitesRendues: capacitesQuiDecide,
          ),
        );
        await _enHaut(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'candidatures_1440_${mode.name}')}',
        );
      });

      testWidgets('comptes 1440 ${mode.name}', (WidgetTester tester) async {
        fixerVueCapture(tester, _bureau, 1);
        await _monter(
          tester,
          Routes.adminPersonnesComptes,
          mode: mode,
          comptes: FauxComptesCapture(comptesCapture()),
        );
        await _enHaut(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'comptes_1440_${mode.name}')}',
        );
      });
    }
  });
}
