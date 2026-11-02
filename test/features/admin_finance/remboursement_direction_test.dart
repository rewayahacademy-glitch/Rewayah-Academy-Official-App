// FN-115c (pilote, 02/11/2026) : « Rembourser » dans le menu « ... » de la
// ligne d'un eleve de Finance > Paiements.
//
// - le menu n'existe que pour un eleve que le serveur dit remboursable ;
// - la feuille montre le montant propose par le serveur et son detail (rien
//   n'est calcule ici) ;
// - un double toucher sur « Rembourser » ne confirme et n'envoie qu'une fois ;
//   « Reessayer » apres une coupure rejoue la meme cle et la meme demande ;
// - un paiement refuse par le prestataire le dit ;
// - l'adaptateur Supabase decode la reponse du serveur.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_saisis.dart';
import 'package:rewayah_academy/core/capacites/port_remboursements_direction.dart';
import 'package:rewayah_academy/core/capacites/port_validations_finance.dart';
import 'package:rewayah_academy/core/capacites/remboursements_direction_supabase.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_finance/paiements/paiements_page.dart';
import 'package:rewayah_academy/features/admin_finance/paiements/remboursement_direction.dart';

import '../../support/harnais.dart';

class _SansValidations implements PortValidationsFinance {
  @override
  Future<List<DemandeValidation>> demandes(FiltreDemandesValidation filtre) =>
      Future<List<DemandeValidation>>.value(const <DemandeValidation>[]);

  @override
  Future<DemandeValidation> decider({
    required String demandeId,
    required DecisionValidation decision,
    required String cleIdempotence,
    String? motif,
  }) => throw UnimplementedError();

  @override
  Future<List<EntreeJournal>> journal(String demandeId) =>
      Future<List<EntreeJournal>>.value(const <EntreeJournal>[]);
}

final PaiementRemboursable _paiement = PaiementRemboursable(
  commandeId: 'c1',
  reference: 'RA-REC-1',
  payeLe: DateTime(2026, 11, 1, 10),
  paye: const Montant(5500, 'USD'),
  propose: const Montant(4654, 'USD'),
  regle: RegleRemboursement.delai,
  seancesSuivies: 2,
  prixSeance: const Montant(423, 'USD'),
  delaiJours: 7,
);

class _Remboursements implements PortRemboursementsDirection {
  _Remboursements({
    this.issues = const <Object>[IssueRemboursement.envoye],
    this.attente,
  });

  final Set<String> remboursables = const <String>{'e2'};
  final List<Object> issues;
  final Completer<String>? attente;
  final List<String> cles = <String>[];
  final List<String> envois = <String>[];

  @override
  Future<Set<String>> elevesRemboursables() async => remboursables;

  @override
  Future<List<PaiementRemboursable>> paiements(String profilId) async =>
      <PaiementRemboursable>[_paiement];

  @override
  Future<String> confirmer({
    required String commandeId,
    required String profilId,
    required Montant montant,
    required String cle,
  }) {
    cles.add(cle);
    return attente?.future ?? Future<String>.value('d1');
  }

  @override
  Future<IssueRemboursement> envoyer(String demandeId) {
    envois.add(demandeId);
    final Object r = issues[envois.length - 1];
    return r is IssueRemboursement
        ? Future<IssueRemboursement>.value(r)
        : Future<IssueRemboursement>.error(r);
  }
}

const ElevePourPaiement _bilal = ElevePourPaiement(
  profilId: 'e2',
  prenom: 'Bilal',
  nom: 'F1',
  matricule: 'RA-26-4817',
  resteAPayer: Montant(0, 'USD'),
);

const ElevePourPaiement _yasmine = ElevePourPaiement(
  profilId: 'e1',
  prenom: 'Yasmine',
  nom: 'F1',
  matricule: 'RA-26-1203',
  resteAPayer: Montant(0, 'USD'),
);

class _Port implements PortPaiementsSaisis {
  @override
  Future<List<ElevePourPaiement>> eleves() async => const <ElevePourPaiement>[
    _bilal,
    _yasmine,
  ];

  @override
  Future<FacturesEmises> emettreFactures(DateTime mois) =>
      throw UnimplementedError();

  @override
  Future<PaiementEnregistre> enregistrer({
    required String profilId,
    required Montant montant,
    required String cle,
    String? reference,
  }) => throw UnimplementedError();
}

Widget _hote(
  PortPaiementsSaisis port, {
  PortRemboursementsDirection? remboursements,
  double echelle = 1,
  Brightness luminosite = Brightness.light,
  TextDirection sens = TextDirection.ltr,
  bool horsLigne = false,
}) => ProviderScope(
  overrides: <Override>[
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
    sansPersonneConnectee(),
    portPaiementsSaisisProvider.overrideWithValue(port),
    portValidationsFinanceProvider.overrideWithValue(_SansValidations()),
    if (remboursements != null)
      portRemboursementsDirectionProvider.overrideWithValue(remboursements),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
      themeMode: luminosite == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (BuildContext context, Widget? app) => Directionality(
        textDirection: sens,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(echelle)),
          child: app!,
        ),
      ),
      home: const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: PaiementsBloc(),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _monter(WidgetTester tester, Widget hote) async {
  tester.view.physicalSize = const Size(1440, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(hote);
  await tester.pumpAndSettle();
}

Future<void> _ouvrirFeuille(WidgetTester tester) async {
  await tester.tap(find.byKey(PaiementsBloc.cleMenuEleve('e2')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(t.admin.finance.pai.rembourser).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'le menu « Rembourser » n existe que pour un eleve remboursable',
    (WidgetTester tester) async {
      await _monter(tester, _hote(_Port(), remboursements: _Remboursements()));
      expect(find.byKey(PaiementsBloc.cleMenuEleve('e2')), findsOneWidget);
      expect(find.byKey(PaiementsBloc.cleMenuEleve('e1')), findsNothing);
    },
  );

  testWidgets('sans source : aucun menu', (WidgetTester tester) async {
    await _monter(tester, _hote(_Port()));
    expect(find.byKey(PaiementsBloc.cleMenuEleve('e2')), findsNothing);
  });

  testWidgets('la feuille dit le montant du serveur et son detail ; un double '
      'toucher ne rembourse qu une fois', (WidgetTester tester) async {
    final Completer<String> attente = Completer<String>();
    final _Remboursements port = _Remboursements(attente: attente);
    await _monter(tester, _hote(_Port(), remboursements: port));
    await _ouvrirFeuille(tester);
    final p = t.admin.finance.pai;
    expect(
      find.text(formaterMontant(const Montant(4654, 'USD'))),
      findsWidgets,
    );
    expect(
      find.text(
        p.rembFois(n: 2, prix: formaterMontant(const Montant(423, 'USD'))),
      ),
      findsOneWidget,
    );
    expect(
      find.text(LibellesGroupe.insecable(p.rembRegleDelai(jours: 7))),
      findsOneWidget,
    );
    final Finder bouton = find.byKey(FeuilleRemboursement.cleConfirmer);
    await tester.tap(bouton);
    await tester.pump();
    await tester.tap(bouton, warnIfMissed: false);
    await tester.pump();
    attente.complete('d1');
    await tester.pumpAndSettle();
    expect(port.cles, hasLength(1));
    expect(port.envois, <String>['d1']);
    expect(find.byKey(FeuilleRemboursement.cleEnvoye), findsOneWidget);
  });

  testWidgets('apres une coupure, « Reessayer » rejoue la meme demande', (
    WidgetTester tester,
  ) async {
    final _Remboursements port = _Remboursements(
      issues: <Object>[Exception('coupure'), IssueRemboursement.envoye],
    );
    await _monter(tester, _hote(_Port(), remboursements: port));
    await _ouvrirFeuille(tester);
    await tester.tap(find.byKey(FeuilleRemboursement.cleConfirmer));
    await tester.pumpAndSettle();
    expect(find.text(t.admin.finance.pai.rembErreur), findsOneWidget);
    await tester.tap(find.byKey(FeuilleRemboursement.cleConfirmer));
    await tester.pumpAndSettle();
    // Une seule confirmation (la demande est gardee), deux envois de la
    // meme demande (idempotents chez le prestataire).
    expect(port.cles, hasLength(1));
    expect(port.envois, <String>['d1', 'd1']);
    expect(find.byKey(FeuilleRemboursement.cleEnvoye), findsOneWidget);
  });

  testWidgets('refuse par le prestataire : dit, rien n est parti', (
    WidgetTester tester,
  ) async {
    final _Remboursements port = _Remboursements(
      issues: <Object>[IssueRemboursement.refuse],
    );
    await _monter(tester, _hote(_Port(), remboursements: port));
    await _ouvrirFeuille(tester);
    await tester.tap(find.byKey(FeuilleRemboursement.cleConfirmer));
    await tester.pumpAndSettle();
    expect(find.text(t.admin.finance.pai.rembRefusePhrase), findsOneWidget);
  });

  test('adaptateur : decode le paiement et le detail du serveur ; envoie la '
      'demande', () async {
    final List<(String, Map<String, dynamic>?)> rpc =
        <(String, Map<String, dynamic>?)>[];
    final List<Map<String, dynamic>> corps = <Map<String, dynamic>>[];
    final RemboursementsDirectionSupabase a =
        RemboursementsDirectionSupabase.avecAppels(
          (String f, Map<String, dynamic>? params) async {
            rpc.add((f, params));
            return switch (f) {
              'remboursement_eleves_remboursables' => <Object>['e2'],
              'remboursement_paiements_eleve' => <Object>[
                <String, dynamic>{
                  'commande_id': 'c1',
                  'reference': 'RA-REC-1',
                  'paye_le': '2026-11-01T09:00:00Z',
                  'devise': 'USD',
                  'paye_mineur': 5500,
                  'montant_propose_mineur': 4654,
                  'detail': <String, dynamic>{
                    'regle': 'delai',
                    'seances_suivies': 2,
                    'prix_seance_mineur': 423,
                    'delai_jours': 7,
                    'deja_rendu_mineur': 0,
                    'en_cours_mineur': 0,
                  },
                },
              ],
              'remboursement_confirmer' => 'd1',
              _ => null,
            };
          },
          (Map<String, dynamic> c) async {
            corps.add(c);
            return <String, dynamic>{'etat': 'envoyee'};
          },
        );
    expect(await a.elevesRemboursables(), <String>{'e2'});
    final PaiementRemboursable x = (await a.paiements('e2')).single;
    expect(x.propose, const Montant(4654, 'USD'));
    expect(x.regle, RegleRemboursement.delai);
    expect(x.prixSeance, const Montant(423, 'USD'));
    expect(x.dejaRendu, isNull);
    expect(
      await a.confirmer(
        commandeId: 'c1',
        profilId: 'e2',
        montant: const Montant(4654, 'USD'),
        cle: 'k',
      ),
      'd1',
    );
    expect(rpc.last.$2, <String, dynamic>{
      'p_commande': 'c1',
      'p_profil': 'e2',
      'p_montant': 4654,
      'p_cle': 'k',
    });
    expect(await a.envoyer('d1'), IssueRemboursement.envoye);
    expect(corps.single, <String, dynamic>{'demandeId': 'd1'});
  });
}
