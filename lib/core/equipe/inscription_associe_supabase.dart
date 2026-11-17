// L'adaptateur Supabase de l'inscription d'un associe invite. `42501` dit « cette
// session ne peut pas s'inscrire comme associe » (deja un profil, ou pas
// d'adresse) ; `22023` dit « un champ est refuse » ; `PGRST202` / `42883` dit
// « pas encore verse » : le port est alors indisponible.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import 'port_inscription_associe.dart';

/// L'inscription d'un associe, servie par Supabase.
class InscriptionAssocieSupabase implements PortInscriptionAssocie {
  /// Cree l'adaptateur sur le client de l'application.
  InscriptionAssocieSupabase(SupabaseClient client)
    : _appel = ((String f, Map<String, dynamic> p) =>
          client.rpc<Object?>(f, params: p));

  /// Cree l'adaptateur sur un appel injecte (tests).
  InscriptionAssocieSupabase.avecAppel(this._appel);

  final Future<Object?> Function(String fonction, Map<String, dynamic> params)
  _appel;

  Future<Object?> _rpc(String fonction, Map<String, dynamic> params) async {
    try {
      return await _appel(fonction, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const RefusInscriptionAssocie(
          CauseRefusInscriptionAssocie.sessionRefusee,
        );
      }
      if (e.code == '22023') {
        throw const RefusInscriptionAssocie(
          CauseRefusInscriptionAssocie.champsRefuses,
        );
      }
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceInscriptionAssocie);
      }
      rethrow;
    } on FormatException {
      rethrow;
    } on Exception {
      throw const HorsLigneInscriptionAssocie();
    }
  }

  @override
  Future<ResultatCodeAssocie> verifier(String code) async =>
      resultatCodeAssocieJson(
        await _rpc('verifier_invitation_associe', <String, dynamic>{
          'p_code': code,
        }),
      );

  @override
  Future<ResultatInscriptionAssocie> inscrire({
    required String code,
    required String prenom,
    required String nom,
    required String genre,
  }) async => resultatInscriptionAssocieJson(
    await _rpc('inscrire_associe_invite', <String, dynamic>{
      'p_code': code,
      'p_first_name': prenom,
      'p_last_name': nom,
      'p_gender': genre,
    }),
  );
}
