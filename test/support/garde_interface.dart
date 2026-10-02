import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// Les cartes trouvees par [cartes] (une par finder, la premiere) sont toutes
/// separees d'au moins [minimum], cote a cote comme l'une sous l'autre (K-55).
/// Sert quand la carte est dans une carte plus grande, ou quand son type est
/// prive : on la designe par son contenu. Retourne le nombre de cartes mesurees.
int verifierEcartEntre(
  WidgetTester tester,
  List<Finder> cartes, {
  double minimum = 16,
}) {
  final List<Rect> cadres = <Rect>[
    for (final Finder f in cartes)
      if (f.evaluate().isNotEmpty) tester.getRect(f.first),
  ];
  for (int i = 0; i < cadres.length; i++) {
    for (int j = i + 1; j < cadres.length; j++) {
      final Rect a = cadres[i];
      final Rect b = cadres[j];
      final double recouvreX =
          (a.right < b.right ? a.right : b.right) -
          (a.left > b.left ? a.left : b.left);
      final double recouvreY =
          (a.bottom < b.bottom ? a.bottom : b.bottom) -
          (a.top > b.top ? a.top : b.top);
      final double ecart = recouvreX > toleranceGarde
          ? (a.top < b.top ? b.top - a.bottom : a.top - b.bottom)
          : recouvreY > toleranceGarde
          ? (a.left < b.left ? b.left - a.right : a.left - b.right)
          : double.infinity;
      expect(
        ecart,
        greaterThanOrEqualTo(minimum - toleranceGarde),
        reason: 'cartes collees : $a et $b ne sont separees que de $ecart',
      );
    }
  }
  return cadres.length;
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
        (Widget w) =>
            w is ActionPrincipale && w.niveau == NiveauAction.principale,
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

/// Aucune carte ne touche une autre, a l'ecran (K-55) : toute paire de
/// surfaces voisines (cote a cote ou l'une sous l'autre) est separee d'au
/// moins [minimum] (`Ecart.vLg`, 16). Les surfaces sont les cartes les plus
/// externes parmi [types] : une carte posee dans une autre ne compte pas, et
/// les lignes d'une `CarteLignes` ne sont pas des cartes.
///
/// Une `AppCard` a marge reduite (pastille de choix) n'exige que [minimumPastille].
/// Retourne le nombre de surfaces mesurees, pour que le test dise qu'il a
/// bien vu des cartes.
int verifierAucuneCarteCollee(
  WidgetTester tester, {
  required bool Function(Widget) estCarte,
  double minimum = 16,
  double minimumPastille = 8,
  bool Function(Widget)? estPastille,
}) {
  final Finder toutes = find.byWidgetPredicate(estCarte);
  final List<Element> elements = toutes.evaluate().toList();
  final List<(Rect, double)> surfaces = <(Rect, double)>[];
  for (final Element e in elements) {
    bool dansUneCarte = false;
    e.visitAncestorElements((Element a) {
      if (estCarte(a.widget)) {
        dansUneCarte = true;
        return false;
      }
      return true;
    });
    if (dansUneCarte) {
      continue;
    }
    final RenderBox? boite = e.renderObject as RenderBox?;
    if (boite == null || !boite.hasSize || boite.size.isEmpty) {
      continue;
    }
    final Rect cadre = boite.localToGlobal(Offset.zero) & boite.size;
    final bool pastille = estPastille?.call(e.widget) ?? false;
    surfaces.add((cadre, pastille ? minimumPastille : minimum));
  }
  for (int i = 0; i < surfaces.length; i++) {
    for (int j = i + 1; j < surfaces.length; j++) {
      final Rect a = surfaces[i].$1;
      final Rect b = surfaces[j].$1;
      final double exigence = surfaces[i].$2 < surfaces[j].$2
          ? surfaces[i].$2
          : surfaces[j].$2;
      final double recouvreX =
          (a.right < b.right ? a.right : b.right) -
          (a.left > b.left ? a.left : b.left);
      final double recouvreY =
          (a.bottom < b.bottom ? a.bottom : b.bottom) -
          (a.top > b.top ? a.top : b.top);
      // Cote a cote : meme bande, ecart horizontal. L'un sous l'autre : meme
      // colonne, ecart vertical.
      final double ecart = recouvreX > toleranceGarde
          ? (a.top < b.top ? b.top - a.bottom : a.top - b.bottom)
          : recouvreY > toleranceGarde
          ? (a.left < b.left ? b.left - a.right : a.left - b.right)
          : double.infinity;
      expect(
        ecart,
        greaterThanOrEqualTo(exigence - toleranceGarde),
        reason:
            'cartes collees : $a et $b ne sont separees que de $ecart '
            '(minimum $exigence)',
      );
    }
  }
  return surfaces.length;
}

/// La taille de police rendue du texte trouve par [texte] (celle que le
/// directeur voit, theme et echelle compris).
double taillePolice(WidgetTester tester, Finder texte) {
  final RenderParagraph p = tester.renderObject<RenderParagraph>(
    find.descendant(of: texte.first, matching: find.byType(RichText)).first,
  );
  return p.text.style?.fontSize ?? double.nan;
}

/// Hierarchie de titres stricte (HIER-1) : [titre] est strictement plus grand
/// que chacun des [inferieurs] (marque, nom, titre de section voisins).
/// « Un nom et un titre ne doivent jamais avoir la meme taille. »
void verifierHierarchie(
  WidgetTester tester, {
  required Finder titre,
  required Map<String, Finder> inferieurs,
}) {
  expect(titre, findsWidgets, reason: 'le titre d\'ecran est introuvable');
  final double grand = taillePolice(tester, titre);
  inferieurs.forEach((String role, Finder f) {
    expect(f, findsWidgets, reason: '$role est introuvable');
    final double petit = taillePolice(tester, f);
    expect(
      grand,
      greaterThan(petit),
      reason:
          'le titre ($grand) doit etre strictement plus grand que $role '
          '($petit)',
    );
  });
}
