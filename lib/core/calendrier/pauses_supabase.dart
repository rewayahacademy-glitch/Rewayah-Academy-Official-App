// CALENDRIER-ET-PAUSES (12/11/2026) : l'adaptateur Supabase des pauses, sur
// les RPC `pauses_eleve_lecture`, `pause_demander`, `pause_annuler`,
// `pauses_a_traiter`, `pause_decider`, `pause_exception_accorder` et
// `pauses_eleves_recherche` (migration 20261123910000). Le serveur decide de
// tout (preavis, mois civil entier, plafond, recul de la date limite) ;
// l'adaptateur traduit ses reponses et ses refus.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_calendrier.dart';

/// Les pauses servies par Supabase.
class PausesSupabase implements PortPauses {
  /// Cree l'adaptateur.
  const PausesSupabase(this._client);

  final SupabaseClient _client;

  Future<Object?> _appeler(String fonction, Map<String, dynamic>? params) async {
    try {
      return await _client.rpc<Object?>(fonction, params: params);
    } on PostgrestException catch (e) {
      throw PauseRefusee(motifRefusPause(code: e.code, message: e.message));
    }
  }

  @override
  Future<LecturePauses?> lecture(String eleveId) async =>
      LecturePauses.depuisJson(
        await _appeler('pauses_eleve_lecture', <String, dynamic>{
          'p_eleve_id': eleveId,
        }),
      );

  @override
  Future<ReponseDemandePause> demander(String eleveId, DateTime mois) async {
    final ReponseDemandePause? reponse = ReponseDemandePause.depuisJson(
      await _appeler('pause_demander', <String, dynamic>{
        'p_eleve_id': eleveId,
        'p_mois': jourVersSql(mois),
      }),
    );
    if (reponse == null) throw const PauseRefusee(MotifRefusPause.inconnu);
    return reponse;
  }

  @override
  Future<void> annuler(String pauseId) async {
    await _appeler('pause_annuler', <String, dynamic>{'p_pause_id': pauseId});
  }

  @override
  Future<FilePauses> file() async =>
      FilePauses.depuisJson(await _appeler('pauses_a_traiter', null));

  @override
  Future<void> decider(
    String pauseId, {
    required bool accepter,
    String? motif,
  }) async {
    await _appeler('pause_decider', <String, dynamic>{
      'p_pause_id': pauseId,
      'p_accepter': accepter,
      'p_motif': motif,
    });
  }

  @override
  Future<void> accorderException({
    required String eleveId,
    required DateTime fin,
    required String motif,
  }) async {
    await _appeler('pause_exception_accorder', <String, dynamic>{
      'p_eleve_id': eleveId,
      'p_debut': null,
      'p_fin': jourVersSql(fin),
      'p_motif': motif,
    });
  }

  @override
  Future<List<EleveTrouve>> rechercherEleves(String recherche) async {
    final Object? brut = await _appeler('pauses_eleves_recherche', <String, dynamic>{
      'p_q': recherche,
    });
    return <EleveTrouve>[
      for (final Object? l in brut is List ? brut : const <Object?>[])
        if (EleveTrouve.depuisJson(l) case final EleveTrouve e) e,
    ];
  }
}
