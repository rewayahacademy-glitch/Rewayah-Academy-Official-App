// COM-RC (R-25) : dans le publieur d'annonce, Ctrl+Entree (Cmd+Entree)
// fait l'action de l'etape depuis un champ (« Continuer ») ; Entree seule
// garde le saut de ligne et n'avance pas. Rejoue sur `de2bdb64`, le
// raccourci n'existait pas : l'etape restait la premiere.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/com_annonces/publieur_annonce.dart';

import 'admin_banc.dart';

void main() {
  testWidgets('390 : Ctrl+Entree passe a l etape suivante, Entree seule non', (
    WidgetTester tester,
  ) async {
    await monterPublierClasse(tester);
    await tester.enterText(
      find.byKey(PublieurAnnonce.cleTitre),
      'Sortie de fin d annee',
    );
    await tester.enterText(
      find.byKey(PublieurAnnonce.cleTexte),
      'Texte de la sortie.',
    );
    await tester.pumpAndSettle();
    expect(find.text(t.commun.etape.sur(n: 1, total: 4)), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(t.commun.etape.sur(n: 1, total: 4)), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text(t.commun.etape.sur(n: 2, total: 4)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
