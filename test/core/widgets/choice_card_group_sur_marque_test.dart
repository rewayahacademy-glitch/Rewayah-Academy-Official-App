// QUESTIONNAIRE-FIN (directeur, 04/11/2026) : la carte choisie se lit sur le
// violet de la marque. Sur la marque, la carte retenue devient blanche
// (`washAccent`) mais toutes les encres de la page sont blanches : la
// description et le repere disparaissaient. La carte prend desormais la
// palette de son fond : titre, description et repere lisibles (4,5:1 pour le
// texte, 3:1 pour le repere), sur la marque comme sur le clair et le sombre.
//
// Contre-epreuve : sur `main` (c0f36a01), `paletteDeCarte` n'existe pas et la
// description de la carte retenue est blanche sur blanc (1:1).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';

Color _c(AppInkColor e) => e.asBorderSide().color;

void main() {
  final Map<String, AppPalette> pages = <String, AppPalette>{
    'marque': AppPalette.surMarque(),
    'clair': AppPalette.claire(),
    'sombre': AppPalette.sombre(),
  };

  for (final MapEntry<String, AppPalette> page in pages.entries) {
    for (final bool retenue in <bool>[true, false]) {
      test('${page.key}, carte ${retenue ? 'retenue' : 'au repos'} : '
          'titre, description et repere lisibles', () {
        final AppColorPair paire = retenue
            ? page.value.washAccent
            : page.value.surfaceRaised;
        final AppPalette carte = paletteDeCarte(page.value, paire);
        final Color fond = paire.background;
        expect(contrasteEntre(_c(carte.inkStrong), fond), greaterThan(4.5));
        expect(contrasteEntre(_c(carte.inkMuted), fond), greaterThan(4.5));
        expect(contrasteEntre(_c(carte.inkAccent), fond), greaterThan(3));
      });
    }
  }

  test('le clair et le sombre gardent la palette de la page', () {
    for (final AppPalette page in <AppPalette>[
      AppPalette.claire(),
      AppPalette.sombre(),
    ]) {
      expect(identical(paletteDeCarte(page, page.washAccent), page), isTrue);
      expect(identical(paletteDeCarte(page, page.surfaceRaised), page), isTrue);
    }
  });

  test('sur la marque, la carte retenue est a encre violette', () {
    final AppPalette marque = AppPalette.surMarque();
    final AppPalette carte = paletteDeCarte(marque, marque.washAccent);
    expect(identical(carte, marque), isFalse);
    expect(_c(carte.inkMuted), marque.washAccent.onBackground);
  });
}
