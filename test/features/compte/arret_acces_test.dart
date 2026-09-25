// S09-S11 « Arreter l'acces » (LT-9) : boutons TOUCHES sur le vrai routeur et
// la coquille du tuteur. Demonstration : S01 -> Gerer les acces -> Arreter
// l'acces -> profils -> S10 (consequences lues) -> case -> Confirmer -> etat
// indisponible honnete (DB-FIN-06, aucun succes). Faux port : jusqu'a S11
// avec les trois issues ; apercu indisponible ou incomplet -> Confirmer
// ferme ; production : aucune action ; double tap -> un appel ; reessai ->
// meme cle ; motif ou consequence inconnus -> jamais bruts.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/features/compte/acces_page.dart';
import 'package:rewayah_academy/features/compte/arret_acces_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/foyer/fiche/acces_page.dart';

import '../../router/support_routeur.dart';
import 'support_compte.dart';

const String _inconnuId = 'profil-hors-foyer';

/// Un faux serveur : l'apercu de la demonstration, et un arret qui rend les
/// trois issues (le motif rendu est un code brut, jamais affiche).
class _ArretRendu extends FinanceFoyerDemo {
  _ArretRendu();

  final List<(String, List<String>, String)> appels =
      <(String, List<String>, String)>[];

  static const ResultatAnnulation resultat = ResultatAnnulation(
    profils: <IssueProfil>[
      IssueProfil(profilId: DonneesDemo.aichaId, issue: IssueServeur.confirmee),
      IssueProfil(profilId: DonneesDemo.yusufId, issue: IssueServeur.enAttente),
      IssueProfil(
        profilId: _inconnuId,
        issue: IssueServeur.echouee,
        motifServeur: 'code_brut_refus',
      ),
    ],
  );

  @override
  Future<ResultatAnnulation> annulerAcces({
    required String referenceApercu,
    required List<String> profilIds,
    required String cleIdempotence,
  }) async {
    appels.add((referenceApercu, profilIds, cleIdempotence));
    return resultat;
  }
}

/// Un apercu rendu tel quel, et un arret compte.
class _ApercuFixe extends FinanceFoyerDemo {
  _ApercuFixe(this.apercu);

  final ApercuAnnulation apercu;
  int arrets = 0;

  @override
  Future<ApercuAnnulation> apercuAnnulation(List<String> profilIds) async =>
      apercu;

  @override
  Future<ResultatAnnulation> annulerAcces({
    required String referenceApercu,
    required List<String> profilIds,
    required String cleIdempotence,
  }) async {
    arrets++;
    return _ArretRendu.resultat;
  }
}

/// Un apercu indisponible (DB-FIN-05) ; un arret compte.
class _SansApercu extends FinanceFoyerDemo {
  int arrets = 0;

  @override
  Future<ApercuAnnulation> apercuAnnulation(List<String> profilIds) =>
      Future<ApercuAnnulation>.error(const CapaciteIndisponible('DB-FIN-05'));

  @override
  Future<ResultatAnnulation> annulerAcces({
    required String referenceApercu,
    required List<String> profilIds,
    required String cleIdempotence,
  }) async {
    arrets++;
    return _ArretRendu.resultat;
  }
}

/// Un arret qui attend que le test le libere : double tap et reessai.
class _ArretLent extends FinanceFoyerDemo {
  final List<String> cles = <String>[];
  Completer<ResultatAnnulation> attente = Completer<ResultatAnnulation>();

  @override
  Future<ResultatAnnulation> annulerAcces({
    required String referenceApercu,
    required List<String> profilIds,
    required String cleIdempotence,
  }) {
    cles.add(cleIdempotence);
    return attente.future;
  }
}

List<Override> _finance(PortFinanceFoyer port) => <Override>[
  portFinanceFoyerProvider.overrideWithValue(port),
];

Finder _case(int rang) => find.byType(Checkbox).at(rang);

/// Page des acces -> Arreter l'acces -> tous les profils -> S10.
Future<GoRouter> _versS10(
  WidgetTester tester,
  PortFinanceFoyer port, {
  Size taille = const Size(390, 844),
}) async {
  final GoRouter routeur = await monterCompte(
    tester,
    taille: taille,
    depart: Routes.tuteurCompteAcces,
    eleves: DonneesDemo.eleves,
    surcharges: _finance(port),
  );
  await toucher(tester, find.byKey(AccesComptePage.arreterKey));
  await toucher(tester, _case(0));
  await toucher(tester, find.byKey(ArretAccesPage.continuerKey));
  return routeur;
}

ActionPrincipale _confirmer(WidgetTester tester) =>
    tester.widget(find.byKey(ArretAccesPage.confirmerKey));

ApercuAnnulation _apercu(ConsequencesAnnulation aicha) => ApercuAnnulation(
  reference: 'test-apercu',
  profils: <ConsequencesAnnulation>[
    aicha,
    const ConsequencesAnnulation(
      profilId: DonneesDemo.yusufId,
      eligible: false,
      consequencesServeur: <String>[],
      repriseDisponible: false,
      motifServeur: 'motif_brut_inconnu',
    ),
  ],
);

void main() {
  testWidgets(
    'demo : S01 -> acces -> Arreter -> S10 -> Confirmer indisponible',
    (WidgetTester tester) async {
      final GoRouter routeur = await monterCompte(
        tester,
        depart: Routes.tuteurCompteSoldes,
        eleves: DonneesDemo.eleves,
        surcharges: _finance(const FinanceFoyerDemo()),
      );
      await toucher(tester, find.text(t.finance.soldes.gererAcces));
      expect(lieu(routeur), Routes.tuteurCompteAcces);
      expect(find.byType(AccesComptePage), findsOneWidget);

      await toucher(tester, find.byKey(AccesComptePage.arreterKey));
      expect(Uri.parse(lieu(routeur)).path, Routes.tuteurCompteArretAcces);
      expect(find.text(t.finance.arret.pourQui), findsOneWidget);
      expect(find.text(t.commun.etape.sur(n: 1, total: 2)), findsOneWidget);

      // Rien de retenu : « Voir les consequences » inerte.
      await tester.tap(find.byKey(ArretAccesPage.continuerKey));
      await stabiliser(tester);
      expect(find.text(t.finance.arret.pourQui), findsOneWidget);

      await toucher(tester, _case(0));
      await toucher(tester, find.byKey(ArretAccesPage.continuerKey));

      // S10 : les consequences rendues, en mots.
      final a = t.finance.arret;
      expect(find.text(a.consequences), findsOneWidget);
      expect(find.text(a.effets.seancesRetirees), findsNWidgets(2));
      expect(find.text(a.effets.soldeConserve), findsNWidgets(2));
      expect(find.text(a.reprisePossible), findsNWidgets(2));
      expect(find.text(a.dateEffet), findsNWidgets(2));
      expect(find.textContaining('demo_'), findsNothing);

      // Confirmer ferme tant que la case n'est pas cochee.
      expect(_confirmer(tester).onPress, isNull);
      await toucher(tester, find.byKey(ArretAccesPage.comprisKey));
      expect(_confirmer(tester).onPress, isNotNull);
      await toucher(tester, find.byKey(ArretAccesPage.confirmerKey));

      // DB-FIN-06 indisponible : dit sur place, aucun succes.
      expect(find.text(a.annulationIndisponible), findsOneWidget);
      expect(find.byKey(ArretAccesPage.confirmerKey), findsNothing);
      expect(Uri.parse(lieu(routeur)).path, Routes.tuteurCompteArretAcces);
      expect(find.byType(ResultatArretAccesPage), findsNothing);
      expect(find.text(t.finance.issues.confirmee), findsNothing);

      // Retour : S09 (selection gardee), puis la page des acces.
      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(find.text(a.pourQui), findsOneWidget);
      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurCompteAcces);
      expect(tester.takeException(), isNull);
    },
  );

  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('${taille.width.toInt()} : S10 -> Confirmer -> S11 -> acces', (
      WidgetTester tester,
    ) async {
      final _ArretRendu port = _ArretRendu();
      final GoRouter routeur = await _versS10(tester, port, taille: taille);
      await toucher(tester, find.byKey(ArretAccesPage.comprisKey));
      await toucher(tester, find.byKey(ArretAccesPage.confirmerKey));

      expect(port.appels, hasLength(1));
      expect(port.appels.single.$1, 'demo-apercu');
      expect(port.appels.single.$2, <String>[
        DonneesDemo.aichaId,
        DonneesDemo.yusufId,
      ]);
      expect(port.appels.single.$3, isNotEmpty);

      expect(lieu(routeur), Routes.tuteurCompteArretAccesResultat);
      expect(find.byType(ResultatArretAccesPage), findsOneWidget);
      final res = t.finance.arret.resultat;
      expect(find.text(res.enregistre), findsOneWidget);
      expect(find.text(t.finance.issues.confirmee), findsOneWidget);
      expect(find.text(t.finance.issues.enAttente), findsOneWidget);
      expect(find.text(t.finance.issues.echouee), findsOneWidget);
      expect(find.textContaining('code_brut'), findsNothing);

      await toucher(tester, find.byKey(ResultatArretAccesPage.accesKey));
      expect(lieu(routeur), Routes.tuteurCompteAcces);
      expect(find.byType(AccesComptePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('production : page des acces sans action', (
    WidgetTester tester,
  ) async {
    await monterCompte(tester, depart: Routes.tuteurCompteAcces);
    expect(find.byType(AccesComptePage), findsOneWidget);
    expect(find.byKey(AccesComptePage.arreterKey), findsNothing);
    expect(find.text(t.finance.arret.action), findsNothing);
  });

  testWidgets('apercu indisponible : Confirmer ferme, aucun appel', (
    WidgetTester tester,
  ) async {
    final _SansApercu port = _SansApercu();
    await monterCompte(
      tester,
      depart: Routes.tuteurCompteAcces,
      eleves: DonneesDemo.eleves,
      surcharges: _finance(port),
    );
    // Sans apercu, aucune action sur la page des acces.
    expect(find.byKey(AccesComptePage.arreterKey), findsNothing);

    // Adresse directe : l'etat le dit, la confirmation reste fermee.
    final GoRouter routeur = GoRouter.of(
      tester.element(find.byType(AccesComptePage)),
    );
    routeur.go(
      Uri(
        path: Routes.tuteurCompteArretAcces,
        queryParameters: <String, String>{'profil': DonneesDemo.aichaId},
      ).toString(),
    );
    await stabiliser(tester);
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.byKey(ArretAccesPage.comprisKey), findsNothing);
    expect(_confirmer(tester).onPress, isNull);
    await tester.tap(
      find.byKey(ArretAccesPage.confirmerKey),
      warnIfMissed: false,
    );
    await stabiliser(tester);
    expect(port.arrets, 0);
  });

  testWidgets(
    'apercu incomplet : Confirmer ferme ; codes inconnus jamais bruts',
    (WidgetTester tester) async {
      // Aicha eligible sans date d'effet et avec une consequence inconnue ;
      // Yusuf non eligible avec un motif inconnu.
      final _ApercuFixe port = _ApercuFixe(
        _apercu(
          const ConsequencesAnnulation(
            profilId: DonneesDemo.aichaId,
            eligible: true,
            consequencesServeur: <String>['consequence_brute_x'],
            repriseDisponible: false,
          ),
        ),
      );
      await _versS10(tester, port);

      final a = t.finance.arret;
      expect(find.text(a.incomplet), findsOneWidget);
      expect(find.text(a.effets.inconnu), findsOneWidget);
      expect(find.text(a.motifs.inconnu), findsOneWidget);
      expect(find.text(a.dateInconnue), findsOneWidget);
      expect(find.textContaining('brut'), findsNothing);
      expect(find.byKey(ArretAccesPage.comprisKey), findsNothing);
      expect(_confirmer(tester).onPress, isNull);
      await tester.tap(
        find.byKey(ArretAccesPage.confirmerKey),
        warnIfMissed: false,
      );
      await stabiliser(tester);
      expect(port.arrets, 0);
    },
  );

  testWidgets('apercu complet : seuls les profils eligibles sont confirmes', (
    WidgetTester tester,
  ) async {
    final _ApercuFixe port = _ApercuFixe(
      _apercu(
        ConsequencesAnnulation(
          profilId: DonneesDemo.aichaId,
          eligible: true,
          consequencesServeur: const <String>['demo_solde_conserve'],
          repriseDisponible: true,
          dateEffet: DateTime.utc(2026, 10, 1),
          soldeConserve: const SoldeProfil(
            profilId: DonneesDemo.aichaId,
            montantMineur: 1200,
            devise: FinanceFoyerDemo.devise,
          ),
        ),
      ),
    );
    await _versS10(tester, port);
    expect(find.text(t.finance.arret.incomplet), findsNothing);
    expect(find.text(t.finance.arret.motifs.inconnu), findsOneWidget);
    expect(find.textContaining('motif_brut'), findsNothing);
    await toucher(tester, find.byKey(ArretAccesPage.comprisKey));
    await toucher(tester, find.byKey(ArretAccesPage.confirmerKey));
    expect(port.arrets, 1);
    expect(find.byType(ResultatArretAccesPage), findsOneWidget);
  });

  testWidgets('double tap : un seul appel ; reessai avec la meme cle', (
    WidgetTester tester,
  ) async {
    final _ArretLent port = _ArretLent();
    await _versS10(tester, port);
    await toucher(tester, find.byKey(ArretAccesPage.comprisKey));
    final Finder confirmer = find.byKey(ArretAccesPage.confirmerKey);
    await tester.ensureVisible(confirmer);
    await tester.tap(confirmer);
    await tester.tap(confirmer, warnIfMissed: false);
    await tester.pump();
    await tester.tap(confirmer, warnIfMissed: false);
    await tester.pump();
    expect(port.cles, hasLength(1));

    port.attente.completeError(StateError('panne'));
    await stabiliser(tester);
    final Finder reessayer = find.descendant(
      of: find.byType(EtatSysteme),
      matching: find.byType(ActionPrincipale),
    );
    expect(reessayer, findsOneWidget);
    port.attente = Completer<ResultatAnnulation>();
    await toucher(tester, reessayer);
    expect(port.cles, hasLength(2));
    expect(port.cles.last, port.cles.first);
    port.attente.complete(_ArretRendu.resultat);
    await stabiliser(tester);
    expect(find.byType(ResultatArretAccesPage), findsOneWidget);
  });

  testWidgets('S11 par adresse directe : etat honnete', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterCompte(
      tester,
      depart: Routes.tuteurCompteArretAccesResultat,
      eleves: DonneesDemo.eleves,
      surcharges: _finance(const FinanceFoyerDemo()),
    );
    expect(find.byType(ResultatArretAccesPage), findsOneWidget);
    expect(find.text(t.finance.arret.resultat.perdu), findsOneWidget);
    expect(find.text(t.finance.issues.confirmee), findsNothing);
    await toucher(tester, find.byKey(ResultatArretAccesPage.accesKey));
    expect(lieu(routeur), Routes.tuteurCompteAcces);
  });

  testWidgets(
    'fiche acces -> Arreter : S10 avec ce profil, retour a la fiche',
    (WidgetTester tester) async {
      final String fiche = Routes.ficheEleveSousPage(
        DonneesDemo.aichaId,
        'acces',
      );
      final GoRouter routeur = await monterCompte(
        tester,
        depart: fiche,
        eleves: DonneesDemo.eleves,
        surcharges: _finance(const FinanceFoyerDemo()),
      );
      expect(find.byType(AccesElevePage), findsOneWidget);
      await toucher(tester, find.byKey(AccesElevePage.arreterKey));
      final Uri ici = Uri.parse(lieu(routeur));
      expect(ici.path, Routes.tuteurCompteArretAcces);
      expect(ici.queryParameters['profil'], DonneesDemo.aichaId);
      expect(ici.queryParameters['retour'], fiche);
      expect(find.text(t.finance.arret.consequences), findsOneWidget);
      expect(
        find.byKey(ArretAccesPage.profilKey(DonneesDemo.aichaId)),
        findsOneWidget,
      );
      expect(
        find.byKey(ArretAccesPage.profilKey(DonneesDemo.yusufId)),
        findsNothing,
      );

      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), fiche);
    },
  );
}
