// Adaptateur FI-BR-17 : les finances de l'eleve adulte sur son seul profil,
// lues par `mes_finances_eleve` et `mes_mouvements_eleve` (migration
// 20261017160100). Aucun identifiant n'est envoye : le serveur lit le profil
// de la session et refuse tout autre appelant (42501).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/finances_profil.dart';
import '../finance/mouvements_profil.dart';
import 'port_mes_finances.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'FI-BR-17';

/// Mes finances servies par Supabase.
class MesFinancesSupabase implements PortMesFinances {
  /// Cree l'adaptateur sur le client de l'application.
  MesFinancesSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  MesFinancesSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  /// `null` quand le serveur n'a encore aucune finance pour ce profil.
  @override
  Future<FinancesProfil?> finances() async {
    final Object? brut = await appelerFinance(
      _appel,
      'mes_finances_eleve',
      _dependance,
    );
    return brut == null ? null : financesProfilJson(brut);
  }

  @override
  Future<List<MouvementProfil>> mouvements() async => mouvementsJson(
    await appelerFinance(
      _appel,
      'mes_mouvements_eleve',
      _dependance,
      <String, dynamic>{'p_limite': 50},
    ),
  );
}
