// Doubles de l'observation tuteur (contrat K4) : politique, budgets, entrees
// accordees et refusees, visites ouvertes et fermees, historique.
//
// PROPRIETE : coordinateur (`test/fixtures/tuteur/`). Les valeurs imitent ce
// que le serveur rend en production le 24/09/2026 (politique `a2` : 2 visites,
// 120 s par visite, 240 s au total) ; elles ne sont une regle nulle part.

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/port_historique_observations.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';

/// La politique de l'Academie telle que la production la rend (`a2`).
const GuardianObservationPolicy politiqueA2 = GuardianObservationPolicy(
  policyVersion: 'a2',
  source: SourcePolitique.academie,
  observationActivee: true,
  maxVisitsPerSession: 2,
  maxTotalObservationTime: Duration(seconds: 240),
  maxParVisite: Duration(seconds: 120),
);

/// Une politique fermee par l'administration pour une classe.
const GuardianObservationPolicy politiqueFermee = GuardianObservationPolicy(
  policyVersion: 'groupe:3',
  source: SourcePolitique.desactivee,
  observationActivee: false,
  maxVisitsPerSession: 0,
  maxTotalObservationTime: Duration.zero,
);

/// Un budget tel que `budget_observation()` le rend.
BudgetObservation budgetFictif({
  int utilisees = 0,
  int max = 2,
  Duration consomme = Duration.zero,
  Duration total = const Duration(seconds: 240),
  Duration restant = const Duration(seconds: 120),
  bool peutEntrer = true,
  MotifRefusObservation? motif,
  bool visiteEnCours = false,
}) => BudgetObservation(
  policyVersion: 'a2',
  visitesUtilisees: utilisees,
  visitesMax: max,
  tempsConsomme: consomme,
  tempsTotalMax: total,
  restant: restant,
  peutEntrer: peutEntrer,
  motifRefus: motif,
  visiteEnCours: visiteEnCours,
);

/// Deux visites disponibles, aucune consommee.
final BudgetObservation budgetDeuxVisites = budgetFictif();

/// Une visite consommee (ecourtee a 40 s), la seconde et derniere disponible.
final BudgetObservation budgetUneRestante = budgetFictif(
  utilisees: 1,
  consomme: const Duration(seconds: 40),
);

/// Les deux visites consommees.
final BudgetObservation budgetEpuise = budgetFictif(
  utilisees: 2,
  consomme: const Duration(seconds: 160),
  restant: const Duration(seconds: 80),
  peutEntrer: false,
  motif: MotifRefusObservation.quotaVisitesAtteint,
);

/// Une visite deja ouverte (rechargement de page pendant la visite).
final BudgetObservation budgetVisiteOuverte = budgetFictif(
  utilisees: 1,
  restant: const Duration(seconds: 70),
  visiteEnCours: true,
);

/// Une ligne de `guardian_session_visit`, fermee par defaut.
Map<String, dynamic> ligneVisite({
  String id = 'v1',
  String seanceId = 's1',
  String groupeId = 'g1',
  String observateur = 'tuteur-foyer-a',
  String? enfantId = 'foyer-a-eleve-1',
  String entree = '2026-09-21T17:05:00Z',
  String? sortie = '2026-09-21T17:07:00Z',
  int? duree = 120,
  int rang = 1,
  String role = 'guardian_observer',
}) => <String, dynamic>{
  'id': id,
  'session_id': seanceId,
  'groupe_id': groupeId,
  'observateur_profile_id': observateur,
  'role': role,
  'enfant_profile_id': ?enfantId,
  'entered_at': entree,
  'left_at': ?sortie,
  'duration_seconds': ?duree,
  'visit_number': rang,
  'policy_version': 'a2',
  if (sortie != null) 'fin_de_visite': 'sortie_volontaire',
};

/// Une entree accordee : l'intervalle est ouvert, la premiere visite compte.
final ResultatEntreeObservation entreeAccordee = ResultatEntreeObservation(
  autorise: true,
  visite: GuardianSessionVisit.lire(ligneVisite(sortie: null, duree: null)),
  budget: budgetFictif(utilisees: 1, visiteEnCours: true),
);

/// Une entree refusee : quota de visites atteint.
final ResultatEntreeObservation entreeRefusee = ResultatEntreeObservation(
  autorise: false,
  motifRefus: MotifRefusObservation.quotaVisitesAtteint,
  budget: budgetEpuise,
);

/// L'historique d'observations, en memoire.
class FauxHistoriqueObservations implements PortHistoriqueObservations {
  /// Cree le faux sur des lignes brutes de `guardian_session_visit`.
  FauxHistoriqueObservations({this.lignes = const <Map<String, dynamic>>[]});

  /// Les lignes lues, incompletes comprises.
  List<Map<String, dynamic>> lignes;

  @override
  Future<List<ObservationsSeance>> mesObservations({
    String? enfantId,
    DateTimeRange? periode,
  }) async => grouperObservations(lignes)
      .where(
        (ObservationsSeance o) => enfantId == null || o.enfantId == enfantId,
      )
      .toList();

  @override
  Future<ObservationsSeance?> detail({
    required String seanceId,
    String? enfantId,
  }) async {
    for (final ObservationsSeance o in grouperObservations(lignes)) {
      if (o.seanceId == seanceId &&
          (enfantId == null || o.enfantId == enfantId)) {
        return o;
      }
    }
    return null;
  }
}
