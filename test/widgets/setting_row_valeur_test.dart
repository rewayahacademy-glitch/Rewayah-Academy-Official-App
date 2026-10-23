import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';

import '../support/harnais.dart';

/// MA-8 : la valeur de fin de ligne ne comprime jamais la colonne de gauche
/// jusqu'a couper un mot ; etroit ou texte agrandi, elle passe sous le texte.
void main() {
  Future<void> poser(
    WidgetTester tester,
    double largeur,
    double echelle,
  ) async {
    tester.view.physicalSize = Size(largeur, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      hote(
        MediaQuery(
          data: MediaQueryData(
            size: Size(largeur, 900),
            textScaler: TextScaler.linear(echelle),
          ),
          child: const SingleChildScrollView(
            child: SettingRow(
              title: 'Fuseau horaire',
              description: 'Détecté automatiquement',
              value: 'Non disponible',
              icon: AppIcons.reglages,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final (double largeur, double echelle) cas in <(double, double)>[
    (390, 1),
    (390, 2),
    (320, 1),
  ]) {
    testWidgets('valeur sous le libellé, aucun mot coupé : '
        '${cas.$1} px, texte x${cas.$2}', (WidgetTester tester) async {
      await poser(tester, cas.$1, cas.$2);
      expect(tester.takeException(), isNull);
      final Finder desc = find.text('Détecté automatiquement');
      final Finder valeur = find.text('Non disponible');
      // La description tient sur une ligne entiere ou se coupe entre mots :
      // sa largeur couvre au moins son mot le plus long.
      final double motLong = _largeurMot(tester, desc, 'automatiquement');
      final double dispo =
          tester.getSize(find.byType(SettingRow)).width - 32 - 36;
      expect(
        tester.getSize(desc).width,
        greaterThanOrEqualTo((motLong < dispo ? motLong : dispo) - 0.5),
      );
      // Disposition empilee : la valeur est sous la description.
      expect(
        tester.getTopLeft(valeur).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(desc).dy - 0.5),
      );
    });
  }

  testWidgets('large : la valeur reste en fin de ligne', (
    WidgetTester tester,
  ) async {
    await poser(tester, 1440, 1);
    expect(
      tester.getTopLeft(find.text('Non disponible')).dy,
      lessThan(tester.getBottomLeft(find.text('Détecté automatiquement')).dy),
    );
  });
}

double _largeurMot(WidgetTester tester, Finder f, String mot) {
  final RenderParagraph rendu = tester.renderObject<RenderParagraph>(
    find.descendant(of: f, matching: find.byType(RichText)).first,
  );
  final TextPainter p = TextPainter(
    text: TextSpan(text: mot, style: rendu.text.style),
    textDirection: TextDirection.ltr,
    textScaler: rendu.textScaler,
  )..layout();
  return p.width;
}
