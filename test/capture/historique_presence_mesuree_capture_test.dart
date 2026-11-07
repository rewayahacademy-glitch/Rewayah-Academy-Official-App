// Captures du point 3 du pilote et de la decision du directeur (07/11/2026) :
// la presence est automatique. Une seance terminee dit la presence MESUREE
// (Presence, Presence partielle et ses minutes, Retard et ses minutes,
// Absence), sans « non confirmee », et plus jamais « En cours de
// verification » pour toujours. Liste des seances et detail de la seance
// coupee (presence partielle, 23 min sur 60), a 390x844 @3 et 1440x900 @1,
// en francais et en arabe.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Mode d'emploi : `test/capture/LISEZ-MOI.md`. Donnees : fixtures isolees.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../features/historique/support_historique.dart';
import '../fixtures/tuteur/foyers.dart';
import 'outil_capture.dart';

void main() {
  group('Capture : presence mesuree (point 3)', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    final List<(String, String)> ecrans = <(String, String)>[
      ('liste', Routes.tuteurSuivi),
      (
        'detail_coupure',
        '${Routes.seancePour('s-coupure')}?eleve=${FoyersFictifs.a1.id}',
      ),
    ];

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final (String nom, String chemin) in ecrans) {
        testWidgets('390x844 @3, $nom, ${langue.languageCode}', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(
            tester,
            const Size(390, 844),
            3,
            zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
          );
          await monterHistorique(
            tester,
            depart: chemin,
            taille: null,
            cadre: cadreCapture,
          );
          expect(tester.takeException(), isNull);
          debugPrint(
            'PNG ${await capturer(tester, 'p3_${nom}_390x844@3_${langue.languageCode}')}',
          );
        });

        testWidgets('1440x900 @1, $nom, ${langue.languageCode}', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await monterHistorique(
            tester,
            depart: chemin,
            taille: null,
            cadre: cadreCapture,
          );
          expect(tester.takeException(), isNull);
          debugPrint(
            'PNG ${await capturer(tester, 'p3_${nom}_1440x900@1_${langue.languageCode}')}',
          );
        });
      }
    }
  });
}
