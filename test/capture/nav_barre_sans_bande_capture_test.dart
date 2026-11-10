// Captures de la barre flottante sans bande (decision du directeur du
// 10/11/2026, tranchee par le pilote) : sur une page dont le fond differe de
// celui de l'application, la pilule et le cercle flottent par-dessus la page,
// sans aplat ; en fin de defilement, le dernier element reste au-dessus de la
// barre. 320, texte x1 et x2, clair et sombre ; donnees de test seulement.
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart' show sansPersonneConnectee;
import 'outil_capture.dart';

Widget _page() => Builder(
  builder: (BuildContext context) => PageShell(
    // Un fond qui differe de celui de l'application et de la pilule.
    fond: AppPalette.of(context).surfaceSunken,
    titre: 'Page de test',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: <Widget>[
        for (int i = 1; i <= 8; i++)
          AppCard(child: SizedBox(height: 72, child: Text('Bloc $i'))),
      ],
    ),
  ),
);

void main() {
  group('Capture : barre flottante sans bande', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (ThemeMode theme, double texte, bool fin)
        in <(ThemeMode, double, bool)>[
          (ThemeMode.light, 1, false),
          (ThemeMode.light, 1, true),
          (ThemeMode.dark, 1, false),
          (ThemeMode.dark, 1, true),
          (ThemeMode.light, 2, true),
        ]) {
      final String nom =
          '320_x${texte.toInt()}_${theme.name}_${fin ? 'fin' : 'haut'}';
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, 700), 1);
        await tester.pumpWidget(
          hoteCapture(
            NavShell(
              destinations: destinationsPour(
                role: AppRole.guardian,
                mode: InterfaceMode.standard,
              ),
              indexActif: 0,
              onAller: (_) {},
              child: _page(),
            ),
            surcharges: <Override>[sansPersonneConnectee()],
            themeMode: theme,
            echelleTexte: texte,
          ),
        );
        await stabiliser(tester);
        if (fin) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -3000),
          );
          await stabiliser(tester);
        }
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'barre-sans-bande_$nom')}');
      });
    }
  });
}
