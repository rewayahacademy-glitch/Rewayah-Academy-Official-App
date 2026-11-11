// LUMIERE-RETARD (11/11/2026) : l'adaptateur serveur de `retard_en_direct(uuid)`
// (migration 20261122700000). Branche `portRetardEnDirectProvider` dans
// `lib/main.dart`. Une ligne mal formee est ignoree, jamais devinee ; une
// reponse qui n'est pas une liste est une erreur (le fournisseur emet `null`).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'retard_en_direct.dart';

/// Les lignes de `retard_en_direct` en eleves en retard.
List<EleveEnRetard> retardsDepuisLignes(Object? lignes) {
  if (lignes is! List<dynamic>) {
    throw const FormatException('Retards en direct invalides');
  }
  final List<EleveEnRetard> retards = <EleveEnRetard>[];
  for (final Object? ligne in lignes) {
    if (ligne is! Map<String, dynamic>) continue;
    final Object? id = ligne['student_id'];
    final Object? secondes = ligne['retard_secondes'];
    if (id is! String || id.isEmpty || secondes is! int) continue;
    retards.add(EleveEnRetard(eleveId: id, retardSecondes: secondes));
  }
  return retards;
}

/// L'adaptateur serveur.
class RetardEnDirectSupabase implements PortRetardEnDirect {
  /// Cree l'adaptateur.
  const RetardEnDirectSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EleveEnRetard>?> pour(String seanceId) async {
    final Object? reponse = await _client.rpc<Object?>(
      'retard_en_direct',
      params: <String, dynamic>{'p_session_id': seanceId},
    );
    return retardsDepuisLignes(reponse);
  }
}
