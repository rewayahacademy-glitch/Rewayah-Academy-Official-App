// CALENDRIER-ET-PAUSES (12/11/2026) : l'adaptateur Supabase du calendrier de
// la direction, sur les RPC `calendrier_ecole_liste`,
// `calendrier_ecole_enregistrer`, `calendrier_ecole_publier`,
// `calendrier_ecole_retirer`, `calendrier_retrait_conflits` et
// `calendrier_seances_concernees` (migration
// 20261123910000). Le serveur decide de tout ; l'adaptateur traduit ses
// reponses et ses refus, il ne calcule rien.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_calendrier.dart';

/// Le calendrier de la direction servi par Supabase.
class CalendrierDirectionSupabase implements PortCalendrierDirection {
  /// Cree l'adaptateur.
  const CalendrierDirectionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EvenementCalendrier>> lister() async => evenementsDepuisJson(
    await _client.rpc<Object?>('calendrier_ecole_liste'),
  );

  @override
  Future<String> enregistrer({
    required TypeEvenement type,
    required String titre,
    required DateTime du,
    required DateTime au,
    required PorteeEvenement portee,
    String? id,
    CategorieFermeture? categorie,
    String? cohorte,
    String? groupeId,
  }) async {
    try {
      final Object? reponse = await _client.rpc<Object?>(
        'calendrier_ecole_enregistrer',
        params: <String, dynamic>{
          'p_id': id,
          'p_type': type.valeurSql,
          'p_categorie': categorie?.valeurSql,
          'p_titre': titre,
          'p_du': jourVersSql(du),
          'p_au': jourVersSql(au),
          'p_portee': portee.valeurSql,
          'p_cohorte': cohorte,
          'p_groupe_id': groupeId,
        },
      );
      return '$reponse';
    } on PostgrestException catch (e) {
      throw CalendrierRefuse(
        motifRefusCalendrier(code: e.code, message: e.message),
      );
    }
  }

  @override
  Future<void> retirer(String id, {int? abandonner}) async {
    try {
      await _client.rpc<Object?>(
        'calendrier_ecole_retirer',
        params: <String, dynamic>{'p_id': id, 'p_abandonner': abandonner},
      );
    } on PostgrestException catch (e) {
      throw CalendrierRefuse(
        motifRefusCalendrier(code: e.code, message: e.message),
      );
    }
  }

  @override
  Future<ConflitsRetrait> retraitConflits(String id) async =>
      ConflitsRetrait.depuisJson(
        await _client.rpc<Object?>(
          'calendrier_retrait_conflits',
          params: <String, dynamic>{'p_id': id},
        ),
      );

  @override
  Future<ApercuSeances> seancesConcernees(String id) async =>
      ApercuSeances.depuisJson(
        await _client.rpc<Object?>(
          'calendrier_seances_concernees',
          params: <String, dynamic>{'p_id': id},
        ),
      );

  @override
  Future<void> publier(String id, {required bool publie}) async {
    try {
      await _client.rpc<Object?>(
        'calendrier_ecole_publier',
        params: <String, dynamic>{'p_id': id, 'p_publie': publie},
      );
    } on PostgrestException catch (e) {
      throw CalendrierRefuse(
        motifRefusCalendrier(code: e.code, message: e.message),
      );
    }
  }
}
