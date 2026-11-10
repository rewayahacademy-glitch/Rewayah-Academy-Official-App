// Decision du directeur du 10/11/2026 (tranchee par le pilote) : plus de
// bande d'une autre couleur sous la barre flottante. La place reservee a la
// barre prend le fond de la page affichee : la pilule et le cercle flottent
// sur la page. La place reste reservee : la fin du contenu n'est jamais
// cachee, et les feuilles de la page restent au-dessus de la barre.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart';

const Key _fin = Key('fin-du-contenu');

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
        child: const Column(
          children: <Widget>[
            SizedBox(height: 1200),
            SizedBox(key: _fin, height: 40),
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
}
