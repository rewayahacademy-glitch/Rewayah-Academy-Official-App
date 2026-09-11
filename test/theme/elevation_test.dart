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
        lessThan(portee(AppElevation.niveau1(palette.ombre))),
      );
      expect(
        portee(AppElevation.niveau1(palette.ombre)),
        lessThan(portee(AppElevation.niveau2(palette.ombre))),
      );
      expect(
        portee(AppElevation.niveau2(palette.ombre)),
        lessThan(portee(AppElevation.niveau3(palette.ombre))),
      );
    });

    test('les compositions sont celles du tableau', () {
      expect(AppElevation.niveau1(palette.ombre).length, 2);
      expect(AppElevation.niveau2(palette.ombre).length, 2);
      expect(AppElevation.niveau3(palette.ombre).length, 1);

      expect(AppElevation.niveau1(palette.ombre).first.offset.dy, 1);
      expect(AppElevation.niveau1(palette.ombre).first.blurRadius, 2);
      expect(AppElevation.niveau1(palette.ombre).last.offset.dy, 2);
      expect(AppElevation.niveau1(palette.ombre).last.blurRadius, 6);

      expect(AppElevation.niveau3(palette.ombre).single.offset.dy, 12);
      expect(AppElevation.niveau3(palette.ombre).single.blurRadius, 32);
    });
  });

  group('L ombre est chaude, jamais grise', () {
    test('sa couleur est celle de la palette, tiree vers le brun', () {
      // Une ombre grise neutre sur un fond creme se lit comme une salissure.
      final Color base = palette.ombre.debugValue;
      expect(base.r, greaterThan(base.g));
      expect(base.g, greaterThan(base.b));
    });

    test('toutes les ombres derivent de la couleur DE LA PALETTE FOURNIE', () {
      // Depuis le lot T3, AppElevation ne tire plus silencieusement
      // AppPalette.claire().ombre : chaque niveau prend l'ombre en parametre.
      for (final BoxShadow o in <BoxShadow>[
        ...AppElevation.niveau1(palette.ombre),
        ...AppElevation.niveau2(palette.ombre),
        ...AppElevation.niveau3(palette.ombre),
      ]) {
        final Color base = palette.ombre.debugValue;
        expect(o.color.r, closeTo(base.r, 0.001));
        expect(o.color.g, closeTo(base.g, 0.001));
        expect(o.color.b, closeTo(base.b, 0.001));
        // Une ombre opaque n'est plus une ombre. Plafond remonte au lot T2
        // (0.2 -> 0.3) : niveau3 est passe a 0.22 pour se detacher enfin du
        // fond, cause n3 mesuree du rejet du 11 septembre 2026.
        expect(o.color.a, lessThan(0.3));
      }
    });

    test('la palette sombre fournit sa propre ombre, pas celle du clair', () {
      // Reutilisee a la meme valeur par choix documente (AppPalette.sombre),
      // mais via son propre champ : le mecanisme ne suppose plus une seule
      // palette possible.
      final AppPalette sombre = AppPalette.sombre();
      final BoxShadow o = AppElevation.niveau1(sombre.ombre).first;
      final Color base = sombre.ombre.debugValue;
      expect(o.color.r, closeTo(base.r, 0.001));
      expect(o.color.g, closeTo(base.g, 0.001));
      expect(o.color.b, closeTo(base.b, 0.001));
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
        ombre: palette.ombre,
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
        ombre: palette.ombre,
        arrondi: AppRadius.arrondiMd,
      );
      expect(d.boxShadow, AppElevation.niveau1(palette.ombre));
    });
  });
}
