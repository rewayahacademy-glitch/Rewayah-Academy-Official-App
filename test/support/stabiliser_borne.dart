// FLUIDITE-1 et BOUTON-ATTENTE (DECISION-FLUIDITE-2026-11-07 §2) : une attente
// vivante (le reflet du squelette, l'attente d'un bouton) boucle tant que
// l'attente dure, comme le veut la decision. `pumpAndSettle` n'aboutit alors
// jamais sur un ecran qui attend encore.
//
// [stabiliserBorne] fait ce que faisait `pumpAndSettle` pour ces ecrans :
// elle avance l'horloge par pas de 100 ms jusqu'a ce que plus rien ne soit a
// redessiner, mais s'arrete au bout de [pas] pas (500 ms par defaut) au lieu de
// lever une erreur si une attente boucle encore. Le composant n'est jamais
// fige pour les tests.

import 'package:flutter_test/flutter_test.dart';

/// Avance l'horloge jusqu'au repos, ou au plus [pas] pas de 100 ms.
Future<void> stabiliserBorne(WidgetTester tester, {int pas = 5}) async {
  for (int i = 0; i < pas; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (!tester.binding.hasScheduledFrame) return;
  }
}
