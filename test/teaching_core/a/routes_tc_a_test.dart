import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';
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
      await tester.tap(find.text('Groupe Al-Fatiha'));
      await tester.pumpAndSettle();

      expect(find.byType(EspaceGroupePage), findsOneWidget);
      final EspaceGroupePage espace = tester.widget<EspaceGroupePage>(
        find.byType(EspaceGroupePage),
      );
      expect(espace.groupeId, GroupesDemonstration.alFatiha);
    });
  });

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
