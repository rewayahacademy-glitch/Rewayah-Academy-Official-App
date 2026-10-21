import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_reprises_admin.dart';

/// Adaptateur C-23 des RPC administratives B-04.
class ReprisesAdminSupabase implements PortReprisesAdmin {
  /// Crée l'adaptateur avec le client utilisateur courant.
  const ReprisesAdminSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RepriseAdmin>> lister() async {
    final List<dynamic> rows = await _client.rpc<List<dynamic>>(
      'lister_reprises_admin',
    );
    return rows
        .map<RepriseAdmin>((dynamic value) {
          if (value is! Map) {
            throw const FormatException('Demande de reprise invalide.');
          }
          final Map<String, dynamic> row = Map<String, dynamic>.from(value);
          final String? id = row['id'] as String?;
          final String? prenom = row['demandeur_prenom'] as String?;
          final String? nom = row['demandeur_nom'] as String?;
          final String? foyer = row['foyer_nom'] as String?;
          final String? statut = row['statut'] as String?;
          final bool? decidable = row['decidable'] as bool?;
          final EtatRepriseAdmin? etat = switch (statut) {
            'a_examiner' => EtatRepriseAdmin.aExaminer,
            'refusee_par_titulaire' => EtatRepriseAdmin.refuseeParTitulaire,
            _ => null,
          };
          if (id == null ||
              prenom == null ||
              nom == null ||
              foyer == null ||
              etat == null ||
              decidable == null) {
            throw const FormatException('Demande de reprise incomplète.');
          }
          return RepriseAdmin(
            id: id,
            demandeurPrenom: prenom,
            demandeurNom: nom,
            foyerNom: foyer,
            etat: etat,
            decidable: decidable,
            deposeeLe: _dateLocale(row['deposee_le']),
            examenPossibleLe: _dateLocale(row['examen_possible_le']),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<ResultatDecisionReprise> decider({
    required String repriseId,
    required bool approuver,
    required String cle,
  }) async {
    try {
      final Object? value = await _client.rpc<Object?>(
        'decider_reprise_foyer',
        params: <String, dynamic>{
          'p_reprise_id': repriseId,
          'p_approuver': approuver,
          'p_cle': cle,
        },
      );
      if (value is! Map) {
        throw const FormatException('Réponse de décision invalide.');
      }
      final String? statut = value['statut'] as String?;
      return switch (statut) {
        'decidee' => const RepriseDecidee(),
        'deja_traitee' => const RepriseDejaTraitee(),
        _ => throw const FormatException('Statut de décision inconnu.'),
      };
    } on Object catch (error) {
      if (_estErreurReseau(error)) {
        return const RepriseDecisionEchecReseau();
      }
      rethrow;
    }
  }
}

DateTime? _dateLocale(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException('Date de reprise invalide.');
  }
  final DateTime? instant = DateTime.tryParse(value);
  if (instant == null) {
    throw const FormatException('Date de reprise invalide.');
  }
  return instant.toLocal();
}

bool _estErreurReseau(Object error) {
  final String texte = error.toString();
  return texte.contains('SocketException') ||
      texte.contains('ClientException') ||
      texte.contains('TimeoutException') ||
      texte.contains('Failed host lookup') ||
      texte.contains('Connection refused');
}
