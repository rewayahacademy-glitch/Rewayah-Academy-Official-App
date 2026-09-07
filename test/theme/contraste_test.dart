import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';

/// Rapport de contraste WCAG entre deux couleurs.
///
/// `Color.computeLuminance` implemente deja la luminance relative de la norme :
/// on ne la reecrit pas, on l'utilise.
double contraste(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double clair = la > lb ? la : lb;
  final double sombre = la > lb ? lb : la;
  return (clair + 0.05) / (sombre + 0.05);
}

/// Tolerance d'arrondi entre la mesure du test et celle inscrite au tableau,
/// qui est arrondie a deux decimales.
const double tolerance = 0.01;

void main() {
  final AppPalette palette = AppPalette.claire();
  final Color creme = palette.surfaceCanvas.background;
  final Color blanc = palette.surfaceRaised.background;
  final Color enfonce = palette.surfaceSunken.background;

  group('Aucune paire du theme ne descend sous 4.5:1', () {
    // La regle qui vaut pour tout le produit : une paire dit sur quoi elle
    // s'ecrit, et elle est lisible par construction. Une paire qui echoue ici
    // rend illisible chaque ecran qui l'emploie, sans qu'aucun de ces ecrans
    // n'ait de defaut.
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
              '${e.key} mesure ${mesure.toStringAsFixed(2)}:1. '
              'La paire est illisible, corriger le jeton dans AppPalette.',
        );
      });
    }
  });

  group('Les mesures inscrites au tableau des jetons sont exactes', () {
    // `docs/produit/design-tokens.md` interdit qu'un jeton entre dans la
    // palette sans sa mesure inscrite. Ce groupe est l'autre moitie de la
    // regle : la mesure inscrite doit etre la vraie. Une valeur qui derive ici
    // signale que le document et le code ont diverge, pas qu'il faut lever la
    // borne.
    void mesure(String nom, double attendu, Color a, Color b) {
      test('$nom vaut $attendu', () {
        expect(
          contraste(a, b),
          closeTo(attendu, tolerance),
          reason:
              '$nom mesure ${contraste(a, b).toStringAsFixed(2)} et non '
              '$attendu : le tableau de design-tokens.md section 1 est a '
              'reprendre, ou le jeton a ete change sans sa mesure.',
        );
      });
    }

    // Rampe neutre, mesuree sur le creme (section 1.3).
    mesure('surfaceRaised sur le creme', 1.10, blanc, creme);
    mesure('surfaceSunken sur le creme', 1.06, enfonce, creme);
    mesure(
      'borderHairline sur le creme',
      1.20,
      palette.borderHairline.debugValue,
      creme,
    );
    mesure(
      'borderResting sur le creme',
      1.45,
      palette.borderResting.debugValue,
      creme,
    );
    mesure(
      'borderStrong sur le creme',
      3.40,
      palette.borderStrong.debugValue,
      creme,
    );
    mesure('inkFaint sur le creme', 4.74, palette.inkFaint.debugValue, creme);
    mesure('inkMuted sur le creme', 6.56, palette.inkMuted.debugValue, creme);
    mesure(
      'inkStrong sur le creme',
      15.37,
      palette.inkStrong.debugValue,
      creme,
    );

    // Paires pleines (section 1.4).
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
    mesure(
      'surfaceInverse',
      15.37,
      palette.surfaceInverse.background,
      palette.surfaceInverse.onBackground,
    );

    // Paires douces : l'encre sur sa teinte (section 1.5).
    mesure(
      'washAccent',
      6.36,
      palette.washAccent.background,
      palette.washAccent.onBackground,
    );
    mesure(
      'washSuccess',
      6.23,
      palette.washSuccess.background,
      palette.washSuccess.onBackground,
    );
    mesure(
      'washWarning',
      6.63,
      palette.washWarning.background,
      palette.washWarning.onBackground,
    );
    mesure(
      'washAlert',
      5.63,
      palette.washAlert.background,
      palette.washAlert.onBackground,
    );
    mesure(
      'washFamily',
      13.51,
      palette.washFamily.background,
      palette.washFamily.onBackground,
    );
    mesure(
      'surfaceQuran',
      14.10,
      palette.surfaceQuran.background,
      palette.surfaceQuran.onBackground,
    );

    // Paires douces : la teinte posee sur le creme. Elles doivent rester
    // PALES : une teinte douce qui monterait vers 3:1 redeviendrait un aplat,
    // c'est-a-dire exactement le defaut que la refonte corrige.
    mesure(
      'washAccent sur le creme',
      1.16,
      palette.washAccent.background,
      creme,
    );
    mesure(
      'washSuccess sur le creme',
      1.14,
      palette.washSuccess.background,
      creme,
    );
    mesure(
      'washWarning sur le creme',
      1.11,
      palette.washWarning.background,
      creme,
    );
    mesure('washAlert sur le creme', 1.11, palette.washAlert.background, creme);
    mesure(
      'washFamily sur le creme',
      1.14,
      palette.washFamily.background,
      creme,
    );
    mesure(
      'surfaceQuran sur le creme',
      1.09,
      palette.surfaceQuran.background,
      creme,
    );

    // Les quatre encres semantiques, sur le creme puis sur une carte blanche.
    mesure('inkAccent sur le creme', 7.37, palette.inkAccent.debugValue, creme);
    mesure(
      'inkSuccess sur le creme',
      7.08,
      palette.inkSuccess.debugValue,
      creme,
    );
    mesure(
      'inkWarning sur le creme',
      7.36,
      palette.inkWarning.debugValue,
      creme,
    );
    mesure('inkAlert sur le creme', 6.25, palette.inkAlert.debugValue, creme);
    mesure(
      'inkAccent sur une carte',
      8.08,
      palette.inkAccent.debugValue,
      blanc,
    );
    mesure(
      'inkSuccess sur une carte',
      7.75,
      palette.inkSuccess.debugValue,
      blanc,
    );
    mesure(
      'inkWarning sur une carte',
      8.06,
      palette.inkWarning.debugValue,
      blanc,
    );
    mesure('inkAlert sur une carte', 6.84, palette.inkAlert.debugValue, blanc);
  });

  group('Les bordures : une seule des trois porte du sens', () {
    // WCAG 1.4.11 demande 3:1 pour un element non textuel qui porte de
    // l'information. L'ancien jeton unique mesurait 1.86 et servait pourtant
    // a delimiter : c'est le defaut que la refonte corrige en eclatant la
    // bordure en trois, dont une seule passe le seuil.
    test('borderStrong passe 3:1 sur les TROIS surfaces', () {
      for (final MapEntry<String, Color> surface in <String, Color>{
        'surfaceCanvas': creme,
        'surfaceRaised': blanc,
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
              '${surface.key}. Un focus, une selection ou un bord de tableau '
              'y deviendraient invisibles.',
        );
      }
    });

    test('les deux autres restent sous 3:1, donc decoratives', () {
      // Le test fige leur statut : quelqu'un qui les assombrirait pour les
      // rendre porteuses devrait lever cette borne, donc decider consciemment.
      for (final MapEntry<String, AppInkColor> filet in <String, AppInkColor>{
        'borderHairline': palette.borderHairline,
        'borderResting': palette.borderResting,
      }.entries) {
        expect(
          contraste(filet.value.debugValue, creme),
          lessThan(3),
          reason:
              '${filet.key} atteint desormais le seuil des elements porteurs '
              'de sens. Mettre a jour design-tokens.md section 1.3 avant de '
              'lever cette borne.',
        );
      }
    });
  });

  group('Le seul trou de la rampe : inkFaint sur la surface enfoncee', () {
    test('inkFaint echoue bien sur surfaceSunken', () {
      final double m = contraste(palette.inkFaint.debugValue, enfonce);
      expect(m, closeTo(4.48, tolerance));
      expect(
        m,
        lessThan(4.5),
        reason:
            'Si inkFaint passe desormais le seuil sur la surface enfoncee, '
            'l aiguillage de encreSecondaireSur n a plus de raison d etre : '
            'le relire avant de le supprimer.',
      );
    });

    test('encreSecondaireSur bascule sur inkMuted, qui lui passe', () {
      final AppInkColor choisie = palette.encreSecondaireSur(
        palette.surfaceSunken,
      );
      expect(choisie, palette.inkMuted);
      final double m = contraste(choisie.debugValue, enfonce);
      expect(m, closeTo(6.19, tolerance));
      expect(m, greaterThanOrEqualTo(4.5));
    });

    test('sur les deux autres surfaces, elle rend inkFaint', () {
      expect(
        palette.encreSecondaireSur(palette.surfaceCanvas),
        palette.inkFaint,
      );
      expect(
        palette.encreSecondaireSur(palette.surfaceRaised),
        palette.inkFaint,
      );
    });
  });

  group('Le piege qui a rendu un message d erreur invisible', () {
    // Trouve a l'etape 3 en construisant les ecrans, present depuis l'etape 2
    // dans PinPad : un message d'erreur pose sur la page etait style par
    // `surfaceAlert.applyTo(...)`, donc avec la couleur de texte prevue pour un
    // fond ROUGE. Le message existait dans l'arbre de widgets et n'existait pas
    // a l'ecran.
    test('la couleur de texte de surfaceAlert est illisible sur le creme', () {
      final double mesure = contraste(palette.surfaceAlert.onBackground, creme);
      expect(mesure, closeTo(1.10, tolerance));
      expect(
        mesure,
        lessThan(4.5),
        reason:
            'Si cette mesure passe desormais 4.5:1, la palette a change et ce '
            'garde-fou doit etre relu : il documente pourquoi inkAlert existe.',
      );
    });

    test('l encre d alerte corrige bien ce cas', () {
      expect(
        contraste(palette.inkAlert.debugValue, creme),
        greaterThan(contraste(palette.surfaceAlert.onBackground, creme)),
      );
    });
  });

  group('Les echecs mesures dans les specs sont bien evites', () {
    test('surfaceSuccess ne porte jamais de texte blanc', () {
      // La charte d'origine mesurait 1.46:1 avec du blanc.
      expect(
        contraste(palette.surfaceSuccess.background, blanc),
        closeTo(1.46, tolerance),
      );
      expect(palette.surfaceSuccess.onBackground, isNot(blanc));
    });

    test('surfaceWarning ne porte jamais de texte blanc', () {
      // La charte d'origine mesurait 1.75:1 avec du blanc.
      expect(
        contraste(palette.surfaceWarning.background, blanc),
        closeTo(1.75, tolerance),
      );
      expect(palette.surfaceWarning.onBackground, isNot(blanc));
    });

    test('surfaceAlert corrige bien le rouge d origine', () {
      // L'original 0xFFFF385C echouait a 3.51:1 sur du blanc.
      final double original = contraste(const Color(0xFFFF385C), blanc);
      expect(original, lessThan(4.5));
      expect(
        contraste(
          palette.surfaceAlert.background,
          palette.surfaceAlert.onBackground,
        ),
        greaterThan(original),
      );
    });

    test('le violet plein ne s ecrit pas en texte sur une surface claire', () {
      // C'est la raison d'etre d'inkAccent : le violet de la charte echoue sur
      // le creme comme sur la surface enfoncee, de peu, donc sans se voir.
      expect(
        contraste(palette.surfacePrimary.background, creme),
        closeTo(4.39, tolerance),
      );
      expect(
        contraste(palette.surfacePrimary.background, enfonce),
        closeTo(4.14, tolerance),
      );
      expect(
        contraste(palette.inkAccent.debugValue, creme),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('le focus et l erreur passent, eux, le seuil de 3:1 sur le creme', () {
      expect(
        contraste(palette.surfacePrimary.background, creme),
        greaterThanOrEqualTo(3),
      );
      expect(
        contraste(palette.surfaceAlert.background, creme),
        greaterThanOrEqualTo(3),
      );
    });
  });

  group('Le creme n est pas jaune, et ca se mesure', () {
    // Le jaunissement se lit sur l'ecart entre les canaux, pas sur la teinte :
    // le creme retenu a un ecart de 10, contre 34 pour un temoin jaunatre
    // (design-tokens.md section 1.2).
    int ecartCanaux(Color c) {
      final List<int> canaux = <int>[
        (c.r * 255).round(),
        (c.g * 255).round(),
        (c.b * 255).round(),
      ];
      return canaux.reduce((int a, int b) => a > b ? a : b) -
          canaux.reduce((int a, int b) => a < b ? a : b);
    }

    test('l ecart entre canaux du creme reste a 10', () {
      expect(ecartCanaux(creme), 10);
    });

    test('un creme jaunatre en serait a plus du triple', () {
      expect(ecartCanaux(const Color(0xFFFBF3D9)), 34);
    });
  });
}
