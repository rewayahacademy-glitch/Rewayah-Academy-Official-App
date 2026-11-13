// POINT-DE-SEANCE : l'adaptateur Supabase (migration 20261125000000). Le
// serveur porte les gardes et tous les calculs ; l'adaptateur appelle et
// traduit les refus.

import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_point_seance.dart';

/// Le point de fin de seance servi par Supabase.
class PointSeanceSupabase implements PortPointSeance {
  /// Cree l'adaptateur.
  const PointSeanceSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<PointSeance?> lire(String seanceId) async {
    final Object? lecture = await _client.rpc<Object?>(
      'point_seance_lire',
      params: <String, Object?>{'p_session_id': seanceId},
    );
    return PointSeance.depuisLecture(lecture);
  }

  @override
  Future<PointSeance?> envoyer(
    String seanceId,
    Map<String, ReponsePoint> reponses, {
    String? note,
  }) async {
    try {
      final Object? lecture = await _client.rpc<Object?>(
        'point_seance_envoyer',
        params: <String, Object?>{
          'p_session_id': seanceId,
          'p_reponses': <String, String>{
            for (final MapEntry<String, ReponsePoint> e in reponses.entries)
              e.key: e.value.code,
          },
          'p_note': note,
        },
      );
      return PointSeance.depuisLecture(lecture);
    } on PostgrestException catch (e) {
      throw EchecPointSeance(refusDepuis(e.code, e.message));
    } on SocketException {
      throw const EchecPointSeance(RefusPoint.reseau);
    } on TimeoutException {
      throw const EchecPointSeance(RefusPoint.reseau);
    } on AuthException {
      throw const EchecPointSeance(RefusPoint.reseau);
    }
  }

  /// Le motif d'un refus du serveur.
  static RefusPoint refusDepuis(String? code, String message) {
    if (code == '42501') return RefusPoint.refuse;
    if (message.contains('point_seance_eleve_tire_sans_reponse')) {
      return RefusPoint.eleveTireSansReponse;
    }
    if (message.contains('point_seance_delai_depasse')) {
      return RefusPoint.delaiDepasse;
    }
    if (message.contains('point_seance_seance_non_tenue')) {
      return RefusPoint.seanceNonTenue;
    }
    if (message.contains('point_seance_aucun_present')) {
      return RefusPoint.aucunPresent;
    }
    if (message.contains('point_seance_eleve_absent') ||
        message.contains('point_seance_reponse_inconnue')) {
      return RefusPoint.presentsChanges;
    }
    return RefusPoint.reseau;
  }

  @override
  Future<List<PointAFaire>> aFaire() async {
    final Object? lecture = await _client.rpc<Object?>('points_seance_a_faire');
    return <PointAFaire>[
      for (final Object? e in lecture as List<Object?>? ?? const <Object?>[])
        if (e is Map && DateTime.tryParse('${e['debut']}') != null)
          PointAFaire(
            seanceId: '${e['session_id']}',
            classe: e['classe'] as String? ?? '',
            debut: DateTime.parse('${e['debut']}').toLocal(),
          ),
    ];
  }

  @override
  Future<HistoriqueSeances?> historique(String eleveId) async {
    try {
      final Object? lecture = await _client.rpc<Object?>(
        'historique_seances_eleve',
        params: <String, Object?>{'p_eleve_id': eleveId},
      );
      return HistoriqueSeances.depuisLecture(lecture);
    } on PostgrestException catch (e) {
      // Le serveur ne l'ouvre pas a cette personne (le compte d'un enfant de
      // 6 a 9 ans : son tuteur le lit) : rien a montrer, pas une panne.
      if (e.code == '42501') return null;
      rethrow;
    }
  }
}
