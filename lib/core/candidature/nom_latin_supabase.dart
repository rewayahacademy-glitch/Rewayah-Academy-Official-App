// L'adaptateur Supabase du nom latin (`PortNomLatin`), sur les RPC de
// `20261024000000_cand_nom_latin.sql` : `lire_nom_latin` et `confirmer_nom_latin`.
//
// Le refus metier arrive **dans la reponse** (`{"erreur": "nom_non_latin"}`).
// 42501 dit « pas de candidature pour ce compte » : [PermissionInsuffisante].
// Une fonction que le serveur ne connait pas encore (lot non verse) est une
// capacite indisponible. Une panne de reseau est [HorsLigneCandidature].
//
// L'adaptateur ne decide rien : il n'envoie que le texte recu et ne
// translittere jamais.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'port_ma_candidature.dart';
import 'port_nom_latin.dart';

/// Un appel RPC injectable (tests) ; en production, `client.rpc`.
typedef AppelNomLatin = Future<Object?> Function(
  String fonction,
  Map<String, dynamic>? params,
);

AppelNomLatin _client(SupabaseClient client) =>
    (String fonction, Map<String, dynamic>? params) =>
        client.rpc<Object?>(fonction, params: params);

/// Le nom latin servi par Supabase.
class NomLatinSupabase implements PortNomLatin {
  /// Cree l'adaptateur sur le client de l'application.
  NomLatinSupabase(SupabaseClient client) : _rpc = _client(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  NomLatinSupabase.avecAppel(this._rpc);

  final AppelNomLatin _rpc;

  Future<Object?> _appel(
    String fonction, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      return await _rpc(fonction, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw PermissionInsuffisante(fonction);
      }
      // PGRST202 : fonction absente du cache de schema ; 42883 : fonction
      // inconnue de la base. Le lot serveur n'est pas encore verse.
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceNomLatin);
      }
      rethrow;
    } on FormatException {
      rethrow;
    } on Exception {
      throw const HorsLigneCandidature();
    }
  }

  @override
  Future<EtatNomLatin> lire() async =>
      EtatNomLatin.depuisJson(await _appel('lire_nom_latin'));

  @override
  Future<String> confirmer(String nomLatin) async {
    final Object? brut = await _appel('confirmer_nom_latin', <String, dynamic>{
      'p_nom_latin': nomLatin,
    });
    if (brut is! Map) {
      throw const FormatException('Objet attendu.');
    }
    if (brut['erreur'] == 'nom_non_latin') {
      throw const NomNonLatin();
    }
    final Object? retenu = brut['nomLatin'];
    if (retenu is! String || retenu.isEmpty) {
      throw const FormatException('Nom latin absent.');
    }
    return retenu;
  }
}
