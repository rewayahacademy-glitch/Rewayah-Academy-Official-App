import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_elevation.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_radius.dart';

void main() {
  final AppPalette palette = AppPalette.claire();

  group('Quatre niveaux, et ils montent', () {
    test('le niveau 0 ne porte aucune ombre', () {
      // Ce qui est pose a plat sur le fond : sections, separateurs.
      expect(AppElevation.niveau0, isEmpty);
    });

    test('chaque niveau porte plus loin que le precedent', () {
      double portee(List<BoxShadow> ombres) => ombres.isEmpty
          ? 0
          : ombres
                .map((BoxShadow o) => o.offset.dy + o.blurRadius)
                .reduce((double a, double b) => a > b ? a : b);

      expect(
        portee(AppElevation.niveau0),
        lessThan(portee(AppElevation.niveau1)),
      );
      expect(
        portee(AppElevation.niveau1),
        lessThan(portee(AppElevation.niveau2)),
      );
      expect(
        portee(AppElevation.niveau2),
        lessThan(portee(AppElevation.niveau3)),
      );
    });

    test('les compositions sont celles du tableau', () {
      expect(AppElevation.niveau1.length, 2);
      expect(AppElevation.niveau2.length, 2);
      expect(AppElevation.niveau3.length, 1);

      expect(AppElevation.niveau1.first.offset.dy, 1);
      expect(AppElevation.niveau1.first.blurRadius, 2);
      expect(AppElevation.niveau1.last.offset.dy, 2);
      expect(AppElevation.niveau1.last.blurRadius, 6);

      expect(AppElevation.niveau3.single.offset.dy, 12);
      expect(AppElevation.niveau3.single.blurRadius, 32);
    });
  });

  group('L ombre est chaude, jamais grise', () {
    test('sa couleur est celle de la palette, tiree vers le brun', () {
      // Une ombre grise neutre sur un fond creme se lit comme une salissure.
      final Color base = palette.ombre.debugValue;
      expect(base.r, greaterThan(base.g));
      expect(base.g, greaterThan(base.b));
    });

    test('toutes les ombres derivent de cette seule couleur', () {
      for (final BoxShadow o in <BoxShadow>[
        ...AppElevation.niveau1,
        ...AppElevation.niveau2,
        ...AppElevation.niveau3,
      ]) {
        final Color base = palette.ombre.debugValue;
        expect(o.color.r, closeTo(base.r, 0.001));
        expect(o.color.g, closeTo(base.g, 0.001));
        expect(o.color.b, closeTo(base.b, 0.001));
        // Une ombre opaque n'est plus une ombre.
        expect(o.color.a, lessThan(0.2));
      }
    });
  });

  group('Une surface elevee porte un filet ET une ombre', () {
    test('la decoration composee ne peut pas en oublier un des deux', () {
      // Le filet tient sur un ecran mal calibre et en contraste eleve, l ombre
      // donne la profondeur. Composer la decoration a la main permettait
      // d'oublier l'un des deux ; passer par avecFilet ne le permet pas.
      final BoxDecoration d = AppElevation.avecFilet(
        surface: palette.surfaceRaised,
        filet: palette.borderHairline,
        arrondi: AppRadius.arrondiMd,
      );

      expect(d.color, palette.surfaceRaised.background);
      expect(d.border, isNotNull);
      expect(d.boxShadow, isNotEmpty);
      expect(d.borderRadius, AppRadius.arrondiMd);
    });

    test('le niveau par defaut est celui des cartes', () {
      final BoxDecoration d = AppElevation.avecFilet(
        surface: palette.surfaceRaised,
        filet: palette.borderHairline,
        arrondi: AppRadius.arrondiMd,
      );
      expect(d.boxShadow, AppElevation.niveau1);
    });
  });
}
