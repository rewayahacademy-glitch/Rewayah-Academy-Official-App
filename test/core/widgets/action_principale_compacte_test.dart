// Lot I (COM-RC5), R-12 choix a (decision du directeur du 05/10) : le
// format reduit d'`ActionPrincipale` (`compacte: true`) ne prend plus toute
// la largeur offerte par un parent souple. Avant, un `Center` sans
// `widthFactor` l'etirait et centrait la pastille au milieu de sa ligne
// (« Mode focus », « Quitter le focus », « Enregistrer »). Le parent la
// place desormais : en debut de ligne, miroir en arabe.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';

import '../../support/hote_theme.dart';

const ValueKey<String> _cle = ValueKey<String>('compacte');

Widget _bouton() => ActionPrincipale(
  key: _cle,
  libelle: 'Mode focus',
  niveau: NiveauAction.tertiaire,
  pleineLargeur: false,
  compacte: true,
  onPress: () {},
);

void main() {
  group('R-12 : ActionPrincipale compacte suit son parent', () {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('Align en debut (${sens.name}) : en debut de ligne, a la '
          'largeur de son contenu', (WidgetTester tester) async {
        fixerVue(tester, vueBureau);
        await tester.pumpWidget(
          hoteTheme(
            Directionality(
              textDirection: sens,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _bouton(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final Rect boite = tester.getRect(find.byKey(_cle));
        final Rect ligne = tester.getRect(find.byType(Align).first);
        expect(boite.width, lessThan(ligne.width / 2));
        if (sens == TextDirection.ltr) {
          expect(boite.left, moreOrLessEquals(ligne.left));
        } else {
          expect(boite.right, moreOrLessEquals(ligne.right));
        }
      });
    }

    testWidgets('dans un Wrap aligne au debut (R-12, decision du directeur) : '
        'la pastille suit le titre sur sa ligne, sans prendre une ligne '
        'entiere', (WidgetTester tester) async {
      fixerVue(tester, vueBureau);
      await tester.pumpWidget(
        hoteTheme(
          SizedBox(
            width: double.infinity,
            child: Wrap(
              key: const ValueKey<String>('ligne'),
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[const Text('Organisation'), _bouton()],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Rect boite = tester.getRect(find.byKey(_cle));
      final Rect titre = tester.getRect(find.text('Organisation'));
      final Rect ligne = tester.getRect(
        find.byKey(const ValueKey<String>('ligne')),
      );
      expect(boite.center.dy, moreOrLessEquals(titre.center.dy, epsilon: 1));
      expect(boite.left, moreOrLessEquals(titre.right + AppSpacing.sm));
      expect(boite.right, lessThan(ligne.right));
      expect(boite.width, lessThan(ligne.width / 2));
    });

    testWidgets('la cible tactile reste d au moins 48', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          Align(alignment: AlignmentDirectional.centerStart, child: _bouton()),
        ),
      );
      await tester.pumpAndSettle();
      final Size taille = tester.getSize(find.byKey(_cle));
      expect(taille.height, greaterThanOrEqualTo(48));
      expect(taille.width, greaterThanOrEqualTo(48));
    });
  });
}
