import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_signalement.dart';
import 'student_concern.dart';

/// Adaptateur des signalements. Les identifiants d'enseignant et d'élève sont
/// résolus côté serveur à partir de la session et de l'identifiant d'académie.
class SignalementSupabase implements PortSignalement {
  const SignalementSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<StudentConcern> signaler({
    required CategorieSignalement categorie,
    required String groupeId,
    String? sessionId,
    required String academyId,
    required String internalDetails,
    String? familySummary,
  }) async {
    final Map<String, dynamic> row = await _client.rpc<Map<String, dynamic>>(
      'deposer_student_concern',
      params: <String, dynamic>{
        'p_categorie': categorie.valeurSql,
        'p_groupe_id': groupeId,
        'p_session_id': sessionId,
        'p_academy_id': academyId,
        'p_internal_details': internalDetails,
        'p_family_summary': familySummary,
      },
    );
    return _depuisJson(row);
  }

  @override
  Future<List<StudentConcern>> mesSignalements({String? groupeId}) async {
    final List<dynamic> rows = await _client.rpc<List<dynamic>>(
      'mes_student_concerns',
      params: <String, dynamic>{'p_groupe_id': groupeId},
    );
    return rows
        .map(
          (dynamic row) =>
              _depuisJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<void> transmettre({
    required String concernId,
    required CibleTransmission cible,
  }) async {
    await _client.rpc<void>(
      'transmettre_student_concern',
      params: <String, dynamic>{
        'p_concern_id': concernId,
        'p_cible': cible.valeurSql,
      },
    );
  }

  StudentConcern _depuisJson(Map<String, dynamic> row) {
    final CategorieSignalement? categorie =
        CategorieSignalement.depuisSql(row['categorie'] as String?);
    final StatutSignalement? statut =
        StatutSignalement.depuisSql(row['statut'] as String?);
    final String? cibleSql = row['transmis_a'] as String?;
    final CibleTransmission? cible = cibleSql == null
        ? null
        : CibleTransmission.depuisSql(cibleSql);
    final DateTime? creeLe = DateTime.tryParse(row['cree_le'] as String? ?? '');
    final String? transmisSql = row['transmis_le'] as String?;
    final DateTime? transmisLe = transmisSql == null
        ? null
        : DateTime.tryParse(transmisSql);

    if (categorie == null ||
        statut == null ||
        (cibleSql != null && cible == null) ||
        creeLe == null ||
        (transmisSql != null && transmisLe == null)) {
      throw const FormatException('Signalement Supabase invalide');
    }

    return StudentConcern(
      id: row['id'] as String,
      categorie: categorie,
      groupeId: row['groupe_id'] as String,
      sessionId: row['session_id'] as String?,
      academyId: row['academy_id'] as String,
      enseignantId: row['enseignant_id'] as String,
      internalDetails: row['internal_details'] as String,
      familySummary: row['family_summary'] as String?,
      statut: statut,
      creeLeUtc: creeLe.toUtc(),
      transmisLeUtc: transmisLe?.toUtc(),
      transmisA: cible,
    );
  }
}
