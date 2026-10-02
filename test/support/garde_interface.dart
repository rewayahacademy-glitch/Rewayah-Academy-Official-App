import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';

/// Les gardes de la revue du directeur des 01 et 02/10/2026 (K-54, K-55, K-56).
///
/// Chaque garde mesure une geometrie rendue, pas un texte de source : c'est
/// ce que le directeur voit, et ce qu'un controle de code ne peut pas voir.
/// Elles servent aux tests des composants partages, puis aux balayages
/// d'ecrans (lot 2) : `verifierBoutonCentre`, `verifierEcartCartes`,
/// `verifierAlignes`, `verifierSansChevauchement`, `verifierContenuCentre`,
/// `verifierLibelleCentreLigneALigne`, `verifierUnSeulBoutonPlein`.

/// Tolerance de mesure, en pixels logiques (arrondis de mise en page).
const double toleranceGarde = 1.0;

/// Le libelle de [bouton] est centre, horizontalement et verticalement, dans
/// son bouton, et ne deborde ni du bouton ni de l'ecran (K-54).
///
/// [libelle] est le texte cherche a l'interieur de [bouton].
void verifierBoutonCentre(WidgetTester tester, Finder bouton, String libelle) {
  final Rect cadre = tester.getRect(bouton);
  final Finder texte = find.descendant(
    of: bouton,
    matching: find.text(libelle),
  );
  final Rect t = tester.getRect(texte);
  final double ecran =
      tester.view.physicalSize.width / tester.view.devicePixelRatio;

  expect(
    (t.center.dx - cadre.center.dx).abs(),
    lessThanOrEqualTo(toleranceGarde),
    reason:
        'le libelle "$libelle" n\'est pas centre horizontalement : '
        'libelle ${t.center.dx}, bouton ${cadre.center.dx}',
  );
  expect(
    (t.center.dy - cadre.center.dy).abs(),
    lessThanOrEqualTo(toleranceGarde),
    reason:
        'le libelle "$libelle" n\'est pas centre verticalement : '
        'libelle ${t.center.dy}, bouton ${cadre.center.dy}',
  );
  expect(
    t.left >= cadre.left - toleranceGarde &&
        t.right <= cadre.right + toleranceGarde,
    isTrue,
    reason: 'le libelle "$libelle" deborde du bouton ($t hors de $cadre)',
  );
  expect(
    cadre.left >= -toleranceGarde && cadre.right <= ecran + toleranceGarde,
    isTrue,
    reason: 'le bouton "$libelle" deborde de l\'ecran ($cadre, largeur $ecran)',
  );
}

/// L'ecart vertical entre deux cartes consecutives vaut au moins [minimum]
/// (K-55 : jamais de cartes collees). [cartes] est trie de haut en bas.
void verifierEcartCartes(
  WidgetTester tester,
  Finder cartes, {
  required double minimum,
}) {
  final List<Rect> cadres = <Rect>[
    for (int i = 0; i < cartes.evaluate().length; i++)
      tester.getRect(cartes.at(i)),
  ]..sort((Rect a, Rect b) => a.top.compareTo(b.top));
  expect(cadres.length, greaterThan(1), reason: 'il faut au moins deux cartes');
  for (int i = 1; i < cadres.length; i++) {
    final double ecart = cadres[i].top - cadres[i - 1].bottom;
    expect(
      ecart,
      greaterThanOrEqualTo(minimum - toleranceGarde),
      reason: 'cartes ${i - 1} et $i collees : ecart $ecart, minimum $minimum',
    );
  }
}

/// Les centres verticaux de [a] et [b] coincident (avatar et nom sur une meme
/// ligne : revue du 01/10, l'avatar etait decale du nom).
void verifierAlignes(WidgetTester tester, Finder a, Finder b) {
  final double ya = tester.getRect(a).center.dy;
  final double yb = tester.getRect(b).center.dy;
  expect(
    (ya - yb).abs(),
    lessThanOrEqualTo(toleranceGarde),
    reason: 'centres verticaux decales : $ya contre $yb',
  );
}

/// Aucun des elements de [finders] ne recouvre un autre (regle : aucun
/// element ne recouvre un contenu a lire).
void verifierSansChevauchement(WidgetTester tester, List<Finder> finders) {
  final List<Rect> cadres = <Rect>[
    for (final Finder f in finders) tester.getRect(f.first),
  ];
  for (int i = 0; i < cadres.length; i++) {
    for (int j = i + 1; j < cadres.length; j++) {
      final Rect commun = cadres[i].intersect(cadres[j]);
      final bool recouvre =
          commun.width > toleranceGarde && commun.height > toleranceGarde;
      expect(
        recouvre,
        isFalse,
        reason:
            'les elements $i et $j se recouvrent : ${cadres[i]} / ${cadres[j]}',
      );
    }
  }
}

/// Le contenu de [bouton] (un libelle, une icone, ou les deux) est centre,
/// horizontalement et verticalement, dans son bouton (K-54).
///
/// [contenus] est la liste des elements du contenu, cherches a l'interieur de
/// [bouton] : le rectangle qui les englobe tous est celui qui doit etre centre.
/// C'est la garde des boutons faits d'une icone et d'un mot (`BoutonOutil`,
/// `LienFleche`, `FilterPill`...), la ou [verifierBoutonCentre] ne mesure que
/// le libelle.
void verifierContenuCentre(
  WidgetTester tester,
  Finder bouton,
  List<Finder> contenus, {
  bool horizontal = true,
}) {
  final Rect cadre = tester.getRect(bouton.first);
  Rect? groupe;
  for (final Finder c in contenus) {
    final Finder interne = find.descendant(of: bouton.first, matching: c);
    expect(interne, findsWidgets, reason: 'contenu absent du bouton');
    for (int i = 0; i < interne.evaluate().length; i++) {
      final Rect r = tester.getRect(interne.at(i));
      groupe = groupe == null ? r : groupe.expandToInclude(r);
    }
  }
  final Rect g = groupe!;
  if (horizontal) {
    expect(
      (g.center.dx - cadre.center.dx).abs(),
      lessThanOrEqualTo(toleranceGarde),
      reason:
          'contenu non centre horizontalement : contenu ${g.center.dx}, '
          'bouton ${cadre.center.dx} (cadre $cadre, contenu $g)',
    );
  }
  expect(
    (g.center.dy - cadre.center.dy).abs(),
    lessThanOrEqualTo(toleranceGarde),
    reason:
        'contenu non centre verticalement : contenu ${g.center.dy}, '
        'bouton ${cadre.center.dy} (cadre $cadre, contenu $g)',
  );
  expect(
    g.left >= cadre.left - toleranceGarde &&
        g.right <= cadre.right + toleranceGarde &&
        g.top >= cadre.top - toleranceGarde &&
        g.bottom <= cadre.bottom + toleranceGarde,
    isTrue,
    reason: 'le contenu deborde du bouton ($g hors de $cadre)',
  );
  final double ecran =
      tester.view.physicalSize.width / tester.view.devicePixelRatio;
  expect(
    cadre.left >= -toleranceGarde && cadre.right <= ecran + toleranceGarde,
    isTrue,
    reason: 'le bouton deborde de l\'ecran ($cadre, largeur $ecran)',
  );
}

/// Le libelle passe a la ligne en restant centre ligne a ligne : le `Text` de
/// [bouton] porte `TextAlign.center` (K-54, libelle multi-ligne).
void verifierLibelleCentreLigneALigne(
  WidgetTester tester,
  Finder bouton,
  String libelle,
) {
  final Text texte = tester.widget<Text>(
    find.descendant(of: bouton.first, matching: find.text(libelle)).first,
  );
  expect(
    texte.textAlign,
    TextAlign.center,
    reason: 'le libelle "$libelle" n\'est pas centre ligne a ligne',
  );
}

/// Un seul bouton plein par ecran (K-56) : au plus un `ActionPrincipale` de
/// niveau `principale` est visible. Les secondaires, tertiaires et liens ne
/// comptent pas ; un ecran sans action pleine (lecture) passe aussi.
///
/// [maximum] vaut 1 sauf pour un ecran qui en montre deux de contextes
/// distincts a la fois (une feuille posee sur sa page) : la garde les dit.
void verifierUnSeulBoutonPlein(WidgetTester tester, {int maximum = 1}) {
  final int pleins = find
      .byWidgetPredicate(
        (Widget w) => w is ActionPrincipale && w.niveau == NiveauAction.principale,
      )
      .evaluate()
      .length;
  expect(
    pleins,
    lessThanOrEqualTo(maximum),
    reason:
        '$pleins boutons pleins visibles, $maximum au plus (K-56) : une '
        'action secondaire se rend en niveau secondaire, tertiaire ou lien',
  );
}
