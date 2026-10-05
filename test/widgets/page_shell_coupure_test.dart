import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../support/harnais.dart';
import '../support/mots_coupes.dart';

/// R8-02 (revue FI-VAGUE-R) : un `PageShell` sans en-tete riche (ni retour,
/// ni sous-titre, ni action) rendait son titre dans un `Text` nu. A 390 et
/// 200 %, « Politiques commerciales » devenait « Politiques / commerci /
/// ales » sur `/demo/finance`. Le titre passe desormais par
/// `TexteSansCoupure`, comme celui d'`EntetePage`.
///
/// Mesure avec les VRAIES polices du depot : la police de test (glyphes
/// carres) ne dit rien de la largeur d'un mot reel.
void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final double largeur in <double>[390, 320]) {
    for (final String titre in <String>[
      'Politiques commerciales',
      'Accessibilite',
    ]) {
      testWidgets('titre sans en-tete riche, $largeur a 200 % : « $titre »', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = Size(largeur, 1600);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          hote(
            PageShell(titre: titre, child: const SizedBox(height: 40)),
            surcharges: <Override>[
              serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
            ],
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text(titre), findsOneWidget);
        expect(motsCoupes(tester, find.byType(PageShell)), isEmpty);
      });
    }
  }
}
