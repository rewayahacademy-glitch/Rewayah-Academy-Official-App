// MA-GR-1 : dans un GroupeReglages, la valeur courte (« Active ») va au bord
// de fin de la ligne quand libelle et valeur tiennent sur une ligne ; sinon
// elle passe dessous, sans mot coupe ni debordement.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';

import '../support/hote_theme.dart';

const String _libelle = 'Mode Accessibilité';
const String _valeur = 'Activé';

Widget _groupe() => const GroupeReglages(
  lignes: <LigneRubrique>[
    LigneRubrique(
      icone: AppIcons.reglages,
      libelle: _libelle,
      legende: 'Une présentation plus simple et plus grande.',
      valeur: _valeur,
    ),
  ],
);

void main() {
  testWidgets('1440 : la valeur est collee au bord de fin de la ligne', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, vueBureau);
    await tester.pumpWidget(hoteTheme(_groupe()));
    expect(tester.takeException(), isNull);

    final Rect libelle = tester.getRect(find.text(_libelle));
    final Rect valeur = tester.getRect(find.text(_valeur));
    final Rect groupe = tester.getRect(find.byType(GroupeReglages));

    // Meme ligne que le libelle.
    expect(valeur.top, lessThan(libelle.bottom));
    // Au bord de fin : seule la marge de fin de ligne la separe du bord.
    expect(valeur.right, moreOrLessEquals(groupe.right - AppSpacing.lg));
    // Et non plus collee au libelle.
    expect(valeur.left - libelle.right, greaterThan(AppSpacing.md * 10));
  });

  testWidgets('390 a 200 % : la valeur passe dessous, aucun debordement', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, vueMobile);
    await tester.pumpWidget(hoteTheme(_groupe(), echelleTexte: 2));
    expect(tester.takeException(), isNull);

    final Rect libelle = tester.getRect(find.text(_libelle));
    final Rect valeur = tester.getRect(find.text(_valeur));
    final Rect groupe = tester.getRect(find.byType(GroupeReglages));

    expect(valeur.top, greaterThanOrEqualTo(libelle.bottom));
    // Seule sur sa ligne, la valeur reste au bord de debut, sous le libelle.
    expect(valeur.left, moreOrLessEquals(libelle.left));
    expect(valeur.right, lessThanOrEqualTo(groupe.right));
    expect(libelle.right, lessThanOrEqualTo(groupe.right));
  });
}
