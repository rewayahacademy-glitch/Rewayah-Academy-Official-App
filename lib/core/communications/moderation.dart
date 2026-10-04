// La moderation des communications (spec section 5.5 ; COM-BR-06).
//
// Ce n'est PAS le signalement pedagogique (`PortSignalement`, enseignant vers
// l'administration, sur un eleve) : objets et destinataires different, les
// deux ne se melangent pas (UX_REVIEW L0, section 1.5).
//
// Les actions de moderation ne se montrent qu'avec la capacite donnee par le
// serveur (`CapacitesModeration`), jamais deduite d'un role. Aucune sanction
// automatique de compte n'existe dans cette spec frontend.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import '../i18n/strings.g.dart';
import 'modeles_communication.dart';

/// Les huit motifs de signalement V1, dans l'ordre de la spec section 5.5.
enum MotifSignalement {
  /// Publicite.
  publicite,

  /// Lien affilie.
  lienAffilie,

  /// Vente non autorisee.
  venteNonAutorisee,

  /// Sollicitation commerciale.
  sollicitationCommerciale,

  /// Contenu sans rapport avec la communaute.
  horsSujet,

  /// Harcelement ou langage inapproprie.
  harcelement,

  /// Donnees personnelles d'un eleve ou d'une famille.
  donneesPersonnelles,

  /// Autre contenu a examiner.
  autre;

  /// Le libelle du motif, dans la langue courante (`com.socle.motifs.*`).
  String get libelle => switch (this) {
    MotifSignalement.publicite => t.com.socle.motifs.publicite,
    MotifSignalement.lienAffilie => t.com.socle.motifs.lienAffilie,
    MotifSignalement.venteNonAutorisee => t.com.socle.motifs.venteNonAutorisee,
    MotifSignalement.sollicitationCommerciale =>
      t.com.socle.motifs.sollicitationCommerciale,
    MotifSignalement.horsSujet => t.com.socle.motifs.horsSujet,
    MotifSignalement.harcelement => t.com.socle.motifs.harcelement,
    MotifSignalement.donneesPersonnelles =>
      t.com.socle.motifs.donneesPersonnelles,
    MotifSignalement.autre => t.com.socle.motifs.autre,
  };
}

/// Une action de moderation (spec section 5.5). « Ouvrir le contexte » et
/// « consulter l'auteur » sont des navigations, pas des actions du port.
enum ActionModeration {
  /// Masquer le contenu.
  masquer,

  /// Restaurer un contenu masque.
  restaurer,

  /// Rejeter le signalement.
  rejeter,

  /// Approuver le contenu apres examen.
  approuver,
}

/// Ce que la personne connectee peut faire en moderation, donne par le
/// serveur. Un widget lit cette capacite, jamais un role : une action absente
/// d'ici n'est pas rendue (jamais grisee).
@immutable
class CapacitesModeration {
  /// Cree les capacites.
  CapacitesModeration({
    this.peutSignaler = false,
    Set<ActionModeration> actions = const <ActionModeration>{},
  }) : actions = Set<ActionModeration>.unmodifiable(actions);

  /// Aucune capacite.
  static final CapacitesModeration aucune = CapacitesModeration();

  /// Vrai si la personne peut signaler un contenu.
  final bool peutSignaler;

  /// Les actions de moderation permises.
  final Set<ActionModeration> actions;

  /// Vrai si [action] est permise.
  bool peut(ActionModeration action) => actions.contains(action);

  /// Vrai si la personne voit la file de moderation.
  bool get voitLaFile => actions.isNotEmpty;
}

/// Un contenu signale, dans la file de moderation.
@immutable
class ElementModeration {
  /// Cree l'element.
  const ElementModeration({
    required this.id,
    required this.objet,
    required this.motif,
    required this.signaleLe,
    this.extrait,
  });

  /// Identifiant du signalement.
  final String id;

  /// Le contenu signale (publication, reponse...).
  final ObjetLie objet;

  /// Le motif choisi.
  final MotifSignalement motif;

  /// L'instant du signalement (UTC).
  final DateTime signaleLe;

  /// Un extrait deja nettoye par le serveur ; `null` s'il n'est pas permis.
  final String? extrait;
}

/// La moderation des contenus de communication.
///
/// Chaque action porte l'identifiant de son objet ou de son signalement,
/// jamais « l'objet courant » (lecons des roles, 15). Un futur ne se termine
/// qu'a l'accuse du serveur : « Le contenu a ete signale » ne s'affiche
/// qu'apres.
abstract interface class PortModeration {
  /// Les capacites de la personne connectee.
  Future<CapacitesModeration> capacites();

  /// Signale [objet] pour [motif]. [precision] est un texte libre facultatif.
  Future<void> signaler({
    required ObjetLie objet,
    required MotifSignalement motif,
    String? precision,
  });

  /// La file des contenus signales, le plus ancien d'abord.
  Future<List<ElementModeration>> file();

  /// Applique [action] au signalement [signalementId].
  Future<void> appliquer({
    required String signalementId,
    required ActionModeration action,
  });
}

/// La moderation tant qu'aucun contrat n'existe (COM-BR-06) : chaque appel
/// echoue avec [CapaciteIndisponible]. L'ecran dit « moderation
/// indisponible » (spec section 25), jamais un faux signalement accepte.
class ModerationIndisponible implements PortModeration {
  /// Cree l'implementation.
  const ModerationIndisponible();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('COM-BR-06');

  @override
  Future<CapacitesModeration> capacites() =>
      Future<CapacitesModeration>.error(_manque);

  @override
  Future<void> signaler({
    required ObjetLie objet,
    required MotifSignalement motif,
    String? precision,
  }) => Future<void>.error(_manque);

  @override
  Future<List<ElementModeration>> file() =>
      Future<List<ElementModeration>>.error(_manque);

  @override
  Future<void> appliquer({
    required String signalementId,
    required ActionModeration action,
  }) => Future<void>.error(_manque);
}

/// La moderation employee par l'application.
final Provider<PortModeration> portModerationProvider =
    Provider<PortModeration>((Ref ref) => const ModerationIndisponible());
