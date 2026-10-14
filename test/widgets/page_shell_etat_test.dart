import 'package:flutter/foundation.dart'
    show FlutterMemoryAllocations, ObjectCreated, ObjectDisposed, ObjectEvent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart'
    show AProposForfaitFamillePage;

import '../support/harnais.dart';

/// AD-RC M4 : `PageShell` bascule entre deux structures (defilement global
/// sous 360 de haut ou a 200 % de texte sur mobile, tete fixe sinon). Sans
/// cle stable, la tete et le corps changeaient de parent a chaque bascule :
/// une rotation, un redimensionnement ou un passage a 200 % effacait la
/// saisie en cours et le focus. Ces tests verrouillent leur conservation.
void main() {
  Widget hotePage(Widget page) => hote(
    page,
    surcharges: <Override>[
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    ],
  );

  const PageShell page = PageShell(
    titre: 'Cahier de seance',
    child: TextField(key: ValueKey<String>('saisie')),
  );

  void attendSaisieEtFocus(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    expect(find.text('abc'), findsOneWidget);
    final EditableText champ = tester.widget<EditableText>(
      find.byType(EditableText),
    );
    expect(champ.controller.text, 'abc');
    expect(champ.focusNode.hasFocus, isTrue);
  }

  testWidgets(
    'la saisie et le focus survivent a 800 puis 300 puis 800 de haut',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(hotePage(page));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('saisie')),
        'abc',
      );
      await tester.pump();
      attendSaisieEtFocus(tester);

      // Vue basse : la tete defile avec le corps.
      tester.view.physicalSize = const Size(800, 300);
      await tester.pumpAndSettle();
      attendSaisieEtFocus(tester);

      // Retour a la tete fixe.
      tester.view.physicalSize = const Size(800, 800);
      await tester.pumpAndSettle();
      attendSaisieEtFocus(tester);
    },
  );

  testWidgets('la saisie et le focus survivent au texte a 200 % sur mobile', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(hotePage(page));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey<String>('saisie')), 'abc');
    await tester.pump();
    attendSaisieEtFocus(tester);

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    attendSaisieEtFocus(tester);

    tester.platformDispatcher.textScaleFactorTestValue = 1;
    await tester.pumpAndSettle();
    attendSaisieEtFocus(tester);
  });

  testWidgets(
    'un corps non defilant garde sa position de defilement a la bascule',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        hotePage(
          PageShell(
            titre: 'Journal',
            defilante: false,
            child: ListView(
              key: const ValueKey<String>('liste'),
              children: <Widget>[
                for (int i = 0; i < 60; i++)
                  SizedBox(height: 40, child: Text('ligne $i')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder defileur = find.descendant(
        of: find.byKey(const ValueKey<String>('liste')),
        matching: find.byType(Scrollable),
      );
      tester.state<ScrollableState>(defileur).position.jumpTo(400);
      await tester.pump();

      tester.view.physicalSize = const Size(800, 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.state<ScrollableState>(defileur).position.pixels, 400);

      tester.view.physicalSize = const Size(800, 800);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.state<ScrollableState>(defileur).position.pixels, 400);
    },
  );

  // AD-M4-DEFIL : une page DEFILANTE gardait saisie et focus, mais repartait
  // du haut a la bascule (deux defileurs differents). Sur une vraie page
  // d'un autre role (Eleve adulte, « A propos du forfait famille »).
  testWidgets('une vraie page defilante garde sa position a la bascule', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 420);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;

    await tester.pumpWidget(
      hotePage(AProposForfaitFamillePage(onRetour: () {})),
    );
    await tester.pumpAndSettle();
    ScrollPosition position() =>
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    expect(position().maxScrollExtent, greaterThan(0));
    final double cible = position().maxScrollExtent < 60
        ? position().maxScrollExtent
        : 60;
    position().jumpTo(cible);
    await tester.pump();

    // Vue basse : la tete defile avec le corps, la position reste.
    tester.view.physicalSize = const Size(320, 300);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(position().pixels, cible);

    // Retour a la tete fixe : toujours la meme position.
    tester.view.physicalSize = const Size(320, 420);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(position().pixels, cible);
  });

  // DEFIL-1 : chaque bascule recree le defileur de `PageShell`. L'ancien est
  // libere apres l'image, le dernier a la destruction de la page. Le suivi
  // des allocations de Flutter (celui du suivi des fuites, sans dependance
  // de plus) compte chaque ScrollController cree et libere.
  testWidgets('chaque defileur cree a la bascule est libere', (
    WidgetTester tester,
  ) async {
    final Set<Object> vivants = Set<Object>.identity();
    int crees = 0;
    void suivre(ObjectEvent e) {
      if (e.object is! ScrollController) {
        return;
      }
      if (e is ObjectCreated) {
        crees++;
        vivants.add(e.object);
      } else if (e is ObjectDisposed) {
        vivants.remove(e.object);
      }
    }

    FlutterMemoryAllocations.instance.addListener(suivre);
    addTearDown(() => FlutterMemoryAllocations.instance.removeListener(suivre));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 420);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;

    await tester.pumpWidget(
      hotePage(AProposForfaitFamillePage(onRetour: () {})),
    );
    await tester.pumpAndSettle();
    final int avantBascules = crees;
    tester.view.physicalSize = const Size(320, 300);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(320, 420);
    await tester.pumpAndSettle();
    // Deux bascules : deux nouveaux defileurs, les anciens deja liberes.
    expect(crees - avantBascules, greaterThanOrEqualTo(2));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(vivants, isEmpty, reason: 'ScrollController non libere');
  });
}
