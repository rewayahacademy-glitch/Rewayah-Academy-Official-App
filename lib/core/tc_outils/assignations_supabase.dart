import 'package:supabase_flutter/supabase_flutter.dart';

import '../tc_bibliotheque/content_range.dart';
import '../tc_etat_partage/codec_etat_partage.dart';
import 'intention_pedagogique.dart';
import 'learning_assignment.dart';
import 'port_assignations.dart';

/// Adaptateur de learning_assignment. La RLS impose l'enseignant propriétaire
/// pour les mutations et limite les lectures famille/élève à leur groupe.
class AssignationsSupabase implements PortAssignations {
  const AssignationsSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<LearningAssignment>> pourGroupe(
    String groupId, {
    String? studentId,
  }) async {
    final List<Map<String, dynamic>> rows = await _rowsVisibles(
      groupId,
      studentId: studentId,
      uniquementOuverts: false,
      limite: null,
    );
    return rows.map(_depuisJson).toList(growable: false);
  }

  @override
  Future<List<LearningAssignment>> aVenir({
    required String groupId,
    String? studentId,
    int limite = 3,
  }) async {
    final int maximum = limite.clamp(0, 3);
    if (maximum == 0) return const <LearningAssignment>[];

    final List<Map<String, dynamic>> rows = await _rowsVisibles(
      groupId,
      studentId: studentId,
      uniquementOuverts: true,
      // Pour une recherche combinant les assignations du groupe et d'un élève,
      // les trois premières de chaque ensemble suffisent à calculer le top 3.
      limite: maximum,
    );
    final List<LearningAssignment> travaux = rows.map(_depuisJson).toList()
      ..sort(_parUrgence);
    return List<LearningAssignment>.unmodifiable(travaux.take(maximum));
  }

  Future<List<Map<String, dynamic>>> _rowsVisibles(
    String groupId, {
    required String? studentId,
    required bool uniquementOuverts,
    required int? limite,
  }) async {
    Future<List<Map<String, dynamic>>> lire({String? idEleve, bool groupe = false}) async {
      dynamic query = _client
          .from('learning_assignment')
          .select()
          .eq('group_id', groupId);

      if (groupe) {
        query = query.isFilter('student_id', null);
      } else if (idEleve != null) {
        query = query.eq('student_id', idEleve);
      }

      if (uniquementOuverts) {
        query = query.inFilter('status', <String>['a_faire', 'en_cours']);
      }
      if (uniquementOuverts) {
        query = query.order('due_at').order('starts_at');
      }
      if (limite != null) {
        query = query.limit(limite);
      }
      final dynamic result = await query;
      if (result is! List) {
        throw const FormatException('Liste learning_assignment invalide');
      }
      return result
          .map((dynamic row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);
    }

    if (studentId == null) {
      return lire();
    }

    final List<List<Map<String, dynamic>>> ensembles = await Future.wait(
      <Future<List<Map<String, dynamic>>>>[
        lire(groupe: true),
        lire(idEleve: studentId),
      ],
    );
    final Map<String, Map<String, dynamic>> uniques = <String, Map<String, dynamic>>{
      for (final Map<String, dynamic> row in ensembles.expand((e) => e))
        row['id'] as String: row,
    };
    return uniques.values.toList(growable: false);
  }

  @override
  Future<LearningAssignment> creerDepuisSelection({
    required String groupId,
    String? studentId,
    required String resourceId,
    String? resourceVersionId,
    ContentRange? contentRange,
    required IntentionPedagogique purpose,
    String? instructions,
    DateTime? dueAtUtc,
  }) async {
    final String? auteur = _client.auth.currentUser?.id;
    if (auteur == null) {
      throw StateError('Session requise pour créer une assignation');
    }
    final DateTime debutUtc = DateTime.now().toUtc();
    final dynamic row = await _client
        .from('learning_assignment')
        .insert(<String, dynamic>{
          'group_id': groupId,
          'student_id': studentId,
          'resource_id': resourceId,
          'resource_version_id': resourceVersionId,
          'content_range': contentRange == null
              ? null
              : plageVersJson(contentRange),
          'purpose': purpose.valeurSql,
          'instructions': _texteFacultatif(instructions),
          'starts_at': debutUtc.toIso8601String(),
          'due_at': dueAtUtc?.toUtc().toIso8601String(),
          'created_by': auteur,
          'status': StatutAssignation.aFaire.valeurSql,
        })
        .select()
        .single();
    return _depuisJson(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<void> changerStatut(
    String assignmentId,
    StatutAssignation statut,
  ) async {
    final dynamic row = await _client
        .from('learning_assignment')
        .update(<String, dynamic>{'status': statut.valeurSql})
        .eq('id', assignmentId)
        .select('id')
        .maybeSingle();
    if (row == null) {
      throw StateError('Assignation inconnue ou accès refusé');
    }
  }

  LearningAssignment _depuisJson(Map<String, dynamic> row) {
    final IntentionPedagogique? intention = IntentionPedagogique.depuisSql(
      row['purpose'] as String?,
    );
    final StatutAssignation? statut = StatutAssignation.depuisSql(
      row['status'] as String?,
    );
    final DateTime? debut = DateTime.tryParse(
      row['starts_at'] as String? ?? '',
    );
    final String? echeanceSql = row['due_at'] as String?;
    final DateTime? echeance = echeanceSql == null
        ? null
        : DateTime.tryParse(echeanceSql);
    final Object? plageBrute = row['content_range'];
    final ContentRange? plage = plageBrute == null
        ? null
        : plageDepuisJson(plageBrute);

    if (intention == null ||
        statut == null ||
        debut == null ||
        (echeanceSql != null && echeance == null) ||
        (plageBrute != null && plage == null)) {
      throw const FormatException('Assignation Supabase invalide');
    }
    return LearningAssignment(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      studentId: row['student_id'] as String?,
      resourceId: row['resource_id'] as String,
      resourceVersionId: row['resource_version_id'] as String?,
      contentRange: plage,
      purpose: intention,
      instructions: row['instructions'] as String?,
      startsAtUtc: debut.toUtc(),
      dueAtUtc: echeance?.toUtc(),
      createdBy: row['created_by'] as String,
      status: statut,
    );
  }

  static String? _texteFacultatif(String? valeur) {
    final String? propre = valeur?.trim();
    return propre == null || propre.isEmpty ? null : propre;
  }

  static int _parUrgence(LearningAssignment a, LearningAssignment b) {
    final DateTime? echeanceA = a.dueAtUtc;
    final DateTime? echeanceB = b.dueAtUtc;
    if (echeanceA == null && echeanceB == null) {
      return a.startsAtUtc.compareTo(b.startsAtUtc);
    }
    if (echeanceA == null) return 1;
    if (echeanceB == null) return -1;
    final int parEcheance = echeanceA.compareTo(echeanceB);
    return parEcheance == 0
        ? a.startsAtUtc.compareTo(b.startsAtUtc)
        : parEcheance;
  }
}
