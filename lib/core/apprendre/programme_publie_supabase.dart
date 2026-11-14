// PROGRAMME-PUBLIE (14/11/2026) : l'adaptateur Supabase du programme publie,
// sur la RPC `programme_publie` (migration 20261125610000, lecture seule). Le
// serveur porte la garde et decide de ce qui sort ; l'adaptateur ne fait que
// lire.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'programme_publie.dart';

/// Le programme publie, servi par Supabase.
class ProgrammePublieSupabase implements PortProgrammePublie {
  /// Cree l'adaptateur.
  const ProgrammePublieSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ProgrammePublie> pourEleve(String eleveId) async {
    final Object? brut = await _client.rpc<Object?>(
      'programme_publie',
      params: <String, Object?>{'p_eleve_id': eleveId},
    );
    return ProgrammePublie.depuisJson(brut);
  }
}
