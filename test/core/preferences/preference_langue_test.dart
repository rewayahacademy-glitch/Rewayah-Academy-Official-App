// Lot 22 a, PREFERENCES-WEB : la langue choisie se garde d'une session a
// l'autre, et le stockage du web n'est plus une memoire perdue au
// rechargement.

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/selecteur_langue.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';

import '../../support/hote_theme.dart';

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
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  test('une valeur persistee se relit, une valeur inconnue est ignoree', () {
    expect(PreferenceLangue.depuis('arabe'), PreferenceLangue.arabe);
    expect(PreferenceLangue.depuis('francais'), PreferenceLangue.francais);
    expect(PreferenceLangue.depuis('systeme'), PreferenceLangue.systeme);
    expect(PreferenceLangue.depuis('en'), isNull);
    expect(PreferenceLangue.depuis(null), isNull);
    expect(PreferenceLangue.systeme.langue, isNull);
    expect(PreferenceLangue.arabe.langue, AppLocale.ar);
    expect(PreferenceLangue.francais.langue, AppLocale.fr);
  });

  test('la langue ecrite est relue au lancement et appliquee', () async {
    final StockagePreferencesMemoire stockage = StockagePreferencesMemoire(
      <String, String>{clefPreferenceLangue: 'arabe'},
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
      <String, String>{clefPreferenceLangue: 'arabe'},
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

  testWidgets('le selecteur montre les trois choix et ecrit la preference', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, vueMobile);
    await tester.pumpWidget(hoteTheme(const SelecteurLangue()));

    expect(find.text(t.commun.langue.contexte), findsOneWidget);
    for (final String detail in <String>[
      t.commun.langue.systemeDetail,
      t.commun.langue.francaisDetail,
      t.commun.langue.arabeDetail,
    ]) {
      expect(
        find.textContaining(detail, findRichText: true),
        findsOneWidget,
        reason: detail,
      );
    }

    await tester.tap(find.text('العربية'));
    await tester.pump();
    expect(
      ProviderScope.containerOf(tester.element(find.byType(SelecteurLangue)))
          .read(preferencesLocalesProvider)
          .langue,
      PreferenceLangue.arabe,
    );
  });
}
