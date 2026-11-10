// ACCUEIL-INVITE (09/11/2026) : l'adaptateur Supabase de l'accueil des
// personnes invitees. Deux RPC de la migration 20261122600000 :
// `mon_invitation_accueil` (lecture, session sans profil) et
// `accepter_invitation_nouveau_compte` et `refuser_invitation_sans_compte`
// (la personne invitee dans un foyer repond ; son compte nait a l'acceptation).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/domain/enums.dart';
import 'accueil_invite.dart';

/// L'accueil lu et ecrit sur Supabase.
class AccueilInviteSupabase implements PortAccueilInvite {
  /// Cree l'adaptateur.
  const AccueilInviteSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<InvitationAccueil?> lire() async {
    try {
      return InvitationAccueil.depuisJson(
        await _client.rpc<Object?>('mon_invitation_accueil'),
      );
    } on PostgrestException catch (e) {
      // Fonction absente (migration pas encore installee) : aucun accueil,
      // l'inscription habituelle s'ouvre comme avant ce lot. Toute autre
      // erreur remonte et se dit.
      if (e.code == 'PGRST202' || e.code == '42883') return null;
      rethrow;
    }
  }

  @override
  Future<IssueReponseInvite> accepter({
    required String prenom,
    required String nom,
    required Genre genre,
    required String cle,
  }) async => issueReponseInviteDepuis(
    await _client.rpc<Object?>(
      'accepter_invitation_nouveau_compte',
      params: <String, Object?>{
        'p_prenom': prenom,
        'p_nom': nom,
        'p_genre': genre.valeurSql,
        'p_cle': cle,
      },
    ),
  );

  @override
  Future<IssueReponseInvite> refuser({required String cle}) async =>
      issueReponseInviteDepuis(
        await _client.rpc<Object?>(
          'refuser_invitation_sans_compte',
          params: <String, Object?>{'p_cle': cle},
        ),
      );
}

/// L'issue lue dans la reponse du serveur ; toute autre forme est « ne peut
/// pas repondre », jamais une acceptation supposee.
IssueReponseInvite issueReponseInviteDepuis(Object? brut) {
  final Object? etat = brut is Map ? brut['etat'] : null;
  return switch (etat) {
    'acceptee' => IssueReponseInvite.acceptee,
    'refusee' => IssueReponseInvite.refusee,
    'perimee' => IssueReponseInvite.perimee,
    _ => IssueReponseInvite.nonAcceptable,
  };
}
