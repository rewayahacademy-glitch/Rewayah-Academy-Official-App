// EN-11 : captures de la Revue de Classe (ENS-08), avec anomalies et vide.
// Jamais sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).
//
// Donnees de demonstration seulement (K-35, E20) : la Classe An-Nour et ses
// eleves (`enseignant_demo.dart`) ; les anomalies elles-memes sont fictives,
// car aucune RPC d'anomalies bornee a l'enseignant n'existe encore
// (`anomalies_revue.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/features/revue_groupe/anomalies_revue.dart';
import 'package:rewayah_academy/features/revue_groupe/revue_groupe_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

const String _classe = 'demo-classe-an-nour';

final List<MembreSeance> _eleves = <MembreSeance>[
  const MembreSeance(
    studentId: 'demo-eleve-yusuf',
    identifiantImmuable: 'RA-YU-000001',
    prenom: 'Yusuf',
  ),
  const MembreSeance(
    studentId: 'demo-eleve-mariam',
    identifiantImmuable: 'RA-MA-000002',
    prenom: 'Mariam',
  ),
  const MembreSeance(
    studentId: 'demo-eleve-adam',
    identifiantImmuable: 'RA-AD-000003',
    prenom: 'Adam',
  ),
];

List<Override> _surcharges({required List<AnomalieRevue> anomalies}) =>
    <Override>[
      serviceEnseignantProvider.overrideWithValue(
        FauxServiceEnseignant()
          ..membresRendus = <String, List<MembreSeance>>{_classe: _eleves},
      ),
      anomaliesGroupeProvider.overrideWith(
        (Ref ref, String groupeId) async => anomalies,
      ),
    ];

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  ThemeMode mode, {
  required List<AnomalieRevue> anomalies,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      const RevueGroupePage(groupeId: _classe),
      surcharges: _surcharges(anomalies: anomalies),
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture : EN-11 revue de Classe', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 900)),
      ('768', const Size(768, 900)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('en11_revue_avec_anomalies_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            taille,
            mode,
            anomalies: <AnomalieRevue>[
              const AnomalieRevue(
                type: TypeAnomalieRevue.gateAVenir,
                studentId: 'demo-eleve-yusuf',
                eleve: 'Yusuf',
                detail: 'Palier de fin de cycle dans deux semaines.',
              ),
              const AnomalieRevue(
                type: TypeAnomalieRevue.horsCorridor,
                studentId: 'demo-eleve-mariam',
                eleve: 'Mariam',
              ),
              const AnomalieRevue(
                type: TypeAnomalieRevue.transfertPropose,
                studentId: 'demo-eleve-adam',
                eleve: 'Adam',
              ),
            ],
          );
          debugPrint(
            'PNG '
            '${await capturer(tester, 'en11_revue_avec_anomalies_${l}_${mode.name}')}',
          );
        });

        testWidgets('en11_revue_vide_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          await _monter(tester, taille, mode, anomalies: const <AnomalieRevue>[]);
          debugPrint(
            'PNG ${await capturer(tester, 'en11_revue_vide_${l}_${mode.name}')}',
          );
        });
      }
    }
  });
}
