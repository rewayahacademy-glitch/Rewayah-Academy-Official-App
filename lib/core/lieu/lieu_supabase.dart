import 'package:supabase_flutter/supabase_flutter.dart';

import 'lieu.dart';

/// L'adaptateur des fonctions du lieu (migrations 20261123940200 et
/// 20261123943000, HORLOGE-ET-LIEU).
class LieuSupabase implements PortLieu {
  /// Cree l'adaptateur.
  const LieuSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Ville>> rechercher(String texte) async {
    final Object? brut = await _client.rpc<Object?>(
      'rechercher_villes',
      params: <String, dynamic>{'p_texte': texte, 'p_limite': 20},
    );
    return _villes(brut);
  }

  @override
  Future<List<Ville>> proposees(int decalageMinutes) async {
    final Object? brut = await _client.rpc<Object?>(
      'villes_proposees',
      params: <String, dynamic>{
        'p_decalage_minutes': decalageMinutes,
        'p_limite': 12,
      },
    );
    return _villes(brut);
  }

  @override
  Future<ResultatVille> enregistrer(int villeId) async {
    final Object? brut = await _client.rpc<Object?>(
      'enregistrer_ma_ville',
      params: <String, dynamic>{'p_ville_id': villeId},
    );
    return ResultatVille(
      disponibilitesARelire:
          brut is Map && brut['disponibilites_a_relire'] == true,
    );
  }

  @override
  Future<EtatLieu> aFournir() async {
    final EtatLieu? etat = EtatLieu.lire(
      await _client.rpc<Object?>('mon_lieu_a_fournir'),
    );
    if (etat == null) throw const FormatException('mon_lieu_a_fournir');
    return etat;
  }

  @override
  Future<EtatLieu> reporter() async {
    final EtatLieu? etat = EtatLieu.lire(
      await _client.rpc<Object?>('reporter_ma_ville'),
    );
    if (etat == null) throw const FormatException('reporter_ma_ville');
    return etat;
  }

  @override
  Future<LieuChoisi?> monLieu() async =>
      LieuChoisi.lire(await _client.rpc<Object?>('mon_lieu'));

  static List<Ville> _villes(Object? brut) {
    if (brut is! List<dynamic>) return const <Ville>[];
    return <Ville>[
      for (final dynamic ligne in brut) ?Ville.lire(ligne),
    ];
  }
}
