import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart';

/// PAGESHELL-200-1 (reserve 1 de la revue OBS-COUPE-1b, 4 octobre 2026).
///
/// Sur telephone a 200 % de texte, la tete de `PageShell` defile avec le
/// corps. Un corps non defilant y recevait **toute** la hauteur de la vue,
/// pose sous la tete : il depassait donc de la hauteur de la tete, et son bas
/// (la barre de commandes de la salle d'observation) passait sous la zone
/// sure au premier affichage (390x844 : bas a 834 pour une zone sure a 810).
///
/// Il recoit maintenant la hauteur laissee sous la tete ; si la tete en
/// laisse moins de la moitie de la vue (zoom a 400 % sur une vue tres basse,
/// AD-11), il garde toute la hauteur de la vue, comme avant.
void main() {
  Widget hotePage(Widget page) => hote(
    page,
    surcharges: <Override>[
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    ],
  );

  const ValueKey<String> cleCorps = ValueKey<String>('corps');
  const ValueKey<String> cleBarre = ValueKey<String>('barre');

  /// Un corps comme la salle : une liste qui prend la place, une barre en bas.
  Widget corps() => Column(
    key: cleCorps,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Expanded(
        child: ListView(
          children: <Widget>[
            for (int i = 0; i < 40; i++)
              SizedBox(height: 40, child: Text('ligne $i')),
          ],
        ),
      ),
      const SizedBox(key: cleBarre, height: 96, child: Text('barre')),
    ],
  );

  /// La position du defileur de la page (celui de la bascule).
  ScrollPosition defileurPage(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .ancestor(
              of: find.byKey(cleCorps),
              matching: find.byType(Scrollable),
            )
            .last,
      )
      .position;

  void vue(WidgetTester tester, Size taille, EdgeInsets zoneSure) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = taille;
    tester.view.padding = FakeViewPadding(
      top: zoneSure.top,
      bottom: zoneSure.bottom,
    );
    addTearDown(tester.view.reset);
  }

  const EdgeInsets zoneSure = EdgeInsets.only(top: 47, bottom: 34);

  for (final (Size, TextDirection) cas in const <(Size, TextDirection)>[
    (Size(390, 844), TextDirection.ltr),
    (Size(320, 844), TextDirection.ltr),
    (Size(390, 844), TextDirection.rtl),
    (Size(320, 844), TextDirection.rtl),
  ]) {
    testWidgets('${cas.$1.width.toInt()}x${cas.$1.height.toInt()} a 200 %, '
        '${cas.$2.name} : le bas du corps non defilant est dans la zone sure '
        'au premier affichage', (WidgetTester tester) async {
      vue(tester, cas.$1, zoneSure);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        hotePage(
          Directionality(
            textDirection: cas.$2,
            child: PageShell(
              titre: 'Journal de seance',
              defilante: false,
              child: corps(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final double basZoneSure = cas.$1.height - zoneSure.bottom;
      // La tete defile bien (structure a 200 % sur telephone) ...
      expect(
        tester.getTopLeft(find.text('Journal de seance')).dy,
        greaterThanOrEqualTo(zoneSure.top),
      );
      // ... mais rien ne depasse : la page tient dans la vue.
      expect(defileurPage(tester).pixels, 0);
      expect(defileurPage(tester).maxScrollExtent, 0);
      expect(
        tester.getRect(find.byKey(cleBarre)).bottom,
        lessThanOrEqualTo(basZoneSure),
      );
      // Et le corps prend toute la hauteur laissee sous la tete.
      expect(
        tester.getRect(find.byKey(cleCorps)).bottom,
        closeTo(basZoneSure, 0.5),
      );
    });
  }

  testWidgets('avec une zone d\'action collee : le corps s\'arrete au-dessus '
      'd\'elle', (WidgetTester tester) async {
    vue(tester, const Size(390, 844), zoneSure);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      hotePage(
        PageShell(
          titre: 'Journal',
          defilante: false,
          actions: const SizedBox(
            key: ValueKey<String>('action'),
            height: 48,
            child: Text('Enregistrer'),
          ),
          child: corps(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(defileurPage(tester).maxScrollExtent, 0);
    final double hautAction = tester
        .getTopLeft(find.byKey(const ValueKey<String>('action')))
        .dy;
    expect(
      tester.getRect(find.byKey(cleBarre)).bottom,
      lessThanOrEqualTo(hautAction),
    );
  });

  // Non-regression AD-11 : une tete qui ne laisse pas la moitie de la vue
  // (vue tres basse) laisse le corps prendre toute la hauteur de la vue ; la
  // tete defile, puis le corps occupe l'ecran.
  testWidgets('vue tres basse, tete haute : le corps garde la hauteur de la '
      'vue', (WidgetTester tester) async {
    vue(tester, const Size(800, 300), EdgeInsets.zero);

    await tester.pumpWidget(
      hotePage(
        PageShell(
          titre: 'Journal',
          defilante: false,
          entete: const SizedBox(height: 200, child: Text('contexte')),
          child: corps(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(cleCorps)).height, 300);
    expect(defileurPage(tester).maxScrollExtent, greaterThan(0));
    // Defile jusqu'au bout : le bas du corps est le bas de la vue.
    defileurPage(tester).jumpTo(defileurPage(tester).maxScrollExtent);
    await tester.pump();
    expect(tester.getRect(find.byKey(cleCorps)).bottom, closeTo(300, 0.5));
    expect(tester.getRect(find.byKey(cleBarre)).bottom, closeTo(300, 0.5));
  });
}
