// CAHIER-C2 (06/11/2026) : l'adaptateur Supabase des etapes des eleves d'une
// Classe. Une RPC de la migration 20261110600000 : `etapes_eleves_classe`.
// Le serveur porte la garde (direction, titulaire, ou enseignant effectif
// d'une seance proche de la Classe).

import 'package:supabase_flutter/supabase_flutter.dart';

import 'etape_eleve.dart';

/// Les etapes des eleves lues sur Supabase.
class EtapesElevesSupabase implements PortEtapesEleves {
  /// Cree l'adaptateur.
  const EtapesElevesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, EtapeEleve>> etapesDeLaClasse(String groupeId) async {
    final Object? brut = await _client.rpc<Object?>(
      'etapes_eleves_classe',
      params: <String, Object?>{'p_groupe_id': groupeId},
    );
    return etapesDepuisReponse(brut);
  }
}

/// Les etapes lues dans la reponse, par `studentId` ; les lignes illisibles
/// sont ecartees.
Map<String, EtapeEleve> etapesDepuisReponse(Object? brut) {
  if (brut is! List) return const <String, EtapeEleve>{};
  return <String, EtapeEleve>{
    for (final Object? ligne in brut)
      if (EtapeEleve.depuisJson(ligne) case final EtapeEleve e) e.studentId: e,
  };
}
