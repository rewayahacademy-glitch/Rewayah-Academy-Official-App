// Exposants ISO 4217 du formateur (constat LT-R 6) : une devise absente de la
// table serait lue avec deux decimales, soit un montant 100 fois trop petit.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';

void main() {
  const String nbsp = ' ';

  test('exposant 0 : aucune decimale', () {
    for (final String devise in <String>[
      'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', //
      'RWF', 'UGX', 'UYI', 'VND', 'VUV', 'XAF', 'XOF', 'XPF',
    ]) {
      expect(formaterMontant(500, devise), '500$nbsp$devise', reason: devise);
    }
  });

  test('exposant 3 : trois decimales', () {
    for (final String devise in <String>[
      'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND', //
    ]) {
      expect(
        formaterMontant(1500, devise),
        '1,500$nbsp$devise',
        reason: devise,
      );
    }
  });

  test('exposant 4 : quatre decimales', () {
    for (final String devise in <String>['CLF', 'UYW']) {
      expect(formaterMontant(12345, devise), '1,2345$nbsp$devise');
    }
  });

  test('exposant 2 par defaut (EUR, XTS)', () {
    expect(formaterMontant(1250, 'EUR'), '12,50${nbsp}EUR');
    expect(formaterMontant(-5, 'XTS'), '−0,05${nbsp}XTS');
  });
}
