import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';

double _contraste(Color a, Color b) {
  final clair = a.computeLuminance() > b.computeLuminance() ? a : b;
  final sombre = clair == a ? b : a;
  return (clair.computeLuminance() + 0.05) / (sombre.computeLuminance() + 0.05);
}

void main() {
  final palette = AppPalette.claire();

  test('les paires claires semantiques restent lisibles', () {
    final paires = <AppColorPair>[
      palette.surfaceRaised,
      palette.surfaceCanvas,
      palette.surfaceSunken,
      palette.surfacePrimary,
      palette.surfaceSuccess,
      palette.surfaceWarning,
      palette.surfaceAlert,
      palette.surfaceInverse,
      palette.washAccent,
      palette.washSuccess,
      palette.washWarning,
      palette.washAlert,
    ];
    for (final paire in paires) {
      expect(
        _contraste(paire.background, paire.onBackground),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('les roles R1 clair sont exacts', () {
    expect(palette.surfaceCanvas.background, const Color(0xFFF8F7FA));
    expect(palette.surfaceRaised.background, const Color(0xFFFFFFFF));
    expect(palette.surfaceSunken.background, const Color(0xFFF0EDF4));
    expect(palette.surfacePrimary.background, const Color(0xFF8652E6));
    expect(palette.inkAccent.debugValue, const Color(0xFF5B36B0));
  });
}
