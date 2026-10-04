import 'package:flutter_test/flutter_test.dart';

/// Tape la premiere ligne de la file `ADM-02A` (panneau unique), comme
/// l'administrateur, pour ouvrir la revue du dossier. Rend vrai si une ligne
/// a ete ouverte, faux si la file est vide ou en erreur (AD-NETTOYAGE-2, n11) :
/// des tests montent volontairement une file vide, donc le helper ne peut pas
/// echouer lui-meme ; tout test qui ATTEND un dossier ouvert asserte le
/// retour (`expect(await ouvrirPremierDossier(tester), isTrue, ...)`) au lieu
/// de compter sur une assertion plus loin.
Future<bool> ouvrirPremierDossier(WidgetTester tester) async {
  final Finder lignes = find.bySemanticsLabel(RegExp('^Ouvrir le dossier'));
  if (lignes.evaluate().isEmpty) {
    return false;
  }
  await tester.tap(lignes.first);
  await tester.pumpAndSettle();
  return true;
}
