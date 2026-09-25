// Captures de recette LT-1 (lot T, selecteur de theme) sur le VRAI routeur :
// la page Apparence (clair/sombre, 390x844 et 1440x900) et, en desktop,
// l'en-tete du tuteur portant `SelecteurTheme.entete()` (clair/sombre).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). La comparaison
// a la maquette « 04 Compte, preferences et assistance » (ecran Preferences >
// Apparence) se fait par une planche composee hors de ce test.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';

/// Force la preference de theme au montage : Clair sous le theme clair,
/// Sombre sous le theme sombre, comme la maquette (« Clair » coche sous
/// l'apercu clair). Sans cela, le choix par defaut « Systeme » ne montrerait
/// aucune icone active de facon previsible en test.
class _ControleurThemeInitial extends PreferencesLocalesControleur {
  _ControleurThemeInitial(this._depart);

  final PreferenceTheme _depart;

  @override
  PreferencesLocales build() => PreferencesLocales(theme: _depart);
}

Future<void> _monter(
  WidgetTester tester,
  String depart, {
  ThemeMode mode = ThemeMode.light,
}) async {
  final PreferenceTheme choix = mode == ThemeMode.dark
      ? PreferenceTheme.sombre
      : PreferenceTheme.clair;
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
        ),
        preferencesLocalesProvider.overrideWith(
          () => _ControleurThemeInitial(choix),
        ),
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
  group('Capture : selecteur de theme (LT-1)', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, Size taille) format in <(String, Size)>[
        ('390x844', const Size(390, 844)),
        ('1440x900', const Size(1440, 900)),
      ]) {
        testWidgets('page Apparence, ${format.$1}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, format.$2, 1);
          await _monter(tester, Routes.tuteurCompteApparence, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'apparence_${format.$1}_${mode.name}')}',
          );
        });
      }

      // Bureau seulement : c'est la largeur (>= 1200) qui fait apparaitre
      // `SelecteurTheme.entete()` dans l'en-tete de la coquille tuteur
      // (`AppGabarit.estLarge`, `app_router.dart` ~l.1303).
      testWidgets('en-tete tuteur (bureau), ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await _monter(tester, Routes.tuteurAccueil, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'entete_1440x900_${mode.name}')}',
        );
      });
    }
  });
}
