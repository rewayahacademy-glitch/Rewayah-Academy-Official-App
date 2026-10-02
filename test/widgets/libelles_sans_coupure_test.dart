// THEME-SW-1 et MA-NAV-1 : a 320 px, texte x1 et x2, aucun libelle d'un mot
// n'est coupe au milieu (« Systeme », « Accueil »), sans ellipse, et le
// libelle de l'onglet actif du Mode Accessibilite garde 4 px au moins de
// chaque cote de sa pastille. Mesure faite avec les vraies polices du depot.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/selecteur_theme.dart';

import '../capture/outil_capture.dart';

/// Le mot [mot] tient sur une seule ligne dans son paragraphe : la largeur du
/// mot a l'echelle reellement appliquee ne depasse pas celle du paragraphe,
/// et le paragraphe n'a qu'une ligne.
void _attendreUneLigne(WidgetTester tester, String mot) {
  final RenderParagraph p = tester.renderObject<RenderParagraph>(
    find.text(mot),
  );
  final TextPainter seul = TextPainter(
    text: p.text,
    textDirection: p.textDirection,
    textScaler: p.textScaler,
    maxLines: 1,
  )..layout();
  expect(seul.width, lessThanOrEqualTo(p.size.width + 0.5), reason: mot);
  expect(p.size.height, lessThan(seul.height * 1.5), reason: mot);
  expect(p.maxLines, isNull, reason: '$mot : aucune ellipse');
  seul.dispose();
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
  });

  for (final double echelle in <double>[1, 2]) {
    for (final double marge in <double>[16, 24]) {
      testWidgets(
        'THEME-SW-1 : 320 px, texte x${echelle.toInt()}, marge $marge : '
        'aucun libelle coupe',
        (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(320, 900), 1);
          await tester.pumpWidget(
            hoteCapture(
              Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(marge),
                  child: const SelecteurTheme(),
                ),
              ),
              echelleTexte: echelle,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          for (final String libelle in <String>[
            t.compte.themeClair,
            t.compte.themeSysteme,
            t.compte.themeSombre,
          ]) {
            _attendreUneLigne(tester, libelle);
          }
        },
      );
    }

    for (final InterfaceMode mode in <InterfaceMode>[InterfaceMode.enfant]) {
      testWidgets(
        'MA-NAV-1 : 320 px, texte x${echelle.toInt()}, ${mode.name} : '
        'Accueil sur une ligne, 4 px de chaque cote',
        (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(320, 640), 1);
          await tester.pumpWidget(
            hoteCapture(
              Scaffold(
                body: NavShell(
                  destinations: destinationsPour(
                    role: AppRole.student,
                    mode: mode,
                  ),
                  indexActif: 0,
                  onAller: (String _) {},
                  child: const SizedBox.expand(),
                ),
              ),
              echelleTexte: echelle,
              interfaceMode: mode,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          final String accueil = t.nav.eleve.accueil;
          _attendreUneLigne(tester, accueil);
          final Rect texte = tester.getRect(find.text(accueil));
          final Rect pastille = tester.getRect(
            find
                .ancestor(
                  of: find.text(accueil),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          expect(texte.left - pastille.left, greaterThanOrEqualTo(4));
          expect(pastille.right - texte.right, greaterThanOrEqualTo(4));
        },
      );
    }
  }
}
