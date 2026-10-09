// TB-1b : squelette des captures du chantier Supports et tableau.
//
// Sautees sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md). Chaque etape
// TB ajoute ses situations a `_situationsCapturees` et garde les cadrages de
// la definition de « fait » (02_DECOUPAGE) : 390x844, 768x1024, 1440x900,
// clair et sombre, texte x2 aux trois tailles, 320 x1 et x2 (320 x 700 @2,
// le cadrage de salle_200_test).
//
// La page montee est `DemoSallePage`, celle que sert `/demo/salle?role=…&tb=…`.
//
// Commande :
//   CAPTURE_DIR=/tmp/tb flutter test test/features/tb_recette/captures_tb_test.dart
//
// TB-2 (VIS-01) : la barre de l'appel au repos (masquee apres le delai) et
// revelee (une touche sur le contenu), pour l'enseignant, l'eleve et le Mode
// Accessibilite (guidee), situation VIS-01. Rangees dans
// docs/current/captures/TB-2/ :
//   CAPTURE_DIR=docs/current/captures/TB-2 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb2_
//
// TB-3 (UI-01, CTX-01, CTX-02) : la capsule pendant le partage (UI-01) et le
// contexte deplie a la section du controle (CTX-02), pour l'enseignant,
// l'eleve et le Mode Accessibilite (guidee, pendant la visite du tuteur : la
// notice de l'enfant reste visible), plus RTL. Rangees dans
// docs/current/captures/TB-3/ :
//   CAPTURE_DIR=docs/current/captures/TB-3 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb3_
//
// TB-4 (CMD-01) : le declencheur « Commandes » ferme (PED-03), le panneau
// ouvert sur l'onglet « Support » et sur l'onglet « Outils » (CMD-01) pour
// l'enseignant ; l'eleve en CMD-01, sans rien de l'enseignant. 390, 768,
// 1440 et 320, texte x1 et x2, clair et sombre, plus RTL. Rangees dans
// docs/current/captures/TB-4/ :
//   CAPTURE_DIR=docs/current/captures/TB-4 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb4_
//
// TB-5 (UI-02, UI-03) : la salle de l'enseignant developpee (Participants a
// gauche, Commandes ouvertes a droite) et en focus, 768, 1024 et 1440, texte
// x1 et x2, clair (et sombre a x1), plus RTL a 1440. Rangees dans
// docs/current/captures/TB-5/ :
//   CAPTURE_DIR=docs/current/captures/TB-5 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb5_
//
// TB-6 (PED-01 a PED-04) : tableau libre, Support, Avec notes, Tableau,
// enseignant et eleve, 390 et 1440 clair et sombre, 390 x2, 320 x2. Rangees dans
// docs/current/captures/TB-6/ :
//   CAPTURE_DIR=docs/current/captures/TB-6 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb6_
//
// TB-8 (LIB-01 a LIB-04) : catalogue, apercu personnel, ouverture et echec,
// 390 et 1440 clair et sombre, 390 x2, 320 x2. Rangees dans
// docs/current/captures/TB-8/ :
//   CAPTURE_DIR=docs/current/captures/TB-8 flutter test \
//     test/features/tb_recette/captures_tb_test.dart --name tb8_

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/bibliotheque_seance.dart';
import 'package:rewayah_academy/features/salle_seance/capsule_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/composition_salle.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/salle_seance/zone_support.dart';
import 'package:rewayah_academy/features/tc_catalogue/surface_bibliotheque.dart';

import '../../capture/outil_capture.dart';

typedef _Cadrage = (
  String nom,
  Size logique,
  double densite,
  EdgeInsets zone,
  double texte,
  ThemeMode mode,
);

const EdgeInsets _zoneTelephone = EdgeInsets.only(top: 47, bottom: 34);

/// Les cadrages de la definition de « fait » (02_DECOUPAGE, point 3).
const List<_Cadrage> _cadragesTb = <_Cadrage>[
  ('390_x1_clair', Size(390, 844), 3, _zoneTelephone, 1, ThemeMode.light),
  ('390_x1_sombre', Size(390, 844), 3, _zoneTelephone, 1, ThemeMode.dark),
  ('390_x2_clair', Size(390, 844), 3, _zoneTelephone, 2, ThemeMode.light),
  ('768_x1_clair', Size(768, 1024), 2, EdgeInsets.zero, 1, ThemeMode.light),
  ('768_x1_sombre', Size(768, 1024), 2, EdgeInsets.zero, 1, ThemeMode.dark),
  ('768_x2_clair', Size(768, 1024), 2, EdgeInsets.zero, 2, ThemeMode.light),
  ('1440_x1_clair', Size(1440, 900), 1, EdgeInsets.zero, 1, ThemeMode.light),
  ('1440_x1_sombre', Size(1440, 900), 1, EdgeInsets.zero, 1, ThemeMode.dark),
  ('1440_x2_clair', Size(1440, 900), 1, EdgeInsets.zero, 2, ThemeMode.light),
  ('320_x1_clair', Size(320, 700), 2, EdgeInsets.zero, 1, ThemeMode.light),
  ('320_x2_clair', Size(320, 700), 2, EdgeInsets.zero, 2, ThemeMode.light),
];

/// Les situations capturees, par role. TB-1b n'a aucune disposition
/// nouvelle : une seule situation, la salle et ses personnes (SAL-00),
/// prouve que le squelette tourne. Chaque etape ajoute les siennes.
const Map<RoleSeance, List<SituationTb>> _situationsCapturees =
    <RoleSeance, List<SituationTb>>{
      RoleSeance.eleve: <SituationTb>[SituationTb.sal00],
      RoleSeance.guidee: <SituationTb>[SituationTb.sal00],
      RoleSeance.enseignant: <SituationTb>[SituationTb.sal00],
    };

/// L'opacite visee par le fondu de la barre de l'appel.
double _opaciteBarre(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byKey(CommandesMasquables.commandesKey),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

void main() {
  test('le delai de masquage est celui de CommandesMasquables (4 s)', () {
    // Une seule valeur (plan V2 §18.1, TB7) : aucune seconde constante.
    expect(CommandesMasquables.delaiParDefaut, const Duration(seconds: 4));
  });

  test('chaque situation capturee a un sens pour son role', () {
    _situationsCapturees.forEach((RoleSeance role, List<SituationTb> l) {
      for (final SituationTb s in l) {
        expect(s.concerne(role), isTrue, reason: '${role.name} ${s.name}');
      }
    });
  });

  group(
    'TB-2 : barre de l\'appel au repos et revelee',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      for (final RoleSeance role in RoleSeance.values) {
        for (final _Cadrage cas in _cadragesTb) {
          for (final bool revelee in <bool>[false, true]) {
            final String nom =
                'tb2_${role.name}_${revelee ? 'revelee' : 'repos'}_${cas.$1}';
            testWidgets(nom, (WidgetTester tester) async {
              fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
              await tester.pumpWidget(
                hoteCapture(
                  DemoSallePage(role: role, situation: SituationTb.vis01),
                  themeMode: cas.$6,
                  echelleTexte: cas.$5,
                ),
              );
              await stabiliser(tester);
              // Le delai passe : la barre se masque (repos).
              await tester.pump(CommandesMasquables.delaiParDefaut);
              await tester.pump(const Duration(seconds: 1));
              if (revelee) {
                // Une touche au centre du support (pas un point fixe de
                // l'ecran : a texte x2, le tiers de la hauteur tombe dans
                // l'en-tete, hors de CommandesMasquables, et rien ne se
                // revelait) : la barre revient, rien d'autre ne change.
                await tester.tapAt(
                  tester.getCenter(find.byType(ZoneSupport).first),
                );
                // Un cadre pour lancer le fondu, puis sa duree.
                await tester.pump();
                await tester.pump(const Duration(milliseconds: 400));
              }
              // La capture prouve ce qu'elle nomme : barre a pleine opacite
              // une fois revelee, effacee au repos.
              expect(
                _opaciteBarre(tester),
                revelee ? 1 : 0,
                reason: '$nom : opacite de la barre',
              );
              expect(tester.takeException(), isNull);
              debugPrint('PNG ${await capturer(tester, nom)}');
            });
          }
        }
      }
    },
  );

  group('TB-3 : capsule et contexte', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Les cadrages de « fait », plus le sens de lecture force (K-41 n. 12).
    final List<(_Cadrage, TextDirection)> cadrages =
        <(_Cadrage, TextDirection)>[
          for (final _Cadrage c in _cadragesTb) (c, TextDirection.ltr),
          (
            (
              '390_x1_clair_rtl',
              const Size(390, 844),
              3,
              _zoneTelephone,
              1,
              ThemeMode.light,
            ),
            TextDirection.rtl,
          ),
          (
            (
              '320_x2_clair_rtl',
              const Size(320, 700),
              2,
              EdgeInsets.zero,
              2,
              ThemeMode.light,
            ),
            TextDirection.rtl,
          ),
        ];
    for (final RoleSeance role in RoleSeance.values) {
      for (final SituationTb situation in <SituationTb>[
        SituationTb.ui01,
        SituationTb.ctx02,
      ]) {
        for (final (_Cadrage cas, TextDirection sens) in cadrages) {
          final String nom = 'tb3_${role.name}_${situation.name}_${cas.$1}';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
            await tester.pumpWidget(
              hoteCapture(
                Directionality(
                  textDirection: sens,
                  child: DemoSallePage(
                    role: role,
                    situation: situation,
                    // Mode Accessibilite : la visite du tuteur, pour que la
                    // notice de l'enfant figure sur la capture.
                    etat: role == RoleSeance.guidee
                        ? EtatDemoSalle.visite
                        : null,
                  ),
                ),
                themeMode: cas.$6,
                echelleTexte: cas.$5,
              ),
            );
            await stabiliser(tester);
            await tester.pump(const Duration(milliseconds: 1400));
            // La capture prouve ce qu'elle nomme.
            expect(find.byKey(CapsuleSeance.cle), findsOneWidget);
            expect(
              find.byKey(SectionContexte.cle),
              situation == SituationTb.ctx02 ? findsOneWidget : findsNothing,
            );
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
  });

  group('TB-4 : declencheur et panneau Commandes', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // 390, 768, 1440 et 320 ; x1 et x2 ; clair et sombre ; plus RTL.
    final List<(_Cadrage, TextDirection)> cadrages =
        <(_Cadrage, TextDirection)>[
          for (final (String, Size, double, EdgeInsets) taille
              in <(String, Size, double, EdgeInsets)>[
                ('390', const Size(390, 844), 3, _zoneTelephone),
                ('768', const Size(768, 1024), 2, EdgeInsets.zero),
                ('1440', const Size(1440, 900), 1, EdgeInsets.zero),
                ('320', const Size(320, 700), 2, EdgeInsets.zero),
              ])
            for (final double texte in <double>[1, 2])
              for (final ThemeMode mode in <ThemeMode>[
                ThemeMode.light,
                ThemeMode.dark,
              ])
                (
                  (
                    '${taille.$1}_x${texte.toInt()}_'
                        '${mode == ThemeMode.light ? 'clair' : 'sombre'}',
                    taille.$2,
                    taille.$3,
                    taille.$4,
                    texte,
                    mode,
                  ),
                  TextDirection.ltr,
                ),
          for (final (String, Size, double, EdgeInsets, double) taille
              in <(String, Size, double, EdgeInsets, double)>[
                ('390_x1', const Size(390, 844), 3, _zoneTelephone, 1),
                ('1440_x1', const Size(1440, 900), 1, EdgeInsets.zero, 1),
                ('320_x2', const Size(320, 700), 2, EdgeInsets.zero, 2),
              ])
            (
              (
                '${taille.$1}_clair_rtl',
                taille.$2,
                taille.$3,
                taille.$4,
                taille.$5,
                ThemeMode.light,
              ),
              TextDirection.rtl,
            ),
        ];
    // Enseignant : ferme, onglet Support, onglet Outils ; eleve : CMD-01.
    for (final (RoleSeance role, SituationTb situation, String etat)
        in <(RoleSeance, SituationTb, String)>[
          (RoleSeance.enseignant, SituationTb.ped03, 'ferme'),
          (RoleSeance.enseignant, SituationTb.cmd01, 'support'),
          (RoleSeance.enseignant, SituationTb.cmd01, 'outils'),
          (RoleSeance.eleve, SituationTb.cmd01, 'sans'),
        ]) {
      for (final (_Cadrage cas, TextDirection sens) in cadrages) {
        final String nom = 'tb4_${role.name}_${etat}_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
          await tester.pumpWidget(
            hoteCapture(
              Directionality(
                textDirection: sens,
                child: DemoSallePage(role: role, situation: situation),
              ),
              themeMode: cas.$6,
              echelleTexte: cas.$5,
            ),
          );
          await stabiliser(tester);
          if (etat == 'outils') {
            await tester.tap(
              find.descendant(
                of: find.byKey(CommandesPedagogiques.cleOnglets),
                matching: find.text('Outils'),
              ),
            );
            await stabiliser(tester);
          }
          await tester.pump(const Duration(milliseconds: 1400));
          // La capture prouve ce qu'elle nomme.
          final bool ouvert = etat == 'support' || etat == 'outils';
          expect(
            find.byKey(CommandesPedagogiques.cle),
            ouvert ? findsOneWidget : findsNothing,
          );
          // TB-5 : ouvertes, les Commandes sont en colonne (declencheur
          // visible) seulement si la largeur divisee par le texte tient les
          // Participants et elles ; sinon en volet ou en feuille.
          final bool enColonne =
              cas.$2.width / cas.$5 >=
              CompositionSalle.seuilColonne + CompositionSalle.coutColonne;
          expect(
            find.byKey(DeclencheurCommandes.cle),
            role == RoleSeance.enseignant && !(ouvert && !enColonne)
                ? findsOneWidget
                : findsNothing,
          );
          if (etat == 'outils') {
            expect(
              find.byKey(const ValueKey<String>('outil-pointeur')),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });

  group('TB-5 : bureau equilibre et focus', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    final List<(String, Size, double, ThemeMode, TextDirection)> cadrages =
        <(String, Size, double, ThemeMode, TextDirection)>[
          for (final (String, Size) taille in <(String, Size)>[
            ('768', const Size(768, 1024)),
            ('1024', const Size(1024, 768)),
            ('1440', const Size(1440, 900)),
          ]) ...<(String, Size, double, ThemeMode, TextDirection)>[
            (
              '${taille.$1}_x1_clair',
              taille.$2,
              1,
              ThemeMode.light,
              TextDirection.ltr,
            ),
            (
              '${taille.$1}_x1_sombre',
              taille.$2,
              1,
              ThemeMode.dark,
              TextDirection.ltr,
            ),
            (
              '${taille.$1}_x2_clair',
              taille.$2,
              2,
              ThemeMode.light,
              TextDirection.ltr,
            ),
          ],
          (
            '1440_x1_clair_rtl',
            const Size(1440, 900),
            1,
            ThemeMode.light,
            TextDirection.rtl,
          ),
        ];
    for (final String etat in <String>['developpe', 'focus']) {
      for (final (String, Size, double, ThemeMode, TextDirection) cas
          in cadrages) {
        final String nom = 'tb5_enseignant_${etat}_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$2, cas.$2.width < 1200 ? 2 : 1);
          await tester.pumpWidget(
            hoteCapture(
              Directionality(
                textDirection: cas.$5,
                child: const DemoSallePage(
                  role: RoleSeance.enseignant,
                  situation: SituationTb.cmd01,
                ),
              ),
              themeMode: cas.$4,
              echelleTexte: cas.$3,
            ),
          );
          await stabiliser(tester);
          if (etat == 'focus') {
            final Finder focus = find.byKey(CommandesPedagogiques.cleFocus);
            await tester.ensureVisible(focus);
            await tester.pump();
            await tester.tap(focus);
            await stabiliser(tester);
          }
          await tester.pump(const Duration(milliseconds: 1400));
          // La capture prouve ce qu'elle nomme.
          final bool colonne =
              cas.$2.width / cas.$3 >= CompositionSalle.seuilColonne;
          expect(
            find.byType(PanneauEleves),
            etat == 'developpe' && colonne ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(CommandesPedagogiques.cle),
            etat == 'developpe' ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });

  // TB-5 : au telephone, pendant le partage, pas de rangee « Eleves »
  // (l'avatar de la capsule ouvre les Participants) ; le support reprend la
  // place qui lui manquait a 320 x2 (reste de TB-4).
  group('TB-5 : telephone pendant le partage', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String, Size, double, EdgeInsets, double, ThemeMode) cas
        in <(String, Size, double, EdgeInsets, double, ThemeMode)>[
          (
            '390_x1_clair',
            const Size(390, 844),
            3,
            _zoneTelephone,
            1,
            ThemeMode.light,
          ),
          (
            '390_x2_clair',
            const Size(390, 844),
            3,
            _zoneTelephone,
            2,
            ThemeMode.light,
          ),
          (
            '320_x2_clair',
            const Size(320, 700),
            2,
            EdgeInsets.zero,
            2,
            ThemeMode.light,
          ),
          (
            '320_x2_sombre',
            const Size(320, 700),
            2,
            EdgeInsets.zero,
            2,
            ThemeMode.dark,
          ),
        ]) {
      final String nom = 'tb5_enseignant_telephone_${cas.$1}';
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
        await tester.pumpWidget(
          hoteCapture(
            const DemoSallePage(
              role: RoleSeance.enseignant,
              situation: SituationTb.ped03,
            ),
            themeMode: cas.$6,
            echelleTexte: cas.$5,
          ),
        );
        await stabiliser(tester);
        await tester.pump(const Duration(milliseconds: 1400));
        expect(
          find.byKey(const ValueKey<String>('bouton-eleves')),
          findsNothing,
        );
        expect(find.byType(ZoneSupport), findsOneWidget);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }
  });

  // TB-6 (PED-01 a PED-04) : les trois affichages et le tableau libre, chez
  // l'enseignant et l'eleve ; clair et sombre (la page reste claire).
  group('TB-6 : surface a page fixe', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final RoleSeance role in <RoleSeance>[
      RoleSeance.enseignant,
      RoleSeance.eleve,
    ]) {
      for (final SituationTb situation in <SituationTb>[
        SituationTb.ped01,
        SituationTb.ped02,
        SituationTb.ped03,
        SituationTb.ped04,
      ]) {
        for (final _Cadrage cas in <_Cadrage>[
          for (final _Cadrage c in _cadragesTb)
            if (<String>[
              '390_x1_clair',
              '390_x1_sombre',
              '390_x2_clair',
              '1440_x1_clair',
              '1440_x1_sombre',
              '320_x2_clair',
            ].contains(c.$1))
              c,
        ]) {
          final String nom = 'tb6_${role.name}_${situation.name}_${cas.$1}';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
            await tester.pumpWidget(
              hoteCapture(
                DemoSallePage(role: role, situation: situation),
                themeMode: cas.$6,
                echelleTexte: cas.$5,
              ),
            );
            await stabiliser(tester);
            await tester.pump(const Duration(milliseconds: 1400));
            // La capture prouve ce qu'elle nomme.
            final bool page =
                situation == SituationTb.ped02 ||
                situation == SituationTb.ped03;
            expect(
              find.byKey(SurfacePageFixe.clePage),
              page ? findsOneWidget : findsNothing,
            );
            expect(
              find.byKey(SurfacePageFixe.cleFeuille),
              page ? findsNothing : findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
  });

  // TB-8 (LIB-01 a LIB-04) : catalogue, apercu personnel, ouverture et
  // echec, dans le panneau droit (bureau) ou la feuille (telephone).
  group('TB-8 : Bibliotheque en seance', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    Future<void> versCarte(WidgetTester tester, String titre) async {
      final Finder catalogue = find.byType(SurfaceBibliotheque);
      await tester.scrollUntilVisible(
        find.descendant(of: catalogue, matching: find.text(titre)),
        120,
        scrollable: find
            .descendant(of: catalogue, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: catalogue, matching: find.text(titre)).first,
      );
      await tester.pumpAndSettle();
    }

    for (final String etat in <String>[
      'catalogue',
      'apercu',
      'ouverture',
      'echec',
    ]) {
      for (final _Cadrage cas in <_Cadrage>[
        for (final _Cadrage c in _cadragesTb)
          if (<String>[
            '390_x1_clair',
            '390_x1_sombre',
            '390_x2_clair',
            '1440_x1_clair',
            '1440_x1_sombre',
            '320_x2_clair',
          ].contains(c.$1))
            c,
      ]) {
        final String nom = 'tb8_enseignant_${etat}_${cas.$1}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
          await tester.pumpWidget(
            hoteCapture(
              const DemoSallePage(
                role: RoleSeance.enseignant,
                situation: SituationTb.lib01,
              ),
              themeMode: cas.$6,
              echelleTexte: cas.$5,
            ),
          );
          await tester.pumpAndSettle();
          if (etat != 'catalogue') {
            await versCarte(
              tester,
              etat == 'echec' ? "Cahier d'écriture" : 'Fiche de mémorisation',
            );
          }
          if (etat == 'ouverture' || etat == 'echec') {
            final Finder presenter = find.byKey(
              BibliothequeSeance.clePresenter,
            );
            await tester.ensureVisible(presenter);
            await tester.pumpAndSettle();
            await tester.tap(presenter);
            await tester.pump();
            if (etat == 'echec') await tester.pumpAndSettle();
          }
          // La capture prouve ce qu'elle nomme.
          expect(
            find.byType(SurfaceBibliotheque),
            etat == 'catalogue' ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(BibliothequeSeance.cleEchec),
            etat == 'echec' ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
          // L'ouverture capturee, le chargement se termine.
          await tester.pumpAndSettle();
        });
      }
    }
  });

  group('TB : captures de la salle', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    _situationsCapturees.forEach((RoleSeance role, List<SituationTb> l) {
      for (final SituationTb situation in l) {
        for (final _Cadrage cas in _cadragesTb) {
          final String nom = 'tb_${role.name}_${situation.name}_${cas.$1}';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, cas.$2, cas.$3, zoneSure: cas.$4);
            await tester.pumpWidget(
              hoteCapture(
                DemoSallePage(role: role, situation: situation),
                themeMode: cas.$6,
                echelleTexte: cas.$5,
              ),
            );
            await stabiliser(tester);
            // Un cycle du point clignotant : capture a pleine opacite.
            await tester.pump(const Duration(milliseconds: 1400));
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    });
  });
}
