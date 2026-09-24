// Double du port des classes du foyer (contrat K6).
//
// PROPRIETE : coordinateur (`test/fixtures/tuteur/`). Une classe fictive,
// enseignant sans nom reel et sans photo ; capacite et effectif imitent ce que
// `mes_groupes_famille_v` rend, ils ne sont une regle nulle part.

import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';

/// Une classe fictive.
GroupSummaryVM classeFictive({
  String groupeId = 'classe-a',
  String libelle = 'Classe fictive A',
  int nombreMembres = 3,
  int seuilMax = 6,
  TypePublicGroupeVM typePublic = TypePublicGroupeVM.enfant,
}) => GroupSummaryVM(
  groupeId: groupeId,
  libelle: libelle,
  couleurJeton: const JetonCouleurGroupe(index: 0, codeStable: 'g0'),
  enseignant: const EnseignantVM(
    enseignantId: 'enseignant-x',
    titre: TitreEnseignant.sayyid,
    nomAffichage: 'Enseignant X',
  ),
  nombreMembres: nombreMembres,
  seuilMax: seuilMax,
  typePublic: typePublic,
  actif: true,
);

/// Le port des classes du foyer, en memoire.
class FauxClassesFoyer implements PortClassesFoyer {
  /// Cree le faux.
  FauxClassesFoyer({this.classes = const <ClasseFoyer>[]});

  /// Les classes du foyer, tous eleves confondus.
  List<ClasseFoyer> classes;

  @override
  Future<List<ClasseFoyer>> classesDe(String eleveId) async =>
      classes.where((ClasseFoyer c) => c.eleveId == eleveId).toList();

  @override
  Future<ClasseFoyer?> classe({
    required String groupeId,
    required String eleveId,
  }) async {
    for (final ClasseFoyer c in classes) {
      if (c.eleveId == eleveId && c.classe.groupeId == groupeId) {
        return c;
      }
    }
    return null;
  }
}
