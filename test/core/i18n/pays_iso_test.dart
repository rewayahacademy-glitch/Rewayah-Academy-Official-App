// La liste des pays du formulaire d'avis : complete, sans doublon, deux noms
// par pays, recherche sans accent, noms arabes sans lettre latine.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/pays_iso.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('249 pays, des codes uniques de deux lettres', () {
    expect(paysIso, hasLength(249));
    expect(paysIso.map((PaysIso p) => p.code).toSet(), hasLength(249));
    for (final PaysIso p in paysIso) {
      expect(RegExp(r'^[A-Z]{2}$').hasMatch(p.code), isTrue, reason: p.code);
      expect(p.fr.trim(), isNotEmpty, reason: p.code);
      expect(p.ar.trim(), isNotEmpty, reason: p.code);
    }
  });

  test('un nom arabe ne contient aucune lettre latine', () {
    for (final PaysIso p in paysIso) {
      expect(RegExp('[A-Za-zÀ-ÿ]').hasMatch(p.ar), isFalse, reason: p.code);
    }
  });

  test('les pays des familles de l academie y sont', () {
    for (final String code in <String>[
      'GN',
      'FR',
      'BE',
      'CA',
      'CI',
      'SN',
      'ML',
      'MA',
      'DZ',
      'TN',
      'GB',
      'US',
      'SA',
      'AE',
      'QA',
      'CH',
      'DE',
      'ES',
      'BF',
      'CM',
      'MR',
      'EG',
      'TR',
    ]) {
      expect(paysDuCode(code), isNotNull, reason: code);
    }
  });

  test('le nom suit la langue de l interface', () async {
    expect(nomDuPays('GN'), 'Guinée');
    expect(nomDuPays('gn'), 'Guinée');
    await LocaleSettings.setLocale(AppLocale.ar);
    expect(nomDuPays('GN'), 'غينيا');
    LocaleSettings.setLocaleSync(AppLocale.fr);
    // Un code inconnu ne fait jamais un trou.
    expect(nomDuPays('ZZ'), 'ZZ');
    expect(paysDuCode(null), isNull);
  });

  test('la recherche ignore accents, tirets, casse ; trouve fr et ar', () {
    expect(
      chercherPays("cote d'ivoire").map((PaysIso p) => p.code),
      contains('CI'),
    );
    expect(chercherPays('COTE').map((PaysIso p) => p.code), contains('CI'));
    expect(chercherPays('etats unis').first.code, 'US');
    expect(chercherPays('guinée').map((PaysIso p) => p.code), contains('GN'));
    expect(chercherPays('غينيا').map((PaysIso p) => p.code), contains('GN'));
    expect(chercherPays('gn').map((PaysIso p) => p.code), contains('GN'));
    expect(chercherPays('zzzz'), isEmpty);
    expect(chercherPays(''), hasLength(249));
  });

  test('la liste est triee par nom, accents ignores', () {
    final List<String> noms = chercherPays('')
        .map((PaysIso p) => formeDeRecherche(p.nom))
        .toList();
    final List<String> tries = List<String>.of(noms)..sort();
    expect(noms, tries);
  });
}
