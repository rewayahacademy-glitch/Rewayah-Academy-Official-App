import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import '../theme/app_delais.dart';
import 'port_genre_partageur.dart';

/// Le genre lu sur `profiles.gender`, la ligne du titulaire.
///
/// Aucune RPC nouvelle : la politique `profiles_self_select` rend la ligne de
/// son titulaire, et le serveur decide. Une ligne illisible ou une valeur hors
/// `male`/`female` rend `null`.
class GenrePartageurSupabase implements PortGenrePartageur {
  /// Cree l'adaptateur.
  const GenrePartageurSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Genre?> genreDuTitulaire() async {
    final User? utilisateur = _client.auth.currentUser;
    if (utilisateur == null) {
      return null;
    }
    final Map<String, dynamic>? ligne = await _client
        .from('profiles')
        .select('gender')
        .eq('id', utilisateur.id)
        .maybeSingle()
        .timeout(AppDelais.requeteMax);
    return genreDepuisLigne(ligne);
  }
}

/// Le genre d'une ligne `profiles`, ou `null`. Pure, testee.
Genre? genreDepuisLigne(Map<String, dynamic>? ligne) {
  if (ligne == null) {
    return null;
  }
  final Object? valeur = ligne['gender'];
  return Genre.depuisSql(valeur is String ? valeur : null);
}
