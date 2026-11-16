// SCENE-CLASSE (directeur, 11/11/2026) : la grille des visages
// (MODES-AFFICHAGE §3 et §5). Le calcul d'abord (fonction pure), sur les
// ecrans de reference ; puis le widget : arrivee, depart, reconnexion,
// mouvement reduit, pages.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/widgets/barre_precedent_suivant.dart';
import 'package:rewayah_academy/core/widgets/grille_visages.dart';

import '../../capture/outil_capture.dart';

/// Un ecran de reference : sa taille, et la place que la scene y laisse aux
/// visages (les commandes et l'ile ont leur place reservee).
typedef _Ecran = ({String nom, Size taille, EdgeInsets reserve});

/// Telephone : l'ile en haut (72), la barre en bas (96), 16 de chaque cote.
/// Tablette : idem. Ordinateur : la colonne des commandes au debut (120), la
/// marge de la scene (16) ; rien en haut ni en bas.
const List<_Ecran> _ecrans = <_Ecran>[
  (
    nom: 'telephone 320x568',
    taille: Size(320, 568),
    reserve: EdgeInsets.fromLTRB(16, 72, 16, 112),
  ),
  (
    nom: 'telephone 390x844',
    taille: Size(390, 844),
    reserve: EdgeInsets.fromLTRB(16, 72, 16, 112),
  ),
  (
    nom: 'tablette 820x1180',
    taille: Size(820, 1180),
    reserve: EdgeInsets.fromLTRB(16, 72, 16, 112),
  ),
  (
    nom: 'ordinateur 1280x720',
    taille: Size(1280, 720),
    reserve: EdgeInsets.fromLTRB(136, 16, 16, 16),
  ),
  (
    nom: 'ordinateur 1440x900',
    taille: Size(1440, 900),
    reserve: EdgeInsets.fromLTRB(136, 16, 16, 16),
  ),
  (
    nom: 'ordinateur 1920x1080',
    taille: Size(1920, 1080),
    reserve: EdgeInsets.fromLTRB(136, 16, 16, 16),
  ),
];

double _rapportDe(Size ecran) => rapportCadre(
  AppGabarit.pour(ecran.width),
  ecran.width >= ecran.height ? Orientation.landscape : Orientation.portrait,
);

void main() {
  group('la forme du cadre se deduit du gabarit et de l orientation', () {
    test('telephone en portrait : carre ; ailleurs : 4/3', () {
      expect(rapportCadre(Gabarit.mobile, Orientation.portrait), 1);
      expect(rapportCadre(Gabarit.mobile, Orientation.landscape), 4 / 3);
      expect(rapportCadre(Gabarit.tablette, Orientation.portrait), 4 / 3);
      expect(rapportCadre(Gabarit.desktop, Orientation.landscape), 4 / 3);
    });
  });

  group('calculerGrille, 1 a 12 personnes, sur les ecrans de reference', () {
    for (final _Ecran e in _ecrans) {
      for (int n = 1; n <= 12; n++) {
        test('${e.nom}, $n personnes', () {
          final Size place = e.reserve.deflateSize(e.taille);
          final double rapport = _rapportDe(e.taille);
          final DispositionGrille d = calculerGrille(
            n,
            place,
            rapport: rapport,
          );
          // Jamais etire : la forme demandee, a un point pres (arrondi).
          expect(
            (d.cadre.width / rapport - d.cadre.height).abs(),
            lessThanOrEqualTo(1),
            reason: '$d',
          );
          // La borne tenue.
          expect(d.cadre.width, lessThanOrEqualTo(largeurMaxCadre));
          // Jamais minuscule : 96 au moins, sinon des pages.
          expect(d.cadre.height, greaterThanOrEqualTo(coteMinCadre));
          expect(d.pages * d.parPage, greaterThanOrEqualTo(n));
          // Jusqu'a sept (une classe pleine et son enseignant), tout tient
          // sur une page, sauf a sept sur le plus petit telephone (320 de
          // large : trois colonnes de 96 n'y entrent pas) : deux pages,
          // jamais des cadres de 85 (signale au pilote).
          if (n <= 6 || (n == 7 && e.taille.width > 320)) {
            expect(d.pages, 1, reason: '$d');
          }
          final Size zone = d.pages > 1
              ? Size(place.width, place.height - hauteurBarrePages)
              : place;
          for (int page = 0; page < d.pages; page++) {
            final int nombre = (n - page * d.parPage).clamp(0, d.parPage);
            final List<Rect> rects = rectsGrille(d, nombre, zone);
            expect(rects, hasLength(nombre));
            final Rect tout = Offset.zero & zone;
            for (final Rect r in rects) {
              // Aucun hors de la place (donc ni sous la barre ni sous l'ile).
              expect(
                tout.intersect(r).size,
                r.size,
                reason: 'hors de la place : $r dans $zone',
              );
            }
            // Aucun chevauchement, 16 au moins entre deux voisins.
            for (int i = 0; i < rects.length; i++) {
              for (int j = i + 1; j < rects.length; j++) {
                expect(
                  rects[i].inflate(7.9).overlaps(rects[j]),
                  isFalse,
                  reason: '${rects[i]} et ${rects[j]}',
                );
              }
            }
            // Centree en largeur et en hauteur ; chaque rangee (la derniere
            // comprise) centree.
            final Map<double, List<Rect>> rangees = <double, List<Rect>>{};
            for (final Rect r in rects) {
              (rangees[r.top] ??= <Rect>[]).add(r);
            }
            for (final List<Rect> rangee in rangees.values) {
              final double gauche = rangee.first.left;
              final double droite = zone.width - rangee.last.right;
              expect((gauche - droite).abs(), lessThanOrEqualTo(1.01));
            }
            final double haut = rects.first.top;
            final double bas = zone.height - rects.last.bottom;
            expect((haut - bas).abs(), lessThanOrEqualTo(1.01));
          }
        });
      }
    }

    test('le plus grand cadre : deux personnes cote a cote sur ordinateur, '
        'l une sous l autre au telephone', () {
      final DispositionGrille large = calculerGrille(
        2,
        const Size(1288, 868),
        rapport: 4 / 3,
      );
      expect(large.colonnes, 2);
      expect(large.cadre.width, largeurMaxCadre);
      final DispositionGrille portrait = calculerGrille(
        2,
        const Size(358, 660),
        rapport: 1,
      );
      expect(portrait.colonnes, 1);
      expect(portrait.cadre, const Size(322, 322));
    });

    test('12 personnes dans une place courte : des pages entieres', () {
      final DispositionGrille d = calculerGrille(
        12,
        const Size(288, 320),
        rapport: 1,
      );
      expect(d.pages, greaterThan(1));
      expect(d.cadre.height, greaterThanOrEqualTo(coteMinCadre));
      expect(d.parPage * d.pages, greaterThanOrEqualTo(12));
    });

    test('en arabe, le premier cadre est a droite', () {
      final DispositionGrille d = calculerGrille(
        2,
        const Size(1000, 400),
        rapport: 4 / 3,
      );
      final List<Rect> rtl = rectsGrille(
        d,
        2,
        const Size(1000, 400),
        sens: TextDirection.rtl,
      );
      expect(rtl.first.left, greaterThan(rtl.last.left));
    });
  });

  group('GrilleVisages, le widget', () {
    Widget hote(List<int> ids, {bool reduit = false, Size? taille}) =>
        hoteCapture(
          Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: const Size(800, 600),
                disableAnimations: reduit,
              ),
              child: Center(
                child: SizedBox.fromSize(
                  size: taille ?? const Size(720, 480),
                  child: GrilleVisages(
                    rapport: 4 / 3,
                    cadres: <EntreeGrille>[
                      for (final int i in ids)
                        EntreeGrille(
                          cle: ValueKey<int>(i),
                          cadre: ColoredBox(
                            key: ValueKey<String>('cadre-$i'),
                            color: const Color(0xFF808080),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

    Finder cadre(int i) => find.byKey(ValueKey<String>('cadre-$i'));

    double opacite(WidgetTester tester, int i) => tester
        .widget<Opacity>(
          find.ancestor(of: cadre(i), matching: find.byType(Opacity)).first,
        )
        .opacity;

    testWidgets('un visage arrive : il grandit en fondu, les autres glissent '
        'sur le ressort (positions animees, pas un saut)', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(800, 600), 1);
      await tester.pumpWidget(hote(<int>[1, 2]));
      final Rect avant = tester.getRect(cadre(1));
      await tester.pumpWidget(hote(<int>[1, 2, 3]));
      await tester.pump(const Duration(milliseconds: 40));
      expect(opacite(tester, 3), lessThan(1));
      final Rect milieu = tester.getRect(cadre(1));
      await tester.pumpAndSettle();
      final Rect apres = tester.getRect(cadre(1));
      expect(apres, isNot(avant));
      // A mi-chemin : ni l'ancienne place ni la nouvelle.
      expect(milieu, isNot(apres));
      expect(milieu, isNot(avant));
      expect(opacite(tester, 3), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un visage part : il garde sa place le temps d une '
        'reconnexion, puis retrecit en fondu, et les autres se replacent', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(800, 600), 1);
      await tester.pumpWidget(hote(<int>[1, 2, 3]));
      final Rect avant = tester.getRect(cadre(1));
      await tester.pumpWidget(hote(<int>[1, 2]));
      await tester.pump(const Duration(seconds: 1));
      // Pendant l'attente : toujours la, attenue ; les autres n'ont pas bouge.
      expect(cadre(3), findsOneWidget);
      expect(opacite(tester, 3), lessThan(1));
      expect(tester.getRect(cadre(1)), avant);
      await tester.pumpAndSettle();
      expect(cadre(3), findsNothing);
      expect(tester.getRect(cadre(1)), isNot(avant));
    });

    testWidgets('revenu pendant l attente : rien ne bouge (reconnexion)', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(800, 600), 1);
      await tester.pumpWidget(hote(<int>[1, 2, 3]));
      final Rect un = tester.getRect(cadre(1));
      final Rect trois = tester.getRect(cadre(3));
      await tester.pumpWidget(hote(<int>[1, 2]));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(hote(<int>[1, 2, 3]));
      await tester.pump();
      expect(opacite(tester, 3), 1);
      expect(tester.getRect(cadre(1)), un);
      expect(tester.getRect(cadre(3)), trois);
      // Plus tard non plus : la grille ne danse pas.
      await tester.pumpAndSettle();
      expect(tester.getRect(cadre(1)), un);
      expect(cadre(3), findsOneWidget);
    });

    testWidgets('sa propre image (sans attente) part aussitot', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(800, 600), 1);
      Widget avec(bool moi) => hoteCapture(
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 720,
              height: 480,
              child: GrilleVisages(
                rapport: 4 / 3,
                cadres: <EntreeGrille>[
                  const EntreeGrille(
                    cle: ValueKey<int>(1),
                    cadre: SizedBox.expand(key: ValueKey<String>('cadre-1')),
                  ),
                  if (moi)
                    const EntreeGrille(
                      cle: ValueKey<int>(9),
                      attendreAuDepart: false,
                      cadre: SizedBox.expand(key: ValueKey<String>('cadre-9')),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(avec(true));
      await tester.pumpWidget(avec(false));
      await tester.pump(AppMouvement.fonduSortie);
      await tester.pump(AppMouvement.fonduSortie);
      await tester.pump();
      expect(cadre(9), findsNothing);
    });

    testWidgets('mouvement reduit : fondu seul, les cadres sautent a leur '
        'place', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(800, 600), 1);
      await tester.pumpWidget(hote(<int>[1, 2], reduit: true));
      await tester.pumpWidget(hote(<int>[1, 2, 3], reduit: true));
      await tester.pump(const Duration(milliseconds: 40));
      // Le fondu reste (l'information arrive), sans grossissement.
      expect(opacite(tester, 3), lessThan(1));
      final Transform echelle = tester.widget<Transform>(
        find.ancestor(of: cadre(3), matching: find.byType(Transform)).first,
      );
      expect(echelle.transform.getMaxScaleOnAxis(), 1);
      final Rect place = tester.getRect(cadre(1));
      await tester.pumpAndSettle();
      expect(tester.getRect(cadre(1)), place);
    });

    testWidgets('la fenetre change de taille : la grille suit, sans '
        'animation', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(800, 600), 1);
      await tester.pumpWidget(hote(<int>[1, 2, 3]));
      await tester.pumpWidget(
        hote(<int>[1, 2, 3], taille: const Size(600, 480)),
      );
      final Rect tout = tester.getRect(cadre(1));
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.getRect(cadre(1)), tout);
    });

    testWidgets('12 personnes dans une place courte : des pages, la barre '
        'precedent / suivant, jamais des cadres minuscules', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(800, 600), 1);
      await tester.pumpWidget(
        hote(
          <int>[for (int i = 1; i <= 12; i++) i],
          taille: const Size(320, 320),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(GrilleVisages.clePages), findsOneWidget);
      expect(find.byType(BarrePrecedentSuivant), findsOneWidget);
      expect(
        tester.getSize(cadre(1)).height,
        greaterThanOrEqualTo(coteMinCadre),
      );
      expect(cadre(12), findsNothing);
      await tester.tap(find.bySemanticsLabel(t.salle.scene.suivants));
      await tester.pumpAndSettle();
      expect(cadre(1), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
