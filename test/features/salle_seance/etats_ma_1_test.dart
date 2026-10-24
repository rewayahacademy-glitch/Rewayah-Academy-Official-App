// ETATS-MA-1 (decision du 05/10/2026, par delegation du directeur ; regle du
// 02/10, DECISIONS_DELEGUEES_2026-10-02.md : « le mot d'etat reste »,
// WCAG 1.4.1). Salle en Mode Accessibilite, texte au-dela de 130 % : les
// commandes passent sur deux rangees (micro et camera, puis quitter ;
// Agrandir a quitte la barre de l'appel avec TB-2) et les bascules gardent leur mot d'etat sous le disque.
//
// - A 320 et 390 px, texte x1,5 et x2, clair et sombre, LTR et RTL : le mot
//   de chaque bascule est a l'ecran, entier (aucun mot coupe ni tronque),
//   rien ne deborde, Quitter reste a l'ecran.
// - Jusqu'a 130 % en Mode Accessibilite, et hors Mode Accessibilite a toute
//   taille : rien ne change (une seule rangee).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';

const Key _grille = ValueKey<String>('commandes-deux-rangees');
const Key _mot = ValueKey<String>('mot-commande');
final Finder _dock = find.byKey(const ValueKey<String>('dock-seance'));

/// Les mots d'etat possibles des bascules de l'eleve.
final Set<String> _motsMicro = <String>{
  t.salle.microOuvert,
  t.salle.microCoupe,
};
final Set<String> _motsCamera = <String>{
  t.salle.cameraAllumee,
  t.salle.cameraCoupee,
};

Future<void> _monter(
  WidgetTester tester, {
  required Size taille,
  double echelle = 2,
  ThemeMode mode = ThemeMode.light,
  bool rtl = false,
  InterfaceMode interface = InterfaceMode.enfant,
  EleveDemoAccessibilite eleve = EleveDemoAccessibilite.idriss,
}) async {
  fixerVueCapture(tester, taille, 1);
  Widget ecran = EcranAccessibiliteDemo(
    eleve: eleve,
    moment: MomentDemoAccessibilite.fenetre,
    etapeInitiale: EtapeDemoAccessibilite.salle,
  );
  if (rtl) {
    ecran = Directionality(textDirection: TextDirection.rtl, child: ecran);
  }
  await tester.pumpWidget(
    hoteCapture(
      ecran,
      themeMode: mode,
      echelleTexte: echelle,
      interfaceMode: interface,
    ),
  );
  await stabiliser(tester);
}

/// Le bouton du dock dont le mot visible est l'un de [mots].
Finder _bouton(Set<String> mots) => find.descendant(
  of: _dock,
  matching: find.byWidgetPredicate(
    (Widget w) => w is BoutonAppel && mots.contains(w.libelle),
  ),
);

/// Les mots affiches sous les disques du dock.
List<String> _motsAffiches(WidgetTester tester) => tester
    .widgetList<Text>(find.descendant(of: _dock, matching: find.byKey(_mot)))
    .map((Text t) => t.data!)
    .toList();

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('ETATS-MA-1 : le mot d etat reste, texte au-dela de 130 %', () {
    for (final (String l, Size taille) in <(String, Size)>[
      ('320', const Size(320, 568)),
      ('390', const Size(390, 844)),
    ]) {
      for (final double echelle in <double>[1.5, 2]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          for (final bool rtl in <bool>[false, true]) {
            final String sens = rtl ? 'rtl' : 'ltr';
            testWidgets('$l px, texte x$echelle, ${mode.name}, $sens', (
              WidgetTester tester,
            ) async {
              await _monter(
                tester,
                taille: taille,
                echelle: echelle,
                mode: mode,
                rtl: rtl,
              );
              expect(tester.takeException(), isNull);

              // Le mot d'etat de chaque bascule est a l'ecran.
              final List<String> mots = _motsAffiches(tester);
              expect(
                mots.where(_motsMicro.contains),
                hasLength(1),
                reason: 'mot du micro absent : $mots',
              );
              expect(
                mots.where(_motsCamera.contains),
                hasLength(1),
                reason: 'mot de la camera absent : $mots',
              );
              // TB-2 (ui/supports-tableau-v1, repris par JONCTION-LIGNES-1) :
              // Agrandir a quitte la barre de l'appel (il n'y revient, en
              // « Reduire », que pendant le focus local) ; Quitter garde
              // son mot.
              expect(mots, isNot(contains(t.salle.seance.agrandir)));
              expect(mots, contains(t.salle.quitter));

              // Entier : aucun mot coupe ni tronque dans le dock.
              verifierAucunMotCoupe(tester, _dock);

              // Deux rangees : micro et camera sur la premiere, le reste
              // dessous.
              expect(find.byKey(_grille), findsOneWidget);
              final Rect micro = tester.getRect(_bouton(_motsMicro));
              final Rect camera = tester.getRect(_bouton(_motsCamera));
              final Finder quitter = find.descendant(
                of: _dock,
                matching: find.byWidgetPredicate(
                  (Widget w) =>
                      w is BoutonAppel && w.libelle == t.salle.quitter,
                ),
              );
              final Rect sortie = tester.getRect(quitter);
              expect(micro.top, moreOrLessEquals(camera.top, epsilon: 0.5));
              expect(sortie.top, greaterThan(micro.bottom));
              // L'ordre suit le sens de lecture.
              expect(
                rtl ? micro.left > camera.left : micro.left < camera.left,
                isTrue,
              );

              // Rien ne deborde : le dock et chaque commande dans l'ecran.
              final Rect dock = tester.getRect(_dock);
              for (final Rect r in <Rect>[dock, micro, camera, sortie]) {
                expect(r.left, greaterThanOrEqualTo(-0.5));
                expect(r.right, lessThanOrEqualTo(taille.width + 0.5));
                expect(r.bottom, lessThanOrEqualTo(taille.height + 0.5));
              }
            });
          }
        }
      }
    }

    // Bureau : la rangee unique reste ; le mot d'etat y passe sur deux
    // lignes dans une case de deux cibles, sans se couper.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('1440 px, texte x2, ${mode.name} : mot entier', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille: const Size(1440, 900), mode: mode);
        expect(tester.takeException(), isNull);
        final List<String> mots = _motsAffiches(tester);
        expect(mots.where(_motsMicro.contains), hasLength(1));
        expect(mots.where(_motsCamera.contains), hasLength(1));
        verifierAucunMotCoupe(tester, _dock);
      });
    }

    testWidgets('Mariam (mineure), 320 px, texte x2 : meme regle', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(320, 568),
        eleve: EleveDemoAccessibilite.mariam,
      );
      expect(tester.takeException(), isNull);
      expect(_motsAffiches(tester).where(_motsMicro.contains), hasLength(1));
      verifierAucunMotCoupe(tester, _dock);
    });
  });

  group('ETATS-MA-1 : rien ne change ailleurs', () {
    testWidgets('Mode Accessibilite, texte a 130 % : une seule rangee', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(390, 844), echelle: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.byKey(_grille), findsNothing);
      final Rect micro = tester.getRect(_bouton(_motsMicro));
      final Rect camera = tester.getRect(_bouton(_motsCamera));
      // Meme rangee : centres a la meme hauteur (depuis TB-2, Quitter garde
      // sa largeur et un mot peut passer sur deux lignes dans sa part).
      expect(micro.center.dy, moreOrLessEquals(camera.center.dy, epsilon: 0.5));
      // Jusqu'a 130 %, le mot se montrait deja : il reste.
      expect(_motsAffiches(tester).where(_motsMicro.contains), hasLength(1));
    });

    for (final double echelle in <double>[1, 2]) {
      testWidgets(
        'hors Mode Accessibilite (eleve), texte x$echelle : inchange',
        (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(390, 844), 1);
          await tester.pumpWidget(
            hoteCapture(
              const DemoSallePage(
                role: RoleSeance.eleve,
                etat: EtatDemoSalle.repos,
              ),
              echelleTexte: echelle,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          expect(find.byKey(_grille), findsNothing);
          // Le comportement d'avant : une seule rangee ; au-dela de 130 %,
          // les bascules en icone seule (EN-12), a x1 leur mot affiche.
          final Rect micro = tester.getRect(_bouton(_motsMicro));
          final Rect quitter = tester.getRect(
            find.descendant(
              of: _dock,
              matching: find.byWidgetPredicate(
                (Widget w) => w is BoutonAppel && w.libelle == t.salle.quitter,
              ),
            ),
          );
          expect(micro.top, moreOrLessEquals(quitter.top, epsilon: 0.5));
          expect(
            _motsAffiches(tester).where(_motsMicro.contains),
            hasLength(echelle > 1.3 ? 0 : 1),
          );
        },
      );
    }
  });

  // Captures K-61 (seulement avec CAPTURE_DIR) : la salle MA d'Idriss, a
  // 390 et 320 px texte x2, a 1440, clair et sombre, et en RTL.
  group('ETATS-MA-1 : captures', skip: sautSansCapture, () {
    const List<(String, Size, double, double)> cas =
        <(String, Size, double, double)>[
          ('390_x2', Size(390, 844), 2, 2),
          ('320_x2', Size(320, 568), 2, 2),
          ('1440_x2', Size(1440, 900), 2, 1),
        ];
    for (final (String nom, Size taille, double echelle, double densite)
        in cas) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final bool rtl in <bool>[false, true]) {
          if (rtl && (mode == ThemeMode.dark || nom.startsWith('1440'))) {
            continue;
          }
          final String fichier =
              'etats_ma_1/salle_ma_idriss_${nom}_${mode.name}'
              '${rtl ? '_rtl' : ''}';
          testWidgets(fichier, (WidgetTester tester) async {
            fixerVueCapture(tester, taille, densite);
            Widget ecran = const EcranAccessibiliteDemo(
              eleve: EleveDemoAccessibilite.idriss,
              moment: MomentDemoAccessibilite.fenetre,
              etapeInitiale: EtapeDemoAccessibilite.salle,
            );
            if (rtl) {
              ecran = Directionality(
                textDirection: TextDirection.rtl,
                child: ecran,
              );
            }
            await tester.pumpWidget(
              hoteCapture(
                ecran,
                themeMode: mode,
                echelleTexte: echelle,
                interfaceMode: InterfaceMode.enfant,
              ),
            );
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, fichier)}');
          });
        }
      }
    }
  });
}
