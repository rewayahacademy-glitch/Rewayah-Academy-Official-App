// PAYS-VERSEMENT : captures R3 de la question du pays de versement et du
// message « pays non pris en charge » (sautees sans CAPTURE_DIR).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/candidature/faux_ma_candidature.dart';
import 'hote_candidature.dart';

void main() {
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(1440, 900),
        const Size(390, 844),
      ]) {
        final String nom =
            'question-${taille.width.toInt()}-${langue.languageCode}';
        testWidgets(nom, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await monterQuestionnaire(
            tester,
            port: FauxMaCandidature(),
            taille: taille,
          );
          await passerLaPresentation(tester);
          for (final (String code, List<String> touches) in parcoursComplet) {
            if (code == 'paysResidence') {
              await toucherCle(tester, 'option-paysResidence-ML');
            } else if (code == 'operateurs') {
              break;
            } else {
              if (code == 'paysVersement') {
                await stabiliser(tester);
                await capturerVue(tester, 'PAYS-VERSEMENT/$nom-choix');
              }
              for (final String cle in touches) {
                await toucherCle(tester, cle);
              }
            }
            await continuer(tester);
          }
          await stabiliser(tester);
          await capturerVue(tester, 'PAYS-VERSEMENT/$nom-non-pris-en-charge');
        });
      }
    }
  }, skip: sautSansCapture);
}
