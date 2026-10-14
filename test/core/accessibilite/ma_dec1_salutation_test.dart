// MA-DEC-1 (decision A3 = c du 27/09) : la salutation de l'Accueil du Mode
// Accessibilite est « Assalamou alaykoum, {prenom}. ». Sur l'ecran que monte
// la route /demo/accessibilite, a 320 px et texte x2, avec les vraies polices du depot :
// elle passe a la ligne entre ses mots, jamais dans un mot (COUPE-MOTS-1,
// K-61), sans ellipse.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';

import '../../capture/outil_capture.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final (String prenom, EleveDemoAccessibilite eleve)
      in <(String, EleveDemoAccessibilite)>[
        ('Mariam', EleveDemoAccessibilite.mariam),
        ('Idriss', EleveDemoAccessibilite.idriss),
      ]) {
    testWidgets('$prenom, 320 px, texte x2 : « Assalamou alaykoum, $prenom. » '
        'sans mot coupe', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(320, 640), 1);
      // L'ecran que monte la route /demo/accessibilite, ouvert sur l'Accueil.
      await tester.pumpWidget(
        hoteCapture(
          EcranAccessibiliteDemo(
            eleve: eleve,
            destinationInitiale: EcranAccessibiliteDemo.indexAccueil,
          ),
          echelleTexte: 2,
          interfaceMode: InterfaceMode.enfant,
        ),
      );
      await stabiliser(tester);

      final String salutation = 'Assalamou alaykoum, $prenom.';
      final RenderParagraph p = tester.renderObject<RenderParagraph>(
        find.text(salutation),
      );
      expect(p.maxLines, isNull, reason: 'aucune ellipse');
      final TextStyle? style = (p.text as TextSpan).style;
      for (final String mot in salutation.split(' ')) {
        final TextPainter seul = TextPainter(
          text: TextSpan(text: mot, style: style),
          textDirection: p.textDirection,
          textScaler: p.textScaler,
          maxLines: 1,
        )..layout();
        expect(
          seul.width,
          lessThanOrEqualTo(p.size.width + 0.5),
          reason: '« $mot » serait coupe en plein mot',
        );
        seul.dispose();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
