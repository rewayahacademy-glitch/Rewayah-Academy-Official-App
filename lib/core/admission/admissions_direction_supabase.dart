import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_admissions_direction.dart';

/// L'adaptateur des admissions (migration 20261030140000).
class AdmissionsDirectionSupabase implements PortAdmissionsDirection {
  /// Cree l'adaptateur.
  const AdmissionsDirectionSupabase(this._client);

  final SupabaseClient _client;

  /// Un geste rend l'etat de la demande ; un refus rendu (`erreur`) devient
  /// [GesteAdmissionRefuse], jamais le texte du serveur.
  void _verifier(Object? reponse) {
    if (reponse is Map<String, dynamic> && reponse['erreur'] is String) {
      throw GesteAdmissionRefuse(switch (reponse['erreur'] as String) {
        'conflit_candidature' => RefusGesteAdmission.dejaTraitee,
        'transition_interdite' => RefusGesteAdmission.transitionInterdite,
        'motif_requis' => RefusGesteAdmission.motifRequis,
        'adresse_inconnue' => RefusGesteAdmission.adresseInconnue,
        'enfant_en_classe' => RefusGesteAdmission.enfantEnClasse,
        _ => RefusGesteAdmission.autre,
      });
    }
  }

  @override
  Future<PageAdmissions> lister(
    PopulationAdmission population, {
    String? recherche,
    int page = 1,
  }) async {
    final Object? r = await _client.rpc<Object?>(
      'lister_demandes_admission',
      params: <String, dynamic>{
        'p_type': population.valeurSql,
        'p_recherche': recherche,
        'p_page': page,
      },
    );
    final Map<String, dynamic> j = r is Map<String, dynamic>
        ? r
        : const <String, dynamic>{};
    return PageAdmissions(
      lignes: <DemandeAdmission>[
        if (j['lignes'] is List<dynamic>)
          for (final Object? l in j['lignes'] as List<dynamic>)
            if (l is Map<String, dynamic>) DemandeAdmission.depuisJson(l),
      ],
      total: (j['total'] as num?)?.toInt() ?? 0,
      aTraiter: (j['aTraiter'] as num?)?.toInt() ?? 0,
      page: (j['page'] as num?)?.toInt() ?? page,
      parPage: (j['parPage'] as num?)?.toInt() ?? 50,
    );
  }

  @override
  Future<void> accepter(DemandeAdmission d, {required String cle}) async =>
      _verifier(
        await _client.rpc<Object?>(
          'accepter_admission',
          params: <String, dynamic>{
            'p_id': d.id,
            'p_version_attendue': d.version,
            'p_cle_idempotence': cle,
          },
        ),
      );

  @override
  Future<void> refuser(
    DemandeAdmission d, {
    required String motif,
    required String modele,
    required String cle,
  }) async => _verifier(
    await _client.rpc<Object?>(
      'refuser_admission',
      params: <String, dynamic>{
        'p_id': d.id,
        'p_motif': motif,
        'p_modele': modele,
        'p_version_attendue': d.version,
        'p_cle_idempotence': cle,
      },
    ),
  );

  @override
  Future<void> annulerRefus(
    DemandeAdmission d, {
    required String motif,
    required String cle,
  }) async => _verifier(
    await _client.rpc<Object?>(
      'annuler_refus_admission',
      params: <String, dynamic>{
        'p_id': d.id,
        'p_motif': motif,
        'p_version_attendue': d.version,
        'p_cle_idempotence': cle,
      },
    ),
  );

  @override
  Future<void> annulerAcceptation(
    DemandeAdmission d, {
    required String motif,
    required String cle,
  }) async => _verifier(
    await _client.rpc<Object?>(
      'annuler_admission',
      params: <String, dynamic>{
        'p_id': d.id,
        'p_motif': motif,
        'p_version_attendue': d.version,
        'p_cle_idempotence': cle,
      },
    ),
  );

  @override
  Future<void> demanderPrecisions(
    DemandeAdmission d, {
    required String message,
    required String cle,
  }) async => _verifier(
    await _client.rpc<Object?>(
      'demander_precisions_admission',
      params: <String, dynamic>{
        'p_id': d.id,
        'p_message': message,
        'p_version_attendue': d.version,
        'p_cle_idempotence': cle,
      },
    ),
  );

  @override
  Future<void> contacter(
    DemandeAdmission d, {
    required String sujet,
    required String message,
    required String cle,
  }) async => _verifier(
    await _client.rpc<Object?>(
      'contacter_admission',
      params: <String, dynamic>{
        'p_id': d.id,
        'p_sujet': sujet,
        'p_message': message,
        'p_cle_idempotence': cle,
      },
    ),
  );
}
