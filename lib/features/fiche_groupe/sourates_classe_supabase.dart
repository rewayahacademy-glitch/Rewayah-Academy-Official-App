// SOURATES (11/11/2026) : l'adaptateur Supabase des sourates des eleves
// d'une Classe. Une RPC de la migration 20261122900000 :
// `sourates_bases_classe`. Le serveur porte la garde (titulaire, remplacant
// de la seance, direction en lecture).

import 'package:supabase_flutter/supabase_flutter.dart';

import 'sourates_classe.dart';

/// Les sourates des eleves lues sur Supabase.
class SouratesClasseSupabase implements PortSouratesClasse {
  /// Cree l'adaptateur.
  const SouratesClasseSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, List<SourateBases>>> souratesDeLaClasse(
    String groupeId,
  ) async {
    final Object? brut = await _client.rpc<Object?>(
      'sourates_bases_classe',
      params: <String, Object?>{'p_groupe_id': groupeId},
    );
    return souratesDepuisReponse(brut);
  }
}
