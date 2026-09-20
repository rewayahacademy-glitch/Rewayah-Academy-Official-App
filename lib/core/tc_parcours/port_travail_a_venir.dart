import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs dans ce depot : le type d'une famille de providers
// n'est pas exporte par l'entree principale de Riverpod 3, il vit dans
// `misc.dart` (meme convention que `service_planning.dart`).
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import 'libelles_tc_parcours.dart';
import 'plage_lisible.dart';
import 'ports_externes/content_position.dart';
import 'ports_externes/learning_assignment.dart';
import 'ports_externes/port_assignations.dart';
import 'ports_externes/slot_action.dart';
import 'source_contenu_seance.dart';

/// Le travail a venir, tel que l'Espace Groupe l'affiche.
///
/// **Contrat produit par Agent H**, consomme par Agent A pour remplir le slot
/// « Avant le prochain cours ». Le lot H **ne construit pas** l'Espace Groupe :
/// il rend des actions, et Agent A decide de leur place.
abstract class PortTravailAVenir {
  /// Au maximum **trois** actions, tous roles confondus.
  ///
  /// Le plafond est garanti par l'implementation, jamais par l'appelant : un
  /// bloc qui en afficherait sept redeviendrait une liste de taches, et
  /// l'application cesserait d'absorber la bureaucratie.
  Future<List<SlotAction>> avantProchainCours({
    required String groupeId,
    String? studentId,
  });
}

/// Le plafond d'actions du bloc « Avant le prochain cours ».
///
/// Trois, et c'est une regle de produit ecrite deux fois dans la spec
/// (sections 4.3 et 13) et une fois dans les contrats (section 11, invariant 2).
const int plafondActionsAvantCours = 3;

/// Le travail a venir, compose depuis les assignations et la reprise de groupe.
///
/// **Aucun formulaire narratif, aucune liste de taches.** Trois actions au plus,
/// chacune portant l'intention pedagogique d'Agent D -- « A apprendre », « A
/// revoir », « A renforcer », « A entretenir », « Pour l'evaluation » -- et la
/// plage a travailler quand elle existe.
///
/// « Reprendre le cours » est **contextuelle** : elle n'apparait que si le
/// groupe a une position connue, et jamais comme une section permanente
/// (spec section 4.4). Quand elle apparait, elle prend l'une des trois places :
/// le plafond ne se negocie pas.
class TravailAVenir implements PortTravailAVenir {
  /// Cree le composeur.
  const TravailAVenir(this._assignations, this._contenu);

  final PortAssignations _assignations;
  final SourceContenuSeance _contenu;

  @override
  Future<List<SlotAction>> avantProchainCours({
    required String groupeId,
    String? studentId,
  }) async {
    final List<SlotAction> actions = <SlotAction>[];

    final ContentPosition? reprise = await _contenu.repriseDeGroupe(groupeId);
    if (reprise != null) {
      actions.add(
        SlotAction(
          id: 'tc.parcours.reprendre',
          libelle: LibellesParcours.avantReprendreDepuis(
            positionLisible(reprise),
          ),
          // Aucune intention pedagogique : reprendre n'est pas un travail a
          // preparer, c'est un raccourci vers l'endroit ou le groupe s'est
          // arrete. Lui coller une intention en ferait une sixieme.
          disponibleHorsLigne: false,
        ),
      );
    }

    final List<LearningAssignment> travaux = await _assignations.aVenir(
      groupId: groupeId,
      limite: plafondActionsAvantCours,
    );

    for (final LearningAssignment travail in travaux) {
      if (actions.length >= plafondActionsAvantCours) {
        break;
      }
      // `PortAssignations.aVenir` ne sait pas filtrer par eleve : le filtre est
      // donc pose ici, apres coup. Consequence assumee et declaree -- la liste
      // peut contenir moins de trois actions quand le groupe porte du travail
      // nominatif pour quelqu'un d'autre. La demande d'un parametre
      // `studentId` sur `aVenir` est en section 5 de
      // `docs/teaching-core/TC_CONTRACT_REQUEST_H.md`.
      if (studentId != null &&
          travail.studentId != null &&
          travail.studentId != studentId) {
        continue;
      }
      actions.add(
        SlotAction(
          id: travail.id,
          libelle: _libelle(travail),
          intention: travail.purpose,
          // Le travail se prepare sur un support, et le hors ligne depend de la
          // ressource, pas de l'assignation : c'est `PortEtatOffline`
          // (Agent B) qui sait, et le lot H ne le devine pas.
          disponibleHorsLigne: false,
        ),
      );
    }

    return List<SlotAction>.unmodifiable(actions);
  }

  /// Ce que l'action dit : l'intention, puis l'endroit.
  ///
  /// L'intention d'abord parce que c'est elle qui fait agir -- « A revoir » dit
  /// quoi faire, « Sourate 2, versets 255 a 257 » dit seulement ou. Une consigne
  /// courte de l'enseignant, quand elle existe, remplace l'endroit : il a ecrit
  /// quelque chose de plus precis que ce que nous saurions formuler.
  String _libelle(LearningAssignment travail) {
    final String intention = LibellesParcours.intention(travail.purpose);
    final String? consigne = travail.instructions?.trim();
    if (consigne != null && consigne.isNotEmpty) {
      return '$intention : $consigne';
    }
    final String ou = travail.contentRange == null
        ? LibellesParcours.plageRessource
        : plageLisible(travail.contentRange!);
    return '$intention : $ou';
  }
}

/// Le travail a venir employe par l'application.
///
/// Il se compose de deux morceaux qui n'ont, aujourd'hui, **aucune source
/// serveur** : les assignations (table absente, demande d'Agent D) et la
/// position de reprise de groupe (persistance absente, demande du lot H). Le
/// provider echoue donc plutot que de rendre un bloc vide qui ferait croire a un
/// groupe sans travail.
final Provider<PortTravailAVenir> portTravailAVenirProvider =
    Provider<PortTravailAVenir>(
      (Ref ref) => throw UnimplementedError(
        'PortTravailAVenir : composer TravailAVenir avec le PortAssignations '
        "d'Agent D et un adaptateur de SourceContenuSeance.",
      ),
    );

/// Le groupe, et eventuellement l'eleve, dont on lit le travail a venir.
///
/// Un enregistrement plutot qu'une classe : l'egalite structurelle est acquise,
/// et une famille de providers en a besoin pour ne pas relire a chaque
/// reconstruction.
typedef ContexteTravailAVenir = ({String groupeId, String? studentId});

/// Les actions du bloc « Avant le prochain cours », pour un groupe donne.
final FutureProviderFamily<List<SlotAction>, ContexteTravailAVenir>
travailAVenirProvider =
    FutureProvider.family<List<SlotAction>, ContexteTravailAVenir>(
      (Ref ref, ContexteTravailAVenir contexte) => ref
          .watch(portTravailAVenirProvider)
          .avantProchainCours(
            groupeId: contexte.groupeId,
            studentId: contexte.studentId,
          ),
    );
