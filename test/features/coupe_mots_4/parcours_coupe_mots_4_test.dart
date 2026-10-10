// COUPE-MOTS-4 (1), appelant `ParcoursOffresPage` de `ChoiceCardGroup` : les
// six questions du parcours (age, langue, lieu, niveau, objectif, moments),
// chacune en cartes de choix. 320 px, texte x2, francais (LTR) et arabe
// (RTL), Interface standard et guidee : aucun mot coupe a aucune etape.

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/parcours_offres/parcours_offres_page.dart';

import '../../parcours/faux_service_offres.dart';
import 'support_coupe_mots_4.dart';

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  preparerCoupeMots4();

  for (final AppLocale langue in languesCoupeMots4) {
    for (final InterfaceMode interface in interfacesCoupeMots4) {
      testWidgets('${langue.name} ${nomInterface(interface)} 320 x2 : les six '
          'questions du parcours', (WidgetTester tester) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[apprenantDeTest()],
        );
        await monterCoupeMots4(
          tester,
          () => const ParcoursOffresPage(eleveId: 'e1'),
          langue: langue,
          interface: interface,
          surcharges: <Override>[serviceOffresProvider.overrideWithValue(faux)],
        );
        await tester.pumpAndSettle();
        int etapes = 0;
        while (find.byType(ChoiceCardGroup).evaluate().isNotEmpty &&
            etapes < 8) {
          verifierCartesDeChoixEntieres(tester);
          etapes++;
          await _toucher(
            tester,
            find
                .descendant(
                  of: find.byType(ChoiceCardGroup),
                  matching: find.byType(Pressable),
                )
                .first,
          );
          final Finder suite = find.text(t.commun.continuer);
          if (suite.evaluate().isEmpty) break;
          await _toucher(tester, suite.last);
        }
        expect(etapes, greaterThanOrEqualTo(6));
      });
    }
  }
}
