// Captures du lot HARMONISATION-B (08/11/2026), dette 6 du garde-cap :
// BarreSelection.compacte sous 640, avant et apres (PHASE=avant ou apres nomme
// les fichiers). La barre telle que la page Comptes la pose : le compte, « Tout
// deselectionner » et « Supprimer » (destructive, compacte).
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Donnees inventees.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/barre_selection.dart';

import 'outil_capture.dart';

final String _phase = Platform.environment['PHASE'] ?? 'apres';

Widget _barre() => Scaffold(
  body: Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: BarreSelection.compacte(
        titre: '2 comptes retenus',
        onRelacher: () {},
        operations: <Widget>[
          ActionPrincipale(
            libelle: 'Supprimer 2 comptes',
            niveau: NiveauAction.destructive,
            compacte: true,
            pleineLargeur: false,
            onPress: () {},
          ),
        ],
      ),
    ),
  ),
);

void main() {
  group('Capture : HARMONISATION-B', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final double echelle in <double>[1, 2]) {
      testWidgets('barre compacte 390, texte x$echelle', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 300), 3);
        await tester.pumpWidget(hoteCapture(_barre(), echelleTexte: echelle));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'barre_selection_compacte_${_phase}_390_x${echelle.toInt()}')}',
        );
      });
    }
  });
}
