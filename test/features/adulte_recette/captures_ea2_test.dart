// EA-2 : les captures finales de l'accueil de l'eleve adulte. Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Fichier propre a l'agent :
// ne pas confondre avec `captures_ea_test.dart` (poste B).
//
// Chaque capture passe par la VRAIE route /demo/adulte (`adresseDemoAdulte`)
// sous un GoRouter, comme `captures_ea_test.dart`, et montre la page
// ENTIERE : la hauteur de la vue suffit a آ« Ressources de la classe آ», en
// bas de page (390 et 768 en clair et en sombre, 1440, 200 %). L'etat porte
// ouverte (`seance=fenetreOuverte`) montre le bouton dominant de
// l'emplacement d'entree (pleine largeur sur telephone, au bord de fin
// au-dela, K-42 point 2).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: routesDemoAdulte('dev'),
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
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: app!,
              ),
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
  group('Capture : EA-2', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Des hauteurs qui tiennent la page entiere (la barre de la coquille
    // reste en bas de la vue).
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 1900)),
      ('768', const Size(768, 1700)),
      ('1440', const Size(1440, 1300)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea2_accueil_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresseDemoAdulte(EcranDemoAdulte.accueil),
            taille,
            mode: mode,
          );
        });
      }
    }

    testWidgets('ea2_accueil_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea2_accueil_390_light_200pc',
        adresseDemoAdulte(EcranDemoAdulte.accueil),
        const Size(390, 4600),
        echelle: 2,
      );
    });

    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 1900)),
      ('1440', const Size(1440, 1300)),
    ]) {
      testWidgets('ea2_accueil_porte_ouverte_$l', (WidgetTester tester) async {
        await _capturer(
          tester,
          'ea2_accueil_porte_ouverte_${l}_light',
          adresseDemoAdulte(
            EcranDemoAdulte.accueil,
            seance: EtatDemoClasse.fenetreOuverte,
          ),
          taille,
        );
      });
    }
  });
}
