import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart';

/// `PageShell.fond` et `PageShell.bordABord` (connexion, 25/10/2026) : un
/// fond plein sans coquille recreee, et un corps qui va d'un bord a l'autre.
void main() {
  Widget hotePage(Widget page) => hote(
    page,
    surcharges: <Override>[
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    ],
  );

  testWidgets('sans fond, le fond du theme ; avec fond, la paire donnee', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hotePage(const PageShell(child: Text('corps'))));
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      isNull,
    );

    final AppColorPair marque = AppPalette.claire().surfaceMarque;
    await tester.pumpWidget(
      hotePage(PageShell(fond: marque, child: const Text('corps'))),
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      marque.background,
    );
  });

  for (final Size vue in <Size>[const Size(320, 640), const Size(1440, 900)]) {
    testWidgets('bord a bord, ${vue.width.toInt()} px : le corps prend '
        'toute la largeur et le haut de la page', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(vue);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const Key cle = ValueKey<String>('corps');
      await tester.pumpWidget(
        hotePage(
          const PageShell(
            bordABord: true,
            defilante: false,
            child: SizedBox.expand(key: cle),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final Rect corps = tester.getRect(find.byKey(cle));
      expect(corps.left, 0);
      expect(corps.width, vue.width);
      expect(corps.top, 0);
    });
  }

  testWidgets('par defaut, la gouttiere et la largeur bornee restent', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const Key cle = ValueKey<String>('corps');
    await tester.pumpWidget(
      hotePage(
        const PageShell(defilante: false, child: SizedBox.expand(key: cle)),
      ),
    );
    final Rect corps = tester.getRect(find.byKey(cle));
    expect(corps.left, greaterThan(0));
    expect(corps.width, lessThan(1440));
  });
}
