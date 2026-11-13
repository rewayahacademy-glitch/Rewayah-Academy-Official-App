// MA-PROGRESSION-ECRAN (12/11/2026) : l'adaptateur Supabase de la progression
// de l'eleve, sur la RPC `ma_progression` (migration 20261123830000, lecture
// seule). Le serveur porte la garde et calcule tout ; l'adaptateur ne fait
// que lire. Une seule RPC : l'etape, les etapes du cycle, les sourates et le
// reglage viennent ensemble.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'ma_progression.dart';

/// La progression servie par Supabase.
class MaProgressionSupabase implements PortMaProgression {
  /// Cree l'adaptateur.
  const MaProgressionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<MaProgression?> pourEleve(String eleveId) async {
    final Object? brut = await _client.rpc<Object?>(
      'ma_progression',
      params: <String, Object?>{'p_student_id': eleveId},
    );
    return MaProgression.depuisJson(brut);
  }
}

/// Le reglage de la progression par la direction, servi par Supabase
/// (`reglages_progression_admin`, `regler_etape_progression`).
class ReglagesProgressionSupabase implements PortReglagesProgression {
  /// Cree l'adaptateur.
  const ReglagesProgressionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ReglageParEtape>> lire() async {
    final Object? brut = await _client.rpc<Object?>(
      'reglages_progression_admin',
    );
    if (brut is! List) return const <ReglageParEtape>[];
    return <ReglageParEtape>[
      for (final Object? ligne in brut)
        if (ligne is Map && '${ligne['code_technique'] ?? ''}'.isNotEmpty)
          ReglageParEtape(
            codeTechnique: '${ligne['code_technique']}',
            heuresRevisionSemaine: switch (ligne['heures_revision_semaine']) {
              final num h => h.toDouble(),
              _ => null,
            },
            repetitionsEstimees: switch (ligne['repetitions_estimees']) {
              final num n => n.toInt(),
              _ => null,
            },
          ),
    ];
  }

  @override
  Future<void> regler({
    required String codeTechnique,
    double? heuresRevisionSemaine,
    int? repetitionsEstimees,
  }) async {
    await _client.rpc<Object?>(
      'regler_etape_progression',
      params: <String, Object?>{
        'p_code_technique': codeTechnique,
        'p_heures_revision_semaine': heuresRevisionSemaine,
        'p_repetitions_estimees': repetitionsEstimees,
      },
    );
  }
}
