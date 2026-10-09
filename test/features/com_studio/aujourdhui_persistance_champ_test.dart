// COM-STU-2 (revue), puis COM-RC (R-22) : `FilDiscussion` porte seul le
// brouillon de son champ (`cleBrouillon`), sans qu'aucun ecran ne parcoure
// l'arbre pour retrouver le controleur. Un autre champ pose avant le fil
// (recherche, vocal) n'est jamais garde. Un fil recree retrouve son
// brouillon ; un controleur donne par l'ecran est celui du brouillon.

import 'dart:io';

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
  brouillonRestaure: 'Brouillon restaure',
);

/// Un canal de test : un autre champ AVANT le fil, et un fil dont la
/// generation (sa cle) peut changer, ce qui recree son etat.
class _Canal extends StatefulWidget {
  const _Canal({this.controleur});

  final TextEditingController? controleur;

  @override
  State<_Canal> createState() => _CanalState();
}

class _CanalState extends State<_Canal> {
  int generation = 0;

  /// Recree le fil : nouvelle cle, nouvel etat.
  void recreerFil() => setState(() => generation++);

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      const TextField(key: _cleAutreChamp),
      Expanded(
        child: FilDiscussion(
          key: ValueKey<int>(generation),
          messages: const <MessageFil>[],
          textes: _textes,
          onEnvoyer: (String _) async {},
          controleur: widget.controleur,
          cleBrouillon: cleBrouillonCanal('c1'),
        ),
      ),
    ],
  );
}

Future<void> _monter(
  WidgetTester tester,
  PortBrouillons port, {
  TextEditingController? controleur,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [portBrouillonsProvider.overrideWithValue(port)],
      child: MaterialApp(
        theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
        home: Scaffold(body: _Canal(controleur: controleur)),
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

  testWidgets('le brouillon est remis dans le champ du fil, pas ailleurs, '
      'avec « Brouillon restaure » jusqu a la premiere frappe', (
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
    expect(find.byKey(FilDiscussion.cleBrouillonRestaure), findsOneWidget);

    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Texte repris');
    await tester.pump();
    expect(find.byKey(FilDiscussion.cleBrouillonRestaure), findsNothing);
    expect(
      (await memoire.lire(cleBrouillonCanal('c1')))?.texte,
      'Texte repris',
    );
  });

  testWidgets('un fil recree retrouve son brouillon et le garde encore', (
    WidgetTester tester,
  ) async {
    final BrouillonsMemoire memoire = BrouillonsMemoire();
    await _monter(tester, memoire);
    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Avant');
    await tester.pump();

    tester.state<_CanalState>(find.byType(_Canal)).recreerFil();
    await tester.pumpAndSettle();
    expect(_texteFil(tester), 'Avant');

    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Apres');
    await tester.pump();
    expect((await memoire.lire(cleBrouillonCanal('c1')))?.texte, 'Apres');
    expect(tester.takeException(), isNull);
  });

  testWidgets('un controleur donne par l ecran est celui du champ et du '
      'brouillon ; le fil ne le libere pas', (WidgetTester tester) async {
    final BrouillonsMemoire memoire = BrouillonsMemoire();
    await memoire.enregistrer(cleBrouillonCanal('c1'), 'Remis');
    final TextEditingController controleur = TextEditingController();
    addTearDown(controleur.dispose);
    await _monter(tester, memoire, controleur: controleur);
    expect(controleur.text, 'Remis');
    expect(
      tester.widget<TextField>(find.byKey(FilDiscussion.champKey)).controller,
      same(controleur),
    );
    controleur.text = 'Ecrit par l ecran';
    await tester.pump();
    expect(
      (await memoire.lire(cleBrouillonCanal('c1')))?.texte,
      'Ecrit par l ecran',
    );
    // Le fil demonte, le controleur reste utilisable.
    await tester.pumpWidget(const SizedBox());
    controleur.text = 'encore';
    expect(controleur.text, 'encore');
  });

  test('brouillons_studio ne parcourt plus l arbre d elements (R-22)', () {
    // Contre-preuve de source : la persistance par parcours de l'arbre
    // (`visitChildren` sur la cle du champ) a disparu du Studio.
    final String source = File('lib/features/com_studio/brouillons_studio.dart')
        .readAsStringSync();
    expect(source.contains('visitChildren'), isFalse);
    expect(source.contains('PersistanceBrouillonCanal'), isFalse);
    final String canal = File('lib/features/com_studio/canal_page.dart')
        .readAsStringSync();
    expect(canal.contains('FilDiscussion.champKey'), isFalse);
  });
}
