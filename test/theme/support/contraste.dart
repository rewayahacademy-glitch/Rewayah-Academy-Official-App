import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';

/// Rapport de contraste WCAG 2.x entre deux couleurs opaques.
double contraste(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double clair = la > lb ? la : lb;
  final double sombre = la > lb ? lb : la;
  return (clair + 0.05) / (sombre + 0.05);
}

/// Texte : 4,5:1 (WCAG 1.4.3, AA).
const double seuilTexte = 4.5;

/// Composants et indicateurs graphiques : 3:1 (WCAG 1.4.11).
const double seuilComposant = 3;

/// La matrice de contraste complete d'une palette, meme regle pour les deux
/// themes : chaque paire, chaque encre sur chaque surface de texte, chaque
/// composant porteur de sens et chaque point de statut sur les surfaces ou il
/// se pose.
///
/// [pairesInterditesSurFondsDoux] nomme, sous la forme `encre / wash`, les
/// encres qui **n'atteignent pas** 4,5:1 sur un fond doux d'une autre famille :
/// ces paires sont interdites a l'ecran (revue phase 0, jetons D7). La liste
/// doit etre exacte : une paire nouvelle sous le seuil, ou une exemption qui
/// n'en est plus une, fait echouer le test.
void testsDeContraste(
  String theme,
  AppPalette p, {
  Set<String> pairesInterditesSurFondsDoux = const <String>{},
}) {
  final Map<String, AppColorPair> paires = <String, AppColorPair>{
    'surfaceRaised': p.surfaceRaised,
    'surfaceCanvas': p.surfaceCanvas,
    'surfaceSunken': p.surfaceSunken,
    'surfaceOverlay': p.surfaceOverlay,
    'surfaceMiseEnAvant': p.surfaceMiseEnAvant,
    'surfaceActionDouce': p.surfaceActionDouce,
    'surfacePrimary': p.surfacePrimary,
    'surfaceSuccess': p.surfaceSuccess,
    'surfaceWarning': p.surfaceWarning,
    'surfaceAlert': p.surfaceAlert,
    'surfaceInverse': p.surfaceInverse,
    'washAccent': p.washAccent,
    'washSuccess': p.washSuccess,
    'washWarning': p.washWarning,
    'washAlert': p.washAlert,
    'washFamily': p.washFamily,
    'surfaceQuran': p.surfaceQuran,
  };

  // Les surfaces sur lesquelles une encre de texte se pose.
  final Map<String, Color> surfacesDeTexte = <String, Color>{
    'surfaceCanvas': p.surfaceCanvas.background,
    'surfaceRaised': p.surfaceRaised.background,
    'surfaceSunken': p.surfaceSunken.background,
    'surfaceOverlay': p.surfaceOverlay.background,
    'surfaceMiseEnAvant': p.surfaceMiseEnAvant.background,
  };

  final Map<String, AppInkColor> encres = <String, AppInkColor>{
    'inkStrong': p.inkStrong,
    'inkMuted': p.inkMuted,
    'inkFaint': p.inkFaint,
    'inkAccent': p.inkAccent,
    'inkAlert': p.inkAlert,
    'inkSuccess': p.inkSuccess,
    'inkWarning': p.inkWarning,
  };

  group('$theme : contrastes (texte 4,5:1, composants 3:1)', () {
    test('chaque paire fond / texte atteint 4,5:1', () {
      paires.forEach((String nom, AppColorPair paire) {
        expect(
          contraste(paire.background, paire.onBackground),
          greaterThanOrEqualTo(seuilTexte),
          reason: nom,
        );
      });
    });

    test('chaque encre atteint 4,5:1 sur chaque surface de texte', () {
      encres.forEach((String encre, AppInkColor valeur) {
        surfacesDeTexte.forEach((String surface, Color fond) {
          expect(
            contraste(valeur.debugValue, fond),
            greaterThanOrEqualTo(seuilTexte),
            reason: '$encre sur $surface',
          );
        });
      });
    });

    test('toute encre sur tout fond doux : 4,5:1, sauf paires interdites', () {
      // Une encre de role ne se pose pas que sur SON fond doux : un libelle
      // `inkFaint` ou un message `inkAlert` peut tomber dans une carte
      // `washWarning`. Les paires sous le seuil sont nommees, donc interdites.
      final Map<String, Color> fondsDoux = <String, Color>{
        'washAccent': p.washAccent.background,
        'washSuccess': p.washSuccess.background,
        'washWarning': p.washWarning.background,
        'washAlert': p.washAlert.background,
        'washFamily': p.washFamily.background,
      };
      final Set<String> sousLeSeuil = <String>{
        for (final MapEntry<String, AppInkColor> e in encres.entries)
          for (final MapEntry<String, Color> f in fondsDoux.entries)
            if (contraste(e.value.debugValue, f.value) < seuilTexte)
              '${e.key} / ${f.key}',
      };
      expect(sousLeSeuil, pairesInterditesSurFondsDoux);
    });

    test('chaque encre de role atteint 4,5:1 sur le fond doux du role', () {
      final Map<String, (AppInkColor, AppColorPair)> roles =
          <String, (AppInkColor, AppColorPair)>{
            'inkAccent / washAccent': (p.inkAccent, p.washAccent),
            'inkSuccess / washSuccess': (p.inkSuccess, p.washSuccess),
            'inkWarning / washWarning': (p.inkWarning, p.washWarning),
            'inkAlert / washAlert': (p.inkAlert, p.washAlert),
          };
      roles.forEach((String nom, (AppInkColor, AppColorPair) r) {
        expect(
          contraste(r.$1.debugValue, r.$2.background),
          greaterThanOrEqualTo(seuilTexte),
          reason: nom,
        );
      });
    });

    test('les composants porteurs de sens atteignent 3:1', () {
      // Filet d'un champ actif, anneau de selection, remplissage de
      // progression (piste `surfaceSunken`) : sur toutes les surfaces.
      surfacesDeTexte.forEach((String surface, Color fond) {
        expect(
          contraste(p.borderStrong.debugValue, fond),
          greaterThanOrEqualTo(seuilComposant),
          reason: 'borderStrong sur $surface',
        );
        expect(
          contraste(p.surfacePrimary.background, fond),
          greaterThanOrEqualTo(seuilComposant),
          reason: 'surfacePrimary sur $surface',
        );
      });
    });

    test('chaque point de statut atteint 3:1 la ou il se pose', () {
      final List<Color> communs = <Color>[
        p.surfaceRaised.background,
        p.surfaceCanvas.background,
        p.surfaceMiseEnAvant.background,
        p.surfaceSunken.background,
      ];
      final Map<String, (AppIndicatorColor, List<Color>)> points =
          <String, (AppIndicatorColor, List<Color>)>{
            'succes': (
              p.pointsStatut.succes,
              <Color>[...communs, p.washSuccess.background],
            ),
            'attention': (
              p.pointsStatut.attention,
              <Color>[...communs, p.washWarning.background],
            ),
            'alerte': (
              p.pointsStatut.alerte,
              <Color>[...communs, p.washAlert.background],
            ),
            'neutre': (p.pointsStatut.neutre, communs),
          };
      points.forEach((String nom, (AppIndicatorColor, List<Color>) point) {
        for (final Color fond in point.$2) {
          expect(
            contraste(point.$1.debugValue, fond),
            greaterThanOrEqualTo(seuilComposant),
            reason: 'point $nom sur $fond',
          );
        }
      });
    });
  });
}
