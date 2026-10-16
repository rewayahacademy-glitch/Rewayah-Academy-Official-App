import 'package:supabase_flutter/supabase_flutter.dart';

import 'invitation_conjoint.dart';

/// L'invitation du second adulte servie par les RPC `inviter_conjoint` et
/// `annuler_invitation_conjoint` (migration 0053 ; reprise de l'adaptateur
/// Codex `aeadbc11`, envoi et annulation seulement).
///
/// Un refus du serveur ne dit jamais pourquoi (F4). Une coupure ne confirme
/// rien (D5) : la meme cle rend la nouvelle tentative sure.
class InvitationConjointSupabase implements PortInvitationConjoint {
  /// Cree l'adaptateur sur le client de l'application.
  const InvitationConjointSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ResultatInvitation> envoyer(InvitationConjoint invitation) async {
    try {
      final Object? reponse = await _client.rpc<Object?>(
        'inviter_conjoint',
        params: <String, dynamic>{
          'p_email': invitation.courriel.trim(),
          'p_cle': invitation.cle,
        },
      );
      if (reponse is Map &&
          reponse['queued'] == true &&
          reponse['invitation_id'] is String) {
        return const InvitationPartie();
      }
      return const InvitationRefusee();
    } on PostgrestException {
      return const InvitationRefusee();
    } on Object {
      return const InvitationEchecReseau();
    }
  }

  @override
  Future<ResultatAnnulation> annuler() async {
    try {
      final Object? reponse = await _client.rpc<Object?>(
        'annuler_invitation_conjoint',
      );
      // `false` : plus d'invitation active, l'etat demande est atteint.
      if (reponse is! bool) return const AnnulationEchecReseau();
      return const AnnulationFaite();
    } on Object {
      return const AnnulationEchecReseau();
    }
  }
}
