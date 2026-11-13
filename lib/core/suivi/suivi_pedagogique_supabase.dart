// SUIVI-ELEVE (07/11/2026) : l'adaptateur Supabase du suivi pedagogique.
//
// SOCLE-PROGRAMME (lot 1 de la charte, 12/11/2026) : l'adaptateur de
// l'ENSEIGNANT et de la direction, sur `etape_eleve_lecture` (migration
// 20261123900000, lecture seule). L'eleve et sa famille lisent tout par
// `ma_progression` (MaProgressionSupabase), qui appelle la meme fonction : un
// seul calcul de l'etape. Le serveur porte la garde ; l'adaptateur ne fait que
// lire.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_suivi_pedagogique.dart';

/// Le suivi pedagogique servi par Supabase.
class SuiviPedagogiqueSupabase implements PortSuiviPedagogique {
  /// Cree l'adaptateur.
  const SuiviPedagogiqueSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<SuiviPedagogique?> pourEleve(String eleveId) async {
    final Object? lecture = await _client.rpc<Object?>(
      'etape_eleve_lecture',
      params: <String, Object?>{'p_eleve_id': eleveId},
    );
    return SuiviPedagogique.depuisLecture(lecture);
  }
}
