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
            auteur: 'Sayyida Mariam',
            texte: 'Voici le vocal.',
            horodatage: '09:12',
            deSoi: false,
            complement: SizedBox(key: complement, height: 40, width: 40),
          ),
          MessageFil(
            id: 'm2',
            auteur: 'Sayyida Mariam',
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

  // SUPERPOS-1 (decide par delegation le 05/10), repris dans le fil des
  // Communications par JONCTION-LIGNES-1 : l'envoi est une icone DANS le
  // champ, rendue des qu'il y a un texte ; le champ prend toute la largeur
  // a toute taille de texte (plus d'« Envoyer » sous le champ).
  group('saisie a texte agrandi', () {
    Future<void> verifier(
      WidgetTester tester, {
      required Size taille,
      required double echelle,
    }) async {
      await _monter(
        tester,
        fil: _fil(_Envois()),
        taille: taille,
        echelle: echelle,
      );
      expect(find.byKey(FilDiscussion.envoyerKey), findsNothing);
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Bonjour');
      await tester.pumpAndSettle();
      final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
      final Rect envoyer = tester.getRect(find.byKey(FilDiscussion.envoyerKey));
      expect(envoyer.top, greaterThanOrEqualTo(champ.top - 0.5));
      expect(envoyer.bottom, lessThanOrEqualTo(champ.bottom + 0.5));
      expect(envoyer.left, greaterThanOrEqualTo(champ.left - 0.5));
      expect(envoyer.right, lessThanOrEqualTo(champ.right + 0.5));
      expect(champ.width, greaterThan(taille.width - 2 * 48));
      expect(tester.takeException(), isNull);
    }

    testWidgets(
      '390, texte x2 : envoi dans le champ, champ pleine largeur',
      (WidgetTester tester) =>
          verifier(tester, taille: const Size(390, 844), echelle: 2),
    );

    testWidgets(
      '1440, texte x2 : envoi dans le champ',
      (WidgetTester tester) =>
          verifier(tester, taille: const Size(1440, 900), echelle: 2),
    );

    testWidgets(
      '390, texte x1 : envoi dans le champ',
      (WidgetTester tester) =>
          verifier(tester, taille: const Size(390, 844), echelle: 1),
    );
  });
}
