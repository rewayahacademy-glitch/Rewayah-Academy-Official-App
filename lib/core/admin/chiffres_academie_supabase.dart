// L'adaptateur Supabase des chiffres de l'academie, sur la RPC
// `chiffres_academie` (migration 20261130969500). Un appel, quelques
// centaines d'octets ; le serveur compte tout et memorise 10 minutes ce qui
// coute.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_chiffres_academie.dart';

/// Les chiffres servis par Supabase.
class ChiffresAcademieSupabase implements PortChiffresAcademie {
  /// Cree l'adaptateur sur le client de l'application.
  const ChiffresAcademieSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ChiffresAcademie> lire() async {
    final Object? brut = await _client.rpc<Object?>('chiffres_academie');
    if (brut is! Map) throw const FormatException('Objet attendu.');
    return ChiffresAcademie.json(Map<String, dynamic>.from(brut));
  }
}
