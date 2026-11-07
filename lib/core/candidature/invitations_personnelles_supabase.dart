// L'adaptateur Supabase des codes personnels des candidats importes
// (`PortInvitationsPersonnelles`), sur les RPC de
// `20261120000000_invitations_candidats_importes.sql`.
//
// Le serveur decide de tout (qui est a inviter, le plafond, le nombre attendu) ;
// l'adaptateur traduit :
// - `42501` : hors du super administrateur en double verification
//   (`PermissionInsuffisante`) ;
// - `22023` : arguments refuses (`InvitationsPersonnellesInvalide`) ;
// - `PGRST202` / `42883` : migration pas encore installee
//   (`CapaciteIndisponible`) ;
// - `{erreur: 'nombre_change' | 'plafond_atteint'}` : refus sans ecriture ;
// - une coupure du reseau : [InvitationsPersonnellesHorsLigne] (non confirme).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'port_invitations_personnelles.dart';

/// Les codes personnels, servis par Supabase.
class InvitationsPersonnellesSupabase implements PortInvitationsPersonnelles {
  /// Cree l'adaptateur sur le client de l'application.
  InvitationsPersonnellesSupabase(SupabaseClient client)
    : _appel = ((String nom, [Map<String, dynamic>? params]) =>
          client.rpc<Object?>(nom, params: params));

  /// Cree l'adaptateur sur un appel injecte (tests).
  InvitationsPersonnellesSupabase.avecAppel(this._appel);

  final Future<Object?> Function(String nom, [Map<String, dynamic>? params])
  _appel;

  @override
  Future<ApercuInvitationsPersonnelles> apercu() async =>
      ApercuInvitationsPersonnelles.depuisJson(
        _objet(await _executer('apercu_invitations_candidats_importes')),
      );

  @override
  Future<ResultatInvitationsPersonnelles> envoyer({
    required int attendu,
    int limite = limiteInvitationsParEnvoi,
  }) async {
    final Map<String, dynamic> j = _objet(
      await _executer(
        'envoyer_invitations_candidats_importes',
        <String, dynamic>{'p_attendu': attendu, 'p_limite': limite},
      ),
    );
    switch (j['erreur']) {
      case null:
        return ResultatInvitationsPersonnelles.depuisJson(j);
      case 'nombre_change':
        final Object? n = j['eligibles'];
        throw NombreChange(n is int ? n : 0);
      case 'plafond_atteint':
        final Object? n = j['restants'];
        throw PlafondAtteint(n is int ? n : 0);
      default:
        throw InvitationsPersonnellesRefusInconnu('${j['erreur']}');
    }
  }

  Future<Object?> _executer(String nom, [Map<String, dynamic>? params]) async {
    try {
      return await _appel(nom, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw PermissionInsuffisante(nom);
      if (e.code == '22023') throw InvitationsPersonnellesInvalide(e.message);
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceInvitationsPersonnelles);
      }
      rethrow;
    } on Object catch (e) {
      if (_estErreurReseau(e)) throw const InvitationsPersonnellesHorsLigne();
      rethrow;
    }
  }
}

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) throw const FormatException('reponse attendue : un objet');
  return Map<String, dynamic>.from(v);
}

bool _estErreurReseau(Object error) {
  final String texte = error.toString();
  return texte.contains('SocketException') ||
      texte.contains('ClientException') ||
      texte.contains('TimeoutException') ||
      texte.contains('Failed host lookup') ||
      texte.contains('Connection refused');
}
