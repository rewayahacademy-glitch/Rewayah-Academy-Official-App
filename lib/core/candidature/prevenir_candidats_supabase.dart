// L'adaptateur Supabase du message qui previent les candidats par e-mail
// (`PortPrevenirCandidats`), sur les RPC de CAND-PREVENIR
// (`20261024010000_cand_prevenir_par_courriel.sql`) :
// `apercu_prevenir_par_courriel` et `prevenir_par_courriel`.
//
// Le serveur decide : qui est a prevenir, ce qui est deja en file, l'etat de
// l'inscription, la limite. L'adaptateur ne calcule rien ; il traduit.
//
// - `42501` : le lecteur n'est pas la direction, ou son genre est inconnu
//   (`PermissionInsuffisante`).
// - `22023` : limite hors bornes (`PrevenirInvalide`).
// - `PGRST202` / `42883` : la fonction n'est pas encore versee
//   (`CapaciteIndisponible`), pas une panne a reessayer.
// - `{erreur: 'inscription_fermee'}`, rendu dans la reponse, sans ecriture :
//   [InscriptionFermee].
// - Une coupure du reseau devient [PrevenirHorsLigne] : pour un envoi, c'est
//   non confirme, et rejouer ne renvoie rien en double (le serveur exclut ce
//   qui est deja en file).
// - Toute autre erreur remonte telle quelle : l'ecran dit « n'a pas abouti »
//   avec « Reessayer », sans affirmer une cause.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'port_prevenir_candidats.dart';

/// Le message qui previent les candidats, servi par Supabase.
class PrevenirCandidatsSupabase implements PortPrevenirCandidats {
  /// Cree l'adaptateur sur le client de l'application.
  PrevenirCandidatsSupabase(SupabaseClient client)
    : _appel = ((String nom, [Map<String, dynamic>? params]) =>
          client.rpc<Object?>(nom, params: params));

  /// Cree l'adaptateur sur un appel injecte (tests).
  PrevenirCandidatsSupabase.avecAppel(this._appel);

  final Future<Object?> Function(String nom, [Map<String, dynamic>? params])
  _appel;

  @override
  Future<ApercuPrevenir> apercu() async {
    final Map<String, dynamic> j = _objet(
      await _executer('apercu_prevenir_par_courriel'),
    );
    return ApercuPrevenir.depuisJson(j);
  }

  @override
  Future<ResultatPrevenir> prevenir({
    int limite = limitePrevenirParDefaut,
  }) async {
    final Map<String, dynamic> j = _objet(
      await _executer('prevenir_par_courriel', <String, dynamic>{
        'p_limite': limite,
      }),
    );
    _refusDuServeur(j);
    return ResultatPrevenir.depuisJson(j);
  }

  Future<Object?> _executer(String nom, [Map<String, dynamic>? params]) async {
    try {
      return await _appel(nom, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw PermissionInsuffisante(nom);
      if (e.code == '22023') throw PrevenirInvalide(e.message);
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependancePrevenirCandidats);
      }
      rethrow;
    } on Object catch (e) {
      if (_estErreurReseau(e)) throw const PrevenirHorsLigne();
      rethrow;
    }
  }
}

/// Traduit le `{erreur: ...}` du serveur en erreur typee. Sans `erreur`, ne
/// fait rien.
void _refusDuServeur(Map<String, dynamic> j) {
  final Object? code = j['erreur'];
  if (code == null) return;
  switch (code) {
    case 'inscription_fermee':
      throw const InscriptionFermee();
    default:
      throw PrevenirRefuseInconnu('$code');
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
