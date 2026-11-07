// PUSH-1 : l'adaptateur Supabase des notifications sur l'appareil
// (migration 20261112000200, fonction Edge push-cle). Aucune regle ici : le
// serveur dit qui peut s'abonner et ce qui part.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_push.dart';

/// Les RPC `push_*` et la fonction Edge `push-cle`.
class PushSupabase implements PortPush {
  /// Cree l'adaptateur.
  const PushSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ReglagesPushServeur> reglages({String? adresse}) async {
    final Object? brut = await _client.rpc<Object?>(
      'push_mes_reglages',
      params: <String, dynamic>{'p_endpoint': adresse},
    );
    return reglagesPushJson(brut);
  }

  @override
  Future<String> clePublique() async {
    final FunctionResponse r = await _client.functions.invoke(
      'push-cle',
      method: HttpMethod.get,
    );
    final Object? data = r.data;
    if (data is Map &&
        data['cle'] is String &&
        (data['cle'] as String).isNotEmpty) {
      return data['cle'] as String;
    }
    throw const FormatException('push-cle : cle absente');
  }

  @override
  Future<void> inscrire(
    AbonnementNavigateur abonnement, {
    String? appareil,
  }) async {
    await _client.rpc<Object?>(
      'push_inscrire',
      params: <String, dynamic>{
        'p_endpoint': abonnement.endpoint,
        'p_p256dh': abonnement.p256dh,
        'p_auth': abonnement.auth,
        'p_appareil': appareil,
      },
    );
  }

  @override
  Future<void> desinscrire(String adresse) async {
    await _client.rpc<Object?>(
      'push_desinscrire',
      params: <String, dynamic>{'p_endpoint': adresse},
    );
  }

  @override
  Future<void> reglerCategorie(
    CategoriePush categorie, {
    required bool actif,
  }) async {
    await _client.rpc<Object?>(
      'push_regler_categorie',
      params: <String, dynamic>{
        'p_categorie': categorie.name,
        'p_actif': actif,
      },
    );
  }
}

/// Decode la reponse de `push_mes_reglages` ; une categorie inconnue (serveur
/// plus recent) est ignoree.
ReglagesPushServeur reglagesPushJson(Object? brut) {
  if (brut is! Map) {
    throw const FormatException('push_mes_reglages : objet attendu');
  }
  final Map<CategoriePush, bool> categories = <CategoriePush, bool>{};
  final Object? liste = brut['categories'];
  if (liste is List) {
    for (final Object? c in liste) {
      if (c is Map && c['code'] is String && c['actif'] is bool) {
        final CategoriePush? cat = CategoriePush.depuisCode(
          c['code'] as String,
        );
        if (cat != null) categories[cat] = c['actif'] as bool;
      }
    }
  }
  final Object? appareils = brut['appareils'];
  return ReglagesPushServeur(
    autorise: brut['autorise'] == true,
    cetAppareil: brut['cetAppareil'] == true,
    appareils: appareils is int ? appareils : 0,
    categories: categories,
  );
}
