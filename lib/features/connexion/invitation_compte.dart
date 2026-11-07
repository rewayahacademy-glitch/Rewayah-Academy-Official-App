/// INVITATION-COMPTE (07/11/2026, garde-cap) : la creation du compte d'une
/// adresse invitee, alors que les inscriptions sont fermees au niveau de
/// l'instance Auth (« Signups not allowed for this instance »).
///
/// Quatre liens portent un code : le second adulte d'un foyer
/// (`?mode=creer&foyer=1&code=...`), l'enseignant
/// (`?mode=creer&invitation=1&code=...`, le comptable de meme), le candidat
/// d'un formulaire importe (`?mode=creer&candidature=1&code=...`). Avant
/// d'envoyer le lien de connexion, la page appelle la fonction Edge
/// `invitation-compte` avec le type, le code et l'adresse saisie : le serveur
/// ne cree le compte que si le code est celui de cette adresse (en attente,
/// non echu, non utilise), dans la limite de cinq demandes par heure. La
/// reponse est toujours la meme ; l'ecran ne dit donc rien de plus : le lien
/// part, comme pour un compte existant.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le type d'invitation lu dans l'adresse.
enum TypeInvitationCompte {
  /// Le second adulte d'un foyer.
  foyer('foyer'),

  /// Un enseignant ou un comptable invite par la direction.
  equipe('equipe'),

  /// Le candidat d'un formulaire importe (courriel `lien_inscription`).
  candidat('candidat');

  const TypeInvitationCompte(this.valeur);

  /// La valeur attendue par la fonction Edge.
  final String valeur;
}

/// Une invitation portee par l'adresse de la page de connexion.
class InvitationDansAdresse {
  /// Cree l'invitation lue.
  const InvitationDansAdresse({required this.type, required this.code});

  /// Le type.
  final TypeInvitationCompte type;

  /// Le code, tel que le lien le porte.
  final String code;
}

/// L'invitation de l'adresse, ou `null` : il faut `mode=creer`, un code, et
/// l'un des trois reperes (`foyer=1`, `candidature=1`, `invitation=1`).
/// L'application route sur le fragment (`/#/connexion?...`) : les parametres
/// se lisent dans l'adresse et dans la requete du fragment, comme
/// `retenirInvitationDepuisAdresse`.
InvitationDansAdresse? invitationDansAdresse(Uri adresse) {
  final Map<String, String> p = <String, String>{
    ...adresse.queryParameters,
    ...?Uri.tryParse(adresse.fragment)?.queryParameters,
  };
  final String code = (p['code'] ?? '').trim();
  if (p['mode'] != 'creer' || code.isEmpty || code.length > 24) return null;
  final TypeInvitationCompte? type = p['foyer'] == '1'
      ? TypeInvitationCompte.foyer
      : p['candidature'] == '1'
      ? TypeInvitationCompte.candidat
      : p['invitation'] == '1'
      ? TypeInvitationCompte.equipe
      : null;
  return type == null ? null : InvitationDansAdresse(type: type, code: code);
}

/// La porte vers la fonction Edge `invitation-compte`.
abstract interface class PortInvitationCompte {
  /// Demande la creation du compte de [courriel] pour l'[invitation]. Ne
  /// rend rien et ne leve jamais : la reponse du serveur est uniforme.
  Future<void> ouvrir(InvitationDansAdresse invitation, String courriel);

  /// Pour une session : le code d'une invitation de foyer est-il pour son
  /// adresse ? Rien n'est consomme.
  Future<EtatInvitationPourMoi> pourMoi(String code);
}

/// Ce que `invitation_foyer_pour_moi` rend.
enum EtatInvitationPourMoi {
  /// L'invitation est pour l'adresse de la session.
  pourVous,

  /// Elle est pour une autre adresse.
  autreAdresse,

  /// Elle ne sert plus (echue, renvoyee, acceptee, annulee) ou le code est
  /// inconnu.
  plusValable,
}

/// L'adaptateur Supabase.
class InvitationCompteSupabase implements PortInvitationCompte {
  /// Cree l'adaptateur.
  const InvitationCompteSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<void> ouvrir(InvitationDansAdresse invitation, String courriel) async {
    try {
      await _client.functions.invoke(
        'invitation-compte',
        body: <String, String>{
          'type': invitation.type.valeur,
          'code': invitation.code,
          'email': courriel.trim(),
        },
      );
    } on Object {
      // Uniforme : une coupure ou un refus n'empeche pas d'envoyer le lien ;
      // pour une adresse sans compte, la connexion dira alors que
      // l'inscription est fermee, comme avant.
    }
  }

  @override
  Future<EtatInvitationPourMoi> pourMoi(String code) async {
    final Object? brut = await _client.rpc<Object?>(
      'invitation_foyer_pour_moi',
      params: <String, dynamic>{'p_code': code},
    );
    return switch (brut is Map ? brut['etat'] : null) {
      'pour_vous' => EtatInvitationPourMoi.pourVous,
      'autre_adresse' => EtatInvitationPourMoi.autreAdresse,
      _ => EtatInvitationPourMoi.plusValable,
    };
  }
}

/// La porte employee par la page de connexion.
final Provider<PortInvitationCompte> portInvitationCompteProvider =
    Provider<PortInvitationCompte>(
      (Ref _) => InvitationCompteSupabase(Supabase.instance.client),
    );
