// Adaptateur COURRIELS-2 : les RPC de la migration 20261023140000
// (`langues_communication_lister`, `ma_langue_communication`,
// `ma_langue_communication_regler`).
//
// Erreurs : une fonction absente (PGRST202) se dit [CapaciteIndisponible] ;
// `42501` (pas de profil) se dit [PermissionInsuffisante] ; `22023` au reglage
// devient [LangueRefusee]. Toute autre erreur remonte telle quelle : l'ecran ne
// dit jamais un succes qu'il ignore.
//
// Apres un reglage reussi, la langue est aussi posee dans les donnees de
// l'utilisateur d'authentification (`user_metadata.langue`) : les modeles
// d'e-mails de connexion de Supabase Auth en dependent. Cette seconde ecriture
// ne defait pas la premiere : la langue du profil est deja enregistree, les
// e-mails de connexion la suivront au prochain reglage.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'permission_insuffisante.dart';
import 'port_langues_communication.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'COURRIELS-2';

/// Pose la langue dans les donnees de l'utilisateur d'authentification.
typedef PoserLangueAuth = Future<void> Function(String code);

/// La langue de communication servie par Supabase.
class LanguesCommunicationSupabase implements PortLanguesCommunication {
  /// Cree l'adaptateur sur le client de l'application.
  LanguesCommunicationSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client),
      _poserAuth = ((String code) async {
        await client.auth.updateUser(
          UserAttributes(data: <String, dynamic>{'langue': code}),
        );
      });

  /// Cree l'adaptateur sur un appel injecte (tests).
  LanguesCommunicationSupabase.avecAppel(this._appel, this._poserAuth);

  final AppelRpc _appel;
  final PoserLangueAuth _poserAuth;

  Future<Object?> _appeler(
    String fonction, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      return await appelerFinance(_appel, fonction, _dependance, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw const PermissionInsuffisante(_dependance);
      rethrow;
    }
  }

  @override
  Future<List<LangueCommunication>> lister() async {
    final Object? brut = await _appeler('langues_communication_lister');
    return List<LangueCommunication>.unmodifiable(<LangueCommunication>[
      for (final Object? ligne
          in brut == null ? const <Object?>[] : listeJson(brut, 'langues'))
        langueDepuis(objetJson(ligne, 'langue')),
    ]);
  }

  @override
  Future<String?> maLangue() async {
    final Object? brut = await _appeler('ma_langue_communication');
    if (brut == null) return null;
    if (brut is String && brut.trim().isNotEmpty) return brut.trim();
    throw const FormatException('langue invalide: ma_langue_communication');
  }

  @override
  Future<void> regler(String code) async {
    try {
      await _appeler('ma_langue_communication_regler', <String, dynamic>{
        'p_code': code,
      });
    } on PostgrestException catch (e) {
      if (e.code == '22023') throw const LangueRefusee();
      rethrow;
    }
    try {
      await _poserAuth(code);
    } on Object {
      // La langue du profil est enregistree ; voir l'en-tete du fichier.
    }
  }
}

/// Une ligne de `langues_communication_lister`. Pure, testee.
LangueCommunication langueDepuis(Map<String, dynamic> j) => LangueCommunication(
  code: texteJson(j, 'code'),
  libelle: texteJson(j, 'libelle'),
  droiteAGauche: booleenJson(j, 'droite_a_gauche'),
);
