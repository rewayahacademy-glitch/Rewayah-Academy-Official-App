// « Reduire les effets » (Compte > Accessibilite) branche (garde-cap,
// 11/11/2026) : il coupe les lumieres. Sous `EffetsReduits(actifs: true)`,
// ni `HaloLumiere` (donc ni le cercle Compte) ni `LumiereAutour` ne peignent
// de lumiere, et l'arbitre n'a rien a faire tourner. Le reglage arrive par la
// preference de l'appareil, via `ReglageMouvement`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/halo_lumiere.dart';
import 'package:rewayah_academy/core/widgets/lumiere_autour.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

Widget _carte({bool arbitre = false}) {
  const Widget carte = Center(
    child: SizedBox(
      width: 300,
      height: 80,
      child: LumiereAutour(nature: NatureHalo.urgent, child: SizedBox.expand()),
    ),
  );
  return arbitre ? const ArbitreLumieres(child: carte) : carte;
}

Widget _hote(Widget enfant, {required bool effetsReduits}) =>
    hoteCapture(EffetsReduits(actifs: effetsReduits, child: enfant));

void main() {
  testWidgets('effets reduits : aucune lumiere autour de la carte', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hote(_carte(arbitre: true), effetsReduits: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HaloLumiere), findsNothing);
    expect(find.byKey(HaloLumiere.lumiereKey), findsNothing);
    expect(find.byKey(HaloLumiere.lueurKey), findsNothing);
  });

  testWidgets('effets normaux : la lumiere est la, puis reste en lueur', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hote(_carte(), effetsReduits: false));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(HaloLumiere), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(HaloLumiere.lueurKey), findsOneWidget);
  });

  testWidgets('HaloLumiere seul (cercle Compte) : rien sous effets reduits', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _hote(
        const Center(
          child: HaloLumiere(
            nature: NatureHalo.nouveau,
            forme: FormeHalo.cercle,
            taille: Size.square(48),
          ),
        ),
        effetsReduits: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(HaloLumiere.lumiereKey), findsNothing);
    expect(find.byKey(HaloLumiere.lueurKey), findsNothing);
  });

  testWidgets('la preference « Reduire les effets » arrive par '
      'ReglageMouvement', (WidgetTester tester) async {
    late BuildContext sonde;
    await tester.pumpWidget(
      hote(
        ReglageMouvement(
          child: Builder(
            builder: (BuildContext contexte) {
              sonde = contexte;
              return const SizedBox();
            },
          ),
        ),
        surcharges: <Override>[
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        ],
      ),
    );
    final ProviderContainer conteneur = ProviderScope.containerOf(sonde);
    expect(EffetsReduits.de(sonde), isFalse);
    conteneur.read(preferencesLocalesProvider.notifier).effets(true);
    await tester.pump();
    expect(EffetsReduits.de(sonde), isTrue);
  });
}
