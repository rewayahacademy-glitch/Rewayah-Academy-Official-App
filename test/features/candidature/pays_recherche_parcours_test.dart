// PAYS-RECHERCHE (directeur, 16/11/2026) : « Quelqu'un dit qu'il ne retrouve pas
// le Ghana dans le formulaire. » Le candidat qui s'est plaint etait dans le
// questionnaire de la salle 1, pas dans le portail : ce test joue ce parcours-la.
//
// Application en arabe, de droite a gauche : on atteint la question « pays » (de
// residence, puis de versement), on tape « Ghana » en lettres latines, le Ghana
// apparait, on le choisit, et le choix part dans le brouillon.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/candidature/choix_avec_recherche.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import 'hote_candidature.dart';

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final String champ in <String>['paysResidence', 'paysVersement']) {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      for (final String frappe in <String>['Ghana', 'gh']) {
        testWidgets(
          'interface en arabe, question $champ : « $frappe » trouve le Ghana et il se choisit (${taille.width.toInt()})',
          (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
            final FauxMaCandidature port = FauxMaCandidature();
            await monterQuestionnaire(
              tester,
              port: port,
              taille: taille,
              direction: TextDirection.rtl,
            );
            await repondreAvant(tester, champ);
            await tester.enterText(
              find.byKey(ChoixAvecRecherche.champKey),
              frappe,
            );
            await tester.pumpAndSettle();
            expect(
              find.byKey(ValueKey<String>('option-$champ-GH')),
              findsOneWidget,
              reason: 'le Ghana doit apparaitre pour « $frappe »',
            );
            await toucherCle(tester, 'option-$champ-GH');
            await continuer(tester);
            expect(port.brouillons.last[champ], 'GH');
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
