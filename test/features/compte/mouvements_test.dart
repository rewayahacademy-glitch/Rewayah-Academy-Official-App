// S07 « Mouvements de solde » et S08 « Detail d'un mouvement » (LT-6) : sur
// le VRAI routeur et la coquille du tuteur, l'entree de S01 TOUCHEE, le filtre
// par profil, le detail et son retour, le lien vers la seance ; la production
// (DB-FIN-02 indisponible, aucune action financiere) ; un code de nature
// inconnu jamais affiche brut.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/compte/mouvements_page.dart';
import 'package:rewayah_academy/features/compte/soldes_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../../router/support_routeur.dart';
import 'support_compte.dart';

final List<Override> _demo = <Override>[
  portFinanceFoyerProvider.overrideWithValue(const FinanceFoyerDemo()),
];

/// Un serveur qui rend des codes que l'application ne connait pas.
class _CodesInconnus extends FinanceFoyerIndisponible {
  const _CodesInconnus();

  static final MouvementSolde _m = MouvementSolde(
    id: 'mvt-x',
    profilId: DonneesDemo.aichaId,
    natureServeur: 'wallet_code_brut',
    statutServeur: 'statut_code_brut',
    montantSigneMineur: 250,
    devise: 'XTS',
    date: DateTime.utc(2026, 9, 20, 9),
  );

  @override
  Future<List<MouvementSolde>> mouvements({String? profilId}) async =>
      <MouvementSolde>[_m];

  @override
  Future<MouvementSolde?> mouvement(String id) async => id == _m.id ? _m : null;
}

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

Future<GoRouter> _demoSur(WidgetTester tester, String depart, Size taille) =>
    monterCompte(
      tester,
      depart: depart,
      taille: taille,
      eleves: DonneesDemo.eleves,
      surcharges: _demo,
    );

void main() {
  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    final String nom = '${taille.width.toInt()}';

    testWidgets('$nom : S01 -> mouvements -> filtre -> detail -> retour', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _demoSur(
        tester,
        Routes.tuteurCompteSoldes,
        taille,
      );
      expect(find.byType(SoldesComptePage), findsOneWidget);

      await toucher(tester, find.text(t.finance.mouvements.voir));
      expect(lieu(routeur), Routes.tuteurCompteMouvements);
      expect(find.byType(MouvementsComptePage), findsOneWidget);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);
      // Trois mouvements par eleve fictif.
      expect(
        find.text(t.finance.mouvements.natures.recharge),
        findsNWidgets(2),
      );
      expect(
        find.text(t.finance.mouvements.natures.remiseSeance),
        findsNWidgets(2),
      );

      await toucher(
        tester,
        find.byKey(MouvementsComptePage.filtreKey(DonneesDemo.aichaId)),
      );
      expect(find.text(t.finance.mouvements.natures.recharge), findsOneWidget);
      expect(find.text(t.finance.mouvements.natures.seance), findsOneWidget);
      expect(find.textContaining('Yusuf ·'), findsNothing);
      expect(find.textContaining('Aïcha ·'), findsNWidgets(3));

      await toucher(tester, find.text(t.finance.mouvements.natures.recharge));
      final Uri ici = Uri.parse(lieu(routeur));
      expect(
        ici.path,
        Routes.mouvementPour('demo-mvt-demo-eleve-aicha-recharge'),
      );
      expect(find.byType(DetailMouvementPage), findsOneWidget);
      expect(
        find.text('+${formaterMontant(1000, FinanceFoyerDemo.devise)}'),
        findsOneWidget,
      );
      expect(find.text('Aïcha'), findsWidgets);
      expect(find.text(t.finance.mouvements.statuts.confirme), findsOneWidget);
      // Une recharge n'a pas de seance liee.
      expect(find.byKey(DetailMouvementPage.voirSeanceKey), findsNothing);

      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurCompteMouvements);
      expect(find.byType(MouvementsComptePage), findsOneWidget);

      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurCompteSoldes);
      // De retour sur S01 aux soldes lus : « Recharger » (LT-7) seulement.
      expect(find.byKey(SoldesComptePage.rechargerKey), findsOneWidget);
      for (final String interdit in <String>['Payer', 'Annuler l', 'Acheter']) {
        expect(find.textContaining(interdit), findsNothing, reason: interdit);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('demonstration : une remise liee mene au detail de la seance', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _demoSur(
      tester,
      Routes.tuteurCompteMouvements,
      const Size(390, 844),
    );
    await toucher(
      tester,
      find.byKey(MouvementsComptePage.filtreKey(DonneesDemo.yusufId)),
    );
    await toucher(tester, find.text(t.finance.mouvements.natures.remiseSeance));
    expect(find.byType(DetailMouvementPage), findsOneWidget);
    expect(
      find.text('+${formaterMontant(100, FinanceFoyerDemo.devise)}'),
      findsOneWidget,
    );

    await toucher(tester, find.byKey(DetailMouvementPage.voirSeanceKey));
    expect(
      Uri.parse(lieu(routeur)).path,
      Routes.seancePour('demo-seance-${DonneesDemo.yusufId}--7'),
    );
  });

  testWidgets('demonstration : une consommation porte le signe moins', (
    WidgetTester tester,
  ) async {
    await _demoSur(
      tester,
      Routes.mouvementPour('demo-mvt-${DonneesDemo.aichaId}-seance'),
      const Size(390, 844),
    );
    expect(
      find.text(formaterMontant(-100, FinanceFoyerDemo.devise)),
      findsOneWidget,
    );
    expect(
      find.text('+${formaterMontant(100, FinanceFoyerDemo.devise)}'),
      findsNothing,
    );
  });

  testWidgets('production : DB-FIN-02 indisponible, aucun bouton financier', (
    WidgetTester tester,
  ) async {
    await monterCompte(tester, depart: Routes.tuteurCompteMouvements);
    expect(find.byType(MouvementsComptePage), findsOneWidget);
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
    expect(find.byKey(MouvementsComptePage.filtreKey(null)), findsNothing);
    expect(find.textContaining('0,00'), findsNothing);
    _aucuneActionFinanciere();
  });

  testWidgets('production : le detail se dit indisponible', (
    WidgetTester tester,
  ) async {
    await monterCompte(tester, depart: Routes.mouvementPour('m1'));
    expect(find.byType(DetailMouvementPage), findsOneWidget);
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
    _aucuneActionFinanciere();
  });

  testWidgets('un code de nature inconnu se dit « Mouvement », jamais brut', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterCompte(
      tester,
      depart: Routes.tuteurCompteMouvements,
      eleves: DonneesDemo.eleves,
      surcharges: <Override>[
        portFinanceFoyerProvider.overrideWithValue(const _CodesInconnus()),
      ],
    );
    expect(find.text(t.finance.mouvements.natures.inconnue), findsOneWidget);
    expect(find.textContaining('code_brut'), findsNothing);

    await toucher(tester, find.text(t.finance.mouvements.natures.inconnue));
    expect(Uri.parse(lieu(routeur)).path, Routes.mouvementPour('mvt-x'));
    expect(find.text(t.finance.mouvements.natures.inconnue), findsOneWidget);
    expect(find.textContaining('code_brut'), findsNothing);
    // Statut inconnu : la ligne n'est pas rendue.
    expect(find.text(t.finance.mouvements.detail.statut), findsNothing);
  });

  testWidgets('?retour= est filtre : un retour externe est ignore', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _demoSur(
      tester,
      '${Routes.mouvementPour('demo-mvt-${DonneesDemo.aichaId}-recharge')}'
      '?retour=//exemple.test',
      const Size(390, 844),
    );
    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    expect(lieu(routeur), Routes.tuteurCompteMouvements);

    routeur.go(
      Uri(
        path: Routes.tuteurCompteMouvements,
        queryParameters: <String, String>{'retour': Routes.tuteurFoyer},
      ).toString(),
    );
    await stabiliser(tester);
    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    expect(lieu(routeur), Routes.tuteurFoyer);
  });
}
