// La scene d'attente de la salle (directeur, 11/11/2026) : le symbole de la
// marque au centre d'ondes lentes, sur la surface de l'ecran.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';
import 'package:rewayah_academy/core/widgets/scene_attente.dart';

Widget _hote(
  Widget enfant, {
  bool reduit = false,
  Brightness clarte = Brightness.light,
}) => MaterialApp(
  theme: AppTheme.pour(InterfaceMode.standard, clarte),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduit),
    child: Scaffold(body: Center(child: enfant)),
  ),
);

void main() {
  setUp(() => SceneAttente.boucle = true);
  tearDown(() => SceneAttente.boucle = false);

  testWidgets('les ondes tournent tant que l\'attente dure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hote(const SceneAttente()));
    expect(find.byType(BrandLogo), findsOneWidget);
    expect(tester.getSize(find.byKey(SceneAttente.cleOndes)).width, 256);
    // Une boucle : une image est toujours demandee, meme apres deux tours.
    await tester.pump(AppMouvement.ondeAttente * 2);
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mouvement reduit : les ondes restent posees, sans boucle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hote(const SceneAttente(), reduit: true));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.byType(BrandLogo), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('decorative : rien dans l\'arbre semantique, aucun geste', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    await tester.pumpWidget(_hote(const SceneAttente(), reduit: true));
    expect(
      find.descendant(
        of: find.byType(SceneAttente),
        matching: find.bySemanticsLabel(RegExp('.+')),
      ),
      findsNothing,
    );
    poignee.dispose();
  });

  for (final double place in <double>[96, 160, 400]) {
    testWidgets('place de $place : la scene tient, jamais sous sa taille '
        'minimale', (WidgetTester tester) async {
      await tester.pumpWidget(
        _hote(
          SizedBox.square(dimension: place, child: const SceneAttente()),
          reduit: true,
          clarte: Brightness.dark,
        ),
      );
      final Size t = tester.getSize(find.byKey(SceneAttente.cleOndes));
      expect(t.width, lessThanOrEqualTo(SceneAttente.coteStandard));
      if (place >= SceneAttente.coteMinimal) {
        expect(t.width, lessThanOrEqualTo(place));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
