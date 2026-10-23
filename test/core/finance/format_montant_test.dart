// FI-3a (guide Finance V4 §7 « Montants », §11.3 « Chiffres ») : la mise en
// mots d'un montant, seul formateur du depot.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';

/// Les espaces insecables rendues visibles dans les attentes.
String _lisible(String s) => s.replaceAll(' ', '_').replaceAll(' ', '.');

void main() {
  test(r'« 50 $ », jamais « 50$ » : une espace insecable avant la devise', () {
    expect(formaterMontant(const Montant(5000, 'USD')), '50 \$');
  });

  test('les centimes seulement quand il y en a', () {
    expect(_lisible(formaterMontant(const Montant(14320, 'USD'))), r'143,20_$');
    expect(_lisible(formaterMontant(const Montant(14305, 'USD'))), r'143,05_$');
    expect(_lisible(formaterMontant(const Montant(14500, 'USD'))), r'145_$');
  });

  test('les milliers separes par une espace fine insecable', () {
    expect(_lisible(formaterMontant(const Montant(125000, 'USD'))), r'1.250_$');
    expect(
      _lisible(formaterMontant(const Montant(123456789, 'USD'))),
      r'1.234.567,89_$',
    );
  });

  test('le signe : moins toujours (U+2212), plus sur demande', () {
    expect(
      _lisible(formaterMontant(const Montant(-500, 'USD'))),
      '${signeMoins}5_\$',
    );
    expect(
      _lisible(formaterMontant(const Montant(-500, 'USD'), signe: true)),
      '${signeMoins}5_\$',
    );
    expect(
      _lisible(formaterMontant(const Montant(500, 'USD'), signe: true)),
      r'+5_$',
    );
    expect(_lisible(formaterMontant(const Montant(500, 'USD'))), r'5_$');
    // Zero n'a pas de signe, meme demande.
    expect(
      _lisible(formaterMontant(const Montant(0, 'USD'), signe: true)),
      r'0_$',
    );
  });

  test('la devise toujours identifiable : symbole connu, sinon le code', () {
    expect(_lisible(formaterMontant(const Montant(5000, 'EUR'))), '50_€');
    expect(_lisible(formaterMontant(const Montant(5000, 'GBP'))), '50_£');
    expect(_lisible(formaterMontant(const Montant(5000, 'CAD'))), '50_CAD');
    // Une devise sans centimes : l'unite mineure est l'unite.
    expect(_lisible(formaterMontant(const Montant(5000, 'XOF'))), '5.000_XOF');
  });

  test('le montant ne passe jamais a la ligne : aucune espace secable', () {
    for (final int m in const <int>[0, 5, 5000, -500, 123456789]) {
      expect(
        formaterMontant(Montant(m, 'USD'), signe: true),
        isNot(contains(' ')),
      );
    }
  });
}
