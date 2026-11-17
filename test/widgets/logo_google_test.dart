import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/marque/logo_google.dart';

/// Les quatre couleurs de la marque Google, telles que la source officielle les
/// pose. Ecrites ici une seconde fois, volontairement : si quelqu'un les modifie
/// dans le composant, ce test doit s'en apercevoir. C'est tout l'interet d'un
/// logo tiers -- il n'a pas le droit de deriver.
const List<int> _couleursDeMarque = <int>[
  0xFF4285F4,
  0xFF34A853,
  0xFFFBBC05,
  0xFFEA4335,
];

void main() {
  testWidgets('le logo pose ses quatre couleurs de marque, et rien autour', (
    WidgetTester tester,
  ) async {
    // Les traces sont recopies de la source officielle et interpretes au
    // rendu : personne ne peut les relire a l'oeil. Ce test est le seul endroit
    // qui verifie que l'interpretation produit bien quatre formes visibles, et
    // non un chemin degenere qui ne peindrait rien.
    await tester.pumpWidget(
      const RepaintBoundary(child: Center(child: LogoGoogle(taille: 96))),
    );
    await tester.pumpAndSettle();

    final ByteData? donnees = await tester.runAsync<ByteData?>(() async {
      final RenderRepaintBoundary boite = tester.renderObject(
        find.byType(RepaintBoundary),
      ) as RenderRepaintBoundary;
      final ui.Image image = await boite.toImage();
      return image.toByteData(format: ui.ImageByteFormat.rawRgba);
    });

    expect(donnees, isNotNull);
    final Uint8List octets = donnees!.buffer.asUint8List();

    final Map<int, int> comptes = <int, int>{};
    for (int i = 0; i + 3 < octets.length; i += 4) {
      if (octets[i + 3] != 255) {
        continue;
      }
      final int couleur =
          0xFF000000 | (octets[i] << 16) | (octets[i + 1] << 8) | octets[i + 2];
      comptes[couleur] = (comptes[couleur] ?? 0) + 1;
    }

    for (final int attendue in _couleursDeMarque) {
      expect(
        comptes[attendue] ?? 0,
        greaterThan(50),
        reason:
            'la couleur '
            '0x${attendue.toRadixString(16).toUpperCase()} '
            'doit couvrir une vraie surface, pas quelques pixels d antialiasing',
      );
    }
  });

  testWidgets('le logo ne se peint pas hors de son carre', (
    WidgetTester tester,
  ) async {
    // Une erreur d interpretation d un trace se voit surtout a ce qu elle
    // deborde. `SizedBox.square` borne la boite ; le tracé doit s y tenir.
    await tester.pumpWidget(const Center(child: LogoGoogle(taille: 24)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(LogoGoogle)), const Size(24, 24));
  });
}
