import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/langue_demarrage.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

/// CLAVIER-ENTREE-1 (relecture PUB-1b) : l'application s'arretait au
/// demarrage avec la langue « en-US@posix » (`RangeError: Incorrect locale
/// information provided`, dans `LocaleSettings.useDeviceLocale`). Toute langue
/// systeme inconnue ou mal formee retombe sur le francais, sans lever.
void main() {
  group('langueDepuisEtiquettes', () {
    const List<String> malFormees = <String>[
      'en-US@posix',
      'en_US@posix',
      'C',
      'POSIX',
      'C.UTF-8',
      '',
      '   ',
      '@',
      '@posix',
      '.UTF-8',
      '-',
      '_',
      'x',
      'english',
      '12-34',
      'fr!FR',
      'und',
      'und-Latn',
      '\u0000',
      'zz-ZZ-garbage-1234567890',
      'de-DE',
      'en',
      'zh-Hant-TW',
    ];

    for (final String etiquette in malFormees) {
      test('« ${etiquette.replaceAll('\u0000', r'\0')} » retombe sur le '
          'francais', () {
        expect(langueDepuisEtiquettes(<String>[etiquette]), AppLocale.fr);
      });
    }

    test('aucune etiquette : le francais', () {
      expect(langueDepuisEtiquettes(const <String>[]), AppLocale.fr);
    });

    test('toutes mal formees, en liste : le francais', () {
      expect(langueDepuisEtiquettes(malFormees), AppLocale.fr);
    });

    test('les langues traduites restent reconnues, formes BCP 47 et POSIX', () {
      expect(langueDepuisEtiquettes(<String>['fr-FR']), AppLocale.fr);
      expect(langueDepuisEtiquettes(<String>['fr_CA.UTF-8']), AppLocale.fr);
      expect(langueDepuisEtiquettes(<String>['ar']), AppLocale.ar);
      expect(langueDepuisEtiquettes(<String>['ar-Arab-EG']), AppLocale.ar);
      expect(
        langueDepuisEtiquettes(<String>['ar_SA.UTF-8@posix']),
        AppLocale.ar,
      );
      expect(langueDepuisEtiquettes(<String>['AR-ma']), AppLocale.ar);
    });

    test("l'ordre de preference est respecte, les etiquettes illisibles "
        'sautees', () {
      expect(
        langueDepuisEtiquettes(<String>['en-US@posix', '', 'ar-MA', 'fr']),
        AppLocale.ar,
      );
      expect(
        langueDepuisEtiquettes(<String>['de', 'fr-BE', 'ar']),
        AppLocale.fr,
      );
    });
  });

  group('appliquerLangueDeLAppareil', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

    test('une lecture qui leve (comme le moteur Web sur « en-US@posix ») '
        'donne le francais, sans lever', () async {
      final AppLocale langue = await appliquerLangueDeLAppareil(
        lire: () => throw RangeError('Incorrect locale information provided'),
      );
      expect(langue, AppLocale.fr);
      expect(LocaleSettings.currentLocale, AppLocale.fr);
    });

    test('une erreur d argument est traitee de meme', () async {
      expect(
        await appliquerLangueDeLAppareil(
          lire: () => throw ArgumentError('Incorrect locale information'),
        ),
        AppLocale.fr,
      );
    });

    test('des langues lues mais inconnues ou vides : le francais', () async {
      for (final List<Locale> langues in <List<Locale>>[
        const <Locale>[],
        const <Locale>[Locale('und')],
        const <Locale>[Locale('en', 'US'), Locale('de')],
        const <Locale>[Locale.fromSubtags(languageCode: 'zz')],
      ]) {
        await LocaleSettings.setLocale(AppLocale.ar);
        expect(
          await appliquerLangueDeLAppareil(lire: () => langues),
          AppLocale.fr,
          reason: '$langues',
        );
        expect(LocaleSettings.currentLocale, AppLocale.fr);
      }
    });

    test("l'arabe de l'appareil est garde", () async {
      await LocaleSettings.setLocale(AppLocale.fr);
      expect(
        await appliquerLangueDeLAppareil(
          lire: () => const <Locale>[Locale('ar', 'EG')],
        ),
        AppLocale.ar,
      );
    });
  });

  testWidgets('au demarrage, les langues reelles du moteur de test, '
      'mal formees, ne font pas lever', (WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const <Locale>[
      Locale('en', 'US'),
      Locale.fromSubtags(languageCode: 'C'),
    ];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    late AppLocale langue;
    await tester.runAsync(() async {
      langue = await appliquerLangueDeLAppareil();
    });
    expect(langue, AppLocale.fr);
    LocaleSettings.setLocaleSync(AppLocale.fr);
  });
}
