import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class RemplacantEligible {
  const RemplacantEligible({
    required this.id,
    required this.identifiant,
    required this.prenom,
    required this.nom,
  });

  factory RemplacantEligible.depuisJson(Map<String, dynamic> json) =>
      RemplacantEligible(
        id: json['teacher_id'] as String,
        identifiant: json['teacher_immutable_id'] as String? ?? '',
        prenom: json['teacher_prenom'] as String?,
        nom: json['teacher_nom'] as String?,
      );

  final String id;
  final String identifiant;
  final String? prenom;
  final String? nom;

  String get libelle {
    final String nomComplet = <String?>[prenom, nom]
        .whereType<String>()
        .join(' ')
        .trim();
    return nomComplet.isEmpty ? identifiant : nomComplet;
  }
}

abstract interface class ServiceRemplacementSession {
  Future<String> demander(String sessionId);

  Future<List<RemplacantEligible>> eligibles(String sessionId);

  Future<String> inviter({required String sessionId, required String teacherId});

  Future<Map<String, dynamic>> accepter(String invitationId);
}

class ServiceRemplacementSessionSupabase
    implements ServiceRemplacementSession {
  const ServiceRemplacementSessionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<String> demander(String sessionId) => _client.rpc<String>(
    'demander_remplacement_session',
    params: <String, dynamic>{'p_session_id': sessionId},
  );

  @override
  Future<List<RemplacantEligible>> eligibles(String sessionId) async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'remplacants_eligibles_session',
      params: <String, dynamic>{'p_session_id': sessionId},
    );
    return lignes
        .map(
          (dynamic ligne) => RemplacantEligible.depuisJson(
            ligne as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<String> inviter({
    required String sessionId,
    required String teacherId,
  }) => _client.rpc<String>(
    'inviter_remplacant_session',
    params: <String, dynamic>{
      'p_session_id': sessionId,
      'p_teacher_id': teacherId,
    },
  );

  @override
  Future<Map<String, dynamic>> accepter(String invitationId) async {
    final dynamic reponse = await _client.rpc<dynamic>(
      'accepter_invitation_remplacement',
      params: <String, dynamic>{'p_invitation_id': invitationId},
    );
    return Map<String, dynamic>.from(reponse as Map);
  }
}

final Provider<ServiceRemplacementSession> serviceRemplacementSessionProvider =
    Provider<ServiceRemplacementSession>(
      (Ref ref) => ServiceRemplacementSessionSupabase(
        Supabase.instance.client,
      ),
    );

final FutureProviderFamily<List<RemplacantEligible>, String>
remplacantsEligiblesSessionProvider =
    FutureProvider.family<List<RemplacantEligible>, String>(
      (Ref ref, String sessionId) => ref
          .watch(serviceRemplacementSessionProvider)
          .eligibles(sessionId),
    );
