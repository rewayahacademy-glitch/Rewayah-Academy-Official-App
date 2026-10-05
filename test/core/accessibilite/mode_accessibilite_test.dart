// MA-1b : le socle du Mode Accessibilite.
//
// 1. Un fournisseur unique dit « Mode Accessibilite actif », depuis
//    l'`InterfaceMode` existant du profil ou la surcharge de demonstration.
// 2. La preference locale « Reduire les animations » et le reglage systeme
//    (Android `disableAnimations`, iOS `reduceMotion`) sont poses UNE fois
//    sous `MaterialApp.builder` : `Mouvement.duree` et `AppMouvement.duree`
//    rendent zero dans la VRAIE racine `RewayahApp` (UX_REVIEW_06, V1).

import 'dart:ui' show AccessibilityFeatures;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/mouvement/mouvement.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';

import '../../support/harnais.dart';

class _SessionEnfant extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.student,
    interfaceMode: InterfaceMode.enfant,
  );
}

class _SessionStandard extends SessionControleur {
  @override
  SessionState build() =>
      const SessionState(resolue: true, role: AppRole.student);
}

/// Un conteneur sans serveur : session fixe, preferences en memoire.
ProviderContainer _conteneur({
  bool enfant = false,
  List<Override> autres = const <Override>[],
}) => ProviderContainer(
  overrides: <Override>[
    stockagePreferencesProvider.overrideWithValue(StockagePreferencesMemoire()),
    sessionProvider.overrideWith(
      enfant ? _SessionEnfant.new : _SessionStandard.new,
    ),
    ...autres,
  ],
);

/// Ce que les ecrans lisent, releve a chaque construction.
final List<Duration> _durees = <Duration>[];

void main() {
  group('fournisseur unique', () {
    test('suit InterfaceMode du profil', () {
      final ProviderContainer standard = _conteneur();
      addTearDown(standard.dispose);
      expect(standard.read(modeAccessibiliteActifProvider), isFalse);

      final ProviderContainer enfant = _conteneur(enfant: true);
      addTearDown(enfant.dispose);
      expect(enfant.read(modeAccessibiliteActifProvider), isTrue);
      expect(
        enfant.read(accessibiliteProvider).presentation,
        InterfaceMode.enfant,
      );
    });

    test('la surcharge de demonstration prime sur le profil', () {
      final ProviderContainer c = _conteneur(
        autres: <Override>[
          surchargePresentationProvider.overrideWithValue(InterfaceMode.enfant),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(modeAccessibiliteActifProvider), isTrue);
    });

    test('la preference locale arrive dans le meme etat', () {
      final ProviderContainer c = _conteneur();
      addTearDown(c.dispose);
      expect(c.read(accessibiliteProvider).animationsReduites, isFalse);
      c.read(preferencesLocalesProvider.notifier).animations(true);
      expect(c.read(accessibiliteProvider).animationsReduites, isTrue);
    });

    test('une seule source suffit pour reduire', () {
      for (final bool s in <bool>[false, true]) {
        for (final bool r in <bool>[false, true]) {
          for (final bool p in <bool>[false, true]) {
            expect(
              mouvementReduitCombine(
                systeme: s,
                reduceMotion: r,
                preference: p,
              ),
              s || r || p,
            );
          }
        }
      }
    });
  });

  group('mouvement reduit dans RewayahApp', () {
    Future<ProviderContainer> monter(WidgetTester tester) async {
      _durees.clear();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          stockagePreferencesProvider.overrideWithValue(
            StockagePreferencesMemoire(),
          ),
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
          routeurProvider.overrideWithValue(
            GoRouter(
              routes: <RouteBase>[
                GoRoute(
                  path: '/',
                  builder: (BuildContext context, GoRouterState _) {
                    _durees
                      ..add(Mouvement.duree(context, Mouvement.moyen))
                      ..add(AppMouvement.duree(context, AppMouvement.micro));
                    return const SizedBox.shrink();
                  },
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

    testWidgets('sans reglage, les durees voulues', (
      WidgetTester tester,
    ) async {
      await monter(tester);
      expect(_durees.last, AppMouvement.micro);
      expect(_durees[_durees.length - 2], Mouvement.moyen);
    });

    testWidgets('la preference locale seule met toute duree a zero', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await monter(tester);
      c.read(preferencesLocalesProvider.notifier).animations(true);
      await tester.pump();
      expect(_durees.last, Duration.zero);
      expect(_durees[_durees.length - 2], Duration.zero);
    });

    testWidgets('reduceMotion (iOS) seul met toute duree a zero', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await monter(tester);
      final AccessibilityFeatures f =
          tester.platformDispatcher.accessibilityFeatures;
      expect(f.reduceMotion, isTrue);
      expect(_durees.last, Duration.zero);
      expect(_durees[_durees.length - 2], Duration.zero);
    });

    testWidgets('disableAnimations du systeme seul met toute duree a zero', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await monter(tester);
      expect(_durees.last, Duration.zero);
      expect(_durees[_durees.length - 2], Duration.zero);
    });
  });
}
