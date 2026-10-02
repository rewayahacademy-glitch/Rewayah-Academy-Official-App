// ETATS-BTN-1 : l'outil du Teaching Dock se lit par un plein contraste quand il
// est arme, contre un contour seul (fond transparent) quand il ne l'est pas.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_contour.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/features/tc_dock/bouton_outil.dart';

import '../../support/hote_theme.dart';

BoxDecoration _decoration(WidgetTester tester) {
  final Finder boite = find.descendant(
    of: find.byType(BoutonOutil),
    matching: find.byType(DecoratedBox),
  );
  return tester.widget<DecoratedBox>(boite.first).decoration as BoxDecoration;
}

void main() {
  for (final Brightness luminosite in Brightness.values) {
    testWidgets('outil arme : plein ; inactif : contour seul, ${luminosite.name}', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(1440, 900));
      Widget outil({required bool retenu}) => hoteTheme(
        Center(
          child: BoutonOutil(
            icone: AppIcons.micro,
            libelle: 'Outil',
            retenu: retenu,
            onPress: () {},
          ),
        ),
        luminosite: luminosite,
        defilant: false,
      );
      await tester.pumpWidget(outil(retenu: true));
      final AppPalette palette = AppPalette.of(
        tester.element(find.byType(BoutonOutil)),
      );
      final BoxDecoration plein = _decoration(tester);
      expect(plein.color, palette.surfaceInverse.background);
      expect(plein.border, isNull);

      await tester.pumpWidget(outil(retenu: false));
      final BoxDecoration repos = _decoration(tester);
      expect(repos.color, isNull, reason: 'fond transparent');
      expect(repos.border, isNotNull, reason: 'contour seul');
      expect((repos.border! as Border).top.width, AppContour.fort);
    });
  }
}
