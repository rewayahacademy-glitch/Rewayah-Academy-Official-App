// SUIVI-ELEVE (07/11/2026) : l'adaptateur Supabase du suivi pedagogique, sur
// la RPC `suivi_pedagogique_eleve` (migration 20261115000000, lecture seule).
// Le serveur porte la garde et calcule la vitesse ; l'adaptateur ne fait que
// lire.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_suivi_pedagogique.dart';

/// Le suivi pedagogique servi par Supabase.
class SuiviPedagogiqueSupabase implements PortSuiviPedagogique {
  /// Cree l'adaptateur.
  const SuiviPedagogiqueSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<SuiviPedagogique?> pourEleve(String eleveId) async =>
      SuiviPedagogique.depuisJson(
        await _client.rpc<Object?>(
          'suivi_pedagogique_eleve',
          params: <String, Object?>{'p_eleve_id': eleveId},
        ),
      );
}
