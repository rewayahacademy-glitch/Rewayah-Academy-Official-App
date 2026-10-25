import 'package:supabase_flutter/supabase_flutter.dart';

import '../offres/affectation_refusee.dart';
import 'creneaux_classe.dart';

/// L'adaptateur de `ajouter_creneau_classe_admin`.
class CreneauxClasseSupabase implements ServiceCreneauxClasse {
  /// Cree l'adaptateur.
  const CreneauxClasseSupabase(this._client);

  final SupabaseClient _client;

  /// Un refus du predicat (P0001, chevauchement 23P01) arrive en
  /// [AffectationRefusee], jamais avec le texte SQL ; les autres erreurs
  /// (droit, reseau) passent telles quelles.
  @override
  Future<int> ajouter({
    required String groupeId,
    required int jour,
    required int heure,
  }) async {
    try {
      final int? n = await _client.rpc<int?>(
        'ajouter_creneau_classe_admin',
        params: <String, dynamic>{
          'p_groupe_id': groupeId,
          'p_weekday': jour,
          'p_hour_local': heure,
        },
      );
      return n ?? 0;
    } on PostgrestException catch (e) {
      final MotifRefusAffectation? motif = motifRefusDeplacementClasse(
        code: e.code,
        message: e.message,
      );
      if (motif == null) rethrow;
      throw AffectationRefusee(motif);
    }
  }
}
