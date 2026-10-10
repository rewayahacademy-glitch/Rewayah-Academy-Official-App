import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_capacite_eleve.dart';

class PortCapaciteEleveSupabase implements PortCapaciteEleve {
  const PortCapaciteEleveSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<CapaciteEleve> lire() async {
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
