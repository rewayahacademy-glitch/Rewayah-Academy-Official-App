// CHAMP-OBLIGATOIRE-2 (directeur, 08/11/2026 ; option (a) du pilote et du
// garde-cap) : la marque des champs obligatoires reste visible sur le violet
// de la marque comme sur le parchemin (WCAG 1.4.11 : 3:1 pour un element
// graphique porteur de sens). Le point est peint avec le point d'alerte de la
// palette du contexte, jamais une couleur en dur.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/champ_etiquete.dart';

import 'support/contraste.dart';

Color _couleurDuPoint(WidgetTester tester) {
  final Container point = tester.widget<Container>(
    find.byKey(const ValueKey<String>('point-rappel')),
  );
  return (point.decoration! as BoxDecoration).color!;
}

Future<void> _monter(WidgetTester tester, AppPalette palette) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.depuis(
          palette,
          InterfaceMode.standard,
          Brightness.light,
        ),
        home: const Scaffold(
          body: TitreChamp('Prénom', style: null, obligatoire: true),
        ),
      ),
    );

void main() {
  test('surMarque : le point d alerte atteint 3:1 sur le violet', () {
    final AppPalette marque = AppPalette.surMarque();
    expect(
      contraste(
        marque.pointObligatoire.debugValue,
        marque.surfaceCanvas.background,
      ),
      greaterThanOrEqualTo(seuilComposant),
    );
  });

  test('parchemin et theme sombre : la couleur d alerte, inchangee, '
      'atteint 3:1 sur le fond et la carte', () {
    for (final AppPalette palette in <AppPalette>[
      AppPalette.claire(),
      AppPalette.sombre(),
    ]) {
      // Hors de la marque, la marque reste la couleur d'alerte d'avant.
      expect(
        palette.pointObligatoire.debugValue,
        palette.surfaceAlert.background,
      );
      for (final Color fond in <Color>[
        palette.surfaceCanvas.background,
        palette.surfaceRaised.background,
      ]) {
        expect(
          contraste(palette.pointObligatoire.debugValue, fond),
          greaterThanOrEqualTo(seuilComposant),
        );
      }
    }
  });

  testWidgets('la marque des champs obligatoires lit la palette du contexte', (
    WidgetTester tester,
  ) async {
    for (final AppPalette palette in <AppPalette>[
      AppPalette.surMarque(),
      AppPalette.claire(),
    ]) {
      await _monter(tester, palette);
      // Le changement de theme s'anime : on attend la fin.
      await tester.pumpAndSettle();
      final Color point = _couleurDuPoint(tester);
      expect(point, palette.pointObligatoire.debugValue);
      expect(
        contraste(point, palette.surfaceCanvas.background),
        greaterThanOrEqualTo(seuilComposant),
      );
    }
  });
}
