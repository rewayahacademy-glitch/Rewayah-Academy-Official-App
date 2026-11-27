// Adaptateur de `ma_dette_famille()` (migration 20261203100000). Aucun
// identifiant n'est envoye : le serveur lit le foyer de la session et refuse
// tout autre appelant (42501).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/dette_famille.dart';
import 'permission_insuffisante.dart';
import 'port_dette_famille.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'D7';

/// La dette de la famille servie par Supabase.
class DetteFamilleSupabase implements PortDetteFamille {
  /// Cree l'adaptateur sur le client de l'application.
  DetteFamilleSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  DetteFamilleSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<DetteFamille> lire() async {
    try {
      return DetteFamille.depuisJson(
        await appelerFinance(_appel, 'ma_dette_famille', _dependance),
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw const PermissionInsuffisante(_dependance);
      rethrow;
    }
  }
}
