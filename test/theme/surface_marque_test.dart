import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import 'support/contraste.dart';

Color _encre(AppInkColor encre) => encre.asBorderSide().color;

/// La surface pleine de marque (connexion, fiche du 25/10/2026) et la palette
/// des contenus poses dessus : contrastes mesures, meme valeur dans les deux
/// themes.
void main() {
  final AppColorPair marque = AppPalette.claire().surfaceMarque;
  final AppPalette sur = AppPalette.surMarque();

  test('violet #6538E4 a encre blanche, identique en clair et en sombre', () {
    expect(marque.background, const Color(0xFF6538E4));
    expect(marque.onBackground, const Color(0xFFFFFFFF));
    expect(AppPalette.sombre().surfaceMarque.background, marque.background);
    expect(AppPalette.sombre().surfaceMarque.onBackground, marque.onBackground);
    // Fiche, section 6 : 6,5:1.
    expect(
      contraste(marque.onBackground, marque.background),
      closeTo(6.5, 0.05),
    );
  });

  test('texte de la palette posee sur la marque : 4,5:1 au moins', () {
    for (final (String nom, AppInkColor encre) in <(String, AppInkColor)>[
      ('inkStrong', sur.inkStrong),
      ('inkMuted', sur.inkMuted),
      ('inkAccent', sur.inkAccent),
      ('inkAlert', sur.inkAlert),
    ]) {
      expect(
        contraste(_encre(encre), marque.background),
        greaterThanOrEqualTo(seuilTexte),
        reason: '$nom sur la marque',
      );
    }
    for (final (String nom, AppColorPair paire) in <(String, AppColorPair)>[
      ('surfaceCanvas', sur.surfaceCanvas),
      ('surfaceRaised', sur.surfaceRaised),
      ('surfaceSunken', sur.surfaceSunken),
      ('surfacePrimary', sur.surfacePrimary),
      ('surfaceActionDouce', sur.surfaceActionDouce),
      ('washAccent', sur.washAccent),
    ]) {
      expect(
        contraste(paire.onBackground, paire.background),
        greaterThanOrEqualTo(seuilTexte),
        reason: nom,
      );
    }
  });

  test('composants sur la marque : 3:1 au moins (WCAG 1.4.11)', () {
    // Le filet d'un bouton secondaire, le fond d'un bouton plein, le rail
    // du controle segmente : chacun se detache du violet.
    expect(
      contraste(_encre(sur.borderStrong), marque.background),
      greaterThanOrEqualTo(seuilComposant),
    );
    expect(
      contraste(sur.surfacePrimary.background, marque.background),
      greaterThanOrEqualTo(seuilComposant),
    );
    expect(
      contraste(sur.washAccent.background, sur.surfaceSunken.background),
      greaterThanOrEqualTo(seuilComposant),
    );
  });

  test('le theme de la palette posee sur la marque ecrit en blanc', () {
    final ThemeData theme = AppTheme.depuis(
      sur,
      InterfaceMode.standard,
      Brightness.dark,
    );
    expect(theme.extension<AppPalette>(), sur);
    expect(theme.textTheme.bodyMedium?.color, marque.onBackground);
    expect(theme.scaffoldBackgroundColor, marque.background);
  });

  test('AppTheme.pour garde la palette de chaque theme', () {
    expect(
      AppTheme.pour(
        InterfaceMode.standard,
        Brightness.light,
      ).extension<AppPalette>()?.surfaceCanvas,
      AppPalette.claire().surfaceCanvas,
    );
    expect(
      AppTheme.pour(
        InterfaceMode.standard,
        Brightness.dark,
      ).extension<AppPalette>()?.surfaceCanvas,
      AppPalette.sombre().surfaceCanvas,
    );
  });
}
