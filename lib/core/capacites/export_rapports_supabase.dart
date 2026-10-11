// Adaptateur CPT-BR-19: le serveur génère et journalise le CSV.
import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_export_rapports.dart';

/// Appelle les RPC d'export sans construire le fichier côté Flutter.
class ExportRapportsSupabase implements PortExportRapports {
  /// Crée l'adaptateur avec le client authentifié de l'application.
  const ExportRapportsSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ResultatExport> exporterRapport({
    required String cleIdempotence,
  }) async => decoder(
    await _client.rpc(
      'exporter_rapport_comptable',
      params: <String, dynamic>{'p_cle': cleIdempotence},
    ),
  );

  @override
  Future<ResultatExport> exporterSelection({
    required List<String> identifiants,
    required String cleIdempotence,
  }) async => decoder(
    await _client.rpc(
      'exporter_selection_comptable',
      params: <String, dynamic>{'p_ids': identifiants, 'p_cle': cleIdempotence},
    ),
  );

  /// Valide le contrat minimal renvoyé par la source.
  static ResultatExport decoder(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('objet export invalide');
    }
    final Object? reference = value['reference'];
    final Object? lignes = value['lignes'];
    if (reference is! String ||
        !RegExp(r'^EXP-\d{8}-[A-Z0-9]{6}$').hasMatch(reference) ||
        lignes is! int ||
        lignes < 0 ||
        lignes > 5000) {
      throw const FormatException('résultat export invalide');
    }
    return ResultatExport(reference: reference, lignes: lignes);
  }
}
