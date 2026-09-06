import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';

/// Rapport de contraste WCAG entre deux couleurs.
///
/// `Color.computeLuminance` implemente deja la luminance relative de la norme :
/// on ne la reecrit pas, on l'utilise.
double contraste(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double clair = la > lb ? la : lb;
  final double sombre = la > lb ? lb : la;
  return (clair + 0.05) / (sombre + 0.05);
}

void main() {
  final AppPalette palette = AppPalette.claire();

  group('Scenario 1 : aucune paire de texte ne descend sous 4.5:1', () {
    final Map<String, AppColorPair> paires = <String, AppColorPair>{
      'surfaceBase': palette.surfaceBase,
      'surfacePrimary': palette.surfacePrimary,
      'surfaceSuccess': palette.surfaceSuccess,
      'surfaceWarning': palette.surfaceWarning,
      'surfaceAlert': palette.surfaceAlert,
    };

    for (final MapEntry<String, AppColorPair> e in paires.entries) {
      test('${e.key} mesure au moins 4.5:1', () {
        final double mesure = contraste(
          e.value.background,
          e.value.onBackground,
        );
        expect(
          mesure,
          greaterThanOrEqualTo(4.5),
          reason:
              '${e.key} mesure ${mesure.toStringAsFixed(2)}:1. '
              'La paire est illisible, corriger le jeton dans AppPalette.',
        );
      });
    }

    test('textOnLightAccent est lisible sur le fond general', () {
      final double mesure = contraste(
        palette.textOnLightAccent.debugValue,
        palette.surfaceBase.background,
      );
      expect(mesure, greaterThanOrEqualTo(4.5));
    });
  });

  group('Les echecs mesures dans les specs sont bien evites', () {
    test('surfaceSuccess ne porte jamais de texte blanc', () {
      // La charte d'origine mesurait 1.46:1 avec du blanc.
      final double avecBlanc = contraste(
        palette.surfaceSuccess.background,
        const Color(0xFFFFFFFF),
      );
      expect(avecBlanc, lessThan(4.5));
      expect(palette.surfaceSuccess.onBackground, isNot(const Color(0xFFFFFFFF)));
    });

    test('surfaceWarning ne porte jamais de texte blanc', () {
      // La charte d'origine mesurait 1.75:1 avec du blanc.
      final double avecBlanc = contraste(
        palette.surfaceWarning.background,
        const Color(0xFFFFFFFF),
      );
      expect(avecBlanc, lessThan(4.5));
      expect(palette.surfaceWarning.onBackground, isNot(const Color(0xFFFFFFFF)));
    });

    test('surfaceAlert corrige bien le rouge d origine', () {
      // L'original 0xFFFF385C echouait a 3.51:1 sur du blanc.
      final double original = contraste(
        const Color(0xFFFF385C),
        const Color(0xFFFFFFFF),
      );
      final double corrige = contraste(
        palette.surfaceAlert.background,
        palette.surfaceAlert.onBackground,
      );
      expect(original, lessThan(4.5));
      expect(corrige, greaterThan(original));
    });
  });

  group('borderDefault : mesure consignee, garde-fou de non-regression', () {
    // Ce jeton est DECORATIF. Il ne passe pas le seuil de 3:1 des elements non
    // textuels (WCAG 1.4.11) et ne doit donc jamais porter seul le sens d'un
    // controle ou d'un etat. Le test fige la mesure : si quelqu'un l'assombrit
    // pour le rendre porteur, il devra aussi lever la borne de ce test, donc
    // decider consciemment.
    test('la bordure reste au niveau consigne, et pas en dessous', () {
      final double mesure = contraste(
        palette.borderDefault.debugValue,
        palette.surfaceBase.background,
      );
      expect(
        mesure,
        greaterThanOrEqualTo(1.85),
        reason:
            'La bordure est descendue a ${mesure.toStringAsFixed(2)}:1, '
            'sous la valeur deja faible du jeton livre.',
      );
      expect(
        mesure,
        lessThan(3.0),
        reason:
            'La bordure atteint desormais ${mesure.toStringAsFixed(2)}:1. '
            'Elle peut devenir porteuse de sens : mettre a jour '
            'AppPalette.borderDefault et docs/architecture/etape-2-journal.md.',
      );
    });

    test('le focus et l erreur passent, eux, le seuil de 3:1', () {
      // Ce sont eux qui portent le sens a la place de la bordure.
      expect(
        contraste(
          palette.surfacePrimary.background,
          palette.surfaceBase.background,
        ),
        greaterThanOrEqualTo(3),
      );
      expect(
        contraste(
          palette.surfaceAlert.background,
          palette.surfaceBase.background,
        ),
        greaterThanOrEqualTo(3),
      );
    });
  });
}
