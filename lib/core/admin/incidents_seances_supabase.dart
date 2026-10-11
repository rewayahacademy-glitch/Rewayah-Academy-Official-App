import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import 'port_incidents_seances.dart';

/// Supabase adapter for the read-only, RLS-checked incident RPC.
class IncidentsSeancesSupabase implements PortIncidentsSeances {
  const IncidentsSeancesSupabase(this._client);

  final SupabaseClient _client;
  static const int _pageSize = 100;

  @override
  Future<List<IncidentSeance>> dernieres24h(DateTime maintenant) async {
    final List<IncidentSeance> result = <IncidentSeance>[];
    var offset = 0;
    while (true) {
      final List<dynamic> rows = await _client.rpc<List<dynamic>>(
        'lister_incidents_seances',
        params: <String, dynamic>{
          'p_maintenant': maintenant.toUtc().toIso8601String(),
          'p_limite': _pageSize,
          'p_offset': offset,
        },
      );
      for (final dynamic item in rows) {
        final Map<String, dynamic> row = Map<String, dynamic>.from(item as Map);
        final StatutSeance? status = StatutSeance.depuisSql(
          row['statut'] as String?,
        );
        final DateTime? at = DateTime.tryParse(
          row['survenu_le'] as String? ?? '',
        );
        if (status == null || !statutsIncident.contains(status) || at == null) {
          throw const FormatException('Réponse RPC incident invalide');
        }
        result.add(
          IncidentSeance(
            id: row['id'] as String,
            classe: row['classe'] as String? ?? '',
            statut: status,
            survenuLe: at,
            enseignant: row['enseignant'] as String?,
          ),
        );
      }
      if (rows.length < _pageSize) return result;
      offset += _pageSize;
    }
  }
}
