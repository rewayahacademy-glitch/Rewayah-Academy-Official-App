// ALERTE-1b : captures de preuve de la coque admin (demonstration) avec une
// alerte urgente ouverte. Bandeau fige en haut et cloche a point, avant et
// apres defilement de la page (Securite et audit, Journal ; Dossiers a
// 320 px texte x2) ; clair et sombre ; LTR et RTL ; Interface guidee ; 390,
// 1440, 320x640 a texte x2 (forme courte du bandeau). Jamais sans
// `CAPTURE_DIR`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import 'outil_capture.dart';

typedef _Cas = ({
  Size taille,
  double echelle,
  ThemeMode theme,
  TextDirection sens,
  bool guidee,
  bool defile,
});

void main() {
  group('Capture : ALERTE-1b', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    const TextDirection ltr = TextDirection.ltr;
    const TextDirection rtl = TextDirection.rtl;
    const ThemeMode clair = ThemeMode.light;
    const ThemeMode sombre = ThemeMode.dark;
    for (final _Cas cas in const <_Cas>[
      (
        taille: Size(390, 844),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: false,
        defile: false,
      ),
      (
        taille: Size(390, 844),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: false,
        defile: true,
      ),
      (
        taille: Size(390, 844),
        echelle: 1,
        theme: clair,
        sens: rtl,
        guidee: false,
        defile: false,
      ),
      (
        taille: Size(390, 844),
        echelle: 1,
        theme: clair,
        sens: rtl,
        guidee: false,
        defile: true,
      ),
      (
        taille: Size(390, 844),
        echelle: 1,
        theme: sombre,
        sens: ltr,
        guidee: false,
        defile: true,
      ),
      (
        taille: Size(390, 844),
        echelle: 1,
        theme: sombre,
        sens: rtl,
        guidee: false,
        defile: true,
      ),
      (
        taille: Size(1440, 700),
        echelle: 1,
        theme: sombre,
        sens: ltr,
        guidee: false,
        defile: false,
      ),
      (
        taille: Size(1440, 500),
        echelle: 1,
        theme: sombre,
        sens: ltr,
        guidee: false,
        defile: true,
      ),
      (
        taille: Size(1440, 500),
        echelle: 1,
        theme: clair,
        sens: rtl,
        guidee: false,
        defile: true,
      ),
      (
        taille: Size(320, 640),
        echelle: 2,
        theme: sombre,
        sens: ltr,
        guidee: false,
        defile: true,
      ),
      (
        taille: Size(320, 640),
        echelle: 2,
        theme: clair,
        sens: rtl,
        guidee: false,
        defile: true,
      ),
      (
        taille: Size(390, 844),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: true,
        defile: false,
      ),
      (
        taille: Size(390, 844),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: true,
        defile: true,
      ),
      (
        taille: Size(390, 844),
        echelle: 1,
        theme: sombre,
        sens: rtl,
        guidee: true,
        defile: true,
      ),
    ]) {
      final String nom =
          'alerte1b_coque_${cas.taille.width.toInt()}x'
          '${cas.taille.height.toInt()}${cas.echelle == 2 ? '_texte2' : ''}_'
          '${cas.theme == clair ? 'clair' : 'sombre'}'
          '${cas.sens == rtl ? '_rtl' : ''}${cas.guidee ? '_guidee' : ''}_'
          '${cas.defile ? 'defile' : 'haut'}';
      testWidgets(nom, (WidgetTester tester) async {
        masquerRubanDebug();
        tester.view.physicalSize = cas.taille;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        if (cas.echelle != 1) {
          tester.platformDispatcher.textScaleFactorTestValue = cas.echelle;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              ...surchargesDemoAdmin(
                environnement: 'staging',
                avecAlertes: true,
              ),
              // La base locale (drift) ne s'ouvre pas sous `runAsync` en
              // test : la preference d'apparence reste en memoire.
              stockagePreferencesProvider.overrideWithValue(
                StockagePreferencesMemoire(),
              ),
              if (cas.guidee)
                modeAccessibiliteActifProvider.overrideWith((Ref _) => true),
            ],
            child: TranslationProvider(
              child: RewayahApp(
                themeMode: cas.theme,
                builder: (BuildContext context, Widget? child) =>
                    Directionality(
                      textDirection: cas.sens,
                      child: RepereDemonstration(child: child),
                    ),
              ),
            ),
          ),
        );
        ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
            .read(routeurProvider)
            .go(
              // A 320 px texte x2, le Journal deborde a droite (ligne de
              // filtres, `journal_page.dart`, defaut anterieur hors de cette
              // etape) : la page des Dossiers.
              cas.echelle == 2
                  ? Routes.adminPersonnesDossiers
                  : Routes.adminSecuriteAuditJournal,
            );
        await stabiliser(tester);
        if (cas.defile) {
          final ScrollableState page = tester
              .stateList<ScrollableState>(
                find.descendant(
                  of: find.byType(PageShell),
                  matching: find.byType(Scrollable),
                ),
              )
              .firstWhere(
                (ScrollableState s) => s.position.axis == Axis.vertical,
              );
          page.position.jumpTo(page.position.maxScrollExtent);
          await stabiliser(tester);
        }
        debugPrint('PNG ${await capturerVue(tester, nom)}');
      });
    }
  });
}
