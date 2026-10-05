// EN-KB (E19) : raccourcis clavier de la salle enseignant sur bureau.
// M micro, V camera (couper seulement), R panneau Eleves, B selecteur de
// ressources, Echap ferme le panneau. Actifs seulement dans la salle, hors
// saisie, et quand la preference de `/compte/reglages` est active.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/libelles_salle_b.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/selecteur_ressources.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

/// Un hote qui tient l'etat de la salle, comme la demonstration.
class _Hote extends StatefulWidget {
  const _Hote({
    this.raccourcis,
    this.camera = true,
    this.avecChampExterne = false,
  });

  final bool? raccourcis;
  final bool camera;
  final bool avecChampExterne;

  @override
  State<_Hote> createState() => _HoteState();
}

final FocusNode _externe = FocusNode(debugLabel: 'hors-salle');

class _HoteState extends State<_Hote> {
  bool micro = true;
  late bool camera = widget.camera;
  PanneauOuvert panneau = PanneauOuvert.aucun;

  void _basculer(PanneauOuvert p) =>
      setState(() => panneau = panneau == p ? PanneauOuvert.aucun : p);

  @override
  Widget build(BuildContext context) {
    final Widget salle = SalleSeance(
      vue: DonneesSeanceDemo.vue(
        RoleSeance.enseignant,
        EtatDemoSalle.repos,
      ).copyWith(panneau: panneau),
      local: EtatLocalSeance(microOuvert: micro, cameraAllumee: camera),
      raccourcisClavier: widget.raccourcis,
      actions: ActionsSeance(
        onMicro: () => setState(() => micro = !micro),
        onCamera: () => setState(() => camera = !camera),
        onEleves: () => _basculer(PanneauOuvert.eleves),
        onSupports: () => _basculer(PanneauOuvert.supports),
        onBibliotheque: () => _basculer(PanneauOuvert.ressources),
      ),
    );
    if (!widget.avecChampExterne) return salle;
    return Column(
      children: <Widget>[
        TextButton(
          focusNode: _externe,
          onPressed: () {},
          child: const Text('x'),
        ),
        Expanded(child: salle),
      ],
    );
  }
}

_HoteState _etat(WidgetTester tester) =>
    tester.state<_HoteState>(find.byType(_Hote));

Future<void> _monter(
  WidgetTester tester,
  _Hote hote, {
  Size taille = const Size(1440, 900),
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(hoteCapture(hote));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _touche(WidgetTester tester, LogicalKeyboardKey cle) async {
  await tester.sendKeyEvent(cle);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('EN-KB raccourcis de la salle', () {
    testWidgets('M bascule le micro', (WidgetTester tester) async {
      await _monter(tester, const _Hote(raccourcis: true));
      await _touche(tester, LogicalKeyboardKey.keyM);
      expect(_etat(tester).micro, isFalse);
      await _touche(tester, LogicalKeyboardKey.keyM);
      expect(_etat(tester).micro, isTrue);
    });

    testWidgets('V coupe une camera allumee', (WidgetTester tester) async {
      await _monter(tester, const _Hote(raccourcis: true));
      await _touche(tester, LogicalKeyboardKey.keyV);
      expect(_etat(tester).camera, isFalse);
      // Une seconde pression ne la rallume jamais.
      await _touche(tester, LogicalKeyboardKey.keyV);
      expect(_etat(tester).camera, isFalse);
    });

    testWidgets("V n'allume jamais une camera eteinte", (
      WidgetTester tester,
    ) async {
      await _monter(tester, const _Hote(raccourcis: true, camera: false));
      await _touche(tester, LogicalKeyboardKey.keyV);
      expect(_etat(tester).camera, isFalse);
    });

    testWidgets('B ouvre le selecteur, Echap le ferme sans quitter', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const _Hote(raccourcis: true));
      await _touche(tester, LogicalKeyboardKey.keyB);
      expect(_etat(tester).panneau, PanneauOuvert.ressources);
      expect(find.byType(SelecteurRessources), findsOneWidget);
      await _touche(tester, LogicalKeyboardKey.escape);
      expect(_etat(tester).panneau, PanneauOuvert.aucun);
      expect(find.byType(SelecteurRessources), findsNothing);
      expect(find.byType(SalleSeance), findsOneWidget);
    });

    testWidgets('R ramene le panneau Eleves', (WidgetTester tester) async {
      await _monter(tester, const _Hote(raccourcis: true));
      await _touche(tester, LogicalKeyboardKey.keyB);
      expect(_etat(tester).panneau, PanneauOuvert.ressources);
      await _touche(tester, LogicalKeyboardKey.keyR);
      expect(_etat(tester).panneau, PanneauOuvert.eleves);
    });

    testWidgets('rien quand un champ de texte a le focus', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const _Hote(raccourcis: true));
      await _touche(tester, LogicalKeyboardKey.keyB);
      await tester.tap(
        find.descendant(
          of: find.byType(SelecteurRessources),
          matching: find.byType(TextField),
        ),
      );
      await tester.pump();
      for (final LogicalKeyboardKey cle in <LogicalKeyboardKey>[
        LogicalKeyboardKey.keyM,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyR,
        LogicalKeyboardKey.keyB,
      ]) {
        await _touche(tester, cle);
      }
      final _HoteState etat = _etat(tester);
      expect(etat.micro, isTrue);
      expect(etat.camera, isTrue);
      expect(etat.panneau, PanneauOuvert.ressources);
    });

    testWidgets('rien quand le reglage est desactive', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const _Hote());
      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(SalleSeance)),
      );
      conteneur
          .read(preferencesLocalesProvider.notifier)
          .raccourcisSalle(false);
      await tester.pump();
      for (final LogicalKeyboardKey cle in <LogicalKeyboardKey>[
        LogicalKeyboardKey.keyM,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyB,
      ]) {
        await _touche(tester, cle);
      }
      final _HoteState etat = _etat(tester);
      expect(etat.micro, isTrue);
      expect(etat.camera, isTrue);
      expect(etat.panneau, PanneauOuvert.aucun);
      // Reactive : la preference (par defaut active) agit de nouveau.
      conteneur.read(preferencesLocalesProvider.notifier).raccourcisSalle(true);
      await tester.pump();
      await _touche(tester, LogicalKeyboardKey.keyM);
      expect(_etat(tester).micro, isFalse);
    });

    testWidgets('rien hors de la salle', (WidgetTester tester) async {
      await _monter(
        tester,
        const _Hote(raccourcis: true, avecChampExterne: true),
      );
      _externe.requestFocus();
      await tester.pump();
      for (final LogicalKeyboardKey cle in <LogicalKeyboardKey>[
        LogicalKeyboardKey.keyM,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyB,
      ]) {
        await _touche(tester, cle);
      }
      final _HoteState etat = _etat(tester);
      expect(etat.micro, isTrue);
      expect(etat.camera, isTrue);
      expect(etat.panneau, PanneauOuvert.aucun);
    });

    testWidgets('rien sur telephone', (WidgetTester tester) async {
      await _monter(
        tester,
        const _Hote(raccourcis: true),
        taille: const Size(390, 844),
      );
      await _touche(tester, LogicalKeyboardKey.keyM);
      await _touche(tester, LogicalKeyboardKey.keyV);
      expect(_etat(tester).micro, isTrue);
      expect(_etat(tester).camera, isTrue);
    });
  });

  group('EN-KB reglage', () {
    testWidgets('la ligne des raccourcis bascule la preference locale', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 2400), 1);
      await tester.pumpWidget(
        hoteCapture(
          const ReglagesComptePage(),
          surcharges: <Override>[
            sourceSessionProvider.overrideWithValue(FausseSourceSession()),
          ],
        ),
      );
      await tester.pump();
      expect(find.text(LibellesSalleB.raccourcisTitre), findsOneWidget);
      expect(find.text(LibellesSalleB.raccourcisDetail), findsOneWidget);
      final Finder bascule = find.descendant(
        of: find.byKey(const ValueKey<String>('reglage-raccourcis-salle')),
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(bascule);
      await tester.tap(bascule);
      await tester.pump();
      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(ReglagesComptePage)),
      );
      expect(conteneur.read(preferencesLocalesProvider).raccourcisSalle, false);
    });
  });

  group('Capture : EN-KB', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String theme = mode == ThemeMode.light ? 'clair' : 'sombre';
        testWidgets('enkb $nom $theme', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, 1);
          await tester.pumpWidget(
            hoteCapture(
              const ReglagesComptePage(),
              themeMode: mode,
              surcharges: <Override>[
                sourceSessionProvider.overrideWithValue(FausseSourceSession()),
              ],
            ),
          );
          await stabiliser(tester);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey<String>('reglage-raccourcis-salle')),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'enkb_reglage_${nom}_$theme')}',
          );
        });
      }
    }
  });
}
