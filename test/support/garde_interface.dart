import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les gardes de la revue du directeur des 01 et 02/10/2026 (K-54, K-55).
///
/// Chaque garde mesure une geometrie rendue, pas un texte de source : c'est
/// ce que le directeur voit, et ce qu'un controle de code ne peut pas voir.
/// Elles servent aux tests des composants partages, puis aux balayages
/// d'ecrans (lot 2) : `verifierBoutonCentre`, `verifierEcartCartes`,
/// `verifierAlignes`, `verifierSansChevauchement`.

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

/// Les centres horizontaux de [a] et [b] coincident (avatar et nom sur le meme
/// axe central, disposition verticale : revue du 01/10 et du 02/10, le nom
/// restait decale par rapport au cercle).
void verifierMemeAxe(WidgetTester tester, Finder a, Finder b) {
  final double xa = tester.getRect(a).center.dx;
  final double xb = tester.getRect(b).center.dx;
  expect(
    (xa - xb).abs(),
    lessThanOrEqualTo(toleranceGarde),
    reason: 'centres horizontaux decales : $xa contre $xb',
  );
}

/// [interieur] reste entierement dans [cadre] (un avatar ne deborde pas de sa
/// tuile).
void verifierContenu(WidgetTester tester, Finder interieur, Finder cadre) {
  final Rect i = tester.getRect(interieur);
  final Rect c = tester.getRect(cadre);
  expect(
    i.left >= c.left - toleranceGarde &&
        i.right <= c.right + toleranceGarde &&
        i.top >= c.top - toleranceGarde &&
        i.bottom <= c.bottom + toleranceGarde,
    isTrue,
    reason: 'deborde de son cadre : $i hors de $c',
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
