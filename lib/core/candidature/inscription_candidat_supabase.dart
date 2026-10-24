// L'adaptateur Supabase de l'inscription du candidat (`PortInscriptionCandidat`,
// `CAND-04`), sur les RPC du lot CAND-L3
// (`20261022000600_cand_l3_inscription_import_rapprochement.sql`) :
// `inscription_candidat_ouverte` et `inscrire_candidat`.
//
// Les refus metier arrivent **dans la reponse** (`{"resultat": "..."}`), jamais
// en exception : le serveur les rend pour qu'ils ne laissent aucune ecriture.
// 42501 dit « session sans adresse, ou deja un profil » : [PermissionInsuffisante].
// Une fonction que le serveur ne connait pas encore (lot non verse) est une
// capacite indisponible, pas une panne a reessayer. Une panne de reseau devient
// [HorsLigneCandidature] : ce qui a ete envoye est alors non confirme.
//
// L'adaptateur ne decide rien : il ne valide ni le telephone, ni la langue, ni
// la version de confidentialite (le serveur le fait), et il ne distingue pas un
// succes d'un depassement du plafond horaire, que le serveur ne distingue pas
// non plus (CAND-F03).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'port_inscription_candidat.dart';
import 'port_ma_candidature.dart';

/// Un appel RPC injectable (tests) ; en production, `client.rpc`.
typedef AppelInscriptionCandidat = Future<Object?> Function(
  String fonction,
  Map<String, dynamic>? params,
);

AppelInscriptionCandidat _client(SupabaseClient client) =>
    (String fonction, Map<String, dynamic>? params) =>
        client.rpc<Object?>(fonction, params: params);

/// L'inscription du candidat servie par Supabase.
class InscriptionCandidatSupabase implements PortInscriptionCandidat {
  /// Cree l'adaptateur sur le client de l'application.
  InscriptionCandidatSupabase(SupabaseClient client) : _rpc = _client(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  InscriptionCandidatSupabase.avecAppel(this._rpc);

  final AppelInscriptionCandidat _rpc;

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
        throw const CapaciteIndisponible(dependanceInscriptionCandidat);
      }
      rethrow;
    } on FormatException {
      rethrow;
    } on Exception {
      throw const HorsLigneCandidature();
    }
  }

  @override
  Future<OuvertureInscriptionCandidat> ouverte() async =>
      ouvertureInscriptionCandidatJson(
        await _appel('inscription_candidat_ouverte'),
      );

  @override
  Future<ResultatInscriptionCandidat> inscrire({
    required String prenom,
    required String nom,
    required String genre,
    required String telephone,
    required String langue,
    required String versionConfidentialite,
    String? code,
  }) async => resultatInscriptionCandidatJson(
    await _appel('inscrire_candidat', <String, dynamic>{
      'p_code': code,
      'p_first_name': prenom,
      'p_last_name': nom,
      'p_gender': genre,
      'p_telephone': telephone,
      'p_langue': langue,
      'p_version_confidentialite': versionConfidentialite,
    }),
  );
}
