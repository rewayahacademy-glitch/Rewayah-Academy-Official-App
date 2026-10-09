import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_demandes_horaires.dart';

/// Adaptateur PostgREST des demandes privées et de la file de regroupements.
class DemandesHorairesSupabase
    implements PortDemandesHorairesFamille, PortRegroupementsDemandesHoraires {
  const DemandesHorairesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<DemandeHoraireFamille> demanderCreneauPersonnalise(
    DemandeCreneauPersonnalise demande,
  ) async {
    final Map<String, dynamic> reponse = await _client.rpc<Map<String, dynamic>>(
      'demander_creneau_personnalise',
      params: <String, dynamic>{
        'p_membre_id': demande.membreId,
        'p_fuseau_iana': demande.fuseauIana,
        'p_jours': demande.joursIso,
        'p_heure_locale': demande.heureLocale,
      },
    );
    return DemandeHoraireFamille(
      id: reponse['id'] as String,
      etat: EtatDemandeHoraire.depuisSql(reponse['etat'] as String?),
      prochaineEtape: reponse['prochaine_etape'] as String? ?? 'constitution_classe',
      motif: reponse['motif'] as String?,
      updatedAt: DateTime.parse(reponse['updated_at'] as String).toUtc(),
    );
  }

  @override
  Future<List<DemandeHoraireFamille>> mesDemandes(String membreId) async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'mes_demandes_horaires',
      params: <String, dynamic>{'p_membre_id': membreId},
    );
    return reponse
        .map((dynamic item) => DemandeHoraireFamille.depuisJson(
              item as Map<String, dynamic>,
            ))
        .toList(growable: false);
  }

  @override
  Future<List<RegroupementDemandesHoraires>> charger() async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'regroupements_demandes_horaires_admin',
    );
    return reponse
        .map((dynamic item) => RegroupementDemandesHoraires.depuisJson(
              item as Map<String, dynamic>,
            ))
        .toList(growable: false);
  }
}
