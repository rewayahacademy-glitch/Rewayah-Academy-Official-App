// L'adaptateur Supabase du support actif d'une seance (CAP29-G), sur les RPC
// `support_actif_capacites`, `presenter_support` et `support_actif`
// (migration 20261016100400).
//
// Le suivi : une lecture de `support_actif` a l'ouverture, puis une relecture
// a chaque changement de la ligne `session_shared_content` de la seance
// (Realtime). Le paquet Realtime ne sert que de signal : ce qui s'affiche est
// toujours la relecture, ou le serveur recontrole les droits. Aucune URL
// signee ni cle de stockage ne transite.
//
// Tant que `session_shared_content` n'est pas publiee dans
// `supabase_realtime` (constat STAGING du 16/10 : seules annotation_layer et
// demande_evenements le sont), le canal ne signale rien : une relecture
// periodique ([intervalleSupportActif]) tient le suivi en attendant.

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../tc_etat_partage/codec_etat_partage.dart';
import 'content_position.dart';
import 'library_resource.dart';
import 'port_support_actif.dart';

/// L'intervalle de relecture du support actif, tant que l'ecran l'ecoute.
const Duration intervalleSupportActif = Duration(seconds: 5);

/// Le support actif servi par Supabase.
class SupportActifSupabase implements PortSupportActif {
  /// Cree l'adaptateur sur le client de l'application.
  const SupportActifSupabase(this._client);

  final SupabaseClient _client;

  Future<Object?> _rpc(String fonction, Map<String, dynamic> params) async {
    try {
      return await _client.rpc<Object?>(fonction, params: params);
    } on PostgrestException {
      rethrow;
    } on FormatException {
      rethrow;
    } on Exception {
      throw const SupportActifHorsLigne();
    }
  }

  @override
  Future<CapacitesSupportActif> capacites(String seanceId) async {
    final Object? brut = await _rpc(
      'support_actif_capacites',
      <String, dynamic>{'p_seance_id': seanceId},
    );
    return CapacitesSupportActif(
      peutPresenter: brut is Map && brut['peut_presenter'] == true,
    );
  }

  @override
  Future<ResultatActivation> activer({
    required String seanceId,
    required String resourceId,
    required int revisionAttendue,
    required String cle,
    ContentPosition? position,
  }) async {
    final Object? brut = await _rpc('presenter_support', <String, dynamic>{
      'p_seance_id': seanceId,
      'p_resource_id': resourceId,
      'p_revision_attendue': revisionAttendue,
      'p_cle': cle,
      'p_position': position == null
          ? null
          : <String, dynamic>{
              for (final MapEntry<String, dynamic> e in positionVersJson(
                position,
              ).entries)
                if (e.value != null) e.key: e.value,
            },
    });
    if (brut is! Map) throw const FormatException('Objet attendu.');
    return resultatActivationJson(Map<String, dynamic>.from(brut));
  }

  @override
  Stream<SupportActif?> suivre(String seanceId) {
    late final StreamController<SupportActif?> flux;
    RealtimeChannel? canal;
    Timer? minuterie;
    var relectures = Future<void>.value();

    void relire() {
      relectures = relectures.then((_) async {
        try {
          final Object? brut = await _rpc('support_actif', <String, dynamic>{
            'p_seance_id': seanceId,
          });
          if (!flux.isClosed) flux.add(supportActifJson(brut));
        } on Object catch (e, pile) {
          if (!flux.isClosed) flux.addError(e, pile);
        }
      });
    }

    flux = StreamController<SupportActif?>(
      onListen: () {
        relire();
        minuterie = Timer.periodic(
          intervalleSupportActif,
          (Timer _) => relire(),
        );
        canal = _client
            .channel('support-actif:$seanceId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'session_shared_content',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'session_id',
                value: seanceId,
              ),
              callback: (PostgresChangePayload _) => relire(),
            )
            .subscribe();
      },
      onCancel: () async {
        minuterie?.cancel();
        final RealtimeChannel? c = canal;
        canal = null;
        if (c != null) await _client.removeChannel(c);
        await flux.close();
      },
    );
    return flux.stream;
  }
}

/// La reponse de `presenter_support`.
ResultatActivation resultatActivationJson(Map<String, dynamic> r) =>
    switch (r['statut']) {
      'faite' => switch (supportActifJson(r['actif'])) {
        final SupportActif actif => ActivationFaite(actif),
        null => throw const FormatException('Support actif absent.'),
      },
      'refusee' => ActivationRefusee(switch (r['raison']) {
        'retire' => RefusActivation.retire,
        'droits_echus' => RefusActivation.droitsEchus,
        'non_attribue' => RefusActivation.nonAttribue,
        _ => throw const FormatException('Raison de refus inconnue.'),
      }),
      'conflit' => const ActivationEnConflit(),
      _ => throw const FormatException('Statut de presentation inconnu.'),
    };

/// Le support actif rendu par `support_actif` ; nul quand aucun support
/// n'est presente.
SupportActif? supportActifJson(Object? brut) {
  if (brut is! Map) return null;
  final Map<String, dynamic> m = Map<String, dynamic>.from(brut);
  final Object? position = m['position'];
  return SupportActif(
    resourceId: m['resource_id'] as String,
    titre: m['titre'] as String? ?? '',
    type:
        TypeRessource.depuisSql(m['type'] as String?) ??
        (throw const FormatException('Type de ressource inconnu.')),
    revision: (m['revision'] as num?)?.toInt() ?? 0,
    numeroVersion: (m['numero_version'] as num?)?.toInt(),
    position: position is Map
        ? positionDepuisJson(Map<String, dynamic>.from(position))
        : null,
    retire: m['retire'] == true,
  );
}
