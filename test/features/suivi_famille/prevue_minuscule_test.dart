// PREVUE-MINUSCULE (08/11/2026) : au milieu d'une phrase, le jour de la
// semaine s'ecrit en minuscule (« Prévue le lundi 12 octobre ») ; en tete de
// ligne, il garde sa majuscule (« Lundi 12 octobre »).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/suivi_famille/libelles_suivi_famille.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  // Le 12 octobre 2026 est un lundi.
  final DateTime lundi = DateTime(2026, 10, 12, 17, 30);

  test('« Prévue le lundi » : jour en minuscule au milieu de la phrase', () {
    expect(datePrevueJour(lundi), 'Prévue le lundi 12 octobre');
    expect(datePrevue(lundi), startsWith('Prévue le lundi 12'));
  });

  test('en tete de ligne, le jour garde sa majuscule', () {
    expect(jourSeul(lundi), startsWith('Lundi 12'));
    expect(horodatage(lundi), startsWith('Lundi 12'));
  });
}
