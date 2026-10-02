// La salle de seance, vue eleve standard (T2) : presence et absence
// d'elements, sans debordement aux trois largeurs, vignette de ratio fixe,
// notice de visite, route de demonstration fermee en production.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vignette_video.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

void _rien() {}

const ActionsSeance _actions = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onMicro: _rien,
  onCamera: _rien,
  onAgrandir: _rien,
  onZoomMoins: _rien,
  onZoomPlus: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
);

const Map<String, Size> _tailles = <String, Size>{
  'mobile': Size(390, 844),
  'web etroit': Size(640, 1000),
  'desktop': Size(1440, 900),
};

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  EtatDemoSalle etat, {
  ThemeMode mode = ThemeMode.light,
  EtatLocalSeance local = const EtatLocalSeance(),
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      SalleSeance(
        vue: DonneesSeanceDemo.vue(RoleSeance.eleve, etat),
        actions: _actions,
        local: local,
      ),
      themeMode: mode,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  for (final MapEntry<String, Size> taille in _tailles.entries) {
    for (final EtatDemoSalle etat in <EtatDemoSalle>[
      EtatDemoSalle.repos,
      EtatDemoSalle.visite,
      EtatDemoSalle.rienPartage,
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('eleve ${etat.name}, ${taille.key}, ${mode.name} : '
            'aucun debordement, rien de reserve a l\'enseignant', (
          WidgetTester tester,
        ) async {
          await _monter(tester, taille.value, etat, mode: mode);
          expect(tester.takeException(), isNull);

          for (final String interdit in <String>[
            'Élèves',
            'Supports',
            'Réseau',
            'Pointeur',
            'Marquer',
            'Masquer',
            'Annoter',
            'Foyer',
            'min restantes',
            'Tuteur de',
            '‹',
            '›',
          ]) {
            expect(
              find.textContaining(interdit),
              findsNothing,
              reason: '« $interdit » ne doit pas paraitre',
            );
          }
          expect(
            find.byKey(const ValueKey<String>('pagination-support')),
            findsNothing,
          );
          // ETATS-BTN-1 : le mot d'etat des deux bascules, micro ouvert et
          // camera allumee par defaut.
          expect(find.text('Micro ouvert'), findsOneWidget);
          expect(find.text('Caméra allumée'), findsOneWidget);
          // Sans support, rien a agrandir.
          expect(
            find.text('Agrandir'),
            etat == EtatDemoSalle.rienPartage ? findsNothing : findsOneWidget,
          );
          expect(find.text('Quitter'), findsOneWidget);
        });
      }
    }

    testWidgets('indicateur et zoom local selon la largeur (${taille.key})', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille.value, EtatDemoSalle.repos);
      final bool desktop = taille.value.width >= 1200;
      expect(
        find.byKey(const ValueKey<String>('indicateur-page')),
        desktop ? findsOneWidget : findsNothing,
      );
      expect(find.text('1 / 12'), desktop ? findsOneWidget : findsNothing);
      expect(
        find.text('Zoom local, sans effet sur les autres'),
        desktop ? findsOneWidget : findsNothing,
      );
    });
  }

  testWidgets('la vignette garde son ratio a toutes les largeurs', (
    WidgetTester tester,
  ) async {
    final List<double> ratios = <double>[];
    for (final Size taille in _tailles.values) {
      await _monter(tester, taille, EtatDemoSalle.repos);
      final Size vignette = tester.getSize(
        find.byKey(const ValueKey<String>('vignette-video')),
      );
      ratios.add(vignette.width / vignette.height);
    }
    for (final double ratio in ratios) {
      expect(ratio, closeTo(MesuresVignette.ratio, 0.001));
    }
  });

  testWidgets('notice « Votre parent » seulement en visite, point clignotant', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900), EtatDemoSalle.repos);
    expect(find.text('Votre parent observe la séance.'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (Widget w) => w is PointEnregistrement && w.clignote,
      ),
      findsNothing,
    );

    await _monter(tester, const Size(1440, 900), EtatDemoSalle.visite);
    expect(find.text('Votre parent observe la séance.'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget w) => w is PointEnregistrement && w.clignote,
      ),
      findsOneWidget,
    );
  });

  testWidgets('Quitter demande confirmation', (WidgetTester tester) async {
    await _monter(tester, const Size(390, 844), EtatDemoSalle.repos);
    await tester.tap(find.text('Quitter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Vous pourrez revenir si la séance est encore ouverte.'),
      findsOneWidget,
    );
  });

  testWidgets('agrandi : le bouton devient « Reduire »', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const Size(390, 844),
      EtatDemoSalle.repos,
      local: const EtatLocalSeance(agrandi: true),
    );
    expect(find.text('Réduire'), findsOneWidget);
    expect(find.text('Agrandir'), findsNothing);
  });

  for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Quitter : combine en encre claire (${mode.name})', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const Size(390, 844),
        EtatDemoSalle.repos,
        mode: mode,
      );
      final IconTheme encre = tester.widget<IconTheme>(
        find
            .ancestor(
              of: find.byIcon(AppIcons.raccrocher.actif),
              matching: find.byType(IconTheme),
            )
            .first,
      );
      expect(encre.data.color, AppPalette.claire().surfaceAlert.onBackground);
      expect(encre.data.color!.computeLuminance(), greaterThan(0.9));
    });
  }

  test('/demo/salle absente en production, presente ailleurs', () {
    expect(routesDemoSalle('production'), isEmpty);
    expect(routesDemoSalle(' Production '), isEmpty);
    expect(routesDemoSalle(''), isEmpty);
    expect(routesDemoSalle('development'), hasLength(1));
  });
}
