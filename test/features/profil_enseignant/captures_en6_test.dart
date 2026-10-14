// EN-6 : captures de Premiers pas (ENS-01), du Profil (ENS-05) et de la photo
// publique (ENS-05A). Jamais sans `CAPTURE_DIR` (voir
// test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/profil_enseignant/photo_publique.dart';

import '../../capture/outil_capture.dart';

Future<void> _monter(
  WidgetTester tester,
  EcranDemoEnseignant ecran,
  Size taille,
  ThemeMode mode,
) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(CoquilleEnseignantDemo(ecran: ecran), themeMode: mode),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

Future<void> _ouvrirPhoto(WidgetTester tester) =>
    _toucher(tester, find.text(t.enseignant.photo.choisir).first);

void main() {
  group('Capture : EN-6', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 900)),
      ('768', const Size(768, 1000)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String suffixe = '${l}_${mode.name}';
        testWidgets('en6_premiers_pas_$suffixe', (WidgetTester tester) async {
          await _monter(tester, EcranDemoEnseignant.premiersPas, taille, mode);
          debugPrint(
            'PNG ${await capturer(tester, 'en6_premiers_pas_$suffixe')}',
          );
        });
        testWidgets('en6_profil_$suffixe', (WidgetTester tester) async {
          await _monter(tester, EcranDemoEnseignant.profil, taille, mode);
          debugPrint('PNG ${await capturer(tester, 'en6_profil_$suffixe')}');
        });
        testWidgets('en6_photo_$suffixe', (WidgetTester tester) async {
          await _monter(tester, EcranDemoEnseignant.profil, taille, mode);
          await _ouvrirPhoto(tester);
          debugPrint('PNG ${await capturer(tester, 'en6_photo_$suffixe')}');
        });
        testWidgets('en6_photo_apercu_$suffixe', (WidgetTester tester) async {
          await _monter(tester, EcranDemoEnseignant.profil, taille, mode);
          await _ouvrirPhoto(tester);
          await _toucher(tester, find.byKey(EditeurPhotoPublique.choisirKey));
          debugPrint(
            'PNG ${await capturer(tester, 'en6_photo_apercu_$suffixe')}',
          );
        });
        testWidgets('en6_photo_succes_$suffixe', (WidgetTester tester) async {
          await _monter(tester, EcranDemoEnseignant.profil, taille, mode);
          await _ouvrirPhoto(tester);
          await _toucher(tester, find.byKey(EditeurPhotoPublique.choisirKey));
          await tester.tap(find.byKey(EditeurPhotoPublique.utiliserKey));
          await tester.pump(const Duration(seconds: 1));
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'en6_photo_succes_$suffixe')}',
          );
        });
      }
    }
  });
}
