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
///
/// **Forme canonique arbitree, commune a Agent A et a Agent H.** Le provider est
/// nullable et rend `null` par defaut ; il ne leve pas. Lever des le premier
/// build ferait passer l'Espace Groupe d'un etat vide propre a un crash, sans
/// qu'aucun compilateur n'ait averti. Rendre `null` sans regle laisserait le
/// consommateur confondre « pas branche » et « rien a faire ».
///
/// **La regle semantique, qui est le coeur de l'arbitrage :**
///
/// - `null` = port **NON BRANCHE**. Le consommateur affiche un etat explicite
///   « non branche », **JAMAIS** « aucun travail a faire ».
/// - non-`null` + liste vide = port branche, et il n'y a **reellement** aucun
///   travail. C'est le **seul** cas ou l'interface a le droit de dire qu'il n'y
///   a rien a preparer.
///
/// Les deux cas produisent donc deux rendus differents, jamais le meme : voir
/// `BlocAvantProchainCours`, qui teste `portBranche` avant `actions.isEmpty`.
final Provider<PortTravailAVenir?> portTravailAVenirProvider =
    Provider<PortTravailAVenir?>((Ref ref) => null);
