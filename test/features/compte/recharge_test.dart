// S03-S04 « Recharger » (LT-7) : boutons TOUCHES sur le vrai routeur et la
// coquille du tuteur. Demonstration : S01 -> Recharger -> profils -> offres ->
// Verifier -> etat indisponible honnete (DB-FIN-03, aucun devis simule) ;
// fiche -> Recharger avec le profil preselectionne ; production : aucun
// bouton ; un faux port qui rend un devis : « Verifier » mene a S05 (LT-8).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/compte/recharge_page.dart';
import 'package:rewayah_academy/features/compte/soldes_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';

import '../../router/support_routeur.dart';
import 'support_compte.dart';

/// La demonstration, dont le devis rend un succes : pour prouver la
/// navigation vers S05 seulement (l'ecran vient en LT-8).
class _FinanceAvecDevis extends FinanceFoyerDemo {
  const _FinanceAvecDevis();

  static final DevisRecharge devis = DevisRecharge(
    reference: 'test-devis',
    lignes: const <LigneDevis>[],
    totalMineur: 0,
    devise: FinanceFoyerDemo.devise,
    valableJusqua: DateTime.utc(2026, 9, 30),
  );

  static List<ChoixRecharge> recus = <ChoixRecharge>[];

  @override
  Future<DevisRecharge> devisRecharge(List<ChoixRecharge> choix) async {
    recus = choix;
    return devis;
  }
}

List<Override> _finance(PortFinanceFoyer port) => <Override>[
  portFinanceFoyerProvider.overrideWithValue(port),
];

Finder _case(int rang) => find.byType(Checkbox).at(rang);

bool? _cochee(WidgetTester tester, int rang) =>
    tester.widget<Checkbox>(_case(rang)).value;

String _offre(String id) => 'demo-offre-$id';

void main() {
  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    final String nom = '${taille.width.toInt()}';

    testWidgets('$nom : S01 -> profils -> offres -> Verifier indisponible', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterCompte(
        tester,
        taille: taille,
        depart: Routes.tuteurCompteSoldes,
        eleves: DonneesDemo.eleves,
        surcharges: _finance(const FinanceFoyerDemo()),
      );

      await toucher(tester, find.byKey(SoldesComptePage.rechargerKey));
      expect(Uri.parse(lieu(routeur)).path, Routes.tuteurCompteRecharge);
      expect(find.byType(RechargePage), findsOneWidget);
      expect(find.text(t.finance.recharge.pourQui), findsOneWidget);
      expect(find.text(t.commun.etape.sur(n: 1, total: 2)), findsOneWidget);

      // Rien de retenu : « Continuer » inerte.
      await tester.tap(find.byKey(RechargePage.continuerKey));
      await stabiliser(tester);
      expect(find.text(t.finance.recharge.pourQui), findsOneWidget);

      // « Tout selectionner », puis un profil retire et remis.
      await toucher(tester, _case(0));
      expect(_cochee(tester, 1), isTrue);
      expect(_cochee(tester, 2), isTrue);
      await toucher(tester, _case(1));
      expect(_cochee(tester, 1), isFalse);
      expect(_cochee(tester, 0), isNull);
      await toucher(tester, _case(1));
      expect(_cochee(tester, 0), isTrue);

      await toucher(tester, find.byKey(RechargePage.continuerKey));
      expect(find.text(t.finance.recharge.quelle), findsOneWidget);
      expect(find.text(t.commun.etape.sur(n: 2, total: 2)), findsOneWidget);
      // Les montants rendus par le serveur, tels quels.
      expect(
        find.byKey(RechargePage.offreKey(_offre(DonneesDemo.aichaId))),
        findsOneWidget,
      );

      await toucher(
        tester,
        find.byKey(RechargePage.offreKey(_offre(DonneesDemo.aichaId))),
      );
      await toucher(
        tester,
        find.byKey(RechargePage.offreKey(_offre(DonneesDemo.yusufId))),
      );
      await toucher(tester, find.byKey(RechargePage.verifierKey));

      // Devis indisponible (DB-FIN-03) : dit sur place, rien de simule.
      expect(find.text(t.finance.recharge.devisIndisponible), findsOneWidget);
      expect(Uri.parse(lieu(routeur)).path, Routes.tuteurCompteRecharge);
      expect(find.byKey(RechargePage.verifierKey), findsNothing);

      // Retour de l'etape 2 : l'etape 1, selection gardee.
      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(find.text(t.finance.recharge.pourQui), findsOneWidget);
      expect(_cochee(tester, 0), isTrue);

      // Retour de l'etape 1 : S01.
      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurCompteSoldes);
      expect(find.byType(SoldesComptePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('fiche -> Recharger : le profil est preselectionne', (
    WidgetTester tester,
  ) async {
    final String fiche = Routes.ficheElevePour(DonneesDemo.aichaId);
    final GoRouter routeur = await monterCompte(
      tester,
      depart: fiche,
      eleves: DonneesDemo.eleves,
      surcharges: _finance(const FinanceFoyerDemo()),
    );

    await toucher(tester, find.byKey(FicheElevePage.rechargerKey));
    final Uri ici = Uri.parse(lieu(routeur));
    expect(ici.path, Routes.tuteurCompteRecharge);
    expect(ici.queryParameters['profil'], DonneesDemo.aichaId);
    expect(ici.queryParameters['retour'], fiche);
    expect(_cochee(tester, 1), isTrue);
    expect(_cochee(tester, 2), isFalse);

    await toucher(tester, find.byKey(RechargePage.continuerKey));
    expect(
      find.byKey(RechargePage.offreKey(_offre(DonneesDemo.aichaId))),
      findsOneWidget,
    );
    expect(
      find.byKey(RechargePage.offreKey(_offre(DonneesDemo.yusufId))),
      findsNothing,
    );

    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    expect(lieu(routeur), fiche);
    expect(find.byType(FicheElevePage), findsOneWidget);
  });

  testWidgets('production : S01 sans bouton Recharger', (
    WidgetTester tester,
  ) async {
    await monterCompte(tester, depart: Routes.tuteurCompteSoldes);
    expect(find.byKey(SoldesComptePage.rechargerKey), findsNothing);
    expect(find.text(t.finance.recharge.action), findsNothing);
  });

  testWidgets('production : l adresse directe dit l indisponibilite', (
    WidgetTester tester,
  ) async {
    await monterCompte(tester, depart: Routes.tuteurCompteRecharge);
    expect(find.byType(RechargePage), findsOneWidget);
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('un devis rendu : « Verifier » mene a S05 avec le devis', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterCompte(
      tester,
      depart: Routes.tuteurCompteSoldes,
      eleves: DonneesDemo.eleves,
      surcharges: _finance(const _FinanceAvecDevis()),
    );
    await toucher(tester, find.byKey(SoldesComptePage.rechargerKey));
    await toucher(tester, _case(1));
    await toucher(tester, find.byKey(RechargePage.continuerKey));
    await toucher(
      tester,
      find.byKey(RechargePage.offreKey(_offre(DonneesDemo.aichaId))),
    );
    await toucher(tester, find.byKey(RechargePage.verifierKey));

    expect(_FinanceAvecDevis.recus, hasLength(1));
    expect(_FinanceAvecDevis.recus.single.profilId, DonneesDemo.aichaId);
    expect(_FinanceAvecDevis.recus.single.offreId, _offre(DonneesDemo.aichaId));
    expect(lieu(routeur), Routes.tuteurCompteRechargeVerifier);
    expect(
      routeur.routerDelegate.currentConfiguration.extra,
      same(_FinanceAvecDevis.devis),
    );
  });
}
