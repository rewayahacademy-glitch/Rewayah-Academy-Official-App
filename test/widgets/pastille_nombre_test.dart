// FINITIONS-MESSAGERIE (directeur, 16/11/2026) : la pastille d'un nombre est
// un cercle parfait, a texte x1 comme a texte x2.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/badge_non_lu.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';

import '../support/hote_theme.dart';

void main() {
  for (final double echelle in <double>[1, 2]) {
    for (final int n in <int>[1, 7, 12, 120]) {
      testWidgets('pastille de $n : largeur = hauteur, texte x$echelle', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          hoteTheme(PastilleNombre(nombre: n), echelleTexte: echelle),
        );
        await tester.pump();
        final Size taille = tester.getSize(find.byType(PastilleNombre));
        expect(taille.width, taille.height);
        expect(taille.width, greaterThanOrEqualTo(PastilleNombre.diametreMin));
        expect(find.text(n > 9 ? '9+' : '$n'), findsOneWidget);
      });
    }
  }

  testWidgets('cloche active : fond doux, pastille ronde de 12 en 9+', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle h = tester.ensureSemantics();
    await tester.pumpWidget(
      hoteTheme(ClocheNotifications(onPress: () {}, nonLues: 12, actif: true)),
    );
    await tester.pump();
    expect(find.text('9+'), findsOneWidget);
    final Size taille = tester.getSize(find.byType(PastilleNombre));
    expect(taille.width, taille.height);
    expect(
      tester.getSemantics(find.byType(ClocheNotifications)),
      matchesSemantics(
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        label: 'Notifications, 12 non lues',
      ),
    );
    h.dispose();
  });
}
