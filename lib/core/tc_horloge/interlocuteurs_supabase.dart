import 'package:supabase_flutter/supabase_flutter.dart';

import 'fuseaux_interlocuteurs.dart';
import 'port_interlocuteurs.dart';

/// L'adaptateur de `public.horloge_interlocuteurs(p_groupe)` (migration
/// 20261109500000, installee en production le 04/11/2026).
class InterlocuteursSupabase implements PortInterlocuteurs {
  /// Cree l'adaptateur.
  const InterlocuteursSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<InterlocuteursClasse?> lire(String groupeId) async {
    try {
      final Object? brut = await _client.rpc<Object?>(
        'horloge_interlocuteurs',
        params: <String, dynamic>{'p_groupe': groupeId},
      );
      return InterlocuteursClasse.lire(brut);
    } on PostgrestException catch (e) {
      // 42501 : la classe ne concerne pas l'appelant. PGRST202 et 42883 : la
      // fonction n'est pas encore installee. Dans les deux cas, pas de
      // seconde heure, jamais une heure fabriquee.
      if (e.code == '42501' || e.code == 'PGRST202' || e.code == '42883') {
        return null;
      }
      rethrow;
    }
  }
}
