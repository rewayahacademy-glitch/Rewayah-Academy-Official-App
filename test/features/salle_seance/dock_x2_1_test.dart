// DOCK-X2-1, remplace dans la salle par le standard des commandes d'appel
// (directeur, 24/10/2026, SALLE-PLAN-2026-10-24.md). Ancienne regle : « le mot
// d'etat des bascules reste entier, quitte a passer sur deux rangees ».
// Nouvelle regle : la pilule d'appel ne porte AUCUN mot, a aucune echelle de
// texte ; les boutons ronds gardent leur taille (56 telephone, 48 bureau) ;
// l'etat vit dans l'infobulle et la semantique ; la pilule peut passer sur
// deux rangees.
//
// Ici : a 1440 et 1024 px, texte x1,5 et x2, pour les trois roles, clair et
// sombre : aucun texte dans le dock, boutons de meme taille qu'a x1, dock
// dans l'ecran, rien ne deborde. A 1440, l'infobulle de chaque bascule dit
// son etat.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/sens_texte.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';

final Finder _dock = find.byKey(const ValueKey<String>('dock-seance'));
final Finder _agrandirBarre = find.byKey(
  const ValueKey<String>('bouton-agrandir-barre'),
);

Future<void> _monter(
  WidgetTester tester, {
  required Size taille,
  required double echelle,
  RoleSeance role = RoleSeance.eleve,
  ThemeMode mode = ThemeMode.light,
  double densite = 1,
}) async {
  fixerVueCapture(tester, taille, densite);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(role: role, etat: EtatDemoSalle.repos),
      echelleTexte: echelle,
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
}

/// Les textes affiches dans le dock : il n'y en a aucun (standard).
List<String> _motsDock(WidgetTester tester) => tester
    .widgetList<Text>(find.descendant(of: _dock, matching: find.byType(Text)))
    .map((Text t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .toList();

/// La hauteur des boutons ronds du dock.
List<double> _hauteurs(WidgetTester tester) => <double>[
  for (final Element e
      in find
          .descendant(
            of: _dock,
            matching: find.byKey(const ValueKey<String>('disque-appel')),
          )
          .evaluate())
    e.size!.height,
];

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('DOCK-X2-1 : standard des commandes d appel, texte agrandi', () {
    for (final (String l, Size taille) in <(String, Size)>[
      ('1440', const Size(1440, 900)),
      ('1024', const Size(1024, 768)),
    ]) {
      for (final double echelle in <double>[1.5, 2]) {
        for (final RoleSeance role in <RoleSeance>[
          RoleSeance.eleve,
          RoleSeance.enseignant,
          RoleSeance.guidee,
        ]) {
          for (final ThemeMode mode in <ThemeMode>[
            ThemeMode.light,
            ThemeMode.dark,
          ]) {
            testWidgets(
              'standard des commandes d appel : $l px, texte x$echelle, '
              '${role.name}, ${mode.name}',
              (WidgetTester tester) async {
                await _monter(
                  tester,
                  taille: taille,
                  echelle: echelle,
                  role: role,
                  mode: mode,
                );
                expect(tester.takeException(), isNull);
                expect(_dock, findsOneWidget);
                // Aucun mot dans la pilule, a aucune echelle.
                expect(_motsDock(tester), isEmpty);
                if (_agrandirBarre.evaluate().isNotEmpty) {
                  verifierAucunMotCoupe(tester, _agrandirBarre);
                }
                // ZOOM-LIB-1 (n2) : toute la rangee du zoom, libelle compris.
                final Finder zoom = find.byKey(
                  const ValueKey<String>('zoom-local'),
                );
                if (zoom.evaluate().isNotEmpty) {
                  verifierAucunMotCoupe(tester, zoom);
                }
                // Les boutons gardent leur taille (48 au bureau ; 72 en
                // interface guidee, cible du mode).
                final double cote = role == RoleSeance.guidee ? 72 : 48;
                final List<double> hauteurs = _hauteurs(tester);
                expect(hauteurs, isNotEmpty);
                for (final double h in hauteurs) {
                  expect(h, moreOrLessEquals(cote, epsilon: 0.5));
                }
                // L'etat de chaque bascule est dit par l'infobulle.
                if (l == '1440') {
                  expect(
                    find.descendant(
                      of: _dock,
                      matching: find.byWidgetPredicate(
                        (Widget w) =>
                            w is Tooltip &&
                            (w.message == t.salle.microOuvert ||
                                w.message == t.salle.microCoupe),
                      ),
                    ),
                    findsOneWidget,
                  );
                }
                // Le dock reste dans l'ecran.
                final Rect r = tester.getRect(_dock);
                expect(r.left, greaterThanOrEqualTo(-0.5));
                expect(r.right, lessThanOrEqualTo(taille.width + 0.5));
              },
            );
          }
        }
      }
    }
  });

  group('DOCK-X2-1 : standard des commandes d appel, jusqu a 130 %', () {
    for (final double echelle in <double>[1, 1.3]) {
      testWidgets('standard des commandes d appel : 1440 px, texte x$echelle : '
          'icones seules de 48', (WidgetTester tester) async {
        await _monter(tester, taille: const Size(1440, 900), echelle: echelle);
        expect(_motsDock(tester), isEmpty);
        for (final double h in _hauteurs(tester)) {
          expect(h, moreOrLessEquals(48, epsilon: 0.5));
        }
      });
    }
  });

  // Complement de la fiche : en droite a gauche, la mention francaise
  // gardait le sens de l'arbre et son point final passait en tete
  // (« .controle possible »). Elle prend le sens de sa langue.
  group('DOCK-X2-1 : mention francaise en droite a gauche', () {
    test('sensDuTexte : premier caractere fort', () {
      expect(sensDuTexte(t.salle.bandeauPermanent), TextDirection.ltr);
      expect(sensDuTexte('« Écoute »'), TextDirection.ltr);
      expect(sensDuTexte('درس مسجل.'), TextDirection.rtl);
      expect(sensDuTexte('12 : ...'), TextDirection.ltr);
      expect(
        sensDuTexte('...', parDefaut: TextDirection.rtl),
        TextDirection.rtl,
      );
    });

    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      testWidgets(
        '${taille.width.toInt()} px, sens rtl : point final a la fin',
        (WidgetTester tester) async {
          fixerVueCapture(tester, taille, 1);
          await tester.pumpWidget(
            hoteCapture(
              const Directionality(
                textDirection: TextDirection.rtl,
                child: DemoSallePage(
                  role: RoleSeance.eleve,
                  etat: EtatDemoSalle.repos,
                ),
              ),
            ),
          );
          await stabiliser(tester);
          final Finder mention = find.text(t.salle.bandeauPermanent);
          expect(mention, findsOneWidget);
          final RenderParagraph p = tester.renderObject<RenderParagraph>(
            find.descendant(of: mention, matching: find.byType(RichText)),
          );
          expect(p.textDirection, TextDirection.ltr);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  // Captures K-61 (seulement avec CAPTURE_DIR) : la salle de demonstration
  // de l'eleve et de l'enseignant, a 1440 et 1024, texte x1,5 et x2.
  group('DOCK-X2-1 : captures', skip: sautSansCapture, () {
    for (final (String l, Size taille) in <(String, Size)>[
      ('1440', const Size(1440, 900)),
      ('1024', const Size(1024, 768)),
    ]) {
      for (final double echelle in <double>[1, 1.3, 1.5, 2]) {
        for (final RoleSeance role in <RoleSeance>[
          RoleSeance.eleve,
          RoleSeance.enseignant,
        ]) {
          final String nom = 'demo_salle_${role.name}_${l}_x$echelle';
          testWidgets(nom, (WidgetTester tester) async {
            await _monter(tester, taille: taille, echelle: echelle, role: role);
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
    testWidgets('demo_salle_eleve_390_rtl', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 2);
      await tester.pumpWidget(
        hoteCapture(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: DemoSallePage(
              role: RoleSeance.eleve,
              etat: EtatDemoSalle.repos,
            ),
          ),
        ),
      );
      await stabiliser(tester);
      debugPrint('PNG ${await capturer(tester, 'demo_salle_eleve_390_rtl')}');
    });
  });
}
