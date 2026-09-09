import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';

/// La valeur d'un axe variable dans un style, ou `null` s'il n'est pas pilote.
double? axe(TextStyle style, String nom) {
  for (final FontVariation v in style.fontVariations ?? <FontVariation>[]) {
    if (v.axis == nom) {
      return v.value;
    }
  }
  return null;
}

/// Tous les roles d'une echelle, avec leur nom.
Map<String, TextStyle> roles(TextTheme echelle) => <String, TextStyle>{
  'displayLarge': echelle.displayLarge!,
  'displayMedium': echelle.displayMedium!,
  'displaySmall': echelle.displaySmall!,
  'headlineLarge': echelle.headlineLarge!,
  'headlineMedium': echelle.headlineMedium!,
  'headlineSmall': echelle.headlineSmall!,
  'titleLarge': echelle.titleLarge!,
  'titleMedium': echelle.titleMedium!,
  'titleSmall': echelle.titleSmall!,
  'bodyLarge': echelle.bodyLarge!,
  'bodyMedium': echelle.bodyMedium!,
  'bodySmall': echelle.bodySmall!,
  'labelLarge': echelle.labelLarge!,
  'labelMedium': echelle.labelMedium!,
  'labelSmall': echelle.labelSmall!,
};

void main() {
  final Map<String, TextTheme> echelles = <String, TextTheme>{
    'standard': AppTypography.standard,
    'enfant': AppTypography.enfant,
  };

  group('Les quatre familles, et pas une de plus', () {
    test('les titres et le corps emploient les deux polices francaises', () {
      expect(AppFontFamily.titre, 'BricolageGrotesque');
      expect(AppFontFamily.corps, 'InstrumentSans');
    });

    test('l arabe n a pas change', () {
      expect(AppFontFamily.arabeDocument, 'UthmanTahaNaskh');
      expect(AppFontFamily.arabeInterface, 'NotoSansArabic');
    });

    test('tout style latin declare l arabe en repli', () {
      // L'application est bilingue et l'arabe est la langue principale : un
      // texte francais qui contient de l'arabe doit rester lisible sans que
      // l'ecran ait a choisir sa police lui-meme.
      for (final MapEntry<String, TextTheme> e in echelles.entries) {
        for (final MapEntry<String, TextStyle> r in roles(e.value).entries) {
          expect(
            r.value.fontFamilyFallback,
            contains(AppFontFamily.arabeInterface),
            reason: '${e.key}.${r.key} n a pas de repli arabe.',
          );
        }
      }
    });
  });

  group('Le crenage optique, qui n existait nulle part avant la refonte', () {
    test('chaque role porte le crenage de sa taille rendue', () {
      // Le bareme est en em : il se convertit en pixels a partir de la taille,
      // il ne se recopie pas role par role.
      for (final MapEntry<String, TextTheme> e in echelles.entries) {
        for (final MapEntry<String, TextStyle> r in roles(e.value).entries) {
          final double taille = r.value.fontSize!;
          expect(
            r.value.letterSpacing,
            closeTo(AppTypography.crenage(taille), 0.0001),
            reason: '${e.key}.${r.key} a un crenage qui ne suit pas sa taille.',
          );
        }
      }
    });

    test('le bareme suit les cinq paliers du tableau', () {
      expect(AppTypography.crenage(40), closeTo(40 * -0.02, 0.0001));
      expect(AppTypography.crenage(32), closeTo(32 * -0.02, 0.0001));
      expect(AppTypography.crenage(28), closeTo(28 * -0.015, 0.0001));
      expect(AppTypography.crenage(24), closeTo(24 * -0.015, 0.0001));
      expect(AppTypography.crenage(20), closeTo(20 * -0.01, 0.0001));
      expect(AppTypography.crenage(18), closeTo(18 * -0.01, 0.0001));
      expect(AppTypography.crenage(16), 0);
      expect(AppTypography.crenage(15), 0);
      expect(AppTypography.crenage(14), closeTo(14 * 0.01, 0.0001));
      expect(AppTypography.crenage(12), closeTo(12 * 0.01, 0.0001));
    });

    test('un grand titre se serre, un petit libelle s aere', () {
      // C'est le sens du bareme, et c'est ce qui se voit a l'ecran : un grand
      // titre a l'espacement d'un corps de texte parait lache et amateur.
      expect(AppTypography.crenage(40), lessThan(0));
      expect(AppTypography.crenage(12), greaterThan(0));
    });

    test('un libelle en capitales sous 12 points prend son propre crenage', () {
      const TextStyle base = TextStyle(fontSize: 12);
      expect(AppTypography.capitales(base).letterSpacing, closeTo(0.72, 0.001));
      // Au dessus de 12, le bareme courant s'applique : la regle des capitales
      // ne remonte pas l'echelle.
      const TextStyle grand = TextStyle(fontSize: 16, letterSpacing: 0);
      expect(AppTypography.capitales(grand).letterSpacing, 0);
    });
  });

  group('Les axes variables sont tous pilotes, aucun laisse a son defaut', () {
    test('les titres reglent opsz sur la taille rendue, bornee au fichier', () {
      // Le defaut du fichier est 96 : un titre de 20 points qui ne declare pas
      // son opsz sortirait dessine pour 96, donc trop fin et trop serre.
      for (final MapEntry<String, TextTheme> e in echelles.entries) {
        final TextTheme t = e.value;
        for (final TextStyle style in <TextStyle>[
          t.displayLarge!,
          t.displayMedium!,
          t.displaySmall!,
          t.headlineLarge!,
          t.headlineMedium!,
          t.headlineSmall!,
        ]) {
          final double taille = style.fontSize!;
          expect(
            axe(style, 'opsz'),
            closeTo(
              taille.clamp(AppFontAxis.opszMin, AppFontAxis.opszMax),
              0.0001,
            ),
            reason: '${e.key} : un titre de $taille ne regle pas son opsz.',
          );
        }
      }
    });

    test('chaque style pilote sa graisse par l axe wght', () {
      // FontWeight seul ne suffirait pas : Flutter synthetiserait un faux gras.
      for (final MapEntry<String, TextTheme> e in echelles.entries) {
        for (final MapEntry<String, TextStyle> r in roles(e.value).entries) {
          expect(
            axe(r.value, 'wght'),
            isNotNull,
            reason: '${e.key}.${r.key} laisse sa graisse au defaut du fichier.',
          );
        }
      }
    });

    test('le corps ne descend jamais sous la graisse 400', () {
      // Instrument Sans commence a 400 : il n'y a pas de light dans ce produit.
      // La hierarchie du texte se fait par la couleur, avec les trois encres
      // neutres, jamais par un gris clair obtenu en amaigrissant la police.
      for (final MapEntry<String, TextTheme> e in echelles.entries) {
        for (final MapEntry<String, TextStyle> r in roles(e.value).entries) {
          if (r.value.fontFamily != AppFontFamily.corps) {
            continue;
          }
          expect(
            axe(r.value, 'wght'),
            greaterThanOrEqualTo(AppFontAxis.wghtCorpsMin),
            reason: '${e.key}.${r.key} demande une graisse absente du fichier.',
          );
          expect(
            axe(r.value, 'wght'),
            lessThanOrEqualTo(AppFontAxis.wghtCorpsMax),
          );
        }
      }
    });
  });

  group('Chiffres tabulaires', () {
    test('les trois roles d affichage les portent d office', () {
      // Leur emploi documente est le chiffre geant d'ELV-02 et le nombre d'une
      // tuile de statistique : des chiffres qui changent en place. Sans tnum,
      // un compteur qui passe de 17 a 18 fait bouger toute la ligne.
      for (final MapEntry<String, TextTheme> e in echelles.entries) {
        for (final TextStyle style in <TextStyle>[
          e.value.displayLarge!,
          e.value.displayMedium!,
          e.value.displaySmall!,
        ]) {
          expect(
            style.fontFeatures,
            contains(const FontFeature.tabularFigures()),
            reason:
                '${e.key} : un role d affichage a perdu ses chiffres '
                'tabulaires.',
          );
        }
      }
    });

    test('la fonction s applique a n importe quel style', () {
      const TextStyle base = TextStyle(fontSize: 15);
      expect(
        AppTypography.tabulaire(base).fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  group('Les deux echelles', () {
    test('le mode enfant agrandit d exactement 20 pour cent', () {
      // L'agrandissement se decide ici et nulle part ailleurs : aucun ecran
      // n'applique de multiplicateur de son cote.
      final Map<String, TextStyle> std = roles(AppTypography.standard);
      final Map<String, TextStyle> enf = roles(AppTypography.enfant);
      for (final String nom in std.keys) {
        expect(
          enf[nom]!.fontSize,
          closeTo(std[nom]!.fontSize! * AppTypography.facteurEnfant, 0.0001),
          reason: '$nom ne suit pas le facteur du mode enfant.',
        );
      }
    });

    test('l interligne s ouvre en mode enfant', () {
      // Un texte plus gros dans le meme interligne se lit moins bien.
      final Map<String, TextStyle> std = roles(AppTypography.standard);
      final Map<String, TextStyle> enf = roles(AppTypography.enfant);
      for (final String nom in std.keys) {
        expect(enf[nom]!.height, greaterThan(std[nom]!.height!));
      }
    });

    test('l interligne des grands corps est resserre', () {
      // C'est ce que la refonte change en plus de la famille et du crenage :
      // un titre de 40 points ne prend pas l'interligne d'un paragraphe.
      final TextTheme t = AppTypography.standard;
      expect(t.displayLarge!.height, lessThan(t.bodyLarge!.height!));
      expect(t.displayLarge!.height, lessThanOrEqualTo(1.05));
    });
  });

  group('Le rendu de document arabe reste hors de l echelle', () {
    test('il emploie la police de document et son interligne genereux', () {
      final TextStyle style = AppTypography.document();
      expect(style.fontFamily, AppFontFamily.arabeDocument);
      expect(style.height, 2);
      // Pas de crenage : le crenage optique latin ne s'applique pas a un
      // naskh, dont les liaisons portent deja l'espacement.
      expect(style.letterSpacing, isNull);
    });
  });
}
