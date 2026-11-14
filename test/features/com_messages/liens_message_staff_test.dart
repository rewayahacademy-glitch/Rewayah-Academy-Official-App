// #Ra_staff (directeur, 14/11/2026) : seuls les messages de l'equipe donnent
// des liens a ouvrir ; https seulement, jamais javascript:, data:, http ni
// une adresse avec identifiants ; la ponctuation de la phrase n'en fait pas
// partie ; le lien s'ouvre dans un nouvel onglet par l'ouvreur unique.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/ouvreur_onglet.dart';
import 'package:rewayah_academy/features/com_messages/liens_message_staff.dart';

import '../../support/harnais.dart';

void main() {
  group('liensHttps', () {
    test('https seulement, ponctuation retiree, sans doublon', () {
      expect(
        liensHttps(
          'Voici le lien : https://rewayahacademy.com/fr/cadre. '
          'Et (https://exemple.org/a?b=1), encore https://rewayahacademy.com/fr/cadre',
        ).map((Uri u) => u.toString()),
        <String>[
          'https://rewayahacademy.com/fr/cadre',
          'https://exemple.org/a?b=1',
        ],
      );
    });

    test(
      'jamais javascript:, data:, http, ni identifiants dans l\'adresse',
      () {
        for (final String t in <String>[
          'javascript:alert(1)',
          'data:text/html;base64,AAAA',
          'http://exemple.org',
          'https://moi:secret@exemple.org/',
          'ftp://exemple.org',
          'https://',
        ]) {
          expect(liensHttps(t), isEmpty, reason: t);
        }
      },
    );

    test('au plus trois liens', () {
      expect(
        liensHttps('https://a.org https://b.org https://c.org https://d.org'),
        hasLength(maxLiensParMessage),
      );
    });
  });

  group('complementAvecLiens', () {
    test('un message qui n\'est pas de l\'equipe n\'ouvre rien', () {
      expect(
        complementAvecLiens(
          pieces: null,
          equipe: false,
          texte: 'https://exemple.org',
        ),
        isNull,
      );
      expect(
        complementAvecLiens(
          pieces: null,
          equipe: true,
          texte: 'https://exemple.org',
        ),
        isA<LiensMessageStaff>(),
      );
    });
  });

  testWidgets('le lien de l\'equipe s\'ouvre dans un nouvel onglet', (
    WidgetTester tester,
  ) async {
    final List<Uri> ouverts = <Uri>[];
    await tester.pumpWidget(
      hote(
        const Scaffold(
          body: LiensMessageStaff(
            texte: 'Le cadre est ici : https://rewayahacademy.com/fr/cadre.',
          ),
        ),
        surcharges: <Override>[
          ouvreurOngletProvider.overrideWithValue((Uri u) {
            ouverts.add(u);
            return true;
          }),
        ],
      ),
    );
    await tester.tap(find.byKey(LiensMessageStaff.cle(0)));
    expect(ouverts.single.toString(), 'https://rewayahacademy.com/fr/cadre');
    expect(tester.takeException(), isNull);
  });

  testWidgets('hors navigateur, aucun lien n\'est rendu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        const Scaffold(body: LiensMessageStaff(texte: 'https://exemple.org')),
        surcharges: <Override>[ouvreurOngletProvider.overrideWithValue(null)],
      ),
    );
    expect(find.byKey(LiensMessageStaff.cle(0)), findsNothing);
  });
}
