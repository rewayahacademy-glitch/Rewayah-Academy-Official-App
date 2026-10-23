// ZOOM-LIB-1 (releve par la verification de DOCK-X2-1, 09/10/2026).
//
// (n1) La barre du support de l'eleve, sur ordinateur : le libelle « Zoom
// local, sans effet sur les autres » partait en ellipse (« Zoom loc… ») et
// disparaissait a 1200 x2 : le calcul du repli d'Agrandir ne comptait pas sa
// largeur. Il est mesure ; quand la place manque, il passe sur sa propre
// ligne (deux lignes s'il le faut, coupees entre les mots), jamais d'ellipse.
// (n2) La rangee du zoom passe par verifierAucunMotCoupe.
// (n5) A 200 px de large, texte x2, la rangee debordait (exception) : elle
// se replie maintenant sans exception.
// (n4) En droite a gauche, les phrases francaises du support de
// demonstration gardaient le sens de l'arbre : leur point final passait en
// tete (« .Ecouter avec calme »). Elles gardent le sens de leur langue.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/barre_support.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';

final Finder _zoom = find.byKey(const ValueKey<String>('zoom-local'));
final Finder _libelle = find.byKey(
  const ValueKey<String>('zoom-local-libelle'),
);
final Finder _agrandir = find.byKey(
  const ValueKey<String>('bouton-agrandir-barre'),
);

Future<void> _monterSalle(
  WidgetTester tester, {
  required Size taille,
  required double echelle,
  TextDirection sens = TextDirection.ltr,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      Directionality(
        textDirection: sens,
        child: const DemoSallePage(
          role: RoleSeance.eleve,
          etat: EtatDemoSalle.repos,
        ),
      ),
      echelleTexte: echelle,
    ),
  );
  await stabiliser(tester);
}

/// Le libelle entier est dans l'ecran et dans la rangee du zoom.
void _libelleEntierVisible(WidgetTester tester, Size ecran) {
  expect(_libelle, findsOneWidget);
  expect(tester.widget<Text>(_libelle).data, t.salle.seance.zoomLocal);
  final RenderParagraph p = tester.renderObject<RenderParagraph>(
    find.descendant(of: _libelle, matching: find.byType(RichText)),
  );
  expect(p.didExceedMaxLines, isFalse);
  final Rect r = tester.getRect(_libelle);
  expect(r.width, greaterThan(0));
  expect(r.left, greaterThanOrEqualTo(-0.5));
  expect(r.right, lessThanOrEqualTo(ecran.width + 0.5));
  expect(r.bottom, lessThanOrEqualTo(ecran.height + 0.5));
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('ZOOM-LIB-1 : ZoomLocal seul, de large a etroit', () {
    for (final double largeur in <double>[640, 460, 330, 260, 200]) {
      for (final double echelle in <double>[1, 1.3, 1.5, 2]) {
        for (final TextDirection sens in TextDirection.values) {
          testWidgets('${largeur.toInt()} px, texte x$echelle, ${sens.name}', (
            WidgetTester tester,
          ) async {
            int appuis = 0;
            const Size ecran = Size(1440, 900);
            fixerVueCapture(tester, ecran, 1);
            await tester.pumpWidget(
              hoteCapture(
                Directionality(
                  textDirection: sens,
                  child: Scaffold(
                    body: Align(
                      alignment: AlignmentDirectional.bottomEnd,
                      child: SizedBox(
                        width: largeur,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: ZoomLocal(
                            zoom: 1,
                            onMoins: () {},
                            onPlus: () {},
                            onAgrandir: () => appuis++,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                echelleTexte: echelle,
              ),
            );
            await tester.pump();
            // n5 : aucune exception de mise en page, 200 px x2 compris.
            expect(tester.takeException(), isNull);
            // n2 : aucun mot coupe ni tronque dans la rangee du zoom.
            verifierAucunMotCoupe(tester, _zoom);
            _libelleEntierVisible(tester, ecran);
            // La rangee reste dans sa place.
            final Rect zone = tester.getRect(_zoom);
            expect(zone.width, lessThanOrEqualTo(largeur + 0.5));
            await tester.tap(_agrandir);
            expect(appuis, 1);
          });
        }
      }
    }

    testWidgets('assez de place : une seule rangee (rendu inchange)', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await tester.pumpWidget(
        hoteCapture(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 640,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ZoomLocal(
                    zoom: 1,
                    onMoins: () {},
                    onPlus: () {},
                    onAgrandir: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.widget(_zoom), isA<Row>());
      // Libelle et Agrandir sur la meme ligne.
      expect(
        tester.getCenter(_libelle).dy,
        moreOrLessEquals(tester.getCenter(_agrandir).dy, epsilon: 0.5),
      );
    });
  });

  group('ZOOM-LIB-1 : barre du support dans la salle', () {
    for (final (String l, Size taille) in <(String, Size)>[
      ('1200', const Size(1200, 800)),
      ('1280', const Size(1280, 800)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final double echelle in <double>[1, 1.3, 1.5, 2]) {
        testWidgets('$l px, texte x$echelle : libelle entier', (
          WidgetTester tester,
        ) async {
          await _monterSalle(tester, taille: taille, echelle: echelle);
          expect(tester.takeException(), isNull);
          expect(_zoom, findsOneWidget);
          verifierAucunMotCoupe(tester, _zoom);
          _libelleEntierVisible(tester, taille);
        });
      }
    }
  });

  group('ZOOM-LIB-1 : phrases francaises du support en droite a gauche', () {
    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      testWidgets('${taille.width.toInt()} px : point final a la fin', (
        WidgetTester tester,
      ) async {
        await _monterSalle(
          tester,
          taille: taille,
          echelle: 1,
          sens: TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
        for (final String phrase in <String>[
          'Écouter avec calme.',
          'Poser des questions poliment.',
          'Respecter les camarades.',
        ]) {
          final Finder texte = find.text(phrase);
          expect(texte, findsOneWidget);
          final RenderParagraph p = tester.renderObject<RenderParagraph>(
            find.descendant(of: texte, matching: find.byType(RichText)),
          );
          expect(p.textDirection, TextDirection.ltr, reason: phrase);
          // Calee au debut de l'interface (a droite), pres de sa pastille.
          expect(p.textAlign, TextAlign.right, reason: phrase);
        }
      });
    }

    testWidgets('gauche a droite : rendu inchange (cale a gauche)', (
      WidgetTester tester,
    ) async {
      await _monterSalle(tester, taille: const Size(390, 844), echelle: 1);
      final RenderParagraph p = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.text('Écouter avec calme.'),
          matching: find.byType(RichText),
        ),
      );
      expect(p.textDirection, TextDirection.ltr);
      expect(p.textAlign, TextAlign.left);
    });
  });

  // Captures K-61 (seulement avec CAPTURE_DIR) : la salle de l'eleve, barre
  // du support, a 320, 390 et 1200, texte x1 et x2 ; et 390 en droite a
  // gauche (n4).
  group('ZOOM-LIB-1 : captures', skip: sautSansCapture, () {
    for (final (String l, Size taille) in <(String, Size)>[
      ('320', const Size(320, 568)),
      ('390', const Size(390, 844)),
      ('1200', const Size(1200, 800)),
    ]) {
      for (final double echelle in <double>[1, 2]) {
        final String nom = 'salle_barre_support_${l}_x$echelle';
        testWidgets(nom, (WidgetTester tester) async {
          await _monterSalle(tester, taille: taille, echelle: echelle);
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
    testWidgets('salle_support_390_rtl', (WidgetTester tester) async {
      await _monterSalle(
        tester,
        taille: const Size(390, 844),
        echelle: 1,
        sens: TextDirection.rtl,
      );
      debugPrint('PNG ${await capturer(tester, 'salle_support_390_rtl')}');
    });
  });
}
