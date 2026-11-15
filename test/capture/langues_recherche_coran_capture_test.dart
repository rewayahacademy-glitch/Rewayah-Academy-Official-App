// LANGUES-1 (13/11/2026) : la recherche « Aller a » du Coran ecrit « Juz 18 »
// et « Page 18 » dans la langue choisie, plus dans celle du corpus. Resultats
// fictifs rendus par un port de test ; 390 et 1440, clair et sombre, francais
// et arabe.
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';
import 'package:rewayah_academy/features/tc_mushaf/navigation_coran_feuille.dart';

import '../support/corpus_coran_depot.dart';
import '../teaching_core/c/faux/faux_corpus_coran.dart';
import 'outil_capture.dart';

class _NavigationAvecResultats extends FauxNavigationCoran {
  @override
  Future<List<ResultatRechercheCoran>> rechercheRapide(String requete) async =>
      const <ResultatRechercheCoran>[
        ResultatRechercheCoran(
          type: TypeResultatRecherche.sourate,
          page: 293,
          libelle: '18. Al-Kahf',
          sourate: 18,
        ),
        ResultatRechercheCoran(
          type: TypeResultatRecherche.juz,
          page: 342,
          libelle: 'Juz 18',
          juz: 18,
        ),
        ResultatRechercheCoran(
          type: TypeResultatRecherche.page,
          page: 18,
          libelle: 'Page 18',
        ),
      ];
}

const Key _ouvrir = Key('ouvrir');

void main() {
  group('Capture : recherche du Coran', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, AppLocale langue, Size vue, ThemeMode theme)
        in <(String, AppLocale, Size, ThemeMode)>[
          ('fr-390-clair', AppLocale.fr, const Size(390, 844), ThemeMode.light),
          ('ar-390-clair', AppLocale.ar, const Size(390, 844), ThemeMode.light),
          (
            'fr-1440-sombre',
            AppLocale.fr,
            const Size(1440, 900),
            ThemeMode.dark,
          ),
          (
            'ar-1440-sombre',
            AppLocale.ar,
            const Size(1440, 900),
            ThemeMode.dark,
          ),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, vue, 1);
        final List<Override> surcharges = <Override>[
          souratesProvider.overrideWith(
            (Ref _) async => souratesDuCorpus(),
          ),
          portNavigationCoranProvider.overrideWithValue(
            _NavigationAvecResultats(),
          ),
        ];
        await tester.pumpWidget(
          hoteCapture(
            Scaffold(
              body: Builder(
                builder: (BuildContext c) => Center(
                  child: TextButton(
                    key: _ouvrir,
                    onPressed: () => FeuilleNavigationCoran.ouvrir(
                      c,
                      onAller: (int _) {},
                    ),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
            surcharges: surcharges,
            themeMode: theme,
          ),
        );
        await tester.tap(find.byKey(_ouvrir));
        await stabiliser(tester);
        await tester.enterText(find.byType(TextField), '18');
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        expect(
          find.text(
            langue == AppLocale.ar
                ? t.eleve.coran.juz(juz: '18')
                : 'Juz 18',
          ),
          findsWidgets,
        );
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }
  });
}
