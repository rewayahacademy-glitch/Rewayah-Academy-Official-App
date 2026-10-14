import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/pin_pad.dart';

import '../support/harnais.dart';

/// Les deux composants partages qui portent un chiffre ou une initiale dans
/// une boite de taille FIXE : a 200 % de texte, leur contenu doit rester
/// entierement dans la boite. La capture 0b du 24/09/2026 montrait « MA »
/// coupe en « M » par le disque, et les chiffres du pave sur l'anneau.
Widget _agrandi(Widget enfant) => hote(
  Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(2)),
      child: Scaffold(body: Center(child: enfant)),
    ),
  ),
);

bool _contient(Rect exterieur, Rect interieur) =>
    interieur.left >= exterieur.left - 0.01 &&
    interieur.top >= exterieur.top - 0.01 &&
    interieur.right <= exterieur.right + 0.01 &&
    interieur.bottom <= exterieur.bottom + 0.01;

void main() {
  testWidgets('AvatarTile : deux initiales tiennent dans le disque a 200 %', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _agrandi(const AvatarTile(prenom: 'Maiwenn Amina', diametre: 56)),
    );
    final Rect disque = tester.getRect(find.byType(AvatarTile));
    final Rect initiales = tester.getRect(find.text('MA'));
    expect(_contient(disque, initiales), isTrue, reason: '$initiales');
    expect(tester.takeException(), isNull);
  });

  testWidgets('PinPad : chaque chiffre tient dans sa touche a 200 %', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _agrandi(SingleChildScrollView(child: PinPad(onCodeComplet: (_) {}))),
    );
    for (int chiffre = 0; chiffre <= 9; chiffre++) {
      final Finder texte = find.text('$chiffre');
      final Finder touche = find
          .ancestor(of: texte, matching: find.byType(Container))
          .first;
      expect(
        _contient(tester.getRect(touche), tester.getRect(texte)),
        isTrue,
        reason: 'chiffre $chiffre',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
