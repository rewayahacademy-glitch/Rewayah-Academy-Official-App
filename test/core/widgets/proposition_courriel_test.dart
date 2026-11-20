// PE-A8 : la proposition d'adresse sous un champ. Ce que le test prouve : rien
// ne s'affiche pour une adresse juste ; une faute de domaine fait apparaitre
// « Vouliez-vous dire ... ? » ; rien ne change sans toucher ; le toucher
// remplace l'adresse, appelle le rappel, et la proposition disparait ; en arabe,
// l'adresse reste isolee dans la phrase.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/proposition_courriel.dart';

import '../../support/harnais.dart';

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  testWidgets('proposee, jamais imposee ; acceptee d un toucher', (
    WidgetTester tester,
  ) async {
    final TextEditingController champ = TextEditingController();
    addTearDown(champ.dispose);
    int acceptee = 0;
    await tester.pumpWidget(
      hote(
        Scaffold(
          body: Column(
            children: <Widget>[
              TextField(controller: champ),
              PropositionCourriel(
                controleur: champ,
                onAccepte: () => acceptee++,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(PropositionCourriel.cleLien), findsNothing);

    champ.text = 'awa@gmail.com';
    await tester.pump();
    expect(find.byKey(PropositionCourriel.cleLien), findsNothing);

    champ.text = 'awa@gmial.com';
    await tester.pump();
    expect(
      find.text(t.formulaire.courrielPropose(adresse: 'awa@gmail.com')),
      findsOneWidget,
    );
    // Rien ne change sans toucher.
    expect(champ.text, 'awa@gmial.com');
    expect(acceptee, 0);

    await tester.tap(find.byKey(PropositionCourriel.cleLien));
    await tester.pump();
    expect(champ.text, 'awa@gmail.com');
    expect(acceptee, 1);
    expect(find.byKey(PropositionCourriel.cleLien), findsNothing);
  });

  test('en arabe, l adresse est isolee dans la phrase', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    expect(
      t.formulaire.courrielPropose(adresse: 'awa@gmail.com'),
      contains('\u2068awa@gmail.com\u2069'),
    );
  });
}
