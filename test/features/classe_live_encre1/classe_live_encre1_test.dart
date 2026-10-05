// CLASSE-LIVE-ENCRE-1 : le texte de la salle vide (« Vous etes seul dans la
// salle pour le moment ») etait ecrit avec l'encre du fond creme, donc en encre
// sombre sur le fond sombre de PageImmersive en theme clair. Il prend
// maintenant l'encre de la paire du registre : 4,5:1 minimum sur le fond, en
// clair comme en sombre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../../capture/outil_capture.dart' show fixerVueCapture, stabiliser;
import '../../theme/support/contraste.dart';
import '../ens_pays1/support_ens_pays1.dart';

void main() {
  for (final (Size taille, double echelle, String nom)
      in <(Size, double, String)>[
        (const Size(390, 844), 1, '390'),
        (const Size(320, 700), 2, '320 x2'),
      ]) {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('seul dans la salle : encre lisible sur le fond, '
          '$nom, ${mode.name}', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1);
        await tester.pumpWidget(
          hotePays(classeLiveTuteur(), theme: mode, echelle: echelle),
        );
        await stabiliser(tester);

        final Finder texte = find.text(t.tc.classe.scene.vide);
        expect(texte, findsOneWidget);
        final RichText rendu = tester.widget<RichText>(
          find.descendant(of: texte, matching: find.byType(RichText)),
        );
        final Color encre = rendu.text.style!.color!;
        final Color fond = tester
            .widget<Scaffold>(find.byType(Scaffold).first)
            .backgroundColor!;

        expect(
          contraste(encre, fond),
          greaterThanOrEqualTo(seuilTexte),
          reason: 'encre $encre sur fond $fond',
        );
      });
    }
  }
}
