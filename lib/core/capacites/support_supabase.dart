import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_support.dart';

/// Adaptateur du canal de support configuré dans app_config.
class SupportSupabase implements PortSupport {
  const SupportSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<CanalSupport?> canal() async {
    final List<dynamic> rows = await _client.rpc<List<dynamic>>('canal_support');
    if (rows.isEmpty) {
      return null;
    }
    if (rows.length != 1 || rows.single is! Map<String, dynamic>) {
      throw const FormatException('Réponse canal_support invalide');
    }

    final Map<String, dynamic> row = rows.single as Map<String, dynamic>;
    final String? type = row['nature'] as String?;
    final String? adresse = row['adresse'] as String?;
    final NatureCanalSupport? nature = switch (type) {
      'courriel' => NatureCanalSupport.courriel,
      'lien' => NatureCanalSupport.lien,
      _ => null,
    };
    if (nature == null || adresse == null || adresse.trim().isEmpty) {
      throw const FormatException('Canal de support invalide');
    }
    return CanalSupport(nature: nature, adresse: adresse.trim());
  }
}
