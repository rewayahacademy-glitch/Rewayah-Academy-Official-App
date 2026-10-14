// COM-RC tour 6, contre-verification COM-R-4 8.3-3 : les ajustements des
// fiches UX du Studio.
//
// - UX_REVIEW_COM-STU-1 point 6 : entre deux sections de la liste des
//   canaux, 24 sur telephone, 32 au-dela (contrat A) ;
// - UX_REVIEW_COM-STU-2 point 4 : entre les indicateurs et les blocs
//   d'Aujourd'hui, 24 sous 600, 32 a partir de 600 ;
// - UX_REVIEW_COM-STU-2 point 14 : le chargement d'Aujourd'hui a sa forme
//   (rangee de tuiles, puis groupes en 1, 2 ou 3 colonnes), pas un
//   `Skeleton.liste()` generique.
//
// Contre-preuve : a a1a33222, 20 entre les sections a toutes les largeurs,
// 24 entre indicateurs et blocs a toutes les largeurs, et le squelette du
// chargement etait `Skeleton.liste()` (`VueEtatCommunication.cleChargement`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/vue_etat_communication.dart';
import 'package:rewayah_academy/features/com_studio/aujourdhui_page.dart';
import 'package:rewayah_academy/features/com_studio/liste_canaux.dart';
import 'package:rewayah_academy/features/com_studio/port_activite_studio.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';

import 'support_studio.dart';

/// Une activite qui attend, puis rend la demonstration.
class _ActiviteEnAttente implements PortActiviteStudio {
  final Completer<void> attente = Completer<void>();

  @override
  Future<List<ActiviteStudio>> activites() async {
    await attente.future;
    return fixturesActiviteStudioDemo(maintenantTest);
  }

  @override
  Future<void> marquerLu(String activiteId) async {}
}

/// L'ecart vertical entre le bas de [haut] et le haut de [bas].
double _ecart(WidgetTester tester, Finder haut, Finder bas) =>
    tester.getTopLeft(bas).dy - tester.getBottomLeft(haut).dy;

Future<void> _monterAujourdhui(
  WidgetTester tester,
  Size taille, {
  PortActiviteStudio? activite,
  bool stabiliser = true,
}) => monterStudio(
  tester,
  port: portDemo(),
  depart: Routes.adminStudio,
  activite:
      activite ??
      ActiviteStudioDemo(
        situation: SituationDemoStudio.normale,
        maintenant: maintenantTest,
      ),
  brouillons: brouillonsStudioDemo(SituationDemoStudio.normale),
  taille: taille,
  stabiliser: stabiliser,
);

void main() {
  group('UX_REVIEW_COM-STU-1 point 6 : ecart entre sections des canaux', () {
    for (final (Size taille, double attendu) cas in <(Size, double)>[
      (const Size(390, 1600), AppSpacing.xxl),
      (const Size(768, 1600), AppSpacing.xxxl),
      (const Size(1440, 1600), AppSpacing.xxxl),
    ]) {
      testWidgets('${cas.$1.width.toInt()} : ${cas.$2.toInt()} entre deux '
          'sections', (WidgetTester tester) async {
        await monterStudio(tester, port: portDemo(), taille: cas.$1);
        final Finder organisation = find.byKey(
          ListeCanaux.cleSection(SectionStudio.organisation),
        );
        final Finder admissions = find.byKey(
          ListeCanaux.cleSection(SectionStudio.admissionsFamilles),
        );
        expect(organisation, findsOneWidget);
        expect(admissions, findsOneWidget);
        expect(_ecart(tester, organisation, admissions), cas.$2);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group(
    "UX_REVIEW_COM-STU-2 point 4 : indicateurs vers blocs d'Aujourd'hui",
    () {
      for (final (Size taille, double attendu) cas in <(Size, double)>[
        (const Size(390, 844), AppSpacing.xxl),
        (const Size(768, 1024), AppSpacing.xxxl),
        (const Size(1440, 900), AppSpacing.xxxl),
      ]) {
        testWidgets('${cas.$1.width.toInt()} : ${cas.$2.toInt()} entre les '
            'indicateurs et la premiere colonne', (WidgetTester tester) async {
          await _monterAujourdhui(tester, cas.$1);
          expect(
            _ecart(
              tester,
              find.byKey(TableauAujourdhui.cleIndicateurs),
              find.byKey(TableauAujourdhui.cleColonne(0)),
            ),
            cas.$2,
          );
          expect(tester.takeException(), isNull);
        });
      }
    },
  );

  group("UX_REVIEW_COM-STU-2 point 14 : squelette a la forme d'Aujourd'hui", () {
    for (final (Size taille, int colonnes, int groupes) cas
        in <(Size, int, int)>[
          (const Size(390, 2400), 1, 5),
          (const Size(768, 1600), 2, 3),
          (const Size(1440, 1200), 3, 5),
        ]) {
      testWidgets('${cas.$1.width.toInt()} : tuiles, puis ${cas.$3} groupes '
          'sur ${cas.$2} colonne(s), aucun squelette de liste', (
        WidgetTester tester,
      ) async {
        final _ActiviteEnAttente activite = _ActiviteEnAttente();
        await _monterAujourdhui(
          tester,
          cas.$1,
          activite: activite,
          stabiliser: false,
        );
        // Le squelette paraît apres son delai (200 ms), sans changement.
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byKey(VueEtatCommunication.cleChargement), findsNothing);
        // Aucun squelette de liste dans l'activite (les brouillons gardent leur
        // propre etat, spec section 25).
        expect(
          find.descendant(
            of: find.byKey(TableauAujourdhui.cleSquelette),
            matching: find.byWidgetPredicate(
              (Widget w) =>
                  w is Skeleton &&
                  w.lignes == 3 &&
                  w.hauteur == AppSpacing.respiration,
            ),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(TableauAujourdhui.cleSqueletteIndicateurs),
            matching: find.byWidgetPredicate(
              (Widget w) => w is Skeleton && w.lignes == 3,
            ),
          ),
          findsNothing,
        );
        final Finder indicateurs = find.byKey(
          TableauAujourdhui.cleSqueletteIndicateurs,
        );
        expect(indicateurs, findsOneWidget);
        expect(
          find.descendant(of: indicateurs, matching: find.byType(Skeleton)),
          findsNWidgets(4),
        );
        expect(find.byKey(TableauAujourdhui.cleSquelette), findsOneWidget);
        for (int i = 0; i < cas.$3; i++) {
          expect(
            find.byKey(TableauAujourdhui.cleSqueletteGroupe(i)),
            findsOneWidget,
            reason: 'groupe $i',
          );
        }
        expect(
          find.byKey(TableauAujourdhui.cleSqueletteGroupe(cas.$3)),
          findsNothing,
        );
        // Les groupes sont ranges sur le nombre de colonnes de la page.
        final Set<double> abscisses = <double>{
          for (int i = 0; i < cas.$3; i++)
            tester
                .getTopLeft(find.byKey(TableauAujourdhui.cleSqueletteGroupe(i)))
                .dx,
        };
        expect(abscisses.length, cas.$2 == 3 ? 2 : 1);
        // Tuiles d'abord, puis l'ecart de section, puis les groupes.
        expect(
          _ecart(
            tester,
            indicateurs,
            find.byKey(TableauAujourdhui.cleSqueletteGroupe(0)),
          ),
          cas.$1.width >= 600 ? AppSpacing.xxxl : AppSpacing.xxl,
        );
        // Les tuiles d'une rangee : quatre cote a cote, ou deux par deux.
        final Set<double> lignesTuiles = <double>{
          for (final Element e
              in find
                  .descendant(of: indicateurs, matching: find.byType(Skeleton))
                  .evaluate())
            (e.renderObject! as RenderBox).localToGlobal(Offset.zero).dy,
        };
        expect(lignesTuiles.length, cas.$2 == 1 ? 2 : 1);
        activite.attente.complete();
        await tester.pumpAndSettle();
        expect(find.byKey(TableauAujourdhui.cleSquelette), findsNothing);
        expect(
          find.byKey(TableauAujourdhui.cleSqueletteIndicateurs),
          findsNothing,
        );
        expect(find.byKey(TableauAujourdhui.cleIndicateurs), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
