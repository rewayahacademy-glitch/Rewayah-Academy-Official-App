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

  // PAGESHELL-200-1b (reserves 1 et 2 de la revue PAGESHELL-200-1) : le
  // corps recoit max(minimum utile, vue - tete). Le minimum utile est ce que
  // ses `ColonneCorps` signalent leur manquer : un bandeau et une barre
  // agrandis qui ne tiennent pas sous la tete ne debordent plus, la page
  // defile d'autant et la barre se rejoint.
  group('PAGESHELL-200-1b : minimum utile du corps', () {
    const ValueKey<String> cleEtiree = ValueKey<String>('etiree');

    /// Une salle : un bandeau haut, une zone etiree, une barre.
    Widget salle({double bandeau = 300, Widget? enTete}) => ColonneCorps(
      key: cleCorps,
      minimumEtire: 48,
      children: <Widget>[
        ?enTete,
        SizedBox(height: bandeau, child: const Text('bandeau')),
        Expanded(
          key: cleEtiree,
          child: ListView(
            children: <Widget>[
              for (int i = 0; i < 10; i++)
                SizedBox(height: 40, child: Text('ligne $i')),
            ],
          ),
        ),
        const SizedBox(key: cleBarre, height: 96, child: Text('barre')),
      ],
    );

    Future<void> monter(
      WidgetTester tester,
      Widget corps, {
      Size taille = const Size(320, 568),
      TextDirection sens = TextDirection.ltr,
    }) async {
      vue(tester, taille, zoneSure);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        hotePage(
          Directionality(
            textDirection: sens,
            child: PageShell(titre: 'Salle', defilante: false, child: corps),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// La barre entiere se rejoint en defilant la page jusqu'au bout.
    Future<void> barreAtteignable(WidgetTester tester, Size taille) async {
      final ScrollPosition page = defileurPage(tester);
      page.jumpTo(page.maxScrollExtent);
      await tester.pump();
      expect(tester.takeException(), isNull);
      final Rect barre = tester.getRect(find.byKey(cleBarre));
      expect(barre.bottom, lessThanOrEqualTo(taille.height - zoneSure.bottom));
      expect(barre.top, greaterThanOrEqualTo(zoneSure.top));
      expect(
        tester.getSize(find.byKey(cleEtiree)).height,
        greaterThanOrEqualTo(48),
      );
    }

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('320x568 a 200 %, ${sens.name} : le corps recoit ce qui '
          'lui manque, la page defile', (WidgetTester tester) async {
        await monter(tester, salle(), sens: sens);
        expect(tester.takeException(), isNull);
        // 300 + 48 + 96 ne tiennent pas sous la tete : la page defile.
        expect(defileurPage(tester).maxScrollExtent, greaterThan(0));
        expect(
          tester.getSize(find.byKey(cleCorps)).height,
          closeTo(300 + 48 + 96, 0.5),
        );
        await barreAtteignable(tester, const Size(320, 568));
      });
    }

    testWidgets('colonnes imbriquees : les deux colonnes sont servies', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        ColonneCorps(
          key: cleCorps,
          children: <Widget>[
            // Ni la colonne exterieure ni l'interieure ne tiennent : il faut
            // plusieurs mises en page du corps pour servir les deux.
            const SizedBox(height: 320, child: Text('bandeau')),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: salle(bandeau: 120),
              ),
            ),
          ],
        ),
        taille: const Size(800, 360),
      );
      expect(tester.takeException(), isNull);
      expect(defileurPage(tester).maxScrollExtent, greaterThan(0));
      await barreAtteignable(tester, const Size(800, 360));
    });

    testWidgets('un bandeau qui grandit seul relance la page, sans '
        'debordement', (WidgetTester tester) async {
      final ValueNotifier<double> hauteur = ValueNotifier<double>(100);
      addTearDown(hauteur.dispose);
      await monter(
        tester,
        salle(
          bandeau: 0,
          enTete: ValueListenableBuilder<double>(
            valueListenable: hauteur,
            builder: (BuildContext _, double h, Widget? _) =>
                SizedBox(height: h),
          ),
        ),
        taille: const Size(390, 844),
      );
      expect(tester.takeException(), isNull);
      expect(defileurPage(tester).maxScrollExtent, 0);

      hauteur.value = 700;
      await tester.pump();
      // L'image ou la colonne se remet en page seule : aucun debordement
      // signale, la page est relancee a la fin de l'image.
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(defileurPage(tester).maxScrollExtent, greaterThan(0));
      await barreAtteignable(tester, const Size(390, 844));

      // Et quand il rapetisse, la page reprend sa hauteur.
      defileurPage(tester).jumpTo(0);
      hauteur.value = 100;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(defileurPage(tester).maxScrollExtent, 0);
    });
  });

  // PAGESHELL-200-1c (reserves de la revue PAGESHELL-200-1b).
  group('PAGESHELL-200-1c', () {
    const ValueKey<String> cleSupport = ValueKey<String>('support');
    final GlobalKey repere = GlobalKey(debugLabel: 'repere');

    Future<void> monter(
      WidgetTester tester,
      Widget corps,
      Size taille, {
      TextDirection sens = TextDirection.ltr,
    }) async {
      vue(tester, taille, zoneSure);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        hotePage(
          Directionality(
            textDirection: sens,
            child: PageShell(titre: 'Salle', defilante: false, child: corps),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Une salle : un bandeau, une zone qui defile (en-tete, support, repere,
    /// vignettes), une barre.
    Widget salle({required double bandeau}) => ColonneCorps(
      key: cleCorps,
      minimumEtire: 48,
      children: <Widget>[
        SizedBox(height: bandeau, child: const Text('bandeau')),
        Expanded(
          child: DefileurCorps(
            repere: repere,
            builder: (BuildContext _, ScrollController defileur) =>
                SingleChildScrollView(
                  controller: defileur,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: 150, child: Text('en-tete')),
                      const SizedBox(
                        key: cleSupport,
                        height: 200,
                        child: Text('support'),
                      ),
                      SizedBox(key: repere),
                      const SizedBox(height: 300, child: Text('vignettes')),
                    ],
                  ),
                ),
          ),
        ),
        const SizedBox(key: cleBarre, height: 96, child: Text('barre')),
      ],
    );

    /// Le defileur imbrique de la salle.
    Finder zone() => find
        .ancestor(of: find.byKey(cleSupport), matching: find.byType(Scrollable))
        .first;

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('page qui defile de toute facon, ${sens.name} : la zone '
          'montre l\'en-tete et le support entiers', (
        WidgetTester tester,
      ) async {
        await monter(tester, salle(bandeau: 300), const Size(320, 568));
        expect(tester.takeException(), isNull);
        expect(defileurPage(tester).maxScrollExtent, greaterThan(0));
        // En-tete et support : 350 ; les vignettes restent dans la zone.
        expect(tester.getSize(zone()).height, closeTo(350, 0.5));
        expect(
          tester.state<ScrollableState>(zone()).position.maxScrollExtent,
          closeTo(300, 0.5),
        );
        final ScrollPosition page = defileurPage(tester);
        page.jumpTo(page.maxScrollExtent);
        await tester.pump();
        expect(
          tester.getRect(find.byKey(cleBarre)).bottom,
          lessThanOrEqualTo(568 - zoneSure.bottom + 0.5),
        );
      });
    }

    testWidgets('salle qui tient : la page ne defile pas pour la zone, la '
        'barre reste au premier affichage', (WidgetTester tester) async {
      // La zone (environ 200) ne montre pas en-tete et support (350) : elle
      // defile seule, la page ne s'allonge pas pour elle.
      await monter(tester, salle(bandeau: 300), const Size(390, 844));
      expect(tester.takeException(), isNull);
      expect(defileurPage(tester).maxScrollExtent, 0);
      expect(tester.getSize(zone()).height, lessThan(350));
      expect(
        tester.getRect(find.byKey(cleBarre)).bottom,
        lessThanOrEqualTo(844 - zoneSure.bottom + 0.5),
      );
    });

    testWidgets('tete fixe et colonne qui deborde : la page passe en '
        'defilement global, puis revient a la tete fixe quand tout tient', (
      WidgetTester tester,
    ) async {
      // Tablette a 200 % : la tete reste fixe (vue haute, gabarit large).
      await monter(tester, salle(bandeau: 500), const Size(800, 600));
      expect(tester.takeException(), isNull);
      final ScrollPosition page = defileurPage(tester);
      expect(page.maxScrollExtent, greaterThan(0));
      page.jumpTo(page.maxScrollExtent);
      await tester.pump();
      expect(tester.takeException(), isNull);
      final Rect barre = tester.getRect(find.byKey(cleBarre));
      expect(barre.top, greaterThanOrEqualTo(zoneSure.top - 0.5));
      expect(barre.bottom, lessThanOrEqualTo(600 - zoneSure.bottom + 0.5));

      // Une vue ou la salle tient : la tete redevient fixe.
      vue(tester, const Size(800, 1600), zoneSure);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.ancestor(
          of: find.byKey(cleCorps),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
    });
  });
}
