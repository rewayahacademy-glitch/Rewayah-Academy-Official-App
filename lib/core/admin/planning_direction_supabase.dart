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
    // HEURES-PROFIL H5 (12/11/2026) : les bornes sont les lundis 00 h au
    // fuseau du PROFIL, plus ceux de l'appareil.
    final ({DateTime debut, DateTime fin}) b = bornesSemaineChezMoi(lundi);
    final Map<String, SeancePlanning> parId = <String, SeancePlanning>{};
    for (final SeancePlanning s in await _lire(b.debut)) {
      parId[s.id] = s;
    }
    // Pourquoi un second appel : `lister_planning_direction` lit toujours
    // `[p_lundi, p_lundi + 7 jours)`, soit 168 heures (session en UTC). Une
    // semaine murale qui contient le passage a l'heure d'hiver du profil dure
    // 169 heures : la derniere heure (dimanche 23 h) manquerait. Plutot
    // qu'une migration, on relit les 168 heures qui finissent au lundi
    // suivant et on fusionne par identifiant, sans doublon. Seuls les profils
    // a heure d'ete, deux semaines par an, font ce second appel.
    if (b.fin.difference(b.debut) > const Duration(days: 7)) {
      for (final SeancePlanning s in await _lire(
        b.fin.subtract(const Duration(days: 7)),
      )) {
        parId[s.id] = s;
      }
    }
    // Une semaine de 167 heures (passage a l'heure d'ete) : le serveur rend
    // une heure du lundi suivant, qui n'est pas de cette semaine.
    final List<SeancePlanning> result =
        parId.values
            .where(
              (SeancePlanning s) =>
                  !s.debut.isBefore(b.debut) && s.debut.isBefore(b.fin),
            )
            .toList()
          ..sort((SeancePlanning x, SeancePlanning y) {
            final int c = x.debut.compareTo(y.debut);
            return c != 0 ? c : x.id.compareTo(y.id);
          });
    return result;
  }

  /// Toutes les pages de la RPC a partir de l'instant [depuis].
  Future<List<SeancePlanning>> _lire(DateTime depuis) async {
    final List<SeancePlanning> result = <SeancePlanning>[];
    var offset = 0;
    while (true) {
      final List<dynamic> rows = await _client.rpc<List<dynamic>>(
        'lister_planning_direction',
        params: <String, dynamic>{
          'p_lundi': depuis.toUtc().toIso8601String(),
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
