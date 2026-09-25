// Captures de recette LT-12 : liste des paiements et detail d'un paiement
// sur le VRAI routeur, avec un faux port (aucune source reelle, DB-CPT-03),
// 390x844 et 1440x900, clair et sombre. A comparer a la planche « 04
// Compte/preferences/aide ».
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';
import 'support_compte.dart' hide toucher;

Future<void> _monter(WidgetTester tester, ThemeMode mode, String depart) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: FauxServiceAppairage(),
        ),
        ...surchargesCompte(),
        portPaiementsFoyerProvider.overrideWithValue(FauxPaiements()),
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
  routeur.go(depart);
  await stabiliser(tester);
}

void main() {
  group('Capture : Paiements (LT-12)', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, Size taille) format in <(String, Size)>[
        ('390x844', const Size(390, 844)),
        ('1440x900', const Size(1440, 900)),
      ]) {
        for (final (String ecran, String depart) cible in <(String, String)>[
          ('paiements', Routes.tuteurComptePaiements),
          ('paiement_detail', Routes.paiementPour('p-regle')),
        ]) {
          testWidgets('${cible.$1}, ${format.$1}, ${mode.name}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, format.$2, 1);
            await _monter(tester, mode, cible.$2);
            debugPrint(
              'PNG ${await capturer(tester, '${cible.$1}_${format.$1}_${mode.name}')}',
            );
          });
        }
      }
    }
  });
}
