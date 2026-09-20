import 'package:flutter/foundation.dart';

import '../tc_horloge/session_clock_vm.dart';
import '../tc_outils/intention_pedagogique.dart';
import 'group_summary_vm.dart';

/// Qui regarde l'Espace Groupe.
///
/// Le role decide de ce qui est montre, jamais de la structure : les quatre
/// roles lisent **la meme page verticale**, dans le **meme ordre**.
enum RoleEspaceGroupe {
  /// L'eleve inscrit.
  eleve,

  /// Le tuteur legal d'un eleve mineur.
  tuteur,

  /// L'enseignant assigne.
  enseignant,

  /// Un role administratif autorise.
  admin,
}

/// Une action du bloc « Avant le prochain cours ».
///
/// **Trois au maximum, tous roles confondus.** C'est une regle de produit, pas
/// une preference de mise en page : un bloc qui en accepterait dix redeviendrait
/// une liste de taches, et l'application cesserait d'absorber la bureaucratie.
@immutable
class SlotAction {
  /// Cree une action.
  const SlotAction({
    required this.id,
    required this.libelle,
    this.intention,
    this.disponibleHorsLigne = false,
  });

  /// Identifiant stable de l'action.
  final String id;

  /// Ce qui s'affiche.
  final String libelle;

  /// L'intention pedagogique, `null` quand l'action n'en porte pas.
  ///
  /// C'est le vocabulaire d'Agent D, repris tel quel : il n'en existe pas un
  /// second.
  final IntentionPedagogique? intention;

  /// Vrai quand l'action reste faisable sans reseau.
  final bool disponibleHorsLigne;
}

/// L'emplacement de la Bibliotheque du groupe.
///
/// **Une enveloppe, pas un contenu.** Elle porte l'identifiant de contexte et
/// rien d'autre : le contenu est rendu par Agent B, a travers `PortCatalogue`.
/// Aucune page Groupe n'invente une deuxieme bibliotheque (decision `D-20`).
@immutable
class SlotBibliotheque {
  /// Cree l'emplacement.
  const SlotBibliotheque({required this.groupeId});

  /// Le groupe dont on montre la bibliotheque.
  final String groupeId;
}

/// L'emplacement de la progression.
///
/// Enveloppe egalement : le contenu vient d'Agent H.
@immutable
class SlotProgression {
  /// Cree l'emplacement.
  const SlotProgression({required this.groupeId, this.sessionId});

  /// Le groupe concerne.
  final String groupeId;

  /// La seance concernee, quand il y en a une.
  final String? sessionId;
}

/// L'emplacement du roster pedagogique.
///
/// Enveloppe egalement : le contenu vient d'Agent E, par
/// `PortRosterEnseignant`, et il ne porte **aucune donnee privee famille**.
/// Non nul uniquement pour l'enseignant et l'administration.
@immutable
class SlotRoster {
  /// Cree l'emplacement.
  const SlotRoster({required this.groupeId, this.sessionId});

  /// Le groupe concerne.
  final String groupeId;

  /// La seance concernee, quand il y en a une.
  final String? sessionId;
}

/// L'Espace Groupe, tel qu'un role donne le lit.
///
/// **Une page verticale, un ordre stable, et rien d'autre** : Session, puis
/// « Avant le prochain cours », puis Bibliotheque, puis progression. Pas de
/// barre laterale interne pour l'eleve ou le tuteur. Pas de systeme de cinq
/// onglets. L'ordre ne depend ni du role, ni de la largeur de l'ecran : ce qui
/// change avec la largeur, c'est la mise en colonnes, jamais la sequence.
///
/// « Reprendre le cours » n'est **pas une section permanente** : c'est un
/// [SlotAction] conditionnel, donc une action contextuelle.
@immutable
class GroupHomeVM {
  /// Cree l'Espace Groupe d'un role.
  const GroupHomeVM({
    required this.identite,
    required this.role,
    required this.avantProchainCours,
    required this.bibliotheque,
    this.horloge,
    this.progression,
    this.roster,
    this.afficheConseilAppareil = true,
  }) : assert(
         avantProchainCours.length <= 3,
         'au maximum trois actions avant le prochain cours, tous roles confondus',
       ),
       assert(
         roster == null ||
             role == RoleEspaceGroupe.enseignant ||
             role == RoleEspaceGroupe.admin,
         'le roster pedagogique n est ouvert qu a l enseignant et a l admin',
       );

  /// Compose l'Espace Groupe d'un role a partir de l'identite du groupe.
  ///
  /// **Une fonction pure, et volontairement pas une methode de port.** Le
  /// contrat `PortGroupes` porte exactement deux methodes, `mesGroupes()` et
  /// `groupe(id)` : lui en ajouter une troisieme serait une divergence avec
  /// `TEACHING_CORE_CONTRACTS.md`, donc un blocage a la fusion. La composition
  /// par role n'a de toute facon besoin d'aucun acces reseau : c'est un calcul.
  ///
  /// [actions] arrive d'Agent H par `PortTravailAVenir`. La borne de trois
  /// reste verifiee par l'assertion du constructeur : on ne tronque pas en
  /// silence une liste trop longue, on signale le defaut.
  factory GroupHomeVM.pourRole({
    required GroupSummaryVM identite,
    required RoleEspaceGroupe role,
    List<SlotAction> actions = const <SlotAction>[],
  }) {
    final bool cotePedagogique =
        role == RoleEspaceGroupe.enseignant || role == RoleEspaceGroupe.admin;
    final String? sessionId = identite.horloge?.sessionId;
    return GroupHomeVM(
      identite: identite,
      role: role,
      horloge: identite.horloge,
      avantProchainCours: actions,
      bibliotheque: SlotBibliotheque(groupeId: identite.groupeId),
      progression: SlotProgression(
        groupeId: identite.groupeId,
        sessionId: sessionId,
      ),
      roster: cotePedagogique
          ? SlotRoster(groupeId: identite.groupeId, sessionId: sessionId)
          : null,
    );
  }

  /// L'identite du groupe : la meme carte que dans « Mes groupes ».
  final GroupSummaryVM identite;

  /// Qui regarde.
  final RoleEspaceGroupe role;

  /// Le temps de la prochaine occurrence, ou `null` s'il n'y en a pas.
  final SessionClockVM? horloge;

  /// Au maximum trois actions.
  final List<SlotAction> avantProchainCours;

  /// L'emplacement de la Bibliotheque.
  final SlotBibliotheque bibliotheque;

  /// L'emplacement de la progression, `null` quand le role n'en a pas besoin.
  final SlotProgression? progression;

  /// L'emplacement du roster, non nul pour l'enseignant et l'administration.
  final SlotRoster? roster;

  /// Vrai quand la Session Card porte le conseil d'appareil.
  ///
  /// « Tablette ou ordinateur conseille pour le cours. Le telephone reste pris
  /// en charge. » **Pas de fenetre modale, pas de blocage, aucun jugement sur
  /// l'appareil.**
  final bool afficheConseilAppareil;

  /// Vrai quand l'eleve ou le tuteur regarde.
  ///
  /// Sert a choisir ce qui est montre, jamais a changer l'ordre de la page.
  bool get estCoteFamille =>
      role == RoleEspaceGroupe.eleve || role == RoleEspaceGroupe.tuteur;
}
