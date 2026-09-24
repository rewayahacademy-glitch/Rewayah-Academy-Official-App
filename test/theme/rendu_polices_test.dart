import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';

/// Rendu avec les VRAIES polices du depot, et non la police de test.
///
/// Sans chargement explicite, `flutter test` dessine chaque glyphe avec sa
/// police de test (un carre de 1 em) : aucune largeur, aucun axe variable,
/// aucun debordement propre a DM Sans ou a Plus Jakarta Sans ne serait mesure.
/// Ce fichier charge `FontManifest.json` (les familles du `pubspec.yaml`),
/// puis mesure. Ce qu'il prouve : les familles sont actives, leurs axes
/// agissent sur le rendu, et le texte agrandi a 200 % ne deborde d'aucune
/// boite. Ce qu'il ne prouve pas : le jugement visuel (captures de la
/// phase 0b).

Future<void> _chargerPolicesDuDepot() async {
  final List<Object?> familles = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<Object?>;
  for (final Object? entree in familles) {
    final Map<String, Object?> famille = entree! as Map<String, Object?>;
    final FontLoader chargeur = FontLoader(famille['family']! as String);
    for (final Object? f in famille['fonts']! as List<Object?>) {
      chargeur.addFont(
        rootBundle.load((f! as Map<String, Object?>)['asset']! as String),
      );
    }
    await chargeur.load();
  }
}

double _largeur(TextStyle style, String texte) {
  final TextPainter peintre = TextPainter(
    text: TextSpan(text: texte, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final double largeur = peintre.width;
  peintre.dispose();
  return largeur;
}

const String _phrase =
    'Séance à préparer : l’élève Maïwenn révise « Ça commence » '
    'jeudi à 17 h 30, où ÉÀÇÔ çgjpq.';

void main() {
  setUpAll(_chargerPolicesDuDepot);

  test('DM Sans et Plus Jakarta Sans sont reellement chargees', () {
    const TextStyle sonde = TextStyle(fontSize: 20);
    final double inconnue = _largeur(
      sonde.copyWith(fontFamily: 'FamilleInexistante'),
      'iiiiiiiiii',
    );
    for (final String famille in <String>[
      AppFontFamily.titre,
      AppFontFamily.corps,
    ]) {
      expect(
        _largeur(sonde.copyWith(fontFamily: famille), 'iiiiiiiiii'),
        lessThan(inconnue * 0.6),
        reason: '$famille rendue en police de test',
      );
    }
  });

  test('l axe opsz de DM Sans agit : dessin de titre plus serre qu a 9', () {
    final TextStyle titre = AppTypography.standard.headlineLarge!;
    final TextStyle opsz9 = titre.copyWith(
      fontVariations: const <FontVariation>[
        FontVariation('wght', 700),
        FontVariation('opsz', 9),
      ],
    );
    expect(
      _largeur(titre, 'Séance à préparer'),
      lessThan(_largeur(opsz9, 'Séance à préparer')),
    );
  });

  test('l axe wght agit sur les deux familles', () {
    for (final TextStyle s in <TextStyle>[
      AppTypography.standard.titleLarge!,
      AppTypography.standard.bodyLarge!,
    ]) {
      final TextStyle maigre = s.copyWith(
        fontVariations: <FontVariation>[
          const FontVariation('wght', 300),
          ...?s.fontVariations?.where((FontVariation v) => v.axis != 'wght'),
        ],
      );
      final TextStyle gras = s.copyWith(
        fontVariations: <FontVariation>[
          const FontVariation('wght', 800),
          ...?s.fontVariations?.where((FontVariation v) => v.axis != 'wght'),
        ],
      );
      expect(
        _largeur(maigre, 'Réglages'),
        lessThan(_largeur(gras, 'Réglages')),
        reason: s.fontFamily,
      );
    }
  });

  test('AppTypography.graisse change reellement le rendu', () {
    // Revue phase 0 (jetons D1) : `copyWith(fontWeight:)` seul rendait la
    // meme largeur que le style d'origine. La graisse passe par l'axe.
    for (final (TextStyle base, FontWeight poids) cas
        in <(TextStyle, FontWeight)>[
          (AppTypography.standard.labelMedium!, FontWeight.w600),
          (AppTypography.standard.bodyLarge!, FontWeight.w600),
          (AppTypography.standard.titleLarge!, FontWeight.w700),
        ]) {
      expect(
        _largeur(AppTypography.graisse(cas.$1, cas.$2), 'Réglages Rewayah'),
        greaterThan(_largeur(cas.$1, 'Réglages Rewayah')),
        reason: '${cas.$1.fontFamily} ${cas.$2}',
      );
    }
  });

  test('le style chiffre aligne les chiffres, DM Sans ne le ferait pas', () {
    final TextStyle chiffre = AppTypography.chiffre(taille: 20);
    expect(_largeur(chiffre, '1111'), closeTo(_largeur(chiffre, '0000'), 0.01));
    final TextStyle titre = AppTypography.standard.titleLarge!;
    expect(_largeur(titre, '1111'), isNot(closeTo(_largeur(titre, '0000'), 1)));
  });

  testWidgets('texte a 200 % sur 390 px : aucun role ne deborde de sa boite', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final ThemeData theme = AppTheme.pour(
      InterfaceMode.standard,
      Brightness.light,
    );
    final TextTheme t = theme.textTheme;
    final Map<String, TextStyle> styles = <String, TextStyle>{
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
      'chiffre': AppTypography.chiffre(),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 6000),
            textScaler: TextScaler.linear(2),
          ),
          child: Material(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final MapEntry<String, TextStyle> e in styles.entries)
                    Text(
                      e.key == 'chiffre' ? '01:42 1/2 4821' : _phrase,
                      key: ValueKey<String>(e.key),
                      style: e.value,
                    ),
                  const ActionPrincipale(
                    libelle: 'Voir la classe de Maïwenn',
                    onPress: _rien,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final MapEntry<String, TextStyle> e in styles.entries) {
      final RenderParagraph rp = tester.renderObject<RenderParagraph>(
        find.byKey(ValueKey<String>(e.key)),
      );
      // La boite du paragraphe contient tout son texte : rien n'est coupe.
      expect(rp.textSize.height, lessThanOrEqualTo(rp.size.height + 0.01));
      expect(rp.textSize.width, lessThanOrEqualTo(rp.size.width + 0.01));
      // La hauteur de ligne suit le facteur 2 : aucun plafond de l'echelle
      // ne comprime le texte agrandi.
      final double ligne = e.value.fontSize! * 2 * e.value.height!;
      expect(rp.size.height, greaterThanOrEqualTo(ligne - 0.01), reason: e.key);
      final double lignes = rp.size.height / ligne;
      expect(lignes, closeTo(lignes.roundToDouble(), 0.01), reason: e.key);
    }
  });
}

void _rien() {}
