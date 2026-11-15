// COM-RC (R-25) : dans le publieur d'annonce, Ctrl+Entree (Cmd+Entree)
// fait l'action du publieur depuis un champ ; Entree seule garde le saut de
// ligne et n'envoie rien. Depuis ANNONCES-SIMPLES (un seul ecran), l'action
// est la publication elle-meme.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/com_annonces/publieur_annonce.dart';

import 'admin_banc.dart';

void main() {
  testWidgets('390 : Ctrl+Entree publie, Entree seule non', (
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
    expect(find.text(t.com.annonces.publieur.publiee), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(t.com.annonces.publieur.publiee), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text(t.com.annonces.publieur.publiee), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
