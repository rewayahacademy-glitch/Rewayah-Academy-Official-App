import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/barre_precedent_suivant.dart';

import '../../support/hote_theme.dart';

/// NAV-FLECHES-1 (revue du directeur, 02/10/2026) : navigation precedent /
/// suivant facon lecteur de musique. Fleche, position au centre, fleche ; deux
/// disques de meme taille, cible 48, la fleche disparait aux bornes, libelles
/// lus par le lecteur d'ecran, miroir en arabe.

const Key _prec = ValueKey<String>('nav-precedent');
const Key _suiv = ValueKey<String>('nav-suivant');
const Key _pos = ValueKey<String>('nav-position');
const Key _barreCle = ValueKey<String>('nav-precedent-suivant');

Widget _barre({
  required int page,
  required List<int> appels,
  int pages = 604,
  bool etendue = true,
}) => BarrePrecedentSuivant(
  etendue: etendue,
  position: '$page / $pages',
  positionSemantique: 'Page $page sur $pages',
  libellePrecedent: 'Verset précédent',
  libelleSuivant: 'Verset suivant',
  onPrecedent: page > 1 ? () => appels.add(-1) : null,
  onSuivant: page < pages ? () => appels.add(1) : null,
);

/// Vrai si le glyphe pose dans [cle] est retourne (miroir horizontal).
bool _retourne(WidgetTester tester, Key cle) {
  final Transform t = tester.widget<Transform>(
    find.descendant(of: find.byKey(cle), matching: find.byType(Transform)),
  );
  return t.transform.storage[0] < 0;
}

void main() {
  for (final Size taille in const <Size>[Size(320, 640), Size(1440, 900)]) {
    for (final double echelle in <double>[1, 2]) {
      testWidgets(
        'au milieu : fleche, position, fleche, a ${taille.width.toInt()} px, '
        'texte x${echelle.toInt()}',
        (WidgetTester tester) async {
          fixerVue(tester, taille);
          final List<int> appels = <int>[];
          await tester.pumpWidget(
            hoteTheme(
              _barre(page: 12, appels: appels),
              echelleTexte: echelle,
              defilant: false,
            ),
          );
          expect(tester.takeException(), isNull);
          final Rect gauche = tester.getRect(find.byKey(_prec));
          final Rect droite = tester.getRect(find.byKey(_suiv));
          final Rect centre = tester.getRect(find.byKey(_pos));
          // Meme taille, ronds, cible de 48.
          expect(gauche.size, droite.size);
          expect(gauche.width, gauche.height);
          expect(gauche.width, greaterThanOrEqualTo(48));
          // A gauche, au centre, a droite, sur une seule ligne.
          expect(gauche.center.dy, droite.center.dy);
          expect(gauche.right, lessThanOrEqualTo(centre.left + 1));
          expect(centre.right, lessThanOrEqualTo(droite.left + 1));
          // La position est centree dans la barre.
          final Rect barre = tester.getRect(find.byKey(_barreCle));
          expect(
            (centre.center.dx - barre.center.dx).abs(),
            lessThanOrEqualTo(1),
          );
          // Aucun debordement de l'ecran.
          expect(barre.left, greaterThanOrEqualTo(0));
          expect(barre.right, lessThanOrEqualTo(taille.width));
          // L'icone est centree dans son disque.
          for (final Key cle in <Key>[_prec, _suiv]) {
            final Rect disque = tester.getRect(find.byKey(cle));
            final Rect icone = tester.getRect(
              find.descendant(
                of: find.byKey(cle),
                matching: find.byIcon(AppIcons.suivant.repos),
              ),
            );
            expect(
              (icone.center - disque.center).distance,
              lessThanOrEqualTo(1),
            );
          }
          // Les rappels partent.
          await tester.tap(find.byKey(_suiv));
          await tester.tap(find.byKey(_prec));
          expect(appels, <int>[1, -1]);
        },
      );
    }
  }

  testWidgets('au debut, la fleche precedente disparait (pas grisee)', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, const Size(390, 844));
    await tester.pumpWidget(
      hoteTheme(_barre(page: 1, appels: <int>[]), defilant: false),
    );
    expect(find.byKey(_prec), findsNothing);
    expect(find.byKey(_suiv), findsOneWidget);
    expect(find.byIcon(AppIcons.suivant.repos), findsOneWidget);
    // La place reste reservee : la position reste au centre, l'autre fleche
    // ne bouge pas.
    final Rect barre = tester.getRect(find.byKey(_barreCle));
    final Rect centre = tester.getRect(find.byKey(_pos));
    expect((centre.center.dx - barre.center.dx).abs(), lessThanOrEqualTo(1));
  });

  testWidgets('a la fin, la fleche suivante disparait (pas grisee)', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, const Size(390, 844));
    await tester.pumpWidget(
      hoteTheme(_barre(page: 604, appels: <int>[]), defilant: false),
    );
    expect(find.byKey(_suiv), findsNothing);
    expect(find.byKey(_prec), findsOneWidget);
    final Rect barre = tester.getRect(find.byKey(_barreCle));
    final Rect centre = tester.getRect(find.byKey(_pos));
    expect((centre.center.dx - barre.center.dx).abs(), lessThanOrEqualTo(1));
  });

  testWidgets('une seule page : aucune fleche, la position reste', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, const Size(390, 844));
    await tester.pumpWidget(
      hoteTheme(_barre(page: 1, pages: 1, appels: <int>[]), defilant: false),
    );
    expect(find.byKey(_prec), findsNothing);
    expect(find.byKey(_suiv), findsNothing);
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('libelles accessibles : verbes entiers et position lue', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, const Size(390, 844));
    final SemanticsHandle sem = tester.ensureSemantics();
    await tester.pumpWidget(
      hoteTheme(_barre(page: 12, appels: <int>[]), defilant: false),
    );
    expect(find.bySemanticsLabel('Verset précédent'), findsOneWidget);
    expect(find.bySemanticsLabel('Verset suivant'), findsOneWidget);
    expect(find.bySemanticsLabel('Page 12 sur 604'), findsOneWidget);
    sem.dispose();
  });

  testWidgets('de gauche a droite : precedent a gauche et pointe a gauche', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, const Size(390, 844));
    await tester.pumpWidget(
      hoteTheme(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _barre(page: 12, appels: <int>[]),
        ),
        defilant: false,
      ),
    );
    expect(
      tester.getCenter(find.byKey(_prec)).dx,
      lessThan(tester.getCenter(find.byKey(_suiv)).dx),
    );
    expect(_retourne(tester, _prec), isTrue, reason: 'pointe a gauche');
    expect(_retourne(tester, _suiv), isFalse, reason: 'pointe a droite');
  });

  testWidgets('miroir en arabe : precedent a droite et pointe a droite', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, const Size(390, 844));
    await tester.pumpWidget(
      hoteTheme(
        Directionality(
          textDirection: TextDirection.rtl,
          child: _barre(page: 12, appels: <int>[]),
        ),
        defilant: false,
      ),
    );
    expect(
      tester.getCenter(find.byKey(_prec)).dx,
      greaterThan(tester.getCenter(find.byKey(_suiv)).dx),
      reason: 'precedent au bord de debut, a droite',
    );
    expect(_retourne(tester, _prec), isFalse, reason: 'pointe a droite');
    expect(_retourne(tester, _suiv), isTrue, reason: 'pointe a gauche');
  });

  testWidgets('barre resserree : meme disposition autour de la position', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, const Size(1440, 900));
    await tester.pumpWidget(
      hoteTheme(
        Align(child: _barre(page: 3, appels: <int>[], etendue: false)),
        defilant: false,
      ),
    );
    final Rect barre = tester.getRect(find.byKey(_barreCle));
    expect(barre.width, lessThan(400));
    expect(
      (tester.getCenter(find.byKey(_pos)).dx - barre.center.dx).abs(),
      lessThanOrEqualTo(1),
    );
  });
}
