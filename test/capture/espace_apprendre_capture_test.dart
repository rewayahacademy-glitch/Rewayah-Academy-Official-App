// ESPACE-APPRENDRE (lot 5, 12/11/2026) : l'espace « Apprendre » et ses trois
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
import 'package:rewayah_academy/core/apprendre/affichage_planche.dart';
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
  group('Capture ESPACE-APPRENDRE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

    for (final bool arabe in <bool>[false, true]) {
      final String langue = arabe ? 'ar' : 'fr';
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nomTheme = theme == ThemeMode.light ? 'clair' : 'sombre';
        for (final double largeur in <double>[390, 1440]) {
          final String l = '${largeur.toInt()}';
          testWidgets('adulte $langue $l $nomTheme : les trois onglets', (
            WidgetTester tester,
          ) async {
            if (arabe) {
              await tester.runAsync(
                () => LocaleSettings.setLocale(AppLocale.ar),
              );
            }
            await monterApprendre(
              tester,
              taille: Size(largeur, 2300),
              theme: theme,
              direction: arabe ? TextDirection.rtl : null,
              documents: documentsComplets(),
              suivi: SuiviLu(lectureDemo(dates: true)),
            );
            await tester.pump(const Duration(milliseconds: 600));
            debugPrint(
              'PNG ${await capturerVue(tester, 'adulte-bibliotheque-grille-$langue-$l-$nomTheme')}',
            );
            await preferer(tester, AffichagePlanche.liste);
            debugPrint(
              'PNG ${await capturerVue(tester, 'adulte-bibliotheque-liste-$langue-$l-$nomTheme')}',
            );
            await _onglet(tester, t.apprendre.sections.programme);
            debugPrint(
              'PNG ${await capturerVue(tester, 'adulte-programme-$langue-$l-$nomTheme')}',
            );
            await _onglet(tester, t.apprendre.sections.livret);
            debugPrint(
              'PNG ${await capturerVue(tester, 'adulte-livret-$langue-$l-$nomTheme')}',
            );
          });
        }
      }
    }

    // Anglais (fusion du 14/11/2026 : l'anglais est complet sur `main`) :
    // les trois onglets de l'adulte a 390, en clair, pour voir les textes en.
    testWidgets('adulte en 390 clair : les trois onglets', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      await monterApprendre(
        tester,
        taille: const Size(390, 2300),
        documents: documentsComplets(),
        suivi: SuiviLu(lectureDemo(dates: true)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      debugPrint(
        'PNG ${await capturerVue(tester, 'adulte-bibliotheque-grille-en-390-clair')}',
      );
      await _onglet(tester, t.apprendre.sections.programme);
      debugPrint(
        'PNG ${await capturerVue(tester, 'adulte-programme-en-390-clair')}',
      );
      await _onglet(tester, t.apprendre.sections.livret);
      debugPrint(
        'PNG ${await capturerVue(tester, 'adulte-livret-en-390-clair')}',
      );
    });

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      final String nomTheme = theme == ThemeMode.light ? 'clair' : 'sombre';
      for (final double largeur in <double>[390, 1440]) {
        final String l = '${largeur.toInt()}';
        testWidgets('mineur guide $l $nomTheme : les trois onglets', (
          WidgetTester tester,
        ) async {
          await monterApprendre(
            tester,
            profil: ProfilApprendre.mineurGuide,
            taille: Size(largeur, 2600),
            theme: theme,
            documents: documentsComplets(),
            // 10 ans et plus : le serveur dit eleve_voit_dates.
            suivi: SuiviLu(lectureDemo(dates: true)),
          );
          await tester.pump(const Duration(milliseconds: 600));
          debugPrint(
            'PNG ${await capturerVue(tester, 'mineur-bibliotheque-grille-fr-$l-$nomTheme')}',
          );
          await _onglet(tester, t.apprendre.sections.programme);
          debugPrint(
            'PNG ${await capturerVue(tester, 'mineur-programme-fr-$l-$nomTheme')}',
          );
          await _onglet(tester, t.apprendre.sections.livret);
          debugPrint(
            'PNG ${await capturerVue(tester, 'mineur-livret-fr-$l-$nomTheme')}',
          );
        });
      }
    }

    testWidgets('mineur de 6 a 9 ans : aucune date, 390 clair', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        taille: const Size(390, 2400),
        documents: documentsComplets(),
        suivi: SuiviLu(lectureDemo(dates: false)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await _onglet(tester, t.apprendre.sections.programme);
      debugPrint(
        'PNG ${await capturerVue(tester, 'mineur-6-9-programme-fr-390-clair')}',
      );
    });
  });
}
