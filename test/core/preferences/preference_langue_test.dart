// Lot 22 a, PREFERENCES-WEB : la langue choisie se garde d'une session a
// l'autre, et le stockage du web n'est plus une memoire perdue au
// rechargement.

import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/langue_demarrage.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';

ProviderContainer _conteneur(StockagePreferences stockage) {
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      stockagePreferencesProvider.overrideWithValue(stockage),
    ],
  );
  addTearDown(c.dispose);
  // Monte la persistance comme le fait RewayahApp.
  c.listen<void>(persistanceLangueProvider, (void _, void _) {});
  return c;
}

void main() {
  // LANGUES-1 : l'appareil de test annonce « en-US », desormais traduit ; ces
  // tests veulent une langue d'appareil inconnue, qui retombe sur le francais.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .localesTestValue = const <Locale>[
      Locale('es'),
    ];
  });
  tearDown(() async {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearLocalesTestValue();
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  test('une valeur persistee se relit, une valeur inconnue est ignoree', () {
    expect(PreferenceLangue.depuis('arabe'), PreferenceLangue.arabe);
    expect(PreferenceLangue.depuis('francais'), PreferenceLangue.francais);
    expect(PreferenceLangue.depuis('systeme'), PreferenceLangue.systeme);
    expect(PreferenceLangue.depuis('anglais'), PreferenceLangue.anglais);
    expect(PreferenceLangue.depuis('en'), isNull);
    expect(PreferenceLangue.depuis(null), isNull);
    expect(PreferenceLangue.systeme.langue, isNull);
    expect(PreferenceLangue.arabe.langue, AppLocale.ar);
    expect(PreferenceLangue.francais.langue, AppLocale.fr);
    expect(PreferenceLangue.anglais.langue, AppLocale.en);
  });

  test('un appareil en anglais suit l anglais (LANGUES-1)', () async {
    expect(langueDepuisEtiquettes(<String>['en-GB', 'fr']), AppLocale.en);
    expect(langueDepuisEtiquettes(<String>['es']), AppLocale.fr);
    await LocaleSettings.setLocale(AppLocale.en);
    expect(t.commun.langue.anglais, 'English');
    expect(t.connexion.titre, 'Sign in');
    // Une cle non traduite en anglais retombe sur le francais, jamais sur
    // une cle brute.
    expect(t.salle.seance.bibliotheque.presenter, isNotEmpty);
  });

  test('la langue ecrite est relue au lancement et appliquee', () async {
    final StockagePreferencesMemoire stockage = StockagePreferencesMemoire(
      <String, String>{
        clefVersionPreferences: versionPreferences,
        clefPreferenceLangue: 'arabe',
      },
    );
    final ProviderContainer c = _conteneur(stockage);
    await pumpEventQueue();
    expect(c.read(preferencesLocalesProvider).langue, PreferenceLangue.arabe);
    expect(LocaleSettings.currentLocale, AppLocale.ar);

    c
        .read(preferencesLocalesProvider.notifier)
        .langue(PreferenceLangue.francais);
    await pumpEventQueue();
    expect(stockage.valeurs[clefPreferenceLangue], 'francais');
    expect(LocaleSettings.currentLocale, AppLocale.fr);
  });

  test('un choix fait pendant la lecture n est jamais ecrase', () async {
    final StockagePreferencesMemoire stockage = StockagePreferencesMemoire(
      <String, String>{
        clefVersionPreferences: versionPreferences,
        clefPreferenceLangue: 'arabe',
      },
    );
    final ProviderContainer c = _conteneur(stockage);
    c
        .read(preferencesLocalesProvider.notifier)
        .langue(PreferenceLangue.francais);
    await pumpEventQueue();
    expect(
      c.read(preferencesLocalesProvider).langue,
      PreferenceLangue.francais,
    );
    expect(stockage.valeurs[clefPreferenceLangue], 'francais');
  });

  test('« Systeme » applique la langue de l appareil', () async {
    expect(
      await appliquerPreferenceLangue(PreferenceLangue.arabe),
      AppLocale.ar,
    );
    expect(LocaleSettings.currentLocale, AppLocale.ar);
    // L'appareil de test parle anglais (non traduit) : retour au francais.
    expect(await appliquerPreferenceLangue(null), AppLocale.fr);
    expect(LocaleSettings.currentLocale, AppLocale.fr);
  });

  test('le stockage du navigateur range ses clefs sous un prefixe', () async {
    const StockagePreferencesNavigateur stockage =
        StockagePreferencesNavigateur();
    await stockage.ecrire(clefPreferenceTheme, 'sombre');
    expect(await stockage.lire(clefPreferenceTheme), 'sombre');
    expect(
      lireMemoireAppareil('rewayah.preferences.$clefPreferenceTheme'),
      'sombre',
    );
    expect(lireMemoireAppareil(clefPreferenceTheme), isNull);
    // Hors web, rien n'est lu avant le premier ecran : la base locale le fait.
    expect(langueMemoriseeAuDemarrage(), isNull);
  });
}
