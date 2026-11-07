// Captures du point 4 du pilote (07/11/2026) : l'Historique du tuteur nomme
// la Classe d'une seance passee meme quand cette Classe est quittee ou close
// (le nom vient avec la seance, `mes_seances_v.groupe_libelle`). Liste et
// detail, a 390x844 @3 et 1440x900 @1, en francais et en arabe.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Mode d'emploi : `test/capture/LISEZ-MOI.md`. Donnees : fixtures isolees,
// aucune classe courante (`avecClasses: false`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../features/historique/support_historique.dart';
import '../fixtures/tuteur/foyers.dart';
import 'outil_capture.dart';

final Map<String, String> _noms = <String, String>{
  for (final Seance s in seancesFoyerA) s.id: 'An-Nour (close)',
};

void main() {
  group('Capture : classe de la seance (point 4)', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    final List<(String, String)> ecrans = <(String, String)>[
      ('liste', Routes.tuteurSuivi),
      (
        'detail',
        '${Routes.seancePour('s-presente')}?eleve=${FoyersFictifs.a1.id}',
      ),
    ];

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final (String nom, String chemin) in ecrans) {
        for (final (Size taille, double densite) in <(Size, double)>[
          (const Size(390, 844), 3),
          (const Size(1440, 900), 1),
        ]) {
          final String format =
              '${taille.width.toInt()}x${taille.height.toInt()}@${densite.toInt()}';
          testWidgets('$format, $nom, ${langue.languageCode}', (
            WidgetTester tester,
          ) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(
              tester,
              taille,
              densite,
              zoneSure: densite == 3
                  ? const EdgeInsets.only(top: 47, bottom: 34)
                  : EdgeInsets.zero,
            );
            await monterHistorique(
              tester,
              depart: chemin,
              taille: null,
              cadre: cadreCapture,
              avecClasses: false,
              nomsClasses: _noms,
            );
            expect(find.text(t.historique.classeInconnue), findsNothing);
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 'p4_${nom}_${format}_${langue.languageCode}')}',
            );
          });
        }
      }
    }
  });
}
