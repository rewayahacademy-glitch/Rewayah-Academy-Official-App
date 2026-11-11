// MOTS-CAHIER (pilote et garde-cap, 11/11/2026) : la page Evaluations de la
// direction affiche les resultats avec les mots de mots-rewayah section 4
// (« Étape validée », « Quelques points sont à renforcer », « Une nouvelle
// vérification est nécessaire »), jamais « Réussi », « Échec » ni « À
// revoir ». Donnees fictives, 390, francais et arabe.
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_evaluations.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_pedagogie_evaluations/evaluations_page.dart';

import 'outil_capture.dart';

final DateTime _jour = DateTime(2026, 11, 10);

EvaluationAdmin _evaluation(int i, ResultatEvaluation resultat) =>
    EvaluationAdmin(
      id: 'e$i',
      studentId: 's$i',
      identifiant: 'RA-26-00${i + 1}0',
      prenom: <String>['Maryam', 'Yusuf', 'Aya'][i],
      nom: 'Exemple',
      niveauId: 'n1',
      niveauNomHumain: 'Les sourates courtes',
      type: TypeEvaluation.periodique,
      statut: StatutEvaluation.realisee,
      datePrevue: _jour,
      dateRealisee: _jour,
      resultat: resultat,
      notes: null,
    );

void main() {
  group('Capture : resultats des evaluations', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 1400), 2);
        await tester.pumpWidget(
          hoteCapture(
            const EvaluationsPage(),
            surcharges: <Override>[
              evaluationsProvider.overrideWith(
                (Ref _) async => <EvaluationAdmin>[
                  _evaluation(0, ResultatEvaluation.reussi),
                  _evaluation(1, ResultatEvaluation.aRevoir),
                  _evaluation(2, ResultatEvaluation.echec),
                ],
              ),
            ],
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        expect(
          find.textContaining(t.admin.evaluations.resultatReussi),
          findsWidgets,
        );
        expect(
          find.textContaining(t.admin.evaluations.resultatEchec),
          findsWidgets,
        );
        debugPrint(
          'PNG ${await capturer(tester, 'evaluations_resultats_$nom')}',
        );
      });
    }
  });
}
