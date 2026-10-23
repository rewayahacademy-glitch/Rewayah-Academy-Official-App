// L4-07 : une rangee de filtres montre trois puces au plus, puis « Plus ».
// Ces aides touchent une puce quel que soit l'endroit ou elle est : dans la
// rangee, ou rangee sous « Plus » (dont elles ouvrent la feuille, puis la
// referment).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';

/// La puce « Plus » de la rangee, quand elle est posee.
Finder puceFiltresPlus() => find
    .byWidgetPredicate(
      (Widget w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('rangee-filtres-plus-'),
    )
    .hitTestable();

/// Vrai quand [puce] est posee dans la rangee (on peut la toucher), sans
/// ouvrir « Plus ».
bool puceDansLaRangee(Finder puce) => puce.hitTestable().evaluate().isNotEmpty;

/// Amene la rangee de filtres dans la vue de la page (un ecran defilant peut
/// l'avoir laissee au-dessus ou au-dessous).
Future<void> _amenerLaRangee(WidgetTester tester) async {
  final Finder rangee = find.byType(RangeeFiltres);
  if (rangee.evaluate().isEmpty) return;
  await tester.ensureVisible(rangee.first);
  await tester.pumpAndSettle();
}

/// Ouvre la feuille de « Plus » (rien si elle est deja ouverte).
Future<void> ouvrirPlus(WidgetTester tester) async {
  if (find.byType(AppBottomSheet).evaluate().isNotEmpty) return;
  await _amenerLaRangee(tester);
  await tester.tap(puceFiltresPlus().first);
  await tester.pumpAndSettle();
}

/// Ferme la feuille de « Plus » si elle est ouverte.
Future<void> fermerPlus(WidgetTester tester) async {
  final Finder feuille = find.byType(AppBottomSheet);
  if (feuille.evaluate().isEmpty) return;
  Navigator.of(tester.element(feuille)).pop();
  await tester.pumpAndSettle();
}

/// Touche [puce] : dans la rangee si elle y est, sinon dans la feuille de
/// « Plus », qui se referme ensuite.
Future<void> toucherFiltre(WidgetTester tester, Finder puce) async {
  await _amenerLaRangee(tester);
  if (puceDansLaRangee(puce)) {
    await tester.tap(puce.hitTestable().first);
    await tester.pumpAndSettle();
    return;
  }
  await ouvrirPlus(tester);
  await tester.tap(puce.hitTestable().first);
  await tester.pumpAndSettle();
  await fermerPlus(tester);
}

/// Ouvre le menu d'une puce [MenuFiltre] : dans la rangee si elle y est,
/// sinon depuis la feuille de « Plus », qui reste ouverte (le menu est
/// au-dessus ; [fermerPlus] la referme une fois la valeur choisie).
Future<void> ouvrirMenuFiltre(WidgetTester tester, Finder menu) async {
  await _amenerLaRangee(tester);
  if (puceDansLaRangee(menu)) {
    await tester.tap(menu.hitTestable().first);
    await tester.pumpAndSettle();
    return;
  }
  await ouvrirPlus(tester);
  await tester.tap(menu.hitTestable().first);
  await tester.pumpAndSettle();
}
