/// Les doubles de demonstration du planning de la direction et des incidents
/// des 24 dernieres heures (DASH-ADM-PLANNING, DASH-ADM-INC). Hors production.
library;

import '../../core/admin/port_incidents_seances.dart';
import '../../core/admin/port_planning_direction.dart';
import '../../core/domain/enums.dart' show StatutSeance;

const List<String> _classes = <String>[
  'Filles, lundi 18 h · n° 1',
  'Garçons, mardi 17 h · n° 1',
  'Garçons, mardi 17 h · n° 2',
  'Adultes, mercredi 20 h · n° 1',
  'Filles, jeudi 18 h · n° 1',
  'Garçons, samedi 10 h · n° 1',
  'Adultes, dimanche 9 h · n° 1',
];

const List<String?> _enseignants = <String?>[
  'Amina B.',
  'Youssef K.',
  null,
  'Ibrahim S.',
  'Khadija L.',
  'Omar T.',
  'Salma R.',
];

/// Le planning fictif : une seance par classe et par jour de cours, dont
/// une annulee, une sans enseignant et une en incident.
class PlanningDirectionDemo implements PortPlanningDirection {
  /// Cree le double ; [maintenant] donne l'instant courant.
  PlanningDirectionDemo({DateTime Function()? maintenant, this.latence})
    : _maintenant = maintenant ?? DateTime.now;

  final DateTime Function() _maintenant;

  /// Un delai simule, pour voir l'etat de chargement.
  final Duration? latence;

  @override
  Future<List<SeancePlanning>> semaine(DateTime lundi) async {
    if (latence != null) await Future<void>.delayed(latence!);
    final DateTime maintenant = _maintenant();
    final List<SeancePlanning> seances = <SeancePlanning>[];
    for (int i = 0; i < _classes.length; i++) {
      final int jour = (i * 5 ~/ 3) % 7;
      final int heure = <int>[18, 17, 17, 20, 18, 10, 9][i];
      final DateTime debut = DateTime(
        lundi.year,
        lundi.month,
        lundi.day + jour,
        heure,
      );
      seances.add(
        SeancePlanning(
          id: 'demo-${lundi.millisecondsSinceEpoch}-$i',
          classe: _classes[i],
          enseignant: _enseignants[i],
          debut: debut,
          dureeMinutes: 45,
          statut: i == 4
              ? StatutSeance.annulee
              : debut.isBefore(maintenant.subtract(const Duration(hours: 1)))
              ? (i == 1
                    ? StatutSeance.incidentTechnique
                    : StatutSeance.terminee)
              : debut.isBefore(maintenant) &&
                    debut.add(const Duration(minutes: 45)).isAfter(maintenant)
              ? StatutSeance.enCours
              : StatutSeance.planifiee,
        ),
      );
    }
    seances.sort(
      (SeancePlanning a, SeancePlanning b) => a.debut.compareTo(b.debut),
    );
    return seances;
  }
}

/// Les incidents fictifs des dernieres 24 h : un de chaque nature, dont deux
/// sur des classes paralleles de meme horaire.
class IncidentsSeancesDemo implements PortIncidentsSeances {
  /// Cree le double.
  const IncidentsSeancesDemo();

  @override
  Future<List<IncidentSeance>> dernieres24h(DateTime maintenant) async =>
      <IncidentSeance>[
        IncidentSeance(
          id: 'inc-1',
          classe: _classes[1],
          enseignant: _enseignants[1],
          statut: StatutSeance.incidentTechnique,
          survenuLe: maintenant.subtract(const Duration(hours: 2)),
        ),
        IncidentSeance(
          id: 'inc-2',
          classe: _classes[2],
          enseignant: _enseignants[2],
          statut: StatutSeance.enseignantAbsent,
          survenuLe: maintenant.subtract(const Duration(hours: 5)),
        ),
        IncidentSeance(
          id: 'inc-3',
          classe: _classes[3],
          enseignant: _enseignants[3],
          statut: StatutSeance.eleveAbsent,
          survenuLe: maintenant.subtract(const Duration(hours: 19)),
        ),
      ];
}
