import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_delais.dart';
import 'port_matricule.dart';

/// Le matricule lu sur `profiles.immutable_id`, qui recoit le matricule RA
/// (`20261012181821_imm_back_1_person_registrations.sql`, registre unique).
///
/// Aucune RPC nouvelle : la politique `profiles_self_select` rend la ligne du
/// titulaire, `profiles_family_select` celles du foyer pour le tuteur. Le
/// serveur decide ; une ligne illisible ou une valeur hors forme rend `null`.
/// `rechercher_personne_par_matricule` (administration) n'est jamais appelee.
class MatriculeSupabase implements PortMatricule {
  /// Cree l'adaptateur.
  const MatriculeSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Matricule?> matriculeDe(String profileId) async {
    final Map<String, dynamic>? ligne = await _client
        .from('profiles')
        .select('immutable_id, role')
        .eq('id', profileId)
        .maybeSingle()
        .timeout(AppDelais.requeteMax);
    return matriculeDepuisLigne(ligne);
  }
}

/// Le matricule d'une ligne `profiles`, ou `null`. Pure, testee.
Matricule? matriculeDepuisLigne(Map<String, dynamic>? ligne) {
  if (ligne == null) return null;
  final Object? valeur = ligne['immutable_id'];
  final RoleAffiche? role = RoleAffiche.depuisSql(ligne['role'] as String?);
  if (valeur is! String || role == null || !Matricule.forme.hasMatch(valeur)) {
    return null;
  }
  return Matricule(valeur: valeur, role: role);
}
