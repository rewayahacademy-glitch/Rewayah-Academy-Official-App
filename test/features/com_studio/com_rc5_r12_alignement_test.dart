// R-12 (decision du directeur, 05/10) : « Mode focus » et « Quitter le
// focus » s'alignent au debut de leur ligne (a droite en arabe), apres ce
// qui les precede ; ils ne sont plus repousses au bout de la ligne
// (`WrapAlignment.spaceBetween`). Sur la vraie `StudioPage`, a 320 en texte
// x2, 390, 1440 et en arabe.
//
// Contre-preuve : a 71e3e555 (Wrap en `spaceBetween`), a 1440 le bouton
// restait au bout de la ligne, loin de ce qui le precede.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/com_studio/focus/bascule_focus.dart';
import 'package:rewayah_academy/features/com_studio/focus/sortie_focus.dart';

import 'support_focus.dart';
import 'support_studio.dart';

final String _adresseC1 = Routes.canalStudioPour('c1');

/// [bouton] est au debut de sa ligne dans [ligne] : seul sur sa ligne, il
/// touche le bord de debut ; sinon il suit l'element qui le precede a
/// l'ecart du Wrap, jamais plus loin.
void _verifierAuDebut(WidgetTester tester, Finder ligne, Finder bouton) {
  final Wrap wrap = tester.widget<Wrap>(ligne);
  final Rect zone = tester.getRect(ligne);
  final bool rtl =
      Directionality.of(tester.element(ligne)) == TextDirection.rtl;
  final Rect cible = tester.getRect(bouton);
  final List<Rect> rects = <Rect>[
    for (final Widget enfant in wrap.children)
      tester.getRect(
        find.descendant(of: ligne, matching: find.byWidget(enfant)).first,
      ),
  ];
  final int i = rects.indexWhere((Rect r) => r.contains(cible.center));
  expect(i, isNonNegative, reason: 'le bouton est un enfant de la ligne');
  final Rect moi = rects[i];
  Rect? precedent;
  for (int j = 0; j < i; j++) {
    final Rect r = rects[j];
    if (r.bottom > moi.top + 1 && r.top < moi.bottom - 1) precedent = r;
  }
  if (precedent == null) {
    expect(
      rtl ? moi.right : moi.left,
      moreOrLessEquals(rtl ? zone.right : zone.left, epsilon: 1),
      reason: 'seul sur sa ligne : au bord de debut',
    );
  } else {
    final double ecart = rtl
        ? precedent.left - moi.right
        : moi.left - precedent.right;
    expect(
      ecart,
      moreOrLessEquals(wrap.spacing, epsilon: 1),
      reason: 'apres ce qui le precede, a l ecart du Wrap',
    );
  }
}

/// La ligne (Wrap) qui porte « Mode focus ».
Finder get _ligneEntree => find
    .ancestor(of: find.byType(BasculeFocus), matching: find.byType(Wrap))
    .first;

const List<(String, Size, double, AppLocale)> _cas =
    <(String, Size, double, AppLocale)>[
      ('320, texte x2', Size(320, 800), 2, AppLocale.fr),
      ('390', Size(390, 844), 1, AppLocale.fr),
      ('1440', Size(1440, 900), 1, AppLocale.fr),
      ('1440, arabe', Size(1440, 900), 1, AppLocale.ar),
    ];

void main() {
  group('R-12 : « Mode focus » et « Quitter le focus » au debut', () {
    for (final (String nom, Size taille, double echelle, AppLocale langue)
        in _cas) {
      testWidgets('$nom : « Mode focus » suit l en-tete, au debut', (
        WidgetTester tester,
      ) async {
        await monterStudio(
          tester,
          port: portFocus(),
          depart: _adresseC1,
          taille: taille,
          echelleTexte: echelle,
          langue: langue,
        );
        if (entrerFocus.evaluate().isEmpty) {
          positionFil(tester).jumpTo(0);
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(entrerFocus);
        await tester.pumpAndSettle();
        expect(
          tester.widget<Wrap>(_ligneEntree).alignment,
          WrapAlignment.start,
        );
        _verifierAuDebut(tester, _ligneEntree, entrerFocus);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$nom : « Quitter le focus » suit l etat, au debut', (
        WidgetTester tester,
      ) async {
        await monterStudio(
          tester,
          port: portFocus(),
          depart: _adresseC1,
          taille: taille,
          echelleTexte: echelle,
          langue: langue,
        );
        await entrer(tester);
        final Finder bandeau = find.byKey(BandeauSortieFocus.cle);
        expect(tester.widget<Wrap>(bandeau).alignment, WrapAlignment.start);
        _verifierAuDebut(tester, bandeau, quitterFocus);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
