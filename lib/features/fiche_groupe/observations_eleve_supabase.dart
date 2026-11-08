// NON-BRANCHE-LIVRAISON 1 (08/11/2026) : l'adaptateur Supabase des
// observations du cahier. Une RPC de la migration 20261110610000 :
// `observations_classe(p_groupe_id uuid)`. Le serveur porte la garde (memes
// lecteurs que la position de reprise : direction, titulaire, remplacant ;
// 42501 sinon).

import 'package:supabase_flutter/supabase_flutter.dart';

import 'observations_eleve.dart';

/// Les observations lues sur Supabase.
class ObservationsClasseSupabase implements PortObservationsClasse {
  /// Cree l'adaptateur.
  const ObservationsClasseSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, ObservationsEleve>> observationsDeLaClasse(
    String groupeId,
  ) async {
    final Object? brut = await _client.rpc<Object?>(
      'observations_classe',
      params: <String, Object?>{'p_groupe_id': groupeId},
    );
    return observationsDepuisReponse(brut);
  }
}
