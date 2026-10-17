// Les adaptateurs Supabase de l'invitation d'un comptable (BF1-03), sur les
// RPC `inviter_comptable`, `invitations_comptable_admin`,
// `revoquer_invitation_comptable`, `verifier_invitation_comptable` et
// `inscrire_comptable_invite` (migration 20261017160200).
//
// Memes regles que l'invitation enseignant : refus metier dans la reponse,
// 42501 = non autorise, toute autre panne d'appel = hors ligne.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'invitations_enseignant_supabase.dart';
import 'port_invitations_comptable.dart';
import 'port_invitations_enseignant.dart';

/// Un appel RPC injectable (tests) ; en production, `client.rpc`.
typedef AppelInvitation = Future<Object?> Function(
  String fonction,
  Map<String, dynamic>? params,
);

AppelInvitation _client(SupabaseClient client) =>
    (String fonction, Map<String, dynamic>? params) =>
        client.rpc<Object?>(fonction, params: params);

Future<Object?> _appel(
  AppelInvitation appel,
  String fonction, [
  Map<String, dynamic>? params,
]) async {
  try {
    return await appel(fonction, params);
  } on PostgrestException catch (e) {
    if (e.code == '42501') throw const NonAutorise();
    rethrow;
  } on FormatException {
    rethrow;
  } on Exception {
    throw const HorsLigne();
  }
}

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) throw const FormatException('Objet attendu.');
  return Map<String, dynamic>.from(v);
}

/// L'administration des invitations de comptable servie par Supabase.
class InvitationsComptableSupabase implements PortInvitationsEnseignant {
  /// Cree l'adaptateur sur le client de l'application.
  InvitationsComptableSupabase(SupabaseClient client) : _rpc = _client(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  InvitationsComptableSupabase.avecAppel(this._rpc);

  final AppelInvitation _rpc;

  @override
  Future<Invitation> inviter(String email) async {
    final Map<String, dynamic> r = _objet(
      await _appel(_rpc, 'inviter_comptable', <String, dynamic>{
        'p_email': email,
      }),
    );
    return switch (r['statut']) {
      'creee' => invitationJson(_objet(r['invitation'])),
      'deja_invite' => throw DejaInvite(
        invitationJson(_objet(r['invitation'])),
      ),
      'email_invalide' => throw const EmailInvalide(),
      'compte_existant' => throw const CompteExistant(),
      _ => throw const FormatException('Statut d invitation inconnu.'),
    };
  }

  @override
  Future<List<Invitation>> lister() async {
    final Object? brut = await _appel(_rpc, 'invitations_comptable_admin');
    if (brut is! List) throw const FormatException('Liste attendue.');
    return List<Invitation>.unmodifiable(<Invitation>[
      for (final Object? i in brut) invitationJson(_objet(i)),
    ]);
  }

  @override
  Future<void> revoquer(String code) async {
    await _appel(_rpc, 'revoquer_invitation_comptable', <String, dynamic>{
      'p_code': code,
    });
  }
}

/// La verification d'un code de comptable par le candidat.
class VerificationInvitationComptableSupabase
    implements PortVerificationInvitation {
  /// Cree l'adaptateur sur le client de l'application.
  VerificationInvitationComptableSupabase(SupabaseClient client)
    : _rpc = _client(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  VerificationInvitationComptableSupabase.avecAppel(this._rpc);

  final AppelInvitation _rpc;

  @override
  Future<ResultatInvitation> verifierInvitation(String code) async =>
      resultatInvitationJson(
        _objet(
          await _appel(_rpc, 'verifier_invitation_comptable', <String, dynamic>{
            'p_code': code,
          }),
        ),
      );
}

/// L'inscription d'un comptable invite.
class InscriptionComptableSupabase implements PortInscriptionComptable {
  /// Cree l'adaptateur sur le client de l'application.
  InscriptionComptableSupabase(SupabaseClient client) : _rpc = _client(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  InscriptionComptableSupabase.avecAppel(this._rpc);

  final AppelInvitation _rpc;

  @override
  Future<ResultatInscriptionComptable> inscrire({
    required String code,
    required String prenom,
    required String nom,
    String? genre,
  }) async => resultatInscriptionComptableJson(
    await _appel(_rpc, 'inscrire_comptable_invite', <String, dynamic>{
      'p_code': code,
      'p_first_name': prenom,
      'p_last_name': nom,
      'p_gender': genre,
    }),
  );
}
