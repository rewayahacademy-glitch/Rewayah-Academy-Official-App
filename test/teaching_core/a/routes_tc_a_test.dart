import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/roster_enseignant_slot.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/carte_groupe.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/chemins_tc_a.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/mes_groupes_page.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/routes_tc_a.dart';

import 'support/hote_tc_a.dart';

void main() {
  test('routesTcA rend des routes, elle ne construit pas de routeur', () {
    final List<RouteBase> routes = routesTcA();
    expect(routes, hasLength(1));
    final GoRoute racine = routes.first as GoRoute;
    expect(racine.path, CheminsTcA.mesGroupes);
    expect(racine.routes, hasLength(1));
    expect(
      (racine.routes.first as GoRoute).path,
      CheminsTcA.segmentEspaceGroupe,
    );
  });

  test('le chemin d un groupe se compose sous le prefixe reserve', () {
    expect(CheminsTcA.espaceGroupe('abc'), '${CheminsTcA.mesGroupes}/abc');
    expect(CheminsTcA.mesGroupes.startsWith('/tc/'), isTrue);
  });

  testWidgets('la carte mene a l Espace Groupe du bon groupe', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await tester.pumpWidget(
        hoteRoutantTcA(
          depart: CheminsTcA.mesGroupes,
          routes: routesTcA(),
          surcharges: surchargesDemonstration(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(MesGroupesPage), findsOneWidget);
      // La liste suit la prochaine seance (Mes classes, 30/10/2026) : la
      // carte n'est plus forcement la premiere.
      await tester.ensureVisible(find.text('Classe Al-Fatiha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Classe Al-Fatiha'));
      await tester.pumpAndSettle();

      expect(find.byType(EspaceGroupePage), findsOneWidget);
      final EspaceGroupePage espace = tester.widget<EspaceGroupePage>(
        find.byType(EspaceGroupePage),
      );
      expect(espace.groupeId, GroupesDemonstration.alFatiha);
    });
  });

  testWidgets(
    'le slot roster est branche sur PortRosterEnseignant, pas laisse nul',
    (WidgetTester tester) async {
      await avecLargeur(tester, largeurMobile, () async {
        await tester.pumpWidget(
          hoteRoutantTcA(
            depart: CheminsTcA.espaceGroupe(GroupesDemonstration.alFatiha),
            routes: routesTcA(role: RoleEspaceGroupe.enseignant),
            surcharges: surchargesDemonstration(),
          ),
        );
        await tester.pump();
        await tester.pump();

        final EspaceGroupePage espace = tester.widget<EspaceGroupePage>(
          find.byType(EspaceGroupePage),
        );
        expect(espace.contenuRoster, isA<RosterEnseignantSlot>());
        expect(
          (espace.contenuRoster! as RosterEnseignantSlot).groupeId,
          GroupesDemonstration.alFatiha,
        );
      });
    },
  );

  // A-05 (L3-01) : « Rejoindre » mene a /salle pour tout role ; il n'existe
  // plus aucune route /tc/classe a laquelle il pourrait mener.
  for (final RoleEspaceGroupe role in <RoleEspaceGroupe>[
    RoleEspaceGroupe.eleve,
    RoleEspaceGroupe.enseignant,
  ]) {
    // Lot salle 3 (pilote, 25/10/2026) : entree directe, sans preparation.
    testWidgets('${role.name} : « Rejoindre » mene a /salle, sans '
        'preparation', (WidgetTester tester) async {
      await avecLargeur(tester, largeurMobile, () async {
        BilletSalle? billet;
        await tester.pumpWidget(
          hoteRoutantTcA(
            depart: CheminsTcA.espaceGroupe(GroupesDemonstration.anNour),
            routes: <RouteBase>[
              ...routesTcA(role: role),
              GoRoute(
                path: Routes.salle,
                builder: (BuildContext _, GoRouterState e) {
                  billet = e.extra as BilletSalle?;
                  return const Text('salle');
                },
              ),
            ],
            surcharges: surchargesDemonstration(),
          ),
        );
        await tester.pump();
        await tester.pump();

        // L'eleve lit « Rejoindre » ; l'enseignant lit son libelle de salle.
        final String libelleEntree = role == RoleEspaceGroupe.eleve
            ? t.classe.entree.rejoindre
            : t.enseignant.journee.rejoindreSalle;
        final Finder rejoindre = find.widgetWithText(
          ActionPrincipale,
          libelleEntree,
        );
        expect(rejoindre, findsOneWidget);
        await tester.ensureVisible(rejoindre);
        await tester.tap(rejoindre);
        await tester.pumpAndSettle();

        expect(find.text('salle'), findsOneWidget);
        expect(billet, isNotNull);
        expect(billet!.sessionId, 'demo-seance-an-nour');
        expect(billet!.preparation, isFalse);
        expect(billet!.groupeId, GroupesDemonstration.anNour);
      });
    });
  }

  testWidgets('l Espace Groupe porte son propre chemin de sortie', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await tester.pumpWidget(
        hoteRoutantTcA(
          depart: CheminsTcA.espaceGroupe(GroupesDemonstration.alFatiha),
          routes: routesTcA(),
          surcharges: surchargesDemonstration(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(EspaceGroupePage), findsOneWidget);
      await tester.tap(find.text(LibellesGroupe.retour));
      await tester.pumpAndSettle();
      expect(find.byType(MesGroupesPage), findsOneWidget);
      expect(find.byType(CarteGroupe), findsWidgets);
    });
  });
}
