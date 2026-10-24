// ETATS-MA-1, remplace dans la salle par le standard des commandes d'appel
// (directeur, 24/10/2026, SALLE-PLAN-2026-10-24.md). Ancienne regle (decision
// du 05/10/2026) : « le mot d'etat reste » sous le disque, deux rangees de
// mots au-dela de 130 %. Nouvelle regle : la pilule d'appel est faite de
// boutons ronds en ICONES SEULES, a toute echelle de texte ; l'etat se lit
// par l'icone barree, le remplissage et l'infobulle / la semantique.
//
// - A 320 et 390 px, texte x1,5 et x2, clair et sombre, LTR et RTL : aucun
//   texte dans le dock, l'infobulle de chaque bascule dit son etat, les
//   boutons gardent leur taille (56), la pilule peut passer sur deux rangees,
//   rien ne deborde, Quitter reste a l'ecran.
// - Jusqu'a 130 % en Mode Accessibilite, et hors Mode Accessibilite a toute
//   taille : la meme pilule, sans mot.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

final Finder _dock = find.byKey(const ValueKey<String>('dock-seance'));
final Finder _disques = find.descendant(
  of: _dock,
  matching: find.byKey(const ValueKey<String>('disque-appel')),
);

/// Les infobulles d'etat possibles des bascules de l'eleve.
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

/// Le bouton du dock dont l'infobulle (son etat) est l'un de [mots].
Finder _bouton(Set<String> mots) => find.descendant(
  of: _dock,
  matching: find.byWidgetPredicate(
    (Widget w) => w is Tooltip && mots.contains(w.message),
  ),
);

/// Le bouton Quitter du dock.
Finder _quitter() => _bouton(<String>{t.salle.quitter});

/// Les textes affiches dans le dock : il n'y en a aucun (standard).
List<String> _motsAffiches(WidgetTester tester) => tester
    .widgetList<Text>(find.descendant(of: _dock, matching: find.byType(Text)))
    .map((Text t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .toList();

/// Le standard : aucun mot, une infobulle d'etat par bascule, des boutons
/// de 56 (telephone), 48 (bureau) ou 72 (Interface guidee) qui gardent leur
/// taille, rien qui deborde de l'ecran.
void _verifierPilule(WidgetTester tester, Size taille, {bool guidee = false}) {
  expect(_motsAffiches(tester), isEmpty, reason: 'mot dans le dock');
  expect(_bouton(_motsMicro), findsOneWidget);
  expect(_bouton(_motsCamera), findsOneWidget);
  expect(_quitter(), findsOneWidget);
  // Interface guidee (Mode Accessibilite) : la cible du mode, 72, l'emporte.
  final double cote = guidee ? 72 : (taille.width < 600 ? 56 : 48);
  for (final Element e in _disques.evaluate()) {
    final Size s = tester.getSize(
      find.byElementPredicate((Element x) => x == e),
    );
    expect(s.height, moreOrLessEquals(cote, epsilon: 0.5));
  }
  final Rect dock = tester.getRect(_dock);
  for (final Rect r in <Rect>[
    dock,
    tester.getRect(_bouton(_motsMicro)),
    tester.getRect(_bouton(_motsCamera)),
    tester.getRect(_quitter()),
  ]) {
    expect(r.left, greaterThanOrEqualTo(-0.5));
    expect(r.right, lessThanOrEqualTo(taille.width + 0.5));
    expect(r.bottom, lessThanOrEqualTo(taille.height + 0.5));
  }
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('ETATS-MA-1 : standard des commandes d appel, texte > 130 %', () {
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
            testWidgets(
              'standard des commandes d appel : $l px, texte x$echelle, '
              '${mode.name}, $sens',
              (WidgetTester tester) async {
                await _monter(
                  tester,
                  taille: taille,
                  echelle: echelle,
                  mode: mode,
                  rtl: rtl,
                );
                expect(tester.takeException(), isNull);

                // Aucun mot sous un bouton ; l'etat vit dans l'infobulle.
                // TB-2 : Agrandir a quitte la pilule hors focus local.
                _verifierPilule(tester, taille, guidee: true);
                expect(
                  _bouton(<String>{t.salle.seance.agrandir}),
                  findsNothing,
                );

                // La pilule peut passer sur deux rangees : micro et camera
                // restent sur la meme, l'ordre suit le sens de lecture.
                final Rect micro = tester.getRect(_bouton(_motsMicro));
                final Rect camera = tester.getRect(_bouton(_motsCamera));
                expect(micro.top, moreOrLessEquals(camera.top, epsilon: 0.5));
                expect(
                  rtl ? micro.left > camera.left : micro.left < camera.left,
                  isTrue,
                );
              },
            );
          }
        }
      }
    }

    // Bureau : meme pilule, sans mot, boutons de 48.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'standard des commandes d appel : 1440 px, texte x2, ${mode.name}',
        (WidgetTester tester) async {
          const Size taille = Size(1440, 900);
          await _monter(tester, taille: taille, mode: mode);
          expect(tester.takeException(), isNull);
          _verifierPilule(tester, taille, guidee: true);
        },
      );
    }

    testWidgets(
      'standard des commandes d appel : Mariam (mineure), 320 px, texte x2',
      (WidgetTester tester) async {
        const Size taille = Size(320, 568);
        await _monter(
          tester,
          taille: taille,
          eleve: EleveDemoAccessibilite.mariam,
        );
        expect(tester.takeException(), isNull);
        _verifierPilule(tester, taille, guidee: true);
      },
    );
  });

  group(
    'ETATS-MA-1 : standard des commandes d appel, meme pilule ailleurs',
    () {
      testWidgets(
        'standard des commandes d appel : Mode Accessibilite, texte a 130 %',
        (WidgetTester tester) async {
          const Size taille = Size(390, 844);
          await _monter(tester, taille: taille, echelle: 1.3);
          expect(tester.takeException(), isNull);
          _verifierPilule(tester, taille, guidee: true);
          final Rect micro = tester.getRect(_bouton(_motsMicro));
          final Rect camera = tester.getRect(_bouton(_motsCamera));
          // Meme rangee : centres a la meme hauteur.
          expect(
            micro.center.dy,
            moreOrLessEquals(camera.center.dy, epsilon: 0.5),
          );
        },
      );

      for (final double echelle in <double>[1, 2]) {
        testWidgets(
          'standard des commandes d appel : hors Mode Accessibilite (eleve), '
          'texte x$echelle',
          (WidgetTester tester) async {
            const Size taille = Size(390, 844);
            fixerVueCapture(tester, taille, 1);
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
            // Le meme standard a toute echelle : aucun mot, boutons de 56.
            _verifierPilule(tester, taille);
            final Rect micro = tester.getRect(_bouton(_motsMicro));
            final Rect camera = tester.getRect(_bouton(_motsCamera));
            expect(micro.top, moreOrLessEquals(camera.top, epsilon: 0.5));
          },
        );
      }
    },
  );

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
