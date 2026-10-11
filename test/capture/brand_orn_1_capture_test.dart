// BRAND-ORN-1 : captures de l'ornement de la marque, signature discrete.
// Une planche (tailles, variantes, separateur) et un etat vide, en clair et en
// sombre, a 390 points.
//
// Saute sans CAPTURE_DIR. Sortie de preuve :
// docs/current/captures/BRAND-ORN-1/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/ornement_marque.dart';

import 'outil_capture.dart';

class _Planche extends StatelessWidget {
  const _Planche();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppPalette.of(context).surfaceCanvas.background,
    body: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (final TailleOrnement t in TailleOrnement.values) ...<Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                OrnementMarque(taille: t),
                OrnementMarque(taille: t, variante: VarianteOrnement.contour),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          const SeparateurOrnement(),
          const SizedBox(height: AppSpacing.xxxl),
          const SizedBox(
            height: 300,
            child: EmptyState(
              message: 'Aucune séance pour le moment',
              invitation: 'Les prochaines apparaîtront ici.',
              icone: AppIcons.disponibilites,
              registre: RegistreVide.subi,
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('Capture : BRAND-ORN-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('planche et etat vide ${theme.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 2);
        await tester.pumpWidget(
          hoteCapture(const _Planche(), themeMode: theme),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        debugPrint(
          'PNG ${await capturer(tester, 'ornement_planche_${theme.name}')}',
        );
      });
    }
  });
}
