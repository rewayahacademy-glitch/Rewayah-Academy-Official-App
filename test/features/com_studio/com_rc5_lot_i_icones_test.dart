// Lot I (COM-RC5), D-FUS-9 choix a (decision du directeur du 05/10) : les
// icones « signet », « epingle » et « lien » de `AppIcons` remplacent les
// replis des Communications (cahier, texte, fleche, supports).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/com_studio/panneau_partages.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';

void main() {
  group('D-FUS-9 : icones dediees des Communications', () {
    test('le catalogue porte signet, epingle et lien, distincts', () {
      final Set<int> points = <int>{
        AppIcons.signet.repos.codePoint,
        AppIcons.epingle.repos.codePoint,
        AppIcons.lien.repos.codePoint,
      };
      expect(points, hasLength(3));
      expect(AppIcons.signet.repos.codePoint, 0xe0ea);
      expect(AppIcons.signet.actif.fontFamily, 'PhosphorFill');
      expect(points, isNot(contains(AppIcons.cahier.repos.codePoint)));
    });

    test('Studio : « Enregistres » porte le signet, plus le cahier', () {
      final Destination enregistres = CoquilleStudio.destinations().singleWhere(
        (Destination d) => d.chemin == VueStudio.enregistres.name,
      );
      expect(enregistres.icone, same(AppIcons.signet));
    });

    test('panneau du canal : epingle et lien sans piece, nature de la '
        'piece sinon', () {
      expect(
        iconeElementPartage(
          ElementPartage(
            id: 'e1',
            titre: 'Regles du canal',
            nature: NaturePartage.epingle,
          ),
        ),
        same(AppIcons.epingle),
      );
      expect(
        iconeElementPartage(
          ElementPartage(
            id: 'l1',
            titre: 'Planning partage',
            nature: NaturePartage.lien,
            hote: 'rewayah.org',
          ),
        ),
        same(AppIcons.lien),
      );
      for (final AppIcon repli in <AppIcon>[
        AppIcons.texteStructure,
        AppIcons.flecheAction,
        AppIcons.supports,
      ]) {
        expect(
          iconeElementPartage(
            ElementPartage(id: 'l2', titre: 'Lien', nature: NaturePartage.lien),
          ),
          isNot(same(repli)),
        );
      }
    });
  });
}
