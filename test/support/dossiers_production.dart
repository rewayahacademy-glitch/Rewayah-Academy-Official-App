import 'package:flutter_test/flutter_test.dart';

/// Tape la premiere ligne de la file `ADM-02A` (panneau unique), comme
/// l'administrateur, pour ouvrir la revue du dossier. Sans file (vide,
/// erreur), ne fait rien.
Future<void> ouvrirPremierDossier(WidgetTester tester) async {
  final Finder lignes = find.bySemanticsLabel(RegExp('^Ouvrir le dossier'));
  if (lignes.evaluate().isEmpty) {
    return;
  }
  await tester.tap(lignes.first);
  await tester.pumpAndSettle();
}
