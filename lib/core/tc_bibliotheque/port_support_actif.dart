/// CAP29-G : le support actif d'une seance (spec CAP-29 §3.1 « dans la classe »
/// et §6.3).
///
/// L'enseignant **presente** un support de la Bibliotheque ; la classe le
/// recoit sans rien faire (aucun bouton « Suivre l'enseignant ») ; la salle
/// continue, la connexion video n'est jamais touchee. La synchronisation reelle
/// est une decision du serveur (BR-1) : ce port la fixe, aucune logique de
/// partage n'est dans l'ecran.
///
/// - Les droits sont recontroles par le serveur **a chaque activation** et a
///   chaque lecture : un support retire ou aux droits echus est refuse, et un
///   support retire en cours de seance se dit a la classe.
/// - Aucune URL signee ni cle de stockage : le support se resout par sa fiche.
/// - Le Coran n'est jamais rendu ici : la classe recoit un lien vers le lecteur
///   existant.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_position.dart';
import 'library_resource.dart';

/// Ce que la classe voit comme support actif.
@immutable
class SupportActif {
  /// Cree le support actif.
  const SupportActif({
    required this.resourceId,
    required this.titre,
    required this.type,
    required this.revision,
    this.numeroVersion,
    this.position,
    this.retire = false,
  });

  /// La ressource presentee.
  final String resourceId;

  /// Son titre.
  final String titre;

  /// Son type.
  final TypeRessource type;

  /// La revision de l'etat partage, pour le controle optimiste.
  final int revision;

  /// La version publiee presentee.
  final int? numeroVersion;

  /// Ou en est la presentation.
  final ContentPosition? position;

  /// Vrai quand le serveur a retire le support en cours de seance.
  final bool retire;
}

/// Pourquoi une presentation est refusee.
enum RefusActivation {
  /// Le support est retire du catalogue.
  retire,

  /// Ses droits sont echus.
  droitsEchus,

  /// Il n'est pas attribue a cette classe.
  nonAttribue,
}

/// La reponse du serveur a une presentation.
sealed class ResultatActivation {
  const ResultatActivation();
}

/// Le support est actif pour la classe.
final class ActivationFaite extends ResultatActivation {
  /// Cree la reponse.
  const ActivationFaite(this.actif);

  /// Le support actif.
  final SupportActif actif;
}

/// Le serveur refuse, avec la raison.
final class ActivationRefusee extends ResultatActivation {
  /// Cree la reponse.
  const ActivationRefusee(this.raison);

  /// La raison.
  final RefusActivation raison;
}

/// Revision perimee : quelqu'un a presente un autre support avant.
final class ActivationEnConflit extends ResultatActivation {
  /// Cree la reponse.
  const ActivationEnConflit();
}

/// Ce que la personne connectee peut faire dans cette seance.
@immutable
class CapacitesSupportActif {
  /// Cree les capacites.
  const CapacitesSupportActif({this.peutPresenter = false});

  /// Peut presenter un support a la classe (capacite rendue par le serveur,
  /// jamais deduite d'un role).
  final bool peutPresenter;
}

/// Le support actif d'une seance.
abstract interface class PortSupportActif {
  /// Ce que la personne peut faire dans [seanceId].
  Future<CapacitesSupportActif> capacites(String seanceId);

  /// Presente [resourceId] a la classe. [revisionAttendue] : la revision du
  /// support actif vu par l'enseignant ; [cle] : une cle d'idempotence par
  /// tentative. Une exception = non confirme : l'ecran reprend la meme cle.
  Future<ResultatActivation> activer({
    required String seanceId,
    required String resourceId,
    required int revisionAttendue,
    required String cle,
    ContentPosition? position,
  });

  /// Le support actif de [seanceId], a chaque changement. `null` : aucun
  /// support n'est presente. La classe suit sans rien faire.
  Stream<SupportActif?> suivre(String seanceId);
}

/// Le support actif n'est pas atteignable (reseau).
class SupportActifHorsLigne implements Exception {
  /// Cree l'erreur.
  const SupportActifHorsLigne();
}

/// Le port. Absent avant le branchement serveur (BR-1) : aucun double ne
/// prend sa place en production.
final Provider<PortSupportActif?> portSupportActifProvider =
    Provider<PortSupportActif?>((Ref _) => null);
