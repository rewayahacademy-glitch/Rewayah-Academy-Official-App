// COM-F-b : captures de recette des complements COM-0b poses dans les pages
// existantes. Aujourd'hui de l'enseignant (l'emplacement « Communaute
// enseignants » est dans « Ma journee », quatre blocs, rien de plus tant que
// COM-COMU-1 ne le remplit pas) et le tableau de bord admin (ligne
// « Communications » des raccourcis). 390, 1440, 320 a texte double (vrai
// `textScaler` 2, par la plateforme), arabe (RTL), clair et sombre.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Mode
// d'emploi : `test/capture/LISEZ-MOI.md`.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/cache/db/app_database.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import 'outil_capture.dart';

/// Une variante : nom, taille logique, densite, echelle de texte, theme,
/// langue.
typedef _Variante = (String, Size, double, double, ThemeMode, AppLocale);

const List<_Variante> _variantes = <_Variante>[
  ('390_clair', Size(390, 1600), 2, 1, ThemeMode.light, AppLocale.fr),
  ('390_sombre', Size(390, 1600), 2, 1, ThemeMode.dark, AppLocale.fr),
  ('390_rtl_clair', Size(390, 1600), 2, 1, ThemeMode.light, AppLocale.ar),
  ('1440_clair', Size(1440, 1000), 1, 1, ThemeMode.light, AppLocale.fr),
  ('1440_sombre', Size(1440, 1000), 1, 1, ThemeMode.dark, AppLocale.fr),
  ('320x2_clair', Size(320, 2600), 2, 2, ThemeMode.light, AppLocale.fr),
  ('320x2_sombre', Size(320, 2600), 2, 2, ThemeMode.dark, AppLocale.fr),
];

void _preparer(WidgetTester tester, _Variante v) {
  final (_, Size logique, double densite, double echelle, _, AppLocale l) = v;
  fixerVueCapture(tester, logique, densite);
  tester.platformDispatcher.textScaleFactorTestValue = echelle;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  LocaleSettings.setLocaleSync(l);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
}

/// Une base en memoire : l'ecriture du PNG laisse courir le vrai temps, et la
/// base de l'appareil chercherait un dossier que le test n'a pas.
Override _baseMemoire() => baseLocaleProvider.overrideWith((Ref ref) {
  final AppDatabase base = AppDatabase.surExecuteur(NativeDatabase.memory());
  ref.onDispose(base.close);
  return base;
});

/// Le tableau de bord admin reel, en demonstration admin, aucun serveur.
Future<void> _monterAdmin(WidgetTester tester, ThemeMode mode) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        _baseMemoire(),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: RewayahApp(themeMode: mode),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
      .read(routeurProvider)
      .go(Routes.admin);
  await stabiliser(tester);
  // La ligne « Communications » est sous les compteurs : on l'amene a
  // l'ecran, comme l'administrateur le ferait.
  final Finder ligne = find.byKey(
    const ValueKey<String>('tableau-communications'),
  );
  await tester.ensureVisible(ligne);
  await stabiliser(tester);
}

void main() {
  group('Capture : COM-F-b', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      // La bibliotheque arabe est differee : chargee une fois, hors du
      // `FakeAsync` des tests, pour que `setLocaleSync` la trouve.
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final _Variante v in _variantes) {
      final (String nom, _, _, double echelle, ThemeMode mode, _) = v;

      testWidgets('journee $nom', (WidgetTester tester) async {
        _preparer(tester, v);
        // La page seule, sous les surcharges de la demonstration enseignant
        // posees a la racine : la coquille de demonstration ouvre son propre
        // ProviderScope, ou la base locale n'est plus surchargee (base de
        // l'appareil, absente en test).
        await tester.pumpWidget(
          hoteCapture(
            const JourneePage(),
            surcharges: <Override>[
              ...surchargesCoquilleEnseignantDemo(EtatDemoEnseignant.nominal),
              _baseMemoire(),
            ],
            themeMode: mode,
            echelleTexte: echelle,
          ),
        );
        await stabiliser(tester);
        expect(
          MediaQuery.textScalerOf(tester.element(find.byType(JourneePage)))
              .scale(10),
          10 * echelle,
        );
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'com_f_b_journee_$nom')}');
      });

      testWidgets('tableau admin $nom', (WidgetTester tester) async {
        _preparer(tester, v);
        await _monterAdmin(tester, mode);
        expect(tester.takeException(), isNull);
        debugPrint(
          'PNG ${await capturer(tester, 'com_f_b_tableau_admin_$nom')}',
        );
      });
    }
  });
}
