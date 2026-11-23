// FICHE-ELEVE-DIRECTION (22/11/2026) : l'adaptateur Supabase de la fiche,
// sur la RPC `fiche_eleve_direction` (migration 20261201010000). Le serveur
// decide de tout ; l'adaptateur lit, il ne calcule rien.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'fiche_eleve_direction.dart';

/// La fiche d'un eleve servie par Supabase.
class FicheEleveDirectionSupabase implements PortFicheEleveDirection {
  /// Cree l'adaptateur.
  const FicheEleveDirectionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<FicheEleveDirection?> lire(String eleveId) async =>
      FicheEleveDirection.depuisJson(
        await _client.rpc<Object?>(
          'fiche_eleve_direction',
          params: <String, dynamic>{'p_eleve_id': eleveId},
        ),
      );

  @override
  Future<ResultatDemandePaiement> demanderPaiement(String eleveId) async {
    final Object? r = await _client.rpc<Object?>(
      'demander_paiement_maintenant',
      params: <String, dynamic>{'p_profil': eleveId},
    );
    final int avertis = r is Map && r['avertis'] is num
        ? (r['avertis'] as num).toInt()
        : 0;
    return avertis > 0
        ? ResultatDemandePaiement.demandee
        : ResultatDemandePaiement.rienAPayer;
  }
}
