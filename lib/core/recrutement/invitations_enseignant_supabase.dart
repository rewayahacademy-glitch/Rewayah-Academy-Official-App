// Les adaptateurs Supabase de l'invitation d'un enseignant (C-13, C-14), sur
// les RPC `inviter_enseignant`, `invitations_enseignant_admin`,
// `revoquer_invitation_enseignant` et `verifier_invitation_enseignant`
// (migration 20261016100300).
//
// Les refus metier arrivent dans la reponse (statut), jamais en exception ;
// 42501 dit « non autorise ». L'etat de chaque invitation est celui du
// serveur, jamais deduit de l'horloge de l'appareil.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_invitations_enseignant.dart';

Future<Object?> _appel(
  SupabaseClient client,
  String fonction, [
  Map<String, dynamic>? params,
]) async {
  try {
    return await client.rpc<Object?>(fonction, params: params);
  } on PostgrestException catch (e) {
    if (e.code == '42501') throw const NonAutorise();
    rethrow;
  } on FormatException {
    rethrow;
  } on Exception {
    throw const HorsLigne();
  }
}

/// L'administration des invitations servie par Supabase.
class InvitationsEnseignantSupabase implements PortInvitationsEnseignant {
  /// Cree l'adaptateur sur le client de l'application.
  const InvitationsEnseignantSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Invitation> inviter(String email) async {
    final Object? brut = await _appel(
      _client,
      'inviter_enseignant',
      <String, dynamic>{'p_email': email},
    );
    if (brut is! Map) throw const FormatException('Objet attendu.');
    return switch (brut['statut']) {
      'creee' => invitationJson(_objet(brut['invitation'])),
      'deja_invite' => throw DejaInvite(
        invitationJson(_objet(brut['invitation'])),
      ),
      'email_invalide' => throw const EmailInvalide(),
      'compte_existant' => throw const CompteExistant(),
      _ => throw const FormatException('Statut d invitation inconnu.'),
    };
  }

  @override
  Future<List<Invitation>> lister() async {
    final Object? brut = await _appel(_client, 'invitations_enseignant_admin');
    if (brut is! List) throw const FormatException('Liste attendue.');
    return List<Invitation>.unmodifiable(<Invitation>[
      for (final Object? i in brut) invitationJson(_objet(i)),
    ]);
  }

  @override
  Future<void> revoquer(String code) async {
    await _appel(_client, 'revoquer_invitation_enseignant', <String, dynamic>{
      'p_code': code,
    });
  }
}

/// La verification d'un code par le candidat, servie par Supabase.
class VerificationInvitationSupabase implements PortVerificationInvitation {
  /// Cree l'adaptateur sur le client de l'application.
  const VerificationInvitationSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ResultatInvitation> verifierInvitation(String code) async {
    final Object? brut = await _appel(
      _client,
      'verifier_invitation_enseignant',
      <String, dynamic>{'p_code': code},
    );
    if (brut is! Map) throw const FormatException('Objet attendu.');
    return resultatInvitationJson(Map<String, dynamic>.from(brut));
  }
}

/// La reponse de `verifier_invitation_enseignant`.
ResultatInvitation resultatInvitationJson(Map<String, dynamic> r) {
  final DateTime? expire = _instant(r['expire_le']);
  return switch (r['resultat']) {
    'valide' when expire != null => InvitationValide(expireLe: expire),
    'expiree' when expire != null => InvitationExpiree(expireLe: expire),
    'deja_utilisee' => const InvitationDejaUtilisee(),
    _ => const InvitationInconnue(),
  };
}

/// Une invitation rendue par le serveur.
Invitation invitationJson(Map<String, dynamic> i) => Invitation(
  code: i['code'] as String,
  email: i['email'] as String,
  expireLe:
      _instant(i['expire_le']) ??
      (throw const FormatException('Echeance absente.')),
  etat: switch (i['etat']) {
    'active' => EtatInvitation.active,
    'utilisee' => EtatInvitation.utilisee,
    'expiree' => EtatInvitation.expiree,
    'revoquee' => EtatInvitation.revoquee,
    _ => throw const FormatException('Etat d invitation inconnu.'),
  },
  utiliseeLe: _instant(i['utilisee_le']),
);

DateTime? _instant(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) throw const FormatException('Objet attendu.');
  return Map<String, dynamic>.from(v);
}
