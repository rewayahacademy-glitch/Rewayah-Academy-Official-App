import 'package:flutter/material.dart' show DateTimeRange;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_historique_observations.dart';

/// L'historique des observations du tuteur, lu dans `guardian_session_visit`
/// sous RLS (contrat K4, lot E du chantier Tuteur V1).
///
/// **Une seule source, aucune ecriture.** La policy de la table rend a
/// l'observateur ses propres lignes (`0032_tc_catalogue.sql`, observateur =
/// soi) : le client ne filtre rien par personne, il ne fait que restreindre
/// par enfant et par periode. Le groupement par (seance, enfant) est celui de
/// [grouperObservations], partage avec la consultation admin.
///
/// **Ce que la table ne dit pas, l'ecran ne le dit pas** : le motif de fin
/// ecrit par le serveur est toujours « sortie volontaire » (DB-OBS-04), il
/// n'est donc jamais affiche ; une visite sans sortie reste « sortie non
/// enregistree » (aucune fermeture serveur, DB-OBS-03).
///
/// Branchement : le provider de production vit dans le fichier du port
/// (coordinateur, demande E-7) ; tant qu'il n'y est pas, l'ecran dit
/// « indisponible ».
class HistoriqueObservationsSupabase implements PortHistoriqueObservations {
  /// Cree l'adaptateur. Le client est lu a la demande : un ecran monte sans
  /// Supabase initialise n'echoue pas a la construction.
  const HistoriqueObservationsSupabase(this._client);

  final SupabaseClient Function() _client;

  /// Le nombre de visites lues d'un coup. Deux visites par seance au plus
  /// (politique effective) : deux cents lignes couvrent au moins cent seances.
  static const int plafond = 200;

  static const String _colonnes =
      'id, session_id, groupe_id, observateur_profile_id, role, '
      'enfant_profile_id, entered_at, left_at, duration_seconds, '
      'visit_number, policy_version, fin_de_visite';

  @override
  Future<List<ObservationsSeance>> mesObservations({
    String? enfantId,
    DateTimeRange? periode,
  }) async {
    PostgrestFilterBuilder<List<Map<String, dynamic>>> requete = _client()
        .from('guardian_session_visit')
        .select(_colonnes)
        .eq('role', 'guardian_observer');
    if (enfantId != null) {
      requete = requete.eq('enfant_profile_id', enfantId);
    }
    if (periode != null) {
      requete = requete
          .gte('entered_at', periode.start.toUtc().toIso8601String())
          .lt('entered_at', periode.end.toUtc().toIso8601String());
    }
    // Le sens du tri s'ecrit (registre, section 1 ter bis) : les visites les
    // plus recentes d'abord, pour que le plafond coupe les plus anciennes.
    final List<Map<String, dynamic>> lignes = await requete
        .order('entered_at', ascending: false)
        .limit(plafond);
    return grouperObservations(lignes);
  }

  @override
  Future<ObservationsSeance?> detail({
    required String seanceId,
    String? enfantId,
  }) async {
    PostgrestFilterBuilder<List<Map<String, dynamic>>> requete = _client()
        .from('guardian_session_visit')
        .select(_colonnes)
        .eq('role', 'guardian_observer')
        .eq('session_id', seanceId);
    if (enfantId != null) {
      requete = requete.eq('enfant_profile_id', enfantId);
    }
    // Par rang croissant : « Visite 1 » puis « Visite 2 ».
    final List<Map<String, dynamic>> lignes = await requete.order(
      'visit_number',
      ascending: true,
    );
    final List<ObservationsSeance> groupes = grouperObservations(lignes);
    return groupes.isEmpty ? null : groupes.first;
  }
}
