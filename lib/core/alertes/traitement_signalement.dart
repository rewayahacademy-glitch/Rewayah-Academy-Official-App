// D1-bis (03/11/2026) : la direction traite un signalement d'enseignant,
// depuis ses alertes : examiner, rediger le message pour la famille, le
// transmettre, clore (migration 20261106200000).
//
// * Ce que la direction peut faire sur un signalement est rendu par le
//   serveur, ligne par ligne (`peut_examiner`, `peut_rediger`,
//   `peut_transmettre`, `peut_clore`, `motif_cloture_requis`) : l'ecran lit
//   ces capacites, jamais un role.
// * Toute transition est verifiee par le serveur (ordre, compte valide,
//   journal) ; l'application ne fait que demander.
// * La source : l'adaptateur des alertes, quand il sait aussi traiter
//   (`AlertesSupabase`) ; sinon « indisponible », jamais un faux succes.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import 'port_alertes.dart';

/// Ou en est un signalement de la file (un signalement clos n'y est plus).
enum StatutSignalement {
  /// Recu, pas encore examine.
  ouvert,

  /// La direction l'examine.
  enExamen,

  /// Le message a ete transmis a la famille.
  transmis,
}

/// A qui part le message pour la famille, deduit par le serveur du profil de
/// l'eleve.
enum CibleTransmission {
  /// Le tuteur d'un eleve mineur.
  tuteurDuMineur,

  /// L'eleve adulte lui-meme.
  eleveAdulte,
}

/// Un signalement de la file de la direction, avec ce qu'elle peut en faire.
@immutable
class SignalementATraiter {
  /// Cree le signalement.
  const SignalementATraiter({
    required this.id,
    required this.categorie,
    required this.prioritaire,
    required this.matricule,
    required this.note,
    required this.statut,
    required this.recuLe,
    this.resume,
    this.cible,
    this.peutExaminer = false,
    this.peutRediger = false,
    this.peutTransmettre = false,
    this.peutClore = false,
    this.motifRequis = true,
  });

  /// Identifiant du signalement (uuid).
  final String id;

  /// Le code de categorie (`pedagogique`, `securite_enfant`...).
  final String categorie;

  /// Vrai pour la securite d'un enfant.
  final bool prioritaire;

  /// Le matricule de l'eleve.
  final String matricule;

  /// La note de l'enseignant, lue par la direction seulement.
  final String note;

  /// Ou il en est.
  final StatutSignalement statut;

  /// Sa date de depot (horloge du serveur).
  final DateTime recuLe;

  /// Le message pour la famille, s'il en a un.
  final String? resume;

  /// A qui le message partirait, ou `null`.
  final CibleTransmission? cible;

  /// « Examiner » est permis.
  final bool peutExaminer;

  /// Le message pour la famille peut s'ecrire.
  final bool peutRediger;

  /// Le message deja ecrit peut se transmettre tel quel.
  final bool peutTransmettre;

  /// « Clore » est permis.
  final bool peutClore;

  /// La cloture exige un motif (reglage du serveur).
  final bool motifRequis;

  /// Vrai pour la securite d'un enfant : jamais de message pour la famille.
  bool get securiteEnfant => categorie == 'securite_enfant';

  /// « Transmettre » se montre : un message peut s'ecrire, puis partir, ou
  /// le message deja ecrit peut partir, vers une cible connue.
  bool get transmissible => cible != null && (peutRediger || peutTransmettre);
}

/// Les gestes de la direction sur un signalement.
abstract interface class PortTraitementSignalement {
  /// Ouvert vers « en examen ».
  Future<void> examiner(String id);

  /// Ecrit le message pour la famille, avant transmission.
  Future<void> rediger(String id, String resume);

  /// Transmet le message a [cible].
  Future<void> transmettre(String id, CibleTransmission cible);

  /// Clot le signalement ; [motif] va au journal seulement.
  Future<void> clore(String id, {String? motif});
}

/// Un refus du serveur : la transition n'est plus permise (un autre poste
/// l'a fait avant, ou le signalement a change). La file se relit.
class TransitionRefusee implements Exception {
  /// Cree le refus avec le message du serveur.
  const TransitionRefusee(this.message);

  /// Le message brut du serveur, pour le journal ; jamais affiche.
  final String message;

  @override
  String toString() => 'TransitionRefusee($message)';
}

/// La source tant qu'aucune ne sait traiter : chaque geste le dit.
class TraitementSignalementIndisponible implements PortTraitementSignalement {
  /// Cree l'implementation.
  const TraitementSignalementIndisponible();

  /// Ce qui manque.
  static const CapaciteIndisponible manque = CapaciteIndisponible('D1-bis');

  @override
  Future<void> examiner(String id) => Future<void>.error(manque);

  @override
  Future<void> rediger(String id, String resume) => Future<void>.error(manque);

  @override
  Future<void> transmettre(String id, CibleTransmission cible) =>
      Future<void>.error(manque);

  @override
  Future<void> clore(String id, {String? motif}) => Future<void>.error(manque);
}

/// Le traitement des signalements : l'adaptateur des alertes quand il sait
/// traiter, sinon indisponible.
final Provider<PortTraitementSignalement> portTraitementSignalementProvider =
    Provider<PortTraitementSignalement>((Ref ref) {
      final PortAlertes alertes = ref.watch(portAlertesProvider);
      return switch (alertes) {
        final PortTraitementSignalement p => p,
        _ => const TraitementSignalementIndisponible(),
      };
    });
