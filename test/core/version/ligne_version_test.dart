// Decision du directeur du 03/11/2026 : « Version 0.2.0 (423) », en anglais,
// lue dans `version.json`, jamais « 0.2.0+423 ».

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/version/ligne_version.dart';

void main() {
  test('lisible : version et numero de construction', () async {
    final v = versionLisible(
      '{"app_name":"rewayah","version":"0.2.0","build_number":"423"}',
    );
    expect(v, isNotNull);
    for (final AppLocale l in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      await LocaleSettings.setLocale(l);
      // En arabe, les parametres sont isoles (U+2068 ... U+2069), invisibles.
      expect(
        libelleVersion(v!).replaceAll(RegExp('[\u2068\u2069]'), ''),
        'Version 0.2.0 (423)',
      );
    }
  });

  test('sans numero de construction : la version seule', () {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    expect(
      libelleVersion(versionLisible('{"version":"0.2.0"}')!),
      'Version 0.2.0',
    );
  });

  test('illisible : aucune version inventee', () {
    expect(versionLisible('pas du json'), isNull);
    expect(versionLisible('{"build_number":"1"}'), isNull);
    expect(versionLisible('[]'), isNull);
  });
}
