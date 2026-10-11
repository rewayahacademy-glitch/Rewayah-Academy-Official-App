/// DASH-ADM-INC : les incidents des 24 dernieres heures, ce que compte la
/// tuile « Incidents (24 h) » du Centre de commande.
///
/// La tuile compte des SEANCES au statut incident technique, enseignant
/// absent ou eleve absent, mises a jour depuis 24 h (migration 0015), pas des
/// entrees du journal d'audit : la page liste donc ces seances, pour qu'un
/// lien mene a ce que la tuile compte (D9). **Le contrat attendu** (ligne
/// Contrats a demander, BR-1) : la lecture de ces seances, plus recentes
/// d'abord, avec le meme critere que le compteur.
///
/// Sans port ([portIncidentsSeancesProvider] vaut `null`), l'ecran dit
/// « disponible au branchement serveur » : aucun incident n'est invente.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import '../domain/enums.dart' show StatutSeance;

/// La duree que couvre la page, la meme que le compteur de la tuile.
const Duration fenetreIncidents = Duration(hours: 24);

/// Les statuts que la tuile compte.
const Set<StatutSeance> statutsIncident = <StatutSeance>{
  StatutSeance.incidentTechnique,
  StatutSeance.enseignantAbsent,
  StatutSeance.eleveAbsent,
};

/// Une seance en incident.
@immutable
class IncidentSeance {
  /// Cree l'incident.
  const IncidentSeance({
    required this.id,
    required this.classe,
    required this.statut,
    required this.survenuLe,
    this.enseignant,
  }) : assert(
         statut == StatutSeance.incidentTechnique ||
             statut == StatutSeance.enseignantAbsent ||
             statut == StatutSeance.eleveAbsent,
         'un incident a un statut d\'incident',
       );

  /// L'identifiant de la seance.
  final String id;

  /// Le nom de la classe, distinct parmi les classes paralleles (R16).
  final String classe;

  /// La nature de l'incident.
  final StatutSeance statut;

  /// Quand la seance est passee a ce statut.
  final DateTime survenuLe;

  /// Le nom de l'enseignant, ou `null`.
  final String? enseignant;
}

/// Le port des incidents.
abstract interface class PortIncidentsSeances {
  /// Les incidents des [fenetreIncidents] precedant [maintenant], plus
  /// recents d'abord.
  Future<List<IncidentSeance>> dernieres24h(DateTime maintenant);
}

/// L'identifiant de la dependance serveur (jamais affiche).
const String dependanceIncidentsSeances = 'DB-DASH-ADM-INC';

/// Le port : absent avant le contrat serveur (BR-1).
final Provider<PortIncidentsSeances?> portIncidentsSeancesProvider =
    Provider<PortIncidentsSeances?>((Ref _) => null);

/// Les incidents des dernieres 24 h. Sans port : [CapaciteIndisponible].
final FutureProvider<List<IncidentSeance>> incidentsSeancesProvider =
    FutureProvider<List<IncidentSeance>>((Ref ref) {
      final PortIncidentsSeances? port = ref.watch(
        portIncidentsSeancesProvider,
      );
      if (port == null) {
        return Future<List<IncidentSeance>>.error(
          const CapaciteIndisponible(dependanceIncidentsSeances),
        );
      }
      return port.dernieres24h(DateTime.now());
    }, retry: (int _, Object _) => null);
