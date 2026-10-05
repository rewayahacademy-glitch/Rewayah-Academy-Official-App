// COM-FUS (socle FilDiscussion) :
//
// - `onEnvoyerMessage` recoit l'identifiant local de la bulle : deux bulles
//   au meme texte ont deux identifiants, « Reessayer » rejoue celui de SA
//   bulle, et deux fils ouverts l'un apres l'autre ne partagent jamais un
//   identifiant (une cle d'idempotence ne passe pas d'une bulle a l'autre) ;
// - `MessageFil.complement` se pose dans la bulle, sous le texte ; un texte
//   vide n'occupe aucune ligne ;
// - a 390 en texte x2, « Envoyer » passe sous le champ, qui garde la largeur
//   de la ligne ; a 1440, ils restent sur la meme ligne.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../../support/hote_theme.dart';

class _Envois {
  final List<(String, String)> recus = <(String, String)>[];
  final List<Completer<void>> attentes = <Completer<void>>[];

  Future<void> envoyer(String id, String texte) {
    recus.add((id, texte));
    final Completer<void> a = Completer<void>();
    attentes.add(a);
    return a.future;
  }
}

Future<void> _monter(
  WidgetTester tester, {
  required Widget fil,
  Size taille = const Size(390, 844),
  double echelle = 1,
}) async {
  fixerVue(tester, taille);
  await tester.pumpWidget(
    hoteTheme(fil, defilant: false, echelleTexte: echelle),
  );
  await tester.pumpAndSettle();
}

Future<void> _ecrire(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(FilDiscussion.champKey), texte);
  await tester.pump();
  await tester.tap(find.byKey(FilDiscussion.envoyerKey));
  await tester.pump();
}

FilDiscussion _fil(_Envois envois, {Key? key}) => FilDiscussion(
  key: key,
  messages: const <MessageFil>[],
  textes: textesFilCommunication(),
  onEnvoyerMessage: envois.envoyer,
);

void main() {
  final c = t.com.socle.composants.composer;

  group('identifiant local transmis a l envoi', () {
    testWidgets('deux bulles au meme texte : deux identifiants ; '
        '« Reessayer » rejoue celui de sa bulle', (WidgetTester tester) async {
      final _Envois envois = _Envois();
      await _monter(tester, fil: _fil(envois));
      await _ecrire(tester, 'Merci');
      envois.attentes.first.completeError(Exception('reseau'));
      await tester.pumpAndSettle();
      await _ecrire(tester, 'Merci');
      expect(envois.recus, hasLength(2));
      expect(envois.recus.first.$2, envois.recus.last.$2);
      expect(envois.recus.first.$1, isNot(envois.recus.last.$1));

      await tester.tap(find.text(c.reessayer));
      await tester.pump();
      expect(envois.recus, hasLength(3));
      expect(envois.recus.last.$1, envois.recus.first.$1);
      for (final Completer<void> a in envois.attentes.skip(1)) {
        a.complete();
      }
      await tester.pumpAndSettle();
      expect(find.text(c.envoye), findsNWidgets(2));
    });

    testWidgets('deux fils l un apres l autre : jamais le meme identifiant', (
      WidgetTester tester,
    ) async {
      final _Envois premier = _Envois();
      await _monter(
        tester,
        fil: _fil(premier, key: const ValueKey<String>('a')),
      );
      await _ecrire(tester, 'Un');
      final _Envois second = _Envois();
      await _monter(
        tester,
        fil: _fil(second, key: const ValueKey<String>('b')),
      );
      await _ecrire(tester, 'Un');
      expect(second.recus.single.$1, isNot(premier.recus.single.$1));
      for (final Completer<void> a in <Completer<void>>[
        ...premier.attentes,
        ...second.attentes,
      ]) {
        a.complete();
      }
      await tester.pumpAndSettle();
    });

    testWidgets('onEnvoyer seul : le texte, comme le controleur', (
      WidgetTester tester,
    ) async {
      final List<String> textes = <String>[];
      await _monter(
        tester,
        fil: FilDiscussion(
          messages: const <MessageFil>[],
          textes: textesFilCommunication(),
          onEnvoyer: (String texte) async => textes.add(texte),
        ),
      );
      await _ecrire(tester, 'Bonjour');
      await tester.pumpAndSettle();
      expect(textes, <String>['Bonjour']);
      expect(find.text(c.envoye), findsOneWidget);
    });
  });

  testWidgets('complement : dans la bulle, sous le texte ; texte vide sans '
      'ligne', (WidgetTester tester) async {
    const Key complement = ValueKey<String>('test-complement');
    await _monter(
      tester,
      fil: FilDiscussion(
        messages: const <MessageFil>[
          MessageFil(
            id: 'm1',
            auteur: 'Mme Mariam',
            texte: 'Voici le vocal.',
            horodatage: '09:12',
            deSoi: false,
            complement: SizedBox(key: complement, height: 40, width: 40),
          ),
          MessageFil(
            id: 'm2',
            auteur: 'Mme Mariam',
            texte: '',
            horodatage: '09:13',
            deSoi: false,
            complement: SizedBox(
              key: ValueKey<String>('test-complement-seul'),
              height: 40,
              width: 40,
            ),
          ),
        ],
        textes: textesFilCommunication(),
        onEnvoyer: (String _) async {},
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('message-m1')),
        matching: find.byKey(complement),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(complement)).dy,
      greaterThan(tester.getBottomLeft(find.text('Voici le vocal.')).dy),
    );
    final Iterable<Text> textesM2 = tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('message-m2')),
        matching: find.byType(Text),
      ),
    );
    expect(textesM2.where((Text w) => w.data == ''), isEmpty);
  });

  group('saisie a texte agrandi', () {
    testWidgets('390, texte x2 : « Envoyer » sous le champ, champ pleine '
        'largeur', (WidgetTester tester) async {
      await _monter(tester, fil: _fil(_Envois()), echelle: 2);
      final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
      final Rect envoyer = tester.getRect(find.byKey(FilDiscussion.envoyerKey));
      expect(envoyer.top, greaterThanOrEqualTo(champ.bottom));
      expect(champ.width, greaterThan(300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440, texte x2 : sur la meme ligne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        fil: _fil(_Envois()),
        taille: const Size(1440, 900),
        echelle: 2,
      );
      final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
      final Rect envoyer = tester.getRect(find.byKey(FilDiscussion.envoyerKey));
      expect(envoyer.top, lessThan(champ.bottom));
      expect(envoyer.left, greaterThan(champ.right));
    });

    testWidgets('390, texte x1 : sur la meme ligne', (
      WidgetTester tester,
    ) async {
      await _monter(tester, fil: _fil(_Envois()));
      final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
      final Rect envoyer = tester.getRect(find.byKey(FilDiscussion.envoyerKey));
      expect(envoyer.top, lessThan(champ.bottom));
    });
  });
}
