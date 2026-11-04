// L'adaptateur Supabase des remplacements de la direction, sur les RPC
// `remplacements_direction`, `remplacants_possibles_seance` et
// `designer_remplacant_admin` (migration 20261102400000), puis
// `enseignants_pour_reaffectation` et `reaffecter_enseignant_classe`
// (migration 20261103100000). Le serveur decide de
// tout ; l'adaptateur traduit ses reponses, il ne calcule rien.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../enseignant/remplacements_supabase.dart' show cleRemplacement;
import 'port_remplacements_direction.dart';

/// Lit le bilan rendu par `remplacements_direction`. Pure, pour les tests.
BilanRemplacements bilanDepuisJson(Object? reponse) {
  final Map<dynamic, dynamic> racine = reponse is Map
      ? reponse
      : const <String, dynamic>{};
  final List<RemplacementsTitulaire> titulaires = <RemplacementsTitulaire>[
    for (final dynamic l in (racine['par_enseignant'] as List?) ?? const [])
      if (l is Map)
        RemplacementsTitulaire(
          titulaireId: '${l['titulaire_id']}',
          titulaire: l['titulaire'] as String? ?? '',
          groupeId: '${l['groupe_id']}',
          classe: l['classe'] as String? ?? '',
          numeroDansFamille: (l['numero_dans_famille'] as num?)?.toInt(),
          seances: (l['seances'] as num?)?.toInt() ?? 0,
          remplacees: (l['remplacees'] as num?)?.toInt() ?? 0,
          sansRemplacant: (l['sans_remplacant'] as num?)?.toInt() ?? 0,
        ),
  ];
  final Map<String, RemplacementSeanceDirection> seances =
      <String, RemplacementSeanceDirection>{};
  for (final dynamic s in (racine['seances'] as List?) ?? const []) {
    if (s is! Map) continue;
    final EtatRemplacementSeance? etat = switch (s['etat']) {
      'absence_declaree' => EtatRemplacementSeance.absenceDeclaree,
      'remplacee' => EtatRemplacementSeance.remplacee,
      _ => null,
    };
    if (etat == null) continue;
    final String id = '${s['seance_id']}';
    seances[id] = RemplacementSeanceDirection(
      seanceId: id,
      etat: etat,
      remplacant: s['remplacant'] as String?,
      horsGenre: s['hors_genre'] == true,
    );
  }
  return BilanRemplacements(parTitulaire: titulaires, seances: seances);
}

/// Le resultat d'une designation, d'apres le message d'erreur du serveur.
ResultatDesignation? resultatDesignationDepuisErreur(String message) =>
    switch (message) {
      'RemplacantOccupe' => ResultatDesignation.occupe,
      'RemplacantIncompatible' => ResultatDesignation.incompatible,
      'RemplacementDejaPris' => ResultatDesignation.dejaPris,
      'SeanceIndisponible' => ResultatDesignation.seanceIndisponible,
      _ => null,
    };

/// Le resultat d'une reaffectation, d'apres le message d'erreur du serveur.
ResultatReaffectation? resultatReaffectationDepuisErreur(String message) =>
    switch (message) {
      'EnseignantOccupe' => ResultatReaffectation.occupe,
      'EnseignantIncompatible' => ResultatReaffectation.incompatible,
      'ClasseIndisponible' => ResultatReaffectation.classeIndisponible,
      _ => null,
    };

/// Les remplacements de la direction servis par Supabase.
class RemplacementsDirectionSupabase implements PortRemplacementsDirection {
  /// Cree l'adaptateur sur le client de l'application.
  const RemplacementsDirectionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<BilanRemplacements> periode(DateTime debut, DateTime fin) async {
    final Object? reponse = await _client.rpc<Object?>(
      'remplacements_direction',
      params: <String, dynamic>{
        'p_debut': debut.toUtc().toIso8601String(),
        'p_fin': fin.toUtc().toIso8601String(),
      },
    );
    return bilanDepuisJson(reponse);
  }

  @override
  Future<List<RemplacantPossible>> possibles(String seanceId) async {
    final Object? reponse = await _client.rpc<Object?>(
      'remplacants_possibles_seance',
      params: <String, dynamic>{'p_session_id': seanceId},
    );
    return <RemplacantPossible>[
      if (reponse is List)
        for (final dynamic l in reponse)
          if (l is Map)
            RemplacantPossible(
              id: '${l['enseignant_id']}',
              nom: l['nom'] as String? ?? '',
              identifiant: l['identifiant'] as String? ?? '',
              genreCompatible: l['genre_compatible'] == true,
            ),
    ];
  }

  @override
  Future<ResultatDesignation> designer({
    required String seanceId,
    required String remplacantId,
    required bool horsGenre,
  }) async {
    try {
      final Object? reponse = await _client.rpc<Object?>(
        'designer_remplacant_admin',
        params: <String, dynamic>{
          'p_session_id': seanceId,
          'p_remplacant_id': remplacantId,
          // Meme seance et meme enseignant : meme cle, d'un essai a l'autre.
          'p_cle_idempotence': cleRemplacement(
            'designation:$remplacantId',
            seanceId,
          ),
          'p_hors_genre': horsGenre,
        },
      );
      if (reponse is Map && reponse['etat'] == 'designe') {
        return ResultatDesignation.designe;
      }
      throw const FormatException('Réponse de désignation inconnue');
    } on PostgrestException catch (e) {
      final ResultatDesignation? connu = resultatDesignationDepuisErreur(
        e.message,
      );
      if (connu != null) return connu;
      rethrow;
    }
  }

  @override
  Future<List<RemplacantPossible>> possiblesReaffectation(
    String groupeId,
  ) async {
    final Object? reponse = await _client.rpc<Object?>(
      'enseignants_pour_reaffectation',
      params: <String, dynamic>{'p_groupe_id': groupeId},
    );
    return <RemplacantPossible>[
      if (reponse is List)
        for (final dynamic l in reponse)
          if (l is Map)
            RemplacantPossible(
              id: '${l['enseignant_id']}',
              nom: l['nom'] as String? ?? '',
              identifiant: l['identifiant'] as String? ?? '',
              // Le serveur n'a rendu que des enseignants du genre du public.
              genreCompatible: true,
            ),
    ];
  }

  @override
  Future<ResultatReaffectation> reaffecter({
    required String groupeId,
    required String enseignantId,
  }) async {
    try {
      final Object? reponse = await _client.rpc<Object?>(
        'reaffecter_enseignant_classe',
        params: <String, dynamic>{
          'p_groupe_id': groupeId,
          'p_enseignant_id': enseignantId,
        },
      );
      return switch (reponse is Map ? reponse['etat'] : null) {
        'reaffecte' => ResultatReaffectation.reaffecte,
        'deja_en_place' => ResultatReaffectation.dejaEnPlace,
        _ => throw const FormatException('Réponse de réaffectation inconnue'),
      };
    } on PostgrestException catch (e) {
      final ResultatReaffectation? connu = resultatReaffectationDepuisErreur(
        e.message,
      );
      if (connu != null) return connu;
      rethrow;
    }
  }
}
