// BENTO-3b (m8 de BENTO-3-R) : le controle « aucun mot coupe » lui-meme.
//
// Il doit nommer un mot vraiment coupe, laisser passer un retour a la ligne
// entre deux mots, et ne pas prendre pour une coupure le glyphe d'une police
// de repli (trait d'union insecable U+2011 de « An‑Nour »), dont la boite est
// plus haute sur la MEME ligne.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../support/aucun_mot_coupe.dart';

Future<void> _monter(
  WidgetTester tester,
  String texte,
  double largeur, {
  TextStyle style = const TextStyle(fontSize: 16),
  TextDirection sens = TextDirection.ltr,
}) => _monterRiche(tester, TextSpan(text: texte, style: style), largeur, sens);

Future<void> _monterRiche(
  WidgetTester tester,
  InlineSpan texte,
  double largeur, [
  TextDirection sens = TextDirection.ltr,
]) => tester.pumpWidget(
  Directionality(
    textDirection: sens,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: largeur, child: Text.rich(texte)),
    ),
  ),
);

/// Les boites de [mot] dans le seul paragraphe monte.
List<TextBox> _boites(WidgetTester tester, String mot) {
  final RenderParagraph p = tester.renderObject<RenderParagraph>(
    find.byType(RichText),
  );
  final String texte = p.text.toPlainText();
  final int debut = texte.indexOf(mot);
  return p.getBoxesForSelection(
    TextSelection(baseOffset: debut, extentOffset: debut + mot.length),
  );
}

/// Le style des titres (`AppTypography._titre`) : DM Sans, repli Noto Sans
/// Arabic, ou le U+2011 n'existe pas et vient de la police de repli.
const TextStyle _titreReel = TextStyle(
  fontFamily: AppFontFamily.titre,
  fontFamilyFallback: AppFontFamily.repli,
  fontSize: 16,
  height: 1.3,
);

/// La largeur naturelle de [texte], sur une ligne, en police de test 16 px.
double _largeurNaturelle(String texte) {
  final TextPainter peintre = TextPainter(
    text: TextSpan(text: texte, style: const TextStyle(fontSize: 16)),
    textDirection: TextDirection.ltr,
  )..layout();
  final double largeur = peintre.width;
  peintre.dispose();
  return largeur;
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  testWidgets('un mot plus large que sa place est nomme', (
    WidgetTester tester,
  ) async {
    await _monter(tester, 'Anticonstitutionnellement', 40);
    expect(motsCoupes(tester, find.byType(Text)), <String>[
      'Anticonstitutionnellement : Anticonstitutionnellement',
    ]);
  });

  testWidgets('un retour a la ligne entre deux mots passe', (
    WidgetTester tester,
  ) async {
    // Juste la place du mot le plus long : les deux mots passent chacun
    // sur sa ligne, entiers.
    double largeurDe(String mot) => (TextPainter(
      text: TextSpan(text: mot, style: const TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    )..layout()).width;
    await _monter(
      tester,
      'Mamadou Diallo',
      largeurDe('Mamadou') + largeurDe('Diallo') / 2,
    );
    // La mesure porte sur deux lignes : le prenom, puis le nom.
    expect(tester.getSize(find.byType(Text)).height, greaterThan(30));
    expect(motsCoupes(tester, find.byType(Text)), isEmpty);
  });

  testWidgets('le trait d union insecable n est pas une coupure', (
    WidgetTester tester,
  ) async {
    await _monter(tester, 'Classe An‑Nour', 400);
    expect(motsCoupes(tester, find.byType(Text)), isEmpty);
  });

  // BENTO-3c (M8-1 de BENTO-3b-R) : le meme cas dans le bon regime. En
  // police de test, « An‑Nour » ne donne qu'une boite ; avec la vraie police
  // des titres, le U+2011 vient du repli et sa boite est plus haute, sur la
  // MEME ligne. L'ancien critere ({top arrondi}) l'y prenait pour une
  // coupure.
  for (final TextDirection sens in TextDirection.values) {
    testWidgets('vraie police, ${sens.name} : le U+2011 du repli, plus haut '
        'sur la meme ligne, n est pas une coupure', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        'Classe An‑Nour',
        400,
        style: _titreReel,
        sens: sens,
      );
      // Contexte : au moins deux boites, a des hauts differents.
      final List<TextBox> boites = _boites(tester, 'An‑Nour');
      expect(boites.length, greaterThanOrEqualTo(2));
      expect(
        <double>{for (final TextBox b in boites) b.top}.length,
        greaterThanOrEqualTo(2),
      );
      // Et une seule ligne : le paragraphe tient sur une hauteur de ligne.
      expect(tester.getSize(find.byType(Text)).height, lessThan(16 * 1.3 * 2));
      expect(motsCoupes(tester, find.byType(Text)), isEmpty);
    });
  }

  // BENTO-3c (M8-2 de BENTO-3b-R) : un mot coupe sur exactement deux
  // lignes, la seconde collee a la premiere (boites [0..16] puis [16..32]).
  // Garde le seuil du « milieu vertical » : un intervalle elargi, ou le haut
  // de la boite pris pour son milieu, ne verraient qu'une ligne.
  testWidgets('un mot coupe sur exactement deux lignes est nomme', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      'Remplacement',
      0.6 * _largeurNaturelle('Remplacement'),
    );
    // Contexte : deux boites, la seconde commence ou finit la premiere.
    final List<TextBox> boites = _boites(tester, 'Remplacement');
    expect(boites, hasLength(2));
    expect(boites[1].top, boites[0].bottom);
    expect(motsCoupes(tester, find.byType(Text)), <String>[
      'Remplacement : Remplacement',
    ]);
  });

  // BENTO-3c (d2 de M8-2) : la clause symetrique. Un mot dont la fin est
  // composee plus grand (64 px apres 16 px) : la petite boite est posee sur
  // la ligne de base, en bas de la grande. Le milieu de la grande tombe
  // au-dessus de la petite ; seul le milieu de la petite, dans la grande,
  // montre qu'elles partagent la ligne.
  for (final TextDirection sens in TextDirection.values) {
    testWidgets('${sens.name} : un mot en deux tailles sur une ligne passe', (
      WidgetTester tester,
    ) async {
      await _monterRiche(
        tester,
        const TextSpan(
          children: <InlineSpan>[
            TextSpan(text: 'Rempla', style: TextStyle(fontSize: 16)),
            TextSpan(text: 'cement', style: TextStyle(fontSize: 64)),
          ],
        ),
        800,
        sens,
      );
      final List<TextBox> boites = _boites(tester, 'Remplacement');
      expect(boites, hasLength(2));
      final TextBox petite = boites[0];
      final TextBox grande = boites[1];
      // Contexte : le milieu de la grande est hors de la petite, celui de la
      // petite dans la grande.
      final double milieuGrande = (grande.top + grande.bottom) / 2;
      final double milieuPetite = (petite.top + petite.bottom) / 2;
      expect(milieuGrande, lessThan(petite.top));
      expect(milieuPetite, inInclusiveRange(grande.top, grande.bottom));
      expect(motsCoupes(tester, find.byType(Text)), isEmpty);
    });
  }

  testWidgets('le meme nom compose, trop etroit, est nomme', (
    WidgetTester tester,
  ) async {
    await _monter(tester, 'Classe An‑Nour', 30);
    // BENTO-3c (M8-3 de BENTO-3b-R) : « Classe » est deja coupe a 30 px ;
    // c'est bien « An‑Nour » entier qui doit etre nomme.
    expect(
      motsCoupes(tester, find.byType(Text)),
      contains('Classe An‑Nour : An‑Nour'),
    );
  });
}
