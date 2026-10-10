import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_progression_famille.dart';

/// Projection serveur des jalons validés et rendus en mots humains.
class ProgressionFamilleSupabase implements PortProgressionFamille {
  const ProgressionFamilleSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ProgressionEleve> progression(String eleveId) async {
    final Object? reponse = await _client.rpc<dynamic>(
      'progression_famille',
      params: <String, dynamic>{'p_student_id': eleveId, 'p_limit': 20},
    );
    if (reponse is! Map) {
      throw const FormatException('La progression doit être un objet JSON.');
    }
    if (reponse.keys.any((dynamic key) => key is! String)) {
      throw const FormatException(
        'Les clés de progression doivent être textuelles.',
      );
    }
    final Map<String, dynamic> json = <String, dynamic>{
      for (final MapEntry<dynamic, dynamic> entry in reponse.entries)
        entry.key as String: entry.value,
    };
    final Object? jalons = json['jalons'];
    if (jalons is! List || jalons.any((dynamic jalon) => jalon is! String)) {
      throw const FormatException(
        'Les jalons doivent être une liste de textes.',
      );
    }
    final Object? niveau = json['niveau_humain'];
    if (niveau != null && niveau is! String) {
      throw const FormatException(
        'Le niveau humain doit être un texte ou nul.',
      );
    }
    return ProgressionEleve(
      eleveId: eleveId,
      niveauHumain: niveau as String?,
      jalons: List<String>.unmodifiable(jalons.cast<String>()),
    );
  }
}
