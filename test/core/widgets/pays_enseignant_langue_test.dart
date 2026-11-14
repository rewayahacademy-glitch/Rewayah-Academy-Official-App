// DRAPEAUX-bis (FINITION 22 b, 06/11/2026) : le nom du pays d'un enseignant,
// stocke en clair et en francais (FORM-L8), se lit dans la langue de l'ecran.
// Avant, l'arabe gardait « Côte d'Ivoire » en lettres latines (garde-cap,
// 04/11). Un nom que la table ne connait pas reste tel quel.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/pays_enseignant.dart';

import '../../support/harnais.dart';

Future<void> _monter(WidgetTester tester, String pays) async {
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: Center(child: PaysEnseignant(pays: pays)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // L'arabe est un morceau differe : il se charge une fois, puis se choisit.
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('le nom stocke en francais suit la langue de l ecran', () {
    testWidgets('francais : « Côte d\'Ivoire » reste « Côte d\'Ivoire »', (
      WidgetTester tester,
    ) async {
      LocaleSettings.setLocaleSync(AppLocale.fr);
      await _monter(tester, "Côte d'Ivoire");
      expect(find.text("Côte d'Ivoire"), findsOneWidget);
      expect(find.byKey(PaysEnseignant.drapeauKey), findsOneWidget);
    });

    testWidgets('arabe : « Côte d\'Ivoire » se lit « ساحل العاج », drapeau '
        'garde', (WidgetTester tester) async {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      await _monter(tester, "Côte d'Ivoire");
      expect(find.text('ساحل العاج'), findsOneWidget);
      expect(find.text("Côte d'Ivoire"), findsNothing);
      expect(find.byKey(PaysEnseignant.drapeauKey), findsOneWidget);
    });

    testWidgets('arabe : un pays hors des 19 de FORM-L8, reconnu par la liste '
        'ISO', (WidgetTester tester) async {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      await _monter(tester, 'Japon');
      expect(find.text('Japon'), findsNothing);
      expect(nomPaysDansLaLangue('Japon'), isNot('Japon'));
    });

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      testWidgets('${langue.languageCode} : un nom inconnu reste tel quel, '
          'sans drapeau', (WidgetTester tester) async {
        LocaleSettings.setLocaleSync(langue);
        await _monter(tester, 'Royaume de Tartempion');
        expect(find.text('Royaume de Tartempion'), findsOneWidget);
        expect(find.byKey(PaysEnseignant.drapeauKey), findsNothing);
      });
    }
  });
}
