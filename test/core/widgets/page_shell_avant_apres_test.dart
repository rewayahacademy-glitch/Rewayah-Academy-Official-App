// LUMIERE-DOUCE (pilote, 11/11/2026) : PageShell pose desormais la gouttiere
// a l'interieur de son defilement. Deux pages sans lumiere, a 320, capturees
// avant et apres le changement pour prouver qu'elles n'ont pas bouge : une
// page a liste longue (la file des candidatures) et le fil de discussion,
// dont la tete est une liste (`TetePageConfiee`). Donnees de demonstration.
// Jamais sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md) ;
// `CAPTURE_SUFFIXE` (avant / apres) nomme la serie.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../../capture/outil_capture.dart';
import '../../features/admin_candidatures/hote_candidatures.dart';
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/demo/controleur_demo.dart';
import '../../support/demo/demo_controleur_page.dart';

final String _suffixe = Platform.environment['CAPTURE_SUFFIXE'] ?? 'apres';

void main() {
  group('Capture : PageShell avant et apres (320)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final double echelle in <double>[1, 2]) {
      testWidgets('liste longue, texte x${echelle.toInt()}', (
        WidgetTester tester,
      ) async {
        await monterCandidatures(
          tester,
          port: FauxCandidaturesDirection(
            lignes: <LigneCandidature>[
              for (int i = 1; i <= 30; i++)
                ligneTest(
                  id: 'c${i.toString().padLeft(2, '0')}',
                  nom: 'Personne ${i.toString().padLeft(2, '0')}',
                ),
            ],
            capacitesRendues: capacitesGestes,
          ),
          largeur: 320,
          hauteur: 900,
          echelle: echelle,
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, 'liste_longue_320_x${echelle.toInt()}_$_suffixe')}',
        );
      });

      testWidgets('fil de discussion, texte x${echelle.toInt()}', (
        WidgetTester tester,
      ) async {
        tester.view
          ..physicalSize = const Size(320, 640)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = echelle;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                locale: AppLocale.fr.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: GoRouter(
                  initialLocation: adresseDemoControleur(
                    EcranDemoControleur.echanges,
                    fil: 'demo-mission-al-badr-0924',
                  ),
                  routes: routesDemoControleur('dev'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        debugPrint(
          'PNG ${await capturerVue(tester, 'fil_discussion_320_x${echelle.toInt()}_$_suffixe')}',
        );
      });
    }
  });
}
