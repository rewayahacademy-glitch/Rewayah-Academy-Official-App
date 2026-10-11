import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

void main() {
  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    test(
      '${langue.languageCode} : chaque événement affichable a un titre et un texte',
      () async {
        final Traductions tr = await langue.build();
        for (final String evenement in evenementsNotificationAffichables) {
          final ContenuNotification? contenu = contenuNotification(
            tr,
            evenement,
          );
          expect(contenu, isNotNull, reason: evenement);
          expect(contenu!.titre.trim(), isNotEmpty, reason: evenement);
          expect(contenu.texte?.trim(), isNotEmpty, reason: evenement);
        }
      },
    );

    test(
      '${langue.languageCode} : un événement inconnu ne donne aucun contenu',
      () async {
        final Traductions tr = await langue.build();
        expect(contenuNotification(tr, 'evenement_inconnu'), isNull);
        expect(contenuNotification(tr, ''), isNull);
      },
    );
  }

  test('les six titres français sont distincts', () {
    final Traductions tr = AppLocale.fr.buildSync();
    final Set<String> titres = <String>{
      for (final String e in evenementsNotificationAffichables)
        contenuNotification(tr, e)!.titre,
    };
    expect(titres.length, evenementsNotificationAffichables.length);
  });
}
