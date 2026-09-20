// TC-STUB-PORT: canonique = lib/core/tc_parcours/port_travail_a_venir.dart (Agent H)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 16.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../group_home_vm.dart';

/// Ce qu'il reste a faire avant le prochain cours.
///
/// **Le plafond de trois est garanti par l'implementation, pas par
/// l'appelant.** Agent A affiche ce qu'on lui donne et verifie la borne par
/// assertion dans `GroupHomeVM` ; il ne tronque pas silencieusement une liste
/// trop longue, parce qu'une troncature silencieuse cacherait un defaut de
/// l'autre cote.
abstract class PortTravailAVenir {
  /// Au maximum 3 actions.
  Future<List<SlotAction>> avantProchainCours({
    required String groupeId,
    String? studentId,
  });
}

/// Le travail a venir affiche par l'Espace Groupe.
///
/// Declare **sans implementation** : Agent H le produit, Agent Z le branche.
/// Tant qu'il vaut `null`, le bloc « Avant le prochain cours » affiche son etat
/// « non branche » plutot qu'une liste inventee.
final Provider<PortTravailAVenir?> portTravailAVenirProvider =
    Provider<PortTravailAVenir?>((Ref ref) => null);
