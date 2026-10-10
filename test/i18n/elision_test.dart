// L'elision « de / d' » n'existe qu'en francais (AR-ENS-1).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  // h aspire : « de Hamza » (revue croisee de LIB-DIR-1, 08/10).
  test('en francais : « d\' » devant une voyelle, « de » sinon', () {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    expect(deDevant('Al-Badr'), "d'Al-Badr");
    expect(deDevant('Hamza'), 'de Hamza');
    expect(deDevant('Nour'), 'de Nour');
  });

  test('en arabe : le nom seul, jamais « d\' » ni « de »', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    expect(deDevant('Al-Badr'), 'Al-Badr');
    expect(deDevant('Nour'), 'Nour');
    expect(
      t.enseignant.journee.cahierLigne(classe: deDevant('Al-Badr')),
      isNot(contains("d'")),
    );
  });
}
