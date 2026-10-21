import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import 'port_planning_direction.dart';

/// Supabase adapter for the weekly direction schedule.
class PlanningDirectionSupabase implements PortPlanningDirection {
  const PlanningDirectionSupabase(this._client);
  final SupabaseClient _client;
  static const int _pageSize = 100;

  @override
  Future<List<SeancePlanning>> semaine(DateTime lundi) async {
    final List<SeancePlanning> result = <SeancePlanning>[];
    var offset = 0;
    while (true) {
      final List<dynamic> rows = await _client.rpc<List<dynamic>>(
        'lister_planning_direction',
        params: <String, dynamic>{
          'p_lundi': DateTime(
            lundi.year,
            lundi.month,
            lundi.day,
          ).toUtc().toIso8601String(),
          'p_limite': _pageSize,
          'p_offset': offset,
        },
      );
      for (final dynamic item in rows) {
        final Map<String, dynamic> row = Map<String, dynamic>.from(item as Map);
        final StatutSeance? status = StatutSeance.depuisSql(
          row['statut'] as String?,
        );
        final DateTime? start = DateTime.tryParse(
          row['debut'] as String? ?? '',
        );
        if (status == null || start == null) {
          throw const FormatException('Réponse RPC planning invalide');
        }
        result.add(
          SeancePlanning(
            id: row['id'] as String,
            classe: row['classe'] as String? ?? '',
            debut: start.toLocal(),
            dureeMinutes: row['duree_minutes'] as int,
            statut: status,
            enseignant: row['enseignant'] as String?,
          ),
        );
      }
      if (rows.length < _pageSize) return result;
      offset += _pageSize;
    }
  }
}
