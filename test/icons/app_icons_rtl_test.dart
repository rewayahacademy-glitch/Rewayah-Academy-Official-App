import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';

/// Lot A1 : preuve comportementale du RTL sur les icones, pas seulement
/// « ne leve pas ».
///
/// `test/widgets/catalogue_galerie_test.dart` rejoue deja toute la galerie en
/// arabe, mais ne verifie que l'absence d'exception : rien n'y empecherait une
/// regression qui retirerait `matchTextDirection` de
/// [AppIcons.chevron] sans qu'aucun test ne le remarque, puisqu'une icone qui
/// ne se miroite plus ne leve toujours aucune exception. C'est exactement le
/// piege documente dans `docs/design/06-accessibilite.md` section 5 : les
/// icones directionnelles se miroitent, l'horloge et les icones de media ne se
/// miroitent pas.
void main() {
  group('Le miroir RTL des icones directionnelles', () {
    test(
      'chevron se miroite en RTL, sur ses deux graisses',
      () {
        expect(AppIcons.chevron.repos.matchTextDirection, isTrue);
        expect(AppIcons.chevron.actif.matchTextDirection, isTrue);
      },
    );

    test(
      'suivant (meme dessin que chevron) ne se miroite pas : '
      'c est la progression du temps, pas une ligne qui mene ailleurs',
      () {
        expect(AppIcons.suivant.repos.matchTextDirection, isFalse);
        expect(AppIcons.suivant.actif.matchTextDirection, isFalse);
        // Le meme point de code que chevron, pour documenter que la
        // distinction est un choix de miroir et non un dessin different.
        expect(AppIcons.suivant.repos.codePoint, AppIcons.chevron.repos.codePoint);
      },
    );

    test(
      'les icones de media et l heure ne se miroitent jamais '
      '(docs/design/06-accessibilite.md section 5)',
      () {
        for (final AppIcon icone in <AppIcon>[
          AppIcons.micro,
          AppIcons.microCoupe,
          AppIcons.camera,
          AppIcons.cameraCoupee,
          AppIcons.suivant,
          AppIcons.pause,
          AppIcons.cours,
        ]) {
          expect(icone.repos.matchTextDirection, isFalse);
          expect(icone.actif.matchTextDirection, isFalse);
        }
      },
    );
  });
}
