// Mode demonstration tuteur (P2-07) : observation simulee.
//
// Politique, budget et historique d'observation fictifs, en memoire. La salle
// video, elle, reste fermee : entrer dans une observation demande un jeton au
// serveur, ce que la demonstration ne fait jamais. `entrer` rend donc un refus
// (`seanceNonActive`), et `observationTuteurReelleProvider` est force a faux
// par `surchargesDemoTuteur`.

import 'package:flutter/material.dart' show DateTimeRange;

import '../../core/tc_observation/guardian_observation_policy.dart';
import '../../core/tc_observation/guardian_session_visit.dart';
import '../../core/tc_observation/port_historique_observations.dart';
import '../../core/tc_observation/port_politique_observation.dart';
import '../../core/tc_observation/port_visite_observation.dart';
import 'mode_demonstration.dart' show DonneesDemo;

/// La politique de l'Academie, telle que la production la rend (`a2`).
const GuardianObservationPolicy politiqueDemo = GuardianObservationPolicy(
  policyVersion: 'a2',
  source: SourcePolitique.academie,
  observationActivee: true,
  maxVisitsPerSession: 2,
  maxTotalObservationTime: Duration(seconds: 240),
  maxParVisite: Duration(seconds: 120),
);

/// Une visite deja faite, la seconde encore disponible.
const BudgetObservation budgetDemo = BudgetObservation(
  policyVersion: 'a2',
  visitesUtilisees: 1,
  visitesMax: 2,
  tempsConsomme: Duration(seconds: 95),
  tempsTotalMax: Duration(seconds: 240),
  restant: Duration(seconds: 120),
  peutEntrer: true,
);

/// Politique et budget fictifs.
class PolitiqueObservationDemo implements PortPolitiqueObservation {
  /// Cree le double.
  const PolitiqueObservationDemo();

  @override
  Future<GuardianObservationPolicy> politiqueEffective({
    required String groupeId,
  }) async => politiqueDemo;

  @override
  Future<BudgetObservation> budget({required String sessionId}) async =>
      budgetDemo;

  @override
  Stream<BudgetObservation> suivreBudget({required String sessionId}) =>
      Stream<BudgetObservation>.value(budgetDemo);

  @override
  Future<GuardianObservationPolicy> definirPolitiqueGroupe({
    required String groupeId,
    required GuardianObservationPolicy politique,
  }) async => politique;
}

/// Les lignes `guardian_session_visit` fictives : une visite par eleve, sur
/// la seance passee d'il y a 7 jours (memes identifiants que
/// `SeancesFamilleDemo`).
List<Map<String, dynamic>> lignesVisitesDemo({DateTime? maintenant}) {
  final DateTime m = (maintenant ?? DateTime.now()).toUtc();
  final DateTime entree = DateTime.utc(
    m.year,
    m.month,
    m.day,
    16,
    10,
  ).subtract(const Duration(days: 7));
  return <Map<String, dynamic>>[
    for (final (int i, String eleveId) in <String>[
      DonneesDemo.aichaId,
      DonneesDemo.yusufId,
    ].indexed)
      <String, dynamic>{
        'id': 'demo-visite-$i',
        'session_id': 'demo-seance-$eleveId--7',
        'groupe_id': DonneesDemo.classes[eleveId]!.groupeId,
        'observateur_profile_id': DonneesDemo.tuteurId,
        'role': 'guardian_observer',
        'enfant_profile_id': eleveId,
        'entered_at': entree.toIso8601String(),
        'left_at': entree.add(const Duration(seconds: 95)).toIso8601String(),
        'duration_seconds': 95,
        'visit_number': 1,
        'policy_version': 'a2',
        'fin_de_visite': 'sortie_volontaire',
      },
  ];
}

/// Visites fictives : aucune salle ne s'ouvre.
class VisiteObservationDemo implements PortVisiteObservation {
  /// Cree le double.
  const VisiteObservationDemo();

  @override
  Future<ResultatEntreeObservation> entrer({
    required String sessionId,
    required RoleObservateur role,
  }) async => const ResultatEntreeObservation(
    autorise: false,
    motifRefus: MotifRefusObservation.seanceNonActive,
    budget: budgetDemo,
  );

  @override
  Future<void> sortir({required String sessionId}) async {}

  @override
  Future<List<GuardianSessionVisit>> visites({
    required String sessionId,
  }) async => <GuardianSessionVisit>[
    for (final Map<String, dynamic> l in lignesVisitesDemo())
      if (l['session_id'] == sessionId) ?GuardianSessionVisit.lire(l),
  ];
}

/// Historique d'observations fictif.
class HistoriqueObservationsDemo implements PortHistoriqueObservations {
  /// Cree le double.
  const HistoriqueObservationsDemo();

  @override
  Future<List<ObservationsSeance>> mesObservations({
    String? enfantId,
    DateTimeRange? periode,
  }) async => grouperObservations(lignesVisitesDemo())
      .where(
        (ObservationsSeance o) => enfantId == null || o.enfantId == enfantId,
      )
      .toList();

  @override
  Future<ObservationsSeance?> detail({
    required String seanceId,
    String? enfantId,
  }) async {
    for (final ObservationsSeance o in grouperObservations(
      lignesVisitesDemo(),
    )) {
      if (o.seanceId == seanceId &&
          (enfantId == null || o.enfantId == enfantId)) {
        return o;
      }
    }
    return null;
  }
}
