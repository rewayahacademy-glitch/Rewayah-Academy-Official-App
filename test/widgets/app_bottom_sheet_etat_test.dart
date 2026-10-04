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
}
