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
      dernierJalonLe: dateDernierJalon(reponse['seances']),
    );
  }
}

/// Le jour de la derniere publication d'un resume qui porte un jalon : la
/// premiere seance (les plus recentes d'abord) dont `jalon_humain` est rempli.
/// Nul si aucune ne l'est ou si la liste est illisible. Pure, pour les tests.
DateTime? dateDernierJalon(Object? seances) {
  if (seances is! List<Object?>) return null;
  for (final Object? s in seances) {
    if (s is Map<Object?, Object?> &&
        '${s['jalon_humain'] ?? ''}'.trim().isNotEmpty) {
      return DateTime.tryParse('${s['publie_le']}');
    }
  }
  return null;
}
