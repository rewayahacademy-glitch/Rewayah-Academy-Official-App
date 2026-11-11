// LUMIERE-ACCUEILS : `LumiereAutour` pose `HaloLumiere` (rectangle) a la
// taille de la carte, et rien du tout sans signal.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/halo_lumiere.dart';
import 'package:rewayah_academy/core/widgets/lumiere_autour.dart';

Widget _hote(Widget enfant) => MaterialApp(
  theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
  home: Scaffold(body: Center(child: enfant)),
);

void main() {
  testWidgets('sans signal : la carte seule, aucune lumiere', (tester) async {
    await tester.pumpWidget(
      _hote(
        const LumiereAutour(
          nature: null,
          child: SizedBox(width: 200, height: 80),
        ),
      ),
    );
    expect(find.byType(HaloLumiere), findsNothing);
  });

  testWidgets('un signal : la lumiere, rectangle, a la taille de la carte', (
    tester,
  ) async {
    await tester.pumpWidget(
      _hote(
        const LumiereAutour(
          nature: NatureHalo.aPreparer,
          child: SizedBox(width: 200, height: 80),
        ),
      ),
    );
    final HaloLumiere halo = tester.widget<HaloLumiere>(
      find.byType(HaloLumiere),
    );
    expect(halo.nature, NatureHalo.aPreparer);
    expect(halo.forme, FormeHalo.rectangle);
    expect(halo.taille, const Size(200, 80));
    await tester.pumpAndSettle();
  });
}
