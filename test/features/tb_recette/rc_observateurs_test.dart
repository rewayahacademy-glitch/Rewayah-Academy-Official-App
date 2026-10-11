// TB-RC, lot L5-observateurs : les observateurs (tuteur, controleur) dans la
// vraie salle `/salle`, presentation lue, mesures AU RENDU, polices du depot.
//
// - TB_RAPPORT §d n° 6 : a texte x2, le rappel du role garde ses DEUX
//   phrases a l'ecran (« Vous n'etes pas entendu. », « ni vu ni entendu...
//   inscrit au journal »), chacune entiere, sans mot coupe ; le lecteur
//   d'ecran lit la phrase entiere une fois.
// - n° 5 et 11 : au telephone et sur tablette en portrait, a texte x1 et x2,
//   la ligne de flottaison ne tranche aucune tuile (chaque tuile est entiere
//   dans la colonne ou entierement dessous), la galerie ne defile pas a
//   l'interieur, et la colonne defilee jusqu'au bout montre chaque tuile
//   entiere avec son nom entier.
// - n° 18 : la page lue se dit dans la ligne du titre (« titre, page 3 sur
//   12 »), sans pastille au style de bouton (aucune `IndicateurPage`, aucune
//   boite peinte sous la ligne).
// - n° 23 : sur tablette en paysage (1100 x 700, 1024 x 768), la page lue
//   n'est plus une vignette : la scene est a cote d'elle, la page fait au
//   moins 200 points de large.
// - Revue TB-R m12 : le titre et la page sont lus une seule fois.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/page_immersive.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/salle_observateur_demo.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/barre_support.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart'
    show SupportPageFixe;
import 'package:rewayah_academy/features/salle_seance/zone_support.dart';

import '../../capture/outil_capture.dart' hide stabiliser;
import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart';

const Key _presentation = ValueKey<String>('presentation-lue');
const Key _ligneTitre = ValueKey<String>('presentation-lue-titre');

Future<void> _monter(
  WidgetTester tester,
  ObservateurDemo o,
  SituationTb s, {
  required Size taille,
  double texte = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(observateur: o, situation: s),
      echelleTexte: texte,
    ),
  );
  await stabiliser(tester);
}

/// Les tuiles de la galerie (enseignant et eleves de la demonstration).
final Finder _tuiles = find.byWidgetPredicate((Widget w) {
  final Key? k = w.key;
  return k is ValueKey<String> &&
      (k.value == 'demo-enseignant' || k.value.startsWith('demo-eleve-'));
});

/// Le titre (premiere phrase) et la suite du rappel de [o].
(String, String, String) _rappel(ObservateurDemo o) {
  final String texte = o == ObservateurDemo.controleur
      ? t.salle.bandeauControle
      : t.salle.observationMuette;
  final String titre = o == ObservateurDemo.controleur
      ? t.salle.bandeauControleTitre
      : t.salle.observationMuetteTitre;
  return (texte, titre, texte.substring(titre.length).trimLeft());
}

/// Les libelles lus du noeud semantique racine, a plat.
List<String> _lus(WidgetTester tester) {
  final List<String> lus = <String>[];
  void visite(SemanticsNode n) {
    if (n.label.isNotEmpty) lus.add(n.label);
    n.visitChildren((SemanticsNode e) {
      visite(e);
      return true;
    });
  }

  visite(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return lus;
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('n° 6 : les deux phrases du rappel se lisent a texte x2', () {
    for (final ObservateurDemo o in ObservateurDemo.values) {
      for (final Size taille in const <Size>[
        Size(320, 700),
        Size(390, 844),
        Size(768, 1024),
        Size(1440, 900),
      ]) {
        testWidgets('${o.name}, ${taille.width.toInt()}, x2', (
          WidgetTester tester,
        ) async {
          final SemanticsHandle h = tester.ensureSemantics();
          await _monter(tester, o, SituationTb.ped03, taille: taille, texte: 2);
          expect(tester.takeException(), isNull);
          final (String texte, String titre, String suite) = _rappel(o);
          for (final String phrase in <String>[titre, suite]) {
            final Finder ecrit = find.text(phrase);
            expect(ecrit, findsOneWidget, reason: phrase);
            final Rect r = tester.getRect(ecrit);
            expect(r.width, greaterThan(0), reason: phrase);
            expect(r.left, greaterThanOrEqualTo(-0.5), reason: '$r');
            expect(r.right, lessThanOrEqualTo(taille.width + 0.5));
            expect(r.top, greaterThanOrEqualTo(-0.5), reason: '$r');
            expect(r.bottom, lessThanOrEqualTo(taille.height + 0.5));
            verifierAucunMotCoupe(tester, ecrit);
          }
          // La suite sous le titre, chacune sur sa ligne.
          expect(
            tester.getRect(find.text(suite)).top,
            greaterThanOrEqualTo(tester.getRect(find.text(titre)).bottom - 0.5),
          );
          // Lue une fois, entiere.
          expect(
            _lus(tester).where((String l) => l.contains(titre)).toList(),
            <String>[texte],
          );
          h.dispose();
        });
      }
    }
  });

  group('n° 5 et 11 : aucune tuile tranchee a la ligne de flottaison', () {
    for (final ObservateurDemo o in ObservateurDemo.values) {
      for (final SituationTb s in <SituationTb>[
        SituationTb.ped01,
        SituationTb.ped03,
      ]) {
        for (final Size taille in const <Size>[
          Size(320, 700),
          Size(390, 844),
          Size(768, 1024),
        ]) {
          for (final double texte in <double>[1, 2]) {
            testWidgets('${o.name} ${s.name}, ${taille.width.toInt()}x'
                '${taille.height.toInt()}, x$texte', (
              WidgetTester tester,
            ) async {
              await _monter(tester, o, s, taille: taille, texte: texte);
              expect(tester.takeException(), isNull);
              final Finder colonne = find
                  .ancestor(
                    of: find.byKey(_presentation),
                    matching: find.byType(Scrollable),
                  )
                  .first;
              final Rect vue = tester.getRect(colonne);
              // Le contenu sous la zone haute et au-dessus du rappel.
              expect(
                vue.bottom,
                lessThanOrEqualTo(
                  tester.getRect(find.byKey(PageImmersive.contenuKey)).bottom +
                      0.5,
                ),
              );
              expect(_tuiles, findsNWidgets(4));
              // La galerie ne defile pas a l'interieur : un seul defilement,
              // celui de la colonne.
              final ScrollableState galerie = tester.state<ScrollableState>(
                find.descendant(
                  of: find.byType(GridView),
                  matching: find.byType(Scrollable),
                ),
              );
              expect(galerie.position.maxScrollExtent, 0);
              // Au repos : chaque tuile entiere dans la colonne, ou
              // entierement sous elle. Jamais a cheval.
              for (final Element e in _tuiles.evaluate()) {
                final Rect r = tester.getRect(find.byWidget(e.widget));
                final bool dedans = r.bottom <= vue.bottom + 0.5;
                final bool dessous = r.top >= vue.bottom - 0.5;
                expect(
                  dedans || dessous,
                  isTrue,
                  reason: 'tuile $r tranchee par le bas de la colonne $vue',
                );
              }
              // La colonne defilee jusqu'au bout : chaque tuile entiere,
              // son nom entier dans la tuile.
              final ScrollPosition position = tester
                  .state<ScrollableState>(colonne)
                  .position;
              position.jumpTo(position.maxScrollExtent);
              await tester.pump();
              for (final Element e in _tuiles.evaluate()) {
                final Finder tuile = find.byWidget(e.widget);
                final Rect r = tester.getRect(tuile);
                expect(r.top, greaterThanOrEqualTo(vue.top - 0.5));
                expect(r.bottom, lessThanOrEqualTo(vue.bottom + 0.5));
                final Finder textes = find.descendant(
                  of: tuile,
                  matching: find.byType(RichText),
                );
                expect(textes, findsWidgets);
                for (final Element x in textes.evaluate()) {
                  final Rect rx = tester.getRect(find.byWidget(x.widget));
                  expect(rx.top, greaterThanOrEqualTo(r.top - 0.5));
                  expect(rx.bottom, lessThanOrEqualTo(r.bottom + 0.5));
                }
                verifierAucunMotCoupe(tester, tuile);
              }
            });
          }
        }
      }
    }
  });

  group('n° 18 et m12 : la page dite dans la ligne du titre, lue une fois', () {
    for (final ObservateurDemo o in ObservateurDemo.values) {
      for (final (Size taille, double texte) in const <(Size, double)>[
        (Size(390, 844), 1),
        (Size(320, 700), 2),
        (Size(1440, 900), 1),
      ]) {
        testWidgets('${o.name}, ${taille.width.toInt()}, x$texte', (
          WidgetTester tester,
        ) async {
          final SemanticsHandle h = tester.ensureSemantics();
          await _monter(
            tester,
            o,
            SituationTb.ped03,
            taille: taille,
            texte: texte,
          );
          expect(tester.takeException(), isNull);
          final SupportPageFixe page = DonneesSeanceDemo.supportPageFixe;
          final String attendu = t.salle.seance.surface.page(
            titre: page.titre,
            page: 3,
            pages: page.total,
          );
          expect(find.byType(IndicateurPage), findsNothing);
          final Finder ligne = find.byKey(_ligneTitre);
          expect(tester.widget<Text>(ligne).data, attendu);
          // Aucune boite peinte entre la ligne et la presentation : du
          // texte sur le fond de la salle, pas une pastille.
          expect(
            find.descendant(
              of: find.byKey(_presentation),
              matching: find.ancestor(
                of: ligne,
                matching: find.byType(DecoratedBox),
              ),
            ),
            findsNothing,
          );
          final Rect r = tester.getRect(ligne);
          expect(r.left, greaterThanOrEqualTo(-0.5));
          expect(r.right, lessThanOrEqualTo(taille.width + 0.5));
          verifierAucunMotCoupe(tester, ligne);
          // Lu une fois : par la surface, qui dit titre et page.
          expect(
            _lus(tester).where((String l) => l.contains(page.titre)).toList(),
            <String>[attendu],
          );
          h.dispose();
        });
      }
    }
  });

  group('n° 23 : tablette en paysage, la page a cote de la scene', () {
    for (final ObservateurDemo o in ObservateurDemo.values) {
      for (final Size taille in const <Size>[
        Size(1100, 700),
        Size(1024, 768),
      ]) {
        for (final double texte in <double>[1, 2]) {
          testWidgets('${o.name}, ${taille.width.toInt()}x'
              '${taille.height.toInt()}, x$texte', (WidgetTester tester) async {
            await _monter(
              tester,
              o,
              SituationTb.ped03,
              taille: taille,
              texte: texte,
            );
            expect(tester.takeException(), isNull);
            final Rect pageLue = tester.getRect(
              find.byKey(SurfacePageFixe.clePage),
            );
            expect(
              pageLue.width,
              greaterThanOrEqualTo(200),
              reason: 'page $pageLue',
            );
            final Rect zone = tester.getRect(find.byType(ZoneSupport));
            for (final Element e in _tuiles.evaluate()) {
              final Rect r = tester.getRect(find.byWidget(e.widget));
              expect(
                r.left,
                greaterThanOrEqualTo(zone.right - 0.5),
                reason: 'tuile $r a cote de la page $zone',
              );
            }
          });
        }
      }
    }
  });
}
