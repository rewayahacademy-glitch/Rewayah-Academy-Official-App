// CAHIER-C1 (06/11/2026) : l'adaptateur Supabase de la position de reprise.
// Trois RPC de la migration 20261110100000 : `enregistrer_page_presentee`,
// `position_reprise_classe`, `position_reprise_seance`. Le serveur porte les
// gardes (enseignant effectif de la seance pour ecrire ; direction,
// titulaire ou remplacant pour lire).

import 'package:supabase_flutter/supabase_flutter.dart';

import 'position_reprise.dart';

/// La position de reprise lue et ecrite sur Supabase.
class PositionRepriseSupabase implements PortPositionReprise {
  /// Cree l'adaptateur.
  const PositionRepriseSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<int?> pageDeLaClasse(String groupeId) => _page(
    'position_reprise_classe',
    <String, Object?>{'p_groupe_id': groupeId},
  );

  @override
  Future<int?> pageDeLaSeance(String sessionId) => _page(
    'position_reprise_seance',
    <String, Object?>{'p_session_id': sessionId},
  );

  @override
  Future<void> enregistrer({
    required String sessionId,
    required int page,
  }) async {
    await _client.rpc<Object?>(
      'enregistrer_page_presentee',
      params: <String, Object?>{'p_session_id': sessionId, 'p_page': page},
    );
  }

  Future<int?> _page(String fonction, Map<String, Object?> params) async {
    final Object? brut = await _client.rpc<Object?>(fonction, params: params);
    return pageDepuisReponse(brut);
  }
}

/// La page lue dans la reponse d'une lecture de position (une ligne ou
/// aucune). `null` quand rien n'a ete presente ou que la reponse est
/// inattendue.
int? pageDepuisReponse(Object? brut) {
  final Object? ligne = brut is List
      ? (brut.isEmpty ? null : brut.first)
      : brut;
  if (ligne is! Map) return null;
  final Object? page = ligne['page'];
  final int? valeur = page is int ? page : (page is num ? page.toInt() : null);
  if (valeur == null || valeur < 1 || valeur > 604) return null;
  return valeur;
}
