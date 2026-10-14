import 'package:flutter/widgets.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/features/disponibilites/disponibilites_page.dart';
import 'package:rewayah_academy/features/disponibilites/grille_semaine.dart';

import '../support/harnais.dart';

const EleveDuFoyer _amina = EleveDuFoyer(
  id: 'e1',
  prenom: 'Amina',
  identifiantImmuable: 'STUD-AD-000001',
  mode: InterfaceMode.enfant,
  camera: CameraPolicy.forbidden,
);

void main() {
  group('TUT-04 : la famille pose ses creneaux', () {
    testWidgets('sans creneau, l ecran dit ce que cela empeche', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage appairage = FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[_amina];
      final FauxServicePlanning planning = FauxServicePlanning();

      await tester.pumpWidget(
        hote(
          const DisponibilitesPage(),
          surcharges: <Override>[
            serviceAppairageProvider.overrideWithValue(appairage),
            servicePlanningProvider.overrideWithValue(planning),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.disponibilites.aucuneDetail(prenom: 'Amina')),
        findsOneWidget,
      );
      expect(find.byType(GrilleSemaine), findsOneWidget);
    });

    testWidgets('toucher une case libre la propose', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage appairage = FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[_amina];
      final FauxServicePlanning planning = FauxServicePlanning();

      await tester.pumpWidget(
        hote(
          const DisponibilitesPage(),
          surcharges: <Override>[
            serviceAppairageProvider.overrideWithValue(appairage),
            servicePlanningProvider.overrideWithValue(planning),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // La grille depasse la hauteur d'un ecran : la case se rejoint en
      // faisant defiler, comme le fera un tuteur au telephone.
      final Finder mardi17 = find.bySemanticsLabel(
        LibellesGroupe.insecable(
          t.disponibilites.celluleLibre(jour: 'mardi', heure: '17'),
        ),
      );
      await tester.ensureVisible(mardi17);
      await tester.pumpAndSettle();
      await tester.tap(mardi17);
      await tester.pumpAndSettle();

      expect(planning.poses.length, 1);
      expect(planning.poses.single.profilId, 'e1');
      expect(planning.poses.single.creneau.jour, 2);
      expect(planning.poses.single.creneau.heure, 17);
      // Le fuseau vient de la base, jamais de l'appareil : celui-la suit le
      // voyageur, alors que le cours ne bouge pas.
      expect(planning.poses.single.creneau.fuseau, 'Europe/Paris');
    });

    testWidgets('toucher une case posee la retire', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage appairage = FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[_amina];
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux['e1'] = <Creneau>[
          const Creneau(jour: 1, heure: 17, fuseau: 'Europe/Paris'),
        ];

      await tester.pumpWidget(
        hote(
          const DisponibilitesPage(),
          surcharges: <Override>[
            serviceAppairageProvider.overrideWithValue(appairage),
            servicePlanningProvider.overrideWithValue(planning),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.disponibilites.poseeUne), findsOneWidget);

      final Finder lundi17 = find.bySemanticsLabel(
        LibellesGroupe.insecable(
          t.disponibilites.cellulePosee(jour: 'lundi', heure: '17'),
        ),
      );
      await tester.ensureVisible(lundi17);
      await tester.pumpAndSettle();
      await tester.tap(lundi17);
      await tester.pumpAndSettle();

      expect(planning.retires.length, 1);
      expect(planning.retires.single.creneau.jour, 1);
    });

    testWidgets('un echec d enregistrement se dit, il ne se tait pas', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage appairage = FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[_amina];
      final FauxServicePlanning planning = FauxServicePlanning()
        ..erreurAJeter = StateError('reseau');

      await tester.pumpWidget(
        hote(
          const DisponibilitesPage(),
          surcharges: <Override>[
            serviceAppairageProvider.overrideWithValue(appairage),
            servicePlanningProvider.overrideWithValue(planning),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final Finder lundi9 = find.bySemanticsLabel(
        LibellesGroupe.insecable(
          t.disponibilites.celluleLibre(jour: 'lundi', heure: '9'),
        ),
      );
      await tester.ensureVisible(lundi9);
      await tester.pumpAndSettle();
      await tester.tap(lundi9);
      await tester.pumpAndSettle();

      // Une case qui n'a pas ete enregistree doit le dire : sinon la grille
      // montre un etat que la base ne connait pas.
      expect(find.text(t.disponibilites.erreur), findsOneWidget);
    });
  });

  group('La grille ne cache jamais une case posee', () {
    testWidgets('une heure hors de la plage par defaut reste affichee', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          SingleChildScrollView(
            child: GrilleSemaine(
              creneaux: const <Creneau>[
                Creneau(jour: 3, heure: 5, fuseau: 'Africa/Conakry'),
              ],
              fuseau: 'Africa/Conakry',
              onBasculer: (Creneau _, bool _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 5 heures est hors de la plage 6 h - 21 h : sans cette regle, la case
      // serait invisible, donc impossible a retirer.
      expect(find.text('\u200E5\u00A0h'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          LibellesGroupe.insecable(
            t.disponibilites.cellulePosee(jour: 'mercredi', heure: '5'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(t.disponibilites.fuseau(fuseau: 'Africa/Conakry')),
        findsOneWidget,
      );
    });
  });
}
