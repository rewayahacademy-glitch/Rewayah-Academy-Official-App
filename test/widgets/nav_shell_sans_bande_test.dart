// Decision du directeur du 10/11/2026 (tranchee par le pilote) : plus de
// bande d'une autre couleur sous la barre flottante. BANDE-BARRE (11/11/2026,
// le directeur voyait encore un rectangle) : la barre flotte SUR la page ; le
// contenu passe sous la pilule et le cercle, jamais coupe au bord d'une place
// reservee ; la fin du contenu s'arrete au-dessus de la barre ; une feuille
// du bas ouverte par la page efface la barre le temps qu'elle reste ouverte.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart';

const Key _fin = Key('fin-du-contenu');
const Key _milieu = Key('milieu-du-contenu');
const Key _ouvrir = Key('ouvrir-feuille');

Widget _page() => hote(
  NavShell(
    destinations: destinationsPour(
      role: AppRole.guardian,
      mode: InterfaceMode.standard,
    ),
    indexActif: 0,
    onAller: (_) {},
    child: Builder(
      builder: (BuildContext context) => PageShell(
        // Un fond qui differe de celui de l'application.
        fond: AppPalette.of(context).surfaceRaised,
        titre: 'Page',
        child: Column(
          children: <Widget>[
            TextButton(
              key: _ouvrir,
              onPressed: () => AppBottomSheet.ouvrir<void>(
                context,
                titre: 'Feuille',
                constructeur: (BuildContext _) => const SizedBox(height: 80),
              ),
              child: const Text('Ouvrir'),
            ),
            const SizedBox(height: 600),
            const ColoredBox(
              color: Color(0xFF000000),
              child: SizedBox(key: _milieu, height: 600, width: 200),
            ),
            const SizedBox(key: _fin, height: 40),
          ],
        ),
      ),
    ),
  ),
  surcharges: <Override>[sansPersonneConnectee()],
);

void main() {
  for (final Size taille in const <Size>[Size(320, 700), Size(390, 844)]) {
    testWidgets('${taille.width.toInt()} : la place de la barre prend le fond '
        'de la page, la fin du contenu reste au-dessus', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_page());
      await tester.pumpAndSettle();

      // Autour de la pilule, le fond de la page, pas celui de l'application.
      final Color fondPage = AppPalette.of(
        tester.element(find.byType(PageShell)),
      ).surfaceRaised.background;
      final Iterable<ColoredBox> sousLaBarre = tester.widgetList<ColoredBox>(
        find.ancestor(
          of: find.byKey(NavShell.barreBasseKey),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(sousLaBarre.first.color, fondPage);
      final Rect barre = tester.getRect(find.byKey(NavShell.barreBasseKey));
      expect(barre.bottom, taille.height);

      // En fin de defilement, le dernier element est entier au-dessus de la
      // barre.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      final Rect fin = tester.getRect(find.byKey(_fin));
      expect(fin.bottom, lessThanOrEqualTo(barre.top));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('le contenu passe sous la barre flottante, sans rectangle', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();
    final Rect barre = tester.getRect(find.byKey(NavShell.barreBasseKey));
    // Le milieu du contenu, haut de 600, est sous la barre : il y est rendu,
    // et non coupe au-dessus d'elle.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    final Rect milieu = tester.getRect(find.byKey(_milieu));
    expect(milieu.top, lessThan(barre.top));
    expect(milieu.bottom, greaterThan(barre.bottom));
    // La page s'etend jusqu'au bord de l'ecran, sous la barre.
    final Rect page = tester.getRect(find.byType(Scrollable).first);
    expect(page.bottom, 844);
  });

  testWidgets('une feuille du bas efface la barre, qui revient a sa '
      'fermeture', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();
    double opacite() => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(NavShell.barreBasseKey),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
    expect(opacite(), 1);
    await tester.tap(find.byKey(_ouvrir));
    await tester.pumpAndSettle();
    expect(find.text('Feuille'), findsOneWidget);
    expect(opacite(), 0);
    // La barre effacee ne prend plus le toucher.
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .ancestor(
                  of: find.byKey(NavShell.barreBasseKey),
                  matching: find.byType(IgnorePointer),
                )
                .first,
          )
          .ignoring,
      isTrue,
    );
    Navigator.of(tester.element(find.text('Feuille'))).pop();
    await tester.pumpAndSettle();
    expect(opacite(), 1);
    expect(tester.takeException(), isNull);
  });
}
