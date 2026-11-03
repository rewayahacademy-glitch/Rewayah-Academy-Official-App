// A3-bis (02/11/2026, point (d) du pilote du 03/11) : l'avertissement du
// titulaire dit vrai dans les deux cas. Il ne perd la seance que si un
// enseignant s'est propose pour le remplacer ; sans cela, il peut encore
// entrer.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  test(
    'avec le delai : la condition du remplacant est dite, jamais « sans cela »',
    () {
      final String titre = contenuNotificationPour(
        'remplacement_avertissement',
        const <String, dynamic>{'minutes': '5'},
      ).titre;
      expect(titre, contains('5 minutes'));
      expect(
        titre,
        contains("si un enseignant s'est proposé pour vous remplacer"),
      );
      expect(titre, isNot(contains('sans cela')));
    },
  );

  test('sans delai : la meme condition', () {
    final String titre = contenuNotificationPour(
      'remplacement_avertissement',
      const <String, dynamic>{},
    ).titre;
    expect(
      titre,
      contains("si un enseignant s'est proposé pour vous remplacer"),
    );
    expect(titre, isNot(contains('sans cela')));
  });

  test('en arabe : la condition du remplacant, plus « وإلا »', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    final String titre = contenuNotificationPour(
      'remplacement_avertissement',
      const <String, dynamic>{'minutes': '5'},
    ).titre;
    expect(titre, contains('إذا تقدّم معلم لاستبدالكم'));
    expect(titre, isNot(contains('وإلا')));
  });
}
