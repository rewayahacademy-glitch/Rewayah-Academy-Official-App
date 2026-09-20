import 'package:flutter/foundation.dart';

import '../../core/tc_observation/vue_budget_observation.dart';
import '../../core/video/video_session_provider.dart';

/// Ce que le tuteur voit pendant sa visite, et rien d'autre.
///
/// **Fonction pure**, comme `VueSalle.depuis` : la liste exacte de ce qui est
/// expose se verifie sans monter d'ecran ni ouvrir de salle.
///
/// La specification 11.2 enumere ce que la visite montre -- le support partage,
/// l'enseignant, son propre enfant si le media est autorise, un compte a
/// rebours discret -- et surtout ce qu'elle ne montre pas : **aucun roster
/// complet, aucune fiche d'un autre eleve, aucun outil pedagogique**.
///
/// La retenue se tient ici **par construction** : cette classe n'expose que
/// deux participants nommes. Les autres ne sont pas « masques a l'affichage »,
/// ils ne sortent pas d'ici. Un widget qui voudrait les montrer n'aurait rien
/// a montrer. C'est la seule forme de filtre qui ne s'oublie pas au prochain
/// lot.
@immutable
class VueObservationTuteur {
  const VueObservationTuteur._({
    required this.participantsNonExposes,
    this.enseignant,
    this.monEnfant,
    this.budget,
  });

  /// Construit la vue a partir de ce que le moteur de salle publie.
  ///
  /// [enfantProfilId] est l'identifiant de l'enfant que ce tuteur a le droit
  /// de regarder, tel que le serveur l'a inscrit dans l'intervalle de visite.
  /// **Il ne vient pas d'un choix de l'ecran** : un tuteur qui pourrait
  /// designer l'enfant a regarder regarderait celui des autres.
  factory VueObservationTuteur.depuis({
    required List<ParticipantSalle> participants,
    required String? enfantProfilId,
    VueBudgetObservation? budget,
  }) {
    ParticipantSalle? enseignant;
    ParticipantSalle? enfant;
    int autres = 0;

    for (final ParticipantSalle personne in participants) {
      if (personne.estLocal) {
        // Le tuteur ne se regarde pas lui-meme : il n'a ni micro ni camera,
        // sa vignette n'afficherait rien.
        continue;
      }
      if (personne.role == 'teacher' && enseignant == null) {
        enseignant = personne;
        continue;
      }
      if (enfantProfilId != null &&
          personne.identite == enfantProfilId &&
          enfant == null) {
        enfant = personne;
        continue;
      }
      autres++;
    }

    return VueObservationTuteur._(
      enseignant: enseignant,
      monEnfant: enfant,
      participantsNonExposes: autres,
      budget: budget,
    );
  }

  /// L'enseignant de la seance. `null` s'il n'a pas encore rejoint.
  final ParticipantSalle? enseignant;

  /// L'enfant de ce tuteur. `null` s'il n'a pas encore rejoint.
  final ParticipantSalle? monEnfant;

  /// Combien de participants ne sont pas exposes a ce tuteur.
  ///
  /// **Ce nombre ne s'affiche jamais.** Il existe pour que le filtre soit
  /// verifiable par un test : « cinq eleves dans la salle, un seul expose,
  /// quatre non exposes ». Un compteur rendu a l'ecran serait deja un debut de
  /// roster.
  final int participantsNonExposes;

  /// Le compte a rebours du budget. `null` tant que le serveur n'a rien dit.
  final VueBudgetObservation? budget;

  /// Vrai quand l'image de l'enfant est ouverte.
  ///
  /// La politique camera d'un mineur vaut `forbidden` tant que personne ne l'a
  /// ouverte (ADR-009) : le cas le plus frequent est donc l'enfant present et
  /// sans image, et l'ecran doit le dire plutot que de laisser un cadre noir.
  bool get mediaEnfantOuvert => monEnfant?.camera ?? false;

  /// Vrai quand il n'y a encore personne a montrer.
  bool get salleVide => enseignant == null && monEnfant == null;
}
