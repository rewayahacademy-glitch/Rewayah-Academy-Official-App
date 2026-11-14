// Captures de recette HORS-SALLE-1 (directeur, 12/11/2026 au soir) : captures
// de TEST, la vraie `SallePage` et le vrai controleur de session sur le faux
// moteur des tests (aucun LiveKit, aucun serveur, aucun telephone).
// (a) l'ecran du retour de l'eleve sorti apres plus de 30 secondes hors de
// l'application : clair, sombre, arabe ; (b) le son bloque, salle reduite
// (l'ecran sous le bandeau est un ecran de test, pas l'accueil reel).
// 390 de large. Saute sans CAPTURE_DIR. Nommage : hors_salle_<cas>_390_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../features/salle_seance/hors_salle_test.dart';
import 'outil_capture.dart';

Future<void> _retour(
  WidgetTester tester,
  ThemeMode mode,
  String nom, {
  bool arabe = false,
}) async {
  if (arabe) {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
  }
  fixerVueCapture(tester, const Size(390, 844), 3);
  await monterHorsSalle(tester, mode: mode, cadre: cadreCapture);
  cacherPage(tester);
  await tester.pump(const Duration(seconds: 31));
  await montrerPage(tester);
  await stabiliser(tester);
  expect(find.text(t.salle.fin.horsApplication.titre), findsOneWidget);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : HORS-SALLE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(neutraliserStockageAppareil);

    testWidgets('hors_salle_retour_390_light', (WidgetTester tester) async {
      await _retour(tester, ThemeMode.light, 'hors_salle_retour_390_light');
    });

    testWidgets('hors_salle_retour_390_dark', (WidgetTester tester) async {
      await _retour(tester, ThemeMode.dark, 'hors_salle_retour_390_dark');
    });

    testWidgets('hors_salle_retour_390_arabe', (WidgetTester tester) async {
      await _retour(
        tester,
        ThemeMode.light,
        'hors_salle_retour_390_arabe',
        arabe: true,
      );
    });

    testWidgets('hors_salle_son_bloque_reduit_390_light', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      final BancHorsSalle b = await monterHorsSalle(
        tester,
        cadre: cadreCapture,
      );
      b.moteur.bloquerSon(bloque: true);
      await reduireSalle(tester, b);
      await stabiliser(tester);
      expect(find.text(t.salle.sonBloque), findsOneWidget);
      debugPrint(
        'PNG ${await capturer(tester, 'hors_salle_son_bloque_reduit_390_light')}',
      );
    });
  });
}
