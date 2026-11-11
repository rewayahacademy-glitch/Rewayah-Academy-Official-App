// LUMIERE-DOUCE (directeur, 11/11/2026) : la lumiere d'une carte n'est jamais
// coupee. Mesure sur l'ecran reel, apres mise en page : chaque `HaloLumiere`
// en rectangle, agrandi de sa portee totale (`HaloLumiere.debordementCarte`),
// doit tenir dans l'ecran et dans toute coupe posee par un parent (liste,
// defilement, colonne qui deborde).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/halo_lumiere.dart';

/// Le rectangle, en coordonnees de l'ecran, que la lumiere de la carte peut
/// peindre : la carte agrandie de [HaloLumiere.debordementCarte].
List<Rect> zonesLumieresDeCarte(WidgetTester tester) => <Rect>[
  for (final Element e in find.byType(HaloLumiere).evaluate())
    if ((e.widget as HaloLumiere).forme == FormeHalo.rectangle)
      _zone(e.renderObject! as RenderBox),
];

Rect _zone(RenderBox boite) => MatrixUtils.transformRect(
  boite.getTransformTo(null),
  Offset.zero & boite.size,
).inflate(HaloLumiere.debordementCarte);

/// Echoue si une lumiere de carte depasse les bords de l'ecran ou est coupee
/// par un parent. [auMoins] : le nombre de lumieres de carte attendues.
void verifierLumieresEntieres(WidgetTester tester, {int auMoins = 1}) {
  final Size ecran = tester.view.physicalSize / tester.view.devicePixelRatio;
  final Rect vue = Offset.zero & ecran;
  int vues = 0;
  for (final Element e in find.byType(HaloLumiere).evaluate()) {
    if ((e.widget as HaloLumiere).forme != FormeHalo.rectangle) continue;
    final RenderBox boite = e.renderObject! as RenderBox;
    final Rect zone = _zone(boite);
    vues++;
    expect(
      zone.left >= vue.left - 0.01 && zone.right <= vue.right + 0.01,
      isTrue,
      reason:
          'La lumiere de carte depasse les bords de l ecran : $zone, '
          'ecran $vue.',
    );
    // Chaque parent qui coupe ce qu'il peint doit laisser passer toute la
    // lumiere.
    RenderObject enfant = boite;
    RenderObject? parent = boite.parent;
    while (parent != null) {
      final Rect? coupe = parent.describeApproximatePaintClip(enfant);
      if (coupe != null) {
        final Rect global = MatrixUtils.transformRect(
          parent.getTransformTo(null),
          coupe,
        );
        // A gauche et a droite, toujours. En haut et en bas, seulement pour
        // une carte entierement visible dans la coupe : une carte que le
        // defilement cache en partie l'est avec sa lumiere, c'est normal.
        final Rect carte = zone.deflate(HaloLumiere.debordementCarte);
        final bool carteVisible =
            carte.top >= global.top - 0.01 &&
            carte.bottom <= global.bottom + 0.01;
        expect(
          zone.left >= global.left - 0.01 &&
              zone.right <= global.right + 0.01 &&
              (!carteVisible ||
                  (zone.top >= global.top - 0.01 &&
                      zone.bottom <= global.bottom + 0.01)),
          isTrue,
          reason:
              'La lumiere de carte est coupee par ${parent.runtimeType} : '
              'coupe $global, lumiere $zone.',
        );
      }
      enfant = parent;
      parent = parent.parent;
    }
  }
  expect(
    vues,
    greaterThanOrEqualTo(auMoins),
    reason: 'Aucune lumiere de carte a mesurer.',
  );
}
