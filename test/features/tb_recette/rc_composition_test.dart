// TB-RC, lot L1-composition : la part de la page dans la salle.
//
// Revue TB-R m5 (test parametre de hauteur de page), M2 (telephone couche),
// M3 (bureau a texte x2) ; TB_RAPPORT §d n. 1 (320 x2), n. 3 (vignette sur
// la feuille), n. 4 (page minuscule au bureau a x2), n. 12 (fermer les
// Commandes rapetissait la page a 1440).
//
// Les mesures sont faites avec les vraies polices du depot : la largeur des
// mots decide des rangees.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/composition_salle.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vignette_video.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

/// Les tailles de la revue (m5) : telephone couche, petit telephone
/// couche, portable, bureau, petit telephone debout.
const List<(String, Size)> _tailles = <(String, Size)>[
  ('844x390', Size(844, 390)),
  ('700x320', Size(700, 320)),
  ('1280x720', Size(1280, 720)),
  ('1440x900', Size(1440, 900)),
  ('320x700', Size(320, 700)),
];

Future<void> _monter(
  WidgetTester tester, {
  required Size taille,
  required double texte,
  required RoleSeance role,
  required SituationTb situation,
}) async {
  fixerVueCapture(tester, taille, 2);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(role: role, situation: situation),
      echelleTexte: texte,
    ),
  );
  await stabiliser(tester);
  await tester.pump(const Duration(milliseconds: 1400));
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('m5 : la page garde sa part de la hauteur utile', () {
    for (final (String nom, Size taille) in _tailles) {
      for (final double texte in <double>[1, 2]) {
        for (final RoleSeance role in <RoleSeance>[
          RoleSeance.enseignant,
          RoleSeance.eleve,
        ]) {
          for (final SituationTb situation in <SituationTb>[
            SituationTb.ped03,
            SituationTb.ped01,
          ]) {
            final bool page = situation == SituationTb.ped03;
            testWidgets('${role.name} ${page ? 'page' : 'tableau libre'} '
                '$nom x${texte.toInt()}', (WidgetTester tester) async {
              await _monter(
                tester,
                taille: taille,
                texte: texte,
                role: role,
                situation: situation,
              );
              expect(tester.takeException(), isNull);
              final Rect r = tester.getRect(
                find.byKey(
                  page ? SurfacePageFixe.clePage : SurfacePageFixe.cleFeuille,
                ),
              );
              expect(
                r.height / taille.height,
                greaterThanOrEqualTo(CompositionSalle.partMinimalePage),
                reason: '$nom x$texte : page ${r.size}',
              );
              // Rien ne recouvre la page : ni le declencheur pose au bord,
              // ni la vignette de l'enseignant (TB_RAPPORT §d n. 3).
              for (final Finder dessus in <Finder>[
                find.byKey(DeclencheurCommandes.cle),
                find.byType(VignetteVideo),
              ]) {
                for (final Element e in dessus.evaluate()) {
                  final RenderBox b = e.renderObject! as RenderBox;
                  final Rect rb = b.localToGlobal(Offset.zero) & b.size;
                  expect(
                    rb.overlaps(r),
                    isFalse,
                    reason: '$nom x$texte : ${e.widget} sur la page',
                  );
                }
              }
            });
          }
        }
      }
    }
  });

  group('n. 3 : la vignette ne recouvre pas la feuille du tableau libre', () {
    for (final (String nom, Size taille) in <(String, Size)>[
      ('320x700', const Size(320, 700)),
      ('390x844', const Size(390, 844)),
      ('768x1024', const Size(768, 1024)),
    ]) {
      for (final RoleSeance role in <RoleSeance>[
        RoleSeance.eleve,
        RoleSeance.guidee,
        RoleSeance.enseignant,
      ]) {
        testWidgets('${role.name} $nom', (WidgetTester tester) async {
          await _monter(
            tester,
            taille: taille,
            texte: 1,
            role: role,
            situation: SituationTb.ped01,
          );
          final Rect feuille = tester.getRect(
            find.byKey(SurfacePageFixe.cleFeuille),
          );
          final Finder vignette = find.byType(VignetteVideo);
          // L'eleve garde la vignette de l'enseignant, hors de la feuille ;
          // l'enseignant garde la sienne a 390 et 768 (a 320, elle cede la
          // place si la feuille tombait sous sa part).
          if (role != RoleSeance.enseignant || taille.width > 320) {
            expect(vignette, findsOneWidget);
          }
          for (final Element e in vignette.evaluate()) {
            final RenderBox b = e.renderObject! as RenderBox;
            expect(
              (b.localToGlobal(Offset.zero) & b.size).overlaps(feuille),
              isFalse,
              reason: '${role.name} $nom',
            );
          }
        });
      }
    }
  });

  group('M2 : la salle courte se decide sur la hauteur', () {
    test('844 x 390 est court, 1440 x 900 ne l\'est qu\'a x2', () {
      expect(
        CompositionSalle.hauteurCourte(hauteur: 390, facteurTexte: 1),
        isTrue,
      );
      expect(
        CompositionSalle.hauteurCourte(hauteur: 900, facteurTexte: 1),
        isFalse,
      );
      expect(
        CompositionSalle.hauteurCourte(hauteur: 900, facteurTexte: 2),
        isTrue,
      );
      expect(
        CompositionSalle.hauteurCourte(hauteur: 1024, facteurTexte: 2),
        isFalse,
      );
    });

    testWidgets('telephone couche x2 : la tete se borne et defile en fondu', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(844, 390),
        texte: 2,
        role: RoleSeance.enseignant,
        situation: SituationTb.ped03,
      );
      final double tete = tester
          .getSize(find.byKey(TeteSalleBornee.defilementKey))
          .height;
      expect(tete, lessThanOrEqualTo(390 * CompositionSalle.partTeteCourte));
      expect(find.byKey(TeteSalleBornee.cleFondu), findsOneWidget);
    });

    testWidgets('bureau x2 : la tete est bornee (M3)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(1280, 720),
        texte: 2,
        role: RoleSeance.eleve,
        situation: SituationTb.ped03,
      );
      expect(find.byKey(TeteSalleBornee.defilementKey), findsOneWidget);
      expect(
        tester.getSize(find.byKey(TeteSalleBornee.defilementKey)).height,
        lessThanOrEqualTo(720 * CompositionSalle.partTeteCourte),
      );
    });
  });

  testWidgets('n. 12 : a 1440, fermer les Commandes ne rapetisse pas la page', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      taille: const Size(1440, 900),
      texte: 1,
      role: RoleSeance.enseignant,
      situation: SituationTb.ped03,
    );
    final Finder page = find.byKey(SurfacePageFixe.clePage);
    final Size ferme = tester.getSize(page);
    await tester.tap(find.byKey(DeclencheurCommandes.cle));
    await stabiliser(tester);
    expect(find.byKey(CommandesPedagogiques.cle), findsOneWidget);
    final Size ouvert = tester.getSize(page);
    expect(ferme.height, greaterThanOrEqualTo(ouvert.height - 0.5));
  });
}
