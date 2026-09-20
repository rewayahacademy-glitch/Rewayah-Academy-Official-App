import 'package:flutter/foundation.dart';

import 'guardian_session_visit.dart';

/// Ce qu'un observateur peut faire une fois entre.
///
/// **Ce n'est PAS un type de contrat.** C'est la forme executable des
/// decisions D-14, D-15 et D-16 : la verite est le jeton serveur
/// (`autoriser_jeton_video`), et aucune capacite ne se calcule cote client.
/// Ce double sert a verifier que la table des roles est la bonne, pas a la
/// faire appliquer.
///
/// Promu par Agent Q (TC_CONTRACT_REQUEST_Q.md) : confronte ligne a ligne au
/// tableau G section 1.5 avant l'ecriture du patch d'`autoriser_jeton_video`.
@immutable
class CapacitesObservateur {
  /// Cree un jeu de capacites.
  const CapacitesObservateur({
    required this.micro,
    required this.camera,
    required this.publicationData,
    required this.visibleDesParticipants,
    required this.annonceFaite,
    required this.auditee,
  });

  /// Le micro est-il autorise.
  final bool micro;

  /// La camera est-elle autorisee.
  final bool camera;

  /// La publication de donnees est-elle autorisee.
  final bool publicationData;

  /// Apparait-il dans la liste des participants.
  final bool visibleDesParticipants;

  /// Une annonce est-elle faite dans la classe.
  final bool annonceFaite;

  /// La visite est-elle journalisee. **Toujours vrai.**
  final bool auditee;
}

/// La table des capacites, par role d'observateur.
///
/// - Le **tuteur** observe, muet et sans camera, et l'enseignant est prevenu.
/// - L'**Admin incognito** est invisible aux participants, sans micro, sans
///   camera, sans annonce -- mais jamais invisible a l'audit.
/// - L'**Admin visible** rejoint la classe sous un nom institutionnel, avec
///   micro et camera, et l'annonce est faite.
/// - Le **Controleur** est incognito uniquement (decision D-16) : aucune
///   variante visible n'existe dans ce chantier.
CapacitesObservateur capacitesDe(RoleObservateur role) => switch (role) {
  RoleObservateur.tuteur => const CapacitesObservateur(
    micro: false,
    camera: false,
    publicationData: false,
    visibleDesParticipants: false,
    annonceFaite: true,
    auditee: true,
  ),
  RoleObservateur.adminIncognito => const CapacitesObservateur(
    micro: false,
    camera: false,
    publicationData: false,
    visibleDesParticipants: false,
    annonceFaite: false,
    auditee: true,
  ),
  RoleObservateur.adminVisible => const CapacitesObservateur(
    micro: true,
    camera: true,
    publicationData: true,
    visibleDesParticipants: true,
    annonceFaite: true,
    auditee: true,
  ),
  RoleObservateur.controleur => const CapacitesObservateur(
    micro: false,
    camera: false,
    publicationData: false,
    visibleDesParticipants: false,
    annonceFaite: false,
    auditee: true,
  ),
};
