import 'port_reponse_invitation.dart';

/// Lecture neutre de l'invitation associée au compte Auth vérifié.
abstract interface class PortLectureInvitationRecue {
  Future<EtatInvitationRecue> lireInvitationEnCours();
}
