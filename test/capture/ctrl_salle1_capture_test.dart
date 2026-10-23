// CTRL-SALLE-1 : la salle vue par le controleur, a 320 et 1440 px, et la
// carte de mission d'une Classe deja controlee. Jamais sans `CAPTURE_DIR`
// (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

import 'outil_capture.dart';

Future<void> _capturerRoute(
  WidgetTester tester,
  String fichier,
  String route,
  Size taille,
) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: route,
    routes: routesDemoControleur('dev'),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext contexte) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: ThemeMode.light,
              locale: TranslationProvider.of(contexte).flutterLocale,
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
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group(
    'Capture : CTRL-SALLE-1, salle du controleur',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      for (final (String l, Size taille) in <(String, Size)>[
        ('320', const Size(320, 700)),
        ('1440', const Size(1440, 900)),
      ]) {
        testWidgets('ctrl_salle1_salle_$l', (WidgetTester tester) async {
          await _capturerRoute(
            tester,
            'ctrl_salle1_salle_$l',
            cheminDemoSalleControleur,
            taille,
          );
        });
        // Un seul controle a la fois par Classe : la carte de mission.
        testWidgets('ctrl_salle1_deja_controlee_$l', (
          WidgetTester tester,
        ) async {
          await _capturerRoute(
            tester,
            'ctrl_salle1_deja_controlee_$l',
            adresseDemoControleur(
              EcranDemoControleur.controle,
              etat: EtatDemoControleur.dejaControlee,
            ),
            taille,
          );
        });
      }
    },
  );
}
