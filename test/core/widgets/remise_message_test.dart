// MESSAGERIE-LU (directeur, 14/11/2026, « comme WhatsApp ») : sous un message
// de soi, « Envoye » (une coche, encre discrete) puis « Lu » (deux coches,
// encre d'accent) une fois que l'autre partie l'a lu ; toujours avec la date.
// Jamais la couleur seule : l'icone et le mot changent aussi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/lecture_fil_communication.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../../support/harnais.dart';

const Participant _moi = Participant(
  id: 'moi',
  nomAffiche: 'Moi',
  estSoi: true,
);
const Participant _autre = Participant(id: 'autre', nomAffiche: 'Autre');

MessageCommunication _message(String id, Participant auteur, DateTime le) =>
    MessageCommunication(
      id: id,
      auteur: auteur,
      texte: 'Texte $id',
      envoyeLe: le,
    );

void main() {
  final DateTime h9 = DateTime.utc(2026, 11, 14, 9);
  final DateTime h10 = DateTime.utc(2026, 11, 14, 10);

  test('envoye tant que l\'autre ne l\'a pas lu, lu ensuite ; rien pour '
      'l\'autre ni sans suivi', () {
    expect(
      messageFilDe(_message('a', _moi, h9), suiviLecture: true).remise,
      RemiseMessage.envoye,
    );
    expect(
      messageFilDe(
        _message('a', _moi, h9),
        suiviLecture: true,
        luParAutresLe: h10,
      ).remise,
      RemiseMessage.lu,
    );
    expect(
      messageFilDe(
        _message('b', _moi, h10),
        suiviLecture: true,
        luParAutresLe: h9,
      ).remise,
      RemiseMessage.envoye,
    );
    expect(
      messageFilDe(
        _message('c', _autre, h9),
        suiviLecture: true,
        luParAutresLe: h10,
      ).remise,
      isNull,
    );
    expect(messageFilDe(_message('a', _moi, h9)).remise, isNull);
  });

  testWidgets('le signe et le mot sous le message, avec la date', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        Scaffold(
          body: FilDiscussion(
            messages: <MessageFil>[
              messageFilDe(
                _message('a', _moi, h9),
                suiviLecture: true,
                luParAutresLe: h10,
              ),
              messageFilDe(
                _message('b', _moi, DateTime.utc(2026, 11, 14, 11)),
                suiviLecture: true,
                luParAutresLe: h10,
              ),
            ],
            textes: textesFilCommunication(),
            lectureSeule: 'Lecture seule.',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('remise-lu')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('remise-envoye')), findsOneWidget);
    final String lu = t.com.socle.composants.composer.lu;
    final String envoye = t.com.socle.composants.composer.envoye;
    expect(find.textContaining('· $lu'), findsOneWidget);
    expect(find.textContaining('· $envoye'), findsOneWidget);
    // La date reste ecrite : « 14 novembre... » ou equivalent, jamais le mot seul.
    expect(find.text(lu), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
