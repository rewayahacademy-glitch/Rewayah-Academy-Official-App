import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';

import 'support/lecteur_police.dart';

/// Les roles de titre : DM Sans, `wght` et `opsz` poses.
const List<String> _rolesTitre = <String>[
  'headlineLarge',
  'headlineMedium',
  'headlineSmall',
  'titleLarge',
  'titleMedium',
  'titleSmall',
];

/// Les roles de corps : Plus Jakarta Sans.
const List<String> _rolesCorps = <String>[
  'bodyLarge',
  'bodyMedium',
  'bodySmall',
  'labelLarge',
  'labelMedium',
  'labelSmall',
];

/// Les valeurs fortes : Plus Jakarta Sans tabulaire.
const List<String> _rolesValeur = <String>[
  'displayLarge',
  'displayMedium',
  'displaySmall',
];

Map<String, TextStyle> _roles(TextTheme t) => <String, TextStyle>{
  'displayLarge': t.displayLarge!,
  'displayMedium': t.displayMedium!,
  'displaySmall': t.displaySmall!,
  'headlineLarge': t.headlineLarge!,
  'headlineMedium': t.headlineMedium!,
  'headlineSmall': t.headlineSmall!,
  'titleLarge': t.titleLarge!,
  'titleMedium': t.titleMedium!,
  'titleSmall': t.titleSmall!,
  'bodyLarge': t.bodyLarge!,
  'bodyMedium': t.bodyMedium!,
  'bodySmall': t.bodySmall!,
  'labelLarge': t.labelLarge!,
  'labelMedium': t.labelMedium!,
  'labelSmall': t.labelSmall!,
};

double? _axe(TextStyle s, String etiquette) {
  for (final FontVariation v in s.fontVariations ?? const <FontVariation>[]) {
    if (v.axis == etiquette) {
      return v.value;
    }
  }
  return null;
}

bool _tabulaire(TextStyle s) => (s.fontFeatures ?? const <FontFeature>[])
    .contains(const FontFeature.tabularFigures());

const String _fichierTitre = 'assets/fonts/DMSans-Variable.ttf';
const String _fichierCorps = 'assets/fonts/PlusJakartaSans-Variable.ttf';

void main() {
  group('repartition des familles (decisions coordinateur, section 3.4)', () {
    for (final (String nom, TextTheme echelle) in <(String, TextTheme)>[
      ('standard', AppTypography.standard),
      ('enfant', AppTypography.enfant),
    ]) {
      test('$nom : titres en DM Sans, corps et valeurs en Jakarta', () {
        final Map<String, TextStyle> roles = _roles(echelle);
        for (final String role in _rolesTitre) {
          expect(roles[role]!.fontFamily, AppFontFamily.titre, reason: role);
        }
        for (final String role in <String>[..._rolesCorps, ..._rolesValeur]) {
          expect(roles[role]!.fontFamily, AppFontFamily.corps, reason: role);
        }
        for (final TextStyle s in roles.values) {
          expect(s.fontFamilyFallback, AppFontFamily.repli);
        }
      });

      test('$nom : chaque style DM Sans pose wght ET opsz = taille bornee', () {
        final Map<String, TextStyle> roles = _roles(echelle);
        for (final String role in _rolesTitre) {
          final TextStyle s = roles[role]!;
          final double? wght = _axe(s, 'wght');
          final double? opsz = _axe(s, 'opsz');
          expect(wght, isNotNull, reason: '$role sans wght');
          expect(opsz, isNotNull, reason: '$role sans opsz (defaut 9)');
          expect(wght, s.fontWeight!.value.toDouble(), reason: role);
          expect(opsz, s.fontSize!.clamp(9, 40), reason: role);
        }
      });

      test('$nom : chaque style Jakarta pose wght dans 200..800', () {
        final Map<String, TextStyle> roles = _roles(echelle);
        for (final String role in <String>[..._rolesCorps, ..._rolesValeur]) {
          final TextStyle s = roles[role]!;
          expect(_axe(s, 'wght'), s.fontWeight!.value.toDouble(), reason: role);
          expect(_axe(s, 'opsz'), isNull, reason: '$role : Jakarta sans opsz');
          expect(
            _axe(s, 'wght'),
            inInclusiveRange(
              AppFontAxis.wghtCorpsMin,
              AppFontAxis.wghtCorpsMax,
            ),
          );
        }
      });
    }

    test('graisses : titres de page 700, titres de section 600', () {
      final TextTheme t = AppTypography.standard;
      expect(t.headlineLarge!.fontWeight, FontWeight.w700);
      expect(t.headlineMedium!.fontWeight, FontWeight.w700);
      expect(t.headlineSmall!.fontWeight, FontWeight.w700);
      expect(t.titleLarge!.fontWeight, FontWeight.w600);
      expect(t.titleMedium!.fontWeight, FontWeight.w600);
      expect(t.bodyLarge!.fontWeight, FontWeight.w400);
      expect(t.labelLarge!.fontWeight, FontWeight.w600);
    });

    test('tailles et interlignes : l echelle est inchangee, en px entiers', () {
      final Map<String, (double, double)> attendu = <String, (double, double)>{
        'displaySmall': (36, 44),
        'headlineLarge': (36, 44),
        'headlineMedium': (32, 40),
        'headlineSmall': (28, 36),
        'titleLarge': (22, 28),
        'titleMedium': (18, 26),
        'titleSmall': (16, 24),
        'bodyLarge': (16, 24),
        'bodyMedium': (14, 20),
        'bodySmall': (12, 16),
        'labelLarge': (16, 20),
        'labelMedium': (12, 16),
        'labelSmall': (12, 16),
      };
      final Map<String, TextStyle> roles = _roles(AppTypography.standard);
      attendu.forEach((String role, (double, double) v) {
        final TextStyle s = roles[role]!;
        expect(s.fontSize, v.$1, reason: role);
        // Hauteur de ligne en pixels entiers : aucun role ne tombe entre
        // deux pixels, ce qui decalerait les lignes de base d'un bloc a
        // l'autre.
        expect(s.fontSize! * s.height!, closeTo(v.$2, 1e-9), reason: role);
      });
    });

    test('la variante enfant est explicite, le document Coran reste isole', () {
      // HIER-1 : titleLarge (28) passe sous headlineSmall (32) ; les deux
      // valaient 32 (un titre d'ecran et un nom a la meme taille).
      expect(AppTypography.enfant.titleLarge!.fontSize, 28);
      expect(AppTypography.enfant.headlineSmall!.fontSize, 32);
      expect(AppTypography.enfant.bodyLarge!.fontSize, 20);
      expect(
        AppTypography.enfant.headlineSmall!.fontFamily,
        AppFontFamily.titre,
      );
      expect(AppTypography.document().fontFamily, AppFontFamily.arabeDocument);
      expect(AppTypography.document().height, 2);
    });
  });

  test('les onglets (TabBar) sont en Plus Jakarta Sans, pas en DM Sans', () {
    // Revue phase 0 (jetons D5) : Material 3 pose `titleSmall` par defaut.
    for (final InterfaceMode mode in InterfaceMode.values) {
      for (final Brightness luminosite in Brightness.values) {
        final TabBarThemeData onglets = AppTheme.pour(
          mode,
          luminosite,
        ).tabBarTheme;
        expect(onglets.labelStyle?.fontFamily, AppFontFamily.corps);
        expect(onglets.unselectedLabelStyle?.fontFamily, AppFontFamily.corps);
      }
    }
  });

  group('graisse : fontWeight ET axe wght, jamais l un sans l autre', () {
    test('un style Jakarta change de graisse par son axe', () {
      final TextStyle base = AppTypography.standard.labelMedium!;
      final TextStyle actif = AppTypography.graisse(base, FontWeight.w600);
      expect(actif.fontWeight, FontWeight.w600);
      expect(_axe(actif, 'wght'), 600);
      expect(actif.fontFamily, base.fontFamily);
      expect(actif.fontSize, base.fontSize);
      expect(
        actif.fontVariations!.where((FontVariation v) => v.axis == 'wght'),
        hasLength(1),
      );
    });

    test('un style DM Sans garde son opsz, sa graisse suit l axe', () {
      final TextStyle base = AppTypography.standard.titleLarge!;
      final TextStyle gras = AppTypography.graisse(base, FontWeight.w700);
      expect(gras.fontWeight, FontWeight.w700);
      expect(_axe(gras, 'wght'), 700);
      expect(_axe(gras, 'opsz'), _axe(base, 'opsz'));
    });

    test('la valeur est bornee a l axe de la famille', () {
      expect(
        _axe(
          AppTypography.graisse(
            AppTypography.standard.bodyLarge!,
            FontWeight.w900,
          ),
          'wght',
        ),
        AppFontAxis.wghtCorpsMax,
      );
    });
  });

  group('chiffres : Plus Jakarta Sans tabulaire, jamais DM Sans', () {
    test('le style chiffre est en Jakarta, tabulaire, graisse par axe', () {
      final TextStyle c = AppTypography.chiffre();
      expect(c.fontFamily, AppFontFamily.corps);
      expect(_tabulaire(c), isTrue);
      expect(c.fontSize, 32);
      expect(c.fontSize! * c.height!, closeTo(40, 1e-9));
      expect(_axe(c, 'wght'), 600);

      final TextStyle petit = AppTypography.chiffre(
        taille: 18,
        poids: FontWeight.w700,
      );
      expect(petit.fontSize! * petit.height!, closeTo(26, 1e-9));
      expect(_axe(petit, 'wght'), 700);
    });

    test('les valeurs fortes display* sont tabulaires', () {
      final Map<String, TextStyle> roles = _roles(AppTypography.standard);
      for (final String role in _rolesValeur) {
        expect(_tabulaire(roles[role]!), isTrue, reason: role);
      }
    });

    test('tabulaire bascule un style DM Sans sur Jakarta, taille egale', () {
      final TextStyle titre = AppTypography.standard.titleMedium!;
      final TextStyle chiffres = AppTypography.tabulaire(titre);
      expect(chiffres.fontFamily, AppFontFamily.corps);
      expect(chiffres.fontSize, titre.fontSize);
      expect(chiffres.height, titre.height);
      expect(chiffres.fontWeight, titre.fontWeight);
      expect(_axe(chiffres, 'opsz'), isNull);
      expect(_axe(chiffres, 'wght'), 600);
      expect(_tabulaire(chiffres), isTrue);

      // Un style deja en Jakarta garde sa famille et ses axes.
      final TextStyle corps = AppTypography.standard.bodySmall!;
      expect(AppTypography.tabulaire(corps).fontFamily, AppFontFamily.corps);
      expect(
        AppTypography.tabulaire(corps).fontVariations,
        corps.fontVariations,
      );
    });
  });

  group('binaires embarques : tables fvar, GSUB, cmap, pas un commentaire', () {
    test('DM Sans : opsz 9..40 defaut 9, wght 100..1000, pas de tnum', () {
      final LecteurPolice dm = LecteurPolice(_fichierTitre);
      final Map<String, AxePolice> axes = dm.axes;
      expect(axes.keys.toSet(), <String>{'opsz', 'wght'});
      expect(axes['opsz']!.min, AppFontAxis.opszTitreMin);
      expect(axes['opsz']!.defaut, 9);
      expect(axes['opsz']!.max, AppFontAxis.opszTitreMax);
      expect(axes['wght']!.min, AppFontAxis.wghtTitreMin);
      expect(axes['wght']!.defaut, 400);
      expect(axes['wght']!.max, AppFontAxis.wghtTitreMax);
      expect(dm.fonctions, isNot(contains('tnum')));
    });

    test('Plus Jakarta Sans : wght 200..800 defaut 400, tnum present', () {
      final LecteurPolice jakarta = LecteurPolice(_fichierCorps);
      final Map<String, AxePolice> axes = jakarta.axes;
      expect(axes.keys.toSet(), <String>{'wght'});
      expect(axes['wght']!.min, AppFontAxis.wghtCorpsMin);
      expect(axes['wght']!.defaut, 400);
      expect(axes['wght']!.max, AppFontAxis.wghtCorpsMax);
      expect(jakarta.fonctions, contains('tnum'));
    });

    test('les deux familles couvrent accents et ponctuation du francais', () {
      const String francais = 'àâäçéèêëîïôöùûüÿœæÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸŒÆ«»’ ';
      for (final String fichier in <String>[_fichierTitre, _fichierCorps]) {
        final Set<int> couverture = LecteurPolice(fichier).couverture;
        final String manquants = String.fromCharCodes(
          francais.runes.where((int r) => !couverture.contains(r)),
        );
        expect(manquants, isEmpty, reason: fichier);
      }
    });

    test('le corps multiligne tient dans la hauteur naturelle de Jakarta', () {
      // Hauteur naturelle ascendante + descendante lue dans `hhea` : 1,26 em.
      // Sous elle, deux lignes de corps se toucheraient (ç sous É).
      final double naturelle = LecteurPolice(_fichierCorps).hauteurNaturelle;
      final TextTheme t = AppTypography.standard;
      for (final TextStyle s in <TextStyle>[
        t.bodyLarge!,
        t.bodyMedium!,
        t.bodySmall!,
      ]) {
        expect(s.height, greaterThanOrEqualTo(naturelle));
      }
    });
  });

  group('pubspec : quatre familles de texte, pas une de plus', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final List<String> familles = RegExp(
      r'^\s*-\s*family:\s*(\S+)\s*$',
      multiLine: true,
    ).allMatches(pubspec).map((RegExpMatch m) => m.group(1)!).toList();

    test('la liste declaree est exactement celle du theme et des icones', () {
      // MUSHAF-15L (decision du directeur du 11/10/2026) : UthmanicHafs est la
      // seule famille de plus, et facultative tant que le bloc de
      // `docs/current/coran/PUBSPEC_MUSHAF_15L.md` n'est pas applique.
      expect(
        familles.toSet().difference(<String>{AppFontFamily.arabeMushaf}),
        <String>{...AppFontFamily.texte, 'Phosphor', 'PhosphorFill'},
      );
      expect(familles.length, anyOf(6, 7));
      if (familles.length == 7) {
        expect(familles, contains(AppFontFamily.arabeMushaf));
      }
    });

    test('chaque fichier declare existe et les anciens sont retires', () {
      final Iterable<String> assets = RegExp(r'asset:\s*(\S+)')
          .allMatches(pubspec)
          .map((RegExpMatch m) => m.group(1)!)
          .where((String a) => a.startsWith('assets/fonts/'));
      expect(assets.length, anyOf(6, 7));
      for (final String asset in assets) {
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }
      for (final String retire in <String>[
        'InstrumentSans-Variable.ttf',
        'BricolageGrotesque-Variable.ttf',
        'LICENSE-InstrumentSans.txt',
        'LICENSE-BricolageGrotesque.txt',
      ]) {
        expect(File('assets/fonts/$retire').existsSync(), isFalse);
      }
      expect(File('assets/fonts/LICENSE-DMSans.txt').existsSync(), isTrue);
      expect(
        File('assets/fonts/LICENSE-PlusJakartaSans.txt').existsSync(),
        isTrue,
      );
    });
  });
}
