import 'package:supabase_flutter/supabase_flutter.dart';

import 'codec_etat_partage.dart';
import 'port_etat_partage_persistant.dart';
import 'shared_content_state.dart';

/// Persistance Supabase de l'etat courant d'une seance.
///
/// L'identite et l'autorisation restent derivees du JWT et des gardes SQL.
/// Cet adaptateur ne transmet jamais `updated_by` ni `updated_at` comme
/// autorite : la RPC les fixe cote serveur.
class EtatPartageSupabase implements PortEtatPartagePersistant {
  const EtatPartageSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<SharedContentState?> lire(String sessionId) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from('session_shared_content')
          .select()
          .eq('session_id', sessionId)
          .maybeSingle();
      if (row == null) return null;

      final Map<String, dynamic> payload = Map<String, dynamic>.from(row);
      final DateTime? updatedAt = DateTime.tryParse(
        payload['updated_at']?.toString() ?? '',
      );
      if (updatedAt == null) {
        throw const FormatException('Horodatage etat partage invalide');
      }
      payload['updated_at'] = updatedAt.toUtc().millisecondsSinceEpoch;

      final SharedContentState? etat = etatDepuisJson(payload);
      if (etat == null || etat.sessionId != sessionId) {
        throw const FormatException('Etat partage Supabase invalide');
      }
      return etat;
    } on FormatException {
      rethrow;
    } catch (error) {
      throw _echec(error);
    }
  }

  @override
  Future<SharedContentState> enregistrer(SharedContentState etat) async {
    try {
      final Map<String, dynamic> payload = etatVersJson(etat);
      final dynamic resultat = await _client.rpc(
        'publier_etat_partage',
        params: <String, dynamic>{
          'p_session_id': etat.sessionId,
          'p_resource_id': etat.resourceId,
          'p_resource_version_id': etat.resourceVersionId,
          'p_content_position': payload['content_position'],
          'p_content_range': payload['content_range'],
          'p_display_mode': payload['display_mode'],
          'p_hidden_ranges': payload['hidden_ranges'],
          'p_semantic_markers': payload['semantic_markers'],
          'p_group_resume_position': payload['group_resume_position'],
          'p_revision': etat.revision,
        },
      );

      if (resultat is! Map) {
        throw const FormatException('Reponse RPC etat partage invalide');
      }
      final Map<String, dynamic> row = Map<String, dynamic>.from(resultat);
      final DateTime? updatedAt = DateTime.tryParse(
        row['updated_at']?.toString() ?? '',
      );
      if (updatedAt == null) {
        throw const FormatException('Horodatage RPC etat partage invalide');
      }
      row['updated_at'] = updatedAt.toUtc().millisecondsSinceEpoch;

      final SharedContentState? stocke = etatDepuisJson(row);
      if (stocke == null || stocke.sessionId != etat.sessionId) {
        throw const FormatException('Etat partage RPC invalide');
      }
      if (stocke.revision != etat.revision) {
        throw EchecEtatPartage(
          MotifEchecEtatPartage.revisionObsolete,
          revisionStockee: stocke.revision,
        );
      }
      return stocke;
    } on EchecEtatPartage {
      rethrow;
    } on FormatException {
      rethrow;
    } catch (error) {
      throw _echec(error);
    }
  }

  @override
  Future<void> effacer(String sessionId) async {
    try {
      await _client.rpc<void>(
        'effacer_etat_partage',
        params: <String, dynamic>{'p_session_id': sessionId},
      );
    } catch (error) {
      throw _echec(error);
    }
  }

  EchecEtatPartage _echec(Object error) {
    if (error is PostgrestException && error.code == '42501') {
      return const EchecEtatPartage(MotifEchecEtatPartage.droitRefuse);
    }
    if (error is PostgrestException &&
        const <String>{
          '42P01',
          '42883',
          'PGRST202',
          'PGRST205',
        }.contains(error.code)) {
      return const EchecEtatPartage(MotifEchecEtatPartage.persistanceAbsente);
    }
    return const EchecEtatPartage(MotifEchecEtatPartage.reseau);
  }
}
