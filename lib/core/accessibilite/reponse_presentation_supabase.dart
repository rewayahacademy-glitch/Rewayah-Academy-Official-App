import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_reponse_presentation.dart';

/// Adaptateur C-22. L'identité et le foyer sont déduits par le serveur.
class ReponsePresentationSupabase implements PortReponsePresentation {
  const ReponsePresentationSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<DemandePresentation>> enAttente() async {
    final List<dynamic> rows = await _client.rpc<List<dynamic>>(
      'lire_demandes_presentation_en_attente_avec_fuseau',
    );
    return rows
        .map<DemandePresentation>((dynamic value) {
          if (value is! Map) {
            throw const FormatException('Demande de présentation invalide.');
          }
          final Map<String, dynamic> row = Map<String, dynamic>.from(value);
          final String? id = row['id'] as String?;
          final String? eleveId = row['eleve_id'] as String?;
          final String? prenom = row['eleve_prenom'] as String?;
          final String? fuseau = row['fuseau_iana'] as String?;
          final DateTime? instantUtc = DateTime.tryParse(
            row['cree_le_utc']?.toString() ?? '',
          );
          final String? valeurHeureFoyer = row['heure_foyer']?.toString();
          // Treat the timestamp-without-zone as calendar fields, not as device
          // local time. The actual instant and IANA zone travel in separate fields.
          final DateTime? heureFoyer = valeurHeureFoyer == null
              ? null
              : DateTime.tryParse('${valeurHeureFoyer}Z');
          if (id == null ||
              eleveId == null ||
              prenom == null ||
              fuseau == null ||
              fuseau.isEmpty ||
              instantUtc == null ||
              heureFoyer == null) {
            throw const FormatException('Demande de présentation incomplète.');
          }
          return DemandePresentation(
            id: id,
            eleveId: eleveId,
            prenom: prenom,
            demandeeLe: heureFoyer,
            instantUtc: instantUtc.toUtc(),
            fuseauIana: fuseau,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> accepter(String demandeId) async {
    final String statut = await _client.rpc<String>(
      'accepter_demande_presentation',
      params: <String, dynamic>{'p_demande_id': demandeId},
    );
    if (statut != 'acceptee') {
      throw const FormatException('Réponse de présentation inconnue.');
    }
  }

  @override
  Future<void> refuser(String demandeId) async {
    final String statut = await _client.rpc<String>(
      'refuser_demande_presentation',
      params: <String, dynamic>{'p_demande_id': demandeId},
    );
    if (statut != 'refusee') {
      throw const FormatException('Réponse de présentation inconnue.');
    }
  }
}
