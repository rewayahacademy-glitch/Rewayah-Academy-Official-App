// CPT-DIR-1 : la lecture des saisies (jamais un double, aucune borne
// commerciale : R-FIN-08, 09).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/features/admin_finance/reserve_delegation/saisie_politique.dart';

void main() {
  group('lireMontant', () {
    test('10 USD et 1 000 000 USD se lisent pareil, en unites mineures', () {
      expect(lireMontant('10', 'USD'), const Montant(1000, 'USD'));
      expect(lireMontant('1000000', 'USD'), const Montant(100000000, 'USD'));
      expect(lireMontant('1 000 000', 'USD'), const Montant(100000000, 'USD'));
      expect(lireMontant('1 000 000', 'USD'), const Montant(100000000, 'USD'));
    });

    test('les centimes, avec virgule ou point, sans passer par un double', () {
      expect(lireMontant('12,5', 'USD'), const Montant(1250, 'USD'));
      expect(lireMontant('12.05', 'USD'), const Montant(1205, 'USD'));
      expect(lireMontant('0,07', 'USD'), const Montant(7, 'USD'));
      // 0,1 + 0,2 ne derive jamais : des entiers.
      expect(lireMontant('0,3', 'USD')!.mineur, 30);
    });

    test('une devise sans decimale refuse les centimes', () {
      expect(lireMontant('500', 'GNF'), const Montant(500, 'GNF'));
      expect(lireMontant('500,5', 'GNF'), isNull);
    });

    test('vide, zero, negatif, lettres, trop de decimales : illisibles', () {
      for (final String s in <String>[
        '',
        '  ',
        '0',
        '0,00',
        '-5',
        'abc',
        '12,345',
        '1,2,3',
      ]) {
        expect(lireMontant(s, 'USD'), isNull, reason: '"$s"');
      }
    });

    test(
      'douze chiffres entiers au plus : limite de l entier, pas de plage',
      () {
        expect(lireMontant('999999999999', 'USD'), isNotNull);
        expect(lireMontant('1000000000000', 'USD'), isNull);
      },
    );
  });

  group('lirePourMille', () {
    test('un pourcentage a une decimale, en pour mille', () {
      expect(lirePourMille('10'), 100);
      expect(lirePourMille('12,5'), 125);
      expect(lirePourMille('100'), 1000);
      expect(lirePourMille('0,1'), 1);
    });

    test('zero, plus de 100 et deux decimales sont refuses', () {
      expect(lirePourMille('0'), isNull);
      expect(lirePourMille('100,1'), isNull);
      expect(lirePourMille('12,55'), isNull);
      expect(lirePourMille(''), isNull);
    });
  });

  test('lireEntier : un entier strictement positif', () {
    expect(lireEntier('3'), 3);
    expect(lireEntier('36'), 36);
    expect(lireEntier('0'), isNull);
    expect(lireEntier('2,5'), isNull);
    expect(lireEntier(''), isNull);
  });

  test('les textes de champ relisent ce qu ils ecrivent', () {
    for (final Montant m in <Montant>[
      const Montant(1000, 'USD'),
      const Montant(1250, 'USD'),
      const Montant(7, 'USD'),
      const Montant(100000000, 'USD'),
    ]) {
      expect(lireMontant(texteMontant(m), m.devise), m);
    }
    expect(texteMontant(null), '');
    expect(textePourMille(125), '12,5');
    expect(textePourMille(800), '80');
    expect(lirePourMille(textePourMille(800)), 800);
    expect(textePourMille(null), '');
    expect(texteEntier(14), '14');
    expect(texteEntier(null), '');
  });
}
