import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_capacite_eleve.dart';

class PortCapaciteEleveSupabase implements PortCapaciteEleve {
  const PortCapaciteEleveSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<CapaciteEleve> lire(String profileId) async {
    // L'identifiant ne part jamais en argument de RPC : ma_capacite_eleve()
    // derive la personne uniquement de auth.uid(). Le parametre associe la
    // lecture a la cle de cache deja validee par SessionControleur.
    if (profileId.isEmpty) {
      return const CapaciteInconnue();
    }
    try {
      final Object? value = await _client.rpc<Object?>('ma_capacite_eleve');
      if (value is bool) {
        return value ? const EleveAutonome() : const PasEleve();
      }
      return const CapaciteInconnue();
    } on Object {
      return const CapaciteInconnue();
    }
  }
}
