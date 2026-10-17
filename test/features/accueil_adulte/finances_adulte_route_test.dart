// Lot F1 : les finances de l'eleve adulte autonome sur leur route reelle
// (`/eleve/finances`), atteintes depuis l'Accueil adulte en un geste, sur le
// VRAI routeur. En production (aucun double des finances), la page dit que
// rien n'est encore publie, sans bouton ni chiffre. Contre-epreuve : un
// compte eleve sans la capacite « eleve autonome » n'y entre pas.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_adulte/routes_accueil_adulte.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mes_finances_page.dart';

import '../../router/support_routeur.dart' show lieu, stabiliser;
import 'support_accueil_adulte_route.dart';

void main() {
  test('garde : la capacite « eleve autonome » seule ouvre ses finances', () {
    expect(redirectionFinancesAdulte(eleveAutonome: true), isNull);
    expect(redirectionFinancesAdulte(eleveAutonome: false), Routes.eleve);
  });

  testWidgets('production : la carte reste sous l\'accueil indisponible et '
      'ouvre ses finances, qui disent « pas encore publie »', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterAccueilAdulteReel(
      tester,
      surcharges: surchargesAccueilAdulte(),
      depart: Routes.eleve,
    );
    expect(lieu(routeur), Routes.eleveAdulte);
    final Finder carte = find.byKey(AccueilAdultePage.financesKey);
    expect(carte, findsOneWidget);

    await tester.ensureVisible(carte);
    await tester.tap(carte);
    await stabiliser(tester);

    expect(lieu(routeur), Routes.eleveFinances);
    expect(find.byType(MesFinancesPage), findsOneWidget);
    // La destination Accueil reste allumee.
    expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 0);
    final EtatSysteme etat = tester.widget<EtatSysteme>(
      find.byType(EtatSysteme),
    );
    expect(etat.nature, NatureEtat.indisponible);
    expect(find.text(t.adulte.finances.indisponibleTitre), findsOneWidget);
    expect(find.text(t.adulte.finances.indisponiblePhrase), findsOneWidget);
    // Ni « Recharger », ni « Reessayer », ni chiffre invente.
    expect(find.byType(ActionPrincipale), findsNothing);
    expect(find.text(t.adulte.paiements.recharger), findsNothing);

    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    expect(lieu(routeur), Routes.eleveAdulte);
  });

  testWidgets('ses mouvements : page reelle, indisponible en production', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterAccueilAdulteReel(
      tester,
      surcharges: surchargesAccueilAdulte(),
      depart: Routes.eleveFinancesMouvements,
    );
    expect(lieu(routeur), Routes.eleveFinancesMouvements);
    expect(find.byType(MesMouvementsPage), findsOneWidget);
    expect(
      find.text(t.adulte.finances.mouvementsIndisponiblePhrase),
      findsOneWidget,
    );
  });

  testWidgets('contre-epreuve : un compte eleve sans la capacite « eleve '
      'autonome » est ramene a son accueil', (WidgetTester tester) async {
    final GoRouter routeur = await monterAccueilAdulteReel(
      tester,
      surcharges: surchargesAccueilAdulte(),
      depart: Routes.eleveFinances,
      role: AppRole.student,
      autonome: false,
    );
    expect(lieu(routeur), Routes.eleve);
    expect(find.byType(MesFinancesPage), findsNothing);
  });
}
