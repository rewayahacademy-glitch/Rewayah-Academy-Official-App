// L'adaptateur Supabase de `PortAttentesRecrutement` : la RPC
// `attentes_recrutement()` (migration 20261126400000). Les refus sont typés
// comme ceux de la file (`CandidaturesDirectionSupabase`).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'attentes_recrutement.dart';
import 'port_candidatures_direction.dart' show GenreLecteurInconnu;

/// L'adaptateur.
class AttentesRecrutementSupabase implements PortAttentesRecrutement {
  /// Cree l'adaptateur sur [_client].
  AttentesRecrutementSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<AttentesRecrutement> lire() async {
    try {
      return AttentesRecrutement.depuisJson(
        await _client.rpc<Object?>('attentes_recrutement'),
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        if (e.message.contains('genre du lecteur inconnu')) {
          throw const GenreLecteurInconnu();
        }
        throw const PermissionInsuffisante('attentes_recrutement');
      }
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceAttentesRecrutement);
      }
      rethrow;
    }
  }
}
