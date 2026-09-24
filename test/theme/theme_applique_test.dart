import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';

import '../support/harnais.dart';

/// Un stockage dont la lecture attend qu'on la libere : c'est ce qui permet de
/// jouer un choix de theme fait AVANT la fin de la lecture au lancement.
class _StockageLent implements StockagePreferences {
  final Completer<String?> lecture = Completer<String?>();
  final Map<String, String> ecrit = <String, String>{};

  @override
  Future<String?> lire(String clef) => lecture.future;

  @override
  Future<void> ecrire(String clef, String valeur) async {
    ecrit[clef] = valeur;
  }
}

/// Un stockage en panne : lecture et ecriture echouent.
class _StockageEnPanne implements StockagePreferences {
  @override
  Future<String?> lire(String clef) async => throw StateError('disque');

  @override
  Future<void> ecrire(String clef, String valeur) async =>
      throw StateError('disque');
}

ProviderContainer _conteneur(StockagePreferences stockage) {
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      stockagePreferencesProvider.overrideWithValue(stockage),
    ],
  );
  addTearDown(c.dispose);
  // Monte la persistance comme le fait RewayahApp.
  c.listen<void>(persistanceApparenceProvider, (void _, void _) {});
  return c;
}

void main() {
  group('une seule preference de theme, deux entrees', () {
    test('la luminosite affichee suit le choix, ou le systeme', () {
      expect(
        PreferenceTheme.systeme.luminosite(Brightness.dark),
        Brightness.dark,
      );
      expect(
        PreferenceTheme.systeme.luminosite(Brightness.light),
        Brightness.light,
      );
      expect(
        PreferenceTheme.clair.luminosite(Brightness.dark),
        Brightness.light,
      );
      expect(
        PreferenceTheme.sombre.luminosite(Brightness.light),
        Brightness.dark,
      );
      expect(PreferenceTheme.depuis('sombre'), PreferenceTheme.sombre);
      expect(PreferenceTheme.depuis('inconnu'), isNull);
      expect(PreferenceTheme.depuis(null), isNull);
    });

    test('la bascule d en-tete passe au theme oppose a celui affiche', () {
      final ProviderContainer c = _conteneur(StockagePreferencesMemoire());
      final PreferencesLocalesControleur controleur = c.read(
        preferencesLocalesProvider.notifier,
      );

      // Systeme, affiche en sombre : la bascule passe en clair.
      controleur.basculerClairSombre(Brightness.dark);
      expect(c.read(preferencesLocalesProvider).theme, PreferenceTheme.clair);
      expect(c.read(modeThemeProvider), ThemeMode.light);

      controleur.basculerClairSombre(Brightness.light);
      expect(c.read(preferencesLocalesProvider).theme, PreferenceTheme.sombre);
      expect(c.read(modeThemeProvider), ThemeMode.dark);

      // La page Apparence ecrit la meme preference, « Systeme » compris.
      controleur.theme(PreferenceTheme.systeme);
      expect(c.read(modeThemeProvider), ThemeMode.system);
    });
  });

  group('persistance sur l appareil', () {
    test('le theme ecrit est relu au lancement', () async {
      final StockagePreferencesMemoire stockage = StockagePreferencesMemoire(
        <String, String>{clefPreferenceTheme: 'sombre'},
      );
      final ProviderContainer c = _conteneur(stockage);
      await pumpEventQueue();
      expect(c.read(preferencesLocalesProvider).theme, PreferenceTheme.sombre);

      c.read(preferencesLocalesProvider.notifier).theme(PreferenceTheme.clair);
      await pumpEventQueue();
      expect(stockage.valeurs[clefPreferenceTheme], 'clair');
    });

    test('un choix fait pendant la lecture n est jamais ecrase', () async {
      final _StockageLent stockage = _StockageLent();
      final ProviderContainer c = _conteneur(stockage);

      c.read(preferencesLocalesProvider.notifier).theme(PreferenceTheme.clair);
      stockage.lecture.complete('sombre');
      await pumpEventQueue();

      expect(c.read(preferencesLocalesProvider).theme, PreferenceTheme.clair);
      expect(stockage.ecrit[clefPreferenceTheme], 'clair');
    });

    test('un stockage en panne laisse la preference en memoire', () async {
      final ProviderContainer c = _conteneur(_StockageEnPanne());
      await pumpEventQueue();
      expect(c.read(preferencesLocalesProvider).theme, PreferenceTheme.systeme);

      c.read(preferencesLocalesProvider.notifier).theme(PreferenceTheme.sombre);
      await pumpEventQueue();
      expect(c.read(preferencesLocalesProvider).theme, PreferenceTheme.sombre);
    });
  });

  group('RewayahApp applique la preference a MaterialApp', () {
    Future<ProviderContainer> monter(
      WidgetTester tester,
      StockagePreferences stockage,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          stockagePreferencesProvider.overrideWithValue(stockage),
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
          routeurProvider.overrideWithValue(
            GoRouter(
              routes: <RouteBase>[
                GoRoute(
                  path: '/',
                  builder: (BuildContext context, GoRouterState _) => Text(
                    'luminosite ${Theme.of(context).brightness.name}',
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: TranslationProvider(child: const RewayahApp()),
        ),
      );
      await tester.pump();
      return c;
    }

    testWidgets('Systeme par defaut, puis Apparence et bascule', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await monter(
        tester,
        StockagePreferencesMemoire(),
      );
      expect(find.text('luminosite light'), findsOneWidget);

      // Page Apparence : Sombre.
      c.read(preferencesLocalesProvider.notifier).theme(PreferenceTheme.sombre);
      await tester.pumpAndSettle();
      expect(find.text('luminosite dark'), findsOneWidget);

      // Bascule d'en-tete depuis le sombre affiche : retour au clair.
      c
          .read(preferencesLocalesProvider.notifier)
          .basculerClairSombre(Brightness.dark);
      await tester.pumpAndSettle();
      expect(find.text('luminosite light'), findsOneWidget);
    });

    testWidgets('le theme persiste est applique au lancement', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        StockagePreferencesMemoire(<String, String>{
          clefPreferenceTheme: 'sombre',
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('luminosite dark'), findsOneWidget);
    });
  });
}
