import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_capacite_eleve.dart';

/// Lit la capacite de la session en cours via la RPC derivee de auth.uid().
/// L'identifiant du port sert au cache de session; il n'est jamais transmis.
final class PortCapaciteEleveSupabase implements PortCapaciteEleve {
  const PortCapaciteEleveSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<CapaciteEleve> lire(String _) async {
    try {
      final Object? resultat = await _client.rpc<Object?>('ma_capacite_eleve');
      if (resultat is bool) {
        return resultat ? const EleveAutonome() : const PasEleve();
      }
    } on Object {
      // Erreur, expiration de session ou contrat inconnu : fermeture par defaut.
    }
    return const CapaciteInconnue();
  }
}
