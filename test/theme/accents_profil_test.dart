// K-62 (decision du directeur du 04/10/2026) : les accents de profil, seule
// exception de couleur apres le gel du theme (K-37). Ce test les FIGE et
// mesure ce qui compte : un accent par cle, distinct des teintes de classe et
// des couleurs de statut, visible sur la carte, encre lisible dessus.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/accent_profil.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';

import 'support/contraste.dart';

void main() {
  for (final (String nom, AppPalette p) in <(String, AppPalette)>[
    ('clair', AppPalette.claire()),
    ('sombre', AppPalette.sombre()),
  ]) {
    group('accents de profil, theme $nom', () {
      test('un accent par cle, dans l ordre de AccentProfil', () {
        expect(p.accentsProfil, hasLength(AccentProfil.values.length));
        for (final AccentProfil a in AccentProfil.values) {
          expect(p.accentProfil(a), same(p.accentsProfil[a.index]));
        }
      });

      test('six fonds tous differents', () {
        final Set<int> fonds = <int>{
          for (final AppColorPair c in p.accentsProfil) c.background.toARGB32(),
        };
        expect(fonds, hasLength(AccentProfil.values.length));
      });

      test('jamais une teinte de classe (teintesIdentite)', () {
        final Set<int> classes = <int>{
          for (final AppColorPair c in p.teintesIdentite)
            c.background.toARGB32(),
        };
        for (final AppColorPair c in p.accentsProfil) {
          expect(classes, isNot(contains(c.background.toARGB32())));
        }
      });

      test('encre posee sur l accent : 4,5:1 au moins', () {
        for (final AccentProfil a in AccentProfil.values) {
          final AppColorPair c = p.accentProfil(a);
          expect(
            contraste(c.onBackground, c.background),
            greaterThanOrEqualTo(4.5),
            reason: a.name,
          );
        }
      });

      test(
        'le bandeau se voit sur la carte (surfaceRaised) : 1,5:1 au moins',
        () {
          final Color carte = p.surfaceRaised.background;
          for (final AccentProfil a in AccentProfil.values) {
            expect(
              contraste(p.accentProfil(a).background, carte),
              greaterThanOrEqualTo(1.5),
              reason: a.name,
            );
          }
        },
      );
    });
  }

  test('valeurs figees (toute retouche passe par le directeur, K-62)', () {
    String hex(Color c) =>
        c.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0');
    expect(
      <String>[
        for (final AppColorPair c in AppPalette.claire().accentsProfil)
          hex(c.background),
      ],
      <String>[
        'FF8ED9BE',
        'FF93C5F0',
        'FFB7A3F3',
        'FFEE9DD8',
        'FFF2B58E',
        'FFD8C291',
      ],
    );
    expect(
      <String>[
        for (final AppColorPair c in AppPalette.sombre().accentsProfil)
          hex(c.background),
      ],
      <String>[
        'FFC8F2E2',
        'FFBEDDF7',
        'FFCDBDF9',
        'FFF4AEE6',
        'FFF7CDAF',
        'FFE9D9B3',
      ],
    );
  });

  test(
    'cle inconnue ou absente : aucun accent, jamais une couleur au hasard',
    () {
      expect(AccentProfil.depuisCle('rose'), AccentProfil.rose);
      expect(AccentProfil.depuisCle('#FF00FF'), isNull);
      expect(AccentProfil.depuisCle(null), isNull);
    },
  );
}
