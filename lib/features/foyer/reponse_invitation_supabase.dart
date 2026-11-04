import 'package:supabase_flutter/supabase_flutter.dart';

import 'invitation_conjoint.dart';

/// L'invitation recue par le second adulte, servie par les RPC
/// `mon_invitation_en_cours` et `repondre_invitation_conjoint` (migration
/// 0053, EA-BR-20 ; lot N2, FA2).
///
/// Le serveur rend un etat (`a_repondre`, `acceptee`, `refusee`, `perimee`,
/// `non_acceptable`) ; tout autre forme est lue « non acceptable », la forme
/// neutre et sans motif (F4). Une coupure ne confirme rien (D5) : la meme cle
/// rend la nouvelle tentative sure.
class ReponseInvitationSupabase implements PortReponseInvitation {
  /// Cree l'adaptateur sur le client de l'application.
  const ReponseInvitationSupabase(this._client);

  final SupabaseClient _client;

  /// L'invitation recue par le compte connecte (`mon_invitation_en_cours`).
  /// Un echec de lecture remonte : l'ecran le dit, avec « Reessayer ».
  Future<EtatInvitationRecue> lire() async {
    final Object? reponse = await _client.rpc<Object?>(
      'mon_invitation_en_cours',
    );
    return etatInvitationDepuis(reponse);
  }

  @override
  Future<ResultatReponseInvitation> accepter({required String cle}) =>
      _repondre('accepter', cle);

  @override
  Future<ResultatReponseInvitation> refuser({required String cle}) =>
      _repondre('refuser', cle);

  Future<ResultatReponseInvitation> _repondre(
    String decision,
    String cle,
  ) async {
    try {
      final Object? reponse = await _client.rpc<Object?>(
        'repondre_invitation_conjoint',
        params: <String, dynamic>{'p_decision': decision, 'p_cle': cle},
      );
      return ReponseRecue(etatInvitationDepuis(reponse));
    } on PostgrestException {
      // Un refus du serveur ne dit jamais pourquoi (F4).
      return const ReponseRecue(InvitationNonAcceptable());
    } on Object {
      return const ReponseEchecReseau();
    }
  }
}

/// L'etat d'une invitation, lu dans la reponse du serveur. Les dates sont
/// celles qu'il rend, jamais calculees ; une date illisible n'est pas
/// montree.
EtatInvitationRecue etatInvitationDepuis(Object? reponse) {
  if (reponse is! Map) return const InvitationNonAcceptable();
  final Object? prenom = reponse['prenom_titulaire'];
  final DateTime? le = _date(reponse['enregistree_le']);
  return switch (reponse['etat']) {
    'a_repondre' when prenom is String && prenom.trim().isNotEmpty =>
      InvitationARepondre(
        prenomTitulaire: prenom.trim(),
        titulaireFeminin: reponse['titulaire_feminin'] == true,
        validationRequise: reponse['validation_requise'] == true,
        dureeConservation: reponse['duree_conservation'] is String
            ? reponse['duree_conservation'] as String
            : null,
      ),
    'acceptee' when prenom is String && prenom.trim().isNotEmpty =>
      InvitationAcceptee(prenom.trim(), enregistreeLe: le),
    'refusee' => InvitationRefuseeParVous(enregistreeLe: le),
    'perimee' => const InvitationPerimee(),
    _ => const InvitationNonAcceptable(),
  };
}

DateTime? _date(Object? valeur) =>
    valeur is String ? DateTime.tryParse(valeur)?.toLocal() : null;
