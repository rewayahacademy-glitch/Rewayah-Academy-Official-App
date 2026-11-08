// PROJECTION-ELEVES (08/11/2026) : l'adaptateur Supabase des lignes
// pedagogiques des eleves d'une Classe, pour leur enseignant. Une RPC de la
// migration 0033 : `groupe_roster_enseignant`. Le serveur porte la garde
// (enseignant titulaire de la Classe, compte valide) ; il ne rend aucune ligne
// a un autre compte.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'preparation_seance.dart';

/// Les lignes des eleves lues sur Supabase.
class ProjectionsElevesSupabase implements PortProjectionsEleves {
  /// Cree l'adaptateur.
  const ProjectionsElevesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, LigneProjectionEleve>> projectionsDeLaClasse(
    String groupeId,
  ) async {
    final Object? brut = await _client.rpc<Object?>(
      'groupe_roster_enseignant',
      params: <String, Object?>{'p_groupe_id': groupeId},
    );
    return projectionsDepuisReponse(brut);
  }
}

/// Les lignes lues dans la reponse, par `studentId` ; les lignes illisibles
/// sont ecartees.
Map<String, LigneProjectionEleve> projectionsDepuisReponse(Object? brut) {
  if (brut is! List) return const <String, LigneProjectionEleve>{};
  return <String, LigneProjectionEleve>{
    for (final Object? ligne in brut)
      if (LigneProjectionEleve.depuisJson(ligne)
          case final LigneProjectionEleve l)
        l.studentId: l,
  };
}
