import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_feedback.dart';
import 'session_feedback.dart';

/// PortFeedback backed by bounded server RPCs; answers are never queried directly.
class FeedbackSupabase implements PortFeedback {
  const FeedbackSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<QuestionFeedback?> questionPour(String sessionId) async {
    final dynamic value = await _client.rpc<dynamic>(
      'question_feedback_pour',
      params: <String, dynamic>{'p_session_id': sessionId},
    );
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('Question feedback invalide');
    }
    final Map<String, dynamic> row = Map<String, dynamic>.from(value);
    final String? id = row['id'] as String?;
    final String? intitule = row['intitule'] as String?;
    final dynamic rawLabels = row['libelles'];
    if (id == null || intitule == null || rawLabels is! Map) {
      throw const FormatException('Question feedback incomplete');
    }
    final Map<String, dynamic> labels = Map<String, dynamic>.from(rawLabels);
    final Map<ReponseFeedback, String> libelles = <ReponseFeedback, String>{};
    for (final ReponseFeedback reponse in ReponseFeedback.values) {
      final dynamic value = labels[reponse.valeurSql];
      if (value is! String || value.trim().isEmpty) {
        throw const FormatException('Libelle feedback invalide');
      }
      libelles[reponse] = value;
    }
    return QuestionFeedback(id: id, intitule: intitule, libelles: libelles);
  }

  @override
  Future<void> soumettre({
    required String sessionId,
    required String questionId,
    required ReponseFeedback reponse,
  }) async {
    try {
      await _client.rpc<void>(
        'soumettre_feedback',
        params: <String, dynamic>{
          'p_session_id': sessionId,
          'p_question_id': questionId,
          'p_reponse': reponse.valeurSql,
        },
      );
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const EchecFeedback(MotifEchecFeedback.dejaDepose);
      }
      throw const EchecFeedback(MotifEchecFeedback.ecriture);
    } catch (_) {
      throw const EchecFeedback(MotifEchecFeedback.ecriture);
    }
  }

  @override
  Future<TendanceFeedback> tendance({required String groupeId}) async {
    final dynamic value = await _client.rpc<dynamic>(
      'tendance_feedback_comprehension',
      params: <String, dynamic>{'p_groupe_id': groupeId},
    );
    if (value is! Map) {
      throw const FormatException('Tendance feedback invalide');
    }
    final Map<String, dynamic> row = Map<String, dynamic>.from(value);
    final int? nombre = row['nombre_echantillons'] as int?;
    final int? seuil = row['seuil_minimum'] as int?;
    final bool? visible = row['visible_par_enseignant'] as bool?;
    final dynamic raw = row['repartition'];
    if (nombre == null || seuil == null || visible == null) {
      throw const FormatException('Tendance feedback incomplete');
    }
    Map<ReponseFeedback, double>? repartition;
    if (visible) {
      if (raw is! Map) {
        throw const FormatException('Repartition feedback invalide');
      }
      final Map<String, dynamic> comptes = Map<String, dynamic>.from(raw);
      repartition = <ReponseFeedback, double>{};
      for (final ReponseFeedback reponse in ReponseFeedback.values) {
        final dynamic ratio = comptes[reponse.valeurSql];
        if (ratio is! num) {
          throw const FormatException('Repartition feedback invalide');
        }
        repartition[reponse] = ratio.toDouble();
      }
    } else if (raw != null) {
      throw const FormatException(
        'Une tendance sous le seuil ne doit rien exposer',
      );
    }
    return TendanceFeedback(
      groupeId: groupeId,
      nombreEchantillons: nombre,
      seuilMinimum: seuil,
      visibleParEnseignant: visible,
      repartition: repartition,
    );
  }
}
