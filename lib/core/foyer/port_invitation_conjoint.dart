import 'package:flutter/foundation.dart';

/// Ce que le titulaire envoie : le prenom et l'adresse (obligatoires), le nom
/// (facultatif, Q7), et une cle d'idempotence tiree une fois par saisie, que
/// chaque nouvelle tentative reprend (doc section 17).
@immutable
class InvitationConjoint {
  /// Cree l'invitation.
  const InvitationConjoint({
    required this.prenom,
    required this.nom,
    required this.courriel,
    required this.cle,
  });

  /// Le prenom de la personne invitee.
  final String prenom;

  /// Son nom, vide s'il n'est pas donne.
  final String nom;

  /// L'adresse a laquelle l'invitation part.
  final String courriel;

  /// La cle d'idempotence de cet envoi.
  final String cle;
}

/// La reponse du serveur a un envoi.
sealed class ResultatInvitation {
  const ResultatInvitation();
}

/// L'invitation est partie.
final class InvitationPartie extends ResultatInvitation {
  /// Cree la reponse.
  const InvitationPartie();
}

/// Le serveur refuse, sans dire pourquoi (F4) : la place n'est plus libre, par
/// exemple. Jamais « cette adresse a deja un compte ».
final class InvitationRefusee extends ResultatInvitation {
  /// Cree la reponse.
  const InvitationRefusee();
}

/// La connexion a coupe : l'invitation n'est pas partie, ou sa reponse est
/// perdue ; la meme cle rend une nouvelle tentative sure.
final class InvitationEchecReseau extends ResultatInvitation {
  /// Cree la reponse.
  const InvitationEchecReseau();
}

/// La reponse du serveur a une annulation.
sealed class ResultatAnnulation {
  const ResultatAnnulation();
}

/// L'invitation est annulee : elle ne peut plus etre acceptee.
final class AnnulationFaite extends ResultatAnnulation {
  /// Cree la reponse.
  const AnnulationFaite();
}

/// La connexion a coupe : l'annulation n'est pas confirmee, l'ecran ne dit
/// que cela (decision D5), jamais « pas annulee ».
final class AnnulationEchecReseau extends ResultatAnnulation {
  /// Cree la reponse.
  const AnnulationEchecReseau();
}

/// L'invitation du second adulte, cote titulaire (EA-BR-15).
abstract interface class PortInvitationConjoint {
  /// Envoie l'invitation. Une seule invitation active par foyer : le serveur
  /// le verifie.
  Future<ResultatInvitation> envoyer(InvitationConjoint invitation);

  /// Annule l'invitation active. Une reponse tardive ne rattache personne.
  Future<ResultatAnnulation> annuler();
}
