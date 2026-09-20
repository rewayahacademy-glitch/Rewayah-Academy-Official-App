// TC-STUB-PORT: canonique = lib/core/tc_groupe/group_home_vm.dart (Agent A)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 2, verifiee mot
// pour mot contre le fichier publie par Agent A.
//
// Seul `SlotAction` est repris : c'est le type de retour de `PortTravailAVenir`,
// que le lot H produit et qu'Agent A consomme. Le reste de `GroupHomeVM` (les
// enveloppes de slots, le VM lui-meme) appartient a Agent A et n'est pas
// recopie : le lot H **remplit un slot**, il ne construit pas l'Espace Groupe.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
import 'package:flutter/foundation.dart';

import 'intention_pedagogique.dart';

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
  final IntentionPedagogique? intention;

  /// Vrai quand l'action reste faisable sans reseau.
  final bool disponibleHorsLigne;
}
