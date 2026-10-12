/// DASH-ADM-PLANNING : le planning de la direction, une semaine de seances
/// toutes classes confondues.
///
/// **Ce que le serveur porte, et que Flutter ne decide jamais** : quelles
/// seances existent, leur statut et leur enseignant. L'ecran regroupe par
/// jour ce qu'on lui rend, il ne calcule aucune recurrence. **Le contrat
/// attendu** (ligne Contrats a demander) : une lecture des seances dont le
/// debut tombe entre un lundi 00 h et le lundi suivant, dans le fuseau de la
/// direction, avec le nom de la classe (code court compris, R16), le nom de
/// l'enseignant s'il y en a un, le debut, la duree et le statut.
///
/// Sans port ([portPlanningDirectionProvider] vaut `null`), l'ecran dit
/// « disponible au branchement serveur » : aucune seance n'est inventee. La
/// demonstration surcharge le port.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../capacites/capacite_indisponible.dart';
import '../domain/enums.dart' show StatutSeance;

/// Une seance du planning.
@immutable
class SeancePlanning {
  /// Cree la seance.
  const SeancePlanning({
    required this.id,
    required this.classe,
    required this.debut,
    required this.dureeMinutes,
    required this.statut,
    this.enseignant,
  });

  /// L'identifiant de la seance.
  final String id;

  /// Le nom de la classe, distinct parmi les classes paralleles (R16).
  final String classe;

  /// Le debut, en heure locale.
  final DateTime debut;

  /// La duree prevue, en minutes.
  final int dureeMinutes;

  /// Le statut rendu par le serveur.
  final StatutSeance statut;

  /// Le nom de l'enseignant, ou `null` tant que la classe n'en a pas.
  final String? enseignant;

  /// La fin prevue.
  DateTime get fin => debut.add(Duration(minutes: dureeMinutes));
}

/// Le lundi (a minuit, heure locale) de la semaine qui contient [jour].
DateTime lundiDe(DateTime jour) {
  final DateTime local = jour.toLocal();
  return DateTime(
    local.year,
    local.month,
    local.day,
  ).subtract(Duration(days: local.weekday - DateTime.monday));
}

/// Le port du planning de la direction.
abstract interface class PortPlanningDirection {
  /// Les seances de la semaine qui commence le [lundi], triees par debut.
  Future<List<SeancePlanning>> semaine(DateTime lundi);
}

/// L'identifiant de la dependance serveur, pour la trace et les tests
/// (jamais affiche).
const String dependancePlanningDirection = 'DB-DASH-ADM-PLANNING';

/// Le port : absent avant le contrat serveur.
final Provider<PortPlanningDirection?> portPlanningDirectionProvider =
    Provider<PortPlanningDirection?>((Ref _) => null);

/// La semaine demandee. Sans port : [CapaciteIndisponible], que l'ecran dit
/// en clair. Aucune retentative automatique : un echec se relit par
/// « Reessayer ».
final FutureProviderFamily<List<SeancePlanning>, DateTime>
planningSemaineProvider = FutureProvider.family<List<SeancePlanning>, DateTime>(
  (Ref ref, DateTime lundi) {
    final PortPlanningDirection? port = ref.watch(
      portPlanningDirectionProvider,
    );
    if (port == null) {
      return Future<List<SeancePlanning>>.error(
        const CapaciteIndisponible(dependancePlanningDirection),
      );
    }
    return port.semaine(lundi);
  },
  retry: (int _, Object _) => null,
);
