import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';

import 'contraste_test.dart' show contraste, tolerance;

/// Rejoue les mesures de [AppPalette.sombre] (lot T3, Bible V2 section 7.3,
/// ADR-019, ecart 23 de `decisions.md`).
///
/// **Aucune mesure ici ne vient de `contraste_test.dart`** : la palette
/// sombre a ete calculee independamment, avec la meme formule WCAG
/// (`contraste`, importee mais pas les valeurs). Ce fichier est la preuve que
/// « toutes les mesures seront refaites » (ecart 23) n'est pas restee un
/// voeu.
void main() {
  final AppPalette palette = AppPalette.sombre();
  final Color canevas = palette.surfaceCanvas.background;
  final Color eleve = palette.surfaceRaised.background;
  final Color enfonce = palette.surfaceSunken.background;

  group('Aucune paire du theme sombre ne descend sous 4.5:1', () {
    final Map<String, AppColorPair> paires = <String, AppColorPair>{
      'surfaceRaised': palette.surfaceRaised,
      'surfaceCanvas': palette.surfaceCanvas,
      'surfaceSunken': palette.surfaceSunken,
      'surfacePrimary': palette.surfacePrimary,
      'surfaceSuccess': palette.surfaceSuccess,
      'surfaceWarning': palette.surfaceWarning,
      'surfaceAlert': palette.surfaceAlert,
      'surfaceInverse': palette.surfaceInverse,
      'washAccent': palette.washAccent,
      'washSuccess': palette.washSuccess,
      'washWarning': palette.washWarning,
      'washAlert': palette.washAlert,
      'washFamily': palette.washFamily,
      'surfaceQuran': palette.surfaceQuran,
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
              '${e.key} mesure ${mesure.toStringAsFixed(2)}:1 sur la palette '
              'sombre. La paire est illisible, corriger le jeton dans '
              'AppPalette.sombre.',
        );
      });
    }
  });

  group('Les mesures inscrites au tableau des jetons sombres sont exactes', () {
    void mesure(String nom, double attendu, Color a, Color b) {
      test('$nom vaut $attendu', () {
        expect(
          contraste(a, b),
          closeTo(attendu, tolerance),
          reason:
              '$nom mesure ${contraste(a, b).toStringAsFixed(2)} et non '
              '$attendu : AppPalette.sombre a change sans que sa mesure ne '
              'suive.',
        );
      });
    }

    // Rampe neutre, mesuree entre les trois plans (le canevas est la
    // reference, comme le creme cote clair).
    mesure('surfaceRaised sur le canevas', 1.24, eleve, canevas);
    mesure('surfaceSunken sur le canevas', 1.12, enfonce, canevas);
    mesure(
      'borderHairline sur le canevas',
      1.44,
      palette.borderHairline.debugValue,
      canevas,
    );
    mesure(
      'borderResting sur le canevas',
      1.81,
      palette.borderResting.debugValue,
      canevas,
    );
    mesure(
      'borderStrong sur le canevas',
      6.13,
      palette.borderStrong.debugValue,
      canevas,
    );
    mesure(
      'inkFaint sur le canevas',
      6.00,
      palette.inkFaint.debugValue,
      canevas,
    );
    mesure(
      'inkMuted sur le canevas',
      9.28,
      palette.inkMuted.debugValue,
      canevas,
    );
    mesure(
      'inkStrong sur le canevas',
      14.95,
      palette.inkStrong.debugValue,
      canevas,
    );

    // Paires pleines : reutilisees telles quelles (voir AppPalette.sombre),
    // revalidees ici plutot que supposees.
    mesure(
      'surfacePrimary',
      4.81,
      palette.surfacePrimary.background,
      palette.surfacePrimary.onBackground,
    );
    mesure(
      'surfaceSuccess',
      11.55,
      palette.surfaceSuccess.background,
      palette.surfaceSuccess.onBackground,
    );
    mesure(
      'surfaceWarning',
      9.64,
      palette.surfaceWarning.background,
      palette.surfaceWarning.onBackground,
    );
    mesure(
      'surfaceAlert',
      6.84,
      palette.surfaceAlert.background,
      palette.surfaceAlert.onBackground,
    );
    // Inversee par rapport au clair (creme+noir au lieu de noir+creme) mais
    // la meme paire de teintes : la mesure reste 15.37, exacte au clair.
    mesure(
      'surfaceInverse',
      15.37,
      palette.surfaceInverse.background,
      palette.surfaceInverse.onBackground,
    );

    // Paires douces : l'encre sur sa teinte.
    mesure(
      'washAccent',
      8.12,
      palette.washAccent.background,
      palette.washAccent.onBackground,
    );
    mesure(
      'washSuccess',
      9.17,
      palette.washSuccess.background,
      palette.washSuccess.onBackground,
    );
    mesure(
      'washWarning',
      8.64,
      palette.washWarning.background,
      palette.washWarning.onBackground,
    );
    mesure(
      'washAlert',
      8.04,
      palette.washAlert.background,
      palette.washAlert.onBackground,
    );
    mesure(
      'washFamily',
      12.51,
      palette.washFamily.background,
      palette.washFamily.onBackground,
    );
    mesure(
      'surfaceQuran',
      13.50,
      palette.surfaceQuran.background,
      palette.surfaceQuran.onBackground,
    );

    // Paires douces : la teinte posee sur le canevas. Elles doivent rester
    // SUBTILES (ratio bas) : une teinte sombre qui se detacherait trop du
    // canevas redeviendrait un aplat, l'exact defaut que le registre doux
    // corrige cote clair comme cote sombre.
    mesure(
      'washAccent sur le canevas',
      1.15,
      palette.washAccent.background,
      canevas,
    );
    mesure(
      'washSuccess sur le canevas',
      1.18,
      palette.washSuccess.background,
      canevas,
    );
    mesure(
      'washWarning sur le canevas',
      1.21,
      palette.washWarning.background,
      canevas,
    );
    mesure(
      'washAlert sur le canevas',
      1.04,
      palette.washAlert.background,
      canevas,
    );
    mesure(
      'washFamily sur le canevas',
      1.20,
      palette.washFamily.background,
      canevas,
    );
    mesure(
      'surfaceQuran sur le canevas',
      1.11,
      palette.surfaceQuran.background,
      canevas,
    );

    // Les quatre encres semantiques, sur le canevas puis sur une carte
    // (surface elevee).
    mesure(
      'inkAccent sur le canevas',
      9.35,
      palette.inkAccent.debugValue,
      canevas,
    );
    mesure(
      'inkSuccess sur le canevas',
      10.79,
      palette.inkSuccess.debugValue,
      canevas,
    );
    mesure(
      'inkWarning sur le canevas',
      10.49,
      palette.inkWarning.debugValue,
      canevas,
    );
    mesure(
      'inkAlert sur le canevas',
      8.39,
      palette.inkAlert.debugValue,
      canevas,
    );
    mesure(
      'inkAccent sur une carte',
      7.53,
      palette.inkAccent.debugValue,
      eleve,
    );
    mesure(
      'inkSuccess sur une carte',
      8.69,
      palette.inkSuccess.debugValue,
      eleve,
    );
    mesure(
      'inkWarning sur une carte',
      8.45,
      palette.inkWarning.debugValue,
      eleve,
    );
    mesure('inkAlert sur une carte', 6.76, palette.inkAlert.debugValue, eleve);
  });

  group('Les bordures : une seule des trois porte du sens', () {
    test('borderStrong passe 3:1 sur les TROIS surfaces', () {
      for (final MapEntry<String, Color> surface in <String, Color>{
        'surfaceCanvas': canevas,
        'surfaceRaised': eleve,
        'surfaceSunken': enfonce,
      }.entries) {
        final double m = contraste(
          palette.borderStrong.debugValue,
          surface.value,
        );
        expect(
          m,
          greaterThanOrEqualTo(3),
          reason:
              'borderStrong mesure ${m.toStringAsFixed(2)} sur '
              '${surface.key} en sombre. Un focus, une selection ou un bord '
              'de tableau y deviendraient invisibles.',
        );
      }
    });

    test('les deux autres restent sous 3:1, donc decoratives', () {
      for (final MapEntry<String, AppInkColor> filet in <String, AppInkColor>{
        'borderHairline': palette.borderHairline,
        'borderResting': palette.borderResting,
      }.entries) {
        expect(
          contraste(filet.value.debugValue, canevas),
          lessThan(3),
          reason:
              '${filet.key} atteint desormais le seuil des elements '
              'porteurs de sens sur la palette sombre.',
        );
      }
    });
  });

  group(
    'A LA DIFFERENCE DU CLAIR : inkFaint ne trouve plus de trou dans la rampe',
    () {
      // Cote clair, inkFaint echoue a 4.48 sur surfaceSunken (sous 4.5). La
      // valeur choisie ici pour le sombre (0xFF9D9A93) a ete mesuree pour
      // rester au-dessus de 4.5 sur les TROIS surfaces : ce n'est pas un
      // hasard, c'est documente dans AppPalette.sombre.
      test('inkFaint passe 4.5:1 sur les trois surfaces', () {
        for (final MapEntry<String, Color> surface in <String, Color>{
          'surfaceCanvas': canevas,
          'surfaceRaised': eleve,
          'surfaceSunken': enfonce,
        }.entries) {
          final double m = contraste(
            palette.inkFaint.debugValue,
            surface.value,
          );
          expect(
            m,
            greaterThanOrEqualTo(4.5),
            reason:
                'inkFaint mesure ${m.toStringAsFixed(2)} sur ${surface.key} '
                'en sombre : le trou documente comme ferme a reapparu, '
                'AppPalette.sombre ou ce test sont a reprendre ensemble.',
          );
        }
      });
    },
  );

  group('Le piege du clair ne se reproduit pas de la meme facon en sombre', () {
    // Cote clair, `surfaceAlert.applyTo(...)` pose sur la page ecrivait en
    // blanc (l'encre du fond rouge), illisible sur le creme (1.10). Cote
    // sombre, ce meme blanc reste tres lisible sur un canevas proche du noir.
    test(
      'le blanc de surfaceAlert reste lisible sur le canevas sombre '
      '(contrairement au clair)',
      () {
        final double mesure = contraste(
          palette.surfaceAlert.onBackground,
          canevas,
        );
        expect(mesure, greaterThanOrEqualTo(4.5));
      },
    );

    // Ce qui NE change pas : le violet plein reste interdit en texte direct,
    // et la marge d'echec est meme plus large qu'en clair (3.50 contre 4.39).
    test('le violet plein ne s ecrit toujours pas en texte sur le canevas', () {
      final double mesure = contraste(
        palette.surfacePrimary.background,
        canevas,
      );
      expect(mesure, closeTo(3.50, tolerance));
      expect(mesure, lessThan(4.5));
      expect(
        contraste(palette.inkAccent.debugValue, canevas),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('le focus passe, lui, le seuil de 3:1 sur le canevas', () {
      expect(
        contraste(palette.borderStrong.debugValue, canevas),
        greaterThanOrEqualTo(3),
      );
    });
  });

  group('Les paires pleines et l ombre sont des couleurs de marque reutilisees', () {
    // Documente dans AppPalette.sombre : ces jetons ne changent pas avec le
    // theme. Ce test fige la decision plutot que de la laisser deriver en
    // silence si quelqu'un les differencie un jour sans le vouloir.
    final AppPalette clair = AppPalette.claire();

    test('surfacePrimary est identique aux deux palettes', () {
      expect(palette.surfacePrimary, clair.surfacePrimary);
    });

    test('surfaceSuccess est identique aux deux palettes', () {
      expect(palette.surfaceSuccess, clair.surfaceSuccess);
    });

    test('surfaceWarning est identique aux deux palettes', () {
      expect(palette.surfaceWarning, clair.surfaceWarning);
    });

    test('surfaceAlert est identique aux deux palettes', () {
      expect(palette.surfaceAlert, clair.surfaceAlert);
    });

    test('ombre est identique aux deux palettes', () {
      expect(palette.ombre, clair.ombre);
    });

    test('surfaceInverse, elle, est bien inversee entre les deux palettes', () {
      expect(
        palette.surfaceInverse.background,
        clair.surfaceInverse.onBackground,
      );
      expect(
        palette.surfaceInverse.onBackground,
        clair.surfaceInverse.background,
      );
    });
  });
}
