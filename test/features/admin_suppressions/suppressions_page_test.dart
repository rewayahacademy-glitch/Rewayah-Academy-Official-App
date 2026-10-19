// CPT-SUPPR-EXPORT : l'ecran de la direction qui traite les demandes de
// suppression de compte.
//
// Ce que le test prouve : les cinq etats et le port absent ; le geste
// n'existe que si le serveur dit le delai ecoule et qu'aucune seance n'est a
// venir, sinon la raison le remplace ; le solde, les seances et le foyer sont
// dits avant la confirmation ; la confirmation dit que l'acte est irreversible
// et renoncer n'envoie rien ; chaque refus du serveur a sa phrase ; une
// coupure ne pretend rien et relit la liste ; 320 px, texte x2, LTR et RTL.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_suppressions_admin.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/identifiant_insecable.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_suppressions/suppressions_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';

/// Un port a l'etat modifiable : traiter fait passer la demande en traitee.
class _Port implements PortSuppressionsAdmin {
  _Port(this.demandes);

  List<DemandeSuppressionAdmin> demandes;
  ResultatTraitementSuppression resultat =
      ResultatTraitementSuppression.traitee;
  Object? erreurTraitement;
  Object? erreurLecture;
  Completer<List<DemandeSuppressionAdmin>>? retenue;
  int lectures = 0;
  final List<String> traitees = <String>[];

  @override
  Future<List<DemandeSuppressionAdmin>> lister() {
    lectures++;
    final Completer<List<DemandeSuppressionAdmin>>? r = retenue;
    if (r != null) return r.future;
    final Object? e = erreurLecture;
    if (e != null) return Future<List<DemandeSuppressionAdmin>>.error(e);
    return Future<List<DemandeSuppressionAdmin>>.value(demandes);
  }

  @override
  Future<ResultatTraitementSuppression> traiter(String id) async {
    traitees.add(id);
    final Object? e = erreurTraitement;
    if (e != null) return Future<ResultatTraitementSuppression>.error(e);
    if (resultat == ResultatTraitementSuppression.traitee) {
      demandes = <DemandeSuppressionAdmin>[
        for (final DemandeSuppressionAdmin d in demandes)
          if (d.id == id) _traitee(d) else d,
      ];
    }
    return resultat;
  }
}

DemandeSuppressionAdmin _demande({
  String id = 'd1',
  String prenom = 'Awa',
  String nom = 'Bah',
  StatutSuppression statut = StatutSuppression.enAttente,
  bool delaiEcoule = true,
  AppRole? role = AppRole.guardian,
  String? motif,
  int eleves = 0,
  SituationSuppressionAdmin? situation = const SituationSuppressionAdmin(
    montantsDus: <Montant>[],
    seancesAVenir: 0,
  ),
}) => DemandeSuppressionAdmin(
  id: id,
  statut: statut,
  matricule: 'RA-26-4817',
  prenom: prenom,
  nom: nom,
  role: role,
  motif: motif,
  delaiJours: 14,
  demandeeLe: DateTime(2026, 10, 1, 10),
  echeanceLe: DateTime(2026, 10, 15, 10),
  delaiEcoule: delaiEcoule,
  elevesDuFoyer: eleves,
  situation: statut == StatutSuppression.enAttente ? situation : null,
);

DemandeSuppressionAdmin _traitee(DemandeSuppressionAdmin d) =>
    DemandeSuppressionAdmin(
      id: d.id,
      statut: StatutSuppression.traitee,
      matricule: d.matricule,
      prenom: 'Compte',
      nom: 'supprimé',
      role: d.role,
      delaiJours: d.delaiJours,
      demandeeLe: d.demandeeLe,
      echeanceLe: d.echeanceLe,
      traiteeLe: DateTime(2026, 10, 19, 9),
      delaiEcoule: false,
      elevesDuFoyer: 0,
    );

Future<void> _monter(
  WidgetTester tester,
  PortSuppressionsAdmin? port, {
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterRecrutement(
  tester,
  chemin: '/admin/personnes/suppressions',
  ecran: (_) => const SuppressionsPage(),
  autres: <String>[
    '/admin/personnes/dossiers',
    '/admin/personnes/comptes',
    '/admin/personnes/invitations',
    '/admin/personnes/reprises',
    '/admin/personnes/import',
  ],
  surcharges: <Override>[
    if (port != null) portSuppressionsAdminProvider.overrideWithValue(port),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

final Finder _traiter = find.byKey(SuppressionsPage.traiterKey('d1'));
final Finder _raison = find.byKey(SuppressionsPage.raisonKey('d1'));
final Finder _retour = find.byKey(SuppressionsPage.retourKey);

/// Le bouton destructif de la confirmation (le dernier du libelle).
Finder _confirmer() => find.text(t.admin.suppressions.confirmerAction).last;

Future<void> _ouvrirConfirmation(WidgetTester tester) async {
  await tester.tap(_traiter);
  await laisser(tester);
}

void main() {
  final a = t.admin.suppressions;

  group('contenu', () {
    testWidgets('qui, matricule, role, dates, motif ; le geste est ouvert', (
      tester,
    ) async {
      await _monter(
        tester,
        _Port(<DemandeSuppressionAdmin>[_demande(motif: 'Nous partons')]),
      );
      expect(find.textContaining('Awa Bah'), findsOneWidget);
      expect(
        find.textContaining(identifiantInsecable('RA-26-4817')),
        findsOneWidget,
      );
      expect(find.text(t.admin.comptes.roleTuteur), findsOneWidget);
      expect(find.text('Nous partons'), findsOneWidget);
      expect(find.text(a.attente(n: 1)), findsOneWidget);
      expect(find.text(a.etat.aTraiter), findsOneWidget);
      expect(_traiter, findsOneWidget);
      expect(_raison, findsNothing);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('delai non ecoule : la raison remplace le geste', (
      tester,
    ) async {
      await _monter(
        tester,
        _Port(<DemandeSuppressionAdmin>[_demande(delaiEcoule: false)]),
      );
      expect(_traiter, findsNothing);
      expect(_raison, findsOneWidget);
      expect(find.text(a.etat.enAttente), findsOneWidget);
      expect(find.textContaining('15'), findsWidgets);
    });

    testWidgets('des seances a venir : dites, et le geste n est pas rendu', (
      tester,
    ) async {
      await _monter(
        tester,
        _Port(<DemandeSuppressionAdmin>[
          _demande(
            situation: const SituationSuppressionAdmin(
              montantsDus: <Montant>[],
              seancesAVenir: 2,
            ),
          ),
        ]),
      );
      expect(find.text(a.seancesTitre), findsOneWidget);
      expect(find.text(a.seancesDetail(n: 2)), findsOneWidget);
      expect(_traiter, findsNothing);
    });

    testWidgets('solde et foyer sont dits avant le geste', (tester) async {
      await _monter(
        tester,
        _Port(<DemandeSuppressionAdmin>[
          _demande(
            eleves: 2,
            situation: const SituationSuppressionAdmin(
              montantsDus: <Montant>[Montant(4500, 'USD')],
              seancesAVenir: 0,
            ),
          ),
        ]),
      );
      expect(find.text(a.soldeTitre), findsOneWidget);
      expect(find.textContaining('45'), findsWidgets);
      expect(find.text(a.foyerTitre), findsOneWidget);
      expect(find.text(a.foyerDetail(n: 2)), findsOneWidget);
      expect(_traiter, findsOneWidget);
    });

    testWidgets('annulee et traitee : l\'historique, jamais de geste', (
      tester,
    ) async {
      await _monter(
        tester,
        _Port(<DemandeSuppressionAdmin>[
          _traitee(_demande(id: 'd2')),
          _demande(id: 'd3', statut: StatutSuppression.annulee, role: null),
        ]),
      );
      expect(find.text(a.etat.traitee), findsOneWidget);
      expect(find.text(a.etat.annulee), findsOneWidget);
      expect(find.text(t.admin.comptes.roleInconnu), findsOneWidget);
      expect(find.text(a.traiter), findsNothing);
      // Aucune demande en attente : pas de phrase de synthese.
      expect(find.textContaining(a.attente(n: 1)), findsNothing);
    });
  });

  group('etats', () {
    testWidgets('chargement', (tester) async {
      final _Port p = _Port(<DemandeSuppressionAdmin>[])
        ..retenue = Completer<List<DemandeSuppressionAdmin>>();
      await _monter(tester, p);
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets('vide', (tester) async {
      await _monter(tester, _Port(<DemandeSuppressionAdmin>[]));
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(a.vide), findsOneWidget);
    });

    testWidgets('port absent : disponible au branchement serveur', (
      tester,
    ) async {
      await _monter(tester, null);
      expect(
        find.byKey(const ValueKey<String>('suppressions-indisponible')),
        findsOneWidget,
      );
      expect(find.text(a.indisponiblePhrase), findsOneWidget);
    });

    testWidgets('erreur : un Reessayer relit', (tester) async {
      final _Port p = _Port(<DemandeSuppressionAdmin>[_demande()])
        ..erreurLecture = Exception('panne');
      await _monter(tester, p);
      expect(find.byType(EtatSysteme), findsOneWidget);
      expect(find.text(a.erreur), findsOneWidget);
      final int avant = p.lectures;
      p.erreurLecture = null;
      await tester.tap(find.text(t.commun.reessayer));
      await laisser(tester);
      expect(p.lectures, greaterThan(avant));
      expect(_traiter, findsOneWidget);
    });

    testWidgets('hors ligne : ce qui manque est dit', (tester) async {
      final _Port p = _Port(<DemandeSuppressionAdmin>[])
        ..erreurLecture = Exception('reseau');
      await _monter(tester, p, horsLigne: true);
      expect(
        find.byKey(const ValueKey<String>('suppressions-sans-donnees')),
        findsOneWidget,
      );
      expect(find.text(a.sansDonnees), findsOneWidget);
    });

    testWidgets('lecture refusee : une phrase, aucune action', (tester) async {
      final _Port p = _Port(<DemandeSuppressionAdmin>[])
        ..erreurLecture = const PermissionInsuffisante('x');
      await _monter(tester, p);
      expect(find.text(a.refuse), findsOneWidget);
      expect(_traiter, findsNothing);
    });
  });

  group('traitement', () {
    testWidgets('la confirmation dit l irreversible, puis la liste est relue', (
      tester,
    ) async {
      final _Port p = _Port(<DemandeSuppressionAdmin>[
        _demande(
          situation: const SituationSuppressionAdmin(
            montantsDus: <Montant>[Montant(4500, 'USD')],
            seancesAVenir: 0,
          ),
        ),
      ]);
      await _monter(tester, p);
      await _ouvrirConfirmation(tester);
      expect(find.textContaining('Awa Bah'), findsWidgets);
      expect(find.textContaining(a.confirmerConsequence), findsOneWidget);
      // Le solde restant du figure dans la confirmation.
      expect(find.textContaining('45'), findsWidgets);
      expect(p.traitees, isEmpty);
      final int avant = p.lectures;
      await tester.tap(_confirmer());
      await laisser(tester);
      expect(p.traitees, <String>['d1']);
      expect(p.lectures, greaterThan(avant));
      expect(find.text(a.traitee), findsOneWidget);
      expect(find.text(a.etat.traitee), findsOneWidget);
      expect(_traiter, findsNothing);
    });

    testWidgets('renoncer : rien ne part', (tester) async {
      final _Port p = _Port(<DemandeSuppressionAdmin>[_demande()]);
      await _monter(tester, p);
      await _ouvrirConfirmation(tester);
      await tester.tap(find.text(a.confirmerRester).last);
      await laisser(tester);
      expect(p.traitees, isEmpty);
      expect(_retour, findsNothing);
      expect(_traiter, findsOneWidget);
    });

    testWidgets('hors ligne : rien ne part, la phrase le dit', (tester) async {
      final _Port p = _Port(<DemandeSuppressionAdmin>[_demande()]);
      await _monter(tester, p, horsLigne: true);
      await _ouvrirConfirmation(tester);
      await tester.tap(_confirmer());
      await laisser(tester);
      expect(p.traitees, isEmpty);
      expect(find.text(a.horsLigne), findsOneWidget);
    });

    final Map<ResultatTraitementSuppression, String> refus =
        <ResultatTraitementSuppression, String>{
          ResultatTraitementSuppression.dejaTraitee: a.dejaTraitee,
          ResultatTraitementSuppression.delaiEnCours: a.delaiNonEcoule,
          ResultatTraitementSuppression.seancesAVenir: a.seancesRefus,
          ResultatTraitementSuppression.introuvable: a.introuvable,
        };
    refus.forEach((ResultatTraitementSuppression r, String phrase) {
      testWidgets('refus du serveur ${r.name} : sa phrase, liste relue', (
        tester,
      ) async {
        final _Port p = _Port(<DemandeSuppressionAdmin>[_demande()])
          ..resultat = r;
        await _monter(tester, p);
        await _ouvrirConfirmation(tester);
        final int avant = p.lectures;
        await tester.tap(_confirmer());
        await laisser(tester);
        expect(find.text(phrase), findsOneWidget);
        expect(find.text(a.traitee), findsNothing);
        expect(p.lectures, greaterThan(avant));
      });
    });

    testWidgets('direction sans double verification : refus dit', (
      tester,
    ) async {
      final _Port p = _Port(<DemandeSuppressionAdmin>[_demande()])
        ..erreurTraitement = const PermissionInsuffisante('x');
      await _monter(tester, p);
      await _ouvrirConfirmation(tester);
      await tester.tap(_confirmer());
      await laisser(tester);
      expect(find.text(a.refuse), findsOneWidget);
    });

    testWidgets('coupure : non confirmee, la liste est relue', (tester) async {
      final _Port p = _Port(<DemandeSuppressionAdmin>[_demande()])
        ..erreurTraitement = Exception('coupure');
      await _monter(tester, p);
      await _ouvrirConfirmation(tester);
      final int avant = p.lectures;
      await tester.tap(_confirmer());
      await laisser(tester);
      expect(find.text(a.echec), findsOneWidget);
      expect(find.text(a.traitee), findsNothing);
      expect(p.lectures, greaterThan(avant));
    });
  });

  group('gabarits', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection d in TextDirection.values) {
      testWidgets('320 px, texte x2, ${d.name}', (tester) async {
        await _monter(
          tester,
          _Port(<DemandeSuppressionAdmin>[
            _demande(
              eleves: 1,
              motif: 'Nous déménageons',
              situation: const SituationSuppressionAdmin(
                montantsDus: <Montant>[Montant(4500, 'USD')],
                seancesAVenir: 0,
              ),
            ),
            _demande(id: 'd2', delaiEcoule: false),
          ]),
          largeur: 320,
          echelle: 2,
          direction: d,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });
}
