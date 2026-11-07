// Adaptateur COULEUR-PROFIL (22 i) : les RPC de la migration
// `20261110500000_couleur_profil.sql` (`accents_profils_du_foyer`,
// `choisir_accent_profil`).
//
// Le serveur borne tout : le tuteur lit et ecrit les profils de son foyer,
// l'adulte autonome le sien, l'enfant ne lit que sa propre couleur.
//
// Erreurs : une fonction absente (PGRST202, migration pas encore installee)
// se dit [CapaciteIndisponible] ; `42501` (appelant refuse) se dit
// [PermissionInsuffisante]. Toute autre erreur remonte telle quelle : l'ecran
// ne dit jamais un succes qu'il ignore. Une cle inconnue rendue par le serveur
// est ignoree (aucun bandeau, jamais une couleur au hasard).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/accent_profil.dart';
import 'permission_insuffisante.dart';
import 'port_accents_profils.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'COULEUR-PROFIL';

/// Les accents des profils servis par Supabase.
class AccentsProfilsSupabase implements PortAccentsProfils {
  /// Cree l'adaptateur sur le client de l'application.
  AccentsProfilsSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  AccentsProfilsSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  Future<Object?> _appeler(
    String fonction, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      return await appelerFinance(_appel, fonction, _dependance, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw const PermissionInsuffisante(_dependance);
      rethrow;
    }
  }

  @override
  Future<Map<String, AccentProfil>> lire() async {
    final Object? brut = await _appeler('accents_profils_du_foyer');
    final Map<String, AccentProfil> accents = <String, AccentProfil>{};
    for (final Object? ligne
        in brut == null ? const <Object?>[] : listeJson(brut, 'accents')) {
      final Map<String, dynamic> objet = objetJson(ligne, 'accent');
      final Object? id = objet['profile_id'];
      if (id is! String || id.isEmpty) {
        throw const FormatException('accent invalide: profile_id');
      }
      final Object? cle = objet['accent_key'];
      if (AccentProfil.depuisCle(cle is String ? cle : null)
          case final AccentProfil accent) {
        accents[id] = accent;
      }
    }
    return Map<String, AccentProfil>.unmodifiable(accents);
  }

  @override
  Future<void> choisir(String profilId, AccentProfil? accent) async {
    await _appeler('choisir_accent_profil', <String, dynamic>{
      'p_profil': profilId,
      'p_accent': accent?.name,
    });
  }
}
