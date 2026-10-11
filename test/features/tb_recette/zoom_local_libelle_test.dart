// TB-12 (recette, captures tb12_eleve_*_1440_x2) : la phrase « Zoom local,
// sans effet sur les autres » de la rangee de l'eleve au bureau se lisait
// coupee a texte x2 (« sans effet sur les a… »). Mesure sur le rendu, avec
// les polices du depot : la phrase n'est jamais tronquee, et la rangee ne
// grandit pas au-dela du bouton « Agrandir ».

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final (Size taille, double texte) in <(Size, double)>[
    (const Size(1440, 900), 1),
    (const Size(1440, 900), 2),
    (const Size(1280, 800), 2),
  ]) {
    testWidgets(
      'eleve, ${taille.width.toInt()} x${texte.toInt()} : la phrase du zoom '
      'local est entiere',
      (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1);
        await tester.pumpWidget(
          hoteCapture(
            const DemoSallePage(
              role: RoleSeance.eleve,
              situation: SituationTb.ped03,
            ),
            echelleTexte: texte,
          ),
        );
        await stabiliser(tester);
        final Finder phrase = find.text(t.salle.seance.zoomLocal);
        expect(phrase, findsOneWidget);
        final RenderParagraph rendu = tester.renderObject(phrase);
        expect(rendu.didExceedMaxLines, isFalse);
        // La rangee garde la hauteur de sa plus haute commande.
        final Rect ligne = tester.getRect(phrase);
        final Rect zoom = tester.getRect(
          find.byKey(const ValueKey<String>('zoom-local')),
        );
        expect(ligne.height, lessThanOrEqualTo(zoom.height));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
