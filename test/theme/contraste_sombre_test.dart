import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';

import 'support/contraste.dart';

void main() {
  final AppPalette palette = AppPalette.sombre();

  // Paires interdites mesurees le 24/09/2026 (revue phase 0, jetons D7) :
  // `inkAlert #F4777D` sur `washWarning #44361A` = 4,35:1 (9,09 avant la
  // palette ardoise), et `inkFaint` sur les fonds doux succes et attention.
  // Aucun usage connu ; a ne pas creer. Corriger la teinte reste une
  // decision de palette (decisions du coordinateur 3.1), pas de ce test.
  testsDeContraste(
    'sombre',
    palette,
    pairesInterditesSurFondsDoux: const <String>{
      'inkFaint / washSuccess',
      'inkFaint / washWarning',
      'inkAlert / washWarning',
    },
  );

  test('le sombre est une ardoise bleu-violet (decisions, section 3.1)', () {
    expect(palette.surfaceCanvas.background, const Color(0xFF1A1A25));
    expect(palette.surfaceRaised.background, const Color(0xFF22222E));
    expect(palette.surfaceOverlay.background, const Color(0xFF2B2B39));
    expect(palette.surfaceSunken.background, const Color(0xFF262534));
    expect(palette.borderHairline.debugValue, const Color(0xFF32323F));
    expect(palette.inkMuted.debugValue, const Color(0xFFAEB1CE));
    expect(palette.inkFaint.debugValue, const Color(0xFF9194B0));
    expect(palette.surfacePrimary.background, const Color(0xFFBA98FB));
    expect(palette.surfacePrimary.onBackground, const Color(0xFF25113F));
    expect(palette.inkAlert.debugValue, const Color(0xFFF4777D));
    expect(palette.surfaceMiseEnAvant.background, const Color(0xFF2B2B39));
    // Figee.
    expect(palette.surfaceQuran.background, const Color(0xFF2E2417));
    expect(palette.surfaceQuran.onBackground, const Color(0xFFF5F1E9));
    expect(
      palette.surfaceCanvas.background,
      isNot(AppPalette.claire().surfaceCanvas.background),
    );
  });

  test('en sombre, le CTA dominant est l accent plein', () {
    expect(palette.surfaceActionDouce, palette.surfacePrimary);
  });

  test('l interpolation clair vers sombre porte les nouveaux jetons', () {
    final AppPalette arrivee = AppPalette.claire().lerp(palette, 1);
    expect(arrivee.surfaceMiseEnAvant, palette.surfaceMiseEnAvant);
    expect(arrivee.surfaceActionDouce, palette.surfaceActionDouce);
    expect(arrivee.pointsStatut, palette.pointsStatut);
  });
}
