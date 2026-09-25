// S01 « Soldes et recharges » (LT-4) : ses deux entrees TOUCHEES sur le vrai
// routeur (Compte et Foyer), l'etat de production (DB-FIN-01 indisponible,
// aucune action financiere) et la demonstration (total et une ligne par
// eleve fictif).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/resume_solde.dart';
import 'package:rewayah_academy/features/compte/acces_page.dart';
import 'package:rewayah_academy/features/compte/compte_tuteur_page.dart';
import 'package:rewayah_academy/features/compte/recharge_page.dart';
import 'package:rewayah_academy/features/compte/soldes_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';

import '../../router/support_routeur.dart';
import 'support_compte.dart';

final List<Override> _demo = <Override>[
  portFinanceFoyerProvider.overrideWithValue(const FinanceFoyerDemo()),
];

/// Aucune action financiere n'est rendue sur S01 sans soldes lus.
void _aucuneActionFinanciere() {
  for (final String interdit in <String>[
    'Recharger',
    'Payer',
    'Annuler l',
    'Acheter',
  ]) {
    expect(find.textContaining(interdit), findsNothing, reason: interdit);
  }
}

void main() {
  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    final String nom = '${taille.width.toInt()}';

    testWidgets('$nom : la ligne du Compte ouvre SoldesComptePage et revient', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterCompte(tester, taille: taille);
      await toucher(tester, find.text(t.finance.soldes.titre));

      expect(lieu(routeur), Routes.tuteurCompteSoldes);
      expect(find.byType(SoldesComptePage), findsOneWidget);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);

      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurCompte);
      expect(find.byType(CompteTuteurPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$nom : le resume du Foyer ouvre S01 et le retour y ramene', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterCompte(
        tester,
        taille: taille,
        depart: Routes.tuteurFoyer,
      );
      final Finder entree = find.descendant(
        of: find.byKey(FoyerPage.soldesKey),
        matching: find.text(t.finance.soldes.titre),
      );
      // Production : le total se dit indisponible, jamais « 0 ».
      expect(
        find.descendant(
          of: find.byKey(FoyerPage.soldesKey),
          matching: find.text(t.compte.nonDisponible),
        ),
        findsOneWidget,
      );
      await toucher(tester, entree);

      final Uri ici = Uri.parse(lieu(routeur));
      expect(ici.path, Routes.tuteurCompteSoldes);
      expect(ici.queryParameters['retour'], Routes.tuteurFoyer);
      expect(find.byType(SoldesComptePage), findsOneWidget);

      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurFoyer);
      expect(find.byType(FoyerPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('production : DB-FIN-01 indisponible, aucun bouton financier', (
    WidgetTester tester,
  ) async {
    await monterCompte(tester, depart: Routes.tuteurCompteSoldes);

    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
    expect(find.byType(ResumeSolde), findsNothing);
    expect(find.textContaining('0,00'), findsNothing);
    _aucuneActionFinanciere();
    // Seule action : la page d'acces existante, qui n'est pas financiere.
    expect(find.text(t.finance.soldes.gererAcces), findsOneWidget);
  });

  testWidgets('demonstration : total et une ligne par eleve fictif', (
    WidgetTester tester,
  ) async {
    await monterCompte(
      tester,
      depart: Routes.tuteurCompteSoldes,
      eleves: DonneesDemo.eleves,
      surcharges: _demo,
    );

    expect(find.byType(ResumeSolde), findsOneWidget);
    expect(find.text(t.finance.totalFoyer), findsOneWidget);
    expect(
      find.text(formaterMontant(2000, FinanceFoyerDemo.devise)),
      findsOneWidget,
    );
    expect(find.text('Aïcha'), findsOneWidget);
    expect(find.text('Yusuf'), findsOneWidget);
    expect(
      find.textContaining(formaterMontant(1200, FinanceFoyerDemo.devise)),
      findsOneWidget,
    );
    expect(
      find.textContaining(formaterMontant(800, FinanceFoyerDemo.devise)),
      findsOneWidget,
    );
    expect(
      find.textContaining(t.compte.tuteur.acces.pastilleActif),
      findsNWidgets(2),
    );
    expect(find.text(t.finance.totalIncomplet), findsNothing);
    // Soldes lus : « Recharger » (LT-7) est la seule action financiere.
    expect(find.byKey(SoldesComptePage.rechargerKey), findsOneWidget);
    for (final String interdit in <String>['Payer', 'Annuler l', 'Acheter']) {
      expect(find.textContaining(interdit), findsNothing, reason: interdit);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('bureau : une ligne selectionne le profil ; le panneau recharge '
      'et ouvre ses mouvements, la selection survit au retour', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterCompte(
      tester,
      depart: Routes.tuteurCompteSoldes,
      taille: const Size(1440, 900),
      eleves: DonneesDemo.eleves,
      surcharges: _demo,
    );
    final Finder panneau = find.byKey(SoldesComptePage.panneauKey);
    expect(panneau, findsOneWidget);
    // Un seul bouton principal : « Recharger » general passe en secondaire.
    expect(
      tester
          .widgetList<ActionPrincipale>(find.byType(ActionPrincipale))
          .where((ActionPrincipale a) => a.niveau == NiveauAction.principale)
          .length,
      1,
    );
    expect(
      tester
          .widget<ActionPrincipale>(find.byKey(SoldesComptePage.rechargerKey))
          .niveau,
      NiveauAction.secondaire,
    );
    // Par defaut, le premier profil lu.
    expect(
      find.descendant(
        of: panneau,
        matching: find.text(t.finance.soldeDe(prenom: 'Aïcha')),
      ),
      findsOneWidget,
    );

    await toucher(tester, find.text('Yusuf'));
    expect(
      Uri.parse(lieu(routeur)).queryParameters['profil'],
      DonneesDemo.yusufId,
    );
    expect(
      find.descendant(
        of: panneau,
        matching: find.text(formaterMontant(800, FinanceFoyerDemo.devise)),
      ),
      findsOneWidget,
    );
    expect(find.text(t.finance.soldes.selectionne), findsOneWidget);

    await toucher(tester, find.byKey(SoldesComptePage.rechargerProfilKey));
    final Uri recharge = Uri.parse(lieu(routeur));
    expect(recharge.path, Routes.tuteurCompteRecharge);
    expect(recharge.queryParameters['profil'], DonneesDemo.yusufId);
    expect(find.byType(RechargePage), findsOneWidget);

    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    expect(
      Uri.parse(lieu(routeur)).queryParameters['profil'],
      DonneesDemo.yusufId,
    );
    expect(
      find.descendant(
        of: panneau,
        matching: find.text(t.finance.soldeDe(prenom: 'Yusuf')),
      ),
      findsOneWidget,
    );

    await toucher(tester, find.byKey(SoldesComptePage.mouvementsProfilKey));
    final Uri mouvements = Uri.parse(lieu(routeur));
    expect(mouvements.path, Routes.tuteurCompteMouvements);
    expect(mouvements.queryParameters['profil'], DonneesDemo.yusufId);
    expect(tester.takeException(), isNull);
  });

  testWidgets('telephone : ni panneau ni selection', (
    WidgetTester tester,
  ) async {
    await monterCompte(
      tester,
      depart: Routes.tuteurCompteSoldes,
      eleves: DonneesDemo.eleves,
      surcharges: _demo,
    );
    expect(find.byKey(SoldesComptePage.panneauKey), findsNothing);
    expect(find.text(t.finance.soldes.selectionne), findsNothing);
  });

  testWidgets('production, bureau : aucun panneau ni action financiere', (
    WidgetTester tester,
  ) async {
    await monterCompte(
      tester,
      depart: Routes.tuteurCompteSoldes,
      taille: const Size(1440, 900),
    );
    expect(find.byKey(SoldesComptePage.panneauKey), findsNothing);
    _aucuneActionFinanciere();
  });

  testWidgets('demonstration : le Foyer resume le total rendu', (
    WidgetTester tester,
  ) async {
    await monterCompte(
      tester,
      depart: Routes.tuteurFoyer,
      eleves: DonneesDemo.eleves,
      surcharges: _demo,
    );
    expect(
      find.descendant(
        of: find.byKey(FoyerPage.soldesKey),
        matching: find.text(formaterMontant(2000, FinanceFoyerDemo.devise)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('« Gérer les accès » ouvre la page d acces existante', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterCompte(
      tester,
      depart: Routes.tuteurCompteSoldes,
    );
    await toucher(tester, find.text(t.finance.soldes.gererAcces));
    expect(lieu(routeur), Routes.compteTuteurSousPage('acces'));
    expect(find.byType(AccesComptePage), findsOneWidget);
  });
}
