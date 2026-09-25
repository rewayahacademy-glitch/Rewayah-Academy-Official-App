// `resumeTotalSoldes` (Foyer et Accueil) respecte `complet` (constat LT-R 5) :
// un total partiel se dit comme tel, jamais comme le total du foyer.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/compte/soldes_page.dart';

AsyncValue<SoldesFoyer> _lus({required bool complet}) =>
    AsyncValue<SoldesFoyer>.data(
      SoldesFoyer(
        profils: const <SoldeProfil>[],
        totaux: const <TotalSoldes>[
          TotalSoldes(montantMineur: 2000, devise: 'EUR'),
        ],
        complet: complet,
        luLe: DateTime.utc(2026, 9, 25),
      ),
    );

void main() {
  final String total = formaterMontant(2000, 'EUR');

  test('total complet : le montant seul', () {
    expect(resumeTotalSoldes(_lus(complet: true)), total);
  });

  test('total incomplet : dit comme tel', () {
    final String? resume = resumeTotalSoldes(_lus(complet: false));
    expect(resume, t.finance.totalPartiel(total: total));
    expect(resume, isNot(total));
  });
}
