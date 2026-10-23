import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';
import 'package:rewayah_academy/core/widgets/porte_lumiere.dart';

/// La porte et la lumiere : le logo est celui de `BrandLogo`, la scene tient
/// dans 320 px de large, clair et sombre, et reste decorative.
void main() {
  for (final (String nom, AppPalette palette) in <(String, AppPalette)>[
    ('clair', AppPalette.claire()),
    ('sombre', AppPalette.sombre()),
  ]) {
    testWidgets('rendu $nom, 320 px, sans debordement ni semantique', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[palette]),
          home: const Scaffold(body: Center(child: PorteLumiere())),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(
        tester.getSize(find.byType(PorteLumiere)).width,
        lessThanOrEqualTo(320),
      );
    });
  }
}
