// SUIVI-ELEVE (07/11/2026) : l'adaptateur Supabase du suivi pedagogique.
//
// SOCLE-PROGRAMME (lot 1 de la charte, 12/11/2026) : une seule RPC,
// `etape_eleve_lecture` (migration 20261123900000, lecture seule), LA lecture
// de l'etape de l'eleve pour tous les roles : etape, chemin, dates, reperes,
// sourates des bases et page de reprise. Le serveur porte la garde, retient la
// date limite pour l'enfant de 6 a 9 ans et calcule la vitesse ; l'adaptateur
// ne fait que lire. `suivi_pedagogique_eleve` et `sourates_eleve` ne sont plus
// appelees d'ici (elles restent en base jusqu'au lot 10).

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

/// (Ancienne lecture, plus appelee depuis SOCLE-PROGRAMME ; retiree au lot 10.)
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
