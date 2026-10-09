// COM-F : composer texte des communications = FilDiscussion (CT-6) avec ses
// emplacements optionnels. Sans emplacement, le fil est exactement celui du
// controleur (deux enfants : la liste et la saisie) ; l'emplacement vocal est
// vide par defaut et, rempli, se pose sous le champ ; la piece jointe au-dessus
// du champ ; l'en-tete au-dessus des messages. Les textes des communications
// disent « non confirme », jamais « non envoye ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../../support/hote_theme.dart';

const Key _vocal = ValueKey<String>('test-emplacement-vocal');
const Key _pj = ValueKey<String>('test-emplacement-pj');
const Key _entete = ValueKey<String>('test-entete');

final List<MessageFil> _messages = <MessageFil>[
  const MessageFil(
    id: 'm1',
    auteur: 'Administration',
    texte: 'Bonjour, la seance de jeudi est confirmee.',
    horodatage: '09:12',
    deSoi: false,
  ),
];

Future<void> _monter(
  WidgetTester tester, {
  Future<void> Function(String)? onEnvoyer,
  Widget? vocal,
  Widget? pj,
  Widget? entete,
  Size taille = const Size(390, 844),
  double echelle = 1,
}) async {
  fixerVue(tester, taille);
  await tester.pumpWidget(
    hoteTheme(
      FilDiscussion(
        messages: _messages,
        textes: textesFilCommunication(),
        onEnvoyer: onEnvoyer ?? (String _) async {},
        emplacementVocal: vocal,
        emplacementPieceJointe: pj,
        entete: entete,
      ),
      defilant: false,
      echelleTexte: echelle,
    ),
  );
  await tester.pumpAndSettle();
}

/// La colonne racine du fil.
Column _racine(WidgetTester tester) => tester.widget<Column>(
  find
      .descendant(
        of: find.byType(FilDiscussion),
        // La racine est une ColonneCorps (SUPERPOS-1), une Column.
        matching: find.byWidgetPredicate((Widget w) => w is Column),
      )
      .first,
);

void main() {
  final c = t.com.socle.composants.composer;

  testWidgets('sans emplacement : le fil du controleur, rien de reserve', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    expect(_racine(tester).children, hasLength(2));
    expect(find.byKey(_vocal), findsNothing);
    expect(find.text(c.vocal), findsNothing);
    // SUPERPOS-1 (JONCTION-LIGNES-1) : un champ d'envoi ne montre pas son
    // etiquette, son invite la dit ; le lecteur d'ecran la lit.
    expect(
      find.bySemanticsLabel(RegExp(RegExp.escape(c.message))),
      findsWidgets,
    );
    expect(find.text(c.champVide), findsOneWidget);
  });

  testWidgets('emplacement vocal : sous le champ, l envoi texte intact', (
    WidgetTester tester,
  ) async {
    final List<String> envoyes = <String>[];
    await _monter(
      tester,
      vocal: Text(c.vocalAVenir, key: _vocal),
      onEnvoyer: (String texte) async => envoyes.add(texte),
    );
    expect(find.byKey(_vocal), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(_vocal)).dy,
      greaterThan(tester.getBottomLeft(find.byKey(FilDiscussion.champKey)).dy),
    );
    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Salam');
    await tester.pump();
    await tester.tap(find.byKey(FilDiscussion.envoyerKey));
    await tester.pumpAndSettle();
    expect(envoyes, <String>['Salam']);
    expect(find.text(c.envoye), findsOneWidget);
  });

  testWidgets('piece jointe au-dessus du champ, en-tete au-dessus du fil', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      pj: const SizedBox(key: _pj, height: 24),
      entete: const SizedBox(key: _entete, height: 24),
    );
    final double champ = tester
        .getTopLeft(find.byKey(FilDiscussion.champKey))
        .dy;
    expect(tester.getBottomLeft(find.byKey(_pj)).dy, lessThanOrEqualTo(champ));
    final double premier = tester
        .getTopLeft(find.byKey(const ValueKey<String>('message-m1')))
        .dy;
    expect(
      tester.getBottomLeft(find.byKey(_entete)).dy,
      lessThanOrEqualTo(premier),
    );
  });

  testWidgets('echec : « non confirme » et « Reessayer », saisie gardee', (
    WidgetTester tester,
  ) async {
    final Completer<void> reponse = Completer<void>();
    await _monter(tester, onEnvoyer: (String _) => reponse.future);
    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Question');
    await tester.pump();
    await tester.tap(find.byKey(FilDiscussion.envoyerKey));
    await tester.pump();
    expect(find.text(c.enCours), findsOneWidget);
    reponse.completeError(Exception('reseau'));
    await tester.pumpAndSettle();
    expect(find.text(c.nonConfirme), findsOneWidget);
    expect(find.text(c.reessayer), findsOneWidget);
    expect(find.text('Question'), findsOneWidget);
  });

  testWidgets('320 px, texte x2, tous les emplacements : aucun debordement', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      taille: const Size(320, 900),
      echelle: 2,
      vocal: Text(c.vocalAVenir, key: _vocal),
      pj: const SizedBox(key: _pj, height: 24),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(_vocal), findsOneWidget);
  });
}
