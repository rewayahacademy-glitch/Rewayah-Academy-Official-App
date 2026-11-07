// Captures de BOUTON-ATTENTE (garde-cap, 07/11/2026) : l'indicateur
// d'attente d'`ActionPrincipale` (`enCours`). Une image d'un indicateur
// anime ne montre qu'un instant : on capture deux instants (400 et 900 ms) pour
// voir que l'arc tourne, puis l'etat en mouvement reduit (statique).
// 390x844 @3 et 1440x900 @1, clair, francais.
//
// Le prefixe des fichiers vient de la variable d'environnement
// CAPTURE_PREFIXE (« avant » sur l'ancien code, « apres » sur le nouveau).
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';

import 'outil_capture.dart';

final String _prefixe = Platform.environment['CAPTURE_PREFIXE'] ?? 'apres';

Widget _ecran({required bool reduit}) => Builder(
  builder: (BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduit),
    child: Scaffold(
      body: Center(
        child: ActionPrincipale(
          libelle: 'Enregistrer',
          pleineLargeur: false,
          enCours: true,
          onPress: () {},
        ),
      ),
    ),
  ),
);

void main() {
  group('Capture : BOUTON-ATTENTE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (Size taille, double densite) in <(Size, double)>[
      (const Size(390, 844), 3),
      (const Size(1440, 900), 1),
    ]) {
      final String format =
          '${taille.width.toInt()}x${taille.height.toInt()}@${densite.toInt()}';
      for (final bool reduit in <bool>[false, true]) {
        testWidgets('$format, ${reduit ? 'mouvement reduit' : 'anime'}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, densite);
          await tester.pumpWidget(hoteCapture(_ecran(reduit: reduit)));
          final List<int> instants = reduit ? <int>[400] : <int>[400, 900];
          int ecoule = 0;
          for (final int t in instants) {
            await tester.pump(Duration(milliseconds: t - ecoule));
            ecoule = t;
            expect(tester.takeException(), isNull);
            final String etat = reduit ? 'reduit' : '${t}ms';
            debugPrint(
              'PNG ${await capturer(tester, 'ba_${_prefixe}_${format}_$etat')}',
            );
          }
        });
      }
    }
  });
}
