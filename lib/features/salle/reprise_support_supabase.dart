// Lot PARTAGE-GENERIQUE (11/11/2026) : l'adaptateur Supabase de la page de
// reprise des supports. Deux fonctions de la migration
// `20261123700000_partage_generique_position_support.sql` (brouillon non
// applique le 11/11/2026) : `enregistrer_position_support` et
// `positions_reprise_supports_seance`. Le serveur porte les gardes
// (enseignant effectif de la seance pour ecrire ; direction, titulaire ou
// remplacant pour lire).
//
// Tant que la migration n'est pas installee, les deux fonctions n'existent
// pas : la lecture rend « rien », l'ecriture rend `false` (« pas encore
// retenue »), jamais une erreur montree.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'reprise_support.dart';

/// La page de reprise des supports lue et ecrite sur Supabase.
class RepriseSupportSupabase implements PortRepriseSupport {
  /// Cree l'adaptateur.
  const RepriseSupportSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, int>> pagesDeLaSeance(String sessionId) async {
    try {
      final Object? brut = await _client.rpc<Object?>(
        'positions_reprise_supports_seance',
        params: <String, Object?>{'p_session_id': sessionId},
      );
      return pagesDepuisReponse(brut);
    } on PostgrestException catch (erreur) {
      if (fonctionAbsente(erreur.code)) return const <String, int>{};
      rethrow;
    }
  }

  @override
  Future<bool> enregistrer({
    required String sessionId,
    required String support,
    required String version,
    required int page,
    required int pages,
  }) async {
    try {
      await _client.rpc<Object?>(
        'enregistrer_position_support',
        params: <String, Object?>{
          'p_session_id': sessionId,
          'p_support': support,
          'p_version': version,
          'p_page': page,
          'p_pages': pages,
        },
      );
      return true;
    } on PostgrestException catch (erreur) {
      if (fonctionAbsente(erreur.code)) return false;
      rethrow;
    }
  }
}

/// Vrai quand [code] dit que la fonction n'existe pas sur ce serveur
/// (PostgREST `PGRST202`, Postgres `42883`) : la migration n'est pas
/// installee.
bool fonctionAbsente(String? code) => code == 'PGRST202' || code == '42883';

/// Les pages lues dans la reponse de `positions_reprise_supports_seance`
/// (une ligne par support). Une ligne inattendue est ignoree.
Map<String, int> pagesDepuisReponse(Object? brut) {
  final Map<String, int> pages = <String, int>{};
  if (brut is! List) return pages;
  for (final Object? ligne in brut) {
    if (ligne is! Map) continue;
    final Object? support = ligne['support'];
    final Object? page = ligne['page'];
    final Object? total = ligne['pages'];
    final int? numero = page is num ? page.toInt() : null;
    final int? nombre = total is num ? total.toInt() : null;
    if (support is! String || support.isEmpty || numero == null) continue;
    if (numero < 1 || (nombre != null && numero > nombre)) continue;
    pages[support] = numero;
  }
  return pages;
}
