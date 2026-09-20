import 'package:flutter/foundation.dart';

import 'guardian_session_visit.dart';

/// Comment l'administration entre dans une seance (specification 11.5).
///
/// **Deux modes, choisis AVANT l'entree, et le choix ne se rejoue pas.** Les
/// confondre produirait soit une intrusion, soit une impuissance : constater
/// sans perturber et intervenir sont deux besoins distincts, et un mode qui
/// basculerait en cours de visite ferait apparaitre au milieu du cours
/// quelqu'un que personne n'avait vu entrer.
enum ModeEntreeAdmin {
  /// Invisible aux participants. Ni micro, ni camera, ni annonce.
  ///
  /// Invisible aux participants, **jamais invisible a l'audit** : la visite est
  /// journalisee comme toutes les autres, avec identite, seance, entree, sortie
  /// et duree.
  observerDiscretement(RoleObservateur.adminIncognito),

  /// Visible de tous, sous un nom institutionnel clair.
  rejoindreLaClasse(RoleObservateur.adminVisible);

  const ModeEntreeAdmin(this.role);

  /// Le role d'observateur que ce mode fait tenir.
  final RoleObservateur role;

  /// Vrai quand les participants voient l'administration.
  bool get visible => this == ModeEntreeAdmin.rejoindreLaClasse;

  /// Vrai quand une annonce est faite a l'entree.
  bool get annonceFaite => visible;
}

/// Une capacite de media ou de presence, telle qu'un jeton l'accorde.
enum CapaciteObservation {
  /// Publier sa voix.
  micro,

  /// Publier son image.
  camera,

  /// Publier sur le canal de donnees : chat, annotation, pilotage du support.
  publicationData,

  /// Apparaitre dans la liste des participants.
  visibilite,
}

/// Ce qu'un role d'observation devrait pouvoir faire.
///
/// **Ce profil ne decide de rien.** Les capacites reelles viennent du jeton
/// signe emis par `autoriser_jeton_video()`, et elles y sont derivees du seul
/// role. Ce profil sert a deux choses, et a aucune autre : ne pas proposer a
/// l'ecran une commande que le jeton refuserait en silence -- l'invariant J7,
/// « un etat ne se dit jamais par l'absence de reaction » -- et rendre visible
/// un ecart entre ce que le produit promet et ce que le serveur accorde.
///
/// Un ecart n'autorise jamais le client a passer outre : il s'affiche.
@immutable
class ProfilObservateur {
  const ProfilObservateur._({
    required this.role,
    required this.capacites,
    required this.annonce,
  });

  /// Le profil attendu pour un role.
  ///
  /// Le tuteur, l'administration incognito et le controle qualite n'ont aucune
  /// capacite : trois roles, une seule ligne de verite. Seule l'intervention
  /// administrative visible en a, et elle les a toutes sauf le canal de
  /// donnees, qui reste l'outil pedagogique de l'enseignant.
  factory ProfilObservateur.pour(RoleObservateur role) => switch (role) {
    RoleObservateur.tuteur => const ProfilObservateur._(
      role: RoleObservateur.tuteur,
      // Visible : l'enseignant doit savoir qu'un parent regarde. C'est deja le
      // comportement de `guardian_observer` depuis la migration `0012`.
      capacites: <CapaciteObservation>{CapaciteObservation.visibilite},
      annonce: true,
    ),
    RoleObservateur.adminIncognito => const ProfilObservateur._(
      role: RoleObservateur.adminIncognito,
      capacites: <CapaciteObservation>{},
      annonce: false,
    ),
    RoleObservateur.adminVisible => const ProfilObservateur._(
      role: RoleObservateur.adminVisible,
      capacites: <CapaciteObservation>{
        CapaciteObservation.micro,
        CapaciteObservation.camera,
        CapaciteObservation.visibilite,
      },
      annonce: true,
    ),
    RoleObservateur.controleur => const ProfilObservateur._(
      role: RoleObservateur.controleur,
      capacites: <CapaciteObservation>{},
      annonce: false,
    ),
  };

  /// Le role decrit.
  final RoleObservateur role;

  /// Ce que ce role devrait pouvoir faire.
  final Set<CapaciteObservation> capacites;

  /// Vrai quand l'entree se dit aux participants.
  final bool annonce;

  /// Vrai quand ce role n'apparait dans aucune liste de participants.
  bool get incognito => !capacites.contains(CapaciteObservation.visibilite);

  /// Les capacites sur lesquelles le jeton et le produit ne sont pas d'accord.
  ///
  /// Les quatre booleens viennent de `CapacitesSalle`, c'est-a-dire du jeton
  /// signe. Un ensemble vide signifie que l'ecran peut se fier a ce qu'il
  /// affiche. Un ensemble non vide est un **defaut a montrer**, jamais une
  /// permission a prendre : si le jeton accorde un micro a un tuteur, c'est le
  /// serveur qu'il faut corriger, pas l'ecran qu'il faut ouvrir.
  Set<CapaciteObservation> ecartsAvecJeton({
    required bool peutPublier,
    required bool peutPublierVideo,
    required bool peutPublierDonnees,
    required bool invisible,
  }) {
    final Map<CapaciteObservation, bool> jeton = <CapaciteObservation, bool>{
      CapaciteObservation.micro: peutPublier,
      CapaciteObservation.camera: peutPublierVideo,
      CapaciteObservation.publicationData: peutPublierDonnees,
      CapaciteObservation.visibilite: !invisible,
    };
    return <CapaciteObservation>{
      for (final MapEntry<CapaciteObservation, bool> accorde in jeton.entries)
        if (accorde.value != capacites.contains(accorde.key)) accorde.key,
    };
  }
}
