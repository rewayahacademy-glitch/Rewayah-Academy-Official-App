// HU-1 (EA-PL) : la rangee du contrat B. Sur une ligne quand elle tient,
// chaque action a sa largeur, groupe au bord de fin ; sinon empilee dans le
// meme ordre, a largeur egale, toujours au bord de fin (jamais en escalier).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';

void main() {
  const Key sortie = Key('sortie');
  const Key suite = Key('suite');

  Future<void> monter(
    WidgetTester tester, {
    required String libelleSortie,
    required String libelleSuite,
    TextDirection sens = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: Directionality(
            textDirection: sens,
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 500,
                  child: RangeeActions(
                    children: <Widget>[
                      ActionPrincipale(
                        key: sortie,
                        libelle: libelleSortie,
                        onPress: () {},
                        niveau: NiveauAction.secondaire,
                        pleineLargeur: false,
                      ),
                      ActionPrincipale(
                        key: suite,
                        libelle: libelleSuite,
                        onPress: () {},
                        pleineLargeur: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tient sur une ligne : chaque action a sa largeur, la sortie '
      'avant la poursuite, au bord de fin', (WidgetTester tester) async {
    await monter(tester, libelleSortie: 'Non', libelleSuite: 'Oui oui');
    final Rect a = tester.getRect(find.byKey(sortie));
    final Rect b = tester.getRect(find.byKey(suite));
    expect(a.top, b.top);
    expect(a.right, lessThanOrEqualTo(b.left));
    expect(b.right, 500);
    expect(a.width, lessThan(b.width));
    // La hauteur du bouton, jamais celle de l'ecran.
    expect(b.height, lessThan(200));
  });

  testWidgets('ne tient pas : empilee, meme largeur, meme bord de fin', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      libelleSortie: 'Inviter ma conjointe',
      libelleSuite: 'Inscrire',
    );
    final Rect a = tester.getRect(find.byKey(sortie));
    final Rect b = tester.getRect(find.byKey(suite));
    expect(a.bottom, lessThanOrEqualTo(b.top));
    expect(a.width, b.width);
    expect(a.right, 500);
    expect(b.right, 500);
    expect(a.width, lessThan(500));
  });

  testWidgets('RTL : le groupe au bord de fin, a gauche', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      libelleSortie: 'Non',
      libelleSuite: 'Oui oui',
      sens: TextDirection.rtl,
    );
    final Rect a = tester.getRect(find.byKey(sortie));
    final Rect b = tester.getRect(find.byKey(suite));
    expect(b.left, 0);
    expect(a.left, greaterThanOrEqualTo(b.right));
  });
}
