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
  final palette = AppPalette.sombre();

  test('les paires sombres semantiques restent lisibles', () {
    final paires = <AppColorPair>[
      palette.surfaceRaised,
      palette.surfaceCanvas,
      palette.surfaceSunken,
      palette.surfaceOverlay,
      palette.surfacePrimary,
      palette.surfaceAlert,
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

  test('le thème sombre est distinct et emploie les rôles R1', () {
    expect(palette.surfaceCanvas.background, const Color(0xFF111014));
    expect(palette.surfaceOverlay.background, const Color(0xFF2C2834));
    expect(palette.surfacePrimary.background, const Color(0xFFC9AEFF));
    expect(
      palette.surfaceCanvas.background,
      isNot(AppPalette.claire().surfaceCanvas.background),
    );
  });
}
