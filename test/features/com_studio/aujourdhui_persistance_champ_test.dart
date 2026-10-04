// COM-STU-2 (revue) : `PersistanceBrouillonCanal` garde le champ du fil, et
// lui seul. Le champ est reconnu par la cle publique de `FilDiscussion`,
// jamais comme « le premier champ venu » : un autre champ pose avant le fil
// (recherche, vocal) n'est pas garde. Si le controleur du fil est recree, la
// persistance s'y rebranche et le brouillon suit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/port_brouillons.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_studio/brouillons_studio.dart';

const ValueKey<String> _cleAutreChamp = ValueKey<String>('autre-champ');

final TextesFilDiscussion _textes = TextesFilDiscussion(
  aideChamp: 'aide',
  libelleChamp: 'champ',
  envoyer: 'envoyer',
  champVide: 'vide',
  enCours: 'en cours',
  envoye: 'envoye',
  echec: 'echec',
  reessayer: 'reessayer',
  auteurSoi: 'Vous',
  annonce: (String auteur, String texte) => '$auteur $texte',
);

/// Un canal de test : un autre champ AVANT le fil, et un fil dont la
/// generation (sa cle) peut changer, ce qui recree son controleur.
class _Canal extends StatefulWidget {
  const _Canal();

  @override
  State<_Canal> createState() => _CanalState();
}

class _CanalState extends State<_Canal> {
  int generation = 0;

  /// Recree le fil : nouvelle cle, nouvel etat, nouveau controleur.
  void recreerFil() => setState(() => generation++);

  @override
  Widget build(BuildContext context) => PersistanceBrouillonCanal(
    canalId: 'c1',
    constructeur: (BuildContext _, bool _) => Column(
      children: <Widget>[
        const TextField(key: _cleAutreChamp),
        Expanded(
          child: FilDiscussion(
            key: ValueKey<int>(generation),
            messages: const <MessageFil>[],
            textes: _textes,
            onEnvoyer: (String _) async {},
          ),
        ),
      ],
    ),
  );
}

Future<void> _monter(WidgetTester tester, PortBrouillons port) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [portBrouillonsProvider.overrideWithValue(port)],
      child: MaterialApp(
        theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
        home: const Scaffold(body: _Canal()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _texteFil(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(FilDiscussion.champKey))
    .controller!
    .text;

void main() {
  testWidgets('un autre champ pose avant le fil n est jamais garde', (
    WidgetTester tester,
  ) async {
    final BrouillonsMemoire memoire = BrouillonsMemoire();
    await _monter(tester, memoire);

    await tester.enterText(find.byKey(_cleAutreChamp), 'recherche');
    await tester.pump();
    expect(await memoire.lire(cleBrouillonCanal('c1')), isNull);

    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Mon message');
    await tester.pump();
    expect((await memoire.lire(cleBrouillonCanal('c1')))?.texte, 'Mon message');
  });

  testWidgets('le brouillon est remis dans le champ du fil, pas ailleurs', (
    WidgetTester tester,
  ) async {
    final BrouillonsMemoire memoire = BrouillonsMemoire();
    await memoire.enregistrer(cleBrouillonCanal('c1'), 'Texte garde');
    await _monter(tester, memoire);
    expect(_texteFil(tester), 'Texte garde');
    expect(
      tester.widget<TextField>(find.byKey(_cleAutreChamp)).controller,
      isNull,
    );
  });

  testWidgets('un controleur recree : la persistance s y rebranche', (
    WidgetTester tester,
  ) async {
    final BrouillonsMemoire memoire = BrouillonsMemoire();
    await _monter(tester, memoire);
    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Avant');
    await tester.pump();

    // Le fil est recree (nouvel etat, nouveau controleur) : le brouillon
    // est remis, et la suite de la saisie est encore gardee.
    tester.state<_CanalState>(find.byType(_Canal)).recreerFil();
    await tester.pumpAndSettle();
    expect(_texteFil(tester), 'Avant');

    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Apres');
    await tester.pump();
    expect((await memoire.lire(cleBrouillonCanal('c1')))?.texte, 'Apres');
    expect(tester.takeException(), isNull);
  });
}
