// ALERTE-1 : la source des alertes de la direction, port neutre.
//
// Aucun branchement serveur avant BR-1 (ordre du directeur du 04/10 : « tout
// ce qui est serveur tu le consignes et tu passes a la suite »). Les besoins
// sont consignes dans `docs/current/DASH_STRATEGIE.md`, section 5 bis :
// gravite et lecture triee (DASH-BR-03), temps reel par profil sous RLS
// (DASH-BR-04), Web Push puis natif (DASH-BR-05), delai mesure (DASH-BR-06).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import 'alerte.dart';

/// Les alertes ouvertes du profil connecte, suivies en continu.
///
/// Un flux et non une lecture : une alerte qui arrive (Supabase Realtime,
/// canal par profil sous RLS, DASH-BR-04) s'affiche sans recharger. Une
/// alerte traitee sort du flux ; le traitement se fait sur sa page.
abstract interface class PortAlertes {
  /// Chaque emission est la liste COMPLETE des alertes ouvertes.
  Stream<List<Alerte>> suivre();
}

/// La source tant qu'aucune n'existe (DASH-BR-03) : « indisponible », jamais
/// une liste vide qui ferait croire que rien n'attend.
class AlertesIndisponibles implements PortAlertes {
  /// Cree l'implementation.
  const AlertesIndisponibles();

  /// Ce qui manque.
  static const String dependance = 'DASH-BR-03';

  @override
  Stream<List<Alerte>> suivre() =>
      Stream<List<Alerte>>.error(const CapaciteIndisponible(dependance));
}

/// La source employee par l'application. Production : indisponible ;
/// demonstration admin : `AlertesDemo`.
final Provider<PortAlertes> portAlertesProvider = Provider<PortAlertes>(
  (Ref ref) => const AlertesIndisponibles(),
);

/// Les alertes ouvertes, dans l'ordre de lecture ([trierAlertes]).
final StreamProvider<List<Alerte>> alertesProvider =
    StreamProvider<List<Alerte>>(
      (Ref ref) => ref.watch(portAlertesProvider).suivre().map(trierAlertes),
    );

/// La capacite « alertes » lue par la coquille et les ecrans : le nombre
/// d'alertes urgentes ouvertes, ou `null` tant que la source ne rend rien
/// (indisponible, en echec, pas encore lue). Jamais deduite d'un role.
final Provider<int?> alertesUrgentesProvider = Provider<int?>((Ref ref) {
  final AsyncValue<List<Alerte>> alertes = ref.watch(alertesProvider);
  if (!alertes.hasValue) {
    return null;
  }
  return alertes.requireValue.where((Alerte a) => a.urgente).length;
});
