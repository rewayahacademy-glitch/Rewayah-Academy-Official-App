// Lot E3 (audit d'entree du 17/10, L3) : un seul gabarit d'etape, borne sur
// grand ecran. A 1440, la rangee d'etape, le contenu et l'action tiennent
// dans une colonne centree de `PageEtape.largeurColonne` ; le bouton prend la
// largeur de son libelle et se range au bord de fin de cette colonne. A 390,
// la colonne prend la largeur offerte et le bouton toute la bande.
// `PageParcours` delegue a `PageEtape` : memes bornes, meme compteur.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/grille_bento.dart';
import 'package:rewayah_academy/core/widgets/page_etape.dart';
import 'package:rewayah_academy/core/widgets/page_parcours.dart';

import '../../support/hote_theme.dart';

const Key _cleBouton = Key('bouton-etape');

Widget _pageEtape() => PageEtape(
  numero: 2,
  total: 4,
  onRetour: () {},
  action: ActionPrincipale(
    key: _cleBouton,
    libelle: 'Continuer',
    onPress: () {},
    pilule: true,
  ),
  child: const Text('Pour qui est ce profil ?'),
);

Widget _pageParcours() => PageParcours(
  numero: 2,
  total: 7,
  question: 'Quel age a Amina ?',
  explication: 'Une tranche suffit.',
  enfant: const SizedBox(height: 120),
  libelleAction: 'Continuer',
  onAction: () {},
  onRetour: () {},
  minutesRestantes: 3,
);

Future<void> _monter(
  WidgetTester tester,
  Size vue,
  Widget page, {
  TextDirection sens = TextDirection.ltr,
}) async {
  fixerVue(tester, vue);
  await tester.pumpWidget(
    hoteTheme(
      Directionality(textDirection: sens, child: page),
      defilant: false,
    ),
  );
  await tester.pumpAndSettle();
}

Rect _colonne(WidgetTester tester) =>
    tester.getRect(find.byKey(PageEtape.colonneKey));

Rect _bouton(WidgetTester tester, {bool parcours = false}) => tester.getRect(
  parcours ? find.byType(ActionPrincipale).last : find.byKey(_cleBouton),
);

void main() {
  for (final (String nom, Widget Function() page, bool parcours)
      in <(String, Widget Function(), bool)>[
        ('PageEtape', _pageEtape, false),
        ('PageParcours', _pageParcours, true),
      ]) {
    group(nom, () {
      testWidgets('1440 : colonne bornee et centree', (
        WidgetTester tester,
      ) async {
        await _monter(tester, vueBureau, page());
        final Rect colonne = _colonne(tester);
        expect(colonne.width, PageEtape.largeurColonne);
        expect(colonne.center.dx, closeTo(vueBureau.width / 2, 0.5));
        // La rangee d'etape tient dans la meme colonne.
        final Rect rangee = tester.getRect(find.byType(RangeeEtape));
        expect(rangee.left, closeTo(colonne.left, 0.5));
        expect(rangee.right, closeTo(colonne.right, 0.5));
      });

      testWidgets('1440 : bouton a largeur de contenu, au bord de fin', (
        WidgetTester tester,
      ) async {
        await _monter(tester, vueBureau, page());
        final Rect colonne = _colonne(tester);
        final Rect bouton = _bouton(tester, parcours: parcours);
        expect(bouton.width, lessThan(colonne.width / 2));
        expect(bouton.right, closeTo(colonne.right, 0.5));
      });

      testWidgets('1440 en arabe : bouton au bord de fin, a gauche', (
        WidgetTester tester,
      ) async {
        await _monter(tester, vueBureau, page(), sens: TextDirection.rtl);
        final Rect colonne = _colonne(tester);
        final Rect bouton = _bouton(tester, parcours: parcours);
        expect(bouton.width, lessThan(colonne.width / 2));
        expect(bouton.left, closeTo(colonne.left, 0.5));
      });

      testWidgets('390 : colonne et bouton prennent toute la bande', (
        WidgetTester tester,
      ) async {
        await _monter(tester, vueMobile, page());
        final Rect colonne = _colonne(tester);
        expect(colonne.width, vueMobile.width - 2 * AppPage.gouttiereMobile);
        final Rect bouton = _bouton(tester, parcours: parcours);
        expect(bouton.left, closeTo(colonne.left, 0.5));
        expect(bouton.right, closeTo(colonne.right, 0.5));
      });
    });
  }

  testWidgets('un seul compteur : PageParcours lit « n sur N »', (
    WidgetTester tester,
  ) async {
    await _monter(tester, vueMobile, _pageParcours());
    expect(find.byType(RangeeEtape), findsOneWidget);
    expect(find.text(t.commun.etape.sur(n: 2, total: 7)), findsOneWidget);
    expect(find.text(t.inscription.etapeSur(n: 2, total: 7)), findsNothing);
  });

  // Lot E9 : une etape de choix garde une colonne assez large pour le bento
  // des cartes (quatre colonnes de grille), centree, rangee comprise.
  testWidgets('1440, etape de choix : colonne large et centree', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      vueBureau,
      const PageEtape(
        numero: 1,
        total: 4,
        colonneLarge: true,
        child: Text('Pour qui est ce compte ?'),
      ),
    );
    final Rect colonne = _colonne(tester);
    // Toute la largeur offerte a 1440 (1136), dans la borne large : quatre
    // colonnes de grille, la ou 560 n'en donne que deux.
    expect(colonne.width, greaterThan(PageEtape.largeurColonne));
    expect(colonne.width, lessThanOrEqualTo(PageEtape.largeurColonneLarge));
    expect(GrilleBento.colonnesPour(colonne.width), 4);
    expect(GrilleBento.colonnesPour(PageEtape.largeurColonne), 2);
    expect(colonne.center.dx, closeTo(vueBureau.width / 2, 0.5));
    final Rect rangee = tester.getRect(find.byType(RangeeEtape));
    expect(rangee.width, closeTo(colonne.width, 0.5));
  });
}
