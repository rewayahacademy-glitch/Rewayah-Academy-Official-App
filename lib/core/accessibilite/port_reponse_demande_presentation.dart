import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Demande en attente visible uniquement au tuteur de son foyer.
class DemandePresentationEnAttente {
  const DemandePresentationEnAttente({
    required this.id,
    required this.eleveId,
    required this.prenomEleve,
    required this.creeeLe,
  });

  final String id;
  final String eleveId;
  final String prenomEleve;
  final DateTime creeeLe;
}

/// Lecture et décision MA-9 côté tuteur.
abstract interface class PortReponseDemandePresentation {
  Future<List<DemandePresentationEnAttente>> enAttente();
  Future<void> accepter(String demandeId);
  Future<void> refuser(String demandeId);
}

/// Adaptateur des RPC privées de demandes de présentation.
class ReponseDemandePresentationSupabase
    implements PortReponseDemandePresentation {
  const ReponseDemandePresentationSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<DemandePresentationEnAttente>> enAttente() async {
    final List<dynamic> rows = await _client.rpc<List<dynamic>>(
      'lire_demandes_presentation_en_attente',
    );
    return rows.map((dynamic value) {
      if (value is! Map) {
        throw const FormatException('Demande de présentation invalide');
      }
      final Map<String, dynamic> row = Map<String, dynamic>.from(value);
      final String? id = row['id'] as String?;
      final String? eleveId = row['eleve_id'] as String?;
      final String? prenom = row['eleve_prenom'] as String?;
      final DateTime? creeeLe =
          DateTime.tryParse(row['cree_le']?.toString() ?? '');
      if (id == null || eleveId == null || prenom == null || creeeLe == null) {
        throw const FormatException('Demande de présentation incomplète');
      }
      return DemandePresentationEnAttente(
        id: id,
        eleveId: eleveId,
        prenomEleve: prenom,
        creeeLe: creeeLe.toUtc(),
      );
    }).toList(growable: false);
  }

  @override
  Future<void> accepter(String demandeId) async {
    await _client.rpc<String>(
      'accepter_demande_presentation',
      params: <String, dynamic>{'p_demande_id': demandeId},
    );
  }

  @override
  Future<void> refuser(String demandeId) async {
    await _client.rpc<String>(
      'refuser_demande_presentation',
      params: <String, dynamic>{'p_demande_id': demandeId},
    );
  }
}

/// Dépendance injectable du parcours MA-9.
final Provider<PortReponseDemandePresentation>
portReponseDemandePresentationProvider =
    Provider<PortReponseDemandePresentation>(
  (Ref ref) => ReponseDemandePresentationSupabase(Supabase.instance.client),
);
