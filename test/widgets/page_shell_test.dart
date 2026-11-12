import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart';

/// Le defaut que ces tests verrouillent, mesure en production le 18 septembre
/// 2026 : cinq ecrans rendaient leur titre, puis plus rien.
///
/// `PageShell` enveloppait le contenu de chaque ecran dans **son propre**
/// `Column`, pour lui ajouter une respiration de bas de page. Or un `Column`
/// donne a ses enfants non flexibles une hauteur **non bornee**. Tout ecran
/// qui gere son propre defilement — donc `defilante: false` avec un `Expanded`
/// — echouait alors a se mesurer.
///
/// Ce qui rendait le defaut invisible : en build release les assertions de
/// layout sont retirees, donc le corps disparaissait **sans une ligne d'erreur
/// en console et sans un seul appel reseau en echec**. Les tests de widgets
/// existants ne le voyaient pas non plus, parce qu'aucun ne montait un ecran
/// non defilant a travers `PageShell`.
///
/// Ecrans concernes : `ADM-07`, `ADM-04`, `CTR-01`, le suivi eleve et
/// `TUT-06`. La dette etait deja ecrite dans la fiche `TUT-00b` du catalogue
/// d'ecrans, sans avoir jamais ete payee.
void main() {
  Widget hotePage(Widget page) => hote(
    page,
    surcharges: <Override>[
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    ],
  );

  testWidgets('un corps non defilant avec un Expanded se mesure et se peint', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hotePage(
        PageShell(
          titre: 'Acces des agents IA',
          defilante: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('en tete du corps'),
              Expanded(
                child: ListView(
                  children: const <Widget>[Text('premiere ligne de la liste')],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // L'assertion de layout est la vraie cible : sans le correctif, elle est
    // levee ici et le corps n'a aucune taille.
    expect(tester.takeException(), isNull);
    expect(find.text('Acces des agents IA'), findsOneWidget);
    expect(find.text('en tete du corps'), findsOneWidget);
    expect(find.text('premiere ligne de la liste'), findsOneWidget);
  });

  testWidgets('un corps non defilant sans Expanded se peint aussi', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hotePage(
        const PageShell(
          titre: 'Journal',
          defilante: false,
          child: Text('corps simple'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('corps simple'), findsOneWidget);
  });

  testWidgets('un corps defilant continue de defiler et de se peindre', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hotePage(
        PageShell(
          titre: 'Centre de commande',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < 40; i++) SizedBox(height: 40, child: Text('ligne $i')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ligne 0'), findsOneWidget);

    // Le mode defilant doit rester defilant : c'est lui qui porte la
    // respiration de bas de page, et le correctif ne doit pas l'avoir retiree.
    await tester.drag(find.text('ligne 0'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
