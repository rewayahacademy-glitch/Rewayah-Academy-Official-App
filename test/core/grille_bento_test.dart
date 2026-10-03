// BENTO-1 : la grille Bento partagee. Aucune tuile ne se chevauche, aucun
// trou, ecart de 16 px, deux colonnes a 320 et 390 px, et le Centre de
// commande alterne plusieurs etendues. BENTO-1b : le nombre de colonnes suit
// la largeur utile a l'echelle du texte (une colonne a 320 px et texte
// double, plusieurs a 1440 px et texte double).

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

    // BENTO-1b : la largeur utile par colonne, a l'echelle du texte, decide
    // du nombre de colonnes (4, 2, 1), jamais l'echelle seule.
    final Map<double, List<int>> attendu = <double, List<int>>{
      // echelles :  1.0 1.15 1.3 2.0
      320: <int>[2, 2, 2, 1],
      600: <int>[4, 4, 2, 2],
      1024: <int>[4, 4, 4, 4],
      1440: <int>[4, 4, 4, 4],
    };
    const List<double> echelles = <double>[1, 1.15, 1.3, 2];
    test('colonnes selon la largeur utile et le texte', () {
      attendu.forEach((double largeur, List<int> colonnes) {
        for (int i = 0; i < echelles.length; i++) {
          expect(
            GrilleBento.colonnesPour(largeur, echelles[i]),
            colonnes[i],
            reason: '$largeur px, texte x${echelles[i]}',
          );
        }
      });
      // Une place etroite repasse en une colonne.
      expect(GrilleBento.colonnesPour(200), 1);
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

    // BENTO-1b : 320/600/1024/1440 px x texte 1.0/1.15/1.3/2.0. La plus
    // etroite des tuiles fait exactement une colonne du nombre attendu, les
    // lignes grandissent avec le texte, rien ne se chevauche ni ne sort.
    for (final double largeur in <double>[320, 600, 1024, 1440]) {
      for (final double echelle in <double>[1, 1.15, 1.3, 2]) {
        testWidgets('$largeur px, texte x$echelle : colonnes et bornes', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, Size(largeur, 3000), 1);
          await tester.pumpWidget(
            _hote(largeur, <TuileBento>[
              for (int i = 0; i < _centre2.length; i++)
                TuileBento(
                  etendue: _centre2[i],
                  etendueLarge: _centre4[i],
                  child: ColoredBox(
                    key: ValueKey<int>(i),
                    color: const Color(0xFF000000),
                  ),
                ),
            ], echelle: echelle),
          );
          expect(tester.takeException(), isNull);
          final int n = GrilleBento.colonnesPour(largeur, echelle);
          final List<Rect> r = <Rect>[
            for (int i = 0; i < _centre2.length; i++)
              tester.getRect(find.byKey(ValueKey<int>(i))),
          ];
          final double cellule = (largeur - 16 * (n - 1)) / n;
          final double plusEtroite = r
              .map((Rect x) => x.width)
              .reduce((double a, double b) => a < b ? a : b);
          expect(plusEtroite, closeTo(cellule, 0.01));
          for (int i = 0; i < r.length; i++) {
            expect(r[i].left, greaterThanOrEqualTo(-0.01));
            expect(r[i].right, lessThanOrEqualTo(largeur + 0.01));
            for (int j = i + 1; j < r.length; j++) {
              expect(r[i].overlaps(r[j]), isFalse);
            }
          }
          if (n > 1) {
            // La tuile haute : deux lignes agrandies plus un ecart.
            expect(
              r[1].height,
              closeTo(GrilleBento.hauteurLignePour(echelle) * 2 + 16, 0.01),
            );
            // Des tailles variees, jamais un damier.
            expect(
              <String>{
                for (final Rect x in r)
                  '${x.width.round()}x${x.height.round()}',
              }.length,
              greaterThanOrEqualTo(2),
            );
          }
        });
      }
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
      (390, 1),
      for (final double l in <double>[320, 600, 1024, 1440])
        for (final double e in <double>[1, 1.15, 1.3, 2]) (l, e),
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
          // BENTO-1b : le nombre de colonnes suit la largeur utile de la
          // grille a cette echelle ; la plus etroite des cartes fait une
          // colonne, et aucune ne sort de la grille.
          final Rect grille = tester.getRect(find.byType(GrilleBento));
          final int n = GrilleBento.colonnesPour(grille.width, cas.$2);
          final double cellule = (grille.width - 16 * (n - 1)) / n;
          final List<Rect> rects = <Rect>[
            for (final Element e in cartes)
              tester.getRect(find.byElementPredicate((Element x) => x == e)),
          ];
          expect(
            rects
                .map((Rect x) => x.width)
                .reduce((double a, double b) => a < b ? a : b),
            closeTo(cellule, 0.5),
          );
          for (final Rect x in rects) {
            expect(x.left, greaterThanOrEqualTo(grille.left - 0.5));
            expect(x.right, lessThanOrEqualTo(grille.right + 0.5));
          }
          if (largeur == 320 && cas.$2 == 2) expect(n, 1);
          if (largeur == 1440) expect(n, greaterThanOrEqualTo(2));
          // Large, haute et carree : trois formes distinctes des qu'il y a
          // plusieurs colonnes (une seule colonne a 320 px et texte double).
          if (n > 1) expect(formes.length, greaterThanOrEqualTo(3));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
