// LANGUE-INFORMATIONS-EN-DUR (garde-cap, 12/11/2026) : la page Informations
// du Compte dit la langue reellement choisie, la meme que la ligne « Langue »
// des Preferences, et non plus « Francais » ecrit en dur.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/compte/informations_page.dart';

import '../../capture/outil_capture.dart';
import 'support_compte.dart';

Finder _dansLaPage(String texte) => find.descendant(
  of: find.byType(InformationsComptePage),
  matching: find.text(texte),
);

Future<void> _langue(WidgetTester tester, AppLocale locale) async {
  await tester.runAsync(() => LocaleSettings.setLocale(locale));
  addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
}

void main() {
  group('LANGUE-INFORMATIONS-EN-DUR', () {
    testWidgets('en francais, la page dit « Français »', (
      WidgetTester tester,
    ) async {
      await _langue(tester, AppLocale.fr);
      await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('informations'),
      );
      expect(find.byType(InformationsComptePage), findsOneWidget);
      expect(_dansLaPage(t.commun.langue.francais), findsOneWidget);
      expect(_dansLaPage(t.commun.langue.arabe), findsNothing);
    });

    testWidgets('en arabe, la page dit l arabe, jamais le francais', (
      WidgetTester tester,
    ) async {
      await _langue(tester, AppLocale.ar);
      await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('informations'),
      );
      expect(find.byType(InformationsComptePage), findsOneWidget);
      expect(_dansLaPage(t.commun.langue.arabe), findsOneWidget);
      expect(_dansLaPage(t.compte.francais), findsNothing);
      expect(_dansLaPage(t.commun.langue.francais), findsNothing);
    });
  });

  group('Capture : LANGUE-INFORMATIONS-EN-DUR', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale locale in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final double largeur in <double>[390, 1440]) {
        final String nom =
            'informations_${locale.languageCode}_${largeur.toInt()}';
        testWidgets(nom, (WidgetTester tester) async {
          await _langue(tester, locale);
          await monterCompte(
            tester,
            depart: Routes.compteTuteurSousPage('informations'),
            taille: Size(largeur, 1000),
            direction: locale == AppLocale.ar
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
          debugPrint('PNG ${await capturerVue(tester, nom)}');
        });
      }
    }
  });
}
