import 'package:supabase_flutter/supabase_flutter.dart';

import 'concierge_seance.dart';

/// Le motif d'un refus de `seance_a_rejoindre`, ou `null` si l'erreur n'en
/// est pas un (panne, reseau). Pure, testable sans client.
MotifRefusConcierge? motifRefusConcierge({String? code, String? message}) {
  if (code == '42501' || (message ?? '').contains('SeanceNonAutorisee')) {
    return MotifRefusConcierge.nonAutorise;
  }
  if (code == '22023' || (message ?? '').contains('ClasseInconnue')) {
    return MotifRefusConcierge.classeInconnue;
  }
  return null;
}

/// L'adaptateur de `seance_a_rejoindre(p_groupe_id)`.
class ConciergeSupabase implements PortConcierge {
  /// Cree l'adaptateur.
  const ConciergeSupabase(this._client);

  final SupabaseClient _client;

  /// Un refus (42501, 22023) arrive en [RefusConcierge], jamais avec le texte
  /// SQL ; les autres erreurs passent telles quelles.
  @override
  Future<String?> seanceARejoindre(String groupeId) async {
    try {
      final Object? id = await _client.rpc<Object?>(
        'seance_a_rejoindre',
        params: <String, dynamic>{'p_groupe_id': groupeId},
      );
      return id is String && id.isNotEmpty ? id : null;
    } on PostgrestException catch (e) {
      final MotifRefusConcierge? motif = motifRefusConcierge(
        code: e.code,
        message: e.message,
      );
      if (motif == null) rethrow;
      throw RefusConcierge(motif);
    }
  }
}
