// Captures de la languette « Revenir page N » du lecteur du Coran (directeur,
// 11/11/2026 : « une petite languette qui dit revenir a l'ancienne page,
// numero tel, qu'on peut fermer facilement »). Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart'
    show PositionLecture;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';

import '../teaching_core/c/faux/faux_corpus_coran.dart';
import '../teaching_core/c/goldens/corpus_reference.dart';
import 'outil_capture.dart';

void main() {
  late CorpusReference reference;

  group('Capture : languette de reprise', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      reference = CorpusReference.charger();
    });
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    Widget ecran(Brightness clarte, AppLocale langue) => ProviderScope(
      overrides: <Override>[
        portCorpusCoranProvider.overrideWithValue(FauxCorpusCoran(reference)),
        portLayoutMushafProvider.overrideWithValue(
          const LayoutLignesIndisponible(),
        ),
        portNavigationCoranProvider.overrideWithValue(
          FauxNavigationCoran(
            personnelle: const PositionLecture(
              page: 30,
              sourate: 2,
              verset: 188,
            ),
          ),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: langue.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.pour(InterfaceMode.standard, clarte),
          home: const MushafPage(),
        ),
      ),
    );

    for (final (String nom, Brightness clarte, AppLocale langue)
        in <(String, Brightness, AppLocale)>[
          ('languette_390_sombre_ar', Brightness.dark, AppLocale.ar),
          ('languette_390_clair_fr', Brightness.light, AppLocale.fr),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        fixerVueCapture(tester, const Size(390, 844), 1);
        await tester.pumpWidget(ecran(clarte, langue));
        for (int i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 120));
        }
        expect(find.byKey(MushafPage.languettePersonnelleKey), findsOneWidget);
        debugPrint('PNG ${await capturerVue(tester, nom)}');
      });
    }
  });
}
