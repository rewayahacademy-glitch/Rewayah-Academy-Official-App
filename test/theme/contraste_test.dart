import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';

import 'support/contraste.dart';

void main() {
  final AppPalette palette = AppPalette.claire();

  testsDeContraste('clair', palette);

  test('les valeurs claires sont celles des decisions du 24/09 (3.1)', () {
    // Gardees.
    expect(palette.surfaceCanvas.background, const Color(0xFFF8F7FA));
    expect(palette.surfaceRaised.background, const Color(0xFFFFFFFF));
    expect(palette.surfaceSunken.background, const Color(0xFFF0EDF4));
    expect(palette.surfacePrimary.background, const Color(0xFF8652E6));
    expect(palette.inkMuted.debugValue, const Color(0xFF655E70));
    // Ajustees.
    expect(palette.inkStrong.debugValue, const Color(0xFF110E20));
    expect(palette.surfaceCanvas.onBackground, const Color(0xFF110E20));
    expect(palette.inkFaint.debugValue, const Color(0xFF6A687E));
    expect(palette.inkAccent.debugValue, const Color(0xFF6538E4));
    expect(palette.washWarning.background, const Color(0xFFFEF5E4));
    expect(palette.washWarning.onBackground, const Color(0xFF755200));
    expect(palette.inkAlert.debugValue, const Color(0xFFC21D3D));
    // Ajoutees.
    expect(palette.surfaceMiseEnAvant.background, const Color(0xFFF7F5FE));
    expect(palette.surfaceActionDouce.background, const Color(0xFFDCCAFD));
    expect(
      palette.surfaceActionDouce.onBackground,
      palette.inkStrong.debugValue,
    );
    // Figee.
    expect(palette.surfaceQuran.background, const Color(0xFFF3EAD9));
    expect(palette.surfaceQuran.onBackground, const Color(0xFF1C1D21));
  });

  test('le CTA dominant clair est doux, jamais l aplat violet', () {
    expect(
      palette.surfaceActionDouce.background,
      isNot(palette.surfacePrimary.background),
    );
  });
}
