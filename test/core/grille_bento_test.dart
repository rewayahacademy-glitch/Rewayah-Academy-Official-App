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

// BENTO-1b/1c : la largeur utile par colonne, a l'echelle du texte, decide du
// nombre de colonnes (4, 3, 2, 1), jamais l'echelle seule. Valeurs fixes,
// jamais recalculees par la fonction testee.
const List<double> _echelles = <double>[1, 1.15, 1.3, 2];
final Map<double, List<int>> _colonnesAttendues = <double, List<int>>{
  // echelles :  1.0 1.15 1.3 2.0
  320: <int>[2, 2, 2, 1],
  600: <int>[4, 4, 3, 2],
  1024: <int>[4, 4, 4, 4],
  1440: <int>[4, 4, 4, 4],
};

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
        for (final int colonnes in <int>[2, 3, 4]) {
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

    test('colonnes selon la largeur utile et le texte', () {
      _colonnesAttendues.forEach((double largeur, List<int> colonnes) {
        for (int i = 0; i < _echelles.length; i++) {
          expect(
            GrilleBento.colonnesPour(largeur, _echelles[i]),
            colonnes[i],
            reason: '$largeur px, texte x${_echelles[i]}',
          );
        }
      });
      // BENTO-1c : a texte 100 %, une place etroite garde ses deux colonnes ;
      // texte agrandi, elle repasse en une colonne.
      expect(GrilleBento.colonnesPour(200), 2);
      expect(GrilleBento.colonnesPour(200, 0.9), 2);
      expect(GrilleBento.colonnesPour(200, 1.15), 1);
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
      for (final double echelle in _echelles) {
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
          final int n =
              _colonnesAttendues[largeur]![_echelles.indexOf(echelle)];
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

  group('GrilleBento, hauteur du contenu (BENTO-2)', () {
    // La vue de test fait 800 x 600 par defaut : on la fixe a la largeur
    // voulue, assez haute pour que rien ne soit borne par l'ecran.
    Future<void> poser(
      WidgetTester tester,
      double largeur,
      List<TuileBento> tuiles, {
      double echelle = 1,
    }) {
      fixerVueCapture(tester, Size(largeur, 3000), 1);
      return tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(largeur, 3000),
              textScaler: TextScaler.linear(echelle),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: largeur,
                child: GrilleBento(hauteurContenu: true, tuiles: tuiles),
              ),
            ),
          ),
        ),
      );
    }

    TuileBento tuile(int i, EtendueBento e, double h, [EtendueBento? l]) =>
        TuileBento(
          etendue: e,
          etendueLarge: l,
          child: SizedBox(key: ValueKey<int>(i), height: h),
        );
    Rect r(WidgetTester tester, int i) =>
        tester.getRect(find.byKey(ValueKey<int>(i)));

    // Composition d'Aujourd'hui (ENS-02) : grande, large, haute/grande,
    // grande, large. Sur quatre colonnes : deux colonnes de 2 cellules.
    testWidgets('1440 px : deux colonnes exactes, hauteurs du contenu', (
      WidgetTester tester,
    ) async {
      await poser(tester, 1440, <TuileBento>[
        tuile(0, EtendueBento.grande, 500),
        tuile(1, EtendueBento.large, 90),
        tuile(2, EtendueBento.haute, 700, EtendueBento.grande),
        tuile(3, EtendueBento.grande, 210),
        tuile(4, EtendueBento.large, 60),
      ]);
      const double demi = (1440 - 16) / 2;
      for (final int i in <int>[0, 1, 2, 3, 4]) {
        expect(r(tester, i).width, demi, reason: 'tuile $i');
      }
      // Le contenu garde sa hauteur : rien n'est reduit ni coupe.
      expect(r(tester, 2).height, 700);
      expect(r(tester, 0).left, 0);
      expect(r(tester, 3).left, 0);
      expect(r(tester, 3).top - r(tester, 0).bottom, 16);
      expect(r(tester, 1).left, demi + 16);
      expect(r(tester, 2).top - r(tester, 1).bottom, 16);
      expect(r(tester, 4).top - r(tester, 2).bottom, 16);
      expect(tester.takeException(), isNull);
    });

    // Accueil famille (TUT-01) : blocage 4x1, deux grandes, derniere 4x1.
    testWidgets('1024 px : bandes pleine largeur et tuiles cote a cote', (
      WidgetTester tester,
    ) async {
      await poser(tester, 1024, <TuileBento>[
        tuile(0, EtendueBento.large, 80, const EtendueBento(4, 1)),
        tuile(1, EtendueBento.grande, 400),
        tuile(2, EtendueBento.grande, 250),
        tuile(3, EtendueBento.large, 120, const EtendueBento(4, 1)),
      ]);
      expect(r(tester, 0).width, 1024);
      expect(r(tester, 1).top - r(tester, 0).bottom, 16);
      expect(r(tester, 2).top, r(tester, 1).top);
      expect(r(tester, 2).left, r(tester, 1).right + 16);
      // La bande suivante part sous la plus haute des deux.
      expect(r(tester, 3).top - r(tester, 1).bottom, 16);
      expect(r(tester, 3).width, 1024);
    });

    testWidgets('390 px : tout en pleine largeur, dans l\'ordre declare', (
      WidgetTester tester,
    ) async {
      await poser(tester, 390, <TuileBento>[
        tuile(0, EtendueBento.grande, 300),
        tuile(1, EtendueBento.haute, 200, EtendueBento.grande),
        tuile(2, EtendueBento.grande, 100),
      ]);
      for (final int i in <int>[0, 1, 2]) {
        expect(r(tester, i).width, 390, reason: 'tuile $i');
      }
      expect(r(tester, 1).top - r(tester, 0).bottom, 16);
      expect(r(tester, 2).top - r(tester, 1).bottom, 16);
    });

    testWidgets('1440 px, texte x2 : aucune hauteur fixe, aucun debordement', (
      WidgetTester tester,
    ) async {
      await poser(tester, 1440, <TuileBento>[
        tuile(0, EtendueBento.grande, 900),
        tuile(1, EtendueBento.haute, 50, EtendueBento.grande),
      ], echelle: 2);
      expect(r(tester, 0).height, 900);
      expect(tester.takeException(), isNull);
    });

    // Aujourd'hui sans remplacement : carte, Ma journee, A terminer. La
    // troisieme tuile, seule dans sa bande, est elargie par la regle sans trou
    // de placerBento : pleine largeur, sous la carte et Ma journee.
    for (final TextDirection sens in TextDirection.values) {
      testWidgets(
        '1440 px, ${sens.name} : une 2x2 seule s elargit, sans trou',
        (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(1440, 3000), 1);
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(size: Size(1440, 3000)),
              child: Directionality(
                textDirection: sens,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 1440,
                    child: GrilleBento(
                      hauteurContenu: true,
                      tuiles: <TuileBento>[
                        tuile(0, EtendueBento.grande, 300),
                        tuile(1, EtendueBento.haute, 120, EtendueBento.grande),
                        tuile(2, EtendueBento.grande, 200),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          const double demi = (1440 - 16) / 2;
          expect(r(tester, 0).width, demi);
          expect(r(tester, 1).width, demi);
          expect(r(tester, 2).width, 1440);
          expect(r(tester, 2).top - r(tester, 0).bottom, 16);
          expect(r(tester, 0).left, sens == TextDirection.ltr ? 0 : demi + 16);
          expect(tester.takeException(), isNull);
        },
      );
    }

    // BENTO-1c : 750 px et texte double donnent trois colonnes. Aujourd'hui
    // avec un remplacement : l'ordre declare est garde (le remplacement
    // avant Ma journee) et Ma journee n'est jamais reduite a un tiers.
    testWidgets('750 px, texte x2 (trois colonnes) : ordre garde, rien de '
        'reduit', (WidgetTester tester) async {
      await poser(tester, 750, <TuileBento>[
        tuile(0, EtendueBento.grande, 300),
        tuile(1, EtendueBento.large, 80),
        tuile(2, EtendueBento.haute, 400, EtendueBento.grande),
        tuile(3, EtendueBento.grande, 200),
      ], echelle: 2);
      for (int i = 1; i < 4; i++) {
        expect(r(tester, i).top, greaterThan(r(tester, i - 1).top));
      }
      expect(r(tester, 2).width, greaterThan(750 / 2));
      expect(r(tester, 2).height, 400);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dispositions en moulinet : une colonne, rien de perdu', (
      WidgetTester tester,
    ) async {
      // BENTO-2b (revue BENTO-2-R, m2) : un vrai moulinet sur quatre
      // colonnes, prouve par placerBento, puis la branche de repli prouvee
      // par les positions rendues.
      //   A A A B
      //   D C C B
      //   D E E E
      // y = 1 coupe B, y = 2 coupe D ; x = 1 et x = 2 coupent A, x = 3
      // coupe E : aucune coupe possible.
      const List<EtendueBento> etendues = <EtendueBento>[
        EtendueBento(3, 1), // A
        EtendueBento(1, 2), // B
        EtendueBento(1, 2), // D
        EtendueBento(2, 1), // C
        EtendueBento(3, 1), // E
      ];
      expect(placerBento(etendues, 4), const <PlacementBento>[
        PlacementBento(0, 0, 3, 1),
        PlacementBento(3, 0, 1, 2),
        PlacementBento(0, 1, 1, 2),
        PlacementBento(1, 1, 2, 1),
        PlacementBento(1, 2, 3, 1),
      ]);
      expect(GrilleBento.colonnesPour(800), 4);
      await poser(tester, 800, <TuileBento>[
        for (int i = 0; i < etendues.length; i++)
          tuile(i, etendues[i], 40, etendues[i]),
      ]);
      // Repli : une colonne pleine largeur, dans l'ordre declare, 16 entre
      // deux tuiles ; aucune tuile perdue.
      for (int i = 0; i < etendues.length; i++) {
        expect(r(tester, i).width, 800);
        expect(r(tester, i).left, 0);
        if (i > 0) expect(r(tester, i).top - r(tester, i - 1).bottom, 16);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Centre de commande', () {
    // Les vraies polices : la police de test (carres de 1 em) mesure un
    // texte bien plus large que celui de l'application.
    setUpAll(chargerPolicesDuDepot);
    // (vue, texte, largeur de la grille, colonnes) : valeurs fixes relevees
    // sur la page reelle, jamais recalculees par colonnesPour (BENTO-1c).
    // 800 px et texte double tombe dans le palier a trois colonnes.
    for (final (double, double, double, int) cas
        in <(double, double, double, int)>[
          (390, 1, 358, 2),
          (320, 1, 288, 2),
          (320, 1.15, 288, 2),
          (320, 1.3, 288, 1),
          (320, 2, 288, 1),
          (600, 1, 552, 2),
          (600, 1.15, 552, 2),
          (600, 1.3, 552, 2),
          (600, 2, 552, 2),
          (800, 2, 752, 3),
          (1024, 1, 976, 4),
          (1024, 1.15, 976, 4),
          (1024, 1.3, 976, 4),
          (1024, 2, 976, 4),
          (1440, 1, 1136, 4),
          (1440, 1.15, 1136, 4),
          (1440, 1.3, 1136, 4),
          (1440, 2, 1136, 4),
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
          expect(grille.width, cas.$3);
          final int n = cas.$4;
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
          // Large, haute et carree : trois formes distinctes des qu'il y a
          // plusieurs colonnes (une seule colonne a 320 px et texte double).
          if (n > 1) expect(formes.length, greaterThanOrEqualTo(3));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
