// Adaptateur PREFERENCES-PAR-COMPTE : les RPC de la migration 20261123200000
// (`ma_preference_theme`, `ma_preference_theme_regler`).
//
// Une fonction absente (PGRST202, migration pas encore installee) se dit
// `CapaciteIndisponible` : le theme reste alors celui de l'appareil pour ce
// compte. Toute autre erreur remonte telle quelle ; la persistance la journalise
// sans rien casser.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/rpc_finance_supabase.dart';
import 'preferences_compte.dart';

const String _dependance = 'PREFERENCES-PAR-COMPTE';

/// Le theme du compte, sur le serveur.
class ThemeCompteSupabase implements PortThemeCompte {
  /// Cree l'adaptateur sur le client de l'application.
  ThemeCompteSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  ThemeCompteSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<String> lire() async {
    final Object? brut = await appelerFinance(
      _appel,
      'ma_preference_theme',
      _dependance,
    );
    if (brut is String && brut.trim().isNotEmpty) return brut.trim();
    throw const FormatException('theme invalide: ma_preference_theme');
  }

  @override
  Future<void> regler(String theme) async {
    await appelerFinance(
      _appel,
      'ma_preference_theme_regler',
      _dependance,
      <String, dynamic>{'p_theme': theme},
    );
  }
}
