// LETTRE-SERVEUR (20/11/2026) : l'adaptateur Supabase de la lettre aux
// candidats enseignants (`PortLettre`), sur la RPC
// `public.lire_lettre_candidats(p_langue text)` de
// `20261130970000_lettre_candidats.sql`.
//
// Le serveur decide seul qui lit : la reponse (lettre ou refus) passe telle
// quelle a `LectureLettre.depuisJson`. Une fonction que le serveur ne connait
// pas encore (migration non installee) est une capacite indisponible ; 42501
// (aucun droit d'execution) est une [PermissionInsuffisante] ; une panne de
// reseau est [HorsLigneCandidature], que la page affiche hors connexion.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/candidature/lettre/port_lettre.dart';
import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'port_ma_candidature.dart';

/// La dependance que nomme la capacite indisponible.
const String dependanceLettre = 'LETTRE-SERVEUR';

/// La RPC de lecture.
const String fonctionLireLettre = 'lire_lettre_candidats';

/// Un appel RPC injectable (tests) ; en production, `client.rpc`.
typedef AppelLettre = Future<Object?> Function(
  String fonction,
  Map<String, dynamic>? params,
);

AppelLettre _client(SupabaseClient client) =>
    (String fonction, Map<String, dynamic>? params) =>
        client.rpc<Object?>(fonction, params: params);

/// La lettre servie par Supabase.
class LettreSupabase implements PortLettre {
  /// Cree l'adaptateur sur le client de l'application.
  LettreSupabase(SupabaseClient client) : _rpc = _client(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  LettreSupabase.avecAppel(this._rpc);

  final AppelLettre _rpc;

  @override
  Future<LectureLettre> lire({required String langue}) async {
    final Object? brut;
    try {
      brut = await _rpc(fonctionLireLettre, <String, dynamic>{
        'p_langue': langue,
      });
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const PermissionInsuffisante(fonctionLireLettre);
      }
      // PGRST202 : fonction absente du cache de schema ; 42883 : fonction
      // inconnue de la base. La migration n'est pas encore installee.
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceLettre);
      }
      rethrow;
    } on Exception {
      throw const HorsLigneCandidature();
    }
    if (brut is! Map) {
      throw const FormatException('lettre : objet attendu');
    }
    return LectureLettre.depuisJson(Map<String, dynamic>.from(brut));
  }
}
