// DELEG-FIN-1 (decision du directeur du 11/10, spec V1 §21.2 a §21.4) : le
// controle de la Direction sur les delegations du Comptable.
//
// - suspension immediate de toutes les delegations (confirmation, une cle
//   par demande, jamais de succes avant la reponse, « non confirme » sur
//   echec) ;
// - expiration (etat rendu par la source, jamais deduit), renouvellement ;
// - sorties retenues par le delai de securite : liste, annulation
//   confirmee, cinq etats (chargement, contenu, vide, erreur, hors ligne) et
//   « pas encore disponible » ;
// - exceptions : coffres autorises, beneficiaires exclus, plafond plus bas
//   que la politique generale (jamais plus haut) ; rendues au brouillon ;
// - cote Comptable : la raison rendue par la source est dite, jamais
//   deduite ;
// - 320 px, texte x2, LTR et RTL.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_beneficiaires_paiement.dart';
import 'package:rewayah_academy/core/capacites/port_delegation_finance.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/pastilles_comptable.dart';
import 'package:rewayah_academy/features/admin_finance/reserve_delegation/controle_delegation.dart';
import 'package:rewayah_academy/features/admin_finance/reserve_delegation/exceptions_delegation.dart';
import 'package:rewayah_academy/features/admin_finance/reserve_delegation/finance_delegation_policy_panel.dart';
import 'package:rewayah_academy/features/admin_finance/reserve_delegation/sorties_en_attente.dart';
import 'package:rewayah_academy/features/comptable/paiements/paiements_donnees.dart';
import 'package:rewayah_academy/features/demo/comptable/beneficiaires_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/direction_demo.dart';

import '../../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../../support/aucun_mot_coupe.dart';
import 'support_direction.dart';

final d = t.comptable.direction.delegationPanneau;

/// Une delegation fraiche par test, la sienne : aucun etat ne fuit.
class _Banc {
  _Banc({this.echecControle = false, this.echecSorties = false})
    : source = DelegationFinanceDemo() {
    controle = _Controle(source, this);
  }

  final DelegationFinanceDemo source;
  late final _Controle controle;
  final bool echecControle;
  final bool echecSorties;
  final List<String> cles = <String>[];
  BrouillonDelegationFinance? dernierBrouillon;

  List<Override> surcharges() => <Override>[
    portDelegationFinanceProvider.overrideWithValue(_Enregistreur(this)),
    portControleDelegationProvider.overrideWithValue(controle),
    portBeneficiairesPaiementProvider.overrideWithValue(
      const BeneficiairesPaiementDemo(),
    ),
  ];
}

class _Enregistreur implements PortDelegationFinance {
  _Enregistreur(this.banc);
  final _Banc banc;

  @override
  Future<PolitiqueDelegationFinance> politique() => banc.source.politique();

  @override
  Future<PolitiqueDelegationFinance> enregistrer({
    required BrouillonDelegationFinance brouillon,
    required String cleIdempotence,
  }) {
    banc.dernierBrouillon = brouillon;
    return banc.source.enregistrer(
      brouillon: brouillon,
      cleIdempotence: cleIdempotence,
    );
  }

  @override
  Future<List<EntreeJournal>> journal() => banc.source.journal();
}

class _Controle implements PortControleDelegation {
  _Controle(this.source, this.banc);
  final DelegationFinanceDemo source;
  final _Banc banc;

  @override
  Future<PolitiqueDelegationFinance> suspendreToutes({
    required String cleIdempotence,
  }) async {
    banc.cles.add(cleIdempotence);
    if (banc.echecControle) throw StateError('reseau');
    return source.suspendreToutes(cleIdempotence: cleIdempotence);
  }

  @override
  Future<PolitiqueDelegationFinance> renouveler({
    required String cleIdempotence,
  }) async {
    banc.cles.add(cleIdempotence);
    if (banc.echecControle) throw StateError('reseau');
    return source.renouveler(cleIdempotence: cleIdempotence);
  }

  @override
  Future<List<SortieEnAttente>> sortiesEnAttente() async {
    if (banc.echecSorties) throw StateError('reseau');
    return source.sortiesEnAttente();
  }

  @override
  Future<void> annulerSortie({
    required String sortieId,
    required String cleIdempotence,
  }) async {
    banc.cles.add(cleIdempotence);
    if (banc.echecControle) throw StateError('reseau');
    return source.annulerSortie(
      sortieId: sortieId,
      cleIdempotence: cleIdempotence,
    );
  }
}

class _SortiesVides extends DelegationFinanceDemo {
  @override
  Future<List<SortieEnAttente>> sortiesEnAttente() async =>
      const <SortieEnAttente>[];
}

class _SortiesEnChargement extends DelegationFinanceDemo {
  final Completer<List<SortieEnAttente>> attente =
      Completer<List<SortieEnAttente>>();

  @override
  Future<List<SortieEnAttente>> sortiesEnAttente() => attente.future;
}

Future<void> _monter(
  WidgetTester tester,
  List<Override> surcharges, {
  Size taille = const Size(900, 3200),
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
  bool horsLigne = false,
  Widget panneau = const FinanceDelegationPolicyPanelBloc(),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteDirection(
      panneau,
      surcharges: surcharges,
      echelle: echelle,
      sens: sens,
      horsLigne: horsLigne,
    ),
  );
  await tester.pumpAndSettle();
}

Finder _cle(Key cle) => find.byKey(cle);

Future<void> _appuyer(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('Suspension immediate', () {
    testWidgets('un geste confirme : la bande le dit, le bouton s en va', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      expect(_cle(ControleDelegation.cleSuspendre), findsOneWidget);
      expect(_cle(ControleDelegation.cleBandeSuspendue), findsNothing);
      await _appuyer(tester, _cle(ControleDelegation.cleSuspendre));
      // La confirmation dit l'effet avant le choix.
      expect(find.text(d.suspendreConfirmerPhrase), findsOneWidget);
      await _appuyer(tester, find.text(d.suspendreConfirmer));
      expect(banc.cles, hasLength(1));
      expect(_cle(ControleDelegation.cleBandeSuspendue), findsOneWidget);
      expect(_cle(ControleDelegation.cleSuspendre), findsNothing);
      // Le mot de l'etat est ecrit, pas seulement une couleur.
      expect(find.text(d.etatSuspendue), findsWidgets);
    });

    testWidgets('« Garder les delegations » : rien ne part', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      await _appuyer(tester, _cle(ControleDelegation.cleSuspendre));
      await _appuyer(tester, find.text(d.suspendreGarder));
      expect(banc.cles, isEmpty);
      expect(_cle(ControleDelegation.cleSuspendre), findsOneWidget);
    });

    testWidgets('echec : « non confirme », la meme cle au second essai', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc(echecControle: true);
      await _monter(tester, banc.surcharges());
      for (int i = 0; i < 2; i++) {
        await _appuyer(tester, _cle(ControleDelegation.cleSuspendre));
        await _appuyer(tester, find.text(d.suspendreConfirmer));
      }
      expect(find.text(d.suspendueEchec), findsOneWidget);
      expect(_cle(ControleDelegation.cleBandeSuspendue), findsNothing);
      expect(banc.cles, hasLength(2));
      expect(banc.cles.first, banc.cles.last, reason: 'meme demande');
    });
  });

  group('Expiration', () {
    testWidgets('la date, la duree et le delai sont rendus par la source', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      expect(find.textContaining('Expire le'), findsOneWidget);
      expect(find.text(d.etatActive), findsOneWidget);
      expect(
        find.textContaining(d.renouvelablePour(jours: 90)),
        findsOneWidget,
      );
      expect(find.textContaining(d.sortiesDelai(heures: 24)), findsOneWidget);
    });

    testWidgets('renouveler : la cle part, la date change, succes dit apres', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      final PolitiqueDelegationFinance avant = await banc.source.politique();
      await _appuyer(tester, _cle(ControleDelegation.cleRenouveler));
      final PolitiqueDelegationFinance apres = await banc.source.politique();
      expect(banc.cles, hasLength(1));
      expect(apres.expireLe, isNot(avant.expireLe));
      expect(find.text(d.renouvelee), findsOneWidget);
    });

    testWidgets('renouveler en echec : « non confirme »', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc(echecControle: true);
      await _monter(tester, banc.surcharges());
      await _appuyer(tester, _cle(ControleDelegation.cleRenouveler));
      expect(find.text(d.renouvelerEchec), findsOneWidget);
      expect(find.text(d.renouvelee), findsNothing);
    });

    testWidgets('l etat vient de la source : expiree se dit « Expiree »', (
      WidgetTester tester,
    ) async {
      final PolitiqueDelegationFinance expiree = PolitiqueDelegationFinance(
        version: '9',
        paiementsStandardsAutorises: true,
        remboursementStandardAutorise: true,
        alimentationReserveAutorisee: true,
        retraitReserveInterdit: true,
        premierPaiementSecondeValidation: true,
        coordonneesRecentesSecondeValidation: true,
        autoPayoutInterdit: true,
        montantManuelInterdit: true,
        politiqueTarifaireInterdite: true,
        etat: EtatDelegation.expiree,
        expireLe: DateTime(2026, 1, 1),
      );
      await _monter(tester, <Override>[
        portControleDelegationProvider.overrideWithValue(
          _Controle(DelegationFinanceDemo(), _Banc()),
        ),
      ], panneau: ControleDelegation(politique: expiree));
      expect(find.text(d.etatExpiree), findsOneWidget);
    });
  });

  group('Sorties en attente (delai de securite)', () {
    testWidgets('contenu : deux sorties, chacune annulable', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      expect(_cle(SortiesEnAttente.cleAnnuler('sortie-1')), findsOneWidget);
      expect(_cle(SortiesEnAttente.cleAnnuler('sortie-2')), findsOneWidget);
      expect(find.text('Sayyid Youssouf Diallo'), findsOneWidget);
    });

    testWidgets('annuler : confirmation, puis la sortie disparait', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      await _appuyer(tester, _cle(SortiesEnAttente.cleAnnuler('sortie-1')));
      expect(find.text(d.sortieAnnulerTitre), findsOneWidget);
      // Garder : rien ne part.
      await _appuyer(tester, find.text(d.sortieGarder));
      expect(banc.cles, isEmpty);
      await _appuyer(tester, _cle(SortiesEnAttente.cleAnnuler('sortie-1')));
      await _appuyer(tester, find.text(d.sortieAnnulerConfirmer));
      expect(banc.cles, hasLength(1));
      expect(_cle(SortiesEnAttente.cleAnnuler('sortie-1')), findsNothing);
      expect(_cle(SortiesEnAttente.cleAnnuler('sortie-2')), findsOneWidget);
      expect(find.text(d.sortieAnnulee), findsOneWidget);
    });

    testWidgets('annulation en echec : « non confirmee », la sortie reste', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc(echecControle: true);
      await _monter(tester, banc.surcharges());
      await _appuyer(tester, _cle(SortiesEnAttente.cleAnnuler('sortie-1')));
      await _appuyer(tester, find.text(d.sortieAnnulerConfirmer));
      expect(find.text(d.sortieAnnulationEchec), findsOneWidget);
      expect(_cle(SortiesEnAttente.cleAnnuler('sortie-1')), findsOneWidget);
    });

    testWidgets('vide : une phrase, aucun bouton', (WidgetTester tester) async {
      final _SortiesVides vide = _SortiesVides();
      await _monter(tester, <Override>[
        portDelegationFinanceProvider.overrideWithValue(vide),
        portControleDelegationProvider.overrideWithValue(vide),
        portBeneficiairesPaiementProvider.overrideWithValue(
          const BeneficiairesPaiementDemo(),
        ),
      ]);
      expect(_cle(SortiesEnAttente.cleVide), findsOneWidget);
    });

    testWidgets('chargement : un squelette', (WidgetTester tester) async {
      final _SortiesEnChargement lent = _SortiesEnChargement();
      tester.view.physicalSize = const Size(900, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteDirection(
          const SortiesEnAttente(),
          surcharges: <Override>[
            portControleDelegationProvider.overrideWithValue(lent),
          ],
        ),
      );
      await tester.pump();
      expect(_cle(SortiesEnAttente.cleVide), findsNothing);
      expect(find.byType(EtatSysteme), findsNothing);
      lent.attente.complete(const <SortieEnAttente>[]);
      await tester.pumpAndSettle();
      expect(_cle(SortiesEnAttente.cleVide), findsOneWidget);
    });

    testWidgets('erreur : un message et « Reessayer »', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc(echecSorties: true);
      await _monter(tester, banc.surcharges());
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.echecServeur,
        ),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne : l etat dit hors ligne', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc(echecSorties: true);
      await _monter(tester, banc.surcharges(), horsLigne: true);
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.horsLigne,
        ),
        findsWidgets,
      );
    });

    testWidgets('port absent : « pas encore disponible »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const <Override>[],
        panneau: const SortiesEnAttente(),
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.indisponible,
        ),
        findsOneWidget,
      );
    });
  });

  group('Exceptions', () {
    testWidgets('l exception de la source est lue : coffres, exclus, plafond', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      expect(_cle(ExceptionsDelegation.cleDe('exc-1')), findsOneWidget);
      expect(find.textContaining('Karim Studio'), findsWidgets);
      expect(
        find.textContaining(libelleCoffre(Coffre.tresorerieLibre)),
        findsWidgets,
      );
    });

    testWidgets('garder un coffre de plus : rendu au brouillon enregistre', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      await _appuyer(
        tester,
        find.text(d.exceptionModifier(libelle: d.exceptionLibelleDefaut)),
      );
      await _appuyer(
        tester,
        find.descendant(
          of: _cle(FeuilleException.cleCoffre(Coffre.enTransit)),
          matching: find.byType(Switch),
        ),
      );
      await _appuyer(tester, _cle(FeuilleException.cleGarder));
      await _appuyer(
        tester,
        find.byKey(FinanceDelegationPolicyPanel.enregistrerKey),
      );
      final ExceptionDelegation e = banc.dernierBrouillon!.exceptions.single;
      expect(e.coffresAutorises, contains(Coffre.enTransit));
      expect(e.coffresAutorises, contains(Coffre.tresorerieLibre));
    });

    testWidgets('un plafond plus haut que le general est refuse', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      await _appuyer(
        tester,
        find.text(d.exceptionModifier(libelle: d.exceptionLibelleDefaut)),
      );
      // Le plafond general par transaction est de 500 USD.
      await tester.enterText(
        find.descendant(
          of: _cle(FeuilleException.clePlafond),
          matching: find.byType(TextField),
        ),
        '600',
      );
      await tester.pump();
      await _appuyer(tester, _cle(FeuilleException.cleGarder));
      expect(
        find.textContaining('politique générale'),
        findsWidgets,
        reason: 'le message dit plus bas que la politique generale',
      );
      expect(_cle(FeuilleException.cleGarder), findsOneWidget);
    });

    testWidgets('un plafond plus bas est garde', (WidgetTester tester) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      await _appuyer(
        tester,
        find.text(d.exceptionModifier(libelle: d.exceptionLibelleDefaut)),
      );
      await tester.enterText(
        find.descendant(
          of: _cle(FeuilleException.clePlafond),
          matching: find.byType(TextField),
        ),
        '200',
      );
      await tester.pump();
      await _appuyer(tester, _cle(FeuilleException.cleGarder));
      expect(_cle(FeuilleException.cleGarder), findsNothing);
      await _appuyer(
        tester,
        find.byKey(FinanceDelegationPolicyPanel.enregistrerKey),
      );
      expect(
        banc.dernierBrouillon!.exceptions.single.plafondParTransaction?.mineur,
        20000,
      );
    });

    testWidgets('exclure un beneficiaire, puis le retirer', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      await _appuyer(
        tester,
        find.text(d.exceptionModifier(libelle: d.exceptionLibelleDefaut)),
      );
      await _appuyer(tester, _cle(FeuilleException.cleExclure('ctr-01')));
      await _appuyer(tester, _cle(FeuilleException.cleGarder));
      await _appuyer(
        tester,
        find.byKey(FinanceDelegationPolicyPanel.enregistrerKey),
      );
      final List<BeneficiaireExclu> exclus =
          banc.dernierBrouillon!.exceptions.single.beneficiairesExclus;
      expect(exclus.map((BeneficiaireExclu b) => b.id), contains('ctr-01'));
      expect(exclus.map((BeneficiaireExclu b) => b.id), contains('ctr-02'));
    });

    testWidgets('retirer l exception : la liste est vide au brouillon', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      await _appuyer(
        tester,
        find.text(d.exceptionModifier(libelle: d.exceptionLibelleDefaut)),
      );
      await _appuyer(tester, _cle(FeuilleException.cleRetirer));
      expect(find.text(d.exceptionsVide), findsOneWidget);
      await _appuyer(
        tester,
        find.byKey(FinanceDelegationPolicyPanel.enregistrerKey),
      );
      expect(banc.dernierBrouillon!.exceptions, isEmpty);
    });

    testWidgets('ajouter une exception', (WidgetTester tester) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc.surcharges());
      await _appuyer(
        tester,
        find.text(d.exceptionModifier(libelle: d.exceptionLibelleDefaut)),
      );
      await _appuyer(tester, _cle(FeuilleException.cleRetirer));
      await _appuyer(tester, _cle(ExceptionsDelegation.cleAjouter));
      await _appuyer(
        tester,
        find.descendant(
          of: _cle(FeuilleException.cleCoffre(Coffre.chargesEssentielles)),
          matching: find.byType(Switch),
        ),
      );
      await _appuyer(tester, _cle(FeuilleException.cleGarder));
      await _appuyer(
        tester,
        find.byKey(FinanceDelegationPolicyPanel.enregistrerKey),
      );
      expect(
        banc.dernierBrouillon!.exceptions.single.coffresAutorises,
        <Coffre>{Coffre.chargesEssentielles},
      );
    });
  });

  group('Cote Comptable : la raison rendue par la source', () {
    test('chaque raison de delegation a son mot, distinct', () {
      final Set<String> mots = <String>{
        for (final RaisonBlocage r in raisonsDelegation)
          libelleRaisonBlocage(r),
      };
      expect(raisonsDelegation, hasLength(6));
      expect(mots, hasLength(6));
      for (final String m in mots) {
        expect(m.trim(), isNotEmpty);
      }
    });

    test('les raisons de delegation ne sont pas celles du reste', () {
      expect(raisonsDelegation, isNot(contains(RaisonBlocage.autoPaiement)));
      expect(
        raisonsDelegation,
        isNot(contains(RaisonBlocage.validationRequise)),
      );
    });
  });

  group('320 px, texte a 200 %', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('panneau, aucun debordement (${sens.name})', (
        WidgetTester tester,
      ) async {
        final _Banc banc = _Banc();
        await _monter(
          tester,
          banc.surcharges(),
          taille: const Size(320, 4000),
          echelle: 2,
          sens: sens,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });
}
