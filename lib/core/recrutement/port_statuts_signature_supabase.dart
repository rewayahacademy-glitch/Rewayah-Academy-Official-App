import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_statuts_signature.dart';

/// Adaptateur du RPC qui calcule les statuts selon les versions serveur.
final class StatutsSignatureSupabase implements PortStatutsSignature {
  const StatutsSignatureSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<StatutsSignature?> pour(String dossierId) async {
    try {
      final Object? result = await _client.rpc<Object?>(
        'teacher_signature_statuses',
        params: <String, dynamic>{'p_profile_id': dossierId},
      );
      if (result is! Map<String, dynamic>) {
        throw const FormatException('teacher_signature_statuses invalide');
      }
      return StatutsSignature(
        contrat: _statut(result['contrat']),
        accuse: _statut(result['accuse']),
      );
    } on PostgrestException catch (error) {
      if (error.code == 'P0002') return null;
      rethrow;
    }
  }

  static StatutSignature _statut(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('statut de signature invalide');
    }
    return switch (value['status']) {
      'signe_version_courante' => const SigneVersionCourante(),
      'non_signe' => const NonSigne(),
      'signe_ancienne_version' => _ancienneVersion(value),
      _ => throw const FormatException('statut de signature inconnu'),
    };
  }

  static SigneAncienneVersion _ancienneVersion(Map<String, dynamic> value) {
    final Object? version = value['version_signee'];
    if (version is! String || version.trim().isEmpty) {
      throw const FormatException('version de signature absente');
    }
    return SigneAncienneVersion(version);
  }
}
