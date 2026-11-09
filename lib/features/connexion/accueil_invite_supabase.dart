// ACCUEIL-INVITE (09/11/2026) : l'adaptateur Supabase de l'accueil des
// personnes invitees. Deux RPC de la migration 20261122600000 :
// `mon_invitation_accueil` (lecture, session sans profil) et
// `inscrire_conjoint_invite` (profil de la personne invitee dans un foyer).

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
  Future<IssueInscriptionConjoint> inscrireConjoint({
    required String prenom,
    required String nom,
    required Genre genre,
  }) async {
    final Object? brut = await _client.rpc<Object?>(
      'inscrire_conjoint_invite',
      params: <String, Object?>{
        'p_prenom': prenom,
        'p_nom': nom,
        'p_genre': genre.valeurSql,
      },
    );
    return issueInscriptionConjointDepuis(brut);
  }
}

/// L'issue lue dans la reponse : `cree` et `deja_inscrit` menent a la session
/// relue ; tout le reste est « ne sert plus », jamais une creation supposee.
IssueInscriptionConjoint issueInscriptionConjointDepuis(Object? brut) {
  final Object? resultat = brut is Map ? brut['resultat'] : null;
  return resultat == 'cree' || resultat == 'deja_inscrit'
      ? IssueInscriptionConjoint.cree
      : IssueInscriptionConjoint.plusValable;
}
