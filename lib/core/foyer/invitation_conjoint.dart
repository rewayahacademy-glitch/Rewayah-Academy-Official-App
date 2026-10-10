import 'package:flutter/foundation.dart';

/// Données de l'invitation envoyée par le titulaire. Le serveur ne reçoit
/// que l'adresse et la clé idempotente, jamais les noms saisis facultativement.
@immutable
class InvitationConjoint {
  const InvitationConjoint({
    required this.prenom,
    required this.nom,
    required this.courriel,
    required this.cle,
  });

  final String prenom;
  final String nom;
  final String courriel;
  final String cle;
}

sealed class ResultatInvitation {
  const ResultatInvitation();
}

final class InvitationPartie extends ResultatInvitation {
  const InvitationPartie();
}

final class InvitationRefusee extends ResultatInvitation {
  const InvitationRefusee();
}

final class InvitationEchecReseau extends ResultatInvitation {
  const InvitationEchecReseau();
}

sealed class ResultatAnnulation {
  const ResultatAnnulation();
}

final class AnnulationFaite extends ResultatAnnulation {
  const AnnulationFaite();
}

final class AnnulationEchecReseau extends ResultatAnnulation {
  const AnnulationEchecReseau();
}

/// Port d'envoi et d'annulation du titulaire.
abstract interface class PortInvitationConjoint {
  Future<ResultatInvitation> envoyer(InvitationConjoint invitation);
  Future<ResultatAnnulation> annuler();
}
