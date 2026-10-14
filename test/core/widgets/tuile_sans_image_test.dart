// VIDEO-TUILE-1 : la tuile video sans image pose le nom centre sous le
// cercle, sur le meme axe (a 1 px pres), micro coupe ou non, a 100 et 200 %
// de texte, sans deborder de sa tuile.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';

import '../../capture/outil_capture.dart';

const Key _cercle = ValueKey<String>('tuile-sans-image-cercle');
const Key _nom = ValueKey<String>('tuile-sans-image-nom');
const Key _tuile = ValueKey<String>('tuile');

void main() {
  for (final double echelle in <double>[1, 2]) {
    for (final bool microCoupe in <bool>[false, true]) {
      for (final Size taille in const <Size>[Size(136, 124), Size(160, 200)]) {
        testWidgets('texte x$echelle, micro coupe $microCoupe, $taille', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 640), 1);
          await tester.pumpWidget(
            hoteCapture(
              Scaffold(
                body: Center(
                  child: SizedBox(
                    key: _tuile,
                    width: taille.width,
                    height: taille.height,
                    child: TuileSansImage(
                      prenom: 'Sayyid Ibrahim',
                      nom: 'Sayyid Ibrahim',
                      libelleSansImage: 'Sans image',
                      libelleMicroCoupe: microCoupe ? 'Micro coupe' : null,
                    ),
                  ),
                ),
              ),
              echelleTexte: echelle,
            ),
          );
          expect(tester.takeException(), isNull, reason: 'debordement');
          final Rect rond = tester.getRect(find.byKey(_cercle));
          final Rect nom = tester.getRect(find.byKey(_nom));
          final Rect tuile = tester.getRect(find.byKey(_tuile));
          expect((rond.center.dx - nom.center.dx).abs(), lessThanOrEqualTo(1));
          expect(
            (rond.center.dx - tuile.center.dx).abs(),
            lessThanOrEqualTo(1),
          );
          expect(nom.top, greaterThanOrEqualTo(rond.bottom));
          expect(tuile.inflate(0.5).contains(rond.topLeft), isTrue);
          expect(tuile.inflate(0.5).contains(nom.bottomRight), isTrue);
          // « Sans image » ne s'ecrit pas, il reste dans la semantique.
          expect(find.text('Sans image'), findsNothing);
          expect(find.bySemanticsLabel(RegExp('Sans image')), findsOneWidget);
        });
      }
    }
  }
}
