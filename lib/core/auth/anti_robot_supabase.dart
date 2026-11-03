// ANTI-ROBOT (03/11/2026) : la cle PUBLIQUE du widget Turnstile, lue sans
// compte par `public.turnstile_cle_site()` (migration 20261109000000).

import 'package:supabase_flutter/supabase_flutter.dart';

import 'anti_robot.dart';

/// La cle publique servie par Supabase.
class CleTurnstileSupabase implements PortCleTurnstile {
  /// Cree l'adaptateur.
  const CleTurnstileSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<String?> lire() async {
    final Object? brut = await _client.rpc<Object?>('turnstile_cle_site');
    return brut is String ? brut : null;
  }
}
