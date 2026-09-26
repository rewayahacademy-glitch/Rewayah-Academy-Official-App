// EN-3 : ENS-09 Mes Classes, sur les donnees de demonstration (K-35).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/point_rappel.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/enseignant_classes/mes_classes_page.dart';

import '../../support/harnais.dart';

void _fenetre(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('ENS-09 : le tri du doc 04 §12.2', () {
    test(
      'la seance la plus proche d abord, les Classes sans seance a la fin',
      () {
        final List<ClasseListee> lignes = classesTriees(
          groupes: DonneesEnseignantDemo.groupes().reversed.toList(),
          seances: DonneesEnseignantDemo.seances(EtatDemoEnseignant.nominal),
          cahiers: DonneesEnseignantDemo.cahiersEnRetard(
            EtatDemoEnseignant.nominal,
          ),
          details: const <String, DetailClasse>{},
          maintenant: DonneesEnseignantDemo.maintenant,
        );
        expect(
          lignes.map((ClasseListee l) => l.groupe.libelle).toList(),
          <String>['An-Nour', 'Al-Fatiha', 'Al-Badr', 'Al-Ikhlas'],
        );
        // Le cahier du 26 septembre d'Al-Badr n'est pas valide (K-45).
        expect(
          lignes
              .where((ClasseListee l) => l.cahierAValider)
              .map((ClasseListee l) => l.groupe.libelle),
          <String>['Al-Badr'],
        );
      },
    );

    test('une seance passee ou annulee n est pas une prochaine seance', () {
      final GroupeEnseignant g = DonneesEnseignantDemo.groupes().first;
      final DateTime m = DonneesEnseignantDemo.maintenant;
      final List<ClasseListee> lignes = classesTriees(
        groupes: <GroupeEnseignant>[g],
        seances: <SeanceEnseignant>[
          SeanceEnseignant(
            id: 's1',
            debut: m.subtract(const Duration(days: 1)),
            fin: m.subtract(const Duration(hours: 23)),
            statut: StatutSeance.planifiee,
            nbParticipants: 4,
            cahierDepose: false,
            groupeId: g.id,
          ),
          SeanceEnseignant(
            id: 's2',
            debut: m.add(const Duration(hours: 1)),
            fin: m.add(const Duration(hours: 2)),
            statut: StatutSeance.annulee,
            nbParticipants: 4,
            cahierDepose: false,
            groupeId: g.id,
          ),
        ],
        cahiers: const <CahierEnRetard>[],
        details: const <String, DetailClasse>{},
        maintenant: m,
      );
      expect(lignes.single.prochaine, isNull);
    });
  });

  group('ENS-09 : la page', () {
    testWidgets('une ligne par Classe, les exceptions seulement', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 1200));
      await tester.pumpWidget(
        hote(const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.classes)),
      );
      await tester.pumpAndSettle();

      // Une seule carte groupee, quatre lignes.
      expect(find.byType(GroupeReglages), findsOneWidget);
      for (final String nom in <String>[
        'An-Nour',
        'Al-Fatiha',
        'Al-Badr',
        'Al-Ikhlas',
      ]) {
        expect(find.text(nom), findsOneWidget);
      }
      // Dans l'ordre du tri.
      final double y1 = tester.getTopLeft(find.text('An-Nour')).dy;
      final double y2 = tester.getTopLeft(find.text('Al-Fatiha')).dy;
      final double y4 = tester.getTopLeft(find.text('Al-Ikhlas')).dy;
      expect(y1 < y2 && y2 < y4, isTrue);
      // « Remplacement » : une pastille de mot, une seule fois (E12).
      expect(
        find.widgetWithText(StatusPill, t.enseignant.classes.remplacement),
        findsOneWidget,
      );
      // Le point de rappel du cahier d'Al-Badr, et lui seul (K-45).
      expect(find.byType(PointRappel), findsOneWidget);
      expect(
        find.textContaining(t.enseignant.classes.sansProchaine),
        findsOneWidget,
      );
      // Ni creation, ni filtre (E18, rectification ENS-09).
      expect(find.textContaining('Nouvelle'), findsNothing);
      expect(find.text('Toutes'), findsNothing);
    });

    testWidgets('aucune Classe : une phrase calme, aucun bouton', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 900));
      await tester.pumpWidget(
        hote(
          const CoquilleEnseignantDemo(
            ecran: EcranDemoEnseignant.classes,
            etat: EtatDemoEnseignant.vide,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.classes.vide), findsOneWidget);
      expect(find.text(t.enseignant.classes.videDetail), findsOneWidget);
    });
  });

  group('PointRappel', () {
    testWidgets('fixe d emblee quand les animations sont reduites', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: PointRappel(libelle: 'rappel')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const ValueKey<String>('point-rappel-halo')),
        findsNothing,
      );
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
