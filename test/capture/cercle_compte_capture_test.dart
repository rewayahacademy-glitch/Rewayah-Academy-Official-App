// Captures du correctif du cercle Compte (decision du directeur du 09/11/2026,
// relayee par le garde-cap le 10/11) : cercle d'environ 64, photo a environ
// 95 % dans un fin liseré blanc, +10 % quand il est ouvert ; la meme regle
// pour les ronds du selecteur de profils de l'Accueil du foyer. Accueil et
// Compte du tuteur sur le VRAI routeur, foyer fictif A (donnees de test), a
// 320 et 1440, texte x1 et x2, clair et sombre.
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

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

import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

Future<void> _monter(
  WidgetTester tester,
  String depart, {
  required ThemeMode mode,
  required double texte,
}) async {
  late GoRouter routeur;
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = FoyersFictifs.foyerA;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesRouteur(
        FausseSourceSession(sessionActive(AppRole.guardian)),
        appairage: appairage,
      ),
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
                builder: (BuildContext contexte, Widget? app) => MediaQuery(
                  data: MediaQuery.of(contexte)
                      .copyWith(textScaler: TextScaler.linear(texte)),
                  child: app!,
                ),
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
  group('Capture : cercle Compte et ronds des profils', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String nom, String chemin) ecran in <(String, String)>[
      ('accueil', Routes.tuteurAccueil),
      ('compte-ouvert', Routes.tuteurCompte),
    ]) {
      for (final (Size taille, double texte, ThemeMode mode) cas
          in <(Size, double, ThemeMode)>[
            (const Size(320, 700), 1, ThemeMode.light),
            (const Size(320, 700), 2, ThemeMode.light),
            (const Size(320, 700), 1, ThemeMode.dark),
            (const Size(1440, 900), 1, ThemeMode.light),
            (const Size(1440, 900), 2, ThemeMode.dark),
          ]) {
        final String suffixe =
            '${cas.$1.width.toInt()}_x${cas.$2.toInt()}_${cas.$3.name}';
        testWidgets('${ecran.$1} $suffixe', (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$1, 1);
          await _monter(tester, ecran.$2, mode: cas.$3, texte: cas.$2);
          expect(tester.takeException(), isNull);
          debugPrint(
            'PNG ${await capturer(tester, 'cercle-compte_${ecran.$1}_$suffixe')}',
          );
        });
      }
    }
  });
}
