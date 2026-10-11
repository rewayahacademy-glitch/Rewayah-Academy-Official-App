import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_capacite_eleve.dart';

/// Lit la capacite de l'utilisateur connecte sans jamais interroger un tiers.
///
/// La RPC `ma_capacite_eleve()` tire l'identite de `auth.uid()` et n'accepte
/// aucun identifiant client. L'identifiant du port sert uniquement a fermer
/// le flux si la session a change avant la lecture.
class PortCapaciteEleveSupabase implements PortCapaciteEleve {
  const PortCapaciteEleveSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<CapaciteEleve> lire(String profileId) async {
    if (_client.auth.currentUser?.id != profileId) {
      return const CapaciteInconnue();
    }
    try {
      final bool reponse = await _client.rpc<bool>('ma_capacite_eleve');
      return reponse ? const EleveAutonome() : const PasEleve();
    } on Object {
      return const CapaciteInconnue();
    }
  }
}
