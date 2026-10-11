/// L'invitation recue par le second adulte, telle que le serveur la rend pour
/// le compte connecte (EA-BR-20).
sealed class EtatInvitationRecue {
  const EtatInvitationRecue();
}

/// L'invitation attend la reponse de la personne connectee.
final class InvitationARepondre extends EtatInvitationRecue {
  /// Cree l'etat.
  const InvitationARepondre({
    required this.prenomTitulaire,
    required this.titulaireFeminin,
    this.validationRequise = false,
    this.dureeConservation,
  });

  /// Le prenom de la personne qui invite, titulaire du foyer.
  final String prenomTitulaire;

  /// Vrai quand la titulaire est une femme : « elle doit voir », « Elle
  /// saura » (T1, variante titulaire femme).
  final bool titulaireFeminin;

  /// Vrai pour un remplacement : le rattachement devra etre valide par
  /// l'administration (doc section 10, texte T2).
  final bool validationRequise;

  /// La duree de conservation de la trace du rattachement, deja redigee par
  /// le serveur (charte 09 section 8 point 8, Q14). `null` : la phrase n'est
  /// pas montree, aucune duree n'est inventee.
  final String? dureeConservation;
}

/// La personne a rejoint le forfait famille : son compte est rattache.
final class InvitationAcceptee extends EtatInvitationRecue {
  /// Cree l'etat.
  const InvitationAcceptee(this.prenomTitulaire, {this.enregistreeLe});

  /// Le prenom du titulaire.
  final String prenomTitulaire;

  /// La date du choix, rendue par le serveur (recu date, charte 09 section
  /// 3, EA-BR-20). `null` : aucune date n'est montree, aucune n'est inventee.
  final DateTime? enregistreeLe;
}

/// L'invitation est acceptee et le rattachement attend la validation de
/// l'administration (remplacement, doc section 10.4).
final class InvitationEnValidation extends EtatInvitationRecue {
  /// Cree l'etat.
  const InvitationEnValidation();
}

/// La personne a refuse l'invitation : rien ne change pour son compte.
final class InvitationRefuseeParVous extends EtatInvitationRecue {
  /// Cree l'etat.
  const InvitationRefuseeParVous({this.enregistreeLe});

  /// La date du choix, rendue par le serveur (recu date, charte 09 section
  /// 3, EA-BR-20). `null` : aucune date n'est montree, aucune n'est inventee.
  final DateTime? enregistreeLe;
}

/// Le compte ne peut pas rejoindre ce forfait : inéligible, ou deja membre ou
/// titulaire d'un autre foyer. Une seule forme neutre, sans motif (F4, doc
/// section 11).
final class InvitationNonAcceptable extends EtatInvitationRecue {
  /// Cree l'etat.
  const InvitationNonAcceptable();
}

/// L'invitation a expire, ou le titulaire l'a annulee : elle ne rattache plus
/// personne (doc section 5.2, reponse tardive).
final class InvitationPerimee extends EtatInvitationRecue {
  /// Cree l'etat.
  const InvitationPerimee();
}

/// La reponse du serveur a une acceptation ou a un refus.
sealed class ResultatReponseInvitation {
  const ResultatReponseInvitation();
}

/// Le serveur a repondu : l'etat de l'invitation apres la reponse.
final class ReponseRecue extends ResultatReponseInvitation {
  /// Cree la reponse.
  const ReponseRecue(this.etat);

  /// L'etat rendu.
  final EtatInvitationRecue etat;
}

/// La connexion a coupe : la reponse n'est pas confirmee (D5) ; la meme cle
/// rend une nouvelle tentative sure.
final class ReponseEchecReseau extends ResultatReponseInvitation {
  /// Cree la reponse.
  const ReponseEchecReseau();
}

/// La reponse du second adulte a l'invitation (EA-BR-20).
abstract interface class PortReponseInvitation {
  /// Accepte l'invitation, avec la cle d'idempotence de cette tentative.
  Future<ResultatReponseInvitation> accepter({required String cle});

  /// Refuse l'invitation, avec la cle d'idempotence de cette tentative.
  Future<ResultatReponseInvitation> refuser({required String cle});
}
