import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_delais.dart';
import 'nom_propre.dart';

/// NOM-PROPRE : `mon_nom_a_corriger()` et `corriger_mon_nom()` (migration
/// 20261125950000).
class NomPropreSupabase implements PortNomPropre {
  /// Cree l'adaptateur.
  const NomPropreSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<EtatNomPropre> lire() async => EtatNomPropre.depuisJson(
    await _client
        .rpc<Object?>('mon_nom_a_corriger')
        .timeout(AppDelais.requeteMax),
  );

  @override
  Future<void> corriger({required String prenom, required String nom}) async {
    try {
      await _client.rpc<Object?>(
        'corriger_mon_nom',
        params: <String, dynamic>{
          'p_first_name': prenom.trim(),
          'p_last_name': nom.trim(),
        },
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('nom_non_conforme')) {
        throw const NomNonConforme();
      }
      rethrow;
    }
  }
}
