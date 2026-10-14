import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/bouton_outil.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';

import '../../support/harnais.dart';

/// CLAVIER-ENTREE-1 (WCAG 2.1.1) : Entree, Entree du pave numerique et Espace
/// activent un [Pressable], une fois par appui, sur le Web comme ailleurs.
///
/// Le defaut relu par PUB-1b : sur le Web, Flutter ne lie pas Entree a
/// `ActivateIntent` mais a `ButtonActivateIntent`
/// (`WidgetsApp._defaultWebShortcuts`, « on the web, enter activates buttons,
/// but not other controls »). `Pressable` n'ecoutait que `ActivateIntent` :
/// seule la barre d'espace le declenchait dans le navigateur.
///
/// `kIsWeb` est faux sous `flutter test` : la table du Web est donc recopiee
/// ici, a l'identique de Flutter 3.47, et passee a `MaterialApp.shortcuts`,
/// a la place de la table native. Elle REMPLACE la table de l'application :
/// posee seulement au-dessus du composant, une touche sans action retomberait
/// sur la table native (Entree -> `ActivateIntent`) et masquerait le defaut.
/// Les evenements sont de vrais evenements clavier (`sendKeyEvent` : appui
/// puis relachement, par le meme chemin que le materiel).
const Map<ShortcutActivator, Intent> _raccourcisDuWeb =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.space): PrioritizedIntents(
        orderedIntents: <Intent>[
          ActivateIntent(),
          ScrollIntent(
            direction: AxisDirection.down,
            type: ScrollIncrementType.page,
          ),
        ],
      ),
      SingleActivator(LogicalKeyboardKey.enter): ButtonActivateIntent(),
      SingleActivator(LogicalKeyboardKey.numpadEnter): ButtonActivateIntent(),
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
      SingleActivator(LogicalKeyboardKey.tab, shift: true):
          PreviousFocusIntent(),
    };

const List<LogicalKeyboardKey> _touches = <LogicalKeyboardKey>[
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.numpadEnter,
  LogicalKeyboardKey.space,
];

String _nom(LogicalKeyboardKey touche) => touche.debugName ?? touche.keyLabel;

/// Monte [enfant] dans le vrai theme, sous la table du Web si [web].
Future<void> _monter(
  WidgetTester tester,
  Widget enfant, {
  required bool web,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          shortcuts: web ? _raccourcisDuWeb : null,
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: Scaffold(body: Center(child: enfant)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Donne le focus au premier element focalisable, par la touche Tab.
Future<void> _tabuler(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
}

void main() {
  for (final bool web in <bool>[true, false]) {
    final String table = web ? 'raccourcis du Web' : 'raccourcis natifs';

    group('Pressable au clavier, $table', () {
      for (final LogicalKeyboardKey touche in _touches) {
        testWidgets('${_nom(touche)} active une fois par appui, '
            'jamais deux', (WidgetTester tester) async {
          int appuis = 0;
          await _monter(
            tester,
            Pressable(
              onPress: () => appuis++,
              libelleSemantique: 'Ouvrir',
              child: const SizedBox(width: 48, height: 48),
            ),
            web: web,
          );
          await _tabuler(tester);
          expect(
            FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<Pressable>(),
            isNotNull,
            reason: 'Tab doit poser le focus sur la zone pressable',
          );

          await tester.sendKeyEvent(touche);
          await tester.pumpAndSettle();
          expect(appuis, 1, reason: '${_nom(touche)} ($table)');

          await tester.sendKeyEvent(touche);
          await tester.pumpAndSettle();
          expect(appuis, 2, reason: 'un appui, une activation');
        });
      }

      testWidgets('une zone inactive ne se declenche a aucune touche', (
        WidgetTester tester,
      ) async {
        int appuis = 0;
        await _monter(
          tester,
          Column(
            children: <Widget>[
              Pressable(
                onPress: () => appuis++,
                actif: false,
                child: const SizedBox(width: 48, height: 48),
              ),
            ],
          ),
          web: web,
        );
        await _tabuler(tester);
        for (final LogicalKeyboardKey touche in _touches) {
          await tester.sendKeyEvent(touche);
          await tester.pumpAndSettle();
        }
        expect(appuis, 0);
      });
    });
  }

  // Les appelants de `lib/core/widgets` heritent du correctif : chacun est
  // rejoue avec la table du Web, Entree puis Entree du pave numerique.
  group('Appelants de Pressable, Entree sur le Web', () {
    final Map<String, Widget Function(VoidCallback)> appelants =
        <String, Widget Function(VoidCallback)>{
          'ActionPrincipale': (VoidCallback f) =>
              ActionPrincipale(libelle: 'Continuer', onPress: f),
          'LienFleche': (VoidCallback f) =>
              LienFleche(libelle: 'Voir le cahier', onPress: f),
          'AppCard': (VoidCallback f) =>
              AppCard(onPress: f, child: const Text('Carte')),
          'FilterPill': (VoidCallback f) =>
              FilterPill(libelle: 'Lundi', onPress: f),
          'SettingRow': (VoidCallback f) =>
              SettingRow(title: 'Notifications', onPress: f),
          'BoutonOutil': (VoidCallback f) => BoutonOutil(
            icone: AppIcons.accueil,
            libelle: 'Accueil',
            onPress: f,
          ),
        };

    for (final MapEntry<String, Widget Function(VoidCallback)> appelant
        in appelants.entries) {
      for (final LogicalKeyboardKey touche in <LogicalKeyboardKey>[
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.numpadEnter,
      ]) {
        testWidgets('${appelant.key} : ${_nom(touche)}', (
          WidgetTester tester,
        ) async {
          int appuis = 0;
          await _monter(tester, appelant.value(() => appuis++), web: true);
          await _tabuler(tester);
          await tester.sendKeyEvent(touche);
          await tester.pumpAndSettle();
          expect(appuis, 1, reason: appelant.key);
        });
      }
    }
  });
}
