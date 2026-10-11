import 'port_reponse_invitation.dart';

/// Lecture serveur de l'invitation reçue par le compte connecté.
///
/// Ce port reste distinct de [PortReponseInvitation] : la page d'invitation
/// peut lire l'état sans recevoir les commandes d'acceptation ou de refus.
abstract interface class PortLectureInvitationRecue {
  /// Lit l'invitation correspondant à l'adresse Auth vérifiée de la session.
  Future<EtatInvitationRecue> lireInvitationEnCours();
}
