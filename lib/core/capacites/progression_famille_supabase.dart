import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_progression_famille.dart';

/// Projection serveur des jalons validés et rendus en mots humains.
class ProgressionFamilleSupabase implements PortProgressionFamille {
  const ProgressionFamilleSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ProgressionEleve> progression(String eleveId) async {
    final Map<String, dynamic> reponse = await _client
        .rpc<Map<String, dynamic>>(
          'progression_famille',
          params: <String, dynamic>{'p_student_id': eleveId},
        );
    final Object? jalons = reponse['jalons'];
    if (jalons is! List<dynamic>) {
      throw const FormatException('Jalons de progression invalides');
    }
    return ProgressionEleve(
      eleveId: eleveId,
      niveauHumain: reponse['niveau_humain'] as String?,
      jalons: jalons.cast<String>(),
    );
  }
}
