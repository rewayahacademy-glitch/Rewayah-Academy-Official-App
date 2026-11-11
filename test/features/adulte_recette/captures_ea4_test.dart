// EA-4 : les captures des pages qu'ouvrait « Mon espace » de l'eleve adulte
// (Mon espace lui-meme est supprime : MON-ESPACE-ADULTE-SUPPR, 11/11/2026,
// avec ses captures et celles des etats de sa ligne famille). Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Fichier propre a l'agent :
// ne pas confondre avec `captures_ea_test.dart` (poste B).
//
// Chaque capture d'ecran entier passe par la VRAIE route /demo/adulte
// (`adresseDemoAdulte`) sous un GoRouter, comme `captures_ea3_test.dart` :
// 390x844, 768x1024 et 1440x900, clair et sombre, plus le texte a 200 %.
//
// EA-4c (revue) : « Paiements du foyer » du second adulte rattache, et le
// cas 21 avec « Ma famille » (vue du titulaire).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/adulte_demo.dart';
import '../../support/demo/demo_adulte_page.dart';

const List<ThemeMode> _modes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

/// La vue grandit de ce qui reste a defiler, jusqu'a ce que plus rien ne
/// defile : la page entiere tient dans le PNG.
Future<void> _pleineHauteur(WidgetTester tester, Size taille) async {
  for (int i = 0; i < 4; i++) {
    double reste = 0;
    for (final ScrollableState s in tester.stateList<ScrollableState>(
      find.byType(Scrollable),
    )) {
      if (s.position.axis == Axis.vertical &&
          s.position.maxScrollExtent > reste) {
        reste = s.position.maxScrollExtent;
      }
    }
    if (reste <= 0) break;
    fixerVueCapture(
      tester,
      Size(taille.width, tester.view.physicalSize.height + reste),
      1,
    );
    await stabiliser(tester);
  }
}

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  bool pleineHauteur = true,
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
  if (pleineHauteur) await _pleineHauteur(tester, taille);
  expect(tester.takeException(), isNull, reason: fichier);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group('Capture : EA-4', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Les pages d'arrivee : « Paiements du foyer » du second adulte,
    // « Paiements » du titulaire et « Preferences » (la vraie page du
    // Compte). Mon espace, ses etats et « Mes accords » sont retires avec lui
    // (MON-ESPACE-ADULTE-SUPPR, 11/11/2026).
    for (final ThemeMode mode in _modes) {
      final String fichier = 'ea4_paiements_foyer_390_${mode.name}_conjoint';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          adresseDemoAdulte(
            EcranDemoAdulte.paiementsFoyer,
            vue: VueDemoAdulte.secondAdulte,
          ),
          const Size(390, 844),
          mode: mode,
        );
      });
    }
    for (final EcranDemoAdulte ecran in <EcranDemoAdulte>[
      EcranDemoAdulte.paiements,
      EcranDemoAdulte.preferences,
    ]) {
      final String fichier = 'ea4_${ecran.name}_390_light';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          adresseDemoAdulte(ecran),
          const Size(390, 844),
        );
      });
    }
    // Cas 21, Ma famille du titulaire : l'invitation envoyee, neutre (F4).
    testWidgets('ea4_ma_famille_390_light_deja_ailleurs', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ea4_ma_famille_390_light_deja_ailleurs',
        adresseDemoAdulte(
          EcranDemoAdulte.maFamille,
          etat: EtatDemoAdulte.dejaDansUnAutreFoyer,
        ),
        const Size(390, 844),
      );
    });
  });
}
