/// Etat que le serveur rend à l'invité dans son propre compte.
sealed class EtatInvitationRecue {
  const EtatInvitationRecue();
}

final class InvitationARepondre extends EtatInvitationRecue {
  const InvitationARepondre({
    required this.prenomTitulaire,
    required this.titulaireFeminin,
    this.validationRequise = false,
    this.dureeConservation,
  });

  final String prenomTitulaire;
  final bool titulaireFeminin;
  final bool validationRequise;
  final String? dureeConservation;
}

final class InvitationAcceptee extends EtatInvitationRecue {
  const InvitationAcceptee(this.prenomTitulaire, {this.enregistreeLe});

  final String prenomTitulaire;
  final DateTime? enregistreeLe;
}

final class InvitationEnValidation extends EtatInvitationRecue {
  const InvitationEnValidation();
}

final class InvitationRefuseeParVous extends EtatInvitationRecue {
  const InvitationRefuseeParVous({this.enregistreeLe});

  final DateTime? enregistreeLe;
}

final class InvitationNonAcceptable extends EtatInvitationRecue {
  const InvitationNonAcceptable();
}

final class InvitationPerimee extends EtatInvitationRecue {
  const InvitationPerimee();
}

sealed class ResultatReponseInvitation {
  const ResultatReponseInvitation();
}

final class ReponseRecue extends ResultatReponseInvitation {
  const ReponseRecue(this.etat);

  final EtatInvitationRecue etat;
}

final class ReponseEchecReseau extends ResultatReponseInvitation {
  const ReponseEchecReseau();
}

abstract interface class PortReponseInvitation {
  Future<ResultatReponseInvitation> accepter({required String cle});
  Future<ResultatReponseInvitation> refuser({required String cle});
}
