// SUIVI-ELEVE (07/11/2026) : l'adaptateur Supabase du suivi pedagogique, sur
// la RPC `suivi_pedagogique_eleve` (migration 20261115000000, lecture seule).
// Le serveur porte la garde et calcule la vitesse ; l'adaptateur ne fait que
// lire.
//
// SOURATES (11/11/2026, option A) : le compte des sourates des bases vient
// d'une seconde RPC, `sourates_eleve` (migration 20261122900000), avec la
// meme porte. Si elle echoue (pas encore installee, refus), le suivi reste
// lisible sans sourates : jamais un 0 invente.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_suivi_pedagogique.dart';

/// Le suivi pedagogique servi par Supabase.
class SuiviPedagogiqueSupabase implements PortSuiviPedagogique {
  /// Cree l'adaptateur.
  const SuiviPedagogiqueSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<SuiviPedagogique?> pourEleve(String eleveId) async {
    final Object? suivi = await _client.rpc<Object?>(
      'suivi_pedagogique_eleve',
      params: <String, Object?>{'p_eleve_id': eleveId},
    );
    Object? sourates;
    try {
      sourates = await _client.rpc<Object?>(
        'sourates_eleve',
        params: <String, Object?>{'p_student_id': eleveId},
      );
    } on Object {
      sourates = null;
    }
    return SuiviPedagogique.depuisJson(avecSourates(suivi, sourates));
  }
}

/// La ligne du suivi completee des cles de `sourates_eleve`
/// (`sourates_validees`, `sourates_total`) ; la ligne telle quelle si l'une
/// des deux reponses est illisible. Pure, pour les tests.
Object? avecSourates(Object? suivi, Object? sourates) {
  final Object? ligne = suivi is List
      ? (suivi.isEmpty ? null : suivi.first)
      : suivi;
  if (ligne is! Map || sourates is! Map) return ligne;
  return <String, Object?>{
    ...ligne.cast<String, Object?>(),
    'sourates_validees': sourates['sourates_validees'],
    'sourates_total': sourates['sourates_total'],
  };
}
