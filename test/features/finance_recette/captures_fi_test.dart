// FI-1c : squelette des captures de la vague Finance, depuis la VRAIE route
// /demo/finance (`routesDemoFinance`), comme `captures_ea10_test.dart`.
//
// Chaque etape d'ecran (FI-4 a FI-11c) ajoute ses cas a [_cas] : une adresse
// de demonstration et un nom de fichier `fi<n>_<ecran>`. Le squelette
// parcourt pour chacun la grille commune de la vague (02_DECOUPAGE.md,
// « Definition de fait » point 4) : 390x844, 768x1024 et 1440x900, clair et
// sombre, puis le texte a 200 % et le sens droite-a-gauche force en 390.
//
// **Jamais execute sans `CAPTURE_DIR`** (`sautSansCapture`) : la CI ne le
// lance pas et rien n'est ecrit sur le disque.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';

import '../../capture/outil_capture.dart';

/// Un cas de capture : le nom du fichier et l'adresse de demonstration.
typedef _Cas = ({String nom, String adresse});

/// Les cas captures. FI-1b : les deux onglets de la direction, sur la page
/// neutre. Les etapes d'ecran ajoutent les leurs ici.
final List<_Cas> _cas = <_Cas>[
  (
    nom: 'fi1_vue_globale',
    adresse: adresseDemoFinance(OngletFinance.vueGlobale),
  ),
  (
    nom: 'fi1_politiques',
    adresse: adresseDemoFinance(OngletFinance.politiques),
  ),
];

/// Les tailles de la vague (guide Finance V4 §6, §10).
const List<(String, Size)> _tailles = <(String, Size)>[
  ('390', Size(390, 844)),
  ('768', Size(768, 1024)),
  ('1440', Size(1440, 900)),
];

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  TextDirection? sens,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: routesDemoFinance('dev'),
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
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? app) {
                final Widget avecTexte = MediaQuery(
                  data: MediaQuery.of(contexte)
                      .copyWith(textScaler: TextScaler.linear(echelle)),
                  child: app!,
                );
                return sens == null
                    ? avecTexte
                    : Directionality(textDirection: sens, child: avecTexte);
              },
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group('Capture : vague Finance', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final _Cas cas in _cas) {
      for (final (String l, Size taille) in _tailles) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier = '${cas.nom}_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(tester, fichier, cas.adresse, taille, mode: mode);
          });
        }
      }

      final String agrandi = '${cas.nom}_390_light_200pc';
      testWidgets(agrandi, (WidgetTester tester) async {
        await _capturer(
          tester,
          agrandi,
          cas.adresse,
          const Size(390, 844),
          echelle: 2,
        );
      });

      final String rtl = '${cas.nom}_390_light_rtl';
      testWidgets(rtl, (WidgetTester tester) async {
        await _capturer(
          tester,
          rtl,
          cas.adresse,
          const Size(390, 844),
          sens: TextDirection.rtl,
        );
      });
    }
  });
}
