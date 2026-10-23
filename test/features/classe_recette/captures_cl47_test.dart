// CL-4.7 : les captures finales de l'entree en classe. Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart'
    show TitreEnseignant;
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';

import '../../capture/outil_capture.dart';

Widget _ecran(String nom, {TitreEnseignant titre = TitreEnseignant.sayyid}) =>
    switch (nom) {
      'espace_eleve' => EcranEleveDemo(
        etat: EtatDemoClasse.fenetreOuverte,
        titre: titre,
      ),
      'espace_enseignant' => EcranEnseignantDemo(
        etat: EtatDemoClasse.fenetreOuverte,
        titre: titre,
      ),
      'preparation_enseignant' => const EcranPreparationDemo(
        etat: PreparationDemo.pret,
      ),
      'preparation_eleve_micro_bloque' => const EcranPreparationEleveDemo(
        etat: PreparationEleveDemo.microBloque,
      ),
      _ => const EcranPreparationEleveDemo(etat: PreparationEleveDemo.pret),
    };

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  Widget ecran,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  bool rtl = false,
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      rtl
          ? Directionality(textDirection: TextDirection.rtl, child: ecran)
          : ecran,
      themeMode: mode,
      echelleTexte: echelle,
    ),
  );
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group('Capture : CL-4.7', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final String nom in <String>[
      'espace_eleve',
      'espace_enseignant',
      'preparation_enseignant',
      'preparation_eleve',
    ]) {
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 900)),
        ('768', const Size(768, 1000)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier = 'cl47_${nom}_sayyid_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(tester, fichier, _ecran(nom), taille, mode: mode);
          });
        }
      }
    }
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final String fichier =
          'cl47_preparation_eleve_micro_bloque_390_${mode.name}';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          _ecran('preparation_eleve_micro_bloque'),
          const Size(390, 900),
          mode: mode,
        );
      });
    }
    testWidgets('cl47_espace_eleve_sayyida_390_light', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'cl47_espace_eleve_sayyida_390_light',
        _ecran('espace_eleve', titre: TitreEnseignant.sayyida),
        const Size(390, 900),
      );
    });
    testWidgets('cl47_espace_enseignant_sayyida_1440_light', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'cl47_espace_enseignant_sayyida_1440_light',
        _ecran('espace_enseignant', titre: TitreEnseignant.sayyida),
        const Size(1440, 900),
      );
    });
    testWidgets('cl47_pseudo_rtl_espace_eleve_390_light', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'cl47_pseudo_rtl_espace_eleve_390_light',
        _ecran('espace_eleve'),
        const Size(390, 900),
        rtl: true,
        echelle: 1.4,
      );
    });
    testWidgets('cl47_pseudo_rtl_preparation_eleve_micro_bloque_390_light', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'cl47_pseudo_rtl_preparation_eleve_micro_bloque_390_light',
        _ecran('preparation_eleve_micro_bloque'),
        const Size(390, 900),
        rtl: true,
        echelle: 1.4,
      );
    });
  });
}
