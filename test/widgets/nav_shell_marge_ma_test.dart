// INTEG-MINEURS-1 point 1 : la barre basse du Mode Accessibilite, avec ses
// quatre onglets, garde sa marge laterale (la gouttiere de 4, `AppSpacing.xs`)
// a 320, texte x1 et x2, clair et sombre, LTR et RTL. Avant, la marge tombait
// a zero des que les minimums des onglets ne tenaient pas, et la barre
// touchait les deux bords de l'ecran.
//
// Vraies polices du depot (comme les captures) : la police de test, un em par
// lettre, ne dit rien de la marge reelle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
  });

  for (final double echelle in <double>[1, 2]) {
    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets(
        'Mode Accessibilite, 4 onglets, 320 x${echelle.toInt()}, ${theme.name} : '
        'marge laterale de ${AppSpacing.xs} de chaque cote',
        (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(320, 640), 1);
          await tester.pumpWidget(
            hoteCapture(
              Scaffold(
                body: NavShell(
                  destinations: destinationsPour(
                    role: AppRole.student,
                    mode: InterfaceMode.enfant,
                  ),
                  indexActif: 0,
                  onAller: (String _) {},
                  child: const SizedBox.expand(),
                ),
              ),
              themeMode: theme,
              echelleTexte: echelle,
              interfaceMode: InterfaceMode.enfant,
            ),
          );
          await stabiliser(tester);
          final Rect barre = tester.getRect(
            find
                .descendant(
                  of: find.byKey(NavShell.barreBasseKey),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          expect(barre.left, AppSpacing.xs);
          expect(320 - barre.right, AppSpacing.xs);
          // Aucun mot n'est coupe pour autant (TexteSansCoupure).
          expect(
            motsCoupes(tester, find.byKey(NavShell.barreBasseKey)),
            isEmpty,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
