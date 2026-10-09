// PAGESHELL-200-1e : captures de preuve, avant et apres (prefixe lu dans
// `CAPTURE_PREFIXE`, « apres » par defaut). Coque admin (demonstration)
// avec une alerte urgente ouverte : tete de page fixe sous le bandeau fige
// en defilant (compact, rail, large ; LTR et RTL ; Interface guidee), ecart
// bandeau-titre en Interface guidee, bandeau de la chaine du Journal a
// 320 px texte x2, Journal en Interface guidee a 390x684 (avec et sans
// alerte), titre simple a
// texte agrandi (Accueil admin, sans bandeau). Reprise du 09/10 : Journal,
// Regles et Dossiers defiles a 800x600, 1024x768, 1440x700, 1440x500 et
// 1440x900 (standard et Interface guidee), barre mobile guidee a 320 x2.
// Jamais sans `CAPTURE_DIR`.

import 'dart:io';

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
  String nom,
  String route,
  Size taille,
  double echelle,
  ThemeMode theme,
  TextDirection sens,
  bool guidee,
  bool defile,
  bool alertes,
});

final String _prefixe =
    Platform.environment['CAPTURE_PREFIXE']?.trim().isNotEmpty ?? false
    ? Platform.environment['CAPTURE_PREFIXE']!.trim()
    : 'apres';

void main() {
  group('Capture : PAGESHELL-200-1e', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    const TextDirection ltr = TextDirection.ltr;
    const TextDirection rtl = TextDirection.rtl;
    const ThemeMode clair = ThemeMode.light;
    const ThemeMode sombre = ThemeMode.dark;
    const String journal = Routes.adminSecuriteAuditJournal;
    const String regles = Routes.adminConfigurationRegles;
    for (final _Cas cas in const <_Cas>[
      (
        nom: 'journal_390x844_clair_haut',
        route: journal,
        taille: Size(390, 844),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: false,
        defile: false,
        alertes: true,
      ),
      (
        nom: 'regles_390x844_clair_defile',
        route: regles,
        taille: Size(390, 844),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: false,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'regles_390x844_sombre_rtl_defile',
        route: regles,
        taille: Size(390, 844),
        echelle: 1,
        theme: sombre,
        sens: rtl,
        guidee: false,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'regles_800x600_clair_rail_defile',
        route: regles,
        taille: Size(800, 600),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: false,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'regles_800x600_sombre_rtl_rail_defile',
        route: regles,
        taille: Size(800, 600),
        echelle: 1,
        theme: sombre,
        sens: rtl,
        guidee: false,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'regles_1440x500_sombre_defile',
        route: regles,
        taille: Size(1440, 500),
        echelle: 1,
        theme: sombre,
        sens: ltr,
        guidee: false,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'regles_1440x500_clair_rtl_defile',
        route: regles,
        taille: Size(1440, 500),
        echelle: 1,
        theme: clair,
        sens: rtl,
        guidee: false,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'journal_390x844_clair_guidee_haut',
        route: journal,
        taille: Size(390, 844),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: true,
        defile: false,
        alertes: true,
      ),
      (
        nom: 'regles_1440x900_clair_guidee_defile',
        route: regles,
        taille: Size(1440, 900),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: true,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'journal_390x684_clair_guidee_defile',
        route: journal,
        taille: Size(390, 684),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: true,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'journal_320x640_texte2_clair_haut',
        route: journal,
        taille: Size(320, 640),
        echelle: 2,
        theme: clair,
        sens: ltr,
        guidee: false,
        defile: false,
        alertes: true,
      ),
      (
        nom: 'journal_320x640_texte2_sombre_rtl_haut',
        route: journal,
        taille: Size(320, 640),
        echelle: 2,
        theme: sombre,
        sens: rtl,
        guidee: false,
        defile: false,
        alertes: true,
      ),
      (
        nom: 'regles_390x844_texte2_clair_defile',
        route: regles,
        taille: Size(390, 844),
        echelle: 2,
        theme: clair,
        sens: ltr,
        guidee: false,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'accueil_390x844_texte2_clair_haut',
        route: Routes.admin,
        taille: Size(390, 844),
        echelle: 2,
        theme: clair,
        sens: ltr,
        guidee: false,
        defile: false,
        alertes: true,
      ),
      (
        nom: 'accueil_320x640_texte2_sombre_rtl_haut',
        route: Routes.admin,
        taille: Size(320, 640),
        echelle: 2,
        theme: sombre,
        sens: rtl,
        guidee: false,
        defile: false,
        alertes: true,
      ),
      (
        nom: 'journal_390x684_clair_guidee_sans_alerte_defile',
        route: journal,
        taille: Size(390, 684),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: true,
        defile: true,
        alertes: false,
      ),
      (
        nom: 'journal_1440x700_clair_defile',
        route: journal,
        taille: Size(1440, 700),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: false,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'journal_1024x768_sombre_rtl_defile',
        route: journal,
        taille: Size(1024, 768),
        echelle: 1,
        theme: sombre,
        sens: rtl,
        guidee: false,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'journal_800x600_clair_rail_defile',
        route: journal,
        taille: Size(800, 600),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: false,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'journal_800x600_sombre_rtl_guidee_defile',
        route: journal,
        taille: Size(800, 600),
        echelle: 1,
        theme: sombre,
        sens: rtl,
        guidee: true,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'journal_1440x500_clair_defile',
        route: journal,
        taille: Size(1440, 500),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: false,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'journal_1440x900_clair_guidee_defile',
        route: journal,
        taille: Size(1440, 900),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: true,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'journal_390x844_clair_defile',
        route: journal,
        taille: Size(390, 844),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: false,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'regles_800x600_clair_guidee_defile',
        route: regles,
        taille: Size(800, 600),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: true,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'dossiers_800x600_clair_guidee_defile',
        route: Routes.adminPersonnesDossiers,
        taille: Size(800, 600),
        echelle: 1,
        theme: clair,
        sens: ltr,
        guidee: true,
        defile: true,
        alertes: true,
      ),
      (
        nom: 'journal_320x640_texte2_clair_guidee_haut',
        route: journal,
        taille: Size(320, 640),
        echelle: 2,
        theme: clair,
        sens: ltr,
        guidee: true,
        defile: false,
        alertes: true,
      ),
    ]) {
      final String nom = 'pageshell200_1e_${_prefixe}_${cas.nom}';
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
                avecAlertes: cas.alertes,
              ),
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
            .go(cas.route);
        await stabiliser(tester);
        if (cas.defile) {
          final List<ScrollableState> pages = tester
              .stateList<ScrollableState>(
                find.descendant(
                  of: find.byType(PageShell),
                  matching: find.byType(Scrollable),
                ),
              )
              .where(
                (ScrollableState s) =>
                    s.position.axis == Axis.vertical &&
                    s.position.maxScrollExtent > 0,
              )
              .toList();
          if (pages.isNotEmpty) {
            pages.first.position.jumpTo(pages.first.position.maxScrollExtent);
            await stabiliser(tester);
          }
        }
        debugPrint('PNG ${await capturerVue(tester, nom)}');
      });
    }
  });
}
