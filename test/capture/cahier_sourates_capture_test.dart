// SOURATES (directeur, 11/11/2026, option A) : la feuille d'un eleve dans le
// cahier, avec les sourates des bases a cocher. Donnees fictives : le
// brouillon de demonstration de l'enseignant et les 17 sourates des bases,
// dont 3 deja validees. 390, clair, sombre et arabe.
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/fiche_groupe/sourates_classe.dart';

import '../support/demo/enseignant_demo.dart';
import 'outil_capture.dart';

const List<(int, String)> _bases = <(int, String)>[
  (1, 'Al-Fatiha'),
  (114, 'An-Nas'),
  (113, 'Al-Falaq'),
  (112, 'Al-Ikhlas'),
  (111, 'Al-Masad'),
  (110, 'An-Nasr'),
  (109, 'Al-Kafirun'),
  (108, 'Al-Kawthar'),
  (107, "Al-Ma'un"),
  (106, 'Quraysh'),
  (105, 'Al-Fil'),
  (104, 'Al-Humaza'),
  (103, "Al-'Asr"),
  (102, 'At-Takathur'),
  (101, "Al-Qari'a"),
  (100, "Al-'Adiyat"),
  (99, 'Az-Zalzalah'),
];

const List<String> _basesArabe = <String>[
  'الفاتحة',
  'الناس',
  'الفلق',
  'الإخلاص',
  'المسد',
  'النصر',
  'الكافرون',
  'الكوثر',
  'الماعون',
  'قريش',
  'الفيل',
  'الهمزة',
  'العصر',
  'التكاثر',
  'القارعة',
  'العاديات',
  'الزلزلة',
];

List<SourateBases> _sourates() => <SourateBases>[
  for (int i = 0; i < _bases.length; i++)
    SourateBases(
      ordre: i + 1,
      numero: _bases[i].$1,
      nom: _bases[i].$2,
      nomArabe: _basesArabe[i],
      validee: i < 3,
    ),
];

void main() {
  group('Capture : sourates du cahier', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, AppLocale langue, ThemeMode theme)
        in <(String, AppLocale, ThemeMode)>[
          ('clair', AppLocale.fr, ThemeMode.light),
          ('sombre', AppLocale.fr, ThemeMode.dark),
          ('arabe', AppLocale.ar, ThemeMode.light),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 2400), 2);
        final BrouillonCahier brouillon =
            DonneesEnseignantDemo.brouillonCahier();
        final ParticipantBrouillon eleve = brouillon.participants.first;
        await tester.pumpWidget(
          hoteCapture(
            Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: FeuilleAjusterCahier(
                  participant: eleve,
                  brouillon: brouillon,
                  decision: DecisionEleve(
                    studentId: eleve.membre.studentId,
                    souratesValidees: const <int>{112},
                  ),
                  sourates: _sourates(),
                ),
              ),
            ),
            themeMode: theme,
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'cahier_sourates_$nom')}');
      });
    }
  });
}
