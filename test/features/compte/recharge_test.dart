// S03-S04 « Recharger » (LT-7) : boutons TOUCHES sur le vrai routeur et la
// coquille du tuteur. Demonstration : S01 -> Recharger -> profils -> offres ->
// Verifier -> etat indisponible honnete (DB-FIN-03, aucun devis simule) ;
// fiche -> Recharger avec le profil preselectionne ; production : aucun
// bouton ; un faux port qui rend un devis : « Verifier » mene a S05 (LT-8).
// S05-S06 (LT-8) : faux port -> S05 (lignes et total rendus) -> Payer -> S06
// (trois issues) -> S01 ; adresse directe sans `extra` -> etat honnete ;
// paiement indisponible -> aucun succes ; double tap -> un appel ; reessai
// -> meme cle d'idempotence.

import 'dart:async';

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
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/features/compte/recharge_page.dart';
import 'package:rewayah_academy/features/compte/soldes_page.dart';
import 'package:rewayah_academy/features/compte/verifier_recharge_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/filtres_historique.dart'
    show dateCourte;

import '../../router/support_routeur.dart';
import 'support_compte.dart';

/// Un faux serveur : la demonstration, dont le devis et le paiement rendent
/// un succes (LT-8). Le total rendu n'est volontairement PAS la somme des
/// lignes : l'ecran doit afficher celui du serveur, jamais recalculer.
class _FinanceAvecDevis extends FinanceFoyerDemo {
  const _FinanceAvecDevis();

  static const String inconnuId = 'profil-hors-foyer';

  static final DevisRecharge devis = DevisRecharge(
    reference: 'test-devis',
    lignes: const <LigneDevis>[
      LigneDevis(
        profilId: DonneesDemo.aichaId,
        prixMineur: 1500,
        remiseMineure: 100,
        quantiteMineure: 1000,
      ),
      LigneDevis(
        profilId: DonneesDemo.yusufId,
        prixMineur: 1200,
        remiseMineure: 0,
        quantiteMineure: 800,
      ),
    ],
    totalMineur: 2599,
    devise: FinanceFoyerDemo.devise,
    valableJusqua: DateTime.utc(2099, 1, 15, 12),
  );

  static const ResultatRecharge resultat = ResultatRecharge(
    referencePaiement: 'PAI-TEST-42',
    paiement: IssueServeur.confirmee,
    attributions: <IssueProfil>[
      IssueProfil(profilId: DonneesDemo.aichaId, issue: IssueServeur.confirmee),
      IssueProfil(profilId: DonneesDemo.yusufId, issue: IssueServeur.enAttente),
      IssueProfil(profilId: inconnuId, issue: IssueServeur.echouee),
    ],
  );

  static List<ChoixRecharge> recus = <ChoixRecharge>[];
  static List<(String, String)> paiements = <(String, String)>[];

  @override
  Future<DevisRecharge> devisRecharge(List<ChoixRecharge> choix) async {
    recus = choix;
    return devis;
  }

  @override
  Future<ResultatRecharge> payer({
    required String referenceDevis,
    required String cleIdempotence,
  }) async {
    paiements.add((referenceDevis, cleIdempotence));
    return resultat;
  }
}

/// Un devis rendu, mais le paiement reste celui de la demonstration :
/// indisponible (DB-FIN-04).
class _DevisSansPaiement extends FinanceFoyerDemo {
  const _DevisSansPaiement();

  static List<String> appels = <String>[];

  @override
  Future<DevisRecharge> devisRecharge(List<ChoixRecharge> choix) async =>
      _FinanceAvecDevis.devis;

  @override
  Future<ResultatRecharge> payer({
    required String referenceDevis,
    required String cleIdempotence,
  }) {
    appels.add(cleIdempotence);
    return super.payer(
      referenceDevis: referenceDevis,
      cleIdempotence: cleIdempotence,
    );
  }
}

/// Un devis qui attend que le test le libere : garde de « Verifier »
/// (constat 14).
class _DevisLent extends FinanceFoyerDemo {
  _DevisLent();

  int appels = 0;
  final Completer<DevisRecharge> attente = Completer<DevisRecharge>();

  @override
  Future<DevisRecharge> devisRecharge(List<ChoixRecharge> choix) {
    appels++;
    return attente.future;
  }
}

/// Un paiement qui attend que le test le libere, puis echoue (hors
/// indisponibilite) : double tap et reessai.
class _PaiementLent extends FinanceFoyerDemo {
  _PaiementLent();

  final List<String> cles = <String>[];
  Completer<ResultatRecharge> attente = Completer<ResultatRecharge>();

  @override
  Future<ResultatRecharge> payer({
    required String referenceDevis,
    required String cleIdempotence,
  }) {
    cles.add(cleIdempotence);
    return attente.future;
  }
}

/// Un devis dont la date de validite est passee selon l'horloge locale ; le
/// serveur refuse le paiement comme expire (constat LT-R 2).
class _DevisExpire extends FinanceFoyerDemo {
  _DevisExpire();

  int paiements = 0;

  static final DevisRecharge devis = DevisRecharge(
    reference: 'test-devis-ancien',
    lignes: _FinanceAvecDevis.devis.lignes,
    totalMineur: 2599,
    devise: FinanceFoyerDemo.devise,
    valableJusqua: DateTime.utc(2000),
  );

  @override
  Future<ResultatRecharge> payer({
    required String referenceDevis,
    required String cleIdempotence,
  }) {
    paiements++;
    return Future<ResultatRecharge>.error(const DevisExpire());
  }
}

Future<GoRouter> _surVerifier(WidgetTester tester, PortFinanceFoyer p) async {
  final GoRouter routeur = await monterCompte(
    tester,
    depart: Routes.tuteurCompteSoldes,
    eleves: DonneesDemo.eleves,
    surcharges: _finance(p),
  );
  routeur.go(
    Routes.tuteurCompteRechargeVerifier,
    extra: _FinanceAvecDevis.devis,
  );
  await stabiliser(tester);
  return routeur;
}

List<Override> _finance(PortFinanceFoyer port) => <Override>[
  portFinanceFoyerProvider.overrideWithValue(port),
];

Finder _case(int rang) => find.byType(Checkbox).at(rang);

bool? _cochee(WidgetTester tester, int rang) =>
    tester.widget<Checkbox>(_case(rang)).value;

String _offre(String id) => 'demo-offre-$id';

void main() {
  testWidgets('devis expire : dit par le refus du serveur, pas l\'horloge', (
    WidgetTester tester,
  ) async {
    final _DevisExpire port = _DevisExpire();
    final GoRouter routeur = await monterCompte(
      tester,
      depart: Routes.tuteurCompteSoldes,
      eleves: DonneesDemo.eleves,
      surcharges: _finance(port),
    );
    routeur.go(Routes.tuteurCompteRechargeVerifier, extra: _DevisExpire.devis);
    await stabiliser(tester);
    final v = t.finance.recharge.verification;
    // Date passee selon l'horloge locale : « Payer » reste propose.
    expect(find.text(v.expire), findsNothing);
    expect(find.byKey(VerifierRechargePage.payerKey), findsOneWidget);
    await toucher(tester, find.byKey(VerifierRechargePage.payerKey));
    expect(port.paiements, 1);
    // Le refus du serveur ouvre l'etat « devis expire », sans « Payer ».
    expect(find.text(v.expire), findsOneWidget);
    expect(find.byKey(VerifierRechargePage.reprendreKey), findsOneWidget);
    expect(find.byKey(VerifierRechargePage.payerKey), findsNothing);
    expect(find.byType(ResultatRechargePage), findsNothing);
  });

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

  testWidgets('« Verifier » en double tap : une seule demande de devis', (
    WidgetTester tester,
  ) async {
    final _DevisLent finance = _DevisLent();
    await monterCompte(
      tester,
      depart: Routes.tuteurCompteSoldes,
      eleves: DonneesDemo.eleves,
      surcharges: _finance(finance),
    );
    await toucher(tester, find.byKey(SoldesComptePage.rechargerKey));
    await toucher(tester, _case(1));
    await toucher(tester, find.byKey(RechargePage.continuerKey));
    await toucher(
      tester,
      find.byKey(RechargePage.offreKey(_offre(DonneesDemo.aichaId))),
    );
    await tester.tap(find.byKey(RechargePage.verifierKey));
    await tester.pump();
    await tester.tap(find.byKey(RechargePage.verifierKey), warnIfMissed: false);
    await tester.pump();
    expect(finance.appels, 1);

    finance.attente.complete(_FinanceAvecDevis.devis);
    await stabiliser(tester);
    expect(finance.appels, 1);
    expect(tester.takeException(), isNull);
  });

  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    final String nom = '${taille.width.toInt()}';

    testWidgets('$nom : S01 -> ... -> S05 -> Payer -> S06 -> S01', (
      WidgetTester tester,
    ) async {
      _FinanceAvecDevis.paiements = <(String, String)>[];
      final GoRouter routeur = await monterCompte(
        tester,
        taille: taille,
        depart: Routes.tuteurCompteSoldes,
        eleves: DonneesDemo.eleves,
        surcharges: _finance(const _FinanceAvecDevis()),
      );
      await toucher(tester, find.byKey(SoldesComptePage.rechargerKey));
      await toucher(tester, _case(0));
      await toucher(tester, find.byKey(RechargePage.continuerKey));
      for (final String id in <String>[
        DonneesDemo.aichaId,
        DonneesDemo.yusufId,
      ]) {
        await toucher(tester, find.byKey(RechargePage.offreKey(_offre(id))));
      }
      await toucher(tester, find.byKey(RechargePage.verifierKey));

      // S05 : lignes, total et validite tels que rendus.
      expect(lieu(routeur), Routes.tuteurCompteRechargeVerifier);
      expect(find.byType(VerifierRechargePage), findsOneWidget);
      const String d = FinanceFoyerDemo.devise;
      final v = t.finance.recharge.verification;
      expect(find.text(v.titre), findsWidgets);
      expect(find.text('Aïcha'), findsWidgets);
      expect(find.text(formaterMontant(1500, d)), findsOneWidget);
      expect(find.text(formaterMontant(100, d)), findsOneWidget);
      expect(find.text(formaterMontant(1000, d)), findsOneWidget);
      expect(find.text(formaterMontant(1200, d)), findsOneWidget);
      expect(find.text(formaterMontant(800, d)), findsOneWidget);
      expect(find.text(v.aucuneRemise), findsOneWidget);
      expect(find.text(formaterMontant(2599, d)), findsOneWidget);
      expect(find.text(formaterMontant(2600, d)), findsNothing);
      expect(
        find.text(
          v.valableJusqua(
            date: dateCourte(_FinanceAvecDevis.devis.valableJusqua.toLocal()),
          ),
        ),
        findsOneWidget,
      );

      await toucher(tester, find.byKey(VerifierRechargePage.payerKey));
      expect(_FinanceAvecDevis.paiements, hasLength(1));
      expect(_FinanceAvecDevis.paiements.single.$1, 'test-devis');
      expect(_FinanceAvecDevis.paiements.single.$2, isNotEmpty);

      // S06 : l'issue du paiement et de chaque profil, en mots.
      expect(lieu(routeur), Routes.tuteurCompteRechargeResultat);
      expect(find.byType(ResultatRechargePage), findsOneWidget);
      final res = t.finance.recharge.resultat;
      expect(find.text(res.paiementConfirme), findsOneWidget);
      expect(
        find.text(res.reference(reference: 'PAI-TEST-42')),
        findsOneWidget,
      );
      expect(find.text(t.finance.issues.confirmee), findsOneWidget);
      expect(find.text(t.finance.issues.enAttente), findsOneWidget);
      expect(find.text(t.finance.issues.echouee), findsOneWidget);
      expect(find.text(t.finance.profilSansPrenom), findsWidgets);

      await toucher(tester, find.byKey(ResultatRechargePage.soldesKey));
      expect(lieu(routeur), Routes.tuteurCompteSoldes);
      expect(find.byType(SoldesComptePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('demo : S05 et S06 par adresse directe, etat honnete', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterCompte(
      tester,
      depart: Routes.tuteurCompteRechargeVerifier,
      eleves: DonneesDemo.eleves,
      surcharges: _finance(const FinanceFoyerDemo()),
    );
    expect(find.byType(VerifierRechargePage), findsOneWidget);
    expect(find.text(t.finance.recharge.verification.perdu), findsOneWidget);
    expect(find.byKey(VerifierRechargePage.payerKey), findsNothing);
    await toucher(tester, find.text(t.finance.recharge.verification.reprendre));
    expect(Uri.parse(lieu(routeur)).path, Routes.tuteurCompteRecharge);

    routeur.go(Routes.tuteurCompteRechargeResultat);
    await stabiliser(tester);
    expect(find.byType(ResultatRechargePage), findsOneWidget);
    expect(find.text(t.finance.recharge.resultat.perdu), findsOneWidget);
    expect(find.text(t.finance.issues.confirmee), findsNothing);
    await toucher(tester, find.byKey(ResultatRechargePage.soldesKey));
    expect(lieu(routeur), Routes.tuteurCompteSoldes);
  });

  testWidgets('paiement indisponible : etat honnete, aucun succes', (
    WidgetTester tester,
  ) async {
    _DevisSansPaiement.appels = <String>[];
    final GoRouter routeur = await _surVerifier(
      tester,
      const _DevisSansPaiement(),
    );
    await toucher(tester, find.byKey(VerifierRechargePage.payerKey));

    expect(_DevisSansPaiement.appels, hasLength(1));
    final v = t.finance.recharge.verification;
    expect(find.text(v.paiementIndisponible), findsOneWidget);
    expect(find.byKey(VerifierRechargePage.payerKey), findsNothing);
    expect(lieu(routeur), Routes.tuteurCompteRechargeVerifier);
    expect(find.byType(ResultatRechargePage), findsNothing);
    expect(find.text(t.finance.issues.confirmee), findsNothing);
  });

  testWidgets('double tap : un seul appel ; reessai avec la meme cle', (
    WidgetTester tester,
  ) async {
    final _PaiementLent port = _PaiementLent();
    await _surVerifier(tester, port);
    final Finder payer = find.byKey(VerifierRechargePage.payerKey);
    await tester.ensureVisible(payer);
    await tester.tap(payer);
    await tester.tap(payer, warnIfMissed: false);
    await tester.pump();
    await tester.tap(payer, warnIfMissed: false);
    await tester.pump();
    expect(port.cles, hasLength(1));

    port.attente.completeError(StateError('panne'));
    await stabiliser(tester);
    final Finder reessayer = find.descendant(
      of: find.byType(EtatSysteme),
      matching: find.byType(ActionPrincipale),
    );
    expect(reessayer, findsOneWidget);
    port.attente = Completer<ResultatRecharge>();
    await toucher(tester, reessayer);
    expect(port.cles, hasLength(2));
    expect(port.cles.last, port.cles.first);
    port.attente.complete(_FinanceAvecDevis.resultat);
    await stabiliser(tester);
    expect(find.byType(ResultatRechargePage), findsOneWidget);
  });
}
