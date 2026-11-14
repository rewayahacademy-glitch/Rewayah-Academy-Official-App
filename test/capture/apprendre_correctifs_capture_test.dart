// APPRENDRE-CORRECTIFS (14/11/2026) : onglets Programme (sourates seules, sans
// etape) et Bibliotheque (rayons dans la langue), en, fr, ar. Reprend le
// montage d'ESPACE-APPRENDRE (lot 5, 12/11/2026) : l'espace « Apprendre » et ses trois
// onglets, montes par le VRAI routeur, a 390 et 1440 points, en clair et en
// sombre, en francais et en arabe (de droite a gauche), grille et liste.
// Eleve adulte (interface standard) et eleve mineur (Interface guidee).
// Donnees de test seulement : la bibliotheque et la lecture du programme sont
// simulees ; rien ne vient de la production.
//
// Saute sans CAPTURE_DIR. Usage :
//   CAPTURE_DIR=docs/current/captures/E2E/espace-apprendre flutter test \
//     --no-pub test/capture/espace_apprendre_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/apprendre/espace_apprendre_page.dart';

import '../features/apprendre/support_apprendre.dart';
import '../router/support_routeur.dart' show stabiliser;
import 'outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;

Future<void> _onglet(WidgetTester tester, String libelle) async {
  final Finder direct = find.descendant(
    of: find.byKey(EspaceApprendrePage.cleSelecteur),
    matching: find.text(libelle),
  );
  if (direct.evaluate().isNotEmpty) {
    await tester.tap(direct.first);
  } else {
    await tester.tap(find.byKey(EspaceApprendrePage.cleSelecteur));
    await stabiliser(tester);
    await tester.tap(find.text(libelle).last);
  }
  await stabiliser(tester);
}

void main() {
  group('Capture APPRENDRE-CORRECTIFS', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

    for (final AppLocale loc in <AppLocale>[
      AppLocale.en,
      AppLocale.fr,
      AppLocale.ar,
    ]) {
      for (final (double largeur, ThemeMode theme, String nomTheme)
          in <(double, ThemeMode, String)>[
            (390, ThemeMode.light, 'clair'),
            (1440, ThemeMode.dark, 'sombre'),
          ]) {
        final String nom = '${loc.languageCode}-${largeur.toInt()}-$nomTheme';
        testWidgets('programme sans etape et bibliotheque $nom', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(loc));
          await monterApprendre(
            tester,
            taille: Size(largeur, 1400),
            theme: theme,
            direction: loc == AppLocale.ar ? TextDirection.rtl : null,
            documents: documentsComplets(),
            suivi: const SuiviLu(<String, Object?>{
              'sourates': <String, Object?>{
                'sourates_validees': 0,
                'sourates_total': 17,
              },
            }),
          );
          await tester.pump(const Duration(milliseconds: 600));
          debugPrint('PNG ${await capturerVue(tester, 'bibliotheque-$nom')}');
          await _onglet(tester, t.apprendre.sections.programme);
          expect(find.text(t.apprendre.programme.sansEtape), findsOneWidget);
          debugPrint('PNG ${await capturerVue(tester, 'programme-$nom')}');
        });
      }
    }
  });
}
