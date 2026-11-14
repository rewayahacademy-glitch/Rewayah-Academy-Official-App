// L'avatar d'un participant d'une conversation, en un seul endroit pour la
// liste des fils, l'en-tete du fil et le panneau de contexte :
//   - l'equipe : l'icone de l'application (`MarqueStaff.avatar`, #Ra_staff,
//     decision du directeur du 14/11/2026) ;
//   - une personne : sa photo par le fournisseur unique (PHOTOS-2b), sinon ses
//     initiales ; une famille : ses initiales.
library;

import 'package:flutter/material.dart';

import '../../core/communications/modeles_communication.dart';
import '../../core/widgets/marque_staff.dart';
import '../foyer/photo_eleve.dart';

/// L'avatar de [participant], ou les initiales de [repli] sans participant.
class AvatarParticipant extends StatelessWidget {
  /// Cree l'avatar.
  const AvatarParticipant({
    required this.participant,
    required this.repli,
    required this.diametre,
    super.key,
  });

  /// Le participant, ou `null` (fil sans interlocuteur).
  final Participant? participant;

  /// Le nom dont les initiales servent sans participant.
  final String repli;

  /// Le diametre du cercle (jetons `AppAvatar`).
  final double diametre;

  @override
  Widget build(BuildContext context) {
    final Participant? p = participant;
    if (p != null && p.equipe) return MarqueStaff.avatar(diametre: diametre);
    return PhotoEleve(
      prenom: p?.nomAffiche ?? repli,
      cleAvatar: null,
      personneId: p?.profilId,
      diametre: diametre,
    );
  }
}
