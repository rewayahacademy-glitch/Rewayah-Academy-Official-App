import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';

import '../support/harnais.dart';

/// AD-NETTOYAGE (m15, meme defaut que AD-RC M4) : `AppBottomSheet` bascule
/// entre le corps defilant seul et la feuille entiere defilante sous 360 de
/// haut. Sans cle, le corps changeait de parent : une rotation effacait la
/// saisie et le focus d'une feuille de saisie ouverte.
void main() {
  Widget hoteFeuille() => hote(
    const Material(
      child: AppBottomSheet(
        titre: 'Motif',
        actions: SizedBox(height: 40, child: Text('Envoyer')),
        child: TextField(key: ValueKey<String>('saisie')),
      ),
    ),
    surcharges: <Override>[
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    ],
  );

  void attendSaisieEtFocus(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    final EditableText champ = tester.widget<EditableText>(
      find.byType(EditableText),
    );
    expect(champ.controller.text, 'abc');
    expect(champ.focusNode.hasFocus, isTrue);
  }

  testWidgets('la saisie et le focus survivent a 800 puis 300 puis 800', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(hoteFeuille());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey<String>('saisie')), 'abc');
    await tester.pump();
    attendSaisieEtFocus(tester);

    tester.view.physicalSize = const Size(800, 300);
    await tester.pumpAndSettle();
    attendSaisieEtFocus(tester);

    tester.view.physicalSize = const Size(800, 800);
    await tester.pumpAndSettle();
    attendSaisieEtFocus(tester);
  });

  // AD-NETTOYAGE-2 (n7) : la garde de glissement ne retient que les feuilles
  // qu'une PopScope interdit de fermer, et ne lance `maybePop` qu'aux seuils de
  // `BottomSheet` (la moitie de la hauteur, ou 700 px/s).
  group('garde de glissement', () {
    Widget hoteOuverture({
      required bool avecPopScope,
      required List<int> pops,
    }) => hote(
      Builder(
        builder: (BuildContext context) => Material(
          child: TextButton(
            onPressed: () => unawaited(
              AppBottomSheet.ouvrir<void>(
                context,
                titre: 'Motif',
                constructeur: (BuildContext _) => avecPopScope
                    ? PopScope(
                        canPop: false,
                        onPopInvokedWithResult: (bool _, Object? _) =>
                            pops.add(1),
                        child: const Text('corps de la feuille'),
                      )
                    : const Text('corps de la feuille'),
              ),
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
      surcharges: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    );

    Future<void> ouvrir(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('corps de la feuille'), findsOneWidget);
    }

    testWidgets('sans PopScope : le glisser ferme comme avant', (
      WidgetTester tester,
    ) async {
      final List<int> pops = <int>[];
      await tester.pumpWidget(hoteOuverture(avecPopScope: false, pops: pops));
      await ouvrir(tester);
      await tester.drag(find.text('Motif'), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(find.text('corps de la feuille'), findsNothing);
      expect(pops, isEmpty);
    });

    testWidgets('avec PopScope : un effleurement ne pose pas la question, '
        'une vraie descente oui', (WidgetTester tester) async {
      final List<int> pops = <int>[];
      await tester.pumpWidget(hoteOuverture(avecPopScope: true, pops: pops));
      await ouvrir(tester);

      await tester.drag(find.text('Motif'), const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(pops, isEmpty);
      expect(find.text('corps de la feuille'), findsOneWidget);

      await tester.drag(find.text('Motif'), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(pops, hasLength(1));
      expect(find.text('corps de la feuille'), findsOneWidget);
    });
  });
}
