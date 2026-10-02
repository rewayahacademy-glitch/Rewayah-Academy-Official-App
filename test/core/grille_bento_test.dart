// BENTO-1 : la grille Bento partagee. Aucune tuile ne se chevauche, aucun
// trou, ecart de 16 px, deux colonnes a 320 et 390 px, une colonne a texte
// agrandi, et le Centre de commande alterne plusieurs etendues.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/grille_bento.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';

import '../capture/outil_capture.dart';
import '../support/harnais.dart';

/// Verifie qu'aucune cellule n'est couverte deux fois ni laissee vide.
void _sansTrouNiChevauchement(List<PlacementBento> places, int colonnes) {
  int lignes = 0;
  for (final PlacementBento p in places) {
    expect(p.colonne + p.colonnes, lessThanOrEqualTo(colonnes));
    lignes = lignes < p.ligne + p.lignes ? p.ligne + p.lignes : lignes;
  }
  final List<List<int>> n = List<List<int>>.generate(
    lignes,
    (_) => List<int>.filled(colonnes, 0),
  );
  for (final PlacementBento p in places) {
    for (int y = p.ligne; y < p.ligne + p.lignes; y++) {
      for (int x = p.colonne; x < p.colonne + p.colonnes; x++) {
        n[y][x]++;
      }
    }
  }
  for (final List<int> ligne in n) {
    for (final int c in ligne) {
      expect(c, 1, reason: 'cellule vide ou couverte deux fois : $places');
    }
  }
}

const List<EtendueBento> _centre2 = <EtendueBento>[
  EtendueBento.large,
  EtendueBento.haute,
  EtendueBento.carree,
  EtendueBento.carree,
  EtendueBento.large,
];

const List<EtendueBento> _centre4 = <EtendueBento>[
  EtendueBento.grande,
  EtendueBento.haute,
  EtendueBento.carree,
  EtendueBento.carree,
  EtendueBento(4, 1),
];

Widget _hote(double largeur, List<TuileBento> tuiles, {double echelle = 1}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(largeur, 2000),
          textScaler: TextScaler.linear(echelle),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: largeur,
            child: GrilleBento(tuiles: tuiles),
          ),
        ),
      ),
    );

List<TuileBento> _tuiles(List<EtendueBento> etendues) => <TuileBento>[
  for (int i = 0; i < etendues.length; i++)
    TuileBento(
      etendue: etendues[i],
      child: ColoredBox(key: ValueKey<int>(i), color: const Color(0xFF000000)),
    ),
];

void main() {
  group('placerBento', () {
    test('le Centre de commande : sans trou ni chevauchement, 2 et 4', () {
      _sansTrouNiChevauchement(placerBento(_centre2, 2), 2);
      _sansTrouNiChevauchement(placerBento(_centre4, 4), 4);
    });

    test('le Centre a deux colonnes alterne large, haut et carre', () {
      expect(placerBento(_centre2, 2), const <PlacementBento>[
        PlacementBento(0, 0, 2, 1),
        PlacementBento(0, 1, 1, 2),
        PlacementBento(1, 1, 1, 1),
        PlacementBento(1, 2, 1, 1),
        PlacementBento(0, 3, 2, 1),
      ]);
    });

    test('des listes quelconques sont toujours comblees', () {
      const List<List<EtendueBento>> cas = <List<EtendueBento>>[
        <EtendueBento>[EtendueBento.carree],
        <EtendueBento>[EtendueBento.haute, EtendueBento.carree],
        <EtendueBento>[
          EtendueBento.carree,
          EtendueBento.grande,
          EtendueBento.haute,
          EtendueBento.large,
          EtendueBento.carree,
        ],
        <EtendueBento>[EtendueBento.large, EtendueBento.large],
        <EtendueBento>[
          EtendueBento.haute,
          EtendueBento.haute,
          EtendueBento.haute,
        ],
      ];
      for (final List<EtendueBento> c in cas) {
        for (final int colonnes in <int>[2, 4]) {
          _sansTrouNiChevauchement(placerBento(c, colonnes), colonnes);
        }
      }
    });

    test('deux colonnes sous 600 px, quatre au-dela', () {
      expect(GrilleBento.colonnesPour(320), 2);
      expect(GrilleBento.colonnesPour(390), 2);
      expect(GrilleBento.colonnesPour(600), 4);
      expect(GrilleBento.colonnesPour(1440), 4);
    });
  });

  group('GrilleBento', () {
    for (final double largeur in <double>[320, 390]) {
      testWidgets('$largeur px : deux colonnes, ecart de 16 px', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_hote(largeur, _tuiles(_centre2)));
        Rect r(int i) => tester.getRect(find.byKey(ValueKey<int>(i)));
        final double cellule = (largeur - 16) / 2;
        // Tuile large : toute la largeur.
        expect(r(0).width, closeTo(largeur, 0.01));
        // Tuile haute : une colonne, deux lignes plus un ecart.
        expect(r(1).width, closeTo(cellule, 0.01));
        expect(r(1).height, closeTo(GrilleBento.hauteurLigne * 2 + 16, 0.01));
        // Ecart de 16 entre la large et la haute, et entre la haute et le
        // carre voisin.
        expect(r(1).top - r(0).bottom, closeTo(16, 0.01));
        expect(r(2).left - r(1).right, closeTo(16, 0.01));
        expect(r(3).top - r(2).bottom, closeTo(16, 0.01));
        expect(r(4).top - r(1).bottom, closeTo(16, 0.01));
        // Aucun chevauchement.
        for (int i = 0; i < 5; i++) {
          for (int j = i + 1; j < 5; j++) {
            expect(r(i).overlaps(r(j)), isFalse);
          }
        }
      });
    }

    testWidgets('texte a 200 % : une seule colonne de hauteur libre', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(320, <TuileBento>[
          const TuileBento(
            etendue: EtendueBento.carree,
            child: SizedBox(key: ValueKey<int>(0), height: 300),
          ),
          const TuileBento(
            etendue: EtendueBento.carree,
            child: SizedBox(key: ValueKey<int>(1), height: 40),
          ),
        ], echelle: 2),
      );
      final Rect a = tester.getRect(find.byKey(const ValueKey<int>(0)));
      final Rect b = tester.getRect(find.byKey(const ValueKey<int>(1)));
      expect(a.width, 320);
      expect(a.height, 300);
      expect(b.top - a.bottom, 16);
    });
  });

  group('Centre de commande', () {
    // Les vraies polices : la police de test (carres de 1 em) mesure un
    // texte bien plus large que celui de l'application.
    setUpAll(chargerPolicesDuDepot);
    for (final (double, double) cas in <(double, double)>[
      (320, 1),
      (390, 1),
      (320, 1.15),
      (1440, 1),
      (320, 2),
    ]) {
      final double largeur = cas.$1;
      testWidgets(
        '$largeur px, texte x${cas.$2} : formes variees, sans debordement',
        (WidgetTester tester) async {
          fixerVueCapture(tester, Size(largeur, 2400), 1);
          await tester.pumpWidget(
            hoteCapture(
              TableauDeBordPage(horloge: () => DateTime(2026, 9, 8, 17)),
              echelleTexte: cas.$2,
              surcharges: <Override>[
                serviceValidationProvider.overrideWithValue(
                  FauxServiceValidation(),
                ),
                serviceAdminProvider.overrideWithValue(
                  FauxServiceAdmin()
                    ..indicateursRendus = const IndicateursAdmin(
                      dossiersEnAttente: 3,
                      foyersSansEnseignant: 2,
                      rapportsManquants: 1,
                      incidents24h: 0,
                      comptesEchus: 0,
                      demandesEnAttente: 4,
                    ),
                ),
              ],
            ),
          );
          await stabiliser(tester);
          final Iterable<Element> cartes = find
              .descendant(
                of: find.byType(GrilleBento),
                matching: find.byType(AppCard),
              )
              .evaluate();
          expect(cartes.length, 5);
          final Set<String> formes = <String>{
            for (final Element e in cartes)
              () {
                final Size s = e.size!;
                return '${s.width.round()}x${s.height.round()}';
              }(),
          };
          // Large, haute et carree : trois formes distinctes (une seule
          // colonne a texte double, par construction).
          if (cas.$2 < 2) expect(formes.length, greaterThanOrEqualTo(3));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
